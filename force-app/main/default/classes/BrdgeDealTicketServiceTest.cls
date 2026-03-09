@IsTest
private class BrdgeDealTicketServiceTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Client Ltd',
            Client_Code__c = 'TEST-001',
            Client_Status__c = 'Active',
            CurrencyIsoCode = 'GBP'
        );
        insert testAccount;

        Account secondAccount = new Account(
            Name = 'Other Client Ltd',
            Client_Code__c = 'TEST-002',
            Client_Status__c = 'Active',
            CurrencyIsoCode = 'GBP'
        );
        insert secondAccount;

        Trade__c existingTrade = new Trade__c(
            Account__c = testAccount.Id,
            External_Reference__c = 'BRDGE-EXISTING-001',
            Buy__c = 'USD',
            Sell__c = 'GBP',
            Total_Amount__c = 10000,
            Status__c = 'Submitted',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now()
        );
        insert existingTrade;

        Trade__c completeTrade = new Trade__c(
            Account__c = testAccount.Id,
            External_Reference__c = 'BRDGE-COMPLETE-001',
            Buy__c = 'EUR',
            Sell__c = 'GBP',
            Total_Amount__c = 5000,
            Status__c = 'Complete',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now().addDays(-5),
            Processed_Date__c = Datetime.now()
        );
        insert completeTrade;

        Trade__c otherClientTrade = new Trade__c(
            Account__c = secondAccount.Id,
            External_Reference__c = 'BRDGE-OTHER-001',
            Buy__c = 'USD',
            Sell__c = 'GBP',
            Total_Amount__c = 1000,
            Status__c = 'Submitted',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now()
        );
        insert otherClientTrade;

        Bank_Account__c ownedBank = new Bank_Account__c(
            Account__c = testAccount.Id,
            Beneficiary_Name__c = 'Owned Bank',
            Bank_Name__c = 'Lydiam UK',
            Bank_Account_Number__c = '11111111',
            Bank_Country__c = 'UK',
            Active__c = true,
            Verified__c = true
        );
        insert ownedBank;

        Bank_Account__c otherClientBank = new Bank_Account__c(
            Account__c = secondAccount.Id,
            Beneficiary_Name__c = 'Other Client Bank',
            Bank_Name__c = 'Other Bank',
            Bank_Account_Number__c = '22222222',
            Bank_Country__c = 'UK',
            Active__c = true,
            Verified__c = true
        );
        insert otherClientBank;
    }

    // --- POST: Create Deal ---

    @IsTest
    static void givenValidPayload_whenCreateDeal_thenReturns201() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'externalReference' => 'BRDGE-NEW-001',
            'clientCode' => 'TEST-001',
            'buyCurrency' => 'EUR',
            'sellCurrency' => 'GBP',
            'amount' => 25000,
            'clientNotes' => 'Urgent transfer'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.createDeal();
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertNotEquals(null, result.get('tradeId'));
        System.assertEquals('BRDGE-NEW-001', result.get('externalReference'));
        System.assertEquals('Submitted', result.get('status'));

        Trade__c created = [
            SELECT Status__c, Source__c, Submitted_Date__c, Client_Notes__c
            FROM Trade__c
            WHERE External_Reference__c = 'BRDGE-NEW-001'
        ];
        System.assertEquals('Submitted', created.Status__c);
        System.assertEquals('Web Platform', created.Source__c);
        System.assertNotEquals(null, created.Submitted_Date__c);
        System.assertEquals('Urgent transfer', created.Client_Notes__c);
    }

    @IsTest
    static void givenDuplicateExternalRef_whenCreateDeal_thenUpsertsAndReturns200() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'externalReference' => 'BRDGE-EXISTING-001',
            'clientCode' => 'TEST-001',
            'buyCurrency' => 'EUR',
            'sellCurrency' => 'GBP',
            'amount' => 15000
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Integer tradeCountBefore = [SELECT COUNT() FROM Trade__c WHERE External_Reference__c = 'BRDGE-EXISTING-001'];
        System.assertEquals(1, tradeCountBefore);

        Test.startTest();
        BrdgeDealTicketService.createDeal();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Integer tradeCountAfter = [SELECT COUNT() FROM Trade__c WHERE External_Reference__c = 'BRDGE-EXISTING-001'];
        System.assertEquals(1, tradeCountAfter, 'Upsert must not create a duplicate record');

        Trade__c updated = [
            SELECT Total_Amount__c, Buy__c FROM Trade__c WHERE External_Reference__c = 'BRDGE-EXISTING-001'
        ];
        System.assertEquals(15000, updated.Total_Amount__c);
        System.assertEquals('EUR', updated.Buy__c);
    }

    @IsTest
    static void givenMissingRequiredFields_whenCreateDeal_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'externalReference' => 'BRDGE-NEW-002'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.createDeal();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_REQUIRED_FIELDS', result.get('errorCode'));

        List<Object> missing = (List<Object>) result.get('missingFields');
        System.assert(missing.contains('clientCode'));
        System.assert(missing.contains('buyCurrency'));
        System.assert(missing.contains('sellCurrency'));
        System.assert(missing.contains('amount'));
    }

    @IsTest
    static void givenInvalidClientCode_whenCreateDeal_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'externalReference' => 'BRDGE-NEW-003',
            'clientCode' => 'NONEXISTENT',
            'buyCurrency' => 'EUR',
            'sellCurrency' => 'GBP',
            'amount' => 5000
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.createDeal();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('ACCOUNT_NOT_FOUND', result.get('errorCode'));
    }

    @IsTest
    static void givenExternalReferenceUsedByAnotherClient_whenCreateDeal_thenReturns409() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'externalReference' => 'BRDGE-OTHER-001',
            'clientCode' => 'TEST-001',
            'buyCurrency' => 'EUR',
            'sellCurrency' => 'GBP',
            'amount' => 7000
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.createDeal();
        Test.stopTest();

        System.assertEquals(409, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('EXTERNAL_REFERENCE_ACCOUNT_CONFLICT', result.get('errorCode'));
    }

    @IsTest
    static void givenBankAccountNotOwnedByClient_whenCreateDeal_thenReturns404() {
        Id foreignBankId = [
            SELECT Id
            FROM Bank_Account__c
            WHERE Account__r.Client_Code__c = 'TEST-002'
            LIMIT 1
        ].Id;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'externalReference' => 'BRDGE-NEW-004',
            'clientCode' => 'TEST-001',
            'buyCurrency' => 'EUR',
            'sellCurrency' => 'GBP',
            'amount' => 5000,
            'clientBankIncomingId' => foreignBankId
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.createDeal();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('BANK_ACCOUNT_NOT_FOUND_FOR_CLIENT', result.get('errorCode'));
    }

    // --- GET: List Deals ---

    @IsTest
    static void givenValidClientCode_whenListDeals_thenReturnsTradeList() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.getDeals();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> results = (List<Object>) wrapper.get('data');
        System.assertEquals(2, results.size());
        System.assertEquals(50, wrapper.get('limit'));
        System.assertEquals(0, wrapper.get('offset'));
        System.assertEquals(2, wrapper.get('totalCount'));

        Map<String, Object> firstTrade = (Map<String, Object>) results[0];
        System.assertNotEquals(null, firstTrade.get('source'));
        System.assertEquals('TEST-001', firstTrade.get('accountClientCode'));
    }

    @IsTest
    static void givenStatusFilter_whenListDeals_thenReturnsFilteredList() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('status', 'Submitted');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.getDeals();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> results = (List<Object>) wrapper.get('data');
        System.assertEquals(1, results.size());
        System.assertEquals(1, wrapper.get('totalCount'));

        Map<String, Object> trade = (Map<String, Object>) results[0];
        System.assertEquals('Submitted', trade.get('status'));
    }

    @IsTest
    static void givenMissingClientCode_whenListDeals_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.getDeals();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }

    // --- GET: Single Deal ---

    @IsTest
    static void givenValidExternalRef_whenGetSingleDeal_thenReturnsDealDetail() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals/BRDGE-EXISTING-001';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.getDeals();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('BRDGE-EXISTING-001', result.get('externalReference'));
        System.assertEquals('Submitted', result.get('status'));
        System.assertEquals('Web Platform', result.get('source'));
        System.assertEquals('TEST-001', result.get('accountClientCode'));
    }

    @IsTest
    static void givenNonExistentExternalRef_whenGetSingleDeal_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals/DOES-NOT-EXIST';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.getDeals();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
    }

    // --- PATCH: Cancel Deal ---

    @IsTest
    static void givenSubmittedDeal_whenCancel_thenReturns200WithCancelledStatus() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals/BRDGE-EXISTING-001/cancel';
        req.httpMethod = 'PATCH';
        req.params.put('clientCode', 'TEST-001');
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.cancelDeal();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('Cancelled', result.get('status'));

        Trade__c updated = [SELECT Status__c FROM Trade__c WHERE External_Reference__c = 'BRDGE-EXISTING-001'];
        System.assertEquals('Cancelled', updated.Status__c);
    }

    @IsTest
    static void givenCompleteDeal_whenCancel_thenReturns409() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals/BRDGE-COMPLETE-001/cancel';
        req.httpMethod = 'PATCH';
        req.params.put('clientCode', 'TEST-001');
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.cancelDeal();
        Test.stopTest();

        System.assertEquals(409, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('INVALID_STATUS_TRANSITION', result.get('errorCode'));
    }

    @IsTest
    static void givenNonExistentDeal_whenCancel_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals/DOES-NOT-EXIST/cancel';
        req.httpMethod = 'PATCH';
        req.params.put('clientCode', 'TEST-001');
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.cancelDeal();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
    }

    @IsTest
    static void givenClientCodeInBody_whenCancel_thenResolvesClientCode() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals/BRDGE-EXISTING-001/cancel';
        req.httpMethod = 'PATCH';

        Map<String, Object> body = new Map<String, Object>{ 'clientCode' => 'TEST-001' };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.cancelDeal();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
    }

    // --- POST: Status Guard ---

    @IsTest
    static void givenCompleteDeal_whenCreateDealWithSameRef_thenReturns409() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'POST';

        Map<String, Object> body = new Map<String, Object>{
            'externalReference' => 'BRDGE-COMPLETE-001',
            'clientCode' => 'TEST-001',
            'buyCurrency' => 'USD',
            'sellCurrency' => 'GBP',
            'amount' => 8000
        };
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.createDeal();
        Test.stopTest();

        System.assertEquals(409, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('INVALID_STATUS_TRANSITION', result.get('errorCode'));

        Trade__c unchanged = [SELECT Total_Amount__c FROM Trade__c WHERE External_Reference__c = 'BRDGE-COMPLETE-001'];
        System.assertEquals(5000, unchanged.Total_Amount__c, 'Complete deal must not be modified');
    }

    // --- GET: Pagination ---

    @IsTest
    static void givenLimitAndOffset_whenListDeals_thenReturnsPaginatedResults() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/deals';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('limit', '1');
        req.params.put('offset', '0');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDealTicketService.getDeals();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> results = (List<Object>) wrapper.get('data');
        System.assertEquals(1, results.size(), 'Should return only 1 record when limit=1');
        System.assertEquals(1, wrapper.get('limit'));
        System.assertEquals(0, wrapper.get('offset'));
        System.assertEquals(2, wrapper.get('totalCount'), 'Total count should reflect all matching records');
    }
}
