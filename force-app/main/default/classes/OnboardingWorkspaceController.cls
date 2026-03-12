/**
 * @description Provides one-page onboarding workspace data and status actions
 *              for internal users reviewing Onboarding_Application__c records.
 */
public with sharing class OnboardingWorkspaceController {
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_IN_PROGRESS = 'In_Progress';
    private static final String STATUS_SUBMITTED = 'Submitted';
    private static final String STATUS_UNDER_REVIEW = 'Under_Review';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_REJECTED = 'Rejected';
    private static final String STATUS_CONVERTED = 'Converted';

    private static final String ACTION_START_REVIEW = 'START_REVIEW';
    private static final String ACTION_APPROVE = 'APPROVE';
    private static final String ACTION_REJECT = 'REJECT';
    private static final String ACTION_RETURN_TO_IN_PROGRESS = 'RETURN_TO_IN_PROGRESS';

    private static final String PROFILE_BROKER_MGMT = 'Lydiam Group Broker / Management';
    private static final String PROFILE_COMPLIANCE = 'Lydiam Group Compliance';
    private static final String PROFILE_SYS_ADMIN = 'System Administrator';

    public class WorkspaceData {
        @AuraEnabled public Id applicationId;
        @AuraEnabled public String applicationName;
        @AuraEnabled public String applicationUrl;
        @AuraEnabled public String clientName;
        @AuraEnabled public String clientType;
        @AuraEnabled public String status;
        @AuraEnabled public String servicesRequired;
        @AuraEnabled public Datetime submittedDate;
        @AuraEnabled public String channel;
        @AuraEnabled public String riskRating;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public Boolean eddRequired;
        @AuraEnabled public Boolean pepFlag;
        @AuraEnabled public Boolean sanctionsFlag;
        @AuraEnabled public Integer missingDocumentsCount;
        @AuraEnabled public Integer declarationAcceptedCount;
        @AuraEnabled public Integer declarationTotalCount;
        @AuraEnabled public Id convertedAccountId;
        @AuraEnabled public String convertedAccountName;
        @AuraEnabled public String convertedAccountUrl;
        @AuraEnabled public LinkInfo applicant;
        @AuraEnabled public LinkInfo businessProfile;
        @AuraEnabled public BusinessProfileDetails businessProfileDetails;
        @AuraEnabled public PrivateRiskDetails privateRiskDetails;
        @AuraEnabled public AddressDetails applicantAddress;
        @AuraEnabled public List<PartyRow> parties;
        @AuraEnabled public List<DeclarationRow> declarations;
        @AuraEnabled public List<DocumentRow> documents;
        @AuraEnabled public List<String> blockers;
        @AuraEnabled public ActionFlags actions;
    }

    public class LinkInfo {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String url;
    }

    public class BusinessProfileDetails {
        @AuraEnabled public String purposeOfAccount;
        @AuraEnabled public String industry;
        @AuraEnabled public String productsAndServices;
        @AuraEnabled public String paymentFlowTypes;
        @AuraEnabled public Decimal expectedTransactionsPerMonth;
        @AuraEnabled public Decimal expectedAnnualVolume;
        @AuraEnabled public Decimal typicalValuePerTransaction;
        @AuraEnabled public String currenciesToSend;
        @AuraEnabled public String currenciesToReceive;
        @AuraEnabled public String countriesSentTo;
        @AuraEnabled public String countriesReceivedFrom;
        @AuraEnabled public Decimal largestSingleTransaction;
        @AuraEnabled public String primarySourceOfFunds;
        @AuraEnabled public String sourceOfWealthExplanation;
        @AuraEnabled public Boolean isRegulated;
        @AuraEnabled public String regulatorName;
        @AuraEnabled public String regulatoryLicenceNumber;
        @AuraEnabled public String regulatoryJurisdiction;
    }

    public class AddressDetails {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String addressType;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public Boolean isPrimary;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String editUrl;
    }

    public class PrivateRiskDetails {
        @AuraEnabled public Decimal expectedMonthlyVolume;
        @AuraEnabled public Decimal estimatedTransactionsPerMonth;
        @AuraEnabled public String sourceOfWealth;
        @AuraEnabled public String sourceOfWealthExplanation;
        @AuraEnabled public String geographicExposure;
        @AuraEnabled public String intendedUseOfAccount;
    }

    public class PartyRow {
        @AuraEnabled public Id partyId;
        @AuraEnabled public String partyType;
        @AuraEnabled public String name;
        @AuraEnabled public String role;
        @AuraEnabled public String roleDescription;
        @AuraEnabled public Decimal ownershipPercentage;
        @AuraEnabled public Boolean isPep;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String partyEditUrl;
        @AuraEnabled public Id addressRecordId;
        @AuraEnabled public String addressRecordUrl;
        @AuraEnabled public String addressEditUrl;
        @AuraEnabled public Boolean hasAddress;
    }

    public class DeclarationRow {
        @AuraEnabled public Id declarationId;
        @AuraEnabled public String name;
        @AuraEnabled public String declarationType;
        @AuraEnabled public Boolean accepted;
        @AuraEnabled public String signatureName;
        @AuraEnabled public Datetime acceptedOn;
        @AuraEnabled public String recordUrl;
    }

    public class DocumentRow {
        @AuraEnabled public Id documentId;
        @AuraEnabled public String name;
        @AuraEnabled public String documentType;
        @AuraEnabled public String level;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isReceived;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String fileUrl;
        @AuraEnabled public String fileLabel;
    }

    public class ActionFlags {
        @AuraEnabled public Boolean showStartReview;
        @AuraEnabled public Boolean showApprove;
        @AuraEnabled public Boolean showReject;
        @AuraEnabled public Boolean showReturnToInProgress;
        @AuraEnabled public Boolean showConvert;
        @AuraEnabled public Boolean canViewSensitiveSections;
    }

    @AuraEnabled(cacheable=true)
    public static WorkspaceData getWorkspaceData(Id applicationId) {
        if (applicationId == null) {
            throw new AuraHandledException('Application Id is required.');
        }

        Onboarding_Application__c app = [
            SELECT Id, Name, Client_Name__c, Client_Type__c, Status__c, Services_Required__c,
                   Submitted_Date__c, Channel__c
            FROM Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        List<Application_Party_Role__c> partyRoles = [
            SELECT Id, Role__c, Position_or_Role_Description__c, Ownership_Percentage__c,
                   Is_Shareholder__c, Is_Director__c,
                   Party__c, Party__r.Full_Legal_Name__c, Party__r.Legal_Entity_Name__c,
                   Party__r.First_Name__c, Party__r.Middle_Name__c, Party__r.Last_Name__c,
                   Party__r.Is_PEP__c, Party__r.Email__c, Party__r.Phone__c, Party__r.Party_Type__c
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :applicationId
            ORDER BY Is_Primary__c DESC, CreatedDate ASC
        ];

        List<Declaration_Acceptance__c> declarationRecords = [
            SELECT Id, Name, Declaration_Type__c, Accepted__c, Signature_Name__c, Accepted_On__c
            FROM Declaration_Acceptance__c
            WHERE Onboarding_Application__c = :applicationId
            ORDER BY CreatedDate DESC
        ];

        List<Document_Submission__c> documentRecords = [
            SELECT Id, Name, Document_Type__c, Level__c, Is_Required__c, Is_Received__c, ContentDocumentId__c
            FROM Document_Submission__c
            WHERE Onboarding_Application__c = :applicationId
            ORDER BY CreatedDate DESC
        ];

        List<Business_Profile__c> businessProfiles = [
            SELECT Id, Name, Purpose_of_Account__c, Industry__c, Products_and_Services__c,
                   Payment_Flow_Types__c, Expected_Transactions_per_Month__c,
                   Expected_Annual_Volume__c, Typical_Value_per_Transaction__c,
                   Currencies_to_Send__c, Currencies_to_Receive__c,
                   Countries_Sent_To__c, Countries_Received_From__c, Largest_Single_Transaction__c,
                   Primary_Source_of_Funds__c, Source_of_Wealth_Explanation__c,
                   Is_Regulated__c, Regulator_Name__c, Regulatory_Licence_Number__c, Regulatory_Jurisdiction__c
            FROM Business_Profile__c
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];

        Set<Id> partyIds = new Set<Id>();
        for (Application_Party_Role__c role : partyRoles) {
            if (role.Party__c != null) {
                partyIds.add(role.Party__c);
            }
        }
        Map<Id, Party_Address__c> primaryAddressByPartyId = buildPrimaryAddressByPartyId(partyIds);

        Id applicantPartyId = getApplicantPartyId(partyRoles);
        List<Party_Address__c> applicantAddresses = new List<Party_Address__c>();
        if (applicantPartyId != null) {
            applicantAddresses = [
                SELECT Id, Address_Type__c, Street__c, City__c, State__c, Postal_Code__c, Country__c, Is_Primary__c
                FROM Party_Address__c
                WHERE Party__c = :applicantPartyId
                ORDER BY Is_Primary__c DESC NULLS LAST, CreatedDate DESC
                LIMIT 1
            ];
        }

        List<Risk_Assessment__c> riskAssessments = [
            SELECT Id, Risk_Rating__c, Calculated_Risk_Score__c, EDD_Required__c, PEP_Flag__c, Sanctions_Flag__c,
                   Private_Expected_Monthly_Volume__c, Private_Estimated_Transactions_per_Month__c,
                   Private_Source_of_Wealth__c, Private_Source_of_Wealth_Explanation__c,
                   Private_Geographic_Exposure__c, Private_Intended_Use_of_Account__c
            FROM Risk_Assessment__c
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];

        List<Account> convertedAccounts = [
            SELECT Id, Name
            FROM Account
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];

        WorkspaceData data = new WorkspaceData();
        data.applicationId = app.Id;
        data.applicationName = app.Name;
        data.applicationUrl = getRecordUrl('Onboarding_Application__c', app.Id);
        data.clientName = app.Client_Name__c;
        data.clientType = app.Client_Type__c;
        data.status = app.Status__c;
        data.servicesRequired = app.Services_Required__c;
        data.submittedDate = app.Submitted_Date__c;
        data.channel = app.Channel__c;
        data.parties = buildParties(partyRoles, primaryAddressByPartyId);
        data.declarations = buildDeclarations(declarationRecords);
        data.documents = buildDocuments(documentRecords);
        data.blockers = new List<String>();
        data.actions = getActionFlagsForStatus(app.Status__c);

        Integer missingDocs = 0;
        for (Document_Submission__c doc : documentRecords) {
            if (doc.Is_Required__c == true && doc.Is_Received__c != true) {
                missingDocs++;
            }
        }
        data.missingDocumentsCount = missingDocs;

        Integer acceptedDeclarations = 0;
        for (Declaration_Acceptance__c decl : declarationRecords) {
            if (decl.Accepted__c == true) {
                acceptedDeclarations++;
            }
        }
        data.declarationAcceptedCount = acceptedDeclarations;
        data.declarationTotalCount = declarationRecords.size();

        if (!riskAssessments.isEmpty()) {
            Risk_Assessment__c risk = riskAssessments[0];
            data.riskRating = risk.Risk_Rating__c;
            data.riskScore = risk.Calculated_Risk_Score__c;
            data.eddRequired = risk.EDD_Required__c;
            data.pepFlag = risk.PEP_Flag__c;
            data.sanctionsFlag = risk.Sanctions_Flag__c;
            data.privateRiskDetails = isPrivateClientType(data.clientType) ? toPrivateRiskDetails(risk) : null;
        }

        data.applicant = getApplicantLink(partyRoles);
        data.businessProfile = businessProfiles.isEmpty() ? null : toLinkInfo('Business_Profile__c', businessProfiles[0].Id, businessProfiles[0].Name);
        data.businessProfileDetails = businessProfiles.isEmpty() ? null : toBusinessProfileDetails(businessProfiles[0]);
        data.applicantAddress = applicantAddresses.isEmpty() ? null : toAddressDetails(applicantAddresses[0]);

        if (!convertedAccounts.isEmpty()) {
            data.convertedAccountId = convertedAccounts[0].Id;
            data.convertedAccountName = convertedAccounts[0].Name;
            data.convertedAccountUrl = getRecordUrl('Account', convertedAccounts[0].Id);
        }

        applyBlockers(data);
        return data;
    }

    @AuraEnabled
    public static WorkspaceData getWorkspaceDataForRefresh(Id applicationId) {
        return getWorkspaceData(applicationId);
    }

    @AuraEnabled
    public static WorkspaceData executeStatusAction(Id applicationId, String actionName) {
        if (applicationId == null) {
            throw new AuraHandledException('Application Id is required.');
        }
        if (String.isBlank(actionName)) {
            throw new AuraHandledException('Action name is required.');
        }

        Onboarding_Application__c app = [
            SELECT Id, Status__c
            FROM Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
            FOR UPDATE
        ];

        String nextStatus = getNextStatus(actionName, app.Status__c);
        validateActionAuthorization(actionName);

        app.Status__c = nextStatus;
        update app;

        return getWorkspaceData(applicationId);
    }

    @AuraEnabled
    public static WorkspaceData updateStatusFromPath(Id applicationId, String targetStatus) {
        if (applicationId == null) {
            throw new AuraHandledException('Application Id is required.');
        }

        String resolvedTargetStatus = normalizeTargetStatus(targetStatus);
        validatePathUpdateAuthorization();

        Onboarding_Application__c app = [
            SELECT Id, Status__c
            FROM Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
            FOR UPDATE
        ];

        if (app.Status__c == resolvedTargetStatus) {
            return getWorkspaceData(applicationId);
        }

        validatePathTransition(app.Status__c, resolvedTargetStatus);
        app.Status__c = resolvedTargetStatus;
        update app;

        return getWorkspaceData(applicationId);
    }

    @AuraEnabled
    public static void registerPartyDocumentUploads(
        Id applicationId,
        Id partyId,
        String documentType,
        List<String> contentDocumentIds
    ) {
        if (applicationId == null) {
            throw new AuraHandledException('Application Id is required.');
        }
        if (partyId == null) {
            throw new AuraHandledException('Party Id is required.');
        }
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('At least one uploaded file is required.');
        }

        String normalizedDocumentType = String.isBlank(documentType) ? 'Party_Document' : documentType.trim();
        Set<String> contentDocIdSet = new Set<String>();
        for (String contentDocumentId : contentDocumentIds) {
            if (String.isNotBlank(contentDocumentId)) {
                contentDocIdSet.add(contentDocumentId.trim());
            }
        }
        if (contentDocIdSet.isEmpty()) {
            throw new AuraHandledException('Uploaded file identifiers are invalid.');
        }

        Map<String, Document_Submission__c> existingByContentDocId = new Map<String, Document_Submission__c>();
        for (Document_Submission__c existingDoc : [
            SELECT Id, ContentDocumentId__c
            FROM Document_Submission__c
            WHERE Onboarding_Application__c = :applicationId
            AND Related_Party__c = :partyId
            AND ContentDocumentId__c IN :contentDocIdSet
        ]) {
            if (String.isNotBlank(existingDoc.ContentDocumentId__c)) {
                existingByContentDocId.put(existingDoc.ContentDocumentId__c, existingDoc);
            }
        }

        List<Document_Submission__c> docsToInsert = new List<Document_Submission__c>();
        List<Document_Submission__c> docsToUpdate = new List<Document_Submission__c>();
        for (String contentDocId : contentDocIdSet) {
            if (existingByContentDocId.containsKey(contentDocId)) {
                Document_Submission__c existingDoc = existingByContentDocId.get(contentDocId);
                existingDoc.Is_Received__c = true;
                if (String.isBlank(existingDoc.Document_Type__c)) {
                    existingDoc.Document_Type__c = normalizedDocumentType;
                }
                if (String.isBlank(existingDoc.Level__c)) {
                    existingDoc.Level__c = 'Party';
                }
                docsToUpdate.add(existingDoc);
            } else {
                Document_Submission__c newDoc = new Document_Submission__c();
                newDoc.Onboarding_Application__c = applicationId;
                newDoc.Related_Party__c = partyId;
                newDoc.Document_Type__c = normalizedDocumentType;
                newDoc.Level__c = 'Party';
                newDoc.Is_Required__c = false;
                newDoc.Is_Received__c = true;
                newDoc.ContentDocumentId__c = contentDocId;
                docsToInsert.add(newDoc);
            }
        }

        if (!docsToInsert.isEmpty()) {
            insert docsToInsert;
        }
        if (!docsToUpdate.isEmpty()) {
            update docsToUpdate;
        }
    }

    private static List<PartyRow> buildParties(List<Application_Party_Role__c> partyRoles, Map<Id, Party_Address__c> primaryAddressByPartyId) {
        List<PartyRow> rows = new List<PartyRow>();
        for (Application_Party_Role__c role : partyRoles) {
            if (role.Party__c == null || role.Party__r == null) {
                continue;
            }
            PartyRow row = new PartyRow();
            row.partyId = role.Party__c;
            row.partyType = role.Party__r.Party_Type__c;
            row.name = resolvePartyDisplayName(role.Party__r);
            row.role = role.Role__c;
            row.roleDescription = role.Position_or_Role_Description__c;
            row.ownershipPercentage = role.Ownership_Percentage__c;
            row.isPep = role.Party__r.Is_PEP__c;
            row.email = role.Party__r.Email__c;
            row.phone = role.Party__r.Phone__c;
            row.recordUrl = getRecordUrl('Party__c', role.Party__c);
            row.partyEditUrl = getRecordEditUrl('Party__c', role.Party__c);
            Party_Address__c primaryAddress = primaryAddressByPartyId != null ? primaryAddressByPartyId.get(role.Party__c) : null;
            if (primaryAddress != null) {
                row.addressRecordId = primaryAddress.Id;
                row.addressRecordUrl = getRecordUrl('Party_Address__c', primaryAddress.Id);
                row.addressEditUrl = getRecordEditUrl('Party_Address__c', primaryAddress.Id);
                row.hasAddress = true;
            } else {
                row.addressRecordId = null;
                row.addressRecordUrl = null;
                row.addressEditUrl = null;
                row.hasAddress = false;
            }
            rows.add(row);
        }
        return rows;
    }

    private static Map<Id, Party_Address__c> buildPrimaryAddressByPartyId(Set<Id> partyIds) {
        Map<Id, Party_Address__c> addressByPartyId = new Map<Id, Party_Address__c>();
        if (partyIds == null || partyIds.isEmpty()) {
            return addressByPartyId;
        }
        for (Party_Address__c addressRecord : [
            SELECT Id, Party__c, Is_Primary__c
            FROM Party_Address__c
            WHERE Party__c IN :partyIds
            ORDER BY Is_Primary__c DESC NULLS LAST, CreatedDate DESC
        ]) {
            if (!addressByPartyId.containsKey(addressRecord.Party__c)) {
                addressByPartyId.put(addressRecord.Party__c, addressRecord);
            }
        }
        return addressByPartyId;
    }

    private static List<DeclarationRow> buildDeclarations(List<Declaration_Acceptance__c> records) {
        List<DeclarationRow> rows = new List<DeclarationRow>();
        for (Declaration_Acceptance__c decl : records) {
            DeclarationRow row = new DeclarationRow();
            row.declarationId = decl.Id;
            row.name = decl.Name;
            row.declarationType = decl.Declaration_Type__c;
            row.accepted = decl.Accepted__c;
            row.signatureName = decl.Signature_Name__c;
            row.acceptedOn = decl.Accepted_On__c;
            row.recordUrl = getRecordUrl('Declaration_Acceptance__c', decl.Id);
            rows.add(row);
        }
        return rows;
    }

    private static List<DocumentRow> buildDocuments(List<Document_Submission__c> records) {
        List<DocumentRow> rows = new List<DocumentRow>();
        for (Document_Submission__c doc : records) {
            DocumentRow row = new DocumentRow();
            row.documentId = doc.Id;
            row.name = doc.Name;
            row.documentType = doc.Document_Type__c;
            row.level = doc.Level__c;
            row.isRequired = doc.Is_Required__c;
            row.isReceived = doc.Is_Received__c;
            row.recordUrl = getRecordUrl('Document_Submission__c', doc.Id);
            if (String.isNotBlank(doc.ContentDocumentId__c)) {
                row.fileUrl = getRecordUrl('ContentDocument', doc.ContentDocumentId__c);
                row.fileLabel = 'View File';
            } else {
                row.fileUrl = null;
                row.fileLabel = '';
            }
            rows.add(row);
        }
        return rows;
    }

    private static LinkInfo getApplicantLink(List<Application_Party_Role__c> partyRoles) {
        for (Application_Party_Role__c role : partyRoles) {
            if (role.Role__c == 'Applicant' && role.Party__c != null && role.Party__r != null) {
                return toLinkInfo('Party__c', role.Party__c, resolvePartyDisplayName(role.Party__r));
            }
        }
        return null;
    }

    private static Id getApplicantPartyId(List<Application_Party_Role__c> partyRoles) {
        for (Application_Party_Role__c role : partyRoles) {
            if (role.Role__c == 'Applicant' && role.Party__c != null) {
                return role.Party__c;
            }
        }
        return null;
    }

    private static BusinessProfileDetails toBusinessProfileDetails(Business_Profile__c businessProfileRecord) {
        if (businessProfileRecord == null) {
            return null;
        }
        BusinessProfileDetails details = new BusinessProfileDetails();
        details.purposeOfAccount = businessProfileRecord.Purpose_of_Account__c;
        details.industry = businessProfileRecord.Industry__c;
        details.productsAndServices = businessProfileRecord.Products_and_Services__c;
        details.paymentFlowTypes = businessProfileRecord.Payment_Flow_Types__c;
        details.expectedTransactionsPerMonth = businessProfileRecord.Expected_Transactions_per_Month__c;
        details.expectedAnnualVolume = businessProfileRecord.Expected_Annual_Volume__c;
        details.typicalValuePerTransaction = businessProfileRecord.Typical_Value_per_Transaction__c;
        details.currenciesToSend = businessProfileRecord.Currencies_to_Send__c;
        details.currenciesToReceive = businessProfileRecord.Currencies_to_Receive__c;
        details.countriesSentTo = businessProfileRecord.Countries_Sent_To__c;
        details.countriesReceivedFrom = businessProfileRecord.Countries_Received_From__c;
        details.largestSingleTransaction = businessProfileRecord.Largest_Single_Transaction__c;
        details.primarySourceOfFunds = businessProfileRecord.Primary_Source_of_Funds__c;
        details.sourceOfWealthExplanation = businessProfileRecord.Source_of_Wealth_Explanation__c;
        details.isRegulated = businessProfileRecord.Is_Regulated__c;
        details.regulatorName = businessProfileRecord.Regulator_Name__c;
        details.regulatoryLicenceNumber = businessProfileRecord.Regulatory_Licence_Number__c;
        details.regulatoryJurisdiction = businessProfileRecord.Regulatory_Jurisdiction__c;
        return details;
    }

    private static AddressDetails toAddressDetails(Party_Address__c addressRecord) {
        if (addressRecord == null) {
            return null;
        }
        AddressDetails details = new AddressDetails();
        details.recordId = addressRecord.Id;
        details.addressType = addressRecord.Address_Type__c;
        details.street = addressRecord.Street__c;
        details.city = addressRecord.City__c;
        details.state = addressRecord.State__c;
        details.postalCode = addressRecord.Postal_Code__c;
        details.country = addressRecord.Country__c;
        details.isPrimary = addressRecord.Is_Primary__c;
        details.recordUrl = getRecordUrl('Party_Address__c', addressRecord.Id);
        details.editUrl = getRecordEditUrl('Party_Address__c', addressRecord.Id);
        return details;
    }

    private static PrivateRiskDetails toPrivateRiskDetails(Risk_Assessment__c riskRecord) {
        if (riskRecord == null) {
            return null;
        }
        PrivateRiskDetails details = new PrivateRiskDetails();
        details.expectedMonthlyVolume = riskRecord.Private_Expected_Monthly_Volume__c;
        details.estimatedTransactionsPerMonth = riskRecord.Private_Estimated_Transactions_per_Month__c;
        details.sourceOfWealth = riskRecord.Private_Source_of_Wealth__c;
        details.sourceOfWealthExplanation = riskRecord.Private_Source_of_Wealth_Explanation__c;
        details.geographicExposure = riskRecord.Private_Geographic_Exposure__c;
        details.intendedUseOfAccount = riskRecord.Private_Intended_Use_of_Account__c;
        return details;
    }

    private static void applyBlockers(WorkspaceData data) {
        if (data == null) {
            return;
        }
        if (data.status == STATUS_UNDER_REVIEW && data.missingDocumentsCount > 0) {
            data.blockers.add('Missing required documents: ' + data.missingDocumentsCount);
        }
        if (data.declarationAcceptedCount == 0) {
            data.blockers.add('No accepted declarations found.');
        }
        if (data.status == STATUS_APPROVED && data.convertedAccountId == null) {
            data.blockers.add('Ready to convert: application is Approved but not converted yet.');
        }
    }

    private static ActionFlags getActionFlagsForStatus(String statusValue) {
        ActionFlags flags = new ActionFlags();
        String profileName = getCurrentUserProfileName();
        Boolean isSysAdmin = profileName == PROFILE_SYS_ADMIN;
        Boolean isCompliance = profileName == PROFILE_COMPLIANCE || isSysAdmin;
        Boolean isBrokerManagement = profileName == PROFILE_BROKER_MGMT || isSysAdmin;

        flags.showStartReview = (statusValue == STATUS_SUBMITTED) && isCompliance;
        flags.showApprove = (statusValue == STATUS_UNDER_REVIEW) && isCompliance;
        flags.showReject = (statusValue == STATUS_UNDER_REVIEW) && isCompliance;
        flags.showReturnToInProgress = (statusValue == STATUS_REJECTED) && (isCompliance || isBrokerManagement);
        flags.showConvert = (statusValue == STATUS_APPROVED) && (isCompliance || isBrokerManagement);
        flags.canViewSensitiveSections = isCompliance || isBrokerManagement || isSysAdmin;
        return flags;
    }

    private static String getNextStatus(String actionName, String currentStatus) {
        if (actionName == ACTION_START_REVIEW) {
            if (currentStatus != STATUS_SUBMITTED) {
                throw new AuraHandledException('Start Review is only allowed when status is Submitted.');
            }
            return STATUS_UNDER_REVIEW;
        }
        if (actionName == ACTION_APPROVE) {
            if (currentStatus != STATUS_UNDER_REVIEW) {
                throw new AuraHandledException('Approve is only allowed when status is Under Review.');
            }
            return STATUS_APPROVED;
        }
        if (actionName == ACTION_REJECT) {
            if (currentStatus != STATUS_UNDER_REVIEW) {
                throw new AuraHandledException('Reject is only allowed when status is Under Review.');
            }
            return STATUS_REJECTED;
        }
        if (actionName == ACTION_RETURN_TO_IN_PROGRESS) {
            if (currentStatus != STATUS_REJECTED) {
                throw new AuraHandledException('Return to In Progress is only allowed when status is Rejected.');
            }
            return STATUS_IN_PROGRESS;
        }
        throw new AuraHandledException('Unsupported action: ' + actionName);
    }

    private static String normalizeTargetStatus(String targetStatus) {
        if (String.isBlank(targetStatus)) {
            throw new AuraHandledException('Target status is required.');
        }

        Set<String> allowedStatuses = new Set<String>{
            STATUS_DRAFT,
            STATUS_IN_PROGRESS,
            STATUS_SUBMITTED,
            STATUS_UNDER_REVIEW,
            STATUS_APPROVED,
            STATUS_REJECTED
        };
        if (!allowedStatuses.contains(targetStatus)) {
            throw new AuraHandledException('Unsupported target status: ' + targetStatus);
        }

        return targetStatus;
    }

    private static void validatePathTransition(String currentStatus, String targetStatus) {
        Map<String, Set<String>> allowedTransitions = new Map<String, Set<String>>{
            STATUS_DRAFT => new Set<String>{ STATUS_IN_PROGRESS, STATUS_SUBMITTED },
            STATUS_IN_PROGRESS => new Set<String>{ STATUS_DRAFT, STATUS_SUBMITTED },
            STATUS_SUBMITTED => new Set<String>{ STATUS_IN_PROGRESS, STATUS_UNDER_REVIEW },
            STATUS_UNDER_REVIEW => new Set<String>{ STATUS_SUBMITTED, STATUS_APPROVED, STATUS_REJECTED },
            STATUS_APPROVED => new Set<String>{ STATUS_SUBMITTED, STATUS_UNDER_REVIEW },
            STATUS_REJECTED => new Set<String>{ STATUS_IN_PROGRESS, STATUS_UNDER_REVIEW }
        };

        Set<String> validTargets = allowedTransitions.get(currentStatus);
        if (validTargets == null || !validTargets.contains(targetStatus)) {
            throw new AuraHandledException(
                'Status transition not allowed from ' + currentStatus + ' to ' + targetStatus + '.'
            );
        }
    }

    private static void validateActionAuthorization(String actionName) {
        String profileName = getCurrentUserProfileName();
        Boolean isSysAdmin = profileName == PROFILE_SYS_ADMIN;
        Boolean isCompliance = profileName == PROFILE_COMPLIANCE || isSysAdmin;
        Boolean isBrokerManagement = profileName == PROFILE_BROKER_MGMT || isSysAdmin;

        if (actionName == ACTION_START_REVIEW || actionName == ACTION_APPROVE || actionName == ACTION_REJECT) {
            if (!isCompliance) {
                throw new AuraHandledException('You are not authorized to perform this action.');
            }
            return;
        }

        if (actionName == ACTION_RETURN_TO_IN_PROGRESS) {
            if (!(isCompliance || isBrokerManagement)) {
                throw new AuraHandledException('You are not authorized to perform this action.');
            }
        }
    }

    private static void validatePathUpdateAuthorization() {
        String profileName = getCurrentUserProfileName();
        Boolean isSysAdmin = profileName == PROFILE_SYS_ADMIN;
        Boolean isCompliance = profileName == PROFILE_COMPLIANCE || isSysAdmin;
        Boolean isBrokerManagement = profileName == PROFILE_BROKER_MGMT || isSysAdmin;
        if (!(isCompliance || isBrokerManagement)) {
            throw new AuraHandledException('You are not authorized to update application status.');
        }
    }

    private static String resolvePartyDisplayName(Party__c partyRecord) {
        if (partyRecord == null) {
            return null;
        }
        if (String.isNotBlank(partyRecord.Legal_Entity_Name__c)) {
            return partyRecord.Legal_Entity_Name__c;
        }
        if (String.isNotBlank(partyRecord.Full_Legal_Name__c)) {
            return partyRecord.Full_Legal_Name__c;
        }
        List<String> nameParts = new List<String>();
        if (String.isNotBlank(partyRecord.First_Name__c)) nameParts.add(partyRecord.First_Name__c);
        if (String.isNotBlank(partyRecord.Middle_Name__c)) nameParts.add(partyRecord.Middle_Name__c);
        if (String.isNotBlank(partyRecord.Last_Name__c)) nameParts.add(partyRecord.Last_Name__c);
        return nameParts.isEmpty() ? 'Party' : String.join(nameParts, ' ');
    }

    private static LinkInfo toLinkInfo(String objectApiName, Id recordId, String displayName) {
        if (recordId == null) {
            return null;
        }
        LinkInfo info = new LinkInfo();
        info.recordId = recordId;
        info.name = displayName;
        info.url = getRecordUrl(objectApiName, recordId);
        return info;
    }

    private static String getRecordUrl(String objectApiName, Id recordId) {
        if (recordId == null) {
            return null;
        }
        return '/lightning/r/' + objectApiName + '/' + recordId + '/view';
    }

    private static String getRecordEditUrl(String objectApiName, Id recordId) {
        if (recordId == null) {
            return null;
        }
        return '/lightning/r/' + objectApiName + '/' + recordId + '/edit';
    }

    private static Boolean isPrivateClientType(String clientTypeValue) {
        return String.isNotBlank(clientTypeValue) && clientTypeValue.toLowerCase().contains('private');
    }

    private static String getCurrentUserProfileName() {
        return [
            SELECT Name
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ].Name;
    }
}