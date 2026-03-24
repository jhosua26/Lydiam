@IsTest
private class AccountSendWelcomeEmailTest {

    @IsTest
    static void testSendEmailFromFlow() {
        // Create a test Account with required fields
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Individual').getRecordTypeId(),
            Name = 'Test User',
            Client_Code__c = 'LYD123',
            Email_for_Notifications__c = 'testclient@example.com'
        );
        insert acc;

        // Prepare flow-style request
        AccountSendWelcomeEmail.Request req = new AccountSendWelcomeEmail.Request();
        req.recordId = acc.Id;

        Test.startTest();
        // Call the invocable method
        AccountSendWelcomeEmail.sendEmail(new List<AccountSendWelcomeEmail.Request>{ req });
        Test.stopTest();
    }

    @IsTest
    static void testNoEmailIfNoNotificationAddress() {
        // Create an Account without Email_for_Notifications__c
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Individual').getRecordTypeId(),
            Name = 'No Client',
            Client_Code__c = 'LYD999'
        );
        insert acc;

        AccountSendWelcomeEmail.Request req = new AccountSendWelcomeEmail.Request();
        req.recordId = acc.Id;

        Test.startTest();
        AccountSendWelcomeEmail.sendEmail(new List<AccountSendWelcomeEmail.Request>{ req });
        Test.stopTest();
    }
}