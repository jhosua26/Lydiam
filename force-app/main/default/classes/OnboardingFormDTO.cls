/**
 * @description Data Transfer Object (DTO) classes for Client Onboarding Form
 * These classes are used to pass complex data structures from LWC to Apex
 * 
 * @author System
 * @date 2024
 */
public class OnboardingFormDTO {
    
    // ========== Entry Data ==========
    /** Client type: 'Private' or 'Corporate' */
    @AuraEnabled public String clientType;
    /** Existing application Id (for draft/continue flows) */
    @AuraEnabled public String applicationId;
    /** Current UI step (for resume/tracking) */
    @AuraEnabled public String currentStep;
    /** Flag indicating this is a final form submission (not an auto-save) */
    @AuraEnabled public Boolean isSubmission;
    /** Intake channel (e.g., ExperienceCloud, Referral, Partner) */
    @AuraEnabled public String channel;
    
    /** List of services required: ['FX', 'Crypto', 'Advisory'] */
    @AuraEnabled public List<String> servicesRequired;
    
    // ========== Personal Info (Private Clients) ==========
    /** Personal information for private clients */
    @AuraEnabled public PersonalInfoDTO personalInfo;
    
    // ========== Address Info ==========
    /** Address information */
    @AuraEnabled public AddressInfoDTO addressInfo;
    
    // ========== Risk Info (Private Clients) ==========
    /** Risk assessment information for private clients */
    @AuraEnabled public RiskInfoDTO riskInfo;
    
    // ========== Corporate-Specific Data ==========
    /** Company information for corporate clients */
    @AuraEnabled public CompanyInfoDTO companyInfo;
    
    /** Business context and transaction information */
    @AuraEnabled public BusinessContextDTO businessContext;
    
    /** List of shareholders */
    @AuraEnabled public List<ShareholderDTO> shareholders;
    
    /** List of authorized users */
    @AuraEnabled public List<AuthorisedUserDTO> authorisedUsers;

    /** Additional parties (Directors / Signatories / UBOs) */
    @AuraEnabled public List<AdditionalPartyDTO> additionalParties;
    
    // ========== Service-Specific Data ==========
    /** Service-specific profiles (one per selected service) */
    @AuraEnabled public List<ServiceProfileDTO> serviceProfiles;
    
    // ========== Regulatory Info (Corporate) ==========
    /** Regulatory and compliance information */
    @AuraEnabled public RegulatoryInfoDTO regulatoryInfo;
    
    // ========== Declarations ==========
    /** List of accepted declarations */
    @AuraEnabled public List<DeclarationDTO> declarations;
    
    // ========== File Uploads ==========
    /** List of uploaded files with metadata */
    @AuraEnabled public List<FileUploadDTO> fileUploads;
    
    // ========== Metadata ==========
    /** User agent string from browser */
    @AuraEnabled public String userAgent;
    
    /** IP address of the client */
    @AuraEnabled public String ipAddress;
    
    // ========== Nested DTO Classes ==========
    
    /**
     * @description Personal information for private clients
     */
    public class PersonalInfoDTO {
        @AuraEnabled public String salutation;
        @AuraEnabled public String firstName;
        @AuraEnabled public String middleName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String suffix;
        @AuraEnabled public String dateOfBirth;
        @AuraEnabled public String nationality;
        @AuraEnabled public String countryOfResidence;
        @AuraEnabled public String governmentIdNumber;
        @AuraEnabled public String email;
        @AuraEnabled public String mobile;
        @AuraEnabled public String phone;
        @AuraEnabled public String website;
        @AuraEnabled public String isPEP; // 'Yes' or 'No'
    }
    
    /**
     * @description Address information
     */
    public class AddressInfoDTO {
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String addressType; // Residential / Business / Registered / Principal_Business
        @AuraEnabled public Boolean addressVerified;
        @AuraEnabled public String verificationProvider;
        @AuraEnabled public List<String> proofOfAddressUpload; // ContentDocument IDs
    }
    
    /**
     * @description Risk assessment information for private clients
     */
    public class RiskInfoDTO {
        @AuraEnabled public String expectedMonthlyVolume;
        @AuraEnabled public String estimatedTransactionsPerMonth;
        @AuraEnabled public String sourceOfWealth;
        @AuraEnabled public String sourceOfWealthExplanation;
        @AuraEnabled public List<String> geographicExposure;
        @AuraEnabled public String intendedUseOfAccount;
        @AuraEnabled public List<String> sourceOfWealthUpload; // ContentDocument IDs
    }
    
    /**
     * @description Company information for corporate clients
     */
    public class CompanyInfoDTO {
        @AuraEnabled public String legalEntityName;
        @AuraEnabled public String tradingName;
        @AuraEnabled public String legalEntityType;
        @AuraEnabled public String dateOfIncorporation;
        @AuraEnabled public String countryOfIncorporation;
        @AuraEnabled public String registrationNumber;
        // Registered Business Address (structured fields)
        @AuraEnabled public String registeredStreet;
        @AuraEnabled public String registeredCity;
        @AuraEnabled public String registeredState;
        @AuraEnabled public String registeredPostalCode;
        @AuraEnabled public String registeredCountry;
        @AuraEnabled public String isRegulatedFinancialInstitution;
        @AuraEnabled public String regulatorName;
        @AuraEnabled public String regulatoryLicenceNumber;
        @AuraEnabled public String regulatoryJurisdiction;
        @AuraEnabled public String website;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String natureOfBusiness;
        @AuraEnabled public List<String> restrictedActivities;
        @AuraEnabled public String expectedNumberOfEmployees;
    }
    
    /**
     * @description Business context and transaction information
     */
    public class BusinessContextDTO {
        @AuraEnabled public String purposeOfAccount;
        @AuraEnabled public String industry;
        @AuraEnabled public String productsAndServices;
        @AuraEnabled public List<String> paymentFlowTypes;
        @AuraEnabled public String expectedTransactionsPerMonth;
        @AuraEnabled public String expectedAnnualVolume;
        @AuraEnabled public String typicalValuePerTransaction;
        @AuraEnabled public List<String> currenciesToSend;
        @AuraEnabled public List<String> currenciesToReceive;
        @AuraEnabled public List<String> countriesFundsSentTo;
        @AuraEnabled public List<String> countriesFundsReceivedFrom;
        @AuraEnabled public String largestSingleTransaction;
        @AuraEnabled public String highRiskJurisdictionExposure; // 'Yes' or 'No'
        @AuraEnabled public String highRiskJurisdictionDetails;
        @AuraEnabled public String anticipatedSanctionedCounterparties; // 'Yes' or 'No'
        @AuraEnabled public String primarySourceOfFunds;
        // @AuraEnabled public String sourceOfWealthForBusinessOwners; // Field removed - captured in Explanation
        @AuraEnabled public String sourceOfWealthExplanation;
        @AuraEnabled public List<String> sourceOfFundsUpload; // ContentDocument IDs
    }
    
    /**
     * @description Shareholder information
     */
    public class ShareholderDTO {
        @AuraEnabled public String id; // Temporary ID from form
        @AuraEnabled public String type; // 'Individual' or 'Corporate'
        
        // Role identifiers
        @AuraEnabled public Boolean isShareholder; // Is this party a Shareholder?
        @AuraEnabled public Boolean isDirector; // Is this party a Director?
        
        // Split name fields for individuals
        @AuraEnabled public String salutation;
        @AuraEnabled public String firstName;
        @AuraEnabled public String middleName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String suffix;
        
        // Legal entity name for corporates
        @AuraEnabled public String legalEntityName;
        
        // Keep for backward compatibility
        @AuraEnabled public String name;
        
        @AuraEnabled public String dateOfBirthOrIncorporation;
        @AuraEnabled public String countryOfResidenceOrIncorporation;
        @AuraEnabled public String nationalityOrCountryOfIncorporation;
        @AuraEnabled public String ownershipPercentage;
        @AuraEnabled public String governmentIdOrRegistrationNumber;
        @AuraEnabled public String isPEP; // 'Yes' or 'No'
        @AuraEnabled public String sourceOfWealth;
        @AuraEnabled public String sourceOfWealthExplanation;
        @AuraEnabled public String email;
        @AuraEnabled public String mobile;
        @AuraEnabled public String phone;
        @AuraEnabled public String website;
        @AuraEnabled public String positionOrRole;
        
        // Address fields
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
    }
    
    /**
     * @description Additional party (Director / Signatory / UBO)
     */
    public class AdditionalPartyDTO {
        @AuraEnabled public String id; // Temporary ID from form
        @AuraEnabled public String role; // Director / Signatory / UBO
        @AuraEnabled public String type; // 'Individual' or 'Corporate'
        
        // Split name fields for individuals
        @AuraEnabled public String salutation;
        @AuraEnabled public String firstName;
        @AuraEnabled public String middleName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String suffix;
        
        // Legal entity name for corporates
        @AuraEnabled public String legalEntityName;
        
        // Keep for backward compatibility
        @AuraEnabled public String name;
        
        @AuraEnabled public String dateOfBirthOrIncorporation;
        @AuraEnabled public String countryOfResidenceOrIncorporation;
        @AuraEnabled public String nationalityOrCountryOfIncorporation;
        @AuraEnabled public String ownershipPercentage;
        @AuraEnabled public String governmentIdOrRegistrationNumber;
        @AuraEnabled public String isPEP; // 'Yes' or 'No'
        @AuraEnabled public String positionOrRole;
        @AuraEnabled public String email;
        @AuraEnabled public String mobile;
        @AuraEnabled public String phone;
        @AuraEnabled public String website;
        
        // Address fields
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
    }
    
    /**
     * @description Authorized user information
     */
    public class AuthorisedUserDTO {
        @AuraEnabled public String id; // Temporary ID from form
        @AuraEnabled public Boolean sameAsShareholder;
        @AuraEnabled public String selectedShareholderId;
        
        // Split name fields
        @AuraEnabled public String salutation;
        @AuraEnabled public String firstName;
        @AuraEnabled public String middleName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String suffix;
        
        // Keep for backward compatibility
        @AuraEnabled public String name;
        
        @AuraEnabled public String position;
        @AuraEnabled public String email;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String phone;  // ADD: Phone field
        @AuraEnabled public String dateOfBirth;
        @AuraEnabled public String countryOfResidence;
        @AuraEnabled public String nationality;
        @AuraEnabled public String governmentIdNumber;
        @AuraEnabled public String isPEP; // 'Yes' or 'No'
        @AuraEnabled public List<String> tradingExperience;
        @AuraEnabled public String tradeFrequency;
        
        // Address fields
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
    }
    
    /**
     * @description Service-specific profile information
     * Note: Fields are populated based on serviceType
     */
    public class ServiceProfileDTO {
        @AuraEnabled public String serviceType; // 'FX', 'Crypto', or 'Advisory'
        
        // FX Service Fields
        // @AuraEnabled public List<String> fxCurrencyPairs; // Deprecated - replaced with currenciesToSend/Receive
        @AuraEnabled public List<String> currenciesToSend;
        @AuraEnabled public List<String> currenciesToReceive;
        @AuraEnabled public List<String> countriesFundsSentTo;
        @AuraEnabled public List<String> countriesFundsReceivedFrom;
        @AuraEnabled public String fxForwardContractsRequired; // 'Yes' or 'No'
        @AuraEnabled public String fxHedgingNeeds; // Multi-select as String (comma-separated)
        @AuraEnabled public String averageFxTradeSize;
        @AuraEnabled public String expectedMonthlyFxVolume;
        
        // Crypto Service Fields
        @AuraEnabled public List<String> digitalAssets;
        @AuraEnabled public String expectedMonthlyCryptoVolume;
        @AuraEnabled public String averageCryptoTransactionSize;
        // @AuraEnabled public String isVASP; // Removed - regulatory status captured in Company Info
        
        // Advisory Service Fields
        @AuraEnabled public List<String> advisoryServicesRequired;
        @AuraEnabled public List<String> investmentObjectives;
        @AuraEnabled public String riskAppetite;
        @AuraEnabled public String timeHorizon; // Years as String
        @AuraEnabled public String existingAdvisoryRelationships;
    }
    
    /**
     * @description Regulatory and compliance information
     */
    public class RegulatoryInfoDTO {
        @AuraEnabled public String additionalUBOs; // 'Yes' or 'No'
        @AuraEnabled public String onSanctionsList; // 'Yes' or 'No'
        @AuraEnabled public String financialCrimeConviction; // 'Yes' or 'No'
        @AuraEnabled public String pepInOrganization; // 'Yes' or 'No'
        @AuraEnabled public String providesMoneyServices; // 'Yes' or 'No'
        @AuraEnabled public String additionalComplianceNotes;
    }
    
    /**
     * @description Declaration acceptance information
     */
    public class DeclarationDTO {
        @AuraEnabled public String declarationType; // 'Terms_of_Business', 'Risk_Disclosure', 'AML_Consent', 'Accuracy_Declaration'
        @AuraEnabled public Boolean accepted;
        @AuraEnabled public String signatureName; // Full name from signatoryFirstName + signatoryLastName
        @AuraEnabled public String signatoryFirstName;
        @AuraEnabled public String signatoryLastName;
        @AuraEnabled public String clientNotes; // Client's corrections, notes, or missing information
    }
    
    /**
     * @description File upload information
     */
    public class FileUploadDTO {
        @AuraEnabled public String contentDocumentId; // Salesforce ContentDocument ID
        @AuraEnabled public String fileName;
        @AuraEnabled public String documentType; // Maps to Document_Submission__c.Document_Type__c
        @AuraEnabled public String level; // 'Application', 'Party', 'Role', or 'Service'
        @AuraEnabled public String relatedPartyId; // Temporary ID if document is party-specific
    }
    
    /**
     * @description Result object returned from save operation
     */
    public class SaveResult {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String applicationId; // Onboarding_Application__c ID
        @AuraEnabled public String message;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public Map<String, String> recordIds; // Map of record type to ID (e.g., 'Party_Applicant' -> ID)
        @AuraEnabled public Map<String, Object> debugInfo; // Debug information for troubleshooting (what Apex received)
    }
}