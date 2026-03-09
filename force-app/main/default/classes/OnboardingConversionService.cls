/**
 * @description Service class that converts an Onboarding_Application__c record
 *              and its related child records into Account and Contact records.
 *              Follows Single Responsibility: each private method handles one mapping concern.
 *              Idempotent: re-running for the same application returns the existing Account.
 * 
 * @Jhosua Arda
 * LinkedIn - https://www.linkedin.com/in/jhosua-arda/
 * @date 2026
 */
public with sharing class OnboardingConversionService {

    private static final String STATUS_APPROVED = 'Approved';
    private static final String CLIENT_TYPE_CORPORATE = 'Corporate entity';
    private static final String CLIENT_TYPE_PRIVATE = 'Private individual';
    private static final String ROLE_APPLICANT = 'Applicant';
    private static final String ROLE_SHAREHOLDER = 'Shareholder';
    private static final String ROLE_DIRECTOR = 'Director';
    private static final String ROLE_UBO = 'UBO';
    private static final String ROLE_SIGNATORY = 'Signatory';
    private static final String ROLE_AUTHORIZED_USER = 'Authorised_User';
    private static final String PARTY_TYPE_INDIVIDUAL = 'Individual';

    /**
     * @description Result wrapper returned to the caller after conversion.
     */
    public class ConversionResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public Id accountId;
        @AuraEnabled public List<Id> contactIds;
        @AuraEnabled public String message;
        @AuraEnabled public List<String> errors;

        public ConversionResult() {
            this.contactIds = new List<Id>();
            this.errors = new List<String>();
        }
    }

    /**
     * @description Converts an Onboarding Application into Account + Contacts.
     * @param applicationId The Onboarding_Application__c record Id
     * @return ConversionResult with created record Ids or errors
     */
    public ConversionResult convert(Id applicationId) {
        ConversionResult result = new ConversionResult();

        try {
            validateInput(applicationId, result);
            if (!result.errors.isEmpty()) {
                result.isSuccess = false;
                result.message = String.join(result.errors, '; ');
                return result;
            }

            Onboarding_Application__c app = queryApplication(applicationId);

            Id existingAccountId = checkAlreadyConverted(applicationId);
            if (existingAccountId != null) {
                result.isSuccess = true;
                result.accountId = existingAccountId;
                result.message = 'This application has already been converted to Account: ' + existingAccountId;
                return result;
            }

            validateApplicationStatus(app, result);
            if (!result.errors.isEmpty()) {
                result.isSuccess = false;
                result.message = String.join(result.errors, '; ');
                return result;
            }

            List<Application_Party_Role__c> partyRoles = queryPartyRoles(applicationId);
            Map<Id, Party_Address__c> partyAddresses = queryPartyAddresses(partyRoles);
            Business_Profile__c businessProfile = queryBusinessProfile(applicationId);
            Risk_Assessment__c riskAssessment = queryRiskAssessment(applicationId);
            List<Document_Submission__c> documents = queryDocuments(applicationId);

            Boolean isCorporate = app.Client_Type__c == CLIENT_TYPE_CORPORATE;
            Id recordTypeId = getAccountRecordTypeId(isCorporate);

            Account acct = buildAccount(app, businessProfile, riskAssessment, partyRoles, partyAddresses, recordTypeId, isCorporate);
            insert acct;

            List<Contact> contacts = buildContacts(acct.Id, applicationId, partyRoles, partyAddresses, riskAssessment, isCorporate);
            if (!contacts.isEmpty()) {
                insert contacts;
                for (Contact c : contacts) {
                    result.contactIds.add(c.Id);
                }
            }

            linkDocumentsToAccount(acct.Id, applicationId, documents);

            updateApplicationAfterConversion(applicationId, acct.Id, contacts);

            result.isSuccess = true;
            result.accountId = acct.Id;
            result.message = 'Successfully converted to Account with ' + contacts.size() + ' Contact(s).';

        } catch (Exception ex) {
            result.isSuccess = false;
            result.errors.add(ex.getMessage());
            result.message = 'Conversion failed: ' + ex.getMessage();
        }

        return result;
    }

    // ──────────────────────────────────────────────
    //  VALIDATION
    // ──────────────────────────────────────────────

    private void validateInput(Id applicationId, ConversionResult result) {
        if (applicationId == null) {
            result.errors.add('Application Id is required.');
        }
    }

    private void validateApplicationStatus(Onboarding_Application__c app, ConversionResult result) {
        if (app == null) {
            result.errors.add('Onboarding Application record not found.');
            return;
        }
        if (app.Status__c != STATUS_APPROVED) {
            result.errors.add('Only applications with Status "Approved" can be converted. Current status: ' + app.Status__c);
        }
    }

    private Id checkAlreadyConverted(Id applicationId) {
        List<Account> existing = [
            SELECT Id FROM Account
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];
        return existing.isEmpty() ? null : existing[0].Id;
    }

    // ──────────────────────────────────────────────
    //  QUERIES
    // ──────────────────────────────────────────────

    private Onboarding_Application__c queryApplication(Id applicationId) {
        List<Onboarding_Application__c> apps = [
            SELECT Id, Client_Type__c, Services_Required__c, Channel__c, Status__c,
                   Client_Name__c, FX_Currency_Pairs__c, FX_Forward_Contracts_Required__c,
                   FX_Hedging_Needs__c, Digital_Assets__c, Crypto_Expected_Monthly_Volume__c,
                   Crypto_Average_Transaction_Size__c, Advisory_Services_Required__c,
                   Investment_Objectives__c, Time_Horizon_Years__c, Existing_Advisory_Relationships__c
            FROM Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];
        return apps.isEmpty() ? null : apps[0];
    }

    private List<Application_Party_Role__c> queryPartyRoles(Id applicationId) {
        return [
            SELECT Id, Role__c, Ownership_Percentage__c, Position_or_Role_Description__c,
                   Is_Shareholder__c, Is_Director__c, Is_Primary__c,
                   Trade_Frequency__c, Trading_Experience__c,
                   Party__c, Party__r.Id, Party__r.Party_Type__c, Party__r.Salutation__c,
                   Party__r.First_Name__c, Party__r.Middle_Name__c, Party__r.Last_Name__c,
                   Party__r.Full_Legal_Name__c, Party__r.Legal_Entity_Name__c,
                   Party__r.Legal_Entity_Type__c, Party__r.Email__c, Party__r.Phone__c,
                   Party__r.Mobile__c, Party__r.Date_of_Birth__c, Party__r.Date_of_Incorporation__c,
                   Party__r.Nationality__c, Party__r.Country_of_Residence__c,
                   Party__r.Country_of_Incorporation__c, Party__r.Registration_Number__c,
                   Party__r.Government_ID_Number__c, Party__r.Is_PEP__c,
                   Party__r.Source_of_Wealth__c, Party__r.Source_of_Wealth_Explanation__c,
                   Party__r.Website__c
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :applicationId
            ORDER BY Is_Primary__c DESC, Role__c ASC
        ];
    }

    private Map<Id, Party_Address__c> queryPartyAddresses(List<Application_Party_Role__c> partyRoles) {
        Set<Id> partyIds = new Set<Id>();
        for (Application_Party_Role__c apr : partyRoles) {
            if (apr.Party__c != null) {
                partyIds.add(apr.Party__c);
            }
        }

        Map<Id, Party_Address__c> addressMap = new Map<Id, Party_Address__c>();
        if (partyIds.isEmpty()) {
            return addressMap;
        }

        for (Party_Address__c addr : [
            SELECT Id, Party__c, Street__c, City__c, State__c, Postal_Code__c,
                   Country__c, Address_Type__c, Is_Primary__c
            FROM Party_Address__c
            WHERE Party__c IN :partyIds
            ORDER BY Is_Primary__c DESC NULLS LAST, CreatedDate DESC
        ]) {
            if (!addressMap.containsKey(addr.Party__c)) {
                addressMap.put(addr.Party__c, addr);
            }
        }
        return addressMap;
    }

    private Business_Profile__c queryBusinessProfile(Id applicationId) {
        List<Business_Profile__c> profiles = [
            SELECT Id, Purpose_of_Account__c, Industry__c, Products_and_Services__c,
                   Payment_Flow_Types__c, Expected_Transactions_per_Month__c,
                   Expected_Annual_Volume__c, Expected_Number_of_Employees__c,
                   Typical_Value_per_Transaction__c,
                   Currencies_to_Send__c, Currencies_to_Receive__c,
                   Countries_Sent_To__c, Countries_Received_From__c,
                   Largest_Single_Transaction__c, Primary_Source_of_Funds__c,
                   Source_of_Wealth_Explanation__c,
                   Regulator_Name__c, Regulatory_Licence_Number__c, Regulatory_Jurisdiction__c,
                   Is_Regulated__c
            FROM Business_Profile__c
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];
        return profiles.isEmpty() ? null : profiles[0];
    }

    private Risk_Assessment__c queryRiskAssessment(Id applicationId) {
        List<Risk_Assessment__c> assessments = [
            SELECT Id, Risk_Rating__c, Calculated_Risk_Score__c, PEP_Flag__c,
                   Sanctions_Flag__c, EDD_Required__c, EDD_Reason__c,
                   Private_Expected_Monthly_Volume__c, Private_Estimated_Transactions_per_Month__c,
                   Private_Source_of_Wealth__c, Private_Source_of_Wealth_Explanation__c,
                   Private_Geographic_Exposure__c, Private_Intended_Use_of_Account__c,
                   Additional_UBOs__c, On_Sanctions_List__c, Financial_Crime_Conviction__c,
                   PEP_In_Organization__c, Provides_Money_Services__c, Additional_Compliance_Notes__c
            FROM Risk_Assessment__c
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];
        return assessments.isEmpty() ? null : assessments[0];
    }

    private List<Document_Submission__c> queryDocuments(Id applicationId) {
        return [
            SELECT Id, ContentDocumentId__c, Document_Type__c
            FROM Document_Submission__c
            WHERE Onboarding_Application__c = :applicationId
        ];
    }

    // ──────────────────────────────────────────────
    //  ACCOUNT BUILDING
    // ──────────────────────────────────────────────

    private Id getAccountRecordTypeId(Boolean isCorporate) {
        String devName = isCorporate ? 'Corporate' : 'Private_Individual';
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(devName).getRecordTypeId();
    }

    private Account buildAccount(
        Onboarding_Application__c app,
        Business_Profile__c bp,
        Risk_Assessment__c ra,
        List<Application_Party_Role__c> partyRoles,
        Map<Id, Party_Address__c> partyAddresses,
        Id recordTypeId,
        Boolean isCorporate
    ) {
        Account acct = new Account();
        acct.RecordTypeId = recordTypeId;
        acct.Onboarding_Application__c = app.Id;
        acct.Client_Type__c = isCorporate ? 'Corporate entity' : 'Private individual';
        acct.Services_Required__c = app.Services_Required__c;
        acct.Onboarding_Channel__c = app.Channel__c;

        if (isCorporate) {
            populateCorporateAccountFields(acct, partyRoles, partyAddresses, bp);
        } else {
            populatePrivateAccountFields(acct, partyRoles, partyAddresses, ra);
        }

        populateBusinessProfileFields(acct, bp);
        populateRiskAssessmentFields(acct, ra, isCorporate);
        populateServiceFields(acct, app);

        return acct;
    }

    private void populateCorporateAccountFields(
        Account acct,
        List<Application_Party_Role__c> partyRoles,
        Map<Id, Party_Address__c> partyAddresses,
        Business_Profile__c bp
    ) {
        Application_Party_Role__c applicantRole = findPrimaryApplicant(partyRoles);
        if (applicantRole?.Party__r == null) {
            return;
        }

        Party__c applicant = applicantRole.Party__r;
        acct.Name = applicant.Legal_Entity_Name__c;
        acct.Legal_Entity_Type__c = applicant.Legal_Entity_Type__c;
        acct.Company_Registration_Number__c = applicant.Registration_Number__c;
        acct.Country_of_Incorporation_or_Domicile__c = applicant.Country_of_Incorporation__c;
        acct.Nationality__c = resolveRestrictedPicklistValue(
            applicant.Country_of_Incorporation__c, Account.Nationality__c
        );
        acct.Email_for_Notifications__c = applicant.Email__c;
        acct.Website = applicant.Website__c;
        acct.Phone = applicant.Phone__c;

        if (applicant.Date_of_Incorporation__c != null) {
            acct.Date_of_Incorporation__c = applicant.Date_of_Incorporation__c;
        }

        populateAccountAddress(acct, applicant.Id, partyAddresses);
    }

    private void populatePrivateAccountFields(
        Account acct,
        List<Application_Party_Role__c> partyRoles,
        Map<Id, Party_Address__c> partyAddresses,
        Risk_Assessment__c ra
    ) {
        Application_Party_Role__c applicantRole = findPrimaryApplicant(partyRoles);
        if (applicantRole?.Party__r == null) {
            return;
        }

        Party__c applicant = applicantRole.Party__r;
        String fullName = buildFullName(applicant);
        acct.Name = fullName;
        acct.Nationality__c = resolveRestrictedPicklistValue(
            applicant.Nationality__c, Account.Nationality__c
        );
        acct.Email_for_Notifications__c = applicant.Email__c;
        acct.Phone = applicant.Phone__c;
        acct.Website = applicant.Website__c;

        populateAccountAddress(acct, applicant.Id, partyAddresses);

        if (ra != null && String.isNotBlank(ra.Private_Geographic_Exposure__c)) {
            acct.Geographic_Exposure__c = ra.Private_Geographic_Exposure__c;
        }
    }

    private void populateAccountAddress(Account acct, Id partyId, Map<Id, Party_Address__c> partyAddresses) {
        Party_Address__c addr = partyAddresses.get(partyId);
        if (addr == null) {
            return;
        }
        acct.BillingStreet = addr.Street__c;
        acct.BillingCity = addr.City__c;
        acct.BillingState = addr.State__c;
        acct.BillingPostalCode = addr.Postal_Code__c;
        acct.BillingCountry = addr.Country__c;
    }

    private void populateBusinessProfileFields(Account acct, Business_Profile__c bp) {
        if (bp == null) {
            return;
        }
        acct.Description = bp.Purpose_of_Account__c;
        acct.Industry = bp.Industry__c;
        acct.AnnualRevenue = bp.Expected_Annual_Volume__c;
        acct.Payment_Flow_Types__c = bp.Payment_Flow_Types__c;
        acct.Source_of_Funds_Text__c = bp.Primary_Source_of_Funds__c;
        acct.Source_of_Wealth_Explanation__c = bp.Source_of_Wealth_Explanation__c;

        if (bp.Expected_Transactions_per_Month__c != null) {
            acct.Expected_Transactions_per_Month__c = bp.Expected_Transactions_per_Month__c.intValue();
        }
        if (bp.Expected_Number_of_Employees__c != null) {
            acct.NumberOfEmployees = bp.Expected_Number_of_Employees__c.intValue();
        }
        acct.Largest_Single_Transaction__c = bp.Largest_Single_Transaction__c;
        acct.Currencies_to_Send__c = bp.Currencies_to_Send__c;
        acct.Currencies_to_Receive__c = bp.Currencies_to_Receive__c;
        acct.Countries_Sent_To__c = bp.Countries_Sent_To__c;
        acct.Countries_Received_From__c = bp.Countries_Received_From__c;

        if (bp.Is_Regulated__c == true) {
            acct.Regulator_Name__c = bp.Regulator_Name__c;
            acct.Regulatory_Licence_Number__c = bp.Regulatory_Licence_Number__c;
            acct.Regulatory_Jurisdiction__c = bp.Regulatory_Jurisdiction__c;
        }
    }

    private void populateRiskAssessmentFields(Account acct, Risk_Assessment__c ra, Boolean isCorporate) {
        if (ra == null) {
            return;
        }
        acct.PEP_Flag__c = ra.PEP_Flag__c == true;
        acct.Sanctions_Flag__c = ra.Sanctions_Flag__c == true;
        acct.EDD_Required__c = ra.EDD_Required__c == true;
        acct.EDD_Reason__c = ra.EDD_Reason__c;

        if (!isCorporate && ra.Private_Estimated_Transactions_per_Month__c != null) {
            acct.Expected_Transactions_per_Month__c = ra.Private_Estimated_Transactions_per_Month__c.intValue();
        }
    }

    private void populateServiceFields(Account acct, Onboarding_Application__c app) {
        acct.FX_Currency_Pairs__c = app.FX_Currency_Pairs__c;
        acct.FX_Forward_Contracts_Required__c = app.FX_Forward_Contracts_Required__c;
        acct.FX_Hedging_Needs__c = app.FX_Hedging_Needs__c;
        acct.Digital_Assets__c = app.Digital_Assets__c;
        acct.Crypto_Expected_Monthly_Volume__c = app.Crypto_Expected_Monthly_Volume__c;
        acct.Crypto_Average_Transaction_Size__c = app.Crypto_Average_Transaction_Size__c;
        acct.Advisory_Services_Required__c = app.Advisory_Services_Required__c;
        acct.Investment_Objectives__c = app.Investment_Objectives__c;

        if (app.Time_Horizon_Years__c != null) {
            acct.Time_Horizon_Years__c = app.Time_Horizon_Years__c.intValue();
        }
        acct.Existing_Advisory_Relationships__c = app.Existing_Advisory_Relationships__c;
    }

    // ──────────────────────────────────────────────
    //  CONTACT BUILDING
    // ──────────────────────────────────────────────

    private List<Contact> buildContacts(
        Id accountId,
        Id applicationId,
        List<Application_Party_Role__c> partyRoles,
        Map<Id, Party_Address__c> partyAddresses,
        Risk_Assessment__c riskAssessment,
        Boolean isCorporate
    ) {
        // Group Party records that represent the same physical person.
        // "Same as Shareholder" authorised users create separate Party__c records
        // with different Ids but identical person data — dedup by identity key.
        Map<String, List<Application_Party_Role__c>> personGroups = new Map<String, List<Application_Party_Role__c>>();
        Map<String, Application_Party_Role__c> personPrimaryRole = new Map<String, Application_Party_Role__c>();

        for (Application_Party_Role__c apr : partyRoles) {
            if (apr.Party__c == null || apr.Party__r == null) {
                continue;
            }
            if (apr.Party__r.Party_Type__c != PARTY_TYPE_INDIVIDUAL && apr.Party__r.Party_Type__c != null) {
                continue;
            }

            String personKey = buildPersonIdentityKey(apr.Party__r);

            if (!personGroups.containsKey(personKey)) {
                personGroups.put(personKey, new List<Application_Party_Role__c>());
                personPrimaryRole.put(personKey, apr);
            }
            personGroups.get(personKey).add(apr);
        }

        List<Contact> contacts = new List<Contact>();
        for (String personKey : personGroups.keySet()) {
            Application_Party_Role__c primaryRole = personPrimaryRole.get(personKey);
            List<Application_Party_Role__c> personRoles = personGroups.get(personKey);

            Contact c = buildSingleContact(
                accountId, applicationId, primaryRole, personRoles,
                partyAddresses, riskAssessment, isCorporate
            );
            contacts.add(c);
        }
        return contacts;
    }

    /**
     * @description Builds a composite key to identify the same physical person
     *              across different Party__c records (e.g., "Same as Shareholder").
     */
    private String buildPersonIdentityKey(Party__c party) {
        String email = String.isNotBlank(party.Email__c) ? party.Email__c.toLowerCase().trim() : '';
        String lastName = String.isNotBlank(party.Last_Name__c) ? party.Last_Name__c.toLowerCase().trim() : '';
        String dob = party.Date_of_Birth__c != null ? String.valueOf(party.Date_of_Birth__c) : '';
        return email + '|' + lastName + '|' + dob;
    }

    private Contact buildSingleContact(
        Id accountId,
        Id applicationId,
        Application_Party_Role__c primaryRole,
        List<Application_Party_Role__c> personRoles,
        Map<Id, Party_Address__c> partyAddresses,
        Risk_Assessment__c riskAssessment,
        Boolean isCorporate
    ) {
        Party__c party = primaryRole.Party__r;
        Contact c = new Contact();
        c.AccountId = accountId;
        c.Onboarding_Application__c = applicationId;

        c.Salutation = party.Salutation__c;
        c.FirstName = party.First_Name__c;
        c.MiddleName = party.Middle_Name__c;
        c.LastName = String.isNotBlank(party.Last_Name__c) ? party.Last_Name__c : party.Full_Legal_Name__c;
        c.Email = party.Email__c;
        c.Phone = party.Phone__c;
        c.MobilePhone = party.Mobile__c;
        c.Birthdate = party.Date_of_Birth__c;
        c.Nationality__c = party.Nationality__c;
        c.ID_Number__c = party.Government_ID_Number__c;
        c.Is_PEP__c = party.Is_PEP__c == true;

        c.Contact_Type__c = resolveContactType(personRoles);
        c.Role__c = primaryRole.Position_or_Role_Description__c;

        populateOwnership(c, personRoles);
        populateContactTrading(c, personRoles);
        populateContactSourceOfWealth(c, party, riskAssessment, isCorporate, primaryRole.Role__c);
        populateContactAddress(c, party.Id, partyAddresses);

        return c;
    }

    private void populateOwnership(Contact c, List<Application_Party_Role__c> personRoles) {
        for (Application_Party_Role__c apr : personRoles) {
            if (apr.Ownership_Percentage__c != null) {
                c.Ownership_Percentage__c = apr.Ownership_Percentage__c;
                return;
            }
        }
    }

    private void populateContactTrading(Contact c, List<Application_Party_Role__c> personRoles) {
        for (Application_Party_Role__c apr : personRoles) {
            if (apr.Role__c == ROLE_AUTHORIZED_USER) {
                c.Estimated_Trade_Frequency__c = resolveRestrictedPicklistValue(
                    apr.Trade_Frequency__c, Contact.Estimated_Trade_Frequency__c
                );
                c.other_relevant_trading_experience__c = apr.Trading_Experience__c;
                return;
            }
        }
    }

    private void populateContactSourceOfWealth(
        Contact c,
        Party__c party,
        Risk_Assessment__c ra,
        Boolean isCorporate,
        String role
    ) {
        if (!isCorporate && role == ROLE_APPLICANT && ra != null) {
            c.Source_of_Wealth__c = ra.Private_Source_of_Wealth__c;
            c.Source_of_Wealth_Explanation__c = ra.Private_Source_of_Wealth_Explanation__c;
        } else {
            c.Source_of_Wealth__c = party.Source_of_Wealth__c;
            c.Source_of_Wealth_Explanation__c = party.Source_of_Wealth_Explanation__c;
        }
    }

    private void populateContactAddress(Contact c, Id partyId, Map<Id, Party_Address__c> partyAddresses) {
        Party_Address__c addr = partyAddresses.get(partyId);
        if (addr == null) {
            return;
        }
        c.MailingStreet = addr.Street__c;
        c.MailingCity = addr.City__c;
        c.MailingState = addr.State__c;
        c.MailingPostalCode = addr.Postal_Code__c;
        c.MailingCountry = addr.Country__c;
    }

    /**
     * @description Resolves combined contact type from all roles belonging to the same person.
     *              Handles "Same as Shareholder" where one person spans multiple Party__c records.
     */
    private String resolveContactType(List<Application_Party_Role__c> personRoles) {
        Set<String> roles = new Set<String>();
        for (Application_Party_Role__c apr : personRoles) {
            if (apr.Role__c == ROLE_APPLICANT) {
                roles.add('Applicant');
            }
            if (apr.Is_Shareholder__c == true || apr.Role__c == ROLE_SHAREHOLDER) {
                roles.add('Shareholder');
            }
            if (apr.Is_Director__c == true || apr.Role__c == ROLE_DIRECTOR) {
                roles.add('Director');
            }
            if (apr.Role__c == ROLE_UBO) {
                roles.add('UBO');
            }
            if (apr.Role__c == ROLE_SIGNATORY) {
                roles.add('Signatory');
            }
            if (apr.Role__c == ROLE_AUTHORIZED_USER) {
                roles.add('Authorised User');
            }
        }
        return roles.isEmpty() ? '' : String.join(new List<String>(roles), ';');
    }

    // ──────────────────────────────────────────────
    //  DOCUMENTS
    // ──────────────────────────────────────────────

    private void linkDocumentsToAccount(Id accountId, Id applicationId, List<Document_Submission__c> documents) {
        Set<Id> contentDocumentIds = new Set<Id>();
        for (Document_Submission__c doc : documents) {
            if (String.isNotBlank(doc.ContentDocumentId__c)) {
                try {
                    contentDocumentIds.add(Id.valueOf(doc.ContentDocumentId__c));
                } catch (Exception ex) {
                    // Skip invalid Content Document Ids
                }
            }
        }

        if (contentDocumentIds.isEmpty()) {
            return;
        }

        Set<Id> alreadyLinked = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId FROM ContentDocumentLink
            WHERE LinkedEntityId = :accountId AND ContentDocumentId IN :contentDocumentIds
        ]) {
            alreadyLinked.add(cdl.ContentDocumentId);
        }

        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        for (Id docId : contentDocumentIds) {
            if (alreadyLinked.contains(docId)) {
                continue;
            }
            newLinks.add(new ContentDocumentLink(
                ContentDocumentId = docId,
                LinkedEntityId = accountId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }

        if (!newLinks.isEmpty()) {
            insert newLinks;
        }
    }

    // ──────────────────────────────────────────────
    //  POST-CONVERSION UPDATE
    // ──────────────────────────────────────────────

    private void updateApplicationAfterConversion(Id applicationId, Id accountId, List<Contact> contacts) {
        Onboarding_Application__c app = new Onboarding_Application__c(
            Id = applicationId,
            Status__c = 'Converted'
        );

        if (!contacts.isEmpty()) {
            app.Primary_Contact__c = contacts[0].Id;
        }

        update app;
    }

    // ──────────────────────────────────────────────
    //  HELPERS
    // ──────────────────────────────────────────────

    private Application_Party_Role__c findPrimaryApplicant(List<Application_Party_Role__c> roles) {
        for (Application_Party_Role__c apr : roles) {
            if (apr.Role__c == ROLE_APPLICANT && apr.Is_Primary__c == true) {
                return apr;
            }
        }
        for (Application_Party_Role__c apr : roles) {
            if (apr.Role__c == ROLE_APPLICANT) {
                return apr;
            }
        }
        return roles.isEmpty() ? null : roles[0];
    }

    private String buildFullName(Party__c party) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(party.First_Name__c)) { parts.add(party.First_Name__c); }
        if (String.isNotBlank(party.Middle_Name__c)) { parts.add(party.Middle_Name__c); }
        if (String.isNotBlank(party.Last_Name__c)) { parts.add(party.Last_Name__c); }
        return parts.isEmpty() ? party.Full_Legal_Name__c : String.join(parts, ' ');
    }

    /**
     * @description Validates a value against a restricted picklist field's allowed values
     *              at runtime. Returns null if the value is not in the allowed set to
     *              prevent INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST errors.
     */
    private String resolveRestrictedPicklistValue(String value, Schema.SObjectField targetField) {
        if (String.isBlank(value)) {
            return null;
        }
        Set<String> allowedValues = new Set<String>();
        for (Schema.PicklistEntry entry : targetField.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                allowedValues.add(entry.getValue());
            }
        }
        return allowedValues.contains(value) ? value : null;
    }

}