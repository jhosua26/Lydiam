@IsTest
private class BrdgeBeneficiaryServiceTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Client Ltd',
            Client_Code__c = 'TEST-001',
            Client_Status__c = 'Active',
            CurrencyIsoCode = 'GBP'
        );
        insert testAccount;

        Bank_Account__c activeBeneficiary = new Bank_Account__c(
            Beneficiary_Name__c = 'John Doe',
            Bank_Name__c = 'HSBC',
            Bank_Account_Number__c = '12345678',
            Bank_Country__c = 'United Kingdom',
            Account__c = testAccount.Id,
            Active__c = true,
            Verified__c = true,
            IBAN__c = 'GB29NWBK60161331926819',
            Swift_Code__c = 'HBUKGB4B',
            Sort_Code__c = '10-20-30'
        );
        insert activeBeneficiary;

        Bank_Account__c inactiveBeneficiary = new Bank_Account__c(
            Beneficiary_Name__c = 'Inactive Beneficiary',
            Bank_Name__c = 'Barclays',
            Bank_Account_Number__c = '87654321',
            Bank_Country__c = 'United Kingdom',
            Account__c = testAccount.Id,
            Active__c = false,
            Verified__c = false
        );
        insert inactiveBeneficiary;
    }

    @IsTest
    static void givenValidClientCode_whenGetBeneficiaries_thenReturnsActiveOnly() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.getBeneficiaries();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        List<Object> results = (List<Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(1, results.size(), 'Should return only active beneficiaries');

        Map<String, Object> beneficiary = (Map<String, Object>) results[0];
        System.assertEquals('John Doe', beneficiary.get('beneficiaryName'));
        System.assertEquals('HSBC', beneficiary.get('bankName'));
        System.assertEquals(true, beneficiary.get('active'));
        System.assertEquals('TEST-001', beneficiary.get('clientCode'));
    }

    @IsTest
    static void givenMissingClientCode_whenGetBeneficiaries_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.getBeneficiaries();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CLIENT_CODE', result.get('errorCode'));
    }

    @IsTest
    static void givenNonExistentClientCode_whenGetBeneficiaries_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'NONEXISTENT');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.getBeneficiaries();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
    }

    @IsTest
    static void givenValidPayload_whenCreateBeneficiary_thenReturns201AndSendsEmail() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'beneficiaryName' => 'Jane Smith',
            'bankName' => 'Lloyds',
            'bankAccountNumber' => '99887766',
            'bankCountry' => 'United Kingdom',
            'clientCode' => 'TEST-001',
            'iban' => 'GB82WEST12345698765432',
            'swiftCode' => 'LOYDGB2L',
            'sortCode' => '12-34-56',
            'bankAddress' => '25 Gresham Street, London',
            'bankAccountName' => 'Jane Smith Trading'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.createBeneficiary();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertNotEquals(null, result.get('id'));

        Bank_Account__c created = [
            SELECT Beneficiary_Name__c, Active__c, Verified__c, Bank_Name__c
            FROM Bank_Account__c
            WHERE Id = :(String) result.get('id')
        ];
        System.assertEquals('Jane Smith', created.Beneficiary_Name__c);
        System.assertEquals(true, created.Active__c);
        System.assertEquals(false, created.Verified__c);
        System.assertEquals('Lloyds', created.Bank_Name__c);
    }

    @IsTest
    static void givenMissingRequiredFields_whenCreateBeneficiary_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'beneficiaryName' => 'Jane Smith'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.createBeneficiary();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_REQUIRED_FIELDS', result.get('errorCode'));

        List<Object> missing = (List<Object>) result.get('missingFields');
        System.assert(missing.contains('bankName'), 'Should report bankName missing');
        System.assert(missing.contains('bankAccountNumber'), 'Should report bankAccountNumber missing');
        System.assert(missing.contains('bankCountry'), 'Should report bankCountry missing');
        System.assert(missing.contains('clientCode'), 'Should report clientCode missing');
    }

    @IsTest
    static void givenInvalidClientCode_whenCreateBeneficiary_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'beneficiaryName' => 'Jane Smith',
            'bankName' => 'Lloyds',
            'bankAccountNumber' => '99887766',
            'bankCountry' => 'United Kingdom',
            'sortCode' => '12-34-56',
            'clientCode' => 'NONEXISTENT'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.createBeneficiary();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('ACCOUNT_NOT_FOUND', result.get('errorCode'));
    }

    @IsTest
    static void givenUkCountryWithoutSortCode_whenCreateBeneficiary_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'beneficiaryName' => 'UK Missing Sort',
            'bankName' => 'HSBC',
            'bankAccountNumber' => '12121212',
            'bankCountry' => 'United Kingdom',
            'clientCode' => 'TEST-001'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.createBeneficiary();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CONDITIONAL_FIELDS', result.get('errorCode'));
        List<Object> missing = (List<Object>) result.get('missingFields');
        System.assert(missing.contains('sortCode'));
    }

    @IsTest
    static void givenUsCountryWithoutAba_whenCreateBeneficiary_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'beneficiaryName' => 'US Missing ABA',
            'bankName' => 'Chase',
            'bankAccountNumber' => '34343434',
            'bankCountry' => 'United States',
            'clientCode' => 'TEST-001'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.createBeneficiary();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CONDITIONAL_FIELDS', result.get('errorCode'));
        List<Object> missing = (List<Object>) result.get('missingFields');
        System.assert(missing.contains('abaNumber'));
    }

    @IsTest
    static void givenIntlCountryWithoutIbanAndSwift_whenCreateBeneficiary_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'beneficiaryName' => 'Intl Missing Routes',
            'bankName' => 'DBS',
            'bankAccountNumber' => '56565656',
            'bankCountry' => 'Singapore',
            'clientCode' => 'TEST-001'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.createBeneficiary();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CONDITIONAL_FIELDS', result.get('errorCode'));
        List<Object> missing = (List<Object>) result.get('missingFields');
        System.assert(missing.contains('iban'));
        System.assert(missing.contains('swiftCode'));
    }

    // --- PATCH: Update Beneficiary ---

    @IsTest
    static void givenValidUpdate_whenPatchBeneficiary_thenReturns200() {
        Bank_Account__c existing = [
            SELECT Id FROM Bank_Account__c WHERE Beneficiary_Name__c = 'John Doe' LIMIT 1
        ];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'PATCH';

        Map<String, Object> body = new Map<String, Object>{
            'id' => existing.Id,
            'clientCode' => 'TEST-001',
            'beneficiaryName' => 'John Doe Updated',
            'bankAddress' => '10 Downing Street, London'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.updateBeneficiary();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('John Doe Updated', result.get('beneficiaryName'));
        System.assertEquals('10 Downing Street, London', result.get('bankAddress'));
        System.assertEquals('HSBC', result.get('bankName'), 'Unmodified fields should remain unchanged');

        Bank_Account__c updated = [
            SELECT Beneficiary_Name__c, Bank_Address__c FROM Bank_Account__c WHERE Id = :existing.Id
        ];
        System.assertEquals('John Doe Updated', updated.Beneficiary_Name__c);
        System.assertEquals('10 Downing Street, London', updated.Bank_Address__c);
    }

    @IsTest
    static void givenProtectedField_whenPatchBeneficiary_thenReturns400() {
        Bank_Account__c existing = [
            SELECT Id FROM Bank_Account__c WHERE Beneficiary_Name__c = 'John Doe' LIMIT 1
        ];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'PATCH';

        Map<String, Object> body = new Map<String, Object>{
            'id' => existing.Id,
            'clientCode' => 'TEST-001',
            'active' => false
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.updateBeneficiary();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('PROTECTED_FIELD', result.get('errorCode'));
    }

    @IsTest
    static void givenNonExistentBeneficiary_whenPatchBeneficiary_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'PATCH';

        Map<String, Object> body = new Map<String, Object>{
            'id' => '001000000000000AAA',
            'clientCode' => 'TEST-001',
            'beneficiaryName' => 'Ghost'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.updateBeneficiary();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('BENEFICIARY_NOT_FOUND', result.get('errorCode'));
    }

    @IsTest
    static void givenMismatchedClientCode_whenPatchBeneficiary_thenReturns404() {
        Bank_Account__c existing = [
            SELECT Id FROM Bank_Account__c WHERE Beneficiary_Name__c = 'John Doe' LIMIT 1
        ];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'PATCH';

        Map<String, Object> body = new Map<String, Object>{
            'id' => existing.Id,
            'clientCode' => 'WRONG-CODE',
            'beneficiaryName' => 'Should Not Update'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.updateBeneficiary();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('BENEFICIARY_NOT_FOUND', result.get('errorCode'));
    }

    @IsTest
    static void givenCountryChangedToUsWithoutAba_whenPatchBeneficiary_thenReturns400() {
        Bank_Account__c existing = [
            SELECT Id FROM Bank_Account__c WHERE Beneficiary_Name__c = 'John Doe' LIMIT 1
        ];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/beneficiaries';
        req.httpMethod = 'PATCH';

        Map<String, Object> body = new Map<String, Object>{
            'id' => existing.Id,
            'clientCode' => 'TEST-001',
            'bankCountry' => 'United States',
            'abaNumber' => ''
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeBeneficiaryService.updateBeneficiary();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CONDITIONAL_FIELDS', result.get('errorCode'));
        List<Object> missing = (List<Object>) result.get('missingFields');
        System.assert(missing.contains('abaNumber'));
    }
}
