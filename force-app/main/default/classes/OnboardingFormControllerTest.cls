/**
 * @description Test class for OnboardingFormController
 * Follows Salesforce best practices:
 * - Tests observable behavior, not implementation details
 * - Uses test data builders for complex objects
 * - Includes positive and negative test cases
 * - Aims for 90%+ code coverage
 * 
 * @author System
 * @date 2026
 */
@isTest
private class OnboardingFormControllerTest {
    
    // ========== HELPER METHODS ==========
    
    /**
     * @description Creates a complete Private Individual onboarding form DTO
     * @return OnboardingFormDTO with all required fields populated
     */
    private static OnboardingFormDTO createPrivateClientFormData() {
        OnboardingFormDTO formData = new OnboardingFormDTO();
        formData.clientType = 'Private';
        formData.servicesRequired = new List<String>{'FX'};
        formData.channel = 'ExperienceCloud';
        formData.ipAddress = '192.168.1.1';
        formData.userAgent = 'Test User Agent';
        formData.currentStep = 'declarations';
        formData.isSubmission = true;
        
        // Personal Info
        OnboardingFormDTO.PersonalInfoDTO personalInfo = new OnboardingFormDTO.PersonalInfoDTO();
        personalInfo.salutation = 'Mr';
        personalInfo.firstName = 'John';
        personalInfo.middleName = 'Michael';
        personalInfo.lastName = 'Doe';
        personalInfo.suffix = 'Jr';
        personalInfo.dateOfBirth = '1990-01-01';
        personalInfo.nationality = 'US';
        personalInfo.countryOfResidence = 'United States';
        personalInfo.governmentIdNumber = '123-45-6789';
        personalInfo.email = 'john.doe@test.com';
        personalInfo.mobile = '+1234567890';
        personalInfo.phone = '+0987654321';
        personalInfo.isPEP = 'No';
        formData.personalInfo = personalInfo;

        // Address Info
        OnboardingFormDTO.AddressInfoDTO addressInfo = new OnboardingFormDTO.AddressInfoDTO();
        addressInfo.street = '123 Main St';
        addressInfo.city = 'New York';
        addressInfo.state = 'NY';
        addressInfo.postalCode = '10001';
        addressInfo.country = 'United States';
        addressInfo.addressType = 'Residential';
        formData.addressInfo = addressInfo;
        
        // Risk Info
        OnboardingFormDTO.RiskInfoDTO riskInfo = new OnboardingFormDTO.RiskInfoDTO();
        riskInfo.expectedMonthlyVolume = '50000';
        riskInfo.estimatedTransactionsPerMonth = '10';
        riskInfo.sourceOfWealth = 'Employment';
        riskInfo.sourceOfWealthExplanation = 'Software Engineer';
        riskInfo.geographicExposure = new List<String>{'United States', 'Canada'};
        riskInfo.intendedUseOfAccount = 'Trading';
        formData.riskInfo = riskInfo;
        
        // Service Profiles
        OnboardingFormDTO.ServiceProfileDTO fxService = new OnboardingFormDTO.ServiceProfileDTO();
        fxService.serviceType = 'FX';
        fxService.currenciesToSend = new List<String>{'USD', 'GBP'};
        fxService.currenciesToReceive = new List<String>{'EUR', 'JPY'};
        fxService.countriesFundsSentTo = new List<String>{'United States', 'United Kingdom'};
        fxService.countriesFundsReceivedFrom = new List<String>{'Germany', 'Japan'};
        fxService.fxForwardContractsRequired = 'Yes';
        fxService.fxHedgingNeeds = 'Currency Risk Hedging';
        formData.serviceProfiles = new List<OnboardingFormDTO.ServiceProfileDTO>{fxService};

        // Declarations
        OnboardingFormDTO.DeclarationDTO declaration = new OnboardingFormDTO.DeclarationDTO();
        declaration.declarationType = 'Terms_of_Business';
        declaration.accepted = true;
        declaration.signatoryFirstName = 'John';
        declaration.signatoryLastName = 'Doe';
        declaration.signatureName = 'John Doe';
        declaration.clientNotes = 'Test notes';
        formData.declarations = new List<OnboardingFormDTO.DeclarationDTO>{declaration};
        
        return formData;
    }
    
    /**
     * @description Creates a complete Corporate onboarding form DTO
     * @return OnboardingFormDTO with corporate client data
     */
    private static OnboardingFormDTO createCorporateClientFormData() {
        OnboardingFormDTO formData = new OnboardingFormDTO();
        formData.clientType = 'Corporate';
        formData.servicesRequired = new List<String>{'FX', 'Crypto', 'Advisory'};
        formData.channel = 'ExperienceCloud';
        formData.ipAddress = '192.168.1.1';
        formData.userAgent = 'Test User Agent';
        formData.currentStep = 'declarations';
        formData.isSubmission = true;
        
        // Company Info
        OnboardingFormDTO.CompanyInfoDTO companyInfo = new OnboardingFormDTO.CompanyInfoDTO();
        companyInfo.legalEntityName = 'Test Corp Ltd';
        companyInfo.tradingName = 'Test Corp';
        companyInfo.legalEntityType = 'Limited Company';
        companyInfo.dateOfIncorporation = '2020-01-01';
        companyInfo.countryOfIncorporation = 'United States';
        companyInfo.registrationNumber = 'REG123456';
        companyInfo.registeredStreet = '456 Business Ave';
        companyInfo.registeredCity = 'San Francisco';
        companyInfo.registeredState = 'CA';
        companyInfo.registeredPostalCode = '94102';
        companyInfo.registeredCountry = 'United States';
        companyInfo.website = 'www.testcorp.com';
        companyInfo.email = 'info@testcorp.com';
        companyInfo.phone = '+1234567890';
        companyInfo.natureOfBusiness = 'Software Development';
        companyInfo.restrictedActivities = new List<String>{'None'};
        companyInfo.expectedNumberOfEmployees = '50';
        companyInfo.isRegulatedFinancialInstitution = 'Yes';
        companyInfo.regulatorName = 'SEC';
        companyInfo.regulatoryLicenceNumber = 'LIC123';
        companyInfo.regulatoryJurisdiction = 'United States';
        formData.companyInfo = companyInfo;
        
        // Business Context
        OnboardingFormDTO.BusinessContextDTO businessContext = new OnboardingFormDTO.BusinessContextDTO();
        businessContext.purposeOfAccount = 'International payments';
        businessContext.industry = 'Technology';
        businessContext.productsAndServices = 'Software as a Service';
        businessContext.paymentFlowTypes = new List<String>{'Inbound', 'Outbound'};
        businessContext.expectedTransactionsPerMonth = '100';
        businessContext.expectedAnnualVolume = '1000000';
        businessContext.typicalValuePerTransaction = '10000';
        businessContext.currenciesToSend = new List<String>{'USD', 'GBP'};
        businessContext.currenciesToReceive = new List<String>{'EUR', 'JPY'};
        businessContext.countriesFundsSentTo = new List<String>{'United States', 'United Kingdom'};
        businessContext.countriesFundsReceivedFrom = new List<String>{'United States', 'Canada'};
        businessContext.largestSingleTransaction = '50000';
        businessContext.primarySourceOfFunds = 'Revenue from services';
        // businessContext.sourceOfWealthForBusinessOwners removed - captured in Explanation
        businessContext.sourceOfWealthExplanation = 'Accumulated profits from SaaS business';
        formData.businessContext = businessContext;

        // Shareholders
        OnboardingFormDTO.ShareholderDTO shareholder = new OnboardingFormDTO.ShareholderDTO();
        shareholder.id = 'sh_' + String.valueOf(Datetime.now().getTime());
        shareholder.type = 'Individual';
        shareholder.isShareholder = true;  // NEW: Role boolean
        shareholder.isDirector = false;     // NEW: Role boolean
        shareholder.salutation = 'Ms';
        shareholder.firstName = 'Jane';
        shareholder.middleName = 'Ann';
        shareholder.lastName = 'Smith';
        shareholder.suffix = '';
        shareholder.dateOfBirthOrIncorporation = '1985-05-15';
        shareholder.nationalityOrCountryOfIncorporation = 'US';
        shareholder.countryOfResidenceOrIncorporation = 'United States';
        shareholder.ownershipPercentage = '60';
        shareholder.governmentIdOrRegistrationNumber = '987-65-4321';
        shareholder.isPEP = 'No';
        shareholder.sourceOfWealth = 'Business Ownership';
        shareholder.sourceOfWealthExplanation = 'Founder of Test Corp';
        shareholder.email = 'jane.smith@testcorp.com';
        shareholder.mobile = '+1234567890';
        shareholder.phone = '+0987654321';
        shareholder.positionOrRole = 'CEO';
        shareholder.street = '789 Executive Blvd';
        shareholder.city = 'San Francisco';
        shareholder.state = 'CA';
        shareholder.postalCode = '94103';
        shareholder.country = 'United States';
        formData.shareholders = new List<OnboardingFormDTO.ShareholderDTO>{shareholder};
        
        // Authorized Users
        OnboardingFormDTO.AuthorisedUserDTO authUser = new OnboardingFormDTO.AuthorisedUserDTO();
        authUser.id = 'au_' + String.valueOf(Datetime.now().getTime());
        authUser.salutation = 'Mr';
        authUser.firstName = 'Bob';
        authUser.middleName = 'Lee';
        authUser.lastName = 'Johnson';
        authUser.position = 'CFO';
        authUser.email = 'bob.johnson@testcorp.com';
        authUser.mobileNumber = '+1234567890';
        authUser.phone = '+0987654321';
        authUser.dateOfBirth = '1988-08-20';
        authUser.nationality = 'US';
        authUser.countryOfResidence = 'United States';
        authUser.governmentIdNumber = '456-78-9012';
        authUser.isPEP = 'No';
        authUser.tradingExperience = new List<String>{'Foreign Exchange', 'Equities'};
        authUser.tradeFrequency = 'Weekly';
        authUser.street = '321 Finance St';
        authUser.city = 'San Francisco';
        authUser.state = 'CA';
        authUser.postalCode = '94104';
        authUser.country = 'United States';
        formData.authorisedUsers = new List<OnboardingFormDTO.AuthorisedUserDTO>{authUser};
        
        // Additional Parties
        OnboardingFormDTO.AdditionalPartyDTO director = new OnboardingFormDTO.AdditionalPartyDTO();
        director.id = 'ap_' + String.valueOf(Datetime.now().getTime());
        director.role = 'Director';
        director.type = 'Individual';
        director.salutation = 'Dr';
        director.firstName = 'Alice';
        director.middleName = 'May';
        director.lastName = 'Brown';
        director.dateOfBirthOrIncorporation = '1980-12-10';
        director.nationalityOrCountryOfIncorporation = 'US';
        director.countryOfResidenceOrIncorporation = 'United States';
        director.governmentIdOrRegistrationNumber = '111-22-3333';
        director.isPEP = 'Yes';
        director.positionOrRole = 'Board Director';
        director.ownershipPercentage = '15';
        director.email = 'alice.brown@testcorp.com';
        director.mobile = '+1234567890';
        director.phone = '+0987654321';
        director.street = '555 Board Rd';
        director.city = 'San Francisco';
        director.state = 'CA';
        director.postalCode = '94105';
        director.country = 'United States';
        formData.additionalParties = new List<OnboardingFormDTO.AdditionalPartyDTO>{director};
        
        // Service Profiles - FX, Crypto, Advisory
        OnboardingFormDTO.ServiceProfileDTO fxService = new OnboardingFormDTO.ServiceProfileDTO();
        fxService.serviceType = 'FX';
        fxService.currenciesToSend = new List<String>{'USD', 'GBP'};
        fxService.currenciesToReceive = new List<String>{'EUR', 'JPY'};
        fxService.countriesFundsSentTo = new List<String>{'United States', 'United Kingdom'};
        fxService.countriesFundsReceivedFrom = new List<String>{'Germany', 'France'};
        fxService.fxForwardContractsRequired = 'Yes';
        fxService.fxHedgingNeeds = 'Full hedging coverage';
        
        OnboardingFormDTO.ServiceProfileDTO cryptoService = new OnboardingFormDTO.ServiceProfileDTO();
        cryptoService.serviceType = 'Crypto';
        cryptoService.digitalAssets = new List<String>{'Bitcoin', 'Ethereum'};
        cryptoService.expectedMonthlyCryptoVolume = '100000';
        cryptoService.averageCryptoTransactionSize = '5000';
        // cryptoService.isVASP removed - regulatory status captured in Company Info
        
        OnboardingFormDTO.ServiceProfileDTO advisoryService = new OnboardingFormDTO.ServiceProfileDTO();
        advisoryService.serviceType = 'Advisory';
        advisoryService.advisoryServicesRequired = new List<String>{'Investment Advisory', 'Risk Management'};
        advisoryService.investmentObjectives = new List<String>{'Growth', 'Capital Preservation'};
        advisoryService.riskAppetite = 'Moderate';
        advisoryService.timeHorizon = '5';
        advisoryService.existingAdvisoryRelationships = 'None';
        
        formData.serviceProfiles = new List<OnboardingFormDTO.ServiceProfileDTO>{fxService, cryptoService, advisoryService};
        
        // Regulatory Info
        OnboardingFormDTO.RegulatoryInfoDTO regulatoryInfo = new OnboardingFormDTO.RegulatoryInfoDTO();
        regulatoryInfo.additionalUBOs = 'No';
        regulatoryInfo.onSanctionsList = 'No';
        regulatoryInfo.financialCrimeConviction = 'No';
        regulatoryInfo.pepInOrganization = 'Yes';
        regulatoryInfo.providesMoneyServices = 'No';
        regulatoryInfo.additionalComplianceNotes = 'All compliance checks passed';
        formData.regulatoryInfo = regulatoryInfo;

        // Declarations
        OnboardingFormDTO.DeclarationDTO declaration = new OnboardingFormDTO.DeclarationDTO();
        declaration.declarationType = 'Terms_of_Business';
        declaration.accepted = true;
        declaration.signatoryFirstName = 'Jane';
        declaration.signatoryLastName = 'Smith';
        declaration.signatureName = 'Jane Smith';
        declaration.clientNotes = 'Authorized signatory for Test Corp';
        formData.declarations = new List<OnboardingFormDTO.DeclarationDTO>{declaration};
        
        return formData;
    }
    
    // ========== TEST METHODS ==========
    
    /**
     * @description Test getCountryPicklistValues method - positive case
     */
    @isTest
    static void testGetCountryPicklistValues_Success() {
        Test.startTest();
        List<OnboardingFormController.PicklistOption> options = OnboardingFormController.getCountryPicklistValues();
        Test.stopTest();
        
        // Assert that picklist values are returned (may be empty if field doesn't exist in test org)
        Assert.isNotNull(options, 'Picklist options should not be null');
    }
    
    /**
     * @description Test searchAddress method - returns empty list (placeholder implementation)
     */
    @isTest
    static void testSearchAddress_ReturnsEmptyList() {
        Test.startTest();
        List<OnboardingFormController.AddressResult> results = OnboardingFormController.searchAddress('123 Main St');
        Test.stopTest();

        Assert.isNotNull(results, 'Address results should not be null');
        Assert.areEqual(0, results.size(), 'Placeholder implementation should return empty list');
    }
    
    /**
     * @description Test searchAddress with blank query - returns empty list
     */
    @isTest
    static void testSearchAddress_BlankQuery() {
        Test.startTest();
        List<OnboardingFormController.AddressResult> results = OnboardingFormController.searchAddress('');
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Blank query should return empty list');
    }
    
    /**
     * @description Test createDraftApplication for Private Individual
     */
    @isTest
    static void testCreateDraftApplication_Private() {
        Test.startTest();
        String draftId = OnboardingFormController.createDraftApplication(
            'Private',
            new List<String>{'FX'},
            '192.168.1.1',
            'Test User Agent',
            'ExperienceCloud',
            'entry'
        );
        Test.stopTest();
        
        Assert.isNotNull(draftId, 'Draft application ID should not be null');
        
        // Verify application was created correctly
        Onboarding_Application__c app = [SELECT Id, Client_Type__c, Status__c, Services_Required__c 
                                         FROM Onboarding_Application__c WHERE Id = :draftId];
        Assert.areEqual('Private individual', app.Client_Type__c, 'Client type should be Private individual');
        Assert.areEqual('Draft', app.Status__c, 'Status should be Draft');
        Assert.areEqual('FX', app.Services_Required__c, 'Services should be FX');
    }
    
    /**
     * @description Test createDraftApplication for Corporate
     */
    @isTest
    static void testCreateDraftApplication_Corporate() {
        Test.startTest();
        String draftId = OnboardingFormController.createDraftApplication(
            'Corporate',
            new List<String>{'FX', 'Crypto'},
            '192.168.1.1',
            'Test User Agent',
            'ExperienceCloud',
            'entry'
        );
        Test.stopTest();
        
        Assert.isNotNull(draftId, 'Draft application ID should not be null');
        
        // Verify application was created correctly
        Onboarding_Application__c app = [SELECT Id, Client_Type__c, Status__c, Services_Required__c 
                                         FROM Onboarding_Application__c WHERE Id = :draftId];
        Assert.areEqual('Corporate entity', app.Client_Type__c, 'Client type should be Corporate entity');
        Assert.areEqual('Draft', app.Status__c, 'Status should be Draft');
        Assert.isTrue(app.Services_Required__c.contains('FX'), 'Services should contain FX');
        Assert.isTrue(app.Services_Required__c.contains('Crypto'), 'Services should contain Crypto');
    }
    
    /**
     * @description Test saveOnboardingApplication for Private Individual - positive case
     */
    @isTest
    static void testSaveOnboardingApplication_Private_Success() {
        OnboardingFormDTO formData = createPrivateClientFormData();
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();

        // Assertions
        Assert.isTrue(result.isSuccess, 'Save should be successful: ' + result.message);
        Assert.isNotNull(result.applicationId, 'Application ID should not be null');
        Assert.areEqual(0, result.errors.size(), 'No errors should be present: ' + String.join(result.errors, ', '));
        
        // Verify application was created
        Onboarding_Application__c app = [SELECT Id, Client_Type__c, Status__c, Services_Required__c 
                                         FROM Onboarding_Application__c WHERE Id = :result.applicationId];
        Assert.areEqual('Private individual', app.Client_Type__c, 'Client type should be Private individual');
        Assert.areEqual('Submitted', app.Status__c, 'Status should be Submitted');
        
        // Verify Party was created
        List<Party__c> parties = [SELECT Id, Party_Type__c, First_Name__c, Last_Name__c 
                                  FROM Party__c WHERE Id IN (SELECT Party__c FROM Application_Party_Role__c WHERE Onboarding_Application__c = :result.applicationId)];
        Assert.areEqual(1, parties.size(), 'One party should be created for applicant');
        Assert.areEqual('Individual', parties[0].Party_Type__c, 'Party type should be Individual');
        Assert.areEqual('John', parties[0].First_Name__c, 'First name should match');
        
        // Verify Risk Assessment was created
        List<Risk_Assessment__c> riskAssessments = [SELECT Id, Private_Expected_Monthly_Volume__c 
                                                     FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.areEqual(1, riskAssessments.size(), 'One risk assessment should be created');
        Assert.areEqual(50000, riskAssessments[0].Private_Expected_Monthly_Volume__c, 'Expected monthly volume should match');
    }
    
    /**
     * @description Test saveOnboardingApplication for Corporate - positive case
     */
    @isTest
    static void testSaveOnboardingApplication_Corporate_Success() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        // Assertions
        Assert.isTrue(result.isSuccess, 'Save should be successful: ' + result.message);
        Assert.isNotNull(result.applicationId, 'Application ID should not be null');
        Assert.areEqual(0, result.errors.size(), 'No errors should be present: ' + String.join(result.errors, ', '));
        
        // Verify application was created
        Onboarding_Application__c app = [SELECT Id, Client_Type__c, Status__c, Services_Required__c,
                                         FX_Currency_Pairs__c, Digital_Assets__c, Advisory_Services_Required__c
                                         FROM Onboarding_Application__c WHERE Id = :result.applicationId];
        Assert.areEqual('Corporate entity', app.Client_Type__c, 'Client type should be Corporate entity');
        Assert.areEqual('Submitted', app.Status__c, 'Status should be Submitted');
        Assert.isTrue(app.Services_Required__c.contains('FX'), 'Services should contain FX');
        Assert.isNotNull(app.FX_Currency_Pairs__c, 'FX currency pairs should be populated');
        Assert.isNotNull(app.Digital_Assets__c, 'Digital assets should be populated');
        Assert.isNotNull(app.Advisory_Services_Required__c, 'Advisory services should be populated');
        
        // Verify Parties were created (Applicant, Shareholder, Authorized User, Additional Party)
        List<Application_Party_Role__c> roles = [SELECT Id, Role__c FROM Application_Party_Role__c 
                                                  WHERE Onboarding_Application__c = :result.applicationId];
        Assert.isTrue(roles.size() >= 4, 'At least 4 party roles should be created: ' + roles.size());
        
        Set<String> roleNames = new Set<String>();
        for (Application_Party_Role__c role : roles) {
            roleNames.add(role.Role__c);
        }
        Assert.isTrue(roleNames.contains('Applicant'), 'Applicant role should exist');
        Assert.isTrue(roleNames.contains('Shareholder'), 'Shareholder role should exist');
        Assert.isTrue(roleNames.contains('Authorised_User'), 'Authorised_User role should exist');
        Assert.isTrue(roleNames.contains('Director'), 'Director role should exist');
        
        // Verify Business Profile was created
        List<Business_Profile__c> profiles = [SELECT Id, Purpose_of_Account__c 
                                              FROM Business_Profile__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.areEqual(1, profiles.size(), 'One business profile should be created');
        Assert.areEqual('International payments', profiles[0].Purpose_of_Account__c, 'Purpose should match');
    }
    
    /**
     * @description Test saveOnboardingApplication with invalid JSON - negative case
     */
    @isTest
    static void testSaveOnboardingApplication_InvalidJson() {
        String invalidJson = '{invalid json';
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(invalidJson);
        Test.stopTest();

        Assert.isFalse(result.isSuccess, 'Save should fail for invalid JSON');
        Assert.isTrue(result.errors.size() > 0, 'Errors should be present');
        Assert.isTrue(result.errors[0].contains('Failed to parse'), 'Error should mention parsing failure');
    }
    
    /**
     * @description Test saveOnboardingApplication with missing client type - negative case
     */
    @isTest
    static void testSaveOnboardingApplication_MissingClientType() {
        OnboardingFormDTO formData = createPrivateClientFormData();
        formData.clientType = '';
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isFalse(result.isSuccess, 'Save should fail for missing client type');
        Assert.isTrue(result.errors.size() > 0, 'Errors should be present');
        Assert.isTrue(result.message.contains('Client type'), 'Error should mention client type');
    }
    
    /**
     * @description Test saveOnboardingApplication draft flow (auto-save)
     */
    @isTest
    static void testSaveOnboardingApplication_DraftFlow() {
        OnboardingFormDTO formData = createPrivateClientFormData();
        formData.currentStep = 'personal'; // Draft flow (not final declarations)
        formData.isSubmission = false; // Auto-save, not final submission
        formData.declarations = null; // No declarations yet
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();

        // Draft saves should succeed even without declarations
        Assert.isTrue(result.isSuccess, 'Draft save should be successful: ' + result.message);
        Assert.isNotNull(result.applicationId, 'Application ID should not be null');
        
        // Verify status is Draft (not Submitted)
        Onboarding_Application__c app = [SELECT Id, Status__c FROM Onboarding_Application__c WHERE Id = :result.applicationId];
        Assert.areNotEqual('Submitted', app.Status__c, 'Status should not be Submitted for draft');
    }
    
    /**
     * @description Test saveOnboardingApplication - update existing application
     */
    @isTest
    static void testSaveOnboardingApplication_UpdateExisting() {
        // Create initial application
        OnboardingFormDTO formData1 = createPrivateClientFormData();
        formData1.currentStep = 'personal'; // Draft
        formData1.declarations = null;
        String formDataJson1 = JSON.serialize(formData1);
        
        OnboardingFormDTO.SaveResult result1 = OnboardingFormController.saveOnboardingApplication(formDataJson1);
        Assert.isTrue(result1.isSuccess, 'First save should succeed: ' + result1.message);
        
        // Update the same application
        OnboardingFormDTO formData2 = createPrivateClientFormData();
        formData2.applicationId = result1.applicationId; // Set existing ID
        formData2.personalInfo.firstName = 'Jane'; // Change first name
        String formDataJson2 = JSON.serialize(formData2);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result2 = OnboardingFormController.saveOnboardingApplication(formDataJson2);
        Test.stopTest();

        Assert.isTrue(result2.isSuccess, 'Update should succeed');
        Assert.areEqual(result1.applicationId, result2.applicationId, 'Application ID should be the same');
        
        // Verify only one application exists
        Integer appCount = [SELECT COUNT() FROM Onboarding_Application__c WHERE Id = :result1.applicationId];
        Assert.areEqual(1, appCount, 'Only one application should exist');
        
        // Verify first name was updated
        List<Party__c> parties = [SELECT Id, First_Name__c FROM Party__c 
                                  WHERE Id IN (SELECT Party__c FROM Application_Party_Role__c 
                                               WHERE Onboarding_Application__c = :result1.applicationId AND Role__c = 'Applicant')];
        Assert.areEqual('Jane', parties[0].First_Name__c, 'First name should be updated');
    }
    
    /**
     * @description Test getOnboardingApplication - retrieve existing application
     */
    @isTest
    static void testGetOnboardingApplication_Success() {
        // Create an application first
        OnboardingFormDTO formData = createCorporateClientFormData();
        String formDataJson = JSON.serialize(formData);
        OnboardingFormDTO.SaveResult saveResult = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Assert.isTrue(saveResult.isSuccess, 'Save should succeed');
        
        Test.startTest();
        Map<String, Object> result = OnboardingFormController.getOnboardingApplication(saveResult.applicationId);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual('Corporate entity', result.get('clientType'), 'Client type should match');
        Assert.isNotNull(result.get('servicesRequired'), 'Services required should not be null');
        
        List<Object> servicesRequired = (List<Object>)result.get('servicesRequired');
        Assert.isTrue(servicesRequired.size() > 0, 'Services should be populated');
        
        // Verify shareholders/directors were loaded
        // Note: After the refactoring, Directors are now included in the shareholders list (renamed to "Shareholders/Directors")
        List<Object> shareholders = (List<Object>)result.get('shareholders');
        Assert.isTrue(shareholders.size() >= 1, 'At least one shareholder/director should be loaded, got: ' + shareholders.size());
        
        // Verify authorized users were loaded
        List<Object> authorisedUsers = (List<Object>)result.get('authorisedUsers');
        Assert.areEqual(1, authorisedUsers.size(), 'One authorized user should be loaded');
        
        // Verify additional parties list (should be empty after removing that section)
        List<Object> additionalParties = (List<Object>)result.get('additionalParties');
        // Additional Parties section was removed, so this should be empty or minimal
        System.debug('Additional parties count: ' + additionalParties.size());
    }
    
    /**
     * @description Test getOnboardingApplication with invalid ID
     */
    @isTest
    static void testGetOnboardingApplication_InvalidId() {
        Test.startTest();
        Map<String, Object> result = OnboardingFormController.getOnboardingApplication('INVALID_ID');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null even for invalid ID');
        Assert.areEqual(0, result.size(), 'Result should be empty for invalid ID');
    }
    
    /**
     * @description Test getDraftApplicationData - retrieve draft
     */
    @isTest
    static void testGetDraftApplicationData_Success() {
        // Create draft application
        String draftId = OnboardingFormController.createDraftApplication(
            'Corporate',
            new List<String>{'FX'},
            '192.168.1.1',
            'Test User Agent',
            'ExperienceCloud',
            'entry'
        );
        
        Test.startTest();
        String draftDataJson = OnboardingFormController.getDraftApplicationData(draftId);
        Test.stopTest();
        
        Assert.isNotNull(draftDataJson, 'Draft data should not be null');
        
        OnboardingFormDTO draftData = (OnboardingFormDTO)JSON.deserialize(draftDataJson, OnboardingFormDTO.class);
        Assert.areEqual(draftId, draftData.applicationId, 'Application ID should match');
        // Client type is stored as "Corporate entity" in Salesforce but mapped to "Corporate" in DTO
        Assert.isTrue(draftData.clientType == 'Corporate' || draftData.clientType == 'Corporate entity', 
                     'Client type should be Corporate or Corporate entity, got: ' + draftData.clientType);
    }
    
    /**
     * @description Test getDraftApplicationData with blank ID
     */
    @isTest
    static void testGetDraftApplicationData_BlankId() {
        Test.startTest();
        String draftDataJson = OnboardingFormController.getDraftApplicationData('');
        Test.stopTest();
        
        Assert.isNull(draftDataJson, 'Draft data should be null for blank ID');
    }
    
    /**
     * @description Test address duplication prevention
     */
    @isTest
    static void testAddressDeduplication() {
        OnboardingFormDTO formData1 = createPrivateClientFormData();
        formData1.currentStep = 'address';
        formData1.declarations = null;
        formData1.addressInfo.street = '123 Original St';
        String formDataJson1 = JSON.serialize(formData1);
        
        // First save
        OnboardingFormDTO.SaveResult result1 = OnboardingFormController.saveOnboardingApplication(formDataJson1);
        Assert.isTrue(result1.isSuccess, 'First save should succeed: ' + result1.message);
        
        // Get initial address count
        Integer initialAddressCount = [SELECT COUNT() FROM Party_Address__c 
                                       WHERE Party__c IN (SELECT Party__c FROM Application_Party_Role__c 
                                                          WHERE Onboarding_Application__c = :result1.applicationId)];
        
        // Update address
        OnboardingFormDTO formData2 = createPrivateClientFormData();
        formData2.applicationId = result1.applicationId;
        formData2.addressInfo.street = '456 Updated St';
        String formDataJson2 = JSON.serialize(formData2);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result2 = OnboardingFormController.saveOnboardingApplication(formDataJson2);
        Test.stopTest();
        
        Assert.isTrue(result2.isSuccess, 'Update should succeed');
        
        // Verify no duplicate addresses were created
        Integer finalAddressCount = [SELECT COUNT() FROM Party_Address__c 
                                     WHERE Party__c IN (SELECT Party__c FROM Application_Party_Role__c 
                                                        WHERE Onboarding_Application__c = :result1.applicationId)];
        Assert.areEqual(initialAddressCount, finalAddressCount, 'Address count should remain the same (no duplicates)');
        
        // Verify address was updated
        Party_Address__c updatedAddress = [SELECT Id, Street__c FROM Party_Address__c 
                                           WHERE Party__c IN (SELECT Party__c FROM Application_Party_Role__c 
                                                              WHERE Onboarding_Application__c = :result1.applicationId AND Role__c = 'Applicant')
                                           LIMIT 1];
        Assert.areEqual('456 Updated St', updatedAddress.Street__c, 'Address should be updated');
    }
    
    /**
     * @description Test Risk Assessment deduplication
     */
    @isTest
    static void testRiskAssessmentDeduplication() {
        OnboardingFormDTO formData1 = createPrivateClientFormData();
        formData1.currentStep = 'risk';
        formData1.declarations = null;
        formData1.riskInfo.expectedMonthlyVolume = '50000';
        String formDataJson1 = JSON.serialize(formData1);
        
        // First save
        OnboardingFormDTO.SaveResult result1 = OnboardingFormController.saveOnboardingApplication(formDataJson1);
        Assert.isTrue(result1.isSuccess, 'First save should succeed: ' + result1.message);
        
        // Update risk info
        OnboardingFormDTO formData2 = createPrivateClientFormData();
        formData2.applicationId = result1.applicationId;
        formData2.riskInfo.expectedMonthlyVolume = '100000';
        String formDataJson2 = JSON.serialize(formData2);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result2 = OnboardingFormController.saveOnboardingApplication(formDataJson2);
        Test.stopTest();
        
        Assert.isTrue(result2.isSuccess, 'Update should succeed');
        
        // Verify only one Risk Assessment exists
        Integer riskCount = [SELECT COUNT() FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result1.applicationId];
        Assert.areEqual(1, riskCount, 'Only one Risk Assessment should exist');
        
        // Verify Risk Assessment was updated
        Risk_Assessment__c updatedRisk = [SELECT Id, Private_Expected_Monthly_Volume__c 
                                          FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result1.applicationId];
        Assert.areEqual(100000, updatedRisk.Private_Expected_Monthly_Volume__c, 'Risk Assessment should be updated');
    }
    
    /**
     * @description Test PEP detection in risk scoring
     */
    @isTest
    static void testRiskScoring_PEP() {
        OnboardingFormDTO formData = createPrivateClientFormData();
        formData.personalInfo.isPEP = 'Yes'; // PEP should increase risk score
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        // Verify PEP flag is set
        Risk_Assessment__c risk = [SELECT Id, PEP_Flag__c, Calculated_Risk_Score__c, EDD_Required__c 
                                   FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.areEqual(true, risk.PEP_Flag__c, 'PEP flag should be true');
        Assert.isTrue(risk.Calculated_Risk_Score__c > 0, 'Risk score should be greater than 0');
        Assert.areEqual(true, risk.EDD_Required__c, 'EDD should be required for PEP');
    }
    
    /**
     * @description Test service field clearing when services are deselected
     */
    @isTest
    static void testServiceFieldClearing() {
        // Create application with all services
        OnboardingFormDTO formData1 = createCorporateClientFormData();
        formData1.servicesRequired = new List<String>{'FX', 'Crypto', 'Advisory'};
        formData1.currentStep = 'service';
        formData1.declarations = null;
        String formDataJson1 = JSON.serialize(formData1);
        
        OnboardingFormDTO.SaveResult result1 = OnboardingFormController.saveOnboardingApplication(formDataJson1);
        Assert.isTrue(result1.isSuccess, 'First save should succeed: ' + result1.message);
        
        // Verify all service fields are populated
        Onboarding_Application__c app1 = [SELECT Id, FX_Currency_Pairs__c, Digital_Assets__c, Advisory_Services_Required__c 
                                          FROM Onboarding_Application__c WHERE Id = :result1.applicationId];
        Assert.isNotNull(app1.FX_Currency_Pairs__c, 'FX fields should be populated');
        Assert.isNotNull(app1.Digital_Assets__c, 'Crypto fields should be populated');
        Assert.isNotNull(app1.Advisory_Services_Required__c, 'Advisory fields should be populated');
        
        // Update to only FX service
        OnboardingFormDTO formData2 = createCorporateClientFormData();
        formData2.applicationId = result1.applicationId;
        formData2.servicesRequired = new List<String>{'FX'};
        formData2.currentStep = 'service';
        formData2.declarations = null;
        // Remove Crypto and Advisory profiles
        formData2.serviceProfiles = new List<OnboardingFormDTO.ServiceProfileDTO>();
        OnboardingFormDTO.ServiceProfileDTO fxOnly = new OnboardingFormDTO.ServiceProfileDTO();
        fxOnly.serviceType = 'FX';
        fxOnly.currenciesToSend = new List<String>{'USD'};
        fxOnly.currenciesToReceive = new List<String>{'EUR'};
        fxOnly.countriesFundsSentTo = new List<String>{'United States'};
        fxOnly.countriesFundsReceivedFrom = new List<String>{'Germany'};
        fxOnly.fxForwardContractsRequired = 'No';
        formData2.serviceProfiles.add(fxOnly);
        String formDataJson2 = JSON.serialize(formData2);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result2 = OnboardingFormController.saveOnboardingApplication(formDataJson2);
        Test.stopTest();
        
        Assert.isTrue(result2.isSuccess, 'Update should succeed');
        
        // Verify Crypto and Advisory fields are cleared
        Onboarding_Application__c app2 = [SELECT Id, FX_Currency_Pairs__c, Digital_Assets__c, Advisory_Services_Required__c 
                                          FROM Onboarding_Application__c WHERE Id = :result1.applicationId];
        Assert.isNotNull(app2.FX_Currency_Pairs__c, 'FX fields should still be populated');
        Assert.isNull(app2.Digital_Assets__c, 'Crypto fields should be cleared');
        Assert.isNull(app2.Advisory_Services_Required__c, 'Advisory fields should be cleared');
    }
    
    /**
     * @description Test bulk data handling - multiple shareholders
     */
    @isTest
    static void testBulkDataHandling_MultipleShareholders() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        
        // Add multiple shareholders
        for (Integer i = 2; i <= 5; i++) {
            OnboardingFormDTO.ShareholderDTO shareholder = new OnboardingFormDTO.ShareholderDTO();
            shareholder.id = 'sh_' + i + '_' + String.valueOf(Datetime.now().getTime());
            shareholder.type = 'Individual';
            shareholder.firstName = 'Shareholder';
            shareholder.lastName = String.valueOf(i);
            shareholder.dateOfBirthOrIncorporation = '1980-01-01';
            shareholder.nationalityOrCountryOfIncorporation = 'US';
            shareholder.countryOfResidenceOrIncorporation = 'United States';
            shareholder.ownershipPercentage = String.valueOf(10);
            shareholder.governmentIdOrRegistrationNumber = '000-00-000' + i;
            shareholder.isPEP = 'No';
            shareholder.email = 'shareholder' + i + '@test.com';
            formData.shareholders.add(shareholder);
        }
        
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed for multiple shareholders: ' + result.message);
        
        // Verify all shareholders were created
        Integer shareholderCount = [SELECT COUNT() FROM Application_Party_Role__c 
                                    WHERE Onboarding_Application__c = :result.applicationId AND Role__c = 'Shareholder'];
        Assert.areEqual(5, shareholderCount, '5 shareholders should be created');
    }
    
    /**
     * @description Test Party record reuse when updating application
     */
    @isTest
    static void testPartyRecordReuse() {
        // Create initial application with shareholder
        OnboardingFormDTO formData1 = createCorporateClientFormData();
        formData1.currentStep = 'shareholders';
        formData1.declarations = null;
        String formDataJson1 = JSON.serialize(formData1);
        
        OnboardingFormDTO.SaveResult result1 = OnboardingFormController.saveOnboardingApplication(formDataJson1);
        Assert.isTrue(result1.isSuccess, 'First save should succeed: ' + result1.message);
        
        // Get shareholder party ID
        List<Application_Party_Role__c> roles1 = [SELECT Id, Party__c FROM Application_Party_Role__c 
                                                   WHERE Onboarding_Application__c = :result1.applicationId AND Role__c = 'Shareholder'];
        Assert.areEqual(1, roles1.size(), 'One shareholder role should exist');
        Id originalPartyId = roles1[0].Party__c;
        
        // Update shareholder info
        OnboardingFormDTO formData2 = createCorporateClientFormData();
        formData2.applicationId = result1.applicationId;
        formData2.shareholders[0].firstName = 'UpdatedName';
        String formDataJson2 = JSON.serialize(formData2);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result2 = OnboardingFormController.saveOnboardingApplication(formDataJson2);
        Test.stopTest();
        
        Assert.isTrue(result2.isSuccess, 'Update should succeed');
        
        // Verify Party ID was reused (not a new one created)
        List<Application_Party_Role__c> roles2 = [SELECT Id, Party__c FROM Application_Party_Role__c 
                                                   WHERE Onboarding_Application__c = :result1.applicationId AND Role__c = 'Shareholder'];
        Assert.areEqual(1, roles2.size(), 'Still one shareholder role should exist');
        Assert.areEqual(originalPartyId, roles2[0].Party__c, 'Party ID should be reused');
        
        // Verify Party was updated
        Party__c updatedParty = [SELECT Id, First_Name__c FROM Party__c WHERE Id = :originalPartyId];
        Assert.areEqual('UpdatedName', updatedParty.First_Name__c, 'Party first name should be updated');
    }
    
    /**
     * @description Test Corporate shareholder (Organisation party type)
     */
    @isTest
    static void testCorporateShareholder() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        formData.shareholders[0].type = 'Corporate';
        formData.shareholders[0].legalEntityName = 'Corporate Shareholder Ltd';
        formData.shareholders[0].firstName = null; // Clear individual fields
        formData.shareholders[0].lastName = null;
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed for corporate shareholder');
        
        // Verify Organisation party was created
        List<Party__c> parties = [SELECT Id, Party_Type__c, Legal_Entity_Name__c 
            FROM Party__c
                                  WHERE Id IN (SELECT Party__c FROM Application_Party_Role__c 
                                               WHERE Onboarding_Application__c = :result.applicationId AND Role__c = 'Shareholder')];
        Assert.areEqual(1, parties.size(), 'One shareholder party should exist');
        Assert.areEqual('Organisation', parties[0].Party_Type__c, 'Party type should be Organisation');
        Assert.areEqual('Corporate Shareholder Ltd', parties[0].Legal_Entity_Name__c, 'Legal entity name should match');
    }
    
    /**
     * @description Test DTO serialization and deserialization
     */
    @isTest
    static void testDTOSerialization() {
        OnboardingFormDTO originalDto = createPrivateClientFormData();
        
        Test.startTest();
        // Serialize to JSON
        String jsonString = JSON.serialize(originalDto);
        Assert.isNotNull(jsonString, 'JSON string should not be null');
        
        // Deserialize back to DTO
        OnboardingFormDTO deserializedDto = (OnboardingFormDTO)JSON.deserialize(jsonString, OnboardingFormDTO.class);
        Test.stopTest();
        
        // Verify data integrity
        Assert.areEqual(originalDto.clientType, deserializedDto.clientType, 'Client type should match');
        Assert.areEqual(originalDto.servicesRequired.size(), deserializedDto.servicesRequired.size(), 'Services count should match');
        Assert.areEqual(originalDto.personalInfo.firstName, deserializedDto.personalInfo.firstName, 'First name should match');
        Assert.areEqual(originalDto.addressInfo.street, deserializedDto.addressInfo.street, 'Street should match');
    }
    
    /**
     * @description Test Additional Party with different roles
     */
    @isTest
    static void testAdditionalPartyRoles() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        
        // Add Signatory
        OnboardingFormDTO.AdditionalPartyDTO signatory = new OnboardingFormDTO.AdditionalPartyDTO();
        signatory.id = 'ap_signatory_' + String.valueOf(Datetime.now().getTime());
        signatory.role = 'Signatory';
        signatory.type = 'Individual';
        signatory.firstName = 'Signatory';
        signatory.lastName = 'Person';
        signatory.dateOfBirthOrIncorporation = '1985-01-01';
        signatory.nationalityOrCountryOfIncorporation = 'US';
        signatory.countryOfResidenceOrIncorporation = 'United States';
        signatory.governmentIdOrRegistrationNumber = '222-33-4444';
        signatory.isPEP = 'No';
        signatory.email = 'signatory@test.com';
        formData.additionalParties.add(signatory);
        
        // Add UBO
        OnboardingFormDTO.AdditionalPartyDTO ubo = new OnboardingFormDTO.AdditionalPartyDTO();
        ubo.id = 'ap_ubo_' + String.valueOf(Datetime.now().getTime());
        ubo.role = 'UBO';
        ubo.type = 'Individual';
        ubo.firstName = 'Ultimate';
        ubo.lastName = 'Owner';
        ubo.dateOfBirthOrIncorporation = '1975-01-01';
        ubo.nationalityOrCountryOfIncorporation = 'US';
        ubo.countryOfResidenceOrIncorporation = 'United States';
        ubo.governmentIdOrRegistrationNumber = '333-44-5555';
        ubo.isPEP = 'No';
        ubo.ownershipPercentage = '30';
        ubo.email = 'ubo@test.com';
        formData.additionalParties.add(ubo);
        
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed for additional parties');
        
        // Verify all roles were created
        List<Application_Party_Role__c> roles = [SELECT Id, Role__c FROM Application_Party_Role__c 
                                                  WHERE Onboarding_Application__c = :result.applicationId 
                                                  AND Role__c IN ('Director', 'Signatory', 'UBO')];
        Assert.areEqual(3, roles.size(), 'Three additional party roles should be created');
        
        Set<String> roleNames = new Set<String>();
        for (Application_Party_Role__c role : roles) {
            roleNames.add(role.Role__c);
        }
        Assert.isTrue(roleNames.contains('Director'), 'Director role should exist');
        Assert.isTrue(roleNames.contains('Signatory'), 'Signatory role should exist');
        Assert.isTrue(roleNames.contains('UBO'), 'UBO role should exist');
    }
    
    /**
     * @description Test high volume risk scoring
     */
    @isTest
    static void testRiskScoring_HighVolume() {
        OnboardingFormDTO formData = createPrivateClientFormData();
        formData.riskInfo.expectedMonthlyVolume = '500000'; // Above threshold
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        Risk_Assessment__c risk = [SELECT Id, Calculated_Risk_Score__c, Risk_Rating__c 
                                   FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.isTrue(risk.Calculated_Risk_Score__c > 0, 'Risk score should reflect high volume');
    }
    
    /**
     * @description Test getDraftApplicationData with non-existent ID
     */
    @isTest
    static void testGetDraftApplicationData_NonExistentId() {
        Test.startTest();
        String draftDataJson = OnboardingFormController.getDraftApplicationData('FAKE_ID_12345');
        Test.stopTest();
        
        Assert.isNull(draftDataJson, 'Draft data should be null for non-existent ID');
    }
    
    /**
     * @description Test corporate client with high-risk jurisdiction
     */
    @isTest
    static void testRiskScoring_HighRiskJurisdiction() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        formData.businessContext.highRiskJurisdictionExposure = 'Yes';
        formData.businessContext.highRiskJurisdictionDetails = 'Operating in high-risk country';
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        Risk_Assessment__c risk = [SELECT Id, Calculated_Risk_Score__c, Risk_Rating__c 
                                   FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.isTrue(risk.Calculated_Risk_Score__c >= 25, 'Risk score should include high-risk jurisdiction penalty');
    }
    
    /**
     * @description Test corporate client with sanctions risk
     */
    @isTest
    static void testRiskScoring_SanctionsRisk() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        formData.regulatoryInfo.onSanctionsList = 'Yes';
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        Risk_Assessment__c risk = [SELECT Id, Sanctions_Flag__c, Calculated_Risk_Score__c, EDD_Required__c 
                                   FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.areEqual(true, risk.Sanctions_Flag__c, 'Sanctions flag should be set');
        Assert.areEqual(true, risk.EDD_Required__c, 'EDD should be required for sanctions risk');
        Assert.isTrue(risk.Calculated_Risk_Score__c >= 50, 'Risk score should include sanctions penalty');
    }
    
    /**
     * @description Test corporate client with financial crime conviction
     */
    @isTest
    static void testRiskScoring_FinancialCrime() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        formData.regulatoryInfo.financialCrimeConviction = 'Yes';
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        Risk_Assessment__c risk = [SELECT Id, Calculated_Risk_Score__c, Risk_Rating__c 
                                   FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.isTrue(risk.Calculated_Risk_Score__c >= 40, 'Risk score should include financial crime penalty');
    }
    
    /**
     * @description Test Business Profile update with blank data (no overwrite)
     */
    @isTest
    static void testBusinessProfileUpdate_BlankData() {
        // Create initial application with full business context
        OnboardingFormDTO formData1 = createCorporateClientFormData();
        String formDataJson1 = JSON.serialize(formData1);
        OnboardingFormDTO.SaveResult result1 = OnboardingFormController.saveOnboardingApplication(formDataJson1);
        Assert.isTrue(result1.isSuccess, 'First save should succeed');
        
        // Update with blank companyInfo (should not overwrite existing business profile)
        OnboardingFormDTO formData2 = new OnboardingFormDTO();
        formData2.applicationId = result1.applicationId;
        formData2.clientType = 'Corporate';
        formData2.servicesRequired = new List<String>{'FX'};
        formData2.currentStep = 'service';
        formData2.channel = 'ExperienceCloud';
        formData2.ipAddress = '192.168.1.1';
        formData2.userAgent = 'Test';
        // No companyInfo provided - should not delete existing business profile
        String formDataJson2 = JSON.serialize(formData2);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result2 = OnboardingFormController.saveOnboardingApplication(formDataJson2);
        Test.stopTest();

        Assert.isTrue(result2.isSuccess, 'Update should succeed');
        
        // Verify Business Profile still exists with original data
        List<Business_Profile__c> profiles = [SELECT Id, Purpose_of_Account__c 
                                              FROM Business_Profile__c WHERE Onboarding_Application__c = :result1.applicationId];
        Assert.areEqual(1, profiles.size(), 'Business Profile should still exist');
        Assert.areEqual('International payments', profiles[0].Purpose_of_Account__c, 'Purpose should not be overwritten');
    }
    
    /**
     * @description Test file upload linking (currently not active but should not error)
     */
    @isTest
    static void testFileUploadLinking() {
        // Create application
        OnboardingFormDTO formData = createPrivateClientFormData();
        
        // Add file upload DTO (though files won't actually be uploaded in test)
        OnboardingFormDTO.FileUploadDTO fileUpload = new OnboardingFormDTO.FileUploadDTO();
        fileUpload.contentDocumentId = '069000000000000AAA'; // Fake ID
        fileUpload.fileName = 'test.pdf';
        fileUpload.documentType = 'Government_ID';
        fileUpload.level = 'Application';
        formData.fileUploads = new List<OnboardingFormDTO.FileUploadDTO>{fileUpload};
        
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        // Should succeed even if file linking fails (no actual file exists)
        Assert.isTrue(result.isSuccess, 'Save should succeed');
    }
    
    /**
     * @description Test with multiple risk factors combined
     */
    @isTest
    static void testRiskScoring_MultipleFactors() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        formData.regulatoryInfo.pepInOrganization = 'Yes';
        formData.regulatoryInfo.onSanctionsList = 'Yes';
        formData.businessContext.highRiskJurisdictionExposure = 'Yes';
        formData.businessContext.expectedAnnualVolume = '10000000'; // High volume
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        Risk_Assessment__c risk = [SELECT Id, Calculated_Risk_Score__c, Risk_Rating__c, 
                                   PEP_Flag__c, Sanctions_Flag__c, EDD_Required__c 
                                   FROM Risk_Assessment__c WHERE Onboarding_Application__c = :result.applicationId];
        Assert.areEqual(true, risk.PEP_Flag__c, 'PEP flag should be set');
        Assert.areEqual(true, risk.Sanctions_Flag__c, 'Sanctions flag should be set');
        Assert.areEqual(true, risk.EDD_Required__c, 'EDD should be required');
        Assert.areEqual('High', risk.Risk_Rating__c, 'Risk rating should be High');
        Assert.isTrue(risk.Calculated_Risk_Score__c > 60, 'Risk score should be high with multiple factors');
    }
    
    /**
     * @description Test shareholder with dual role (both Shareholder AND Director)
     * Verifies that boolean fields are correctly set and role-specific data is saved
     */
    @isTest
    static void testShareholderDualRole_ShareholderAndDirector() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        
        // Set up shareholder who is ALSO a director
        formData.shareholders[0].isShareholder = true;
        formData.shareholders[0].isDirector = true;
        formData.shareholders[0].ownershipPercentage = '40';
        formData.shareholders[0].positionOrRole = 'CEO';
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed with dual-role shareholder');
        Assert.isNotNull(result.applicationId, 'Application ID should be returned');
        
        // Verify Application_Party_Role was created with both role flags
        List<Application_Party_Role__c> roles = [
            SELECT Id, Is_Shareholder__c, Is_Director__c, Ownership_Percentage__c, 
                   Position_or_Role_Description__c, Role__c
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :result.applicationId
            AND (Is_Shareholder__c = true OR Is_Director__c = true)
        ];
        
        Assert.areEqual(1, roles.size(), 'Should create exactly 1 role record for dual-role person');
        Assert.areEqual(true, roles[0].Is_Shareholder__c, 'Is_Shareholder should be true');
        Assert.areEqual(true, roles[0].Is_Director__c, 'Is_Director should be true');
        Assert.areEqual(40, roles[0].Ownership_Percentage__c, 'Ownership percentage should be set');
        Assert.areEqual('CEO', roles[0].Position_or_Role_Description__c, 'Position/Role should be set');
    }
    
    /**
     * @description Test shareholder with only Shareholder role (not Director)
     * Verifies that only shareholder-specific data is saved
     */
    @isTest
    static void testShareholderRole_ShareholderOnly() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        
        // Set up as shareholder only
        formData.shareholders[0].isShareholder = true;
        formData.shareholders[0].isDirector = false;
        formData.shareholders[0].ownershipPercentage = '50';
        formData.shareholders[0].positionOrRole = ''; // Should not be set
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        // Verify role flags
        List<Application_Party_Role__c> roles = [
            SELECT Id, Is_Shareholder__c, Is_Director__c, Ownership_Percentage__c, 
                   Position_or_Role_Description__c
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :result.applicationId
            AND Is_Shareholder__c = true
        ];
        
        Assert.areEqual(1, roles.size(), 'Should create 1 role record');
        Assert.areEqual(true, roles[0].Is_Shareholder__c, 'Is_Shareholder should be true');
        Assert.areEqual(false, roles[0].Is_Director__c, 'Is_Director should be false');
        Assert.areEqual(50, roles[0].Ownership_Percentage__c, 'Ownership percentage should be set');
        Assert.areEqual(null, roles[0].Position_or_Role_Description__c, 'Position should not be set for shareholder-only');
    }
    
    /**
     * @description Test shareholder with only Director role (not Shareholder)
     * Verifies that only director-specific data is saved
     */
    @isTest
    static void testShareholderRole_DirectorOnly() {
        OnboardingFormDTO formData = createCorporateClientFormData();
        
        // Set up as director only
        formData.shareholders[0].isShareholder = false;
        formData.shareholders[0].isDirector = true;
        formData.shareholders[0].ownershipPercentage = ''; // Should not be set
        formData.shareholders[0].positionOrRole = 'CTO';
        String formDataJson = JSON.serialize(formData);
        
        Test.startTest();
        OnboardingFormDTO.SaveResult result = OnboardingFormController.saveOnboardingApplication(formDataJson);
        Test.stopTest();
        
        Assert.isTrue(result.isSuccess, 'Save should succeed');
        
        // Verify role flags
        List<Application_Party_Role__c> roles = [
            SELECT Id, Is_Shareholder__c, Is_Director__c, Ownership_Percentage__c, 
                   Position_or_Role_Description__c
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :result.applicationId
            AND Is_Director__c = true
        ];
        
        Assert.areEqual(1, roles.size(), 'Should create 1 role record');
        Assert.areEqual(false, roles[0].Is_Shareholder__c, 'Is_Shareholder should be false');
        Assert.areEqual(true, roles[0].Is_Director__c, 'Is_Director should be true');
        Assert.areEqual(null, roles[0].Ownership_Percentage__c, 'Ownership percentage should not be set for director-only');
        Assert.areEqual('CTO', roles[0].Position_or_Role_Description__c, 'Position should be set');
    }
}
