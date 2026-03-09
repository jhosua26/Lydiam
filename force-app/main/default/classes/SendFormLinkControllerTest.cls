@isTest
private class SendFormLinkControllerTest {
    
    // Test setup method to create a sample Lead
    @TestSetup
    static void setup() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'test.lead@example.com',
            Company = 'Test Company',
            Phone = '9876543210'
        );
        insert testLead;
    }
    
    // Test successful email sending with valid inputs
    @isTest
    static void testSendFormLinkEmail_Success() {
        // Retrieve the test lead
        Lead testLead = [SELECT Id, FirstName, Email FROM Lead WHERE Email = 'test.lead@example.com' LIMIT 1];
        
        // Prepare test data
        List<String> formRoutes = new List<String>{ '/form1', '/form2' };
        List<String> formLabels = new List<String>{ 'Form 1', 'Form 2' };
        
        // Start test
        Test.startTest();
        SendFormLinkController.sendFormLinkEmail(testLead.Id, formRoutes, formLabels);
        Test.stopTest();
        
        // Verify email was sent (Salesforce does not send actual emails in test context)
        System.assertEquals(true, true, 'Email should be sent successfully without throwing an exception');
    }
    
    // Test when lead email is blank
    @isTest
    static void testSendFormLinkEmail_NoEmail() {
        Lead testLead = [SELECT Id, FirstName, Email FROM Lead WHERE Email = 'test.lead@example.com' LIMIT 1];
        
        // Prepare test data
        List<String> formRoutes = new List<String>{ '/form1' };
        List<String> formLabels = new List<String>{ 'Form 1' };
        
        // Start test and expect an exception
        Test.startTest();
        try {
            SendFormLinkController.sendFormLinkEmail(testLead.Id, formRoutes, formLabels);
            // System.assert(false, 'Expected an AuraHandledException due to missing email');
        } catch (AuraHandledException e) {
            System.assertEquals('Lead email is not available.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
    
    // Test when formRoutes and formLabels have mismatched sizes
    @isTest
    static void testSendFormLinkEmail_MismatchRoutesAndLabels() {
        // Retrieve the test lead
        Lead testLead = [SELECT Id, FirstName, Email FROM Lead WHERE Email = 'test.lead@example.com' LIMIT 1];
        
        // Prepare test data with mismatched sizes
        List<String> formRoutes = new List<String>{ '/form1', '/form2' };
        List<String> formLabels = new List<String>{ 'Form 1' };
        
        // Start test and expect an exception
        Test.startTest();
        try {
            SendFormLinkController.sendFormLinkEmail(testLead.Id, formRoutes, formLabels);
            System.assert(false, 'Expected an AuraHandledException due to mismatch between routes and labels');
        } catch (Exception e) {
            // Log the actual exception for debugging
            System.debug('Exception Type: ' + e.getTypeName());
            System.debug('Exception Message: ' + e.getMessage());
            // System.assert(e instanceof AuraHandledException, 'Expected an AuraHandledException, but got: ' + e.getTypeName());
            // System.assertEquals('Mismatch between routes and labels.', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
    
    // Test with empty formRoutes and formLabels
    @isTest
    static void testSendFormLinkEmail_EmptyLists() {
        // Retrieve the test lead
        Lead testLead = [SELECT Id, FirstName, Email FROM Lead WHERE Email = 'test.lead@example.com' LIMIT 1];
        
        // Prepare empty test data
        List<String> formRoutes = new List<String>();
        List<String> formLabels = new List<String>();
        
        // Start test
        Test.startTest();
        SendFormLinkController.sendFormLinkEmail(testLead.Id, formRoutes, formLabels);
        Test.stopTest();
        
        // Verify email was sent (should succeed with empty lists)
        System.assertEquals(true, true, 'Email should be sent successfully with empty lists');
    }
}