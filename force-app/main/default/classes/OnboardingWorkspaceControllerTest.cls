@isTest
private class OnboardingWorkspaceControllerTest {
    private static Onboarding_Application__c createApplication(String statusValue) {
        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = 'Private individual',
            Status__c = statusValue,
            Services_Required__c = 'FX',
            Channel__c = 'ExperienceCloud',
            Client_Name__c = 'Workspace Test Client'
        );
        insert app;
        return app;
    }

    private static Party__c createApplicantParty() {
        Party__c party = new Party__c(
            Party_Type__c = 'Individual',
            First_Name__c = 'Jane',
            Last_Name__c = 'Doe',
            Full_Legal_Name__c = 'Jane Doe',
            Email__c = 'jane.doe@test.com',
            Is_PEP__c = false
        );
        insert party;
        return party;
    }

    @isTest
    static void testGetWorkspaceData_ReturnsLinksAndSections() {
        Onboarding_Application__c app = createApplication('Approved');
        Party__c applicant = createApplicantParty();

        insert new Application_Party_Role__c(
            Onboarding_Application__c = app.Id,
            Party__c = applicant.Id,
            Role__c = 'Applicant',
            Is_Primary__c = true
        );

        insert new Party_Address__c(
            Party__c = applicant.Id,
            Address_Type__c = 'Residential',
            Street__c = '123 Main St',
            City__c = 'Dubai',
            State__c = 'Dubai',
            Postal_Code__c = '00000',
            Country__c = 'United Arab Emirates',
            Is_Primary__c = true
        );

        insert new Business_Profile__c(
            Onboarding_Application__c = app.Id,
            Purpose_of_Account__c = 'Testing',
            Industry__c = 'Technology'
        );

        insert new Risk_Assessment__c(
            Onboarding_Application__c = app.Id,
            Risk_Rating__c = 'Medium',
            Calculated_Risk_Score__c = 45,
            EDD_Required__c = false,
            Private_Expected_Monthly_Volume__c = 15000,
            Private_Estimated_Transactions_per_Month__c = 8,
            Private_Source_of_Wealth__c = 'Salary',
            Private_Source_of_Wealth_Explanation__c = 'Accumulated savings from employment',
            Private_Geographic_Exposure__c = 'United Arab Emirates;Singapore',
            Private_Intended_Use_of_Account__c = 'Personal FX hedging'
        );

        insert new Declaration_Acceptance__c(
            Onboarding_Application__c = app.Id,
            Signatory_Party__c = applicant.Id,
            Declaration_Type__c = 'Terms_of_Business',
            Accepted__c = true,
            Signature_Name__c = 'Jane Doe',
            Accepted_On__c = Datetime.now(),
            Signature_Timestamp__c = Datetime.now()
        );

        insert new Document_Submission__c(
            Onboarding_Application__c = app.Id,
            Document_Type__c = 'Passport',
            Level__c = 'Application',
            Is_Required__c = true,
            Is_Received__c = false
        );

        insert new Account(
            Name = 'Converted Account',
            Onboarding_Application__c = app.Id
        );

        Test.startTest();
        OnboardingWorkspaceController.WorkspaceData data =
            OnboardingWorkspaceController.getWorkspaceData(app.Id);
        Test.stopTest();

        System.assertNotEquals(null, data, 'Workspace data should be returned');
        System.assertEquals(app.Id, data.applicationId, 'Application id should match');
        System.assertNotEquals(null, data.applicationUrl, 'Application URL should be populated');
        System.assertNotEquals(null, data.applicant, 'Applicant link should be populated');
        System.assertNotEquals(null, data.businessProfile, 'Business profile link should be populated');
        System.assertNotEquals(null, data.businessProfileDetails, 'Business profile details should be populated');
        System.assertEquals('Technology', data.businessProfileDetails.industry, 'Business profile field should be mapped');
        System.assertNotEquals(null, data.applicantAddress, 'Applicant address should be populated');
        System.assertNotEquals(null, data.applicantAddress.editUrl, 'Address edit URL should be available');
        System.assertEquals(1, data.parties.size(), 'Party rows should be returned');
        System.assertNotEquals(null, data.parties[0].partyEditUrl, 'Party edit URL should be available');
        System.assertNotEquals(null, data.parties[0].addressRecordId, 'Party address id should be available');
        System.assertNotEquals(null, data.parties[0].addressRecordUrl, 'Party address view URL should be available');
        System.assertNotEquals(null, data.parties[0].addressEditUrl, 'Party address edit URL should be available');
        System.assertNotEquals(null, data.privateRiskDetails, 'Private risk details should be populated for private clients');
        System.assertEquals(15000, data.privateRiskDetails.expectedMonthlyVolume, 'Private expected monthly volume should be mapped');
        System.assertEquals('Salary', data.privateRiskDetails.sourceOfWealth, 'Private source of wealth should be mapped');
        System.assertEquals(1, data.documents.size(), 'Document rows should be present');
        System.assertEquals(1, data.declarations.size(), 'Declaration rows should be present');
        System.assertEquals(1, data.missingDocumentsCount, 'Missing required document should be counted');
        System.assertEquals('Converted Account', data.convertedAccountName, 'Converted account should be included');
        System.assertEquals(true, data.actions.showConvert, 'Convert should be visible on Approved status');
    }

    @isTest
    static void testExecuteStatusAction_StartReviewAndApproveFlow() {
        Onboarding_Application__c app = createApplication('Submitted');

        Test.startTest();
        OnboardingWorkspaceController.WorkspaceData afterReview =
            OnboardingWorkspaceController.executeStatusAction(app.Id, 'START_REVIEW');
        OnboardingWorkspaceController.WorkspaceData afterApprove =
            OnboardingWorkspaceController.executeStatusAction(app.Id, 'APPROVE');
        Test.stopTest();

        System.assertEquals('Under_Review', afterReview.status, 'Status should move to Under Review');
        System.assertEquals('Approved', afterApprove.status, 'Status should move to Approved');
    }

    @isTest
    static void testExecuteStatusAction_InvalidTransitionThrows() {
        Onboarding_Application__c app = createApplication('Submitted');
        Boolean didThrow = false;

        try {
            Test.startTest();
            OnboardingWorkspaceController.executeStatusAction(app.Id, 'APPROVE');
            Test.stopTest();
        } catch (AuraHandledException ex) {
            didThrow = true;
        }

        System.assertEquals(true, didThrow, 'Invalid transition should throw');
    }

    @isTest
    static void testUpdateStatusFromPath_AllowsApprovedToSubmitted() {
        Onboarding_Application__c app = createApplication('Approved');

        Test.startTest();
        OnboardingWorkspaceController.WorkspaceData updated =
            OnboardingWorkspaceController.updateStatusFromPath(app.Id, 'Submitted');
        Test.stopTest();

        System.assertEquals('Submitted', updated.status, 'Status should be updated to Submitted');
    }
}


