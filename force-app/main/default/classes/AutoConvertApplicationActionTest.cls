@isTest
private class AutoConvertApplicationActionTest {

    private static Onboarding_Application__c createSubmittedApplication() {
        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = 'Private individual',
            Status__c      = 'Submitted',
            Services_Required__c = 'FX',
            Channel__c     = 'ExperienceCloud',
            Client_Name__c = 'Auto Convert Test'
        );
        insert app;
        return app;
    }

    private static void attachPartyAndRisk(Id applicationId) {
        Party__c party = new Party__c(
            Party_Type__c    = 'Individual',
            First_Name__c    = 'Auto',
            Last_Name__c     = 'Convert',
            Full_Legal_Name__c = 'Auto Convert',
            Email__c         = 'autoconvert@test.com',
            Phone__c         = '+1234567890',
            Date_of_Birth__c = Date.newInstance(1990, 6, 15),
            Nationality__c   = 'United Kingdom',
            Government_ID_Number__c = 'PP999888'
        );
        insert party;

        Application_Party_Role__c apr = new Application_Party_Role__c(
            Onboarding_Application__c = applicationId,
            Party__c    = party.Id,
            Role__c     = 'Applicant',
            Is_Primary__c = true
        );
        insert apr;

        Risk_Assessment__c ra = new Risk_Assessment__c(
            Onboarding_Application__c              = applicationId,
            Risk_Rating__c                         = 'Low',
            Private_Source_of_Wealth__c            = 'Salary',
            Private_Source_of_Wealth_Explanation__c = 'Tech employment',
            Private_Estimated_Transactions_per_Month__c = 5,
            Private_Geographic_Exposure__c         = 'United Kingdom',
            Private_Intended_Use_of_Account__c     = 'Personal FX'
        );
        insert ra;
    }

    @isTest
    static void testExecute_SuccessfullyConvertsSubmittedApplication() {
        Onboarding_Application__c app = createSubmittedApplication();
        attachPartyAndRisk(app.Id);

        AutoConvertApplicationAction.Request req = new AutoConvertApplicationAction.Request();
        req.applicationId = app.Id;

        Test.startTest();
        AutoConvertApplicationAction.execute(new List<AutoConvertApplicationAction.Request>{ req });
        Test.stopTest();

        Onboarding_Application__c updatedApp = [
            SELECT Status__c, Target_Account__c FROM Onboarding_Application__c WHERE Id = :app.Id
        ];
        Assert.areEqual('Converted', updatedApp.Status__c, 'Application should be marked Converted');
        Assert.isNotNull(updatedApp.Target_Account__c, 'Target_Account__c should be linked after conversion');

        List<Contact> contacts = [SELECT Id FROM Contact WHERE Onboarding_Application__c = :app.Id];
        Assert.isFalse(contacts.isEmpty(), 'At least one Contact should be created');
    }

    @isTest
    static void testExecute_NullApplicationId_SkipsGracefully() {
        AutoConvertApplicationAction.Request req = new AutoConvertApplicationAction.Request();
        req.applicationId = null;

        Test.startTest();
        Boolean errorThrown = false;
        try {
            AutoConvertApplicationAction.execute(new List<AutoConvertApplicationAction.Request>{ req });
        } catch (Exception ex) {
            errorThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(errorThrown, 'Null applicationId should be skipped without throwing');
    }

    @isTest
    static void testExecute_FailedConversion_ThrowsException() {
        // Application with Draft status — conversion will fail
        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = 'Private individual',
            Status__c      = 'Draft',
            Client_Name__c = 'Should Fail'
        );
        insert app;

        AutoConvertApplicationAction.Request req = new AutoConvertApplicationAction.Request();
        req.applicationId = app.Id;

        Test.startTest();
        Boolean errorThrown = false;
        try {
            AutoConvertApplicationAction.execute(new List<AutoConvertApplicationAction.Request>{ req });
        } catch (AutoConvertApplicationAction.AutoConvertException ex) {
            errorThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(errorThrown, 'Failed conversion should throw AutoConvertException for flow fault connector');
    }
}
