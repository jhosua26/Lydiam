@IsTest
private class GetDataWebhookTest {

    @IsTest
    static void testGetAccountData() {
        // Create test Account
        Account testAcc = new Account(
            Name = 'Test Account Ltd',
            Phone = '+44 123 456 789',
            Email_for_Notifications__c = 'test@example.com',
            CurrencyIsoCode = 'GBP',
            Client_Code__c = 'ABC123'
        );
        insert testAcc;

        // Create related Payment
        Payment__c pay = new Payment__c(
            Amount__c = 1000,
            Type__c = 'Paid Out',
            Status__c = 'Verified',
            Account__c = testAcc.Id
        );
        insert pay;

        // Create related Trade
        Trade__c trade = new Trade__c(
            Number_of_Tokens__c = 100,
            Total_Amount__c = 1200,
            Price__c = 12,
            Trade_Reference_Number__c = 'TR12345',
            Transaction_Fee__c = 10,
            Account__c = testAcc.Id
        );
        insert trade;

        // Simulate REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/accounts/v1/' + testAcc.Client_Code__c;
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        GetDataWebhook.getAccountData();
        Test.stopTest();
    }

    @IsTest
    static void testMissingAccountId() {
        // Simulate missing accountId
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/accounts/v1/';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        GetDataWebhook.getAccountData();
        Test.stopTest();
    }
}