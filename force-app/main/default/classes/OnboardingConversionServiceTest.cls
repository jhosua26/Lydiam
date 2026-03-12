/**
 * @description Test class for OnboardingConversionService and OnboardingConversionController.
 *              Covers positive and negative scenarios for converting onboarding
 *              applications into Account and Contact records.
 *              Uses stub data to avoid dependency on external configuration.
 *
 * @Jhosua Arda
 * LinkedIn - https://www.linkedin.com/in/jhosua-arda/
 * @date 2026
 */
@isTest
private class OnboardingConversionServiceTest {

    // ──────────────────────────────────────────────
    //  TEST DATA BUILDERS
    // ──────────────────────────────────────────────

    private static final String CLIENT_CORPORATE = 'Corporate entity';
    private static final String CLIENT_PRIVATE = 'Private individual';

    private static Onboarding_Application__c createSubmittedApplication(String clientType, List<String> services) {
        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = clientType,
            Status__c = 'Submitted',
            Services_Required__c = String.join(services, ';'),
            Channel__c = 'ExperienceCloud',
            Client_Name__c = clientType == CLIENT_CORPORATE ? 'Test Corp Ltd' : 'John Doe'
        );
        insert app;
        return app;
    }

    private static Party__c createIndividualParty(String firstName, String lastName, String email) {
        Party__c party = new Party__c(
            Party_Type__c = 'Individual',
            First_Name__c = firstName,
            Middle_Name__c = 'Test',
            Last_Name__c = lastName,
            Full_Legal_Name__c = firstName + ' ' + lastName,
            Email__c = email,
            Phone__c = '+1234567890',
            Mobile__c = '+0987654321',
            Date_of_Birth__c = Date.newInstance(1990, 1, 15),
            Nationality__c = 'United States',
            Country_of_Residence__c = 'United States',
            Government_ID_Number__c = 'PP123456',
            Is_PEP__c = false,
            Source_of_Wealth__c = 'Employment',
            Source_of_Wealth_Explanation__c = 'Technology professional'
        );
        insert party;
        return party;
    }

    private static Party__c createCorporateParty(String entityName) {
        Party__c party = new Party__c(
            Party_Type__c = 'Corporate',
            Legal_Entity_Name__c = entityName,
            Full_Legal_Name__c = entityName,
            Legal_Entity_Type__c = 'Limited Company',
            Registration_Number__c = 'REG123456',
            Country_of_Incorporation__c = 'United States',
            Date_of_Incorporation__c = Date.newInstance(2020, 1, 1),
            Email__c = 'info@testcorp.com',
            Phone__c = '+1234567890',
            Website__c = 'https://testcorp.com'
        );
        insert party;
        return party;
    }

    private static Application_Party_Role__c createPartyRole(
        Id applicationId, Id partyId, String role, Boolean isPrimary
    ) {
        Application_Party_Role__c apr = new Application_Party_Role__c(
            Onboarding_Application__c = applicationId,
            Party__c = partyId,
            Role__c = role,
            Is_Primary__c = isPrimary
        );
        insert apr;
        return apr;
    }

    private static Party_Address__c createAddress(Id partyId) {
        Party_Address__c addr = new Party_Address__c(
            Party__c = partyId,
            Street__c = '123 Main St',
            City__c = 'New York',
            State__c = 'NY',
            Postal_Code__c = '10001',
            Country__c = 'United States',
            Address_Type__c = 'Residential',
            Is_Primary__c = true
        );
        insert addr;
        return addr;
    }

    private static Business_Profile__c createBusinessProfile(Id applicationId) {
        Business_Profile__c bp = new Business_Profile__c(
            Onboarding_Application__c = applicationId,
            Purpose_of_Account__c = 'International payments',
            Industry__c = 'Technology',
            Products_and_Services__c = 'SaaS platform',
            Payment_Flow_Types__c = '1st_to_1st;1st_to_3rd',
            Expected_Transactions_per_Month__c = 100,
            Expected_Annual_Volume__c = 1000000,
            Typical_Value_per_Transaction__c = 10000,
            Currencies_to_Send__c = 'USD;GBP',
            Currencies_to_Receive__c = 'EUR;JPY',
            Countries_Sent_To__c = 'United States;United Kingdom',
            Countries_Received_From__c = 'Germany;Japan',
            Largest_Single_Transaction__c = 50000,
            Primary_Source_of_Funds__c = 'Revenue from services',
            Source_of_Wealth_Explanation__c = 'Profits from SaaS business',
            Expected_Number_of_Employees__c = 50,
            Is_Regulated__c = true,
            Regulator_Name__c = 'SEC',
            Regulatory_Licence_Number__c = 'LIC-001',
            Regulatory_Jurisdiction__c = 'United States'
        );
        insert bp;
        return bp;
    }

    private static Risk_Assessment__c createRiskAssessment(Id applicationId, Boolean isPrivate) {
        Risk_Assessment__c ra = new Risk_Assessment__c(
            Onboarding_Application__c = applicationId,
            Risk_Rating__c = 'Low',
            Calculated_Risk_Score__c = 15,
            PEP_Flag__c = false,
            Sanctions_Flag__c = false,
            EDD_Required__c = true,
            EDD_Reason__c = 'High transaction volume',
            Additional_UBOs__c = 'No',
            On_Sanctions_List__c = 'No',
            Financial_Crime_Conviction__c = 'No',
            PEP_In_Organization__c = 'No',
            Provides_Money_Services__c = 'No'
        );
        if (isPrivate) {
            ra.Private_Expected_Monthly_Volume__c = 50000;
            ra.Private_Estimated_Transactions_per_Month__c = 10;
            ra.Private_Source_of_Wealth__c = 'Salary and Savings';
            ra.Private_Source_of_Wealth_Explanation__c = 'Accumulated from tech career';
            ra.Private_Geographic_Exposure__c = 'United States;Canada';
            ra.Private_Intended_Use_of_Account__c = 'Personal FX';
        }
        insert ra;
        return ra;
    }

    // ──────────────────────────────────────────────
    //  POSITIVE TESTS — SERVICE
    // ──────────────────────────────────────────────

    // @isTest
    // static void testConvert_CorporateClient_CreatesAccountAndContacts() {
    //     Onboarding_Application__c app = createSubmittedApplication(CLIENT_CORPORATE, new List<String>{'FX', 'Crypto'});
    //     Party__c corpParty = createCorporateParty('Test Corp Ltd');
    //     createPartyRole(app.Id, corpParty.Id, 'Applicant', true);
    //     createAddress(corpParty.Id);

    //     Party__c shareholderParty = createIndividualParty('Jane', 'Smith', 'jane@testcorp.com');
    //     Application_Party_Role__c shRole = createPartyRole(app.Id, shareholderParty.Id, 'Shareholder', false);
    //     shRole.Is_Shareholder__c = true;
    //     shRole.Ownership_Percentage__c = 60;
    //     update shRole;
    //     createAddress(shareholderParty.Id);

    //     createBusinessProfile(app.Id);
    //     createRiskAssessment(app.Id, false);

    //     Test.startTest();
    //     OnboardingConversionService service = new OnboardingConversionService();
    //     OnboardingConversionService.ConversionResult result = service.convert(app.Id);
    //     Test.stopTest();

    //     Assert.isTrue(result.isSuccess, 'Conversion should succeed: ' + result.message);
    //     Assert.isNotNull(result.accountId, 'Account Id should be populated');
    //     Assert.isFalse(result.contactIds.isEmpty(), 'At least one Contact should be created');

    //     Account acct = [SELECT Id, Name, RecordType.DeveloperName, Client_Type__c,
    //                            Onboarding_Application__c, Services_Required__c,
    //                            Legal_Entity_Type__c, Company_Registration_Number__c,
    //                            Country_of_Incorporation_or_Domicile__c, Nationality__c,
    //                            Date_of_Incorporation__c, Email_for_Notifications__c,
    //                            Source_of_Funds_Text__c, Source_of_Wealth_Explanation__c,
    //                            NumberOfEmployees,
    //                            BillingStreet, BillingCity, BillingCountry,
    //                            AnnualRevenue, Industry, Payment_Flow_Types__c,
    //                            Currencies_to_Send__c, Currencies_to_Receive__c,
    //                            Countries_Sent_To__c, Countries_Received_From__c,
    //                            Regulator_Name__c, Regulatory_Licence_Number__c,
    //                            EDD_Required__c, EDD_Reason__c
    //                     FROM Account WHERE Id = :result.accountId];

    //     Assert.areEqual('Corporate', acct.RecordType.DeveloperName, 'Should use Corporate record type');
    //     Assert.areEqual('Corporate entity', acct.Client_Type__c, 'Client type should be Corporate entity');
    //     Assert.areEqual('Test Corp Ltd', acct.Name, 'Account name should be entity name');
    //     Assert.areEqual(app.Id, acct.Onboarding_Application__c, 'Should link back to application');
    //     Assert.areEqual('Limited Company', acct.Legal_Entity_Type__c, 'Legal entity type should map directly');
    //     Assert.areEqual('REG123456', acct.Company_Registration_Number__c, 'Registration number should map');
    //     Assert.areEqual('United States', acct.Country_of_Incorporation_or_Domicile__c, 'Country of incorporation should map');
    //     Assert.areEqual(Date.newInstance(2020, 1, 1), acct.Date_of_Incorporation__c, 'Date of incorporation should map');
    //     Assert.areEqual('info@testcorp.com', acct.Email_for_Notifications__c, 'Email should map from Applicant Party');
    //     Assert.areEqual('Revenue from services', acct.Source_of_Funds_Text__c, 'Source of funds should map from Business Profile');
    //     Assert.areEqual('123 Main St', acct.BillingStreet, 'Billing address should be populated');
    //     Assert.areEqual(1000000, acct.AnnualRevenue, 'AnnualRevenue should map from Expected_Annual_Volume');
    //     Assert.areEqual('Technology', acct.Industry, 'Industry should map from Business Profile');
    //     Assert.isNotNull(acct.Currencies_to_Send__c, 'Currencies to send should be populated');
    //     Assert.areEqual('SEC', acct.Regulator_Name__c, 'Regulator name should map');
    //     Assert.isTrue(acct.EDD_Required__c, 'EDD Required should be true');

    //     Contact shareholderContact = [SELECT Id, FirstName, MiddleName, LastName, Nationality__c,
    //                                          Is_PEP__c, Ownership_Percentage__c, Source_of_Wealth__c,
    //                                          Source_of_Wealth_Explanation__c,
    //                                          MailingStreet, Onboarding_Application__c
    //                                   FROM Contact WHERE Id IN :result.contactIds
    //                                   AND FirstName = 'Jane' LIMIT 1];

    //     Assert.areEqual('Test', shareholderContact.MiddleName, 'Contact middle name should map');
    //     Assert.areEqual('Smith', shareholderContact.LastName, 'Contact last name should map');
    //     Assert.areEqual('United States', shareholderContact.Nationality__c, 'Nationality should map');
    //     Assert.areEqual(60, shareholderContact.Ownership_Percentage__c, 'Ownership % should map');
    //     Assert.areEqual('Employment', shareholderContact.Source_of_Wealth__c, 'Source of wealth should map from Party');
    //     Assert.areEqual('Technology professional', shareholderContact.Source_of_Wealth_Explanation__c, 'SOW explanation should map from Party');
    //     Assert.areEqual(app.Id, shareholderContact.Onboarding_Application__c, 'Contact should link to application');

    //     Onboarding_Application__c updatedApp = [SELECT Status__c FROM Onboarding_Application__c WHERE Id = :app.Id];
    //     Assert.areEqual('Converted', updatedApp.Status__c, 'Application status should be Converted');
    // }

    @isTest
    static void testConvert_PrivateClient_CreatesAccountAndContact() {
        Onboarding_Application__c app = createSubmittedApplication(CLIENT_PRIVATE, new List<String>{'FX'});
        Party__c individualParty = createIndividualParty('John', 'Doe', 'john@test.com');
        createPartyRole(app.Id, individualParty.Id, 'Applicant', true);
        createAddress(individualParty.Id);
        createRiskAssessment(app.Id, true);

        Test.startTest();
        OnboardingConversionService service = new OnboardingConversionService();
        OnboardingConversionService.ConversionResult result = service.convert(app.Id);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Conversion should succeed: ' + result.message);

        Account acct = [SELECT Id, Name, RecordType.DeveloperName, Client_Type__c,
                               Nationality__c, Geographic_Exposure__c,
                               Expected_Transactions_per_Month__c
                        FROM Account WHERE Id = :result.accountId];

        Assert.areEqual('Private_Individual', acct.RecordType.DeveloperName, 'Should use Private_Individual record type');
        Assert.areEqual('Private individual', acct.Client_Type__c, 'Client type should be Private individual');
        Assert.areEqual('John Test Doe', acct.Name, 'Account name should be full name');
        Assert.areEqual('United States;Canada', acct.Geographic_Exposure__c, 'Geographic exposure from risk assessment');
        Assert.areEqual(10, acct.Expected_Transactions_per_Month__c, 'Transactions per month from risk assessment');

        Contact primaryContact = [SELECT Id, FirstName, MiddleName, LastName,
                                         Source_of_Wealth__c, Source_of_Wealth_Explanation__c,
                                         Nationality__c
                                  FROM Contact WHERE Id IN :result.contactIds LIMIT 1];

        Assert.areEqual('Test', primaryContact.MiddleName, 'Contact middle name should map');
        Assert.areEqual('Doe', primaryContact.LastName, 'Contact last name should map');
        Assert.areEqual('Salary and Savings', primaryContact.Source_of_Wealth__c, 'Private client SOW should come from Risk Assessment');
        Assert.areEqual('Accumulated from tech career', primaryContact.Source_of_Wealth_Explanation__c, 'SOW explanation from Risk Assessment');

        Onboarding_Application__c updatedApp = [SELECT Status__c, Primary_Contact__c FROM Onboarding_Application__c WHERE Id = :app.Id];
        Assert.areEqual('Converted', updatedApp.Status__c, 'Status should be Converted');
        Assert.areEqual(primaryContact.Id, updatedApp.Primary_Contact__c, 'Primary contact should be set');
    }

    // @isTest
    // static void testConvert_WithServiceFields_MapsToAccount() {
    //     Onboarding_Application__c app = createSubmittedApplication(CLIENT_CORPORATE, new List<String>{'FX', 'Crypto', 'Advisory'});
    //     app.FX_Currency_Pairs__c = 'USD;GBP;EUR';
    //     app.FX_Forward_Contracts_Required__c = 'Yes';
    //     app.FX_Hedging_Needs__c = 'Currency Risk Hedging';
    //     app.Digital_Assets__c = 'BTC;ETH';
    //     app.Crypto_Expected_Monthly_Volume__c = 500000;
    //     app.Crypto_Average_Transaction_Size__c = 25000;
    //     app.Advisory_Services_Required__c = 'Market_Insights;Risk_Management';
    //     app.Investment_Objectives__c = 'Growth;Hedging';
    //     app.Time_Horizon_Years__c = 5;
    //     app.Existing_Advisory_Relationships__c = 'Goldman Sachs';
    //     update app;

    //     Party__c party = createCorporateParty('Service Corp');
    //     createPartyRole(app.Id, party.Id, 'Applicant', true);
    //     createBusinessProfile(app.Id);
    //     createRiskAssessment(app.Id, false);

    //     Test.startTest();
    //     OnboardingConversionService service = new OnboardingConversionService();
    //     OnboardingConversionService.ConversionResult result = service.convert(app.Id);
    //     Test.stopTest();

    //     Assert.isTrue(result.isSuccess, 'Conversion should succeed');

    //     Account acct = [SELECT FX_Currency_Pairs__c, FX_Forward_Contracts_Required__c,
    //                            FX_Hedging_Needs__c, Digital_Assets__c,
    //                            Crypto_Expected_Monthly_Volume__c, Crypto_Average_Transaction_Size__c,
    //                            Advisory_Services_Required__c, Investment_Objectives__c,
    //                            Time_Horizon_Years__c, Existing_Advisory_Relationships__c
    //                     FROM Account WHERE Id = :result.accountId];

    //     Assert.areEqual('USD;GBP;EUR', acct.FX_Currency_Pairs__c, 'FX currency pairs should map');
    //     Assert.areEqual('Yes', acct.FX_Forward_Contracts_Required__c, 'FX forward contracts should map');
    //     Assert.areEqual('BTC;ETH', acct.Digital_Assets__c, 'Digital assets should map');
    //     Assert.areEqual(500000, acct.Crypto_Expected_Monthly_Volume__c, 'Crypto volume should map');
    //     Assert.areEqual('Market_Insights;Risk_Management', acct.Advisory_Services_Required__c, 'Advisory services should map');
    //     Assert.areEqual(5, acct.Time_Horizon_Years__c, 'Time horizon should map');
    //     Assert.areEqual('Goldman Sachs', acct.Existing_Advisory_Relationships__c, 'Advisory relationships should map');
    // }

    // ──────────────────────────────────────────────
    //  IDEMPOTENCY TEST
    // ──────────────────────────────────────────────

    @isTest
    static void testConvert_AlreadyConverted_ReturnsExistingAccount() {
        Onboarding_Application__c app = createSubmittedApplication(CLIENT_PRIVATE, new List<String>{'FX'});
        Party__c party = createIndividualParty('Existing', 'User', 'existing@test.com');
        createPartyRole(app.Id, party.Id, 'Applicant', true);
        createRiskAssessment(app.Id, true);

        OnboardingConversionService service = new OnboardingConversionService();
        OnboardingConversionService.ConversionResult firstResult = service.convert(app.Id);

        Test.startTest();
        OnboardingConversionService.ConversionResult secondResult = service.convert(app.Id);
        Test.stopTest();

        Assert.isTrue(secondResult.isSuccess, 'Second conversion should succeed (idempotent)');
        Assert.areEqual(firstResult.accountId, secondResult.accountId, 'Should return the same Account');
        Assert.isTrue(secondResult.message.contains('already been converted'), 'Should indicate already converted');
    }

    // ──────────────────────────────────────────────
    //  NEGATIVE TESTS — SERVICE
    // ──────────────────────────────────────────────

    @isTest
    static void testConvert_NullApplicationId_ReturnsError() {
        OnboardingConversionService service = new OnboardingConversionService();
        OnboardingConversionService.ConversionResult result = service.convert(null);

        Assert.isFalse(result.isSuccess, 'Should fail with null Id');
        Assert.isTrue(result.message.contains('required'), 'Error should mention required');
    }

    @isTest
    static void testConvert_DraftStatus_ReturnsError() {
        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = CLIENT_CORPORATE,
            Status__c = 'Draft',
            Client_Name__c = 'Draft Corp'
        );
        insert app;

        OnboardingConversionService service = new OnboardingConversionService();

        Test.startTest();
        OnboardingConversionService.ConversionResult result = service.convert(app.Id);
        Test.stopTest();

        Assert.isFalse(result.isSuccess, 'Should fail for Draft status');
        Assert.isTrue(result.message.contains('Submitted'), 'Error should mention required status');
    }

    @isTest
    static void testConvert_NonExistentId_ReturnsError() {
        Id fakeId = Onboarding_Application__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001';

        OnboardingConversionService service = new OnboardingConversionService();

        Test.startTest();
        OnboardingConversionService.ConversionResult result = service.convert(fakeId);
        Test.stopTest();

        Assert.isFalse(result.isSuccess, 'Should fail for non-existent record');
    }

    // ──────────────────────────────────────────────
    //  CONTROLLER TESTS
    // ──────────────────────────────────────────────

    @isTest
    static void testCheckEligibility_Eligible() {
        Onboarding_Application__c app = createSubmittedApplication(CLIENT_CORPORATE, new List<String>{'FX'});

        Test.startTest();
        Map<String, Object> result = OnboardingConversionController.checkConversionEligibility(app.Id);
        Test.stopTest();

        Assert.areEqual(true, result.get('eligible'), 'Application should be eligible');
        Assert.areEqual('Corporate entity', result.get('clientType'), 'Client type should be returned');
    }

    @isTest
    static void testCheckEligibility_AlreadyConverted() {
        Onboarding_Application__c app = createSubmittedApplication(CLIENT_PRIVATE, new List<String>{'FX'});
        Account acct = new Account(
            Name = 'Already Converted',
            Onboarding_Application__c = app.Id
        );
        insert acct;

        Test.startTest();
        Map<String, Object> result = OnboardingConversionController.checkConversionEligibility(app.Id);
        Test.stopTest();

        Assert.areEqual(false, result.get('eligible'), 'Should not be eligible');
        Assert.areEqual(acct.Id, (Id) result.get('alreadyConvertedAccountId'), 'Should return existing Account Id');
    }

    @isTest
    static void testCheckEligibility_DraftStatus() {
        Onboarding_Application__c app = new Onboarding_Application__c(
            Client_Type__c = CLIENT_CORPORATE,
            Status__c = 'Draft',
            Client_Name__c = 'Draft Check'
        );
        insert app;

        Test.startTest();
        Map<String, Object> result = OnboardingConversionController.checkConversionEligibility(app.Id);
        Test.stopTest();

        Assert.areEqual(false, result.get('eligible'), 'Draft should not be eligible');
    }

    @isTest
    static void testCheckEligibility_NullId() {
        Test.startTest();
        Map<String, Object> result = OnboardingConversionController.checkConversionEligibility(null);
        Test.stopTest();

        Assert.areEqual(false, result.get('eligible'), 'Null Id should not be eligible');
    }

    @isTest
    static void testControllerConvert_DelegatesCorrectly() {
        Onboarding_Application__c app = createSubmittedApplication(CLIENT_PRIVATE, new List<String>{'FX'});
        Party__c party = createIndividualParty('Controller', 'Test', 'ctrl@test.com');
        createPartyRole(app.Id, party.Id, 'Applicant', true);
        createRiskAssessment(app.Id, true);

        Test.startTest();
        OnboardingConversionService.ConversionResult result =
            OnboardingConversionController.convertToAccountAndContacts(app.Id);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Controller conversion should succeed');
        Assert.isNotNull(result.accountId, 'Account Id should be populated');
    }

    // ──────────────────────────────────────────────
    //  MULTIPLE PARTIES TEST
    // ──────────────────────────────────────────────

    // @isTest
    // static void testConvert_MultipleParties_CreatesDistinctContacts() {
    //     Onboarding_Application__c app = createSubmittedApplication(CLIENT_CORPORATE, new List<String>{'FX'});
    //     Party__c corpParty = createCorporateParty('Multi Party Corp');
    //     createPartyRole(app.Id, corpParty.Id, 'Applicant', true);

    //     Party__c sh1 = createIndividualParty('Alice', 'First', 'alice@test.com');
    //     Application_Party_Role__c shRole1 = createPartyRole(app.Id, sh1.Id, 'Shareholder', false);
    //     shRole1.Is_Shareholder__c = true;
    //     shRole1.Ownership_Percentage__c = 40;
    //     update shRole1;

    //     Party__c sh2 = createIndividualParty('Bob', 'Second', 'bob@test.com');
    //     Application_Party_Role__c shRole2 = createPartyRole(app.Id, sh2.Id, 'Shareholder', false);
    //     shRole2.Is_Shareholder__c = true;
    //     shRole2.Ownership_Percentage__c = 35;
    //     update shRole2;

    //     Party__c dir = createIndividualParty('Charlie', 'Director', 'charlie@test.com');
    //     Application_Party_Role__c dirRole = createPartyRole(app.Id, dir.Id, 'Director', false);
    //     dirRole.Is_Director__c = true;
    //     update dirRole;

    //     createBusinessProfile(app.Id);
    //     createRiskAssessment(app.Id, false);

    //     Test.startTest();
    //     OnboardingConversionService service = new OnboardingConversionService();
    //     OnboardingConversionService.ConversionResult result = service.convert(app.Id);
    //     Test.stopTest();

    //     Assert.isTrue(result.isSuccess, 'Conversion should succeed');
    //     Assert.areEqual(3, result.contactIds.size(), 'Should create 3 individual contacts (excluding corporate party)');

    //     List<Contact> contacts = [SELECT FirstName, LastName, Ownership_Percentage__c
    //                               FROM Contact WHERE AccountId = :result.accountId ORDER BY FirstName];
    //     Assert.areEqual(3, contacts.size(), 'All 3 individual parties should become Contacts');
    // }

    // ──────────────────────────────────────────────
    //  SAME-AS-SHAREHOLDER DEDUP TEST
    // ──────────────────────────────────────────────

    // @isTest
    // static void testConvert_SameAsShareholder_CreatesSingleContact() {
    //     Onboarding_Application__c app = createSubmittedApplication(CLIENT_CORPORATE, new List<String>{'FX'});
    //     Party__c corpParty = createCorporateParty('Dedup Corp');
    //     createPartyRole(app.Id, corpParty.Id, 'Applicant', true);

    //     Party__c shParty = createIndividualParty('Jane', 'Smith', 'jane@dedup.com');
    //     Application_Party_Role__c shRole = createPartyRole(app.Id, shParty.Id, 'Shareholder', false);
    //     shRole.Is_Shareholder__c = true;
    //     shRole.Ownership_Percentage__c = 75;
    //     update shRole;

    //     // "Same as Shareholder" creates a SEPARATE Party__c record with identical data
    //     Party__c authParty = new Party__c(
    //         Party_Type__c = 'Individual',
    //         First_Name__c = 'Jane',
    //         Last_Name__c = 'Smith',
    //         Full_Legal_Name__c = 'Jane Smith',
    //         Email__c = 'jane@dedup.com',
    //         Phone__c = '+1234567890',
    //         Date_of_Birth__c = Date.newInstance(1990, 1, 15),
    //         Nationality__c = 'United States',
    //         Country_of_Residence__c = 'United States',
    //         Government_ID_Number__c = 'PP123456'
    //     );
    //     insert authParty;

    //     Application_Party_Role__c authRole = new Application_Party_Role__c(
    //         Onboarding_Application__c = app.Id,
    //         Party__c = authParty.Id,
    //         Role__c = 'Authorised_User',
    //         Is_Primary__c = false,
    //         Trade_Frequency__c = 'Weekly',
    //         Trading_Experience__c = 'Foreign Exchange'
    //     );
    //     insert authRole;

    //     createBusinessProfile(app.Id);
    //     createRiskAssessment(app.Id, false);

    //     Test.startTest();
    //     OnboardingConversionService service = new OnboardingConversionService();
    //     OnboardingConversionService.ConversionResult result = service.convert(app.Id);
    //     Test.stopTest();

    //     Assert.isTrue(result.isSuccess, 'Conversion should succeed');
    //     Assert.areEqual(1, result.contactIds.size(), 'Should create ONE Contact (not two) for the same person');

    //     Contact mergedContact = [SELECT FirstName, LastName, Contact_Type__c,
    //                                     Ownership_Percentage__c, Estimated_Trade_Frequency__c
    //                              FROM Contact WHERE Id = :result.contactIds[0]];

    //     Assert.areEqual('Jane', mergedContact.FirstName, 'Name should be from primary role');
    //     Assert.areEqual('Smith', mergedContact.LastName, 'Last name should map');
    //     Assert.isTrue(mergedContact.Contact_Type__c.contains('Shareholder'), 'Should include Shareholder role');
    //     Assert.isTrue(mergedContact.Contact_Type__c.contains('Authorised User'), 'Should include Authorised User role');
    //     Assert.areEqual(75, mergedContact.Ownership_Percentage__c, 'Ownership % should come from Shareholder role');
    //     Assert.areEqual('Weekly', mergedContact.Estimated_Trade_Frequency__c, 'Trade frequency should come from Auth User role');
    // }

    // ──────────────────────────────────────────────
    //  DOCUMENT LINKING TEST
    // ──────────────────────────────────────────────

    @isTest
    static void testConvert_LinksDocumentsToAccount() {
        Onboarding_Application__c app = createSubmittedApplication(CLIENT_PRIVATE, new List<String>{'FX'});
        Party__c party = createIndividualParty('Doc', 'Test', 'doc@test.com');
        createPartyRole(app.Id, party.Id, 'Applicant', true);
        createRiskAssessment(app.Id, true);

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        Document_Submission__c docSub = new Document_Submission__c(
            Onboarding_Application__c = app.Id,
            ContentDocumentId__c = String.valueOf(contentDocId),
            Document_Type__c = 'Passport'
        );
        insert docSub;

        Test.startTest();
        OnboardingConversionService service = new OnboardingConversionService();
        OnboardingConversionService.ConversionResult result = service.convert(app.Id);
        Test.stopTest();

        Assert.isTrue(result.isSuccess, 'Conversion should succeed');

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE LinkedEntityId = :result.accountId AND ContentDocumentId = :contentDocId
        ];
        Assert.areEqual(1, links.size(), 'Document should be linked to the new Account');
    }
}