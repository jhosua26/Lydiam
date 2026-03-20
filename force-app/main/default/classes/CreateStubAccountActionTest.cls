@isTest
private class CreateStubAccountActionTest {

    @isTest
    static void testCreatesStubAccountAndLinksToApplication() {
        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = 'Private individual',
            Status__c = 'Submitted',
            Client_Name__c = 'Walk In Client'
        );
        insert app;

        CreateStubAccountAction.Request req = new CreateStubAccountAction.Request();
        req.applicationId = app.Id;
        req.clientName    = 'Walk In Client';
        req.clientType    = 'Private individual';
        req.onboardingDate = Date.today();

        Test.startTest();
        CreateStubAccountAction.execute(new List<CreateStubAccountAction.Request>{ req });
        Test.stopTest();

        Onboarding_Application__c updatedApp = [
            SELECT Target_Account__c FROM Onboarding_Application__c WHERE Id = :app.Id
        ];
        Assert.isNotNull(updatedApp.Target_Account__c, 'Target_Account__c should be set after stub creation');

        Account acct = [
            SELECT Name, Stage__c, Client_Type__c, Has_Submitted_Application__c, Onboarding_Application__c
            FROM Account WHERE Id = :updatedApp.Target_Account__c
        ];
        Assert.areEqual('Walk In Client', acct.Name, 'Account name should match client name');
        Assert.areEqual('Opportunity', acct.Stage__c, 'Stage should be Opportunity');
        Assert.areEqual('Private individual', acct.Client_Type__c, 'Client type should carry over');
        Assert.isTrue(acct.Has_Submitted_Application__c, 'Has_Submitted_Application__c should be true');
        Assert.areEqual(app.Id, acct.Onboarding_Application__c, 'Onboarding_Application__c should be set so workspace can find the account');
    }

    @isTest
    static void testDuplicateNameDoesNotThrowError() {
        Account existing = new Account(Name = 'Duplicate Name Client');
        insert existing;

        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = 'Private individual',
            Status__c = 'Submitted',
            Client_Name__c = 'Duplicate Name Client'
        );
        insert app;

        CreateStubAccountAction.Request req = new CreateStubAccountAction.Request();
        req.applicationId  = app.Id;
        req.clientName     = 'Duplicate Name Client';
        req.clientType     = 'Private individual';
        req.onboardingDate = Date.today();

        Test.startTest();
        Boolean errorThrown = false;
        try {
            CreateStubAccountAction.execute(new List<CreateStubAccountAction.Request>{ req });
        } catch (Exception ex) {
            errorThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(errorThrown, 'Duplicate name should not throw an error — DMLOptions should allow save');

        Onboarding_Application__c updatedApp = [
            SELECT Target_Account__c FROM Onboarding_Application__c WHERE Id = :app.Id
        ];
        Assert.isNotNull(updatedApp.Target_Account__c, 'A new stub Account should still be created and linked');
    }
}
