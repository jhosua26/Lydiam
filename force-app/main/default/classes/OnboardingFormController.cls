/**
 * @description Controller class for Client Onboarding Form LWC
 * Provides picklist values and handles form data operations
 * Uses 'without sharing' to allow Guest Users to create and reference records
 * in the onboarding process without sharing rule restrictions
 */
public without sharing class OnboardingFormController {
    
    /**
     * @description Gets picklist values for Countries_which_funds_transfers_are_expe__c field from Opportunity
     * @return List<PicklistOption> List of picklist options with label and value
     */
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getCountryPicklistValues() {
        List<PicklistOption> options = new List<PicklistOption>();
        
        try {
            Schema.DescribeFieldResult fieldResult = Opportunity.Countries_which_funds_transfers_are_expe__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving country picklist values: ' + e.getMessage());
        }
        
        return options;
    }

    /**
     * @description Searches for addresses using a geocoding service
     * @param searchQuery The address search query
     * @return List<AddressResult> List of address suggestions
     */
    public class AddressResult {
        @AuraEnabled public String formattedAddress;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String placeId;
    }

    @AuraEnabled
    public static List<AddressResult> searchAddress(String searchQuery) {
        List<AddressResult> results = new List<AddressResult>();
        
        if (String.isBlank(searchQuery) || searchQuery.length() < 3) {
            return results;
        }
        
        try {
            // Note: This is a placeholder implementation
            // In production, you would integrate with Google Places API, HERE Maps, or another geocoding service
            // For now, this returns an empty list - you'll need to add your API integration
            
            // Example structure for Google Places API integration:
            // HttpRequest req = new HttpRequest();
            // req.setEndpoint('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=' + 
            //                 EncodingUtil.urlEncode(searchQuery, 'UTF-8') + '&key=YOUR_API_KEY');
            // req.setMethod('GET');
            // Http http = new Http();
            // HttpResponse res = http.send(req);
            // Parse JSON response and populate AddressResult objects
            
        } catch (Exception e) {
            throw new AuraHandledException('Error searching address: ' + e.getMessage());
        }
        
        return results;
    }

    /**
     * @description Retrieves draft application data for editing/resuming
     * @param applicationId The Onboarding_Application__c record ID
     * @return String JSON string of OnboardingFormDTO with existing data
     */
    @AuraEnabled
    public static String getDraftApplicationData(String applicationId) {
        if (String.isBlank(applicationId)) {
            return null;
        }

        try {
            OnboardingFormDTO formData = new OnboardingFormDTO();
            
            // Query the application record
            List<Onboarding_Application__c> apps = [
                SELECT Id, Client_Type__c, Services_Required__c, Channel__c, 
                       Application_Type__c, Status__c, Current_Step__c
                FROM Onboarding_Application__c
                WHERE Id = :applicationId
                LIMIT 1
            ];
            
            if (apps.isEmpty()) {
                return null;
            }
            
            Onboarding_Application__c app = apps[0];
            formData.applicationId = app.Id;
            formData.clientType = app.Client_Type__c;
            
            // Parse Services_Required__c (semicolon-separated)
            if (String.isNotBlank(app.Services_Required__c)) {
                formData.servicesRequired = app.Services_Required__c.split(';');
            }
            
            formData.channel = app.Channel__c;
            formData.currentStep = app.Current_Step__c;
            
            // Query Party__c record for Applicant role (corporate or individual)
            // Only query fields that actually exist on Party__c (based on createCorporateParty method)
            List<Application_Party_Role__c> applicantRoles = [
                SELECT Party__r.Id, Party__r.Full_Legal_Name__c, Party__r.Legal_Entity_Name__c,
                       Party__r.Legal_Entity_Type__c, Party__r.Date_of_Incorporation__c,
                       Party__r.Country_of_Incorporation__c, Party__r.Registration_Number__c,
                       Party__r.Website__c, Party__r.Email__c, Party__r.Phone__c,
                       Party__r.Party_Type__c
                FROM Application_Party_Role__c
                WHERE Onboarding_Application__c = :applicationId
                AND Role__c = 'Applicant'
                LIMIT 1
            ];
            
            // If corporate client, populate companyInfo from Party__c
            // Note: Only fields that exist on Party__c are populated here
            // Other fields (tradingName, registeredBusinessAddress, etc.) are stored elsewhere
            // or will be populated when the user fills them in the Company Information step
            if (app.Client_Type__c == 'Corporate' && !applicantRoles.isEmpty()) {
                Party__c party = applicantRoles[0].Party__r;
                formData.companyInfo = new OnboardingFormDTO.CompanyInfoDTO();
                
                if (party != null) {
                    formData.companyInfo.legalEntityName = party.Legal_Entity_Name__c;
                    formData.companyInfo.legalEntityType = party.Legal_Entity_Type__c;
                    
                    if (party.Date_of_Incorporation__c != null) {
                        formData.companyInfo.dateOfIncorporation = party.Date_of_Incorporation__c.format();
                    }
                    
                    formData.companyInfo.countryOfIncorporation = party.Country_of_Incorporation__c;
                    formData.companyInfo.registrationNumber = party.Registration_Number__c;
                    formData.companyInfo.website = party.Website__c;
                    formData.companyInfo.email = party.Email__c;
                    formData.companyInfo.phone = party.Phone__c;
                    
                    // Note: The following fields are not stored on Party__c:
                    // - tradingName
                    // - regulatorName
                    // - regulatoryLicenceNumber
                    // - regulatoryJurisdiction
                    // - natureOfBusiness
                    // - restrictedActivities
                    // - expectedNumberOfEmployees
                    // These will be populated when the user fills them in the Company Information step
                    // Addresses are stored in Party_Address__c records
                }
            }
            
            return JSON.serialize(formData);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving draft application data: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading draft application: ' + e.getMessage());
        }
    }

    /**
     * @description Load existing onboarding application data - BASIC VERSION
     * Fetches Services Required and Client Type (critical fields for form initialization)
     * 
     * @param applicationId The ID of the Onboarding_Application__c record to load
     * @return Map<String, Object> Map containing basic application data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOnboardingApplication(String applicationId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(applicationId)) {
                return result;
            }
            
            System.debug('📥 Loading basic application data for: ' + applicationId);
            
            // Query ONLY the fields we KNOW exist
            List<Onboarding_Application__c> apps = [
                SELECT Id, Client_Type__c, Services_Required__c, Channel__c, Status__c,
                       CreatedBy.Profile.Name
                FROM Onboarding_Application__c
                WHERE Id = :applicationId
                LIMIT 1
            ];
            
            if (apps.isEmpty()) {
                System.debug('⚠️ No application found with ID: ' + applicationId);
                return result;
            }
            
            Onboarding_Application__c app = apps[0];
            
            // Populate basic result map
            result.put('clientType', app.Client_Type__c);
            result.put('channel', app.Channel__c);
            result.put('status', app.Status__c);
            
            // Parse Services_Required__c (semicolon-separated values) into list
            List<String> servicesList = new List<String>();
            if (String.isNotBlank(app.Services_Required__c)) {
                servicesList = app.Services_Required__c.split(';');
            }
            result.put('servicesRequired', servicesList);
            
            // Determine if created by internal user (for auto-detection of pre-filled)
            result.put('createdByProfile', app.CreatedBy.Profile.Name);
            
            // ========================================
            // LOAD SHAREHOLDERS & AUTHORIZED USERS
            // ========================================
            List<Application_Party_Role__c> partyRoles = [
                SELECT Id, Role__c, Ownership_Percentage__c, Position_or_Role_Description__c, Is_Primary__c,
                       Is_Shareholder__c, Is_Director__c,
                       Party__c, Party__r.Id, Party__r.Party_Type__c, Party__r.First_Name__c, Party__r.Middle_Name__c,
                       Party__r.Last_Name__c, Party__r.Date_of_Birth__c, Party__r.Nationality__c,
                       Party__r.Email__c, Party__r.Phone__c, Party__r.Mobile__c,
                       Party__r.Country_of_Residence__c, Party__r.Government_ID_Number__c,
                       Party__r.Is_PEP__c, Party__r.Source_of_Wealth__c, Party__r.Source_of_Wealth_Explanation__c,
                       Party__r.Legal_Entity_Name__c, Party__r.Legal_Entity_Type__c,
                       Party__r.Date_of_Incorporation__c, Party__r.Country_of_Incorporation__c,
                       Party__r.Registration_Number__c
                FROM Application_Party_Role__c
                WHERE Onboarding_Application__c = :applicationId
            ];
            
            // Collect Party IDs to query addresses
            Set<Id> partyIds = new Set<Id>();
            for (Application_Party_Role__c apr : partyRoles) {
                if (apr.Party__c != null) {
                    partyIds.add(apr.Party__c);
                }
            }
            
            // Query addresses for all parties
            Map<Id, Party_Address__c> partyAddressMap = new Map<Id, Party_Address__c>();
            if (!partyIds.isEmpty()) {
                List<Party_Address__c> addresses = [
                    SELECT Id, Party__c, Street__c, City__c, State__c, Postal_Code__c, 
                           Country__c, Address_Type__c, Is_Primary__c
                    FROM Party_Address__c
                    WHERE Party__c IN :partyIds
                    ORDER BY Is_Primary__c DESC NULLS LAST, CreatedDate DESC
                ];
                
                // Map first (primary) address for each party
                for (Party_Address__c addr : addresses) {
                    if (!partyAddressMap.containsKey(addr.Party__c)) {
                        partyAddressMap.put(addr.Party__c, addr);
                    }
                }
            }
            
            List<Map<String, Object>> shareholdersList = new List<Map<String, Object>>();
            List<Map<String, Object>> authorisedUsersList = new List<Map<String, Object>>();
            List<Map<String, Object>> additionalPartiesList = new List<Map<String, Object>>();
            
            for (Application_Party_Role__c apr : partyRoles) {
                if (apr.Party__r != null) {
                    System.debug('🔍 Processing party role: Role=' + apr.Role__c + ', PartyName=' + apr.Party__r.First_Name__c + ' ' + apr.Party__r.Last_Name__c);
                    Map<String, Object> partyData = new Map<String, Object>();
                    partyData.put('id', apr.Party__r.Id);
                    partyData.put('type', apr.Party__r.Party_Type__c != null ? apr.Party__r.Party_Type__c : 'Individual');
                    partyData.put('firstName', apr.Party__r.First_Name__c);
                    partyData.put('middleName', apr.Party__r.Middle_Name__c);
                    partyData.put('lastName', apr.Party__r.Last_Name__c);
                    partyData.put('email', apr.Party__r.Email__c);
                    partyData.put('phone', apr.Party__r.Phone__c);
                    partyData.put('mobile', apr.Party__r.Mobile__c);
                    partyData.put('dateOfBirth', apr.Party__r.Date_of_Birth__c != null ? String.valueOf(apr.Party__r.Date_of_Birth__c) : null);
                    partyData.put('nationality', apr.Party__r.Nationality__c);
                    partyData.put('countryOfResidence', apr.Party__r.Country_of_Residence__c);
                    partyData.put('governmentIdNumber', apr.Party__r.Government_ID_Number__c);
                    partyData.put('isPEP', apr.Party__r.Is_PEP__c);
                    partyData.put('sourceOfWealth', apr.Party__r.Source_of_Wealth__c);
                    partyData.put('sourceOfWealthExplanation', apr.Party__r.Source_of_Wealth_Explanation__c);
                    partyData.put('legalEntityName', apr.Party__r.Legal_Entity_Name__c);
                    partyData.put('legalEntityType', apr.Party__r.Legal_Entity_Type__c);
                    partyData.put('dateOfIncorporation', apr.Party__r.Date_of_Incorporation__c != null ? String.valueOf(apr.Party__r.Date_of_Incorporation__c) : null);
                    partyData.put('countryOfIncorporation', apr.Party__r.Country_of_Incorporation__c);
                    partyData.put('registrationNumber', apr.Party__r.Registration_Number__c);
                    
                    // Load Address Information (primary address from map)
                    if (partyAddressMap.containsKey(apr.Party__c)) {
                        Party_Address__c addr = partyAddressMap.get(apr.Party__c);
                        Map<String, Object> addressData = new Map<String, Object>();
                        addressData.put('street', addr.Street__c);
                        addressData.put('city', addr.City__c);
                        addressData.put('state', addr.State__c);
                        addressData.put('postalCode', addr.Postal_Code__c);
                        addressData.put('country', addr.Country__c);
                        addressData.put('addressType', addr.Address_Type__c);
                        partyData.put('address', addressData);
                    }
                    
                    // Map parties to appropriate lists based on role
                    // For new records with boolean fields, check Is_Shareholder__c or Is_Director__c
                    // For legacy records, fallback to Role__c field
                    Boolean isShareholder = (apr.Is_Shareholder__c != null && apr.Is_Shareholder__c) || 
                                            (apr.Role__c == 'Shareholder' || apr.Role__c == 'Ultimate Beneficial Owner' || apr.Role__c == 'UBO');
                    Boolean isDirector = (apr.Is_Director__c != null && apr.Is_Director__c) || (apr.Role__c == 'Director');
                    
                    if (isShareholder || isDirector) {
                        // This is a Shareholder/Director
                        partyData.put('isShareholder', isShareholder);
                        partyData.put('isDirector', isDirector);
                        partyData.put('ownershipPercentage', apr.Ownership_Percentage__c != null ? String.valueOf(apr.Ownership_Percentage__c) : null);
                        partyData.put('positionOrRole', apr.Position_or_Role_Description__c);
                        shareholdersList.add(partyData);
                    } else if (apr.Role__c == 'Authorised_User' || apr.Role__c == 'Authorized User' || apr.Role__c == 'Authorized_User') {
                        // Handle multiple variations: UK/US spelling, with/without underscore
                        partyData.put('positionTitle', apr.Position_or_Role_Description__c);
                        partyData.put('isPrimaryContact', apr.Is_Primary__c);
                        authorisedUsersList.add(partyData);
                    } else {
                        // All other roles go to Additional Parties (Director, Signatory, etc.)
                        partyData.put('role', apr.Role__c);
                        partyData.put('positionTitle', apr.Position_or_Role_Description__c);
                        additionalPartiesList.add(partyData);
                    }
                }
            }
            
            result.put('shareholders', shareholdersList);
            result.put('authorisedUsers', authorisedUsersList);
            result.put('additionalParties', additionalPartiesList);

            // Load Risk Assessment data (Private client Source of Wealth)
            List<Risk_Assessment__c> riskAssessments = [
                SELECT Id, Private_Source_of_Wealth__c, Private_Source_of_Wealth_Explanation__c,
                       Private_Expected_Monthly_Volume__c, Private_Estimated_Transactions_per_Month__c,
                       Private_Geographic_Exposure__c, Private_Intended_Use_of_Account__c
                FROM Risk_Assessment__c
                WHERE Onboarding_Application__c = :applicationId
                LIMIT 1
            ];
            if (!riskAssessments.isEmpty()) {
                Risk_Assessment__c ra = riskAssessments[0];
                Map<String, Object> riskInfoData = new Map<String, Object>();
                riskInfoData.put('sourceOfWealth', ra.Private_Source_of_Wealth__c);
                riskInfoData.put('sourceOfWealthExplanation', ra.Private_Source_of_Wealth_Explanation__c);
                riskInfoData.put('expectedMonthlyVolume', ra.Private_Expected_Monthly_Volume__c != null
                    ? String.valueOf(ra.Private_Expected_Monthly_Volume__c.longValue()) : null);
                riskInfoData.put('estimatedTransactionsPerMonth', ra.Private_Estimated_Transactions_per_Month__c != null
                    ? String.valueOf(ra.Private_Estimated_Transactions_per_Month__c.longValue()) : null);
                riskInfoData.put('geographicExposure', String.isNotBlank(ra.Private_Geographic_Exposure__c)
                    ? ra.Private_Geographic_Exposure__c.split(';') : new List<String>());
                riskInfoData.put('intendedUseOfAccount', ra.Private_Intended_Use_of_Account__c);
                result.put('riskInfo', riskInfoData);
            }

            System.debug('✅ Loaded application data');
            System.debug('  - Client Type: ' + app.Client_Type__c);
            System.debug('  - Services Required: ' + servicesList);
            System.debug('  - Shareholders: ' + shareholdersList.size());
            System.debug('  - Authorized Users: ' + authorisedUsersList.size());
            System.debug('  - Additional Parties: ' + additionalPartiesList.size());
            System.debug('📊 Authorized Users Details: ' + JSON.serializePretty(authorisedUsersList));
            System.debug('📊 Additional Parties Details: ' + JSON.serializePretty(additionalPartiesList));
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '❌ Error loading application: ' + e.getMessage());
            throw new AuraHandledException('Error loading application: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Main method to save onboarding application data
     * Orchestrates the creation of all related records in a single transaction
     * 
     * @param formData OnboardingFormDTO containing all form data
     * @return SaveResult Result object with success status, record IDs, and any errors
     */
    @AuraEnabled
    public static OnboardingFormDTO.SaveResult saveOnboardingApplication(String formDataJson) {
        // Parse JSON string to DTO to avoid Lightning serialization issues
        OnboardingFormDTO formData;
        try {
            formData = (OnboardingFormDTO) JSON.deserialize(formDataJson, OnboardingFormDTO.class);
        } catch (Exception e) {
            OnboardingFormDTO.SaveResult errorResult = new OnboardingFormDTO.SaveResult();
            errorResult.isSuccess = false;
            errorResult.errors = new List<String>{ 'Failed to parse form data: ' + e.getMessage() };
            errorResult.message = 'Invalid form data format';
            return errorResult;
        }
        OnboardingFormDTO.SaveResult result = new OnboardingFormDTO.SaveResult();
        result.isSuccess = false;
        result.errors = new List<String>();
        result.recordIds = new Map<String, String>();
        result.debugInfo = new Map<String, Object>();
        
        // DEBUG: Capture what Apex receives and return it in the response
        // This allows us to see the data in browser console without needing debug logs
        Map<String, Object> debugData = new Map<String, Object>();
        debugData.put('formDataJsonLength', formDataJson != null ? formDataJson.length() : 0);
        debugData.put('formDataIsNull', formData == null);
        
        if (formData != null) {
            debugData.put('clientType', formData.clientType);
            debugData.put('clientTypeIsBlank', String.isBlank(formData.clientType));
            debugData.put('clientTypeLength', formData.clientType != null ? formData.clientType.length() : 0);
            
            debugData.put('servicesRequiredIsNull', formData.servicesRequired == null);
            if (formData.servicesRequired != null) {
                debugData.put('servicesRequiredSize', formData.servicesRequired.size());
                debugData.put('servicesRequiredIsEmpty', formData.servicesRequired.isEmpty());
                debugData.put('servicesRequiredValues', formData.servicesRequired);
            } else {
                debugData.put('servicesRequiredSize', 0);
                debugData.put('servicesRequiredIsEmpty', true);
                debugData.put('servicesRequiredValues', new List<String>());
            }
            
            debugData.put('declarationsIsNull', formData.declarations == null);
            if (formData.declarations != null) {
                debugData.put('declarationsSize', formData.declarations.size());
                debugData.put('declarationsIsEmpty', formData.declarations.isEmpty());
                if (!formData.declarations.isEmpty()) {
                    List<Map<String, Object>> declDetails = new List<Map<String, Object>>();
                    for (OnboardingFormDTO.DeclarationDTO decl : formData.declarations) {
                        Map<String, Object> declMap = new Map<String, Object>();
                        declMap.put('declarationType', decl.declarationType);
                        declMap.put('accepted', decl.accepted);
                        declMap.put('signatureName', decl.signatureName);
                        declDetails.add(declMap);
                    }
                    debugData.put('declarationsDetails', declDetails);
                }
            } else {
                debugData.put('declarationsSize', 0);
                debugData.put('declarationsIsEmpty', true);
            }
            
            // DEBUG: Log shareholders data
            debugData.put('shareholdersIsNull', formData.shareholders == null);
            if (formData.shareholders != null) {
                debugData.put('shareholdersSize', formData.shareholders.size());
                debugData.put('shareholdersIsEmpty', formData.shareholders.isEmpty());
                if (!formData.shareholders.isEmpty()) {
                    List<Map<String, Object>> shareholderDetails = new List<Map<String, Object>>();
                    for (OnboardingFormDTO.ShareholderDTO sh : formData.shareholders) {
                        Map<String, Object> shMap = new Map<String, Object>();
                        shMap.put('id', sh.id);
                        shMap.put('name', sh.name);
                        shMap.put('type', sh.type);
                        shMap.put('ownershipPercentage', sh.ownershipPercentage);
                        shMap.put('isPEP', sh.isPEP);
                        shareholderDetails.add(shMap);
                    }
                    debugData.put('shareholdersDetails', shareholderDetails);
                }
            } else {
                debugData.put('shareholdersSize', 0);
                debugData.put('shareholdersIsEmpty', true);
            }
        }
        
        result.debugInfo.put('apexReceivedData', debugData);
        
        // Also log to System.debug for traditional debugging
        System.debug('=== APEX RECEIVED FORM DATA ===');
        System.debug(JSON.serializePretty(debugData));
        System.debug('=== END APEX DEBUG ===');
        
        // Validate input
        if (formData == null) {
            result.errors.add('Form data is required');
            result.message = 'Invalid form data provided';
            result.debugInfo.put('validationStage', 'nullCheck');
            return result;
        }
        
        // Validate required fields
        ValidationResult validation = validateFormData(formData);
        if (!validation.isValid) {
            result.errors = validation.errors;
            result.message = 'Validation failed: ' + String.join(validation.errors, ', ');
            result.debugInfo.put('validationStage', 'fieldValidation');
            result.debugInfo.put('validationErrors', validation.errors);
            return result;
        }
        
        // Capture client metadata as fallback if not provided by LWC
        if (String.isBlank(formData.ipAddress) || String.isBlank(formData.userAgent)) {
            Map<String, String> metadata = captureClientMetadata();
            if (String.isBlank(formData.ipAddress) && String.isNotBlank(metadata.get('ipAddress'))) {
                formData.ipAddress = metadata.get('ipAddress');
            }
            if (String.isBlank(formData.userAgent) && String.isNotBlank(metadata.get('userAgent'))) {
                formData.userAgent = metadata.get('userAgent');
            }
        }
        
        // Start transaction with Savepoint
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Step 1: Create or update Onboarding_Application__c record
            String applicationId = createOnboardingApplication(formData);
            result.recordIds.put('Onboarding_Application', applicationId);
            
            // Step 1.5: Capture existing Party IDs from roles BEFORE creating/updating parties
            // This prevents orphaned Party__c records when roles are recreated
            Map<String, String> existingPartyIds = captureExistingPartyIds(applicationId, formData);
            
            // Step 2: Create Party__c records (applicant, shareholders, authorized users)
            // Pass existingPartyIds to reuse Party records instead of creating duplicates
            Map<String, String> partyMap = createPartyRecords(formData, applicationId, existingPartyIds);
            result.recordIds.putAll(partyMap);
            
            // Step 3: Create Application_Party_Role__c records
            createApplicationPartyRoles(applicationId, partyMap, formData);
            
            // Step 4: Create Party_Address__c records
            createPartyAddresses(partyMap, formData);
            
            // Step 5: Create or Update Business_Profile__c for corporate clients
            // Create/update when companyInfo is available (Company Information step) or businessContext is available
            // Wrap in try-catch to prevent Business_Profile__c errors from breaking shareholder/party saves
            System.debug(LoggingLevel.DEBUG, 'Step 5: Checking if Business_Profile__c should be created/updated');
            System.debug(LoggingLevel.DEBUG, 'Client Type: ' + formData.clientType);
            System.debug(LoggingLevel.DEBUG, 'Has companyInfo: ' + (formData.companyInfo != null));
            System.debug(LoggingLevel.DEBUG, 'Has businessContext: ' + (formData.businessContext != null));
            System.debug(LoggingLevel.DEBUG, 'Has serviceProfiles: ' + (formData.serviceProfiles != null && !formData.serviceProfiles.isEmpty()));
            
            // Check if we need to create Business_Profile__c
            // - Corporate: Always create if they have companyInfo or businessContext
            // - Private: Create if they have FX service data (currencies/countries)
            Boolean shouldCreateBusinessProfile = false;
            if (formData.clientType == 'Corporate' && 
                (formData.companyInfo != null || formData.businessContext != null)) {
                shouldCreateBusinessProfile = true;
            } else if (formData.clientType == 'Private' && formData.serviceProfiles != null) {
                // Check if Private client has FX service with currency/country data
                for (OnboardingFormDTO.ServiceProfileDTO serviceProfile : formData.serviceProfiles) {
                    if (serviceProfile.serviceType == 'FX' && (
                        (serviceProfile.currenciesToSend != null && !serviceProfile.currenciesToSend.isEmpty()) ||
                        (serviceProfile.currenciesToReceive != null && !serviceProfile.currenciesToReceive.isEmpty()) ||
                        (serviceProfile.countriesFundsSentTo != null && !serviceProfile.countriesFundsSentTo.isEmpty()) ||
                        (serviceProfile.countriesFundsReceivedFrom != null && !serviceProfile.countriesFundsReceivedFrom.isEmpty())
                    )) {
                        shouldCreateBusinessProfile = true;
                        System.debug(LoggingLevel.DEBUG, '✅ Private client has FX currency/country data - will create Business_Profile__c');
                        break;
                    }
                }
            }
            
            if (shouldCreateBusinessProfile) {
                System.debug(LoggingLevel.DEBUG, '✅ Calling createOrUpdateBusinessProfile...');
                try {
                    String businessProfileId = createOrUpdateBusinessProfile(applicationId, formData);
                if (String.isNotBlank(businessProfileId)) {
                    result.recordIds.put('Business_Profile', businessProfileId);
                        System.debug(LoggingLevel.DEBUG, '✅ Business_Profile__c created/updated: ' + businessProfileId);
                    } else {
                        System.debug(LoggingLevel.WARN, '⚠️ createOrUpdateBusinessProfile returned null (no data to save)');
                    }
                } catch (Exception e) {
                    // Log error but don't fail the entire transaction
                    // This allows shareholders and other parties to be saved even if Business_Profile__c fails
                    System.debug(LoggingLevel.ERROR, '❌ Error creating/updating Business_Profile__c: ' + e.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                    result.errors.add('Business Profile Error: ' + e.getMessage());
                    // Continue with the rest of the transaction
                }
            } else {
                System.debug(LoggingLevel.DEBUG, '⏭️ Skipping Business_Profile__c creation (no relevant data)');
            }
            
            // Step 6: Service data is now saved directly on Onboarding_Application__c
            // No need to create separate Service_Profile__c records anymore
            // Service fields are populated in createOnboardingApplication() method
            
            // Step 7: Create Risk_Assessment__c record
            String riskAssessmentId = createRiskAssessment(applicationId, formData);
            if (String.isNotBlank(riskAssessmentId)) {
                result.recordIds.put('Risk_Assessment', riskAssessmentId);
            }
            
            // Step 8: Create Document_Submission__c records (required documents)
            List<String> documentIds = createDocumentSubmissions(applicationId, formData);
            for (Integer i = 0; i < documentIds.size(); i++) {
                result.recordIds.put('Document_Submission_' + i, documentIds[i]);
            }
            
            // Step 9: Create Declaration_Acceptance__c records
            List<String> declarationIds = createDeclarationAcceptances(applicationId, partyMap, formData);
            for (Integer i = 0; i < declarationIds.size(); i++) {
                result.recordIds.put('Declaration_Acceptance_' + i, declarationIds[i]);
            }
            
            // Step 10: Link file uploads to Document_Submission__c records
            if (formData.fileUploads != null && !formData.fileUploads.isEmpty()) {
                linkFileUploads(formData.fileUploads, applicationId, partyMap);
            }
            
            // Success
            result.isSuccess = true;
            result.applicationId = applicationId;
            result.message = 'Onboarding application submitted successfully';
            
        } catch (DmlException e) {
            // Rollback transaction on DML error
            Database.rollback(sp);
            result.isSuccess = false;
            result.errors.add('Database error: ' + e.getMessage());
            result.message = 'Failed to save application: ' + e.getMessage();
            
            // Add field-specific errors if available
            for (Integer i = 0; i < e.getNumDml(); i++) {
                result.errors.add('Error on record ' + (i + 1) + ': ' + e.getDmlMessage(i));
            }
            
        } catch (Exception e) {
            // Rollback transaction on any other error
            Database.rollback(sp);
            result.isSuccess = false;
            result.errors.add('Unexpected error: ' + e.getMessage());
            result.message = 'An unexpected error occurred: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Validates form data before processing
     * @param formData OnboardingFormDTO to validate
     * @return ValidationResult Validation result with errors list
     */
    private static ValidationResult validateFormData(OnboardingFormDTO formData) {
        ValidationResult result = new ValidationResult();
        result.isValid = true;
        result.errors = new List<String>();

        // Basic validation always required
        if (String.isBlank(formData.clientType)) {
            result.errors.add('Client type is required');
        } else if (formData.clientType != 'Private' && formData.clientType != 'Corporate') {
            result.errors.add('Invalid client type: ' + formData.clientType);
        }

        // Keep draft auto-save validation intentionally lenient.
        // Treat as final submit only on declarations step.
        // Backward-compatible: old clients may not send isSubmission.
        Boolean isDeclarationsStep = formData.currentStep == 'declarations';
        Boolean isFinalSubmission = isDeclarationsStep && (formData.isSubmission == true || formData.isSubmission == null);
        if (!isFinalSubmission) {
            result.isValid = result.errors.isEmpty();
            return result;
        }

        if (formData.servicesRequired == null || formData.servicesRequired.isEmpty()) {
            result.errors.add('At least one service is required');
        }

        if (formData.clientType == 'Private') {
            validatePrivateSubmission(formData, result);
        } else if (formData.clientType == 'Corporate') {
            validateCorporateSubmission(formData, result);
        }

        validateServiceSpecificSubmission(formData, result);
        validateDeclarationsSubmission(formData, result);

        result.isValid = result.errors.isEmpty();
        return result;
    }

    private static void validatePrivateSubmission(OnboardingFormDTO formData, ValidationResult result) {
        if (formData.personalInfo == null) {
            result.errors.add('Personal information is required for private clients');
        } else {
            requireText(formData.personalInfo.salutation, 'Salutation is required', result.errors);
            requireText(formData.personalInfo.firstName, 'First name is required', result.errors);
            requireText(formData.personalInfo.lastName, 'Last name is required', result.errors);
            requireText(formData.personalInfo.dateOfBirth, 'Date of birth is required', result.errors);
            requireText(formData.personalInfo.nationality, 'Nationality is required', result.errors);
            requireText(formData.personalInfo.countryOfResidence, 'Country of residence is required', result.errors);
            requireText(formData.personalInfo.governmentIdNumber, 'Government ID number is required', result.errors);
            requireText(formData.personalInfo.email, 'Email is required', result.errors);
            requireText(formData.personalInfo.mobile, 'Mobile is required', result.errors);
            requireText(formData.personalInfo.isPEP, 'PEP response is required', result.errors);
        }

        validateAddressInfo(formData.addressInfo, result.errors);

        if (formData.riskInfo == null) {
            result.errors.add('Risk assessment information is required for private clients');
        } else {
            requireText(formData.riskInfo.estimatedTransactionsPerMonth, 'Estimated transactions per month is required', result.errors);
            requireText(formData.riskInfo.sourceOfWealth, 'Source of wealth is required', result.errors);
            requireText(formData.riskInfo.sourceOfWealthExplanation, 'Source of wealth explanation is required', result.errors);
            requireNonEmptyList(formData.riskInfo.geographicExposure, 'At least one geographic exposure country is required', result.errors);
            requireText(formData.riskInfo.intendedUseOfAccount, 'Intended use of account is required', result.errors);
        }
    }

    private static void validateCorporateSubmission(OnboardingFormDTO formData, ValidationResult result) {
        if (formData.companyInfo == null) {
            result.errors.add('Company information is required for corporate clients');
        } else {
            requireText(formData.companyInfo.legalEntityName, 'Legal entity name is required', result.errors);
            requireText(formData.companyInfo.legalEntityType, 'Legal entity type is required', result.errors);
            requireText(formData.companyInfo.dateOfIncorporation, 'Date of incorporation is required', result.errors);
            requireText(formData.companyInfo.countryOfIncorporation, 'Country of incorporation is required', result.errors);
            requireText(formData.companyInfo.registrationNumber, 'Registration number is required', result.errors);
            requireText(formData.companyInfo.registeredStreet, 'Registered street is required', result.errors);
            requireText(formData.companyInfo.registeredCity, 'Registered city is required', result.errors);
            requireText(formData.companyInfo.registeredCountry, 'Registered country is required', result.errors);
            requireText(formData.companyInfo.email, 'Corporate email is required', result.errors);
        }

        if (formData.businessContext == null) {
            result.errors.add('Business context is required for corporate clients');
        } else {
            requireText(formData.businessContext.purposeOfAccount, 'Purpose of account is required', result.errors);
            requireText(formData.businessContext.industry, 'Industry is required', result.errors);
            requireText(formData.businessContext.productsAndServices, 'Products and services is required', result.errors);
            requireNonEmptyList(formData.businessContext.paymentFlowTypes, 'Payment flow types is required', result.errors);
            requireText(formData.businessContext.expectedTransactionsPerMonth, 'Expected transactions per month is required', result.errors);
            requireText(formData.businessContext.expectedAnnualVolume, 'Expected annual volume is required', result.errors);
            requireText(formData.businessContext.typicalValuePerTransaction, 'Typical value per transaction is required', result.errors);
            requireNonEmptyList(formData.businessContext.countriesFundsSentTo, 'Countries funds sent to is required', result.errors);
            requireNonEmptyList(formData.businessContext.countriesFundsReceivedFrom, 'Countries funds received from is required', result.errors);
            requireText(formData.businessContext.primarySourceOfFunds, 'Primary source of funds is required', result.errors);
            requireText(formData.businessContext.sourceOfWealthExplanation, 'Source of wealth explanation is required', result.errors);
        }

        Boolean hasShareholders = !getActiveShareholders(formData.shareholders).isEmpty();
        Boolean hasAuthorisedUsers = !getActiveAuthorisedUsers(formData.authorisedUsers).isEmpty();
        if (!hasShareholders && !hasAuthorisedUsers) {
            result.errors.add('At least one shareholder/director or authorised user is required');
        }

        validateShareholders(formData.shareholders, result.errors);
        validateAuthorisedUsers(formData.authorisedUsers, formData.servicesRequired, result.errors);
    }

    private static void validateShareholders(List<OnboardingFormDTO.ShareholderDTO> shareholders, List<String> errors) {
        List<OnboardingFormDTO.ShareholderDTO> activeShareholders = getActiveShareholders(shareholders);
        if (activeShareholders.isEmpty()) {
            return;
        }
        Integer index = 0;
        for (OnboardingFormDTO.ShareholderDTO holder : activeShareholders) {
            index++;
            String prefix = 'Shareholder/Director #' + index + ': ';

            if (holder == null) {
                errors.add(prefix + 'Record is required');
                continue;
            }
            if (holder.isShareholder != true && holder.isDirector != true) {
                errors.add(prefix + 'At least one role (Shareholder or Director) is required');
            }
            if (holder.type == 'Corporate') {
                requireText(holder.legalEntityName, prefix + 'Legal entity name is required', errors);
            } else {
                requireText(holder.firstName, prefix + 'First name is required', errors);
                requireText(holder.lastName, prefix + 'Last name is required', errors);
            }
            requireText(holder.dateOfBirthOrIncorporation, prefix + 'Date of birth/incorporation is required', errors);
            requireText(holder.countryOfResidenceOrIncorporation, prefix + 'Country is required', errors);
            requireText(holder.nationalityOrCountryOfIncorporation, prefix + 'Nationality/country of incorporation is required', errors);
            requireText(holder.governmentIdOrRegistrationNumber, prefix + 'Government ID/registration number is required', errors);
            requireText(holder.isPEP, prefix + 'PEP response is required', errors);
            requireText(holder.email, prefix + 'Email is required', errors);
            requireText(holder.mobile, prefix + 'Mobile number is required', errors);
            requireText(holder.street, prefix + 'Street address is required', errors);
            requireText(holder.city, prefix + 'City is required', errors);
            requireText(holder.state, prefix + 'State/province is required', errors);
            requireText(holder.postalCode, prefix + 'Postal code is required', errors);
            requireText(holder.country, prefix + 'Country is required', errors);
            if (holder.isShareholder == true) {
                requireText(holder.ownershipPercentage, prefix + 'Ownership percentage is required for shareholder role', errors);
            }
        }
    }

    private static void validateAuthorisedUsers(
        List<OnboardingFormDTO.AuthorisedUserDTO> authorisedUsers,
        List<String> servicesRequired,
        List<String> errors
    ) {
        List<OnboardingFormDTO.AuthorisedUserDTO> activeAuthorisedUsers = getActiveAuthorisedUsers(authorisedUsers);
        if (activeAuthorisedUsers.isEmpty()) {
            return;
        }
        Boolean requiresTradingFrequency = hasService(servicesRequired, 'FX') || hasService(servicesRequired, 'Crypto');
        Integer index = 0;
        for (OnboardingFormDTO.AuthorisedUserDTO user : activeAuthorisedUsers) {
            index++;
            String prefix = 'Authorised user #' + index + ': ';
            if (user == null) {
                errors.add(prefix + 'Record is required');
                continue;
            }
            requireText(user.firstName, prefix + 'First name is required', errors);
            requireText(user.lastName, prefix + 'Last name is required', errors);
            requireText(user.dateOfBirth, prefix + 'Date of birth is required', errors);
            requireText(user.countryOfResidence, prefix + 'Country of residence is required', errors);
            requireText(user.nationality, prefix + 'Nationality is required', errors);
            requireText(user.governmentIdNumber, prefix + 'Government ID number is required', errors);
            requireText(user.email, prefix + 'Email is required', errors);
            requireText(user.mobileNumber, prefix + 'Mobile number is required', errors);
            requireText(user.street, prefix + 'Street address is required', errors);
            requireText(user.city, prefix + 'City is required', errors);
            requireText(user.state, prefix + 'State/province is required', errors);
            requireText(user.postalCode, prefix + 'Postal code is required', errors);
            requireText(user.country, prefix + 'Country is required', errors);
            if (requiresTradingFrequency) {
                requireText(user.tradeFrequency, prefix + 'Trade frequency is required for FX/Crypto services', errors);
            }
        }
    }

    private static void validateServiceSpecificSubmission(OnboardingFormDTO formData, ValidationResult result) {
        if (formData.servicesRequired == null || formData.servicesRequired.isEmpty()) {
            return;
        }
        for (String serviceType : formData.servicesRequired) {
            OnboardingFormDTO.ServiceProfileDTO profile = getServiceProfile(formData.serviceProfiles, serviceType);
            if (profile == null) {
                result.errors.add(serviceType + ' service details are required');
                continue;
            }
            if (serviceType == 'FX') {
                List<String> fxCurrenciesToSend = profile.currenciesToSend;
                List<String> fxCurrenciesToReceive = profile.currenciesToReceive;

                // Corporate captures FX currencies in businessContext, while private captures
                // them in serviceProfiles. Use businessContext as fallback.
                if (formData.clientType == 'Corporate' && formData.businessContext != null) {
                    if (fxCurrenciesToSend == null || fxCurrenciesToSend.isEmpty()) {
                        fxCurrenciesToSend = formData.businessContext.currenciesToSend;
                    }
                    if (fxCurrenciesToReceive == null || fxCurrenciesToReceive.isEmpty()) {
                        fxCurrenciesToReceive = formData.businessContext.currenciesToReceive;
                    }
                }

                requireNonEmptyList(fxCurrenciesToSend, 'FX: currencies to send is required', result.errors);
                requireNonEmptyList(fxCurrenciesToReceive, 'FX: currencies to receive is required', result.errors);
                requireText(profile.fxForwardContractsRequired, 'FX: forward contracts/hedging response is required', result.errors);
                if (profile.fxForwardContractsRequired == 'Yes') {
                    requireText(profile.fxHedgingNeeds, 'FX: hedging needs are required when forward contracts are required', result.errors);
                }
            } else if (serviceType == 'Crypto') {
                requireNonEmptyList(profile.digitalAssets, 'Crypto: digital assets selection is required', result.errors);
                requireText(profile.expectedMonthlyCryptoVolume, 'Crypto: expected monthly volume is required', result.errors);
                requireText(profile.averageCryptoTransactionSize, 'Crypto: average transaction size is required', result.errors);
            } else if (serviceType == 'Advisory') {
                requireNonEmptyList(profile.advisoryServicesRequired, 'Advisory: services required is required', result.errors);
                requireNonEmptyList(profile.investmentObjectives, 'Advisory: investment objectives is required', result.errors);
                requireText(profile.riskAppetite, 'Advisory: risk appetite is required', result.errors);
            }
        }
    }

    private static void validateDeclarationsSubmission(OnboardingFormDTO formData, ValidationResult result) {
        if (formData.declarations == null || formData.declarations.isEmpty()) {
            result.errors.add('At least one declaration must be accepted');
            return;
        }
        Boolean hasAcceptedDeclaration = false;
        for (OnboardingFormDTO.DeclarationDTO decl : formData.declarations) {
            if (decl.accepted == true) {
                hasAcceptedDeclaration = true;
                if (String.isBlank(decl.signatureName) &&
                    (String.isBlank(decl.signatoryFirstName) || String.isBlank(decl.signatoryLastName))) {
                    result.errors.add('Signature name is required for accepted declarations');
                }
                break;
            }
        }
        if (!hasAcceptedDeclaration) {
            result.errors.add('At least one declaration must be accepted');
        }
    }

    private static void validateAddressInfo(OnboardingFormDTO.AddressInfoDTO addressInfo, List<String> errors) {
        if (addressInfo == null) {
            errors.add('Address information is required');
            return;
        }
        requireText(addressInfo.street, 'Street is required', errors);
        requireText(addressInfo.city, 'City is required', errors);
        requireText(addressInfo.state, 'State/Province is required', errors);
        requireText(addressInfo.postalCode, 'Postal code is required', errors);
        requireText(addressInfo.country, 'Country is required', errors);
    }

    private static void requireText(String value, String message, List<String> errors) {
        if (String.isBlank(value)) {
            errors.add(message);
        }
    }

    private static void requireNonEmptyList(List<String> values, String message, List<String> errors) {
        if (values == null || values.isEmpty()) {
            errors.add(message);
        }
    }

    private static Boolean hasService(List<String> servicesRequired, String serviceName) {
        return servicesRequired != null && servicesRequired.contains(serviceName);
    }

    private static List<OnboardingFormDTO.ShareholderDTO> getActiveShareholders(
        List<OnboardingFormDTO.ShareholderDTO> shareholders
    ) {
        List<OnboardingFormDTO.ShareholderDTO> active = new List<OnboardingFormDTO.ShareholderDTO>();
        if (shareholders == null || shareholders.isEmpty()) {
            return active;
        }
        for (OnboardingFormDTO.ShareholderDTO holder : shareholders) {
            if (holder == null) {
                continue;
            }
            Boolean hasInput =
                holder.isShareholder == true ||
                holder.isDirector == true ||
                String.isNotBlank(holder.type) ||
                String.isNotBlank(holder.firstName) ||
                String.isNotBlank(holder.lastName) ||
                String.isNotBlank(holder.legalEntityName) ||
                String.isNotBlank(holder.email) ||
                String.isNotBlank(holder.dateOfBirthOrIncorporation);
            if (hasInput) {
                active.add(holder);
            }
        }
        return active;
    }

    private static List<OnboardingFormDTO.AuthorisedUserDTO> getActiveAuthorisedUsers(
        List<OnboardingFormDTO.AuthorisedUserDTO> authorisedUsers
    ) {
        List<OnboardingFormDTO.AuthorisedUserDTO> active = new List<OnboardingFormDTO.AuthorisedUserDTO>();
        if (authorisedUsers == null || authorisedUsers.isEmpty()) {
            return active;
        }
        for (OnboardingFormDTO.AuthorisedUserDTO user : authorisedUsers) {
            if (user == null) {
                continue;
            }
            Boolean hasInput =
                String.isNotBlank(user.firstName) ||
                String.isNotBlank(user.lastName) ||
                String.isNotBlank(user.email) ||
                String.isNotBlank(user.dateOfBirth) ||
                String.isNotBlank(user.countryOfResidence) ||
                String.isNotBlank(user.nationality) ||
                String.isNotBlank(user.governmentIdNumber) ||
                String.isNotBlank(user.tradeFrequency);
            if (hasInput) {
                active.add(user);
            }
        }
        return active;
    }

    private static OnboardingFormDTO.ServiceProfileDTO getServiceProfile(
        List<OnboardingFormDTO.ServiceProfileDTO> profiles,
        String serviceType
    ) {
        if (profiles == null || profiles.isEmpty()) {
            return null;
        }
        for (OnboardingFormDTO.ServiceProfileDTO profile : profiles) {
            if (profile != null && profile.serviceType == serviceType) {
                return profile;
            }
        }
        return null;
    }
    
    /**
     * @description Validation result wrapper class
     */
    private class ValidationResult {
        Boolean isValid;
        List<String> errors;
    }
    
    // ========== Helper Methods ==========
    
    /**
     * @description Creates Onboarding_Application__c record
     * @param formData Form data
     * @return Created record ID
     */
    private static String createOnboardingApplication(OnboardingFormDTO formData) {
        System.debug(LoggingLevel.DEBUG, '🏗️ === CREATE/UPDATE ONBOARDING APPLICATION ===');
        Onboarding_Application__c app;
        Boolean isUpdate = String.isNotBlank(formData.applicationId);
        System.debug(LoggingLevel.DEBUG, 'Application ID: ' + formData.applicationId);
        System.debug(LoggingLevel.DEBUG, 'Is Update: ' + isUpdate);
        System.debug(LoggingLevel.DEBUG, 'Current Step: ' + formData.currentStep);
        
        if (isUpdate) {
            app = new Onboarding_Application__c(Id = formData.applicationId);
            System.debug(LoggingLevel.DEBUG, '📝 Updating existing application: ' + formData.applicationId);
        } else {
            app = new Onboarding_Application__c();
            System.debug(LoggingLevel.DEBUG, '🆕 Creating new application');
        }
        
        // Map client type: "Private" -> "Private individual", "Corporate" -> "Corporate entity"
        if (formData.clientType == 'Private') {
            app.Client_Type__c = 'Private individual';
            app.Application_Type__c = 'Private';
        } else if (formData.clientType == 'Corporate') {
            app.Client_Type__c = 'Corporate entity';
            app.Application_Type__c = 'Corporate';
        }
        
        // Populate Client Name from personal or company info
        app.Client_Name__c = resolveClientName(formData);
        
        // Channel and current step
        if (String.isNotBlank(formData.channel)) {
            app.Channel__c = formData.channel;
        } else if (String.isBlank(app.Channel__c)) {
            app.Channel__c = 'ExperienceCloud';
        }
        if (String.isNotBlank(formData.currentStep)) {
            app.Current_Step__c = formData.currentStep;
        }
        
        // Map services required (multi-select picklist)
        if (formData.servicesRequired != null && !formData.servicesRequired.isEmpty()) {
            app.Services_Required__c = String.join(formData.servicesRequired, ';');
        }
        
        // Populate service-specific fields directly on application
        populateServiceFieldsOnApplication(app, formData);
        
        // Extract client notes from declarations if provided
        if (formData.declarations != null && !formData.declarations.isEmpty()) {
            for (OnboardingFormDTO.DeclarationDTO declDTO : formData.declarations) {
                if (String.isNotBlank(declDTO.clientNotes)) {
                    app.Client_Notes__c = declDTO.clientNotes;
                    break; // All declarations will have the same notes, so take the first one
                }
            }
        }
        
        // Set status and dates.
        // Align with validation rules: only treat as final submit from declarations step.
        // Backward-compatible: declarations step without explicit flag is also treated as submit.
        Boolean isDeclarationsStep = formData.currentStep == 'declarations' || formData.currentStep == 'success';
        Boolean isFinalSubmission = isDeclarationsStep && (formData.isSubmission == true || formData.isSubmission == null);
        if (isFinalSubmission) {
            app.Status__c = 'Submitted';
            app.Submitted_Date__c = Datetime.now();
        } else if (!isUpdate) {
            // New draft created via this path (should be rare; normally drafts
            // are created via createDraftApplication)
            app.Status__c = 'Draft';
        }
        app.Created_From_IP__c = formData.ipAddress;
        app.User_Agent__c = formData.userAgent;
        
        if (isUpdate) {
            update app;
            System.debug(LoggingLevel.DEBUG, '✅ Application UPDATED: ' + app.Id);
        } else {
            insert app;
            System.debug(LoggingLevel.DEBUG, '✅ Application CREATED: ' + app.Id);
        }
        System.debug(LoggingLevel.DEBUG, '🏗️ === CREATE/UPDATE COMPLETE ===');
        return app.Id;
    }

    /**
     * @description Creates a draft Onboarding_Application__c for file uploads / resume
     */
    @AuraEnabled
    public static String createDraftApplication(String clientType, List<String> servicesRequired, String ipAddress, String userAgent, String channel, String currentStep) {
        Onboarding_Application__c app = new Onboarding_Application__c();
        
        if (clientType == 'Private') {
            app.Client_Type__c = 'Private individual';
            app.Application_Type__c = 'Private';
        } else if (clientType == 'Corporate') {
            app.Client_Type__c = 'Corporate entity';
            app.Application_Type__c = 'Corporate';
        }
        if (servicesRequired != null && !servicesRequired.isEmpty()) {
            app.Services_Required__c = String.join(servicesRequired, ';');
        }
        app.Status__c = 'Draft';
        app.Client_Name__c = clientType == 'Private' ? 'Draft - Private' : 'Draft - Corporate';
        app.Created_From_IP__c = ipAddress;
        app.User_Agent__c = userAgent;
        app.Channel__c = String.isNotBlank(channel) ? channel : 'ExperienceCloud';
        if (String.isNotBlank(currentStep)) {
            app.Current_Step__c = currentStep;
        }
        
        insert app;
        return app.Id;
    }
    
    /**
     * @description Creates Party__c records for applicant, shareholders, and authorized users
     * Handles both new inserts and updates to existing draft applications
     * @param formData Form data
     * @param applicationId Parent application ID
     * @return Map of role to party ID (e.g., 'Applicant' -> partyId, 'Shareholder_<id>' -> partyId)
     */
    /**
     * @description Capture existing Party__c IDs from Application_Party_Role__c records
     *              This prevents orphaned Party records when roles are recreated
     * @param applicationId The ID of the onboarding application
     * @param formData The onboarding form data (to count parties)
     * @return Map of party keys (e.g., "Shareholder_0") to existing Party__c IDs
     */
    private static Map<String, String> captureExistingPartyIds(String applicationId, OnboardingFormDTO formData) {
        Map<String, String> existingPartyIds = new Map<String, String>();
        
        if (String.isBlank(applicationId)) {
            return existingPartyIds; // No existing application, return empty map
        }
        
        // Query existing Application_Party_Role__c records with Party info
        List<Application_Party_Role__c> existingRoles = [
            SELECT Id, Role__c, Party__c,
                   Party__r.Full_Legal_Name__c, Party__r.Legal_Entity_Name__c,
                   Party__r.First_Name__c, Party__r.Last_Name__c, Party__r.Party_Type__c,
                   CreatedDate
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :applicationId
            AND Role__c IN ('Shareholder', 'Authorised_User', 'Director', 'Signatory', 'UBO')
            ORDER BY Role__c, CreatedDate ASC
        ];
        
        // Build map by role type and sequence (to match form data order)
        Map<String, Integer> roleSequence = new Map<String, Integer>{
            'Shareholder' => 0,
            'Authorised_User' => 0,
            'Director' => 0,
            'Signatory' => 0,
            'UBO' => 0
        };
        
        for (Application_Party_Role__c role : existingRoles) {
            if (role.Party__c != null) {
                String roleType = role.Role__c;
                Integer seq = roleSequence.get(roleType);
                String key = roleType + '_' + seq;
                existingPartyIds.put(key, role.Party__c);
                roleSequence.put(roleType, seq + 1);
                System.debug(LoggingLevel.DEBUG, 'captureExistingPartyIds - Captured: ' + key + ' -> ' + role.Party__c);
            }
        }
        
        System.debug(LoggingLevel.DEBUG, 'captureExistingPartyIds - Total captured: ' + existingPartyIds.size());
        return existingPartyIds;
    }
    
    private static Map<String, String> createPartyRecords(OnboardingFormDTO formData, String applicationId, Map<String, String> existingPartyIds) {
        Map<String, String> partyMap = new Map<String, String>();
        List<Party__c> partiesToInsert = new List<Party__c>();
        List<Party__c> partiesToUpdate = new List<Party__c>();
        Map<String, Party__c> tempIdToParty = new Map<String, Party__c>();
        
        System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Entering with clientType=' + formData.clientType + ', applicationId=' + applicationId);
        
        // VALIDATE: Check if captured Party IDs still exist (not deleted)
        Set<String> validatedPartyIds = new Set<String>();
        if (!existingPartyIds.isEmpty()) {
            List<Party__c> existingParties = [
                SELECT Id FROM Party__c WHERE Id IN :existingPartyIds.values() AND IsDeleted = false
            ];
            for (Party__c p : existingParties) {
                validatedPartyIds.add(p.Id);
            }
            
            // Remove invalid (deleted) Party IDs from the map
            Map<String, String> validatedMap = new Map<String, String>();
            for (String key : existingPartyIds.keySet()) {
                String partyId = existingPartyIds.get(key);
                if (validatedPartyIds.contains(partyId)) {
                    validatedMap.put(key, partyId);
                } else {
                    System.debug(LoggingLevel.WARN, 'createPartyRecords - Party ID ' + partyId + ' for key ' + key + ' has been deleted, will create NEW Party');
                }
            }
            existingPartyIds = validatedMap; // Replace with validated map
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Validated ' + validatedPartyIds.size() + ' existing Party IDs');
        }
        
        // Query existing Application_Party_Role__c records to find existing parties
        Map<String, String> existingPartyRoles = new Map<String, String>(); // role -> Party__c.Id
        Map<String, Party__c> existingPartiesById = new Map<String, Party__c>(); // Party__c.Id -> Party__c
        if (String.isNotBlank(applicationId)) {
            List<Application_Party_Role__c> existingRoles = [
                SELECT Id, Party__c, Role__c, Party__r.Id, Party__r.Full_Legal_Name__c, 
                       Party__r.Legal_Entity_Name__c
                FROM Application_Party_Role__c
                WHERE Onboarding_Application__c = :applicationId
            ];
            Set<Id> partyIds = new Set<Id>();
            for (Application_Party_Role__c role : existingRoles) {
                if (role.Party__c != null) {
                    existingPartyRoles.put(role.Role__c, role.Party__c);
                    partyIds.add(role.Party__c);
                }
            }
            if (!partyIds.isEmpty()) {
                existingPartiesById = new Map<String, Party__c>([
                    SELECT Id, Full_Legal_Name__c, Legal_Entity_Name__c, Party_Type__c
                    FROM Party__c
                    WHERE Id IN :partyIds
                ]);
                System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Found ' + existingPartiesById.size() + ' existing parties');
            }
        }
        
        // Handle Applicant Party (only create if companyInfo/personalInfo has actual data)
        if (formData.clientType == 'Private' && formData.personalInfo != null) {
            // Only create/update applicant if personalInfo has actual data (not just blank object)
            Boolean hasPersonalData = String.isNotBlank(formData.personalInfo.firstName) ||
                                     String.isNotBlank(formData.personalInfo.lastName) ||
                                     String.isNotBlank(formData.personalInfo.email);
            
            if (hasPersonalData) {
                String existingApplicantPartyId = existingPartyRoles.get('Applicant');
                if (String.isNotBlank(existingApplicantPartyId) && existingPartiesById.containsKey(existingApplicantPartyId)) {
                    // Update existing applicant party
                    Party__c existingParty = existingPartiesById.get(existingApplicantPartyId);
                    Party__c updatedParty = createIndividualParty(formData.personalInfo);
                    updatedParty.Id = existingParty.Id;
                    partiesToUpdate.add(updatedParty);
                    partyMap.put('Applicant', existingParty.Id);
                } else {
                    // Create new applicant party
                    Party__c applicantParty = createIndividualParty(formData.personalInfo);
            partiesToInsert.add(applicantParty);
                    tempIdToParty.put('Applicant', applicantParty);
                }
            } else {
                // personalInfo exists but is blank, just reuse existing applicant if available
                String existingApplicantPartyId = existingPartyRoles.get('Applicant');
                if (String.isNotBlank(existingApplicantPartyId)) {
                    partyMap.put('Applicant', existingApplicantPartyId);
                }
                System.debug(LoggingLevel.DEBUG, 'Personal info exists but is blank - not creating applicant yet');
            }
        } else if (formData.clientType == 'Corporate' && formData.companyInfo != null) {
            // Only create/update applicant if companyInfo has actual data (not just blank object)
            Boolean hasCompanyData = String.isNotBlank(formData.companyInfo.legalEntityName) ||
                                    String.isNotBlank(formData.companyInfo.registrationNumber) ||
                                    String.isNotBlank(formData.companyInfo.countryOfIncorporation);
            
            if (hasCompanyData) {
                String existingApplicantPartyId = existingPartyRoles.get('Applicant');
                if (String.isNotBlank(existingApplicantPartyId) && existingPartiesById.containsKey(existingApplicantPartyId)) {
                    // Update existing applicant party with company information
                    Party__c existingParty = existingPartiesById.get(existingApplicantPartyId);
                    Party__c updatedParty = createCorporateParty(formData.companyInfo);
                    updatedParty.Id = existingParty.Id;
                    partiesToUpdate.add(updatedParty);
                    partyMap.put('Applicant', existingParty.Id);
                    System.debug(LoggingLevel.DEBUG, 'Updating existing Applicant Party with Company Info: ' + existingParty.Id);
                    System.debug(LoggingLevel.DEBUG, 'Legal Entity Name: ' + updatedParty.Legal_Entity_Name__c + ', Website: ' + updatedParty.Website__c + ', Email: ' + updatedParty.Email__c + ', Phone: ' + updatedParty.Phone__c);
                } else {
                    // Create new applicant party
                    Party__c applicantParty = createCorporateParty(formData.companyInfo);
            partiesToInsert.add(applicantParty);
                    tempIdToParty.put('Applicant', applicantParty);
                    System.debug(LoggingLevel.DEBUG, 'Creating new Applicant Party with Company Info');
                    System.debug(LoggingLevel.DEBUG, 'Legal Entity Name: ' + applicantParty.Legal_Entity_Name__c + ', Website: ' + applicantParty.Website__c + ', Email: ' + applicantParty.Email__c + ', Phone: ' + applicantParty.Phone__c);
                }
            } else {
                // companyInfo is not filled yet, just reuse existing applicant if available
                String existingApplicantPartyId = existingPartyRoles.get('Applicant');
                if (String.isNotBlank(existingApplicantPartyId)) {
                    partyMap.put('Applicant', existingApplicantPartyId);
                }
                System.debug(LoggingLevel.DEBUG, 'Company info exists but is blank - not creating applicant yet');
            }
        } else if (formData.clientType == 'Corporate') {
            // For Corporate clients on shareholders step, companyInfo is null, so we can't create applicant yet
            // But we can use existing applicant party if it exists
            String existingApplicantPartyId = existingPartyRoles.get('Applicant');
            if (String.isNotBlank(existingApplicantPartyId)) {
                partyMap.put('Applicant', existingApplicantPartyId);
            }
        }
        
        // Create/Update Shareholder Parties
        System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Checking shareholders: null=' + (formData.shareholders == null) + 
                                          ', isEmpty=' + (formData.shareholders != null ? formData.shareholders.isEmpty() : true));
        if (formData.shareholders != null && !formData.shareholders.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Processing ' + formData.shareholders.size() + ' shareholders');
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Existing Party IDs available: ' + existingPartyIds.keySet());
            
            // Iterate through shareholders and reuse existing Party IDs by sequence
            Integer shareholderIndex = 0;
            for (OnboardingFormDTO.ShareholderDTO shareholder : formData.shareholders) {
                System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Processing shareholder: id=' + shareholder.id + 
                                                  ', type=' + shareholder.type + ', index=' + shareholderIndex);
                
                // Check if we have an existing Party ID for this shareholder (by sequence)
                String existingPartyKey = 'Shareholder_' + shareholderIndex;
                String existingPartyId = existingPartyIds.get(existingPartyKey);
                
                Party__c shareholderParty;
                String partyMapKey = 'Shareholder_' + shareholder.id; // Key for partyMap (uses form ID)
                
                // DEBUG: Show all available data for troubleshooting
                System.debug(LoggingLevel.DEBUG, '🔍 DEBUG Shareholder ' + shareholderIndex + ':');
                System.debug(LoggingLevel.DEBUG, '  - Looking for key: ' + existingPartyKey);
                System.debug(LoggingLevel.DEBUG, '  - Found Party ID: ' + existingPartyId);
                System.debug(LoggingLevel.DEBUG, '  - existingPartiesById contains this ID? ' + (existingPartyId != null ? String.valueOf(existingPartiesById.containsKey(existingPartyId)) : 'N/A (ID is null)'));
                System.debug(LoggingLevel.DEBUG, '  - existingPartiesById size: ' + existingPartiesById.size());
                System.debug(LoggingLevel.DEBUG, '  - existingPartiesById keys: ' + existingPartiesById.keySet());
                
                if (String.isNotBlank(existingPartyId) && existingPartiesById.containsKey(existingPartyId)) {
                    // REUSE existing Party record - UPDATE it with new data
                    System.debug(LoggingLevel.DEBUG, '✅ UPDATING existing Party: ' + existingPartyId + ' (was ' + existingPartyKey + ', now ' + partyMapKey + ')');
                    if (shareholder.type == 'Individual') {
                        shareholderParty = createShareholderIndividualParty(shareholder);
                    } else if (shareholder.type == 'Corporate') {
                        shareholderParty = createShareholderCorporateParty(shareholder);
                    }
                    if (shareholderParty != null) {
                        shareholderParty.Id = existingPartyId; // SET EXISTING ID TO UPDATE
                        partiesToUpdate.add(shareholderParty);
                        partyMap.put(partyMapKey, existingPartyId); // Store with form ID key
                        System.debug(LoggingLevel.DEBUG, '✅ Party queued for UPDATE');
                    }
                } else {
                    // Create NEW Party record (first-time or additional shareholder)
                    String reason = '';
                    if (String.isBlank(existingPartyId)) {
                        reason = 'existingPartyId is blank/null';
                    } else if (!existingPartiesById.containsKey(existingPartyId)) {
                        reason = 'Party ID not found in existingPartiesById map';
                    }
                    System.debug(LoggingLevel.DEBUG, '🆕 CREATING NEW Party (Reason: ' + reason + ')');
                if (shareholder.type == 'Individual') {
                    shareholderParty = createShareholderIndividualParty(shareholder);
                } else if (shareholder.type == 'Corporate') {
                    shareholderParty = createShareholderCorporateParty(shareholder);
                }
                if (shareholderParty != null) {
                    partiesToInsert.add(shareholderParty);
                        tempIdToParty.put(partyMapKey, shareholderParty);
                        System.debug(LoggingLevel.DEBUG, '🆕 Party queued for INSERT');
                }
            }
                
                shareholderIndex++; // Increment for next shareholder
            }
        } else {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - No shareholders to process (null or empty)');
        }
        
        // Create/Update Authorized User Parties
        if (formData.authorisedUsers != null && !formData.authorisedUsers.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - authorisedUsers size=' + formData.authorisedUsers.size());
            
            Integer authUserIndex = 0;
            for (OnboardingFormDTO.AuthorisedUserDTO authUser : formData.authorisedUsers) {
                System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Processing auth user: id=' + authUser.id + ', index=' + authUserIndex);
                
                // Check if we have an existing Party ID for this authorized user (by sequence)
                String existingPartyKey = 'Authorised_User_' + authUserIndex;
                String existingPartyId = existingPartyIds.get(existingPartyKey);
                
                Party__c userParty;
                String partyMapKey = 'AuthorisedUser_' + authUser.id; // Key for partyMap (uses form ID)
                
                if (String.isNotBlank(existingPartyId) && existingPartiesById.containsKey(existingPartyId)) {
                    // REUSE existing Party record
                    System.debug(LoggingLevel.DEBUG, 'createPartyRecords - ✅ UPDATING existing AuthUser Party: ' + existingPartyId);
                    userParty = createAuthorizedUserParty(authUser);
                    if (userParty != null) {
                        userParty.Id = existingPartyId;
                        partiesToUpdate.add(userParty);
                        partyMap.put(partyMapKey, existingPartyId);
                    }
                } else {
                    // Create NEW Party record
                    System.debug(LoggingLevel.DEBUG, 'createPartyRecords - 🆕 CREATING NEW AuthUser Party');
                    userParty = createAuthorizedUserParty(authUser);
                if (userParty != null) {
                    partiesToInsert.add(userParty);
                        tempIdToParty.put(partyMapKey, userParty);
                    }
                }
                
                authUserIndex++;
            }
        }
        
        // Create/Update Additional Parties (Director / Signatory / UBO)
        if (formData.additionalParties != null && !formData.additionalParties.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - additionalParties size=' + formData.additionalParties.size());
            
            Integer additionalPartyIndex = 0;
            for (OnboardingFormDTO.AdditionalPartyDTO addl : formData.additionalParties) {
                System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Processing additional party: id=' + addl.id + ', role=' + addl.role + ', index=' + additionalPartyIndex);
                
                // Check if we have an existing Party ID (by role type and sequence)
                // Use the role from DTO (Director, Signatory, or UBO)
                String existingPartyKey = addl.role + '_' + additionalPartyIndex;
                String existingPartyId = existingPartyIds.get(existingPartyKey);
                
                Party__c extraParty;
                String partyMapKey = 'Additional_' + addl.id; // Key for partyMap (uses form ID)
                
                if (String.isNotBlank(existingPartyId) && existingPartiesById.containsKey(existingPartyId)) {
                    // REUSE existing Party record
                    System.debug(LoggingLevel.DEBUG, 'createPartyRecords - ✅ UPDATING existing Additional Party: ' + existingPartyId);
                    extraParty = createAdditionalParty(addl);
                    if (extraParty != null) {
                        extraParty.Id = existingPartyId;
                        partiesToUpdate.add(extraParty);
                        partyMap.put(partyMapKey, existingPartyId);
                    }
                } else {
                    // Create NEW Party record
                    System.debug(LoggingLevel.DEBUG, 'createPartyRecords - 🆕 CREATING NEW Additional Party');
                    extraParty = createAdditionalParty(addl);
                    if (extraParty != null) {
                        partiesToInsert.add(extraParty);
                        tempIdToParty.put(partyMapKey, extraParty);
                    }
                }
                
                additionalPartyIndex++;
            }
        }
        
        // Insert new parties
        if (!partiesToInsert.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - About to insert ' + partiesToInsert.size() + ' new parties');
            try {
                insert partiesToInsert;
                System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Successfully inserted ' + partiesToInsert.size() + ' new parties');
                
                // Map newly inserted parties
            for (String tempId : tempIdToParty.keySet()) {
                    Party__c party = tempIdToParty.get(tempId);
                    if (party.Id != null) {
                    partyMap.put(tempId, party.Id);
                        System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Mapped tempId: ' + tempId + ' -> Party Id: ' + party.Id);
                    } else {
                        System.debug(LoggingLevel.ERROR, 'createPartyRecords - Party inserted but Id is null for tempId: ' + tempId);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'createPartyRecords - Error inserting parties: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'createPartyRecords - Stack trace: ' + e.getStackTraceString());
                throw e; // Re-throw to be caught by outer try-catch
            }
        } else {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - No new parties to insert');
        }
        
        // Update existing parties with individual record error handling
        if (!partiesToUpdate.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - About to update ' + partiesToUpdate.size() + ' existing parties');
            
            // Build reverse map: Party ID -> partyMap key for tracking
            Map<Id, String> partyIdToKey = new Map<Id, String>();
            for (String key : partyMap.keySet()) {
                Id partyId = partyMap.get(key);
                if (partyId != null) {
                    partyIdToKey.put(partyId, key);
                    System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Tracking Party ' + partyId + ' -> key: ' + key);
                }
            }
            
            // Use Database.update with allOrNone=false to handle deleted records gracefully
            Database.SaveResult[] updateResults = Database.update(partiesToUpdate, false);
            
            Integer successCount = 0;
            Integer failCount = 0;
            Map<String, Party__c> failedPartiesByKey = new Map<String, Party__c>();
            
            for (Integer i = 0; i < updateResults.size(); i++) {
                Database.SaveResult sr = updateResults[i];
                if (sr.isSuccess()) {
                    successCount++;
                    System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Updated Party: ' + sr.getId());
                } else {
                    failCount++;
                    Party__c failedParty = partiesToUpdate[i];
                    
                    // Check if error is ENTITY_IS_DELETED
                    Boolean isDeleted = false;
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'createPartyRecords - Update error on Party ' + failedParty.Id + ': ' + err.getMessage());
                        if (err.getStatusCode() == StatusCode.ENTITY_IS_DELETED) {
                            isDeleted = true;
                            System.debug(LoggingLevel.WARN, 'createPartyRecords - Party ' + failedParty.Id + ' was deleted, will create NEW Party');
                        }
                    }
                    
                    // If party was deleted, create it as new (remove ID and re-insert)
                    if (isDeleted) {
                        // Look up the original key for this Party ID
                        String originalKey = partyIdToKey.get(failedParty.Id);
                        if (String.isNotBlank(originalKey)) {
                            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Deleted Party ' + failedParty.Id + ' was for key: ' + originalKey);
                            Party__c newParty = failedParty.clone(false, true, false, false); // Clone without ID
                            failedPartiesByKey.put(originalKey, newParty);
                        } else {
                            System.debug(LoggingLevel.ERROR, 'createPartyRecords - Could not find original key for deleted Party: ' + failedParty.Id);
                        }
                    } else {
                        // Other error - re-throw
                        throw new AuraHandledException('Failed to update Party: ' + sr.getErrors()[0].getMessage());
                    }
                }
            }
            
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Update results: ' + successCount + ' success, ' + failCount + ' failed');
            
            // Re-insert failed (deleted) parties as new records
            if (!failedPartiesByKey.isEmpty()) {
                System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Inserting ' + failedPartiesByKey.size() + ' deleted parties as NEW records');
                List<Party__c> failedParties = failedPartiesByKey.values();
                insert failedParties;
                
                // Update partyMap with new IDs (CRITICAL FIX!)
                for (String key : failedPartiesByKey.keySet()) {
                    Party__c newParty = failedPartiesByKey.get(key);
                    partyMap.put(key, newParty.Id);
                    System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Updated partyMap: ' + key + ' -> NEW Party ID: ' + newParty.Id);
                }
            }
        } else {
            System.debug(LoggingLevel.DEBUG, 'createPartyRecords - No existing parties to update');
        }
        
        System.debug(LoggingLevel.DEBUG, 'createPartyRecords - Final partyMap size: ' + partyMap.size() + ', keys: ' + partyMap.keySet());
        return partyMap;
    }
    
    /**
     * @description Creates an individual Party__c record from PersonalInfoDTO
     */
    private static Party__c createIndividualParty(OnboardingFormDTO.PersonalInfoDTO personalInfo) {
        Party__c party = new Party__c();
        party.Party_Type__c = 'Individual';
        party.Salutation__c = personalInfo.salutation;
        party.First_Name__c = personalInfo.firstName;
        party.Middle_Name__c = personalInfo.middleName;
        party.Last_Name__c = personalInfo.lastName;
        party.Suffix__c = personalInfo.suffix;
        
        // Build full legal name
        String fullName = '';
        if (String.isNotBlank(personalInfo.salutation)) fullName += personalInfo.salutation + ' ';
        if (String.isNotBlank(personalInfo.firstName)) fullName += personalInfo.firstName + ' ';
        if (String.isNotBlank(personalInfo.middleName)) fullName += personalInfo.middleName + ' ';
        if (String.isNotBlank(personalInfo.lastName)) fullName += personalInfo.lastName;
        if (String.isNotBlank(personalInfo.suffix)) fullName += ' ' + personalInfo.suffix;
        party.Full_Legal_Name__c = fullName.trim();
        
        // Date of birth
        party.Date_of_Birth__c = safeParseDate(personalInfo.dateOfBirth);
        
        party.Nationality__c = personalInfo.nationality;
        party.Country_of_Residence__c = personalInfo.countryOfResidence;
        party.Government_ID_Number__c = personalInfo.governmentIdNumber;
        party.Email__c = personalInfo.email;
        party.Mobile__c = personalInfo.mobile;
        party.Phone__c = personalInfo.phone;
        party.Website__c = personalInfo.website;
        // Convert 'Yes'/'No' string to Boolean for Checkbox field
        party.Is_PEP__c = (personalInfo.isPEP == 'Yes');
        
        return party;
    }
    
    /**
     * @description Creates a corporate Party__c record from CompanyInfoDTO
     */
    private static Party__c createCorporateParty(OnboardingFormDTO.CompanyInfoDTO companyInfo) {
        Party__c party = new Party__c();
        party.Party_Type__c = 'Organisation';
        party.Legal_Entity_Name__c = companyInfo.legalEntityName;
        party.Full_Legal_Name__c = companyInfo.legalEntityName;
        party.Legal_Entity_Type__c = companyInfo.legalEntityType;
        
        party.Date_of_Incorporation__c = safeParseDate(companyInfo.dateOfIncorporation);
        
        party.Country_of_Incorporation__c = companyInfo.countryOfIncorporation;
        party.Registration_Number__c = companyInfo.registrationNumber;
        party.Website__c = companyInfo.website;
        if (String.isNotBlank(companyInfo.email)) {
            party.Email__c = companyInfo.email;
        }
        if (String.isNotBlank(companyInfo.phone)) {
            party.Phone__c = companyInfo.phone;
        }
        
        // Note: The following fields may not exist on Party__c object
        // If deployment fails, these fields may need to be saved to Business_Profile__c or another object
        // We'll handle them in createBusinessProfile method below
        
        return party;
    }
    
    /**
     * @description Safely converts a string to Date, handling null and invalid formats
     * @param dateString String in YYYY-MM-DD format
     * @return Date or null if invalid
     */
    private static Date safeParseDate(String dateString) {
        if (String.isBlank(dateString)) {
            return null;
        }
        try {
            return Date.valueOf(dateString);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Invalid date format: ' + dateString + ' - ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Builds a full name from split name components (with all fields)
     * @param salutation Salutation (optional)
     * @param firstName First name
     * @param middleName Middle name (optional)
     * @param lastName Last name
     * @param suffix Suffix (optional)
     * @return String Full name with proper spacing
     */
    private static String buildFullName(String salutation, String firstName, String middleName, String lastName, String suffix) {
        List<String> nameParts = new List<String>();
        if (String.isNotBlank(salutation)) nameParts.add(salutation.trim());
        if (String.isNotBlank(firstName)) nameParts.add(firstName.trim());
        if (String.isNotBlank(middleName)) nameParts.add(middleName.trim());
        if (String.isNotBlank(lastName)) nameParts.add(lastName.trim());
        if (String.isNotBlank(suffix)) nameParts.add(suffix.trim());
        return String.join(nameParts, ' ');
    }
    
    /**
     * @description Builds a full name from split name components (backward compatibility)
     * @param firstName First name
     * @param middleName Middle name (optional)
     * @param lastName Last name
     * @return String Full name with proper spacing
     */
    private static String buildFullName(String firstName, String middleName, String lastName) {
        return buildFullName(null, firstName, middleName, lastName, null);
    }
    
    /**
     * @description Resolves the client display name from form data.
     * For Private clients returns "FirstName LastName".
     * For Corporate clients returns the Legal Entity Name.
     * Falls back to the existing value or a draft placeholder when no name data is available.
     * @param formData The onboarding form data
     * @return String The resolved client name
     */
    private static String resolveClientName(OnboardingFormDTO formData) {
        if (formData.clientType == 'Private' && formData.personalInfo != null) {
            String clientName = buildFullName(
                formData.personalInfo.firstName,
                formData.personalInfo.middleName,
                formData.personalInfo.lastName
            );
            if (String.isNotBlank(clientName)) {
                return clientName;
            }
        } else if (formData.clientType == 'Corporate' && formData.companyInfo != null) {
            if (String.isNotBlank(formData.companyInfo.legalEntityName)) {
                return formData.companyInfo.legalEntityName;
            }
        }
        // Fallback for early-stage drafts before name is captured
        return formData.clientType == 'Private' ? 'Draft - Private' : 'Draft - Corporate';
    }
    
    /**
     * @description Creates an individual Party__c record for a shareholder
     */
    private static Party__c createShareholderIndividualParty(OnboardingFormDTO.ShareholderDTO shareholder) {
        Party__c party = new Party__c();
        party.Party_Type__c = 'Individual';
        
        // Use split name fields
        party.Salutation__c = shareholder.salutation;
        party.First_Name__c = shareholder.firstName;
        party.Middle_Name__c = shareholder.middleName;
        party.Last_Name__c = shareholder.lastName;
        party.Suffix__c = shareholder.suffix;
        
        // Build full name from split fields (including salutation and suffix)
        party.Full_Legal_Name__c = buildFullName(shareholder.salutation, shareholder.firstName, shareholder.middleName, shareholder.lastName, shareholder.suffix);
        
        // Fallback to old name field if split names are empty (backward compatibility)
        if (String.isBlank(party.Full_Legal_Name__c) && String.isNotBlank(shareholder.name)) {
            party.Full_Legal_Name__c = shareholder.name;
        }
        
        party.Date_of_Birth__c = safeParseDate(shareholder.dateOfBirthOrIncorporation);
        
        party.Country_of_Residence__c = shareholder.countryOfResidenceOrIncorporation;
        party.Nationality__c = shareholder.nationalityOrCountryOfIncorporation;
        party.Government_ID_Number__c = shareholder.governmentIdOrRegistrationNumber;
        // Convert 'Yes'/'No' string to Boolean for Checkbox field
        party.Is_PEP__c = (shareholder.isPEP == 'Yes');
        party.Source_of_Wealth__c = shareholder.sourceOfWealth;
        party.Source_of_Wealth_Explanation__c = shareholder.sourceOfWealthExplanation;
        party.Email__c = shareholder.email;
        party.Mobile__c = shareholder.mobile;
        party.Phone__c = shareholder.phone;  // ADD: Phone mapping
        
        return party;
    }
    
    /**
     * @description Creates a corporate Party__c record for a shareholder
     */
    private static Party__c createShareholderCorporateParty(OnboardingFormDTO.ShareholderDTO shareholder) {
        Party__c party = new Party__c();
        party.Party_Type__c = 'Organisation';
        
        // Use legalEntityName field for corporates
        party.Legal_Entity_Name__c = shareholder.legalEntityName;
        party.Full_Legal_Name__c = shareholder.legalEntityName;
        
        // Fallback to old name field if legalEntityName is empty (backward compatibility)
        if (String.isBlank(party.Legal_Entity_Name__c) && String.isNotBlank(shareholder.name)) {
        party.Legal_Entity_Name__c = shareholder.name;
        party.Full_Legal_Name__c = shareholder.name;
        }
        
        party.Date_of_Incorporation__c = safeParseDate(shareholder.dateOfBirthOrIncorporation);
        
        party.Country_of_Incorporation__c = shareholder.countryOfResidenceOrIncorporation;
        party.Nationality__c = shareholder.nationalityOrCountryOfIncorporation;  // FIX: Add nationality mapping
        party.Registration_Number__c = shareholder.governmentIdOrRegistrationNumber;
        party.Is_PEP__c = (shareholder.isPEP == 'Yes');  // FIX: Add PEP mapping for Corporate
        party.Source_of_Wealth__c = shareholder.sourceOfWealth;
        party.Source_of_Wealth_Explanation__c = shareholder.sourceOfWealthExplanation;
        party.Email__c = shareholder.email;
        party.Mobile__c = shareholder.mobile;
        party.Phone__c = shareholder.phone;  // ADD: Phone mapping
        party.Website__c = shareholder.website;  // ADD: Website mapping
        
        return party;
    }

    /**
     * @description Creates Party__c for Additional Party (Director / Signatory / UBO)
     */
    private static Party__c createAdditionalParty(OnboardingFormDTO.AdditionalPartyDTO addl) {
        if (addl == null) return null;
        if (addl.type == 'Individual') {
            Party__c party = new Party__c();
            party.Party_Type__c = 'Individual';
            
            // Use split name fields
            party.Salutation__c = addl.salutation;
            party.First_Name__c = addl.firstName;
            party.Middle_Name__c = addl.middleName;
            party.Last_Name__c = addl.lastName;
            party.Suffix__c = addl.suffix;
            
            // Build full name (including salutation and suffix)
            party.Full_Legal_Name__c = buildFullName(addl.salutation, addl.firstName, addl.middleName, addl.lastName, addl.suffix);
            
            // Fallback to old name field (backward compatibility)
            if (String.isBlank(party.Full_Legal_Name__c) && String.isNotBlank(addl.name)) {
                party.Full_Legal_Name__c = addl.name;
            }
            
            party.Date_of_Birth__c = safeParseDate(addl.dateOfBirthOrIncorporation);
            party.Country_of_Residence__c = addl.countryOfResidenceOrIncorporation;
            party.Nationality__c = addl.nationalityOrCountryOfIncorporation;
            party.Government_ID_Number__c = addl.governmentIdOrRegistrationNumber;
            party.Is_PEP__c = (addl.isPEP == 'Yes');
            party.Email__c = addl.email;
            party.Mobile__c = addl.mobile;
            party.Phone__c = addl.phone;  // ADD: Phone mapping
            return party;
        } else if (addl.type == 'Corporate') {
            Party__c party = new Party__c();
            party.Party_Type__c = 'Organisation';
            
            // Use legalEntityName for corporates
            party.Legal_Entity_Name__c = addl.legalEntityName;
            party.Full_Legal_Name__c = addl.legalEntityName;
            
            // Fallback to old name field (backward compatibility)
            if (String.isBlank(party.Legal_Entity_Name__c) && String.isNotBlank(addl.name)) {
                party.Legal_Entity_Name__c = addl.name;
                party.Full_Legal_Name__c = addl.name;
            }
            
            party.Date_of_Incorporation__c = safeParseDate(addl.dateOfBirthOrIncorporation);
            party.Country_of_Incorporation__c = addl.countryOfResidenceOrIncorporation;
            party.Registration_Number__c = addl.governmentIdOrRegistrationNumber;
            party.Is_PEP__c = (addl.isPEP == 'Yes');
            party.Email__c = addl.email;
            party.Mobile__c = addl.mobile;
            party.Phone__c = addl.phone;  // ADD: Phone mapping
            party.Website__c = addl.website;  // ADD: Website mapping
            return party;
        }
        return null;
    }
    
    /**
     * @description Creates an individual Party__c record for an authorized user
     */
    private static Party__c createAuthorizedUserParty(OnboardingFormDTO.AuthorisedUserDTO authUser) {
        Party__c party = new Party__c();
        party.Party_Type__c = 'Individual';
        
        // Use split name fields
        party.Salutation__c = authUser.salutation;
        party.First_Name__c = authUser.firstName;
        party.Middle_Name__c = authUser.middleName;
        party.Last_Name__c = authUser.lastName;
        party.Suffix__c = authUser.suffix;
        
        // Build full name (including salutation and suffix)
        party.Full_Legal_Name__c = buildFullName(authUser.salutation, authUser.firstName, authUser.middleName, authUser.lastName, authUser.suffix);
        
        // Fallback to old name field (backward compatibility)
        if (String.isBlank(party.Full_Legal_Name__c) && String.isNotBlank(authUser.name)) {
        party.Full_Legal_Name__c = authUser.name;
        }
        
        party.Email__c = authUser.email;
        party.Mobile__c = authUser.mobileNumber;
        party.Phone__c = authUser.phone;  // ADD: Phone mapping
        
        party.Date_of_Birth__c = safeParseDate(authUser.dateOfBirth);
        
        party.Country_of_Residence__c = authUser.countryOfResidence;
        party.Nationality__c = authUser.nationality;
        party.Government_ID_Number__c = authUser.governmentIdNumber;
        // Convert 'Yes'/'No' string to Boolean for Checkbox field
        party.Is_PEP__c = (authUser.isPEP == 'Yes');
        
        return party;
    }
    
    /**
     * @description Creates Application_Party_Role__c records linking parties to application
     * Deletes existing roles for Shareholders/Authorized Users/Additional Parties and recreates them
     * Keeps Applicant role if it exists, updates it if party changed
     * @param applicationId Application ID
     * @param partyMap Map of role to party ID
     * @param formData Form data
     */
    private static void createApplicationPartyRoles(String applicationId, Map<String, String> partyMap, OnboardingFormDTO formData) {
        List<Application_Party_Role__c> rolesToInsert = new List<Application_Party_Role__c>();
        List<Application_Party_Role__c> rolesToUpdate = new List<Application_Party_Role__c>();
        System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - partyMap keys=' + partyMap.keySet());
        System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - shareholder count=' + (formData.shareholders == null ? 0 : formData.shareholders.size()) +
                                           ', authorisedUsers count=' + (formData.authorisedUsers == null ? 0 : formData.authorisedUsers.size()) +
                                           ', additionalParties count=' + (formData.additionalParties == null ? 0 : formData.additionalParties.size()));
        
        // DELETE all existing Shareholder, Authorised_User, and Additional Party roles
        // Then we'll create fresh ones (simpler and more reliable than trying to update)
        // But first, capture the Party__c IDs so we can reuse them (prevent orphaned Party records)
        Map<String, String> roleToPartyId = new Map<String, String>(); // Role__c + sequence -> Party__c.Id
        List<Application_Party_Role__c> rolesToDelete = [
            SELECT Id, Role__c, Party__c, 
                   Party__r.Full_Legal_Name__c, Party__r.Legal_Entity_Name__c,
                   Party__r.First_Name__c, Party__r.Last_Name__c
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :applicationId
            AND Role__c IN ('Shareholder', 'Authorised_User', 'Director', 'Signatory', 'UBO')
            ORDER BY CreatedDate ASC
        ];
        
        // Build a map of existing Party IDs by role and sequence (to preserve Party records)
        Map<String, Integer> roleSequence = new Map<String, Integer>{
            'Shareholder' => 0,
            'Authorised_User' => 0,
            'Director' => 0,
            'Signatory' => 0,
            'UBO' => 0
        };
        for (Application_Party_Role__c role : rolesToDelete) {
            if (role.Party__c != null) {
                String roleType = role.Role__c;
                Integer seq = roleSequence.get(roleType);
                roleSequence.put(roleType, seq + 1);
                String key = roleType + '_' + seq;
                roleToPartyId.put(key, role.Party__c);
                System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Captured Party for reuse: ' + key + ' -> ' + role.Party__c);
            }
        }
        
        // Capture Party IDs that might be orphaned after role deletion
        // (We'll check and cleanup at the END, after new roles are created)
        Set<Id> partyIdsToCheckForCleanup = new Set<Id>();
        for (Application_Party_Role__c role : rolesToDelete) {
            if (role.Party__c != null) {
                partyIdsToCheckForCleanup.add(role.Party__c);
            }
        }
        
        if (!rolesToDelete.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Deleting ' + rolesToDelete.size() + ' existing non-Applicant roles');
            delete rolesToDelete;
        }
        
        // Handle Applicant role - update if exists, create if not
        List<Application_Party_Role__c> existingApplicantRoles = [
            SELECT Id, Party__c
            FROM Application_Party_Role__c
            WHERE Onboarding_Application__c = :applicationId
            AND Role__c = 'Applicant'
            LIMIT 1
        ];
        
        if (partyMap.containsKey('Applicant')) {
            String applicantPartyId = partyMap.get('Applicant');
            if (!existingApplicantRoles.isEmpty()) {
                // Update existing applicant role
                Application_Party_Role__c existingRole = existingApplicantRoles[0];
                if (existingRole.Party__c != applicantPartyId) {
                    existingRole.Party__c = applicantPartyId;
                    update existingRole;
                }
            } else {
                // Create new applicant role
            Application_Party_Role__c applicantRole = new Application_Party_Role__c();
            applicantRole.Onboarding_Application__c = applicationId;
                applicantRole.Party__c = applicantPartyId;
            applicantRole.Role__c = 'Applicant';
            applicantRole.Is_Primary__c = true;
            rolesToInsert.add(applicantRole);
            }
        }
        
        // Create/Update Shareholder roles
        System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Checking shareholders: null=' + (formData.shareholders == null) + 
                                          ', isEmpty=' + (formData.shareholders != null ? formData.shareholders.isEmpty() : true));
        if (formData.shareholders != null && !formData.shareholders.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Processing ' + formData.shareholders.size() + ' shareholders');
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Available partyMap keys: ' + partyMap.keySet());
            
            for (OnboardingFormDTO.ShareholderDTO shareholder : formData.shareholders) {
                String partyKey = 'Shareholder_' + shareholder.id;
                System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Processing shareholder: id=' + shareholder.id + 
                                                  ', name=' + shareholder.name + ', partyKey=' + partyKey);
                
                if (partyMap.containsKey(partyKey)) {
                    String partyId = partyMap.get(partyKey);
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Found party in map: ' + partyId);
                    
                    // Create new role (old roles were deleted above)
                    Application_Party_Role__c shareholderRole = new Application_Party_Role__c();
                    shareholderRole.Onboarding_Application__c = applicationId;
                    shareholderRole.Party__c = partyId;
                    
                    // Set role boolean fields
                    shareholderRole.Is_Shareholder__c = (shareholder.isShareholder != null && shareholder.isShareholder);
                    shareholderRole.Is_Director__c = (shareholder.isDirector != null && shareholder.isDirector);
                    
                    // Set Role__c for backward compatibility (deprecated in favor of boolean fields)
                    // Use "Shareholder" as default if neither role is selected
                    if (shareholderRole.Is_Shareholder__c && shareholderRole.Is_Director__c) {
                        shareholderRole.Role__c = 'Shareholder';  // Primary role
                    } else if (shareholderRole.Is_Shareholder__c) {
                        shareholderRole.Role__c = 'Shareholder';
                    } else if (shareholderRole.Is_Director__c) {
                        shareholderRole.Role__c = 'Director';
                    } else {
                        shareholderRole.Role__c = 'Shareholder';  // Default fallback
                    }
                    
                    shareholderRole.KYC_Completed__c = false;
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Creating new shareholder/director role for Party: ' + partyId + 
                                 ', isShareholder=' + shareholderRole.Is_Shareholder__c + ', isDirector=' + shareholderRole.Is_Director__c);
                    
                    // Set Ownership_Percentage__c only if they are a Shareholder
                    if (shareholderRole.Is_Shareholder__c && String.isNotBlank(shareholder.ownershipPercentage)) {
                        try {
                            shareholderRole.Ownership_Percentage__c = Decimal.valueOf(shareholder.ownershipPercentage);
                            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Set ownership %: ' + shareholder.ownershipPercentage);
                        } catch (Exception e) {
                            System.debug(LoggingLevel.WARN, 'Failed to parse ownership percentage: ' + shareholder.ownershipPercentage + ', error: ' + e.getMessage());
                        }
                    }
                    
                    // Set Position/Role field only if they are a Director
                    if (shareholderRole.Is_Director__c && String.isNotBlank(shareholder.positionOrRole)) {
                        shareholderRole.Position_or_Role_Description__c = shareholder.positionOrRole;
                        System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Set position/role: ' + shareholder.positionOrRole);
                    }
                    
                    // Calculate KYC_Risk_Flags__c based on shareholder data
                    List<String> riskFlags = new List<String>();
                    if (shareholder.isPEP == 'Yes') {
                        riskFlags.add('PEP');
                    }
                    if (String.isNotBlank(shareholder.ownershipPercentage)) {
                        try {
                            Decimal ownershipPct = Decimal.valueOf(shareholder.ownershipPercentage);
                            if (ownershipPct >= 25) {
                                riskFlags.add('Significant Ownership (≥25%)');
                            }
                        } catch (Exception e) {
                            // Ignore parse errors
                        }
                    }
                    if (!riskFlags.isEmpty()) {
                        shareholderRole.KYC_Risk_Flags__c = String.join(riskFlags, '; ');
                        System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Set KYC_Risk_Flags: ' + shareholderRole.KYC_Risk_Flags__c);
                    }
                    
                    // Always insert (old roles were deleted above)
                    rolesToInsert.add(shareholderRole);
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Added shareholder role to insert list');
                } else {
                    System.debug(LoggingLevel.ERROR, 'createApplicationPartyRoles - Shareholder party NOT found in partyMap for key: ' + partyKey + 
                                                     '. Available keys: ' + partyMap.keySet() + ', shareholder.id=' + shareholder.id);
                }
            }
        } else {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - No shareholders to process (null or empty)');
        }
        
        // Create/Update Authorized User roles
        if (formData.authorisedUsers != null && !formData.authorisedUsers.isEmpty()) {
            for (OnboardingFormDTO.AuthorisedUserDTO authUser : formData.authorisedUsers) {
                String partyKey = 'AuthorisedUser_' + authUser.id;
                if (partyMap.containsKey(partyKey)) {
                    String partyId = partyMap.get(partyKey);
                    String roleKey = partyId + '_Authorised_User';
                    // Create new role (old roles were deleted above)
                    Application_Party_Role__c userRole = new Application_Party_Role__c();
                    userRole.Onboarding_Application__c = applicationId;
                    userRole.Party__c = partyId;
                    userRole.Role__c = 'Authorised_User';
                    userRole.KYC_Completed__c = false;
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Creating new auth user role for Party: ' + partyId);
                    
                    // Update Trading Experience
                    if (authUser.tradingExperience != null && !authUser.tradingExperience.isEmpty()) {
                        userRole.Trading_Experience__c = String.join(authUser.tradingExperience, ';');
                    }
                    
                    // Update Trade Frequency
                    if (String.isNotBlank(authUser.tradeFrequency)) {
                    userRole.Trade_Frequency__c = authUser.tradeFrequency;
                    }
                    
                    // ADD: Map Position/Role field
                    if (String.isNotBlank(authUser.position)) {
                        userRole.Position_or_Role_Description__c = authUser.position;
                    }
                    
                    // Calculate KYC_Risk_Flags__c for Authorised Users
                    List<String> riskFlags = new List<String>();
                    if (authUser.isPEP == 'Yes') {
                        riskFlags.add('PEP');
                    }
                    if (!riskFlags.isEmpty()) {
                        userRole.KYC_Risk_Flags__c = String.join(riskFlags, '; ');
                    }
                    
                    // Always insert (old roles were deleted above)
                    rolesToInsert.add(userRole);
                }
            }
        }
        
        // Create/Update Additional Party roles (Director / Signatory / UBO)
        if (formData.additionalParties != null && !formData.additionalParties.isEmpty()) {
            for (OnboardingFormDTO.AdditionalPartyDTO addl : formData.additionalParties) {
                String partyKey = 'Additional_' + addl.id;
                if (partyMap.containsKey(partyKey)) {
                    String partyId = partyMap.get(partyKey);
                    // Create new role (old roles were deleted above)
                    Application_Party_Role__c roleRec = new Application_Party_Role__c();
                    roleRec.Onboarding_Application__c = applicationId;
                    roleRec.Party__c = partyId;
                    roleRec.Role__c = addl.role;
                    roleRec.KYC_Completed__c = false;
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Creating new additional party role: ' + addl.role + ' for Party: ' + partyId);
                    
                    // Update Ownership Percentage
                    if (String.isNotBlank(addl.ownershipPercentage)) {
                        try {
                            roleRec.Ownership_Percentage__c = Decimal.valueOf(addl.ownershipPercentage);
                        } catch (Exception e) {
                            System.debug(LoggingLevel.WARN, 'Failed to parse ownership percentage: ' + addl.ownershipPercentage);
                        }
                    }
                    
                    // Update Position/Role Description
                    if (String.isNotBlank(addl.positionOrRole)) {
                        roleRec.Position_or_Role_Description__c = addl.positionOrRole;
                    }
                    
                    // Calculate KYC_Risk_Flags__c for Additional Parties
                    List<String> riskFlags = new List<String>();
                    if (addl.isPEP == 'Yes') {
                        riskFlags.add('PEP');
                    }
                    if (String.isNotBlank(addl.ownershipPercentage)) {
                        try {
                            Decimal ownershipPct = Decimal.valueOf(addl.ownershipPercentage);
                            if (ownershipPct >= 25) {
                                riskFlags.add('Significant Ownership (≥25%)');
                            }
                        } catch (Exception e) {
                            // Ignore parse errors
                        }
                    }
                    if (!riskFlags.isEmpty()) {
                        roleRec.KYC_Risk_Flags__c = String.join(riskFlags, '; ');
                    }
                    
                    // Always insert (old roles were deleted above)
                    rolesToInsert.add(roleRec);
                }
            }
        }
        
        // Insert new roles
        if (!rolesToInsert.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - About to insert ' + rolesToInsert.size() + ' new roles');
            try {
            insert rolesToInsert;
                System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Successfully inserted ' + rolesToInsert.size() + ' new roles');
                for (Application_Party_Role__c role : rolesToInsert) {
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Inserted role: Id=' + role.Id + 
                                                      ', Role=' + role.Role__c + ', Party=' + role.Party__c + 
                                                      ', Ownership_Percentage__c=' + role.Ownership_Percentage__c);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'createApplicationPartyRoles - Error inserting roles: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'createApplicationPartyRoles - Stack trace: ' + e.getStackTraceString());
                throw e;
            }
        } else {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - No new roles to insert');
        }
        
        // Update existing roles
        if (!rolesToUpdate.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - About to update ' + rolesToUpdate.size() + ' existing roles');
            try {
                update rolesToUpdate;
                System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Successfully updated ' + rolesToUpdate.size() + ' existing roles');
                for (Application_Party_Role__c role : rolesToUpdate) {
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Updated role: Id=' + role.Id + 
                                                      ', Role=' + role.Role__c + ', Ownership_Percentage__c=' + role.Ownership_Percentage__c +
                                                      ', KYC_Completed__c=' + role.KYC_Completed__c);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'createApplicationPartyRoles - Error updating roles: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'createApplicationPartyRoles - Stack trace: ' + e.getStackTraceString());
                throw e;
            }
        } else {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - No existing roles to update');
        }
        
        // CLEANUP: Delete orphaned Party records that are no longer linked to any role
        // This runs AFTER all new roles have been created to avoid deleting Parties that are being reused
        if (!partyIdsToCheckForCleanup.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Checking for orphaned Party records (cleanup phase)');
            
            // Query to find which of these Party IDs are still linked to roles (after new roles created)
            Set<Id> partiesStillInUse = new Set<Id>();
            for (Application_Party_Role__c remainingRole : [
                SELECT Party__c
                FROM Application_Party_Role__c
                WHERE Party__c IN :partyIdsToCheckForCleanup
            ]) {
                if (remainingRole.Party__c != null) {
                    partiesStillInUse.add(remainingRole.Party__c);
                }
            }
            
            // Identify orphaned Party records (not linked to any role)
            Set<Id> orphanedPartyIds = new Set<Id>();
            for (Id partyId : partyIdsToCheckForCleanup) {
                if (!partiesStillInUse.contains(partyId)) {
                    orphanedPartyIds.add(partyId);
                }
            }
            
            // Delete orphaned Party records
            if (!orphanedPartyIds.isEmpty()) {
                List<Party__c> orphanedParties = [
                    SELECT Id, Full_Legal_Name__c FROM Party__c WHERE Id IN :orphanedPartyIds
                ];
                System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Deleting ' + orphanedParties.size() + ' orphaned Party records');
                for (Party__c p : orphanedParties) {
                    System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - Deleting orphaned Party: ' + p.Id + ' (' + p.Full_Legal_Name__c + ')');
                }
                delete orphanedParties;
            } else {
                System.debug(LoggingLevel.DEBUG, 'createApplicationPartyRoles - No orphaned Party records to cleanup');
            }
        }
    }
    
    /**
     * @description Creates or Updates Party_Address__c records
     * @param partyMap Map of role to party ID
     * @param formData Form data
     */
    private static void createPartyAddresses(Map<String, String> partyMap, OnboardingFormDTO formData) {
        List<Party_Address__c> addressesToInsert = new List<Party_Address__c>();
        List<Party_Address__c> addressesToUpdate = new List<Party_Address__c>();
        
        // Query ALL existing addresses for ALL parties to prevent duplicates
        Map<String, Party_Address__c> existingAddressesByPartyAndType = new Map<String, Party_Address__c>();
        
        // Get all Party IDs from the partyMap
        Set<String> allPartyIds = new Set<String>(partyMap.values());
        
        if (!allPartyIds.isEmpty()) {
            for (Party_Address__c existingAddr : [
                SELECT Id, Party__c, Address_Type__c, Is_Primary__c
                FROM Party_Address__c
                WHERE Party__c IN :allPartyIds
            ]) {
                // Key format: PartyId_AddressType_IsPrimary
                String key = existingAddr.Party__c + '_' + existingAddr.Address_Type__c + '_' + existingAddr.Is_Primary__c;
                existingAddressesByPartyAndType.put(key, existingAddr);
            }
        }
        
        System.debug(LoggingLevel.DEBUG, 'createPartyAddresses - Found ' + existingAddressesByPartyAndType.size() + ' existing addresses');
        
        // For backward compatibility with Applicant addresses
        Map<String, Party_Address__c> existingAddressesByType = new Map<String, Party_Address__c>();
        if (partyMap.containsKey('Applicant')) {
            String applicantPartyId = partyMap.get('Applicant');
            for (String key : existingAddressesByPartyAndType.keySet()) {
                if (key.startsWith(applicantPartyId + '_')) {
                    Party_Address__c addr = existingAddressesByPartyAndType.get(key);
                    String shortKey = addr.Address_Type__c + '_' + addr.Is_Primary__c;
                    existingAddressesByType.put(shortKey, addr);
                }
            }
        }
        
        // Create/Update primary address for applicant (ONLY if it has data)
        if (formData.addressInfo != null && partyMap.containsKey('Applicant')) {
            // Check if address has actual data (not all blank)
            Boolean hasAddressData = String.isNotBlank(formData.addressInfo.street) ||
                                    String.isNotBlank(formData.addressInfo.city) ||
                                    String.isNotBlank(formData.addressInfo.country);
            
            if (hasAddressData) {
                String addressType = '';
                if (String.isNotBlank(formData.addressInfo.addressType)) {
                    addressType = formData.addressInfo.addressType;
                } else if (formData.clientType == 'Private') {
                    addressType = 'Residential';
                } else {
                    addressType = 'Business';
                }
                
                String applicantPartyId = partyMap.get('Applicant');
                Party_Address__c address;
                
                // IMPROVED: Find ANY primary address for this party, regardless of type
                // This prevents duplicates when addressType changes or isn't loaded
                Boolean foundExisting = false;
                for (String key : existingAddressesByPartyAndType.keySet()) {
                    if (key.startsWith(applicantPartyId + '_') && key.endsWith('_true')) {
                        // Found a primary address for this party
                        address = existingAddressesByPartyAndType.get(key);
                        foundExisting = true;
                        System.debug('🔄 Updating existing primary address for Applicant: ' + address.Id + ' (Type: ' + address.Address_Type__c + ')');
                        break;
                    }
                }
                
                if (!foundExisting) {
                    // Create new address
                    address = new Party_Address__c();
                    address.Party__c = applicantPartyId;
                    address.Is_Primary__c = true;
                    System.debug('✨ Creating new primary address for Applicant (Type: ' + addressType + ')');
                }
                
                // Update address fields (including type, which might have changed)
                address.Address_Type__c = addressType;
                address.Street__c = formData.addressInfo.street;
                address.City__c = formData.addressInfo.city;
                address.State__c = formData.addressInfo.state;
                address.Postal_Code__c = formData.addressInfo.postalCode;
                address.Country__c = formData.addressInfo.country;
                address.Source__c = 'Manual';
                
                if (formData.addressInfo.addressVerified != null) {
                    address.Verified__c = formData.addressInfo.addressVerified;
                }
                if (String.isNotBlank(formData.addressInfo.verificationProvider)) {
                    address.Verification_Provider__c = formData.addressInfo.verificationProvider;
                }
                
                if (address.Id != null) {
                    addressesToUpdate.add(address);
                } else {
                    addressesToInsert.add(address);
                }
            }
        }
        
        // Create registered business address and principal place of business for corporate (ONLY if not blank)
        if (formData.clientType == 'Corporate' && formData.companyInfo != null && 
            partyMap.containsKey('Applicant')) {
            // Registered Business Address (structured fields)
            Boolean hasRegisteredAddress = String.isNotBlank(formData.companyInfo.registeredStreet) ||
                                          String.isNotBlank(formData.companyInfo.registeredCity) ||
                                          String.isNotBlank(formData.companyInfo.registeredCountry);
            
            if (hasRegisteredAddress) {
                String regKey = 'Registered_false';
                Party_Address__c regAddress;
                
                if (existingAddressesByType.containsKey(regKey)) {
                    regAddress = existingAddressesByType.get(regKey);
                } else {
                    regAddress = new Party_Address__c();
            regAddress.Party__c = partyMap.get('Applicant');
            regAddress.Address_Type__c = 'Registered';
            regAddress.Is_Primary__c = false;
            regAddress.Source__c = 'Manual';
                }
                
                regAddress.Street__c = formData.companyInfo.registeredStreet;
                regAddress.City__c = formData.companyInfo.registeredCity;
                regAddress.State__c = formData.companyInfo.registeredState;
                regAddress.Postal_Code__c = formData.companyInfo.registeredPostalCode;
                regAddress.Country__c = formData.companyInfo.registeredCountry;
                
                if (regAddress.Id != null) {
                    addressesToUpdate.add(regAddress);
                } else {
            addressesToInsert.add(regAddress);
                }
            }
        }
        
        // Create/Update addresses for Shareholders (if they have address data)
        if (formData.shareholders != null && !formData.shareholders.isEmpty()) {
            Integer shareholderIndex = 0;
            for (OnboardingFormDTO.ShareholderDTO shareholder : formData.shareholders) {
                String partyKey = 'Shareholder_' + shareholder.id;
                
                if (partyMap.containsKey(partyKey)) {
                    // Check if shareholder has address data
                    Boolean hasAddressData = String.isNotBlank(shareholder.street) ||
                                            String.isNotBlank(shareholder.city) ||
                                            String.isNotBlank(shareholder.country);
                    
                    if (hasAddressData) {
                        String shareholderPartyId = partyMap.get(partyKey);
                        String addressType = (shareholder.type == 'Individual') ? 'Residential' : 'Business';
                        String addressKey = shareholderPartyId + '_' + addressType + '_true';
                        
                        Party_Address__c shareholderAddress;
                        
                        // Check if address already exists
                        if (existingAddressesByPartyAndType.containsKey(addressKey)) {
                            // Update existing address
                            shareholderAddress = existingAddressesByPartyAndType.get(addressKey);
                            System.debug(LoggingLevel.DEBUG, 'Updating existing shareholder address: ' + shareholderAddress.Id);
                        } else {
                            // Create new address
                            shareholderAddress = new Party_Address__c();
                            shareholderAddress.Party__c = shareholderPartyId;
                            shareholderAddress.Address_Type__c = addressType;
                            shareholderAddress.Is_Primary__c = true;
                            shareholderAddress.Source__c = 'Manual';
                            System.debug(LoggingLevel.DEBUG, 'Creating new shareholder address for Party: ' + shareholderPartyId);
                        }
                        
                        // Set/Update address fields
                        shareholderAddress.Street__c = shareholder.street;
                        shareholderAddress.City__c = shareholder.city;
                        shareholderAddress.State__c = shareholder.state;
                        shareholderAddress.Postal_Code__c = shareholder.postalCode;
                        shareholderAddress.Country__c = shareholder.country;
                        
                        if (shareholderAddress.Id != null) {
                            addressesToUpdate.add(shareholderAddress);
                        } else {
                            addressesToInsert.add(shareholderAddress);
                        }
                    }
                }
                shareholderIndex++;
            }
        }
        
        // Create/Update addresses for Authorized Users (if they have address data)
        if (formData.authorisedUsers != null && !formData.authorisedUsers.isEmpty()) {
            Integer authUserIndex = 0;
            for (OnboardingFormDTO.AuthorisedUserDTO authUser : formData.authorisedUsers) {
                String partyKey = 'AuthorisedUser_' + authUser.id;
                
                if (partyMap.containsKey(partyKey)) {
                    // Check if authorized user has address data
                    Boolean hasAddressData = String.isNotBlank(authUser.street) ||
                                            String.isNotBlank(authUser.city) ||
                                            String.isNotBlank(authUser.country);
                    
                    if (hasAddressData) {
                        String authUserPartyId = partyMap.get(partyKey);
                        String addressType = 'Residential';
                        String addressKey = authUserPartyId + '_' + addressType + '_true';
                        
                        Party_Address__c authUserAddress;
                        
                        // Check if address already exists
                        if (existingAddressesByPartyAndType.containsKey(addressKey)) {
                            // Update existing address
                            authUserAddress = existingAddressesByPartyAndType.get(addressKey);
                            System.debug(LoggingLevel.DEBUG, 'Updating existing auth user address: ' + authUserAddress.Id);
                        } else {
                            // Create new address
                            authUserAddress = new Party_Address__c();
                            authUserAddress.Party__c = authUserPartyId;
                            authUserAddress.Address_Type__c = addressType;
                            authUserAddress.Is_Primary__c = true;
                            authUserAddress.Source__c = 'Manual';
                            System.debug(LoggingLevel.DEBUG, 'Creating new auth user address for Party: ' + authUserPartyId);
                        }
                        
                        // Set/Update address fields
                        authUserAddress.Street__c = authUser.street;
                        authUserAddress.City__c = authUser.city;
                        authUserAddress.State__c = authUser.state;
                        authUserAddress.Postal_Code__c = authUser.postalCode;
                        authUserAddress.Country__c = authUser.country;
                        
                        if (authUserAddress.Id != null) {
                            addressesToUpdate.add(authUserAddress);
                        } else {
                            addressesToInsert.add(authUserAddress);
                        }
                    }
                }
                authUserIndex++;
            }
        }
        
        // Create/Update addresses for Additional Parties (if they have address data)
        if (formData.additionalParties != null && !formData.additionalParties.isEmpty()) {
            Integer additionalPartyIndex = 0;
            for (OnboardingFormDTO.AdditionalPartyDTO addlParty : formData.additionalParties) {
                String partyKey = 'Additional_' + addlParty.id;
                
                if (partyMap.containsKey(partyKey)) {
                    // Check if additional party has address data
                    Boolean hasAddressData = String.isNotBlank(addlParty.street) ||
                                            String.isNotBlank(addlParty.city) ||
                                            String.isNotBlank(addlParty.country);
                    
                    if (hasAddressData) {
                        String addlPartyId = partyMap.get(partyKey);
                        String addressType = (addlParty.type == 'Individual') ? 'Residential' : 'Business';
                        String addressKey = addlPartyId + '_' + addressType + '_true';
                        
                        Party_Address__c addlPartyAddress;
                        
                        // Check if address already exists
                        if (existingAddressesByPartyAndType.containsKey(addressKey)) {
                            // Update existing address
                            addlPartyAddress = existingAddressesByPartyAndType.get(addressKey);
                            System.debug(LoggingLevel.DEBUG, 'Updating existing additional party address: ' + addlPartyAddress.Id);
                        } else {
                            // Create new address
                            addlPartyAddress = new Party_Address__c();
                            addlPartyAddress.Party__c = addlPartyId;
                            addlPartyAddress.Address_Type__c = addressType;
                            addlPartyAddress.Is_Primary__c = true;
                            addlPartyAddress.Source__c = 'Manual';
                            System.debug(LoggingLevel.DEBUG, 'Creating new additional party address for Party: ' + addlPartyId);
                        }
                        
                        // Set/Update address fields
                        addlPartyAddress.Street__c = addlParty.street;
                        addlPartyAddress.City__c = addlParty.city;
                        addlPartyAddress.State__c = addlParty.state;
                        addlPartyAddress.Postal_Code__c = addlParty.postalCode;
                        addlPartyAddress.Country__c = addlParty.country;
                        
                        if (addlPartyAddress.Id != null) {
                            addressesToUpdate.add(addlPartyAddress);
                        } else {
                            addressesToInsert.add(addlPartyAddress);
                        }
                    }
                }
                additionalPartyIndex++;
            }
        }
        
        if (!addressesToInsert.isEmpty()) {
            insert addressesToInsert;
        }
        if (!addressesToUpdate.isEmpty()) {
            update addressesToUpdate;
        }
    }
    
    /**
     * @description Creates or Updates Business_Profile__c record for corporate clients
     * Handles both draft saves (when companyInfo is available) and final submission (when businessContext is available)
     * @param applicationId Application ID
     * @param formData Form data
     * @return Created/Updated record ID
     */
    private static String createOrUpdateBusinessProfile(String applicationId, OnboardingFormDTO formData) {
        System.debug(LoggingLevel.DEBUG, '=== CREATE/UPDATE BUSINESS PROFILE CALLED ===');
        System.debug(LoggingLevel.DEBUG, 'Application ID: ' + applicationId);
        System.debug(LoggingLevel.DEBUG, 'Has companyInfo: ' + (formData.companyInfo != null));
        System.debug(LoggingLevel.DEBUG, 'Has businessContext: ' + (formData.businessContext != null));
        if (formData.companyInfo != null) {
            System.debug(LoggingLevel.DEBUG, 'Nature of Business: ' + formData.companyInfo.natureOfBusiness);
            System.debug(LoggingLevel.DEBUG, 'Restricted Activities: ' + formData.companyInfo.restrictedActivities);
            System.debug(LoggingLevel.DEBUG, 'Expected Employees: ' + formData.companyInfo.expectedNumberOfEmployees);
        }
        
        // Query for existing Business_Profile__c record
        // Include all fields we need to read during update logic
        List<Business_Profile__c> existingProfiles = [
            SELECT Id, 
                   Products_and_Services__c,
                   Source_of_Wealth_Explanation__c,
                   Industry__c
            FROM Business_Profile__c
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];
        
        Business_Profile__c businessProfile;
        if (!existingProfiles.isEmpty()) {
            businessProfile = existingProfiles[0];
        } else {
            businessProfile = new Business_Profile__c();
        businessProfile.Onboarding_Application__c = applicationId;
        }
        
        // Save company information fields from Company Information step
        if (formData.companyInfo != null) {
            System.debug(LoggingLevel.DEBUG, 'Saving Company Information to Business_Profile__c');
            System.debug(LoggingLevel.DEBUG, 'Nature of Business: ' + formData.companyInfo.natureOfBusiness);
            System.debug(LoggingLevel.DEBUG, 'Regulator Name: ' + formData.companyInfo.regulatorName);
            
            // Nature of Business - save to Products_and_Services__c if businessContext.productsAndServices is not set
            // Check if we're still in "Company Info only" mode (Business Context not filled yet)
            Boolean isBusinessContextFilled = (formData.businessContext != null && String.isNotBlank(formData.businessContext.productsAndServices));
            
            if (String.isNotBlank(formData.companyInfo.natureOfBusiness)) {
                if (!isBusinessContextFilled) {
                    // If Business Context hasn't been filled yet, directly set/update the field
                    businessProfile.Products_and_Services__c = formData.companyInfo.natureOfBusiness;
                    System.debug(LoggingLevel.DEBUG, 'Nature of Business saved (Company Info only mode): ' + businessProfile.Products_and_Services__c);
                } else {
                    // If Business Context is filled, preserve both values
                    if (String.isBlank(businessProfile.Products_and_Services__c)) {
                        businessProfile.Products_and_Services__c = formData.companyInfo.natureOfBusiness;
                    } else if (!businessProfile.Products_and_Services__c.contains('Nature of Business:')) {
                        // Prepend Nature of Business only if it's not already there
                        businessProfile.Products_and_Services__c = 'Nature of Business: ' + formData.companyInfo.natureOfBusiness + '\n\n' + businessProfile.Products_and_Services__c;
                    }
                    System.debug(LoggingLevel.DEBUG, 'Nature of Business saved (with Business Context): ' + businessProfile.Products_and_Services__c);
                }
            }
            
            // Save all company information fields
            // Note: If deployment fails, these fields may need to be created on Business_Profile__c
            // Trading Name - only append if Business Context is filled
            if (String.isNotBlank(formData.companyInfo.tradingName) && isBusinessContextFilled) {
                // Store in Products_and_Services__c as a workaround if Trading_Name__c doesn't exist
                // Format: "Trading Name: [value]" if Products_and_Services__c is already set
                String tradingNameNote = 'Trading Name: ' + formData.companyInfo.tradingName;
                if (String.isNotBlank(businessProfile.Products_and_Services__c) && !businessProfile.Products_and_Services__c.contains('Trading Name:')) {
                    businessProfile.Products_and_Services__c = businessProfile.Products_and_Services__c + '\n\n' + tradingNameNote;
                } else if (String.isBlank(businessProfile.Products_and_Services__c)) {
                    businessProfile.Products_and_Services__c = tradingNameNote;
                }
            }
            
            // Regulatory Information - save to dedicated fields
            if (String.isNotBlank(formData.companyInfo.isRegulatedFinancialInstitution)) {
                businessProfile.Is_Regulated__c = formData.companyInfo.isRegulatedFinancialInstitution == 'Yes';
            }
            if (String.isNotBlank(formData.companyInfo.regulatorName)) {
                businessProfile.Regulator_Name__c = formData.companyInfo.regulatorName;
            }
            if (String.isNotBlank(formData.companyInfo.regulatoryLicenceNumber)) {
                businessProfile.Regulatory_Licence_Number__c = formData.companyInfo.regulatoryLicenceNumber;
            }
            if (String.isNotBlank(formData.companyInfo.regulatoryJurisdiction)) {
                businessProfile.Regulatory_Jurisdiction__c = formData.companyInfo.regulatoryJurisdiction;
            }
            
            // Restricted Activities - save to dedicated field
            if (formData.companyInfo.restrictedActivities != null && !formData.companyInfo.restrictedActivities.isEmpty()) {
                businessProfile.Restricted_Activities__c = String.join(formData.companyInfo.restrictedActivities, ';');
                System.debug(LoggingLevel.DEBUG, 'Restricted Activities: ' + businessProfile.Restricted_Activities__c);
            }
            
            // Expected Number of Employees - save to dedicated field
            if (String.isNotBlank(formData.companyInfo.expectedNumberOfEmployees)) {
                try {
                    businessProfile.Expected_Number_of_Employees__c = Integer.valueOf(formData.companyInfo.expectedNumberOfEmployees);
                    System.debug(LoggingLevel.DEBUG, 'Expected Number of Employees: ' + businessProfile.Expected_Number_of_Employees__c);
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, 'Could not parse expectedNumberOfEmployees: ' + formData.companyInfo.expectedNumberOfEmployees);
                }
            }
        }
        
        // Save business context fields (from Business Context step)
        if (formData.businessContext != null) {
            System.debug(LoggingLevel.DEBUG, '💼 === SAVING BUSINESS CONTEXT TO BUSINESS_PROFILE ===');
            System.debug(LoggingLevel.DEBUG, 'Purpose of Account: ' + formData.businessContext.purposeOfAccount);
            System.debug(LoggingLevel.DEBUG, 'Industry: ' + formData.businessContext.industry);
        businessProfile.Purpose_of_Account__c = formData.businessContext.purposeOfAccount;
            if (String.isNotBlank(formData.businessContext.industry)) {
        businessProfile.Industry__c = formData.businessContext.industry;
            }
            if (String.isNotBlank(formData.businessContext.productsAndServices)) {
        businessProfile.Products_and_Services__c = formData.businessContext.productsAndServices;
            }
        
        if (formData.businessContext.paymentFlowTypes != null && !formData.businessContext.paymentFlowTypes.isEmpty()) {
            businessProfile.Payment_Flow_Types__c = String.join(formData.businessContext.paymentFlowTypes, ';');
        }
        
        if (String.isNotBlank(formData.businessContext.expectedTransactionsPerMonth)) {
            businessProfile.Expected_Transactions_per_Month__c = Decimal.valueOf(formData.businessContext.expectedTransactionsPerMonth);
        }
        
        if (String.isNotBlank(formData.businessContext.expectedAnnualVolume)) {
            businessProfile.Expected_Annual_Volume__c = Decimal.valueOf(formData.businessContext.expectedAnnualVolume);
        }
        
        if (String.isNotBlank(formData.businessContext.typicalValuePerTransaction)) {
            businessProfile.Typical_Value_per_Transaction__c = Decimal.valueOf(formData.businessContext.typicalValuePerTransaction);
        }
        
        if (formData.businessContext.currenciesToSend != null && !formData.businessContext.currenciesToSend.isEmpty()) {
            businessProfile.Currencies_to_Send__c = String.join(formData.businessContext.currenciesToSend, ';');
        }
        
        if (formData.businessContext.currenciesToReceive != null && !formData.businessContext.currenciesToReceive.isEmpty()) {
            businessProfile.Currencies_to_Receive__c = String.join(formData.businessContext.currenciesToReceive, ';');
        }
        
        if (formData.businessContext.countriesFundsSentTo != null && !formData.businessContext.countriesFundsSentTo.isEmpty()) {
            businessProfile.Countries_Sent_To__c = String.join(formData.businessContext.countriesFundsSentTo, ';');
        }
        
        if (formData.businessContext.countriesFundsReceivedFrom != null && !formData.businessContext.countriesFundsReceivedFrom.isEmpty()) {
            businessProfile.Countries_Received_From__c = String.join(formData.businessContext.countriesFundsReceivedFrom, ';');
        }
        
        if (String.isNotBlank(formData.businessContext.largestSingleTransaction)) {
            businessProfile.Largest_Single_Transaction__c = Decimal.valueOf(formData.businessContext.largestSingleTransaction);
        }
        
            // High-Risk Jurisdiction and Anticipated Sanctioned Counterparties fields removed per requirements
        businessProfile.Primary_Source_of_Funds__c = formData.businessContext.primarySourceOfFunds;
        // businessProfile.Source_of_Wealth_for_Owners__c removed - captured in Explanation field
        // Keep this mapping idempotent: always set from current form value.
        if (String.isNotBlank(formData.businessContext.sourceOfWealthExplanation)) {
            businessProfile.Source_of_Wealth_Explanation__c = formData.businessContext.sourceOfWealthExplanation;
        }
            System.debug(LoggingLevel.DEBUG, '✅ Business Context fields saved to businessProfile object');
            System.debug(LoggingLevel.DEBUG, 'Purpose: ' + businessProfile.Purpose_of_Account__c);
            System.debug(LoggingLevel.DEBUG, 'Products/Services: ' + businessProfile.Products_and_Services__c);
            System.debug(LoggingLevel.DEBUG, 'Primary Source of Funds: ' + businessProfile.Primary_Source_of_Funds__c);
            System.debug(LoggingLevel.DEBUG, '💼 === END BUSINESS CONTEXT SAVE ===');
        }
        
        // Save currency/country fields from serviceProfiles (for Private Individual FX service)
        // Corporate clients save these via businessContext (above), Private clients save via serviceProfiles
        if (formData.serviceProfiles != null && !formData.serviceProfiles.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, '🔄 === SAVING SERVICE PROFILE CURRENCIES/COUNTRIES TO BUSINESS_PROFILE ===');
            for (OnboardingFormDTO.ServiceProfileDTO serviceDTO : formData.serviceProfiles) {
                if (serviceDTO.serviceType == 'FX') {
                    System.debug(LoggingLevel.DEBUG, '💱 Processing FX service profile for Business_Profile__c');
                    
                    // Save currencies (if not already saved from businessContext)
                    if (serviceDTO.currenciesToSend != null && !serviceDTO.currenciesToSend.isEmpty()) {
                        businessProfile.Currencies_to_Send__c = String.join(serviceDTO.currenciesToSend, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Saved Currencies_to_Send__c: ' + businessProfile.Currencies_to_Send__c);
                    }
                    
                    if (serviceDTO.currenciesToReceive != null && !serviceDTO.currenciesToReceive.isEmpty()) {
                        businessProfile.Currencies_to_Receive__c = String.join(serviceDTO.currenciesToReceive, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Saved Currencies_to_Receive__c: ' + businessProfile.Currencies_to_Receive__c);
                    }
                    
                    // Save countries
                    if (serviceDTO.countriesFundsSentTo != null && !serviceDTO.countriesFundsSentTo.isEmpty()) {
                        businessProfile.Countries_Sent_To__c = String.join(serviceDTO.countriesFundsSentTo, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Saved Countries_Sent_To__c: ' + businessProfile.Countries_Sent_To__c);
                    }
                    
                    if (serviceDTO.countriesFundsReceivedFrom != null && !serviceDTO.countriesFundsReceivedFrom.isEmpty()) {
                        businessProfile.Countries_Received_From__c = String.join(serviceDTO.countriesFundsReceivedFrom, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Saved Countries_Received_From__c: ' + businessProfile.Countries_Received_From__c);
                    }
                    
                    System.debug(LoggingLevel.DEBUG, '💱 FX service profile currency/country data saved to Business_Profile__c');
                    break; // Only process first FX service profile
                }
            }
            System.debug(LoggingLevel.DEBUG, '🔄 === END SERVICE PROFILE CURRENCIES/COUNTRIES SAVE ===');
        }
        
        // Only upsert if we have at least some data to save
        // This prevents creating empty Business_Profile__c records during draft saves
        Boolean hasDataToSave = false;
        if (formData.companyInfo != null) {
            hasDataToSave = String.isNotBlank(formData.companyInfo.natureOfBusiness) ||
                           String.isNotBlank(formData.companyInfo.tradingName) ||
                           (formData.companyInfo.restrictedActivities != null && !formData.companyInfo.restrictedActivities.isEmpty()) ||
                           String.isNotBlank(formData.companyInfo.expectedNumberOfEmployees) ||
                           String.isNotBlank(formData.companyInfo.isRegulatedFinancialInstitution) ||
                           String.isNotBlank(formData.companyInfo.regulatorName) ||
                           String.isNotBlank(formData.companyInfo.regulatoryLicenceNumber) ||
                           String.isNotBlank(formData.companyInfo.regulatoryJurisdiction) ||
                           String.isNotBlank(formData.companyInfo.website) ||
                           String.isNotBlank(formData.companyInfo.email) ||
                           String.isNotBlank(formData.companyInfo.phone);
        }
        if (formData.businessContext != null) {
            // Check for any Business Context field, not just purposeOfAccount
            hasDataToSave = hasDataToSave || 
                           String.isNotBlank(formData.businessContext.purposeOfAccount) ||
                           String.isNotBlank(formData.businessContext.productsAndServices) ||
                           (formData.businessContext.paymentFlowTypes != null && !formData.businessContext.paymentFlowTypes.isEmpty()) ||
                           String.isNotBlank(formData.businessContext.expectedTransactionsPerMonth) ||
                           String.isNotBlank(formData.businessContext.expectedAnnualVolume) ||
                           String.isNotBlank(formData.businessContext.typicalValuePerTransaction) ||
                           (formData.businessContext.currenciesToSend != null && !formData.businessContext.currenciesToSend.isEmpty()) ||
                           (formData.businessContext.currenciesToReceive != null && !formData.businessContext.currenciesToReceive.isEmpty()) ||
                           (formData.businessContext.countriesFundsSentTo != null && !formData.businessContext.countriesFundsSentTo.isEmpty()) ||
                           (formData.businessContext.countriesFundsReceivedFrom != null && !formData.businessContext.countriesFundsReceivedFrom.isEmpty()) ||
                           String.isNotBlank(formData.businessContext.primarySourceOfFunds) ||
                           String.isNotBlank(formData.businessContext.sourceOfWealthExplanation);
            System.debug(LoggingLevel.DEBUG, '📊 Business Context Data Check - hasDataToSave: ' + hasDataToSave);
        }
        // Check for serviceProfiles with currency/country data (Private Individual FX service)
        if (formData.serviceProfiles != null && !formData.serviceProfiles.isEmpty()) {
            for (OnboardingFormDTO.ServiceProfileDTO serviceDTO : formData.serviceProfiles) {
                if (serviceDTO.serviceType == 'FX') {
                    hasDataToSave = hasDataToSave ||
                                   (serviceDTO.currenciesToSend != null && !serviceDTO.currenciesToSend.isEmpty()) ||
                                   (serviceDTO.currenciesToReceive != null && !serviceDTO.currenciesToReceive.isEmpty()) ||
                                   (serviceDTO.countriesFundsSentTo != null && !serviceDTO.countriesFundsSentTo.isEmpty()) ||
                                   (serviceDTO.countriesFundsReceivedFrom != null && !serviceDTO.countriesFundsReceivedFrom.isEmpty());
                    System.debug(LoggingLevel.DEBUG, '📊 Service Profile Data Check - hasDataToSave: ' + hasDataToSave);
                    break; // Only check first FX service
                }
            }
        }
        
        // Always upsert if we have an existing record (to update it) or if we have data to save
        if (hasDataToSave || !existingProfiles.isEmpty()) {
            // Debug: Show what we're about to save
            System.debug(LoggingLevel.DEBUG, '💾 === ABOUT TO UPSERT BUSINESS_PROFILE ===');
            System.debug(LoggingLevel.DEBUG, 'Record ID: ' + businessProfile.Id);
            System.debug(LoggingLevel.DEBUG, 'hasDataToSave: ' + hasDataToSave);
            System.debug(LoggingLevel.DEBUG, 'Existing record?: ' + !existingProfiles.isEmpty());
            System.debug(LoggingLevel.DEBUG, 'Purpose_of_Account__c: ' + businessProfile.Purpose_of_Account__c);
            System.debug(LoggingLevel.DEBUG, 'Products_and_Services__c: ' + businessProfile.Products_and_Services__c);
            
            // Upsert the record (insert if new, update if existing)
            upsert businessProfile;
            System.debug(LoggingLevel.DEBUG, 'Business_Profile__c saved/updated: ' + businessProfile.Id);
            System.debug(LoggingLevel.DEBUG, 'Products_and_Services__c: ' + businessProfile.Products_and_Services__c);
            System.debug(LoggingLevel.DEBUG, 'Source_of_Wealth_Explanation__c: ' + businessProfile.Source_of_Wealth_Explanation__c);
            return businessProfile.Id;
        }
        
        // No data to save and no existing record, return null
        System.debug(LoggingLevel.WARN, 'Business_Profile__c not saved - no data and no existing record');
        return null;
    }
    
    /**
     * @description Populates service-specific fields directly on Onboarding_Application__c
     * This replaces the previous Service_Profile__c object pattern
     * @param app The Onboarding_Application__c record to populate
     * @param formData Form data containing service-specific information
     */
    private static void populateServiceFieldsOnApplication(Onboarding_Application__c app, OnboardingFormDTO formData) {
        System.debug(LoggingLevel.DEBUG, '🎯 === POPULATE SERVICE FIELDS START ===');
        System.debug(LoggingLevel.DEBUG, 'currentStep: ' + formData.currentStep);
        System.debug(LoggingLevel.DEBUG, 'Has serviceProfiles: ' + (formData.serviceProfiles != null));
        System.debug(LoggingLevel.DEBUG, 'ServiceProfiles count: ' + (formData.serviceProfiles != null ? formData.serviceProfiles.size() : 0));
        
        // Architectural rule:
        //  - Only the Services step should be able to CLEAR existing FX/Crypto/Advisory data.
        //  - Other steps may populate/update these fields if they provide non-empty values,
        //    but must not wipe them out just because they don't send service data.
        Boolean hasServiceProfiles = (formData.serviceProfiles != null && !formData.serviceProfiles.isEmpty());
        Boolean isServicesStep = (formData.currentStep == 'service');
        
        // If we are not on the Services step AND there is no service data at all,
        // then we must not touch service fields – preserve existing values.
        if (!hasServiceProfiles && !isServicesStep) {
            System.debug(LoggingLevel.DEBUG,
                '⏭ Skipping service field population – no serviceProfiles and currentStep != service. ' +
                'Existing FX/Crypto/Advisory values on application will be preserved.');
            System.debug(LoggingLevel.DEBUG, '🎯 === POPULATE SERVICE FIELDS END (SKIPPED) ===');
            return;
        }
        
        // If on the Services step, clear ALL service fields first to handle deselected services
        // This ensures that if user went back to Get Started and unchecked a service (e.g., removed Crypto),
        // that service's data is completely wiped from Salesforce
        if (isServicesStep) {
            System.debug(LoggingLevel.DEBUG, '🧹 Clearing ALL service fields (on Services step) to handle deselected services');
            // Clear FX fields
            app.FX_Currency_Pairs__c = null;
            app.FX_Forward_Contracts_Required__c = null;
            app.FX_Hedging_Needs__c = null;
            // Clear Crypto fields
            app.Digital_Assets__c = null;
            app.Crypto_Expected_Monthly_Volume__c = null;
            app.Crypto_Average_Transaction_Size__c = null;
            app.Is_VASP__c = null;
            // Clear Advisory fields
            app.Advisory_Services_Required__c = null;
            app.Investment_Objectives__c = null;
            app.Risk_Appetite__c = null;
            app.Time_Horizon_Years__c = null;
            app.Existing_Advisory_Relationships__c = null;
        }
        
        // Process service profiles if provided
        if (hasServiceProfiles) {
            for (OnboardingFormDTO.ServiceProfileDTO serviceDTO : formData.serviceProfiles) {
                System.debug(LoggingLevel.DEBUG, '📋 Processing service type: ' + serviceDTO.serviceType);
        
        // Map service-specific fields based on service type
        if (serviceDTO.serviceType == 'FX') {
                    System.debug(LoggingLevel.DEBUG, '💱 FX Service - Currencies and Countries');
                    System.debug(LoggingLevel.DEBUG, 'Currencies to Send: ' + serviceDTO.currenciesToSend);
                    System.debug(LoggingLevel.DEBUG, 'Currencies to Receive: ' + serviceDTO.currenciesToReceive);
                    System.debug(LoggingLevel.DEBUG, 'Countries Sent To: ' + serviceDTO.countriesFundsSentTo);
                    System.debug(LoggingLevel.DEBUG, 'Countries Received From: ' + serviceDTO.countriesFundsReceivedFrom);
                    
                    // Currencies to Send
            if (serviceDTO.currenciesToSend != null && !serviceDTO.currenciesToSend.isEmpty()) {
                        app.FX_Currency_Pairs__c = String.join(serviceDTO.currenciesToSend, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Set Currencies to Send (FX_Currency_Pairs__c): ' + app.FX_Currency_Pairs__c);
                    }
                    // Note: If empty and on Services step, already cleared above
                    
                    // Note: currenciesToReceive, countriesFundsSentTo, countriesFundsReceivedFrom
                    // are saved to Business_Profile__c for Corporate clients (via businessContext)
                    // or stored in Service_Profile__c if that object exists
                    
                    // FX_Forward_Contracts_Required__c – scalar
                    if (isServicesStep || String.isNotBlank(serviceDTO.fxForwardContractsRequired)) {
                        app.FX_Forward_Contracts_Required__c = serviceDTO.fxForwardContractsRequired;
                        System.debug(LoggingLevel.DEBUG, '✅ Set FX_Forward_Contracts_Required__c: ' + app.FX_Forward_Contracts_Required__c);
                    }
                    
                    // FX_Hedging_Needs__c – scalar
                    if (isServicesStep || String.isNotBlank(serviceDTO.fxHedgingNeeds)) {
                        app.FX_Hedging_Needs__c = serviceDTO.fxHedgingNeeds;
                        System.debug(LoggingLevel.DEBUG, '✅ Set FX_Hedging_Needs__c: ' + app.FX_Hedging_Needs__c);
                    }
                    // FX_Average_Trade_Size__c and FX_Expected_Monthly_Volume__c fields removed per requirements
        } else if (serviceDTO.serviceType == 'Crypto') {
                    System.debug(LoggingLevel.DEBUG, '₿ Crypto Service - Digital Assets: ' + serviceDTO.digitalAssets);
                    
                    // Digital_Assets__c – multi-select style
            if (serviceDTO.digitalAssets != null && !serviceDTO.digitalAssets.isEmpty()) {
                        app.Digital_Assets__c = String.join(serviceDTO.digitalAssets, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Set Digital_Assets__c: ' + app.Digital_Assets__c);
            }
                    // Note: If empty and on Services step, already cleared above
                    
                    System.debug(LoggingLevel.DEBUG, 'Expected Monthly Volume: ' + serviceDTO.expectedMonthlyCryptoVolume);
            if (String.isNotBlank(serviceDTO.expectedMonthlyCryptoVolume)) {
                        app.Crypto_Expected_Monthly_Volume__c = Decimal.valueOf(serviceDTO.expectedMonthlyCryptoVolume);
                        System.debug(LoggingLevel.DEBUG, '✅ Set Crypto_Expected_Monthly_Volume__c: ' + app.Crypto_Expected_Monthly_Volume__c);
            }
                    // Note: If blank and on Services step, already cleared above
                    
                    System.debug(LoggingLevel.DEBUG, 'Average Transaction Size: ' + serviceDTO.averageCryptoTransactionSize);
            if (String.isNotBlank(serviceDTO.averageCryptoTransactionSize)) {
                        app.Crypto_Average_Transaction_Size__c = Decimal.valueOf(serviceDTO.averageCryptoTransactionSize);
                        System.debug(LoggingLevel.DEBUG, '✅ Set Crypto_Average_Transaction_Size__c: ' + app.Crypto_Average_Transaction_Size__c);
                    }
                    // Note: If blank and on Services step, already cleared above
                    
                    // isVASP removed - regulatory status now captured in Company Info step
                    // Regulatory info saved to Business_Profile__c fields:
                    // Is_Regulated__c, Regulator_Name__c, Regulatory_Licence_Number__c, Regulatory_Jurisdiction__c
        } else if (serviceDTO.serviceType == 'Advisory') {
                    System.debug(LoggingLevel.DEBUG, '📊 Advisory Service - Advisory Services: ' + serviceDTO.advisoryServicesRequired);
                    
                    // Advisory_Services_Required__c – multi-select
            if (serviceDTO.advisoryServicesRequired != null && !serviceDTO.advisoryServicesRequired.isEmpty()) {
                        app.Advisory_Services_Required__c = String.join(serviceDTO.advisoryServicesRequired, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Set Advisory_Services_Required__c: ' + app.Advisory_Services_Required__c);
            }
                    // Note: If empty and on Services step, already cleared above
                    
                    System.debug(LoggingLevel.DEBUG, 'Investment Objectives: ' + serviceDTO.investmentObjectives);
            if (serviceDTO.investmentObjectives != null && !serviceDTO.investmentObjectives.isEmpty()) {
                        app.Investment_Objectives__c = String.join(serviceDTO.investmentObjectives, ';');
                        System.debug(LoggingLevel.DEBUG, '✅ Set Investment_Objectives__c: ' + app.Investment_Objectives__c);
                    }
                    // Note: If empty and on Services step, already cleared above
                    
                    System.debug(LoggingLevel.DEBUG, 'Risk Appetite: ' + serviceDTO.riskAppetite);
                    if (isServicesStep || String.isNotBlank(serviceDTO.riskAppetite)) {
                        app.Risk_Appetite__c = serviceDTO.riskAppetite;
                        System.debug(LoggingLevel.DEBUG, '✅ Set Risk_Appetite__c: ' + app.Risk_Appetite__c);
                    }
                    
                    System.debug(LoggingLevel.DEBUG, 'Time Horizon: ' + serviceDTO.timeHorizon);
            if (String.isNotBlank(serviceDTO.timeHorizon)) {
                        app.Time_Horizon_Years__c = Decimal.valueOf(serviceDTO.timeHorizon);
                        System.debug(LoggingLevel.DEBUG, '✅ Set Time_Horizon_Years__c: ' + app.Time_Horizon_Years__c);
                    }
                    // Note: If blank and on Services step, already cleared above
                    
                    System.debug(LoggingLevel.DEBUG, 'Existing Advisory Relationships: ' + serviceDTO.existingAdvisoryRelationships);
                    if (isServicesStep || String.isNotBlank(serviceDTO.existingAdvisoryRelationships)) {
                        app.Existing_Advisory_Relationships__c = serviceDTO.existingAdvisoryRelationships;
                        System.debug(LoggingLevel.DEBUG, '✅ Set Existing_Advisory_Relationships__c: ' + app.Existing_Advisory_Relationships__c);
                    }
                }
            }
        } else {
            System.debug(LoggingLevel.WARN, '⚠️ No service profiles provided - service fields will not be populated');
        }
        
        System.debug(LoggingLevel.DEBUG, '🎯 === POPULATE SERVICE FIELDS END ===');
        System.debug(LoggingLevel.DEBUG, 'FINAL VALUES:');
        System.debug(LoggingLevel.DEBUG, 'FX_Currency_Pairs__c: ' + app.FX_Currency_Pairs__c);
        System.debug(LoggingLevel.DEBUG, 'FX_Forward_Contracts_Required__c: ' + app.FX_Forward_Contracts_Required__c);
        System.debug(LoggingLevel.DEBUG, 'FX_Hedging_Needs__c: ' + app.FX_Hedging_Needs__c);
        System.debug(LoggingLevel.DEBUG, 'Digital_Assets__c: ' + app.Digital_Assets__c);
        System.debug(LoggingLevel.DEBUG, 'Crypto_Expected_Monthly_Volume__c: ' + app.Crypto_Expected_Monthly_Volume__c);
        System.debug(LoggingLevel.DEBUG, 'Crypto_Average_Transaction_Size__c: ' + app.Crypto_Average_Transaction_Size__c);
        System.debug(LoggingLevel.DEBUG, 'Is_VASP__c: ' + app.Is_VASP__c);
        System.debug(LoggingLevel.DEBUG, 'Advisory_Services_Required__c: ' + app.Advisory_Services_Required__c);
        System.debug(LoggingLevel.DEBUG, 'Investment_Objectives__c: ' + app.Investment_Objectives__c);
        System.debug(LoggingLevel.DEBUG, 'Risk_Appetite__c: ' + app.Risk_Appetite__c);
        System.debug(LoggingLevel.DEBUG, 'Time_Horizon_Years__c: ' + app.Time_Horizon_Years__c);
        System.debug(LoggingLevel.DEBUG, 'Existing_Advisory_Relationships__c: ' + app.Existing_Advisory_Relationships__c);
    }
    
    
    /**
     * @description Creates Risk_Assessment__c record
     * @param applicationId Application ID
     * @param formData Form data
     * @return Created record ID
     */
    private static String createRiskAssessment(String applicationId, OnboardingFormDTO formData) {
        // Check if Risk Assessment already exists for this application
        List<Risk_Assessment__c> existingRisks = [
            SELECT Id, 
                   Onboarding_Application__c,
                   Private_Expected_Monthly_Volume__c,
                   Private_Estimated_Transactions_per_Month__c,
                   Private_Source_of_Wealth__c,
                   Private_Source_of_Wealth_Explanation__c,
                   Private_Geographic_Exposure__c,
                   Private_Intended_Use_of_Account__c,
                   Additional_UBOs__c,
                   On_Sanctions_List__c,
                   Financial_Crime_Conviction__c,
                   PEP_In_Organization__c,
                   Provides_Money_Services__c,
                   Additional_Compliance_Notes__c,
                   Calculated_Risk_Score__c,
                   Risk_Rating__c,
                   PEP_Flag__c,
                   Sanctions_Flag__c,
                   EDD_Required__c,
                   EDD_Reason__c
            FROM Risk_Assessment__c
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];
        
        Risk_Assessment__c riskAssessment;
        if (!existingRisks.isEmpty()) {
            // Update existing record
            riskAssessment = existingRisks[0];
            System.debug('🔄 Updating existing Risk Assessment: ' + riskAssessment.Id);
        } else {
            // Create new record
            riskAssessment = new Risk_Assessment__c();
            riskAssessment.Onboarding_Application__c = applicationId;
            System.debug('✨ Creating new Risk Assessment for Application: ' + applicationId);
        }
        
        // Map private client risk fields
        if (formData.clientType == 'Private' && formData.riskInfo != null) {
            if (String.isNotBlank(formData.riskInfo.expectedMonthlyVolume)) {
                riskAssessment.Private_Expected_Monthly_Volume__c = Decimal.valueOf(formData.riskInfo.expectedMonthlyVolume);
            }
            if (String.isNotBlank(formData.riskInfo.estimatedTransactionsPerMonth)) {
                riskAssessment.Private_Estimated_Transactions_per_Month__c = Decimal.valueOf(formData.riskInfo.estimatedTransactionsPerMonth);
            }
            riskAssessment.Private_Source_of_Wealth__c = formData.riskInfo.sourceOfWealth;
            riskAssessment.Private_Source_of_Wealth_Explanation__c = formData.riskInfo.sourceOfWealthExplanation;
            if (formData.riskInfo.geographicExposure != null && !formData.riskInfo.geographicExposure.isEmpty()) {
                riskAssessment.Private_Geographic_Exposure__c = String.join(formData.riskInfo.geographicExposure, ';');
            }
            riskAssessment.Private_Intended_Use_of_Account__c = formData.riskInfo.intendedUseOfAccount;
        }
        
        // Map corporate regulatory fields
        if (formData.clientType == 'Corporate' && formData.regulatoryInfo != null) {
            riskAssessment.Additional_UBOs__c = formData.regulatoryInfo.additionalUBOs;
            riskAssessment.On_Sanctions_List__c = formData.regulatoryInfo.onSanctionsList;
            riskAssessment.Financial_Crime_Conviction__c = formData.regulatoryInfo.financialCrimeConviction;
            riskAssessment.PEP_In_Organization__c = formData.regulatoryInfo.pepInOrganization;
            riskAssessment.Provides_Money_Services__c = formData.regulatoryInfo.providesMoneyServices;
            riskAssessment.Additional_Compliance_Notes__c = formData.regulatoryInfo.additionalComplianceNotes;
        }
        
        // Calculate risk score and set flags before saving
        calculateRiskScore(riskAssessment, formData);
        setRiskFlags(riskAssessment, formData);
        
        // Use upsert to handle both insert and update scenarios
        upsert riskAssessment;
        System.debug('✅ Risk Assessment saved: ' + riskAssessment.Id);
        
        return riskAssessment.Id;
    }
    
    /**
     * @description Calculates risk score based on form data
     * @param riskAssessment Risk_Assessment__c record
     * @param formData Form data
     */
    private static void calculateRiskScore(Risk_Assessment__c riskAssessment, OnboardingFormDTO formData) {
        Decimal riskScore = 0;
        
        // PEP detection: +30 points
        if (formData.clientType == 'Private' && formData.personalInfo != null && formData.personalInfo.isPEP == 'Yes') {
            riskScore += 30;
        } else if (formData.clientType == 'Corporate' && formData.regulatoryInfo != null && formData.regulatoryInfo.pepInOrganization == 'Yes') {
            riskScore += 30;
        }
        
        // Sanctions risk: +50 points
        if (formData.clientType == 'Corporate' && formData.regulatoryInfo != null && formData.regulatoryInfo.onSanctionsList == 'Yes') {
            riskScore += 50;
        }
        
        // High volume: +20 points (if above threshold)
        Decimal volumeThreshold = 100000; // $100,000 threshold
        if (formData.clientType == 'Private' && formData.riskInfo != null && 
            String.isNotBlank(formData.riskInfo.expectedMonthlyVolume)) {
            Decimal monthlyVolume = Decimal.valueOf(formData.riskInfo.expectedMonthlyVolume);
            if (monthlyVolume > volumeThreshold) {
                riskScore += 20;
            }
        } else if (formData.clientType == 'Corporate' && formData.businessContext != null &&
                   String.isNotBlank(formData.businessContext.expectedAnnualVolume)) {
            Decimal annualVolume = Decimal.valueOf(formData.businessContext.expectedAnnualVolume);
            if (annualVolume > (volumeThreshold * 12)) {
                riskScore += 20;
            }
        }
        
        // High-risk jurisdiction: +25 points
        if (formData.clientType == 'Corporate' && formData.businessContext != null && 
            formData.businessContext.highRiskJurisdictionExposure == 'Yes') {
            riskScore += 25;
        }
        
        // Financial crime conviction: +40 points
        if (formData.clientType == 'Corporate' && formData.regulatoryInfo != null && 
            formData.regulatoryInfo.financialCrimeConviction == 'Yes') {
            riskScore += 40;
        }
        
        // Cap score at 100
        riskScore = Math.min(riskScore, 100);
        riskAssessment.Calculated_Risk_Score__c = riskScore;
        
        // Assign risk rating
        if (riskScore <= 30) {
            riskAssessment.Risk_Rating__c = 'Low';
        } else if (riskScore <= 60) {
            riskAssessment.Risk_Rating__c = 'Medium';
        } else {
            riskAssessment.Risk_Rating__c = 'High';
        }
    }
    
    /**
     * @description Sets risk flags based on form data
     * @param riskAssessment Risk_Assessment__c record
     * @param formData Form data
     */
    private static void setRiskFlags(Risk_Assessment__c riskAssessment, OnboardingFormDTO formData) {
        // PEP Flag
        if (formData.clientType == 'Private' && formData.personalInfo != null && formData.personalInfo.isPEP == 'Yes') {
            riskAssessment.PEP_Flag__c = true;
        } else if (formData.clientType == 'Corporate' && formData.regulatoryInfo != null && formData.regulatoryInfo.pepInOrganization == 'Yes') {
            riskAssessment.PEP_Flag__c = true;
        }
        
        // Sanctions Flag
        if (formData.clientType == 'Corporate' && formData.regulatoryInfo != null && formData.regulatoryInfo.onSanctionsList == 'Yes') {
            riskAssessment.Sanctions_Flag__c = true;
        }
        
        // High-Risk Jurisdiction Flag
        // High-Risk Jurisdiction Flag removed per requirements
        
        // EDD Required
        if (riskAssessment.PEP_Flag__c == true || 
            riskAssessment.Sanctions_Flag__c == true ||
            riskAssessment.Calculated_Risk_Score__c > 60) {
            riskAssessment.EDD_Required__c = true;
            
            // Set EDD reason
            List<String> reasons = new List<String>();
            if (riskAssessment.PEP_Flag__c == true) reasons.add('PEP detected');
            if (riskAssessment.Sanctions_Flag__c == true) reasons.add('Sanctions risk');
            if (riskAssessment.Calculated_Risk_Score__c > 60) reasons.add('High risk score');
            riskAssessment.EDD_Reason__c = String.join(reasons, '; ');
        }
    }
    
    /**
     * @description Creates Document_Submission__c records for required documents
     * @param applicationId Application ID
     * @param formData Form data
     * @return List of created record IDs
     */
    private static List<String> createDocumentSubmissions(String applicationId, OnboardingFormDTO formData) {
        List<String> documentIds = new List<String>();
        
        // CHANGE: Since Documents UI step was removed, only create Document_Submission__c
        // records for files that were actually uploaded (not for "required" documents)
        
        Set<String> uploadedDocumentTypes = new Set<String>();
        if (formData.fileUploads != null && !formData.fileUploads.isEmpty()) {
            for (OnboardingFormDTO.FileUploadDTO fileUpload : formData.fileUploads) {
                if (String.isNotBlank(fileUpload.documentType)) {
                    uploadedDocumentTypes.add(fileUpload.documentType);
                }
            }
        }
        
        // Only create documents for uploaded files (not for "required" documents that can't be uploaded)
        List<Document_Submission__c> documentsToInsert = new List<Document_Submission__c>();
        for (String docType : uploadedDocumentTypes) {
            Document_Submission__c doc = new Document_Submission__c();
            doc.Onboarding_Application__c = applicationId;
            doc.Document_Type__c = docType;
            doc.Level__c = 'Application';
            doc.Is_Required__c = false; // Not required since Documents step was removed from UI
            doc.Is_Received__c = true; // Always true since only created if file uploaded
            documentsToInsert.add(doc);
        }
        
        if (!documentsToInsert.isEmpty()) {
            insert documentsToInsert;
            for (Document_Submission__c doc : documentsToInsert) {
                documentIds.add(doc.Id);
            }
        }
        
        return documentIds;
    }
    
    /**
     * @description Creates Declaration_Acceptance__c records
     * @param applicationId Application ID
     * @param partyMap Map of role to party ID
     * @param formData Form data
     * @return List of created record IDs
     */
    private static List<String> createDeclarationAcceptances(String applicationId, Map<String, String> partyMap, OnboardingFormDTO formData) {
        List<String> declarationIds = new List<String>();
        
        // Get the Applicant Party ID - this is required for Signatory_Party__c lookup
        String signatoryPartyId = partyMap != null ? partyMap.get('Applicant') : null;
        if (String.isBlank(signatoryPartyId)) {
            // Log error but don't throw - this will be caught by validation
            System.debug(LoggingLevel.ERROR, 'createDeclarationAcceptances: Applicant Party ID not found in partyMap. partyMap: ' + partyMap);
            return declarationIds;
        }
        
        // Get required declarations
        List<String> requiredDeclarations = getRequiredDeclarations();
        
        // Check if declarations were accepted
        Boolean declarationsAccepted = false;
        String signatoryFirstName = '';
        String signatoryLastName = '';
        String signatureName = '';
        
        if (formData.declarations != null && !formData.declarations.isEmpty()) {
            // Handle list format (if provided)
            for (OnboardingFormDTO.DeclarationDTO declDTO : formData.declarations) {
                if (declDTO.accepted == true) {
                    declarationsAccepted = true;
                    if (String.isNotBlank(declDTO.signatureName)) {
                        signatureName = declDTO.signatureName;
                    } else if (String.isNotBlank(declDTO.signatoryFirstName) && String.isNotBlank(declDTO.signatoryLastName)) {
                        signatoryFirstName = declDTO.signatoryFirstName;
                        signatoryLastName = declDTO.signatoryLastName;
                        signatureName = declDTO.signatoryFirstName + ' ' + declDTO.signatoryLastName;
                    }
                    break;
                }
            }
        }
        
        // If no declarations in list format, check if we need to create from single agreeToTerms
        // This handles backward compatibility - the form might send a single boolean
        if (!declarationsAccepted && requiredDeclarations != null && !requiredDeclarations.isEmpty()) {
            // Assume all declarations are accepted if we're creating records
            // The validation will ensure at least one is accepted
            declarationsAccepted = true;
        }
        
        if (!declarationsAccepted || String.isBlank(signatureName)) {
            return declarationIds;
        }
        
        // Create declaration records for all required types
        List<Declaration_Acceptance__c> declarationsToInsert = new List<Declaration_Acceptance__c>();
        for (String declType : requiredDeclarations) {
            Declaration_Acceptance__c decl = new Declaration_Acceptance__c();
            decl.Onboarding_Application__c = applicationId;
            decl.Signatory_Party__c = signatoryPartyId;
            decl.Declaration_Type__c = declType;
            decl.Accepted__c = true;
            decl.Accepted_On__c = Datetime.now();
            decl.Accepted_From_IP__c = formData.ipAddress;
            decl.Signature_Name__c = signatureName;
            decl.Signature_Timestamp__c = Datetime.now();
            
            declarationsToInsert.add(decl);
        }
        
        if (!declarationsToInsert.isEmpty()) {
            insert declarationsToInsert;
            for (Declaration_Acceptance__c decl : declarationsToInsert) {
                declarationIds.add(decl.Id);
            }
        }
        
        return declarationIds;
    }
    
    /**
     * @description Gets list of required declaration types
     * @return List of required declaration types
     */
    private static List<String> getRequiredDeclarations() {
        return new List<String>{
            'Terms_of_Business',
            'Risk_Disclosure',
            'AML_Consent',
            'Accuracy_Declaration'
        };
    }
    
    /**
     * @description Captures client metadata (IP address and user agent) from the HTTP request
     * This is a fallback method if the LWC doesn't provide this information
     * Note: For Aura/LWC calls, this may not always be available. The LWC should capture and send this data.
     * @return Map with 'ipAddress' and 'userAgent' keys
     */
    private static Map<String, String> captureClientMetadata() {
        Map<String, String> metadata = new Map<String, String>();
        String ipAddress = '';
        String userAgent = '';
        
        try {
            // Try to get from REST context (for REST API calls)
            RestRequest req = RestContext.request;
            if (req != null) {
                // Try to get IP address from various headers (for load balancers/proxies)
                ipAddress = req.headers.get('X-Forwarded-For');
                if (String.isBlank(ipAddress)) {
                    ipAddress = req.headers.get('X-Real-IP');
                }
                if (String.isBlank(ipAddress) && req.remoteAddress != null) {
                    ipAddress = req.remoteAddress;
                }
                
                // Get user agent
                userAgent = req.headers.get('User-Agent');
            }
        } catch (Exception e) {
            // REST context not available - this is normal for Aura/LWC calls
            // The LWC should provide these values in formData
        }
        
        // For Aura/LWC calls, we rely on the client-side to provide IP and user agent
        // This method serves as a fallback for REST API calls or future integrations
        metadata.put('ipAddress', String.isNotBlank(ipAddress) ? ipAddress : '');
        metadata.put('userAgent', String.isNotBlank(userAgent) ? userAgent : '');
        
        return metadata;
    }
    
    /**
     * @description Links uploaded files to Document_Submission__c records
     * @param fileUploads List of file upload DTOs
     * @param applicationId Application ID
     * @param partyMap Map of role to party ID
     */
    private static void linkFileUploads(List<OnboardingFormDTO.FileUploadDTO> fileUploads, String applicationId, Map<String, String> partyMap) {
        if (fileUploads == null || fileUploads.isEmpty()) {
            return;
        }
        
        // Get all document submissions for this application
        List<Document_Submission__c> documents = [
            SELECT Id, Document_Type__c, Level__c, Related_Party__c
            FROM Document_Submission__c
            WHERE Onboarding_Application__c = :applicationId
        ];
        
        List<Document_Submission__c> documentsToUpdate = new List<Document_Submission__c>();
        
        for (OnboardingFormDTO.FileUploadDTO fileUpload : fileUploads) {
            if (String.isBlank(fileUpload.contentDocumentId) || String.isBlank(fileUpload.documentType)) {
                continue;
            }
            
            // Find matching document submission
            for (Document_Submission__c doc : documents) {
                if (doc.Document_Type__c == fileUpload.documentType && 
                    doc.Level__c == fileUpload.level) {
                    // Check if party-specific
                    if (String.isNotBlank(fileUpload.relatedPartyId) && partyMap != null && partyMap.containsKey(fileUpload.relatedPartyId)) {
                        String relatedPartyId = partyMap.get(fileUpload.relatedPartyId);
                        if (String.isNotBlank(relatedPartyId)) {
                            doc.Related_Party__c = relatedPartyId;
                        }
                    }
                    
                    doc.ContentDocumentId__c = fileUpload.contentDocumentId;
                    doc.Is_Received__c = true;
                    documentsToUpdate.add(doc);
                    break;
                }
            }
        }
        
        if (!documentsToUpdate.isEmpty()) {
            update documentsToUpdate;
        }
    }
}