@IsTest
private class BrdgeAccountServiceTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Client Ltd',
            Client_Code__c = 'TEST-001',
            Client_Status__c = 'Active',
            Email_for_Notifications__c = 'test@example.com',
            Phone = '+44 20 1234 5678',
            CurrencyIsoCode = 'GBP'
        );
        insert testAccount;
    }

    @IsTest
    static void givenValidClientCode_whenGetAccount_thenReturnsAccountSummary() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/accounts/TEST-001';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeAccountService.getAccount();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('TEST-001', result.get('clientCode'));
        System.assertEquals('Test Client Ltd', result.get('name'));
        System.assertEquals('Active', result.get('status'));
        System.assertEquals('test@example.com', result.get('email'));
        System.assertEquals('GBP', result.get('currency'));
        System.assertEquals(true, result.containsKey('stage'));
    }

    @IsTest
    static void givenBlankClientCode_whenGetAccount_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/accounts/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeAccountService.getAccount();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CLIENT_CODE', result.get('errorCode'));
    }

    @IsTest
    static void givenNonExistentClientCode_whenGetAccount_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/accounts/DOES-NOT-EXIST';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeAccountService.getAccount();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('ACCOUNT_NOT_FOUND', result.get('errorCode'));
    }
}
