import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import getCountryPicklistValues from '@salesforce/apex/OnboardingFormController.getCountryPicklistValues';
import searchAddress from '@salesforce/apex/OnboardingFormController.searchAddress';
import saveOnboardingApplication from '@salesforce/apex/OnboardingFormController.saveOnboardingApplication';
import getOnboardingApplication from '@salesforce/apex/OnboardingFormController.getOnboardingApplication';
import createDraftApplication from '@salesforce/apex/OnboardingFormController.createDraftApplication';
import getDraftApplicationData from '@salesforce/apex/OnboardingFormController.getDraftApplicationData';
import LYDIAM_LOGO from '@salesforce/resourceUrl/Lydiam_Logo';

const TITLE_OPTIONS = [
    { label: 'Mr', value: 'Mr' },
    { label: 'Mrs', value: 'Mrs' },
    { label: 'Ms', value: 'Ms' },
    { label: 'Dr', value: 'Dr' },
    { label: 'Prof', value: 'Prof' }
];

const SERVICE_OPTIONS = [
    { label: 'FX', value: 'FX' },
    { label: 'Crypto', value: 'Crypto' },
    { label: 'Advisory', value: 'Advisory' }
];

const CLIENT_TYPE_OPTIONS = [
    { label: 'Private Individual', value: 'Private' },
    { label: 'Corporate Entity', value: 'Corporate' }
];

const YES_NO_OPTIONS = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
];

const SOURCE_OF_WEALTH_OPTIONS = [
    { label: 'Employment', value: 'Employment' },
    { label: 'Business Ownership', value: 'Business Ownership' },
    { label: 'Inheritance', value: 'Inheritance' },
    { label: 'Investment Income', value: 'Investment Income' },
    { label: 'Other', value: 'Other' }
];

const SOURCE_OF_FUNDS_OPTIONS = [
    { label: 'Operating Revenue', value: 'Operating Revenue' },
    { label: 'Investments', value: 'Investments' },
    { label: 'Client Funds', value: 'Client Funds' },
    { label: 'Mixed', value: 'Mixed' },
    { label: 'Other', value: 'Other' }
];

const SHAREHOLDER_TYPE_OPTIONS = [
    { label: 'Individual', value: 'Individual' }
];

const CHANNEL_OPTIONS = [
    { label: 'Referral', value: 'Referral' },
    { label: 'Partner', value: 'Partner' },
    { label: 'Website', value: 'Website' },
    { label: 'Other', value: 'Other' }
];

const ADDRESS_TYPE_OPTIONS = [
    { label: 'Residential', value: 'Residential' },
    { label: 'Business', value: 'Business' },
    { label: 'Registered', value: 'Registered' },
    { label: 'Mailing', value: 'Mailing' }
];
const LEGAL_ENTITY_TYPE_OPTIONS = [
    // Previous values (commented out for reference)
    // { label: 'Corporation', value: 'Corporation' },
    // { label: 'LLC', value: 'LLC' },
    // { label: 'Partnership', value: 'Partnership' },
    // { label: 'Trust', value: 'Trust' },
    // { label: 'Fund', value: 'Fund' },
    { label: 'Ltd', value: 'Ltd' },
    { label: 'Unregistered Partnership', value: 'Unregistered Partnership' },
    { label: 'Registered Partnership', value: 'Registered Partnership' },
    { label: 'PLC', value: 'PLC' },
    { label: 'Sole Trader', value: 'Sole Trader' },
    { label: 'GMBH', value: 'GMBH' },
    { label: 'GBr', value: 'GBr' },
    { label: 'KG', value: 'KG' },
    { label: 'SARL', value: 'SARL' },
    { label: 'OHG', value: 'OHG' },
    { label: 'AG', value: 'AG' },
    { label: 'Other', value: 'Other' }
];

// Restricted Activities field removed from UI - commented out for future reference
// const RESTRICTED_ACTIVITIES_OPTIONS = [
//     { label: 'Gambling', value: 'Gambling' },
//     { label: 'Cannabis', value: 'Cannabis' },
//     { label: 'Adult Content', value: 'Adult Content' },
//     { label: 'Weapons', value: 'Weapons' },
//     { label: 'Money Service Business', value: 'Money Service Business' },
//     { label: 'Sanctioned Goods', value: 'Sanctioned Goods' },
//     { label: 'Other', value: 'Other' }
// ];

const PAYMENT_FLOW_TYPE_OPTIONS = [
    { label: '1st → 1st Party', value: '1st_to_1st' },
    { label: '1st → 3rd Party', value: '1st_to_3rd' },
    { label: '3rd → 1st Party', value: '3rd_to_1st' },
    { label: '3rd → 3rd Party', value: '3rd_to_3rd' }
];

const TRADING_EXPERIENCE_OPTIONS = [
    { label: 'Foreign Exchange', value: 'FX' },
    { label: 'Digital Assets', value: 'Digital Assets' },
    { label: 'Equities', value: 'Equities' },
    { label: 'Options', value: 'Options' },
    { label: 'Futures', value: 'Futures' },
    { label: 'None', value: 'None' }
];

const TRADE_FREQUENCY_OPTIONS = [
    { label: 'Never', value: 'Never' },
    { label: 'Weekly', value: 'Weekly' },
    { label: 'Monthly', value: 'Monthly' },
    { label: 'Quarterly', value: 'Quarterly' },
    { label: 'Annually', value: 'Annually' }
];

const ADVISORY_SERVICES_OPTIONS = [
    { label: 'Market Insights', value: 'Market Insights' },
    { label: 'Risk Management', value: 'Risk Management' },
    { label: 'Regulatory Guidance', value: 'Regulatory Guidance' },
    { label: 'Treasury Strategy', value: 'Treasury Strategy' },
    { label: 'Other', value: 'Other' }
];

const INVESTMENT_OBJECTIVES_OPTIONS = [
    { label: 'Capital Preservation', value: 'Capital Preservation' },
    { label: 'Growth', value: 'Growth' },
    { label: 'Income Generation', value: 'Income Generation' },
    { label: 'Hedging', value: 'Hedging' },
    { label: 'Diversification', value: 'Diversification' },
    { label: 'Other', value: 'Other' }
];

const RISK_APPETITE_OPTIONS = [
    { label: 'Low', value: 'Low' },
    { label: 'Medium', value: 'Medium' },
    { label: 'High', value: 'High' }
];

const DIGITAL_ASSET_OPTIONS = [
    { label: 'BTC', value: 'BTC' },
    { label: 'ETH', value: 'ETH' },
    { label: 'USDT', value: 'USDT' },
    { label: 'USDC', value: 'USDC' },
    { label: 'Other', value: 'Other' }
];

const COUNTRY_OPTIONS = [
    { label: 'United States', value: 'US' },
    { label: 'United Kingdom', value: 'UK' },
    { label: 'Canada', value: 'CA' },
    { label: 'Australia', value: 'AU' },
    { label: 'Germany', value: 'DE' },
    { label: 'France', value: 'FR' },
    { label: 'Japan', value: 'JP' },
    { label: 'Singapore', value: 'SG' },
    { label: 'Switzerland', value: 'CH' },
    { label: 'Other', value: 'Other' }
];

const CURRENCY_OPTIONS = [
    // Big Four - Most commonly traded currencies (at top for easy access)
    { label: 'USD - US Dollar', value: 'USD' },
    { label: 'EUR - Euro', value: 'EUR' },
    { label: 'JPY - Japanese Yen', value: 'JPY' },
    { label: 'GBP - British Pound', value: 'GBP' },
    // All other currencies (alphabetical by code)
    { label: 'AED - UAE Dirham', value: 'AED' },
    { label: 'AFN - Afghan Afghani', value: 'AFN' },
    { label: 'ALL - Albanian Lek', value: 'ALL' },
    { label: 'AMD - Armenian Dram', value: 'AMD' },
    { label: 'ANG - Netherlands Antillean Guilder', value: 'ANG' },
    { label: 'AOA - Angolan Kwanza', value: 'AOA' },
    { label: 'ARS - Argentine Peso', value: 'ARS' },
    { label: 'AUD - Australian Dollar', value: 'AUD' },
    { label: 'AWG - Aruban Florin', value: 'AWG' },
    { label: 'AZN - Azerbaijani Manat', value: 'AZN' },
    { label: 'BAM - Bosnia-Herzegovina Convertible Mark', value: 'BAM' },
    { label: 'BBD - Barbadian Dollar', value: 'BBD' },
    { label: 'BDT - Bangladeshi Taka', value: 'BDT' },
    { label: 'BGN - Bulgarian Lev', value: 'BGN' },
    { label: 'BHD - Bahraini Dinar', value: 'BHD' },
    { label: 'BIF - Burundian Franc', value: 'BIF' },
    { label: 'BMD - Bermudan Dollar', value: 'BMD' },
    { label: 'BND - Brunei Dollar', value: 'BND' },
    { label: 'BOB - Bolivian Boliviano', value: 'BOB' },
    { label: 'BOV - Bolivian Mvdol', value: 'BOV' },
    { label: 'BRL - Brazilian Real', value: 'BRL' },
    { label: 'BSD - Bahamian Dollar', value: 'BSD' },
    { label: 'BTN - Bhutanese Ngultrum', value: 'BTN' },
    { label: 'BWP - Botswanan Pula', value: 'BWP' },
    { label: 'BYN - Belarusian Ruble', value: 'BYN' },
    { label: 'BZD - Belize Dollar', value: 'BZD' },
    { label: 'CAD - Canadian Dollar', value: 'CAD' },
    { label: 'CDF - Congolese Franc', value: 'CDF' },
    { label: 'CHE - WIR Euro', value: 'CHE' },
    { label: 'CHF - Swiss Franc', value: 'CHF' },
    { label: 'CHW - WIR Franc', value: 'CHW' },
    { label: 'CLF - Chilean Unit of Account (UF)', value: 'CLF' },
    { label: 'CLP - Chilean Peso', value: 'CLP' },
    { label: 'CNY - Chinese Yuan', value: 'CNY' },
    { label: 'COP - Colombian Peso', value: 'COP' },
    { label: 'COU - Colombian Unidad de Valor Real', value: 'COU' },
    { label: 'CRC - Costa Rican Colón', value: 'CRC' },
    { label: 'CUC - Cuban Convertible Peso', value: 'CUC' },
    { label: 'CUP - Cuban Peso', value: 'CUP' },
    { label: 'CVE - Cape Verdean Escudo', value: 'CVE' },
    { label: 'CZK - Czech Koruna', value: 'CZK' },
    { label: 'DJF - Djiboutian Franc', value: 'DJF' },
    { label: 'DKK - Danish Krone', value: 'DKK' },
    { label: 'DOP - Dominican Peso', value: 'DOP' },
    { label: 'DZD - Algerian Dinar', value: 'DZD' },
    { label: 'EGP - Egyptian Pound', value: 'EGP' },
    { label: 'ERN - Eritrean Nakfa', value: 'ERN' },
    { label: 'ETB - Ethiopian Birr', value: 'ETB' },
    { label: 'FJD - Fijian Dollar', value: 'FJD' },
    { label: 'FKP - Falkland Islands Pound', value: 'FKP' },
    { label: 'GEL - Georgian Lari', value: 'GEL' },
    { label: 'GHS - Ghanaian Cedi', value: 'GHS' },
    { label: 'GIP - Gibraltar Pound', value: 'GIP' },
    { label: 'GMD - Gambian Dalasi', value: 'GMD' },
    { label: 'GNF - Guinean Franc', value: 'GNF' },
    { label: 'GTQ - Guatemalan Quetzal', value: 'GTQ' },
    { label: 'GYD - Guyanaese Dollar', value: 'GYD' },
    { label: 'HKD - Hong Kong Dollar', value: 'HKD' },
    { label: 'HNL - Honduran Lempira', value: 'HNL' },
    { label: 'HRK - Croatian Kuna', value: 'HRK' },
    { label: 'HTG - Haitian Gourde', value: 'HTG' },
    { label: 'HUF - Hungarian Forint', value: 'HUF' },
    { label: 'IDR - Indonesian Rupiah', value: 'IDR' },
    { label: 'ILS - Israeli New Shekel', value: 'ILS' },
    { label: 'INR - Indian Rupee', value: 'INR' },
    { label: 'IQD - Iraqi Dinar', value: 'IQD' },
    { label: 'IRR - Iranian Rial', value: 'IRR' },
    { label: 'ISK - Icelandic Króna', value: 'ISK' },
    { label: 'JMD - Jamaican Dollar', value: 'JMD' },
    { label: 'JOD - Jordanian Dinar', value: 'JOD' },
    { label: 'KES - Kenyan Shilling', value: 'KES' },
    { label: 'KGS - Kyrgystani Som', value: 'KGS' },
    { label: 'KHR - Cambodian Riel', value: 'KHR' },
    { label: 'KMF - Comorian Franc', value: 'KMF' },
    { label: 'KPW - North Korean Won', value: 'KPW' },
    { label: 'KRW - South Korean Won', value: 'KRW' },
    { label: 'KWD - Kuwaiti Dinar', value: 'KWD' },
    { label: 'KYD - Cayman Islands Dollar', value: 'KYD' },
    { label: 'KZT - Kazakhstani Tenge', value: 'KZT' },
    { label: 'LAK - Laotian Kip', value: 'LAK' },
    { label: 'LBP - Lebanese Pound', value: 'LBP' },
    { label: 'LKR - Sri Lankan Rupee', value: 'LKR' },
    { label: 'LRD - Liberian Dollar', value: 'LRD' },
    { label: 'LSL - Lesotho Loti', value: 'LSL' },
    { label: 'LYD - Libyan Dinar', value: 'LYD' },
    { label: 'MAD - Moroccan Dirham', value: 'MAD' },
    { label: 'MDL - Moldovan Leu', value: 'MDL' },
    { label: 'MGA - Malagasy Ariary', value: 'MGA' },
    { label: 'MKD - Macedonian Denar', value: 'MKD' },
    { label: 'MMK - Myanmar Kyat', value: 'MMK' },
    { label: 'MNT - Mongolian Tugrik', value: 'MNT' },
    { label: 'MOP - Macanese Pataca', value: 'MOP' },
    { label: 'MRU - Mauritanian Ouguiya', value: 'MRU' },
    { label: 'MUR - Mauritian Rupee', value: 'MUR' },
    { label: 'MVR - Maldivian Rufiyaa', value: 'MVR' },
    { label: 'MWK - Malawian Kwacha', value: 'MWK' },
    { label: 'MXN - Mexican Peso', value: 'MXN' },
    { label: 'MYR - Malaysian Ringgit', value: 'MYR' },
    { label: 'MZN - Mozambican Metical', value: 'MZN' },
    { label: 'NAD - Namibian Dollar', value: 'NAD' },
    { label: 'NGN - Nigerian Naira', value: 'NGN' },
    { label: 'NIO - Nicaraguan Córdoba', value: 'NIO' },
    { label: 'NOK - Norwegian Krone', value: 'NOK' },
    { label: 'NPR - Nepalese Rupee', value: 'NPR' },
    { label: 'NZD - New Zealand Dollar', value: 'NZD' },
    { label: 'OMR - Omani Rial', value: 'OMR' },
    { label: 'PAB - Panamanian Balboa', value: 'PAB' },
    { label: 'PEN - Peruvian Sol', value: 'PEN' },
    { label: 'PGK - Papua New Guinean Kina', value: 'PGK' },
    { label: 'PHP - Philippine Peso', value: 'PHP' },
    { label: 'PKR - Pakistani Rupee', value: 'PKR' },
    { label: 'PLN - Polish Zloty', value: 'PLN' },
    { label: 'PYG - Paraguayan Guarani', value: 'PYG' },
    { label: 'QAR - Qatari Rial', value: 'QAR' },
    { label: 'RON - Romanian Leu', value: 'RON' },
    { label: 'RSD - Serbian Dinar', value: 'RSD' },
    { label: 'RUB - Russian Ruble', value: 'RUB' },
    { label: 'RWF - Rwandan Franc', value: 'RWF' },
    { label: 'SAR - Saudi Riyal', value: 'SAR' },
    { label: 'SBD - Solomon Islands Dollar', value: 'SBD' },
    { label: 'SCR - Seychellois Rupee', value: 'SCR' },
    { label: 'SDG - Sudanese Pound', value: 'SDG' },
    { label: 'SEK - Swedish Krona', value: 'SEK' },
    { label: 'SGD - Singapore Dollar', value: 'SGD' },
    { label: 'SHP - Saint Helena Pound', value: 'SHP' },
    { label: 'SLL - Sierra Leonean Leone', value: 'SLL' },
    { label: 'SOS - Somali Shilling', value: 'SOS' },
    { label: 'SRD - Surinamese Dollar', value: 'SRD' },
    { label: 'SSP - South Sudanese Pound', value: 'SSP' },
    { label: 'STN - São Tomé and Príncipe Dobra', value: 'STN' },
    { label: 'SVC - Salvadoran Colón', value: 'SVC' },
    { label: 'SYP - Syrian Pound', value: 'SYP' },
    { label: 'SZL - Swazi Lilangeni', value: 'SZL' },
    { label: 'THB - Thai Baht', value: 'THB' },
    { label: 'TJS - Tajikistani Somoni', value: 'TJS' },
    { label: 'TMT - Turkmenistani Manat', value: 'TMT' },
    { label: 'TND - Tunisian Dinar', value: 'TND' },
    { label: 'TOP - Tongan Paʻanga', value: 'TOP' },
    { label: 'TRY - Turkish Lira', value: 'TRY' },
    { label: 'TTD - Trinidad and Tobago Dollar', value: 'TTD' },
    { label: 'TWD - New Taiwan Dollar', value: 'TWD' },
    { label: 'TZS - Tanzanian Shilling', value: 'TZS' },
    { label: 'UAH - Ukrainian Hryvnia', value: 'UAH' },
    { label: 'UGX - Ugandan Shilling', value: 'UGX' },
    { label: 'USN - US Dollar (Next day)', value: 'USN' },
    { label: 'UYI - Uruguayan Peso en Unidades Indexadas', value: 'UYI' },
    { label: 'UYU - Uruguayan Peso', value: 'UYU' },
    { label: 'UYW - Unidad Previsional', value: 'UYW' },
    { label: 'UZS - Uzbekistan Som', value: 'UZS' },
    { label: 'VED - Venezuelan Bolívar Digital', value: 'VED' },
    { label: 'VES - Venezuelan Bolívar Soberano', value: 'VES' },
    { label: 'VND - Vietnamese Dong', value: 'VND' },
    { label: 'VUV - Vanuatu Vatu', value: 'VUV' },
    { label: 'WST - Samoan Tala', value: 'WST' },
    { label: 'XAD - Active Day Unit', value: 'XAD' },
    { label: 'XAF - CFA Franc BEAC', value: 'XAF' },
    { label: 'XAG - Silver (troy ounce)', value: 'XAG' },
    { label: 'XAU - Gold (troy ounce)', value: 'XAU' },
    { label: 'XBA - European Composite Unit', value: 'XBA' },
    { label: 'XBB - European Monetary Unit', value: 'XBB' },
    { label: 'XBC - European Unit of Account 9', value: 'XBC' },
    { label: 'XBD - European Unit of Account 17', value: 'XBD' },
    { label: 'XCD - East Caribbean Dollar', value: 'XCD' },
    { label: 'XDR - Special Drawing Rights', value: 'XDR' },
    { label: 'XOF - CFA Franc BCEAO', value: 'XOF' },
    { label: 'XPD - Palladium (troy ounce)', value: 'XPD' },
    { label: 'XPF - CFP Franc', value: 'XPF' },
    { label: 'XPT - Platinum (troy ounce)', value: 'XPT' },
    { label: 'XSU - Sucre', value: 'XSU' },
    { label: 'XTS - Code for Testing', value: 'XTS' },
    { label: 'XXX - No Currency', value: 'XXX' },
    { label: 'YER - Yemeni Rial', value: 'YER' },
    { label: 'ZAR - South African Rand', value: 'ZAR' },
    { label: 'ZMW - Zambian Kwacha', value: 'ZMW' },
    { label: 'ZWL - Zimbabwean Dollar', value: 'ZWL' }
];

const CURRENCY_PAIR_OPTIONS = [
    { label: 'USD/EUR', value: 'USD_EUR' },
    { label: 'USD/GBP', value: 'USD_GBP' },
    { label: 'EUR/GBP', value: 'EUR_GBP' },
    { label: 'USD/JPY', value: 'USD_JPY' },
    { label: 'Other', value: 'Other' }
];

const ACCEPTED_FILE_TYPES = '.pdf,.jpg,.jpeg,.png,.doc,.docx';

const ADDITIONAL_ROLE_OPTIONS = [
    { label: 'Director', value: 'Director' },
    { label: 'Signatory', value: 'Signatory' },
    { label: 'UBO', value: 'UBO' }
];

// ============================================
// STEP CONFIGURATION - Single Source of Truth
// ============================================

/**
 * @description Configuration for Private Client onboarding steps
 * Defines step order, labels, and lifecycle hooks
 */
const PRIVATE_STEPS_CONFIG = [
    { 
        key: 'entry', 
        label: 'Get Started', 
        onEnter: null,
        onExit: null 
    },
    { 
        key: 'personal', 
        label: 'Personal Info',
        onEnter: null,
        onExit: null
    },
    { 
        key: 'address', 
        label: 'Address',
        onEnter: null,
        onExit: null
    },
    { 
        key: 'risk', 
        label: 'Risk Assessment',
        onEnter: null,
        onExit: 'autoSaveAndWait'
    },
    { 
        key: 'declarations', 
        label: 'Declarations',
        onEnter: null,
        onExit: null
    }
];

/**
 * @description Configuration for Corporate Client onboarding steps
 * Defines step order, labels, and lifecycle hooks
 */
const CORPORATE_STEPS_CONFIG = [
    { 
        key: 'entry', 
        label: 'Get Started', 
        onEnter: null,
        onExit: null 
    },
    { 
        key: 'company', 
        label: 'Company Info',
        onEnter: 'loadDraftCompanyInfo',
        onExit: 'autoSave'
    },
    { 
        key: 'business', 
        label: 'Business & Services',
        onEnter: null,
        onExit: 'autoSaveAndWait'
    },
    { 
        key: 'shareholders', 
        label: 'Shareholders',
        onEnter: null,
        onExit: 'autoSave'
    },
    { 
        key: 'declarations', 
        label: 'Declarations',
        onEnter: null,
        onExit: null
    }
];

export default class ClientOnboardingForm extends LightningElement {
    @api recordId;

    @track currentStep = 'entry';
    @track channel = 'ExperienceCloud';
    @track servicesRequired = [];
    @track clientType = '';
    @track showProgress = true;
    @track showSuccessMessage = false;
    @track submissionDate = '';
    @track isSubmitting = false;
    @track uploadDisabled = true;
    @track submissionError = null;
    @track showRetryButton = false;
    
    // Client Mode Detection
    @track isClientMode = false;           // ?mode=client in URL
    @track clientLink = '';                // Link for client to access the form
    
    // Track if component has been initialized
    _isInitialized = false;
    
    // PHASE 2: Mobile & Auto-Save Features
    @track isMobileDevice = false;
    @track isTabletDevice = false;
    @track autoSaveStatus = 'idle'; // idle, saving, saved, error
    @track lastSavedTime = null;
    @track lastSavedDisplay = '';
    _autoSaveTimer = null;
    _lastSavedInterval = null;
    _hasUnsavedChanges = false;
    
    /**
     * @description Initialize component - load recordId from URL or storage
     */
    async connectedCallback() {
        // PHASE 2: Detect device type
        this.detectDeviceType();
        
        // Initialize recordId
        this.initializeRecordId();
        
        // Load existing application data if recordId exists
        if (this.recordId) {
            await this.loadApplicationData();
        }
        
        // PHASE 2: Start auto-save timer (mobile-friendly)
        this.startAutoSaveTimer();
        
        // PHASE 2: Start last saved time updater
        this.startLastSavedUpdater();
        
        // Add resize listener for device detection
        window.addEventListener('resize', this.handleResize.bind(this));
    }
    
    /**
     * @description Cleanup on component disconnect
     */
    disconnectedCallback() {
        // PHASE 2: Clear timers
        if (this._autoSaveTimer) {
            clearInterval(this._autoSaveTimer);
        }
        if (this._lastSavedInterval) {
            clearInterval(this._lastSavedInterval);
        }
        
        // Remove resize listener
        window.removeEventListener('resize', this.handleResize.bind(this));
    }
    
    /**
     * @description Load recordId from URL parameter or localStorage for Experience Sites
     */
    initializeRecordId() {
        if (this._isInitialized) return;
        this._isInitialized = true;
        
        // Priority 1: Use existing recordId from component property (if passed by parent)
        if (this.recordId) {
            console.log('✅ RecordId provided by parent:', this.recordId);
            this.saveRecordIdToStorage(this.recordId);
            this.updateUrlWithRecordId(this.recordId);
            return;
        }
        
        // Priority 2: Try to get from URL parameter
        const urlRecordId = this.getRecordIdFromUrl();
        if (urlRecordId) {
            console.log('✅ RecordId loaded from URL:', urlRecordId);
            this.recordId = urlRecordId;
            this.saveRecordIdToStorage(urlRecordId);
            return;
        }
        
        // Priority 3: Try to get from localStorage (fallback) - ONLY if URL has no 'new' parameter
        // Allow ?new=true to force a new application even if localStorage has data
        const urlParams = new URLSearchParams(window.location.search);
        const forceNew = urlParams.get('new') === 'true';
        
        // HYBRID APPROACH: Detect Client Mode from URL
        this.detectClientMode(urlParams);
        
        if (!forceNew) {
            const storedRecordId = this.getRecordIdFromStorage();
            if (storedRecordId) {
                console.log('✅ RecordId loaded from storage:', storedRecordId);
                this.recordId = storedRecordId;
                this.updateUrlWithRecordId(storedRecordId);
                return;
            }
        } else {
            console.log('🆕 Force new application requested (URL param ?new=true)');
            this.clearRecordIdFromStorage();
        }
        
        console.log('🆕 No existing recordId found - new application will be created on first save');
    }
    
    /* ============================================
       PHASE 2: MOBILE DEVICE DETECTION
       ============================================ */
    
    /**
     * @description Detect device type based on screen width
     */
    detectDeviceType() {
        const width = window.innerWidth;
        this.isMobileDevice = width < 768;
        this.isTabletDevice = width >= 768 && width < 1024;
        
        console.log('📱 Device detection:', {
            width,
            isMobile: this.isMobileDevice,
            isTablet: this.isTabletDevice
        });
    }
    
    /**
     * @description Handle window resize
     */
    handleResize() {
        this.detectDeviceType();
    }
    
    /* ============================================
       PHASE 2: AUTO-SAVE FUNCTIONALITY
       ============================================ */
    
    /**
     * @description Start auto-save timer (saves every 30 seconds)
     */
    startAutoSaveTimer() {
        // Auto-save every 30 seconds if there are unsaved changes
        this._autoSaveTimer = setInterval(() => {
            if (this._hasUnsavedChanges && !this.isSubmitting && this.recordId) {
                console.log('🔄 Auto-save triggered');
                this.performAutoSave();
            }
        }, 30000); // 30 seconds
    }
    
    /**
     * @description Perform auto-save operation
     */
    async performAutoSave() {
        try {
            this.autoSaveStatus = 'saving';
            
            // Prepare form data
            const formData = this.prepareFormData();
            const formDataJson = JSON.stringify(formData);
            
            // Call Apex to save
            const result = await saveOnboardingApplication({ formDataJson });
            
            if (result.isSuccess) {
                this.autoSaveStatus = 'saved';
                this.lastSavedTime = new Date();
                this._hasUnsavedChanges = false;
                
                // Update recordId if it was created
                if (result.recordIds && result.recordIds.applicationId) {
                    this.recordId = result.recordIds.applicationId;
                    this.saveRecordIdToStorage(this.recordId);
                }
                
                console.log('✅ Auto-save successful');
                
                // Reset to idle after 3 seconds
                setTimeout(() => {
                    if (this.autoSaveStatus === 'saved') {
                        this.autoSaveStatus = 'idle';
                    }
                }, 3000);
            } else {
                this.autoSaveStatus = 'error';
                console.error('❌ Auto-save failed:', result.errors);
                
                // Reset to idle after 5 seconds
                setTimeout(() => {
                    this.autoSaveStatus = 'idle';
                }, 5000);
            }
        } catch (error) {
            this.autoSaveStatus = 'error';
            console.error('❌ Auto-save error:', error);
            
            // Reset to idle after 5 seconds
            setTimeout(() => {
                this.autoSaveStatus = 'idle';
            }, 5000);
        }
    }
    
    /**
     * @description Mark form as having unsaved changes
     */
    markAsChanged() {
        this._hasUnsavedChanges = true;
    }
    
    /**
     * @description Start interval to update "last saved" display
     */
    startLastSavedUpdater() {
        this._lastSavedInterval = setInterval(() => {
            if (this.lastSavedTime) {
                this.updateLastSavedDisplay();
            }
        }, 60000); // Update every minute
    }
    
    /**
     * @description Update the "last saved" display text
     */
    updateLastSavedDisplay() {
        if (!this.lastSavedTime) {
            this.lastSavedDisplay = '';
            return;
        }
        
        const now = new Date();
        const diff = Math.floor((now - this.lastSavedTime) / 1000); // seconds
        
        if (diff < 60) {
            this.lastSavedDisplay = 'Saved just now';
        } else if (diff < 3600) {
            const minutes = Math.floor(diff / 60);
            this.lastSavedDisplay = `Saved ${minutes} minute${minutes > 1 ? 's' : ''} ago`;
        } else {
            const hours = Math.floor(diff / 3600);
            this.lastSavedDisplay = `Saved ${hours} hour${hours > 1 ? 's' : ''} ago`;
        }
    }
    
    /* ============================================
       COMPUTED PROPERTIES FOR MOBILE
       ============================================ */
    
    /**
     * @description Check if auto-save indicator should be shown
     */
    get showAutoSaveIndicator() {
        return this.autoSaveStatus !== 'idle' || this.lastSavedTime !== null;
    }
    
    /**
     * @description Get auto-save indicator CSS classes
     */
    get autoSaveIndicatorClass() {
        return `auto-save-indicator ${this.autoSaveStatus}`;
    }
    
    /**
     * @description Get auto-save icon name
     */
    get autoSaveIconName() {
        switch (this.autoSaveStatus) {
            case 'saving': return 'utility:sync';
            case 'saved': return 'utility:success';
            case 'error': return 'utility:warning';
            default: return 'utility:check';
        }
    }
    
    /**
     * @description Get auto-save message
     */
    get autoSaveMessage() {
        switch (this.autoSaveStatus) {
            case 'saving': return 'Saving...';
            case 'saved': return this.lastSavedDisplay || 'Saved';
            case 'error': return 'Save failed - will retry';
            default: return this.lastSavedDisplay || '';
        }
    }
    
    /**
     * @description Check if mobile navigation should be shown
     */
    get showMobileNavigation() {
        return this.isMobileDevice && !this.showSuccessMessage;
    }
    
    /**
     * @description Scroll to first error on validation failure
     */
    scrollToFirstError() {
        // Give DOM time to render error messages
        setTimeout(() => {
            const firstError = this.template.querySelector('.slds-has-error');
            if (firstError) {
                firstError.scrollIntoView({ 
                    behavior: 'smooth', 
                    block: 'center' 
                });
                
                // Find the input and focus it
                const input = firstError.querySelector('input, select, textarea');
                if (input) {
                    input.focus();
                }
            }
        }, 100);
    }
    
    /**
     * @description Load existing application data from Salesforce
     * CRITICAL: This populates servicesRequired, clientType, shareholders, and authorized users
     */
    async loadApplicationData() {
        try {
            console.log('📥 Loading application data for recordId:', this.recordId);
            
            const appData = await getOnboardingApplication({ applicationId: this.recordId });
            
            if (appData) {
                // Load Services Required
                if (appData.servicesRequired && Array.isArray(appData.servicesRequired) && appData.servicesRequired.length > 0) {
                    // Filter out any undefined/null values
                    this.servicesRequired = appData.servicesRequired.filter(s => s != null && s !== '');
                    console.log('✅ Loaded servicesRequired:', this.servicesRequired);
                } else {
                    this.servicesRequired = [];
                }
                
                // Load Client Type
                if (appData.clientType) {
                    this.clientType = appData.clientType;
                    console.log('✅ Loaded clientType:', this.clientType);
                }
                
                // Load Channel
                if (appData.channel) {
                    this.channel = appData.channel;
                    console.log('✅ Loaded channel:', this.channel);
                }
                
                // Load Shareholders
                if (appData.shareholders && appData.shareholders.length > 0) {
                    this.shareholders = appData.shareholders.map(sh => ({
                        id: sh.id,
                        type: sh.type || 'Individual',
                        firstName: sh.firstName || '',
                        middleName: sh.middleName || '',
                        lastName: sh.lastName || '',
                        email: sh.email || '',
                        phone: sh.phone || '',
                        mobile: sh.mobile || '',
                        // Map to correct form field names (with "OrIncorporation" suffix)
                        dateOfBirthOrIncorporation: sh.dateOfBirth || '',
                        nationalityOrCountryOfIncorporation: sh.nationality || '',
                        countryOfResidenceOrIncorporation: sh.countryOfResidence || '',
                        governmentIdOrRegistrationNumber: sh.governmentIdNumber || '',
                        isPEP: sh.isPEP ? 'Yes' : 'No',
                        sourceOfWealth: sh.sourceOfWealth || '',
                        sourceOfWealthExplanation: sh.sourceOfWealthExplanation || '',
                        ownershipPercentage: sh.ownershipPercentage || '',
                        legalEntityName: sh.legalEntityName || '',
                        legalEntityType: sh.legalEntityType || '',
                        dateOfIncorporation: sh.dateOfIncorporation || '',
                        countryOfIncorporation: sh.countryOfIncorporation || '',
                        registrationNumber: sh.registrationNumber || '',
                        // Map address fields
                        street: sh.address?.street || '',
                        city: sh.address?.city || '',
                        state: sh.address?.state || '',
                        postalCode: sh.address?.postalCode || '',
                        country: sh.address?.country || ''
                    }));
                    console.log('✅ Loaded shareholders:', this.shareholders.length, 'records');
                }
                
                // Load Authorized Users
                if (appData.authorisedUsers && appData.authorisedUsers.length > 0) {
                    console.log('📥 Raw authorisedUsers from Apex:', JSON.parse(JSON.stringify(appData.authorisedUsers)));
                    this.authorisedUsers = appData.authorisedUsers.map(au => ({
                        id: au.id,
                        firstName: au.firstName || '',
                        middleName: au.middleName || '',
                        lastName: au.lastName || '',
                        email: au.email || '',
                        phone: au.phone || '',
                        mobileNumber: au.mobile || '',
                        dateOfBirth: au.dateOfBirth || '',
                        nationality: au.nationality || '',
                        countryOfResidence: au.countryOfResidence || '',
                        governmentIdNumber: au.governmentIdNumber || '',
                        isPEP: au.isPEP ? 'Yes' : 'No',
                        sourceOfWealth: au.sourceOfWealth || '',
                        sourceOfWealthExplanation: au.sourceOfWealthExplanation || '',
                        position: au.positionTitle || '',
                        isPrimaryContact: au.isPrimaryContact || false,
                        // Map address fields
                        street: au.address?.street || '',
                        city: au.address?.city || '',
                        state: au.address?.state || '',
                        postalCode: au.address?.postalCode || '',
                        country: au.address?.country || ''
                    }));
                    console.log('✅ Loaded authorisedUsers:', this.authorisedUsers.length, 'records');
                    console.log('✅ Mapped authorisedUsers:', JSON.parse(JSON.stringify(this.authorisedUsers)));
                } else {
                    console.warn('⚠️ No authorisedUsers in appData or empty array');
                }
                
                // Load Risk Info (Private client Source of Wealth)
                if (appData.riskInfo) {
                    this.riskInfo = {
                        ...this.riskInfo,
                        sourceOfWealth: appData.riskInfo.sourceOfWealth || '',
                        sourceOfWealthExplanation: appData.riskInfo.sourceOfWealthExplanation || '',
                        expectedMonthlyVolume: appData.riskInfo.expectedMonthlyVolume || '',
                        estimatedTransactionsPerMonth: appData.riskInfo.estimatedTransactionsPerMonth || '',
                        geographicExposure: appData.riskInfo.geographicExposure || [],
                        intendedUseOfAccount: appData.riskInfo.intendedUseOfAccount || ''
                    };
                    console.log('✅ Loaded riskInfo from server');
                }

                // Load Additional Parties
                if (appData.additionalParties && appData.additionalParties.length > 0) {
                    console.log('📥 Raw additionalParties from Apex:', JSON.parse(JSON.stringify(appData.additionalParties)));
                    this.additionalParties = appData.additionalParties.map(ap => ({
                        id: ap.id,
                        role: ap.role || '',
                        type: ap.type || 'Individual',
                        firstName: ap.firstName || '',
                        middleName: ap.middleName || '',
                        lastName: ap.lastName || '',
                        email: ap.email || '',
                        phone: ap.phone || '',
                        // Map to correct form field names (with "OrIncorporation" suffix)
                        dateOfBirthOrIncorporation: ap.dateOfBirth || '',
                        nationalityOrCountryOfIncorporation: ap.nationality || '',
                        countryOfResidenceOrIncorporation: ap.countryOfResidence || '',
                        governmentIdOrRegistrationNumber: ap.governmentIdNumber || '',
                        isPEP: ap.isPEP ? 'Yes' : 'No',
                        sourceOfWealth: ap.sourceOfWealth || '',
                        sourceOfWealthExplanation: ap.sourceOfWealthExplanation || '',
                        positionTitle: ap.positionTitle || '',
                        legalEntityName: ap.legalEntityName || '',
                        legalEntityType: ap.legalEntityType || '',
                        dateOfIncorporation: ap.dateOfIncorporation || '',
                        countryOfIncorporation: ap.countryOfIncorporation || '',
                        registrationNumber: ap.registrationNumber || '',
                        // Map address fields
                        street: ap.address?.street || '',
                        city: ap.address?.city || '',
                        state: ap.address?.state || '',
                        postalCode: ap.address?.postalCode || '',
                        country: ap.address?.country || ''
                    }));
                    console.log('✅ Loaded additionalParties:', this.additionalParties.length, 'records');
                    console.log('✅ Mapped additionalParties:', JSON.parse(JSON.stringify(this.additionalParties)));
                } else {
                    console.warn('⚠️ No additionalParties in appData or empty array');
                }
                
                console.log('✅ Application data loaded successfully');
            }
        } catch (error) {
            console.error('❌ Error loading application data:', error);
            // Don't throw - allow form to continue with empty values
        }
    }
    
    /**
     * @description Detect Client Mode from URL parameters
     * ?mode=client = External client accessing the form
     */
    detectClientMode(urlParams) {
        // Check if ?mode=client is in URL
        const mode = urlParams.get('mode');
        this.isClientMode = (mode === 'client');
        
        console.log('🎯 Client Mode Detection:', {
            isClientMode: this.isClientMode
        });
        
        // Generate shareable link if we have a recordId
        if (this.recordId) {
            this.generateClientLinks();
        }
    }
    
    /**
     * @description Generate shareable client link for copying
     */
    generateClientLinks() {
        const baseUrl = window.location.origin + window.location.pathname;
        
        // Single link for client to access the form
        this.clientLink = `${baseUrl}?mode=client&id=${this.recordId}`;
        
        console.log('📋 Client Link Generated:', this.clientLink);
    }
    
    /**
     * @description Get recordId from URL parameter
     */
    getRecordIdFromUrl() {
        try {
            const params = new URLSearchParams(window.location.search);
            return params.get('recordId') || params.get('id');
        } catch (e) {
            console.warn('Failed to read URL parameters:', e);
            return null;
        }
    }
    
    /**
     * @description Update URL with recordId (without page refresh)
     */
    updateUrlWithRecordId(recordId) {
        if (!recordId) return;
        
        try {
            const url = new URL(window.location.href);
            url.searchParams.set('recordId', recordId);
            window.history.replaceState({}, '', url.toString());
            console.log('URL updated with recordId:', recordId);
        } catch (e) {
            console.warn('Failed to update URL:', e);
        }
    }
    
    /**
     * @description Save recordId to localStorage
     */
    saveRecordIdToStorage(recordId) {
        if (!recordId) return;
        
        try {
            localStorage.setItem('onboarding_recordId', recordId);
            localStorage.setItem('onboarding_recordId_timestamp', Date.now().toString());
        } catch (e) {
            console.warn('Failed to save to localStorage:', e);
        }
    }
    
    /**
     * @description Get recordId from localStorage (with 1-hour expiry)
     */
    getRecordIdFromStorage() {
        try {
            const recordId = localStorage.getItem('onboarding_recordId');
            const timestamp = localStorage.getItem('onboarding_recordId_timestamp');
            
            if (!recordId || !timestamp) return null;
            
            // Check if stored data is less than 1 hour old (shorter expiry for better UX)
            const age = Date.now() - parseInt(timestamp);
            const maxAge = 1 * 60 * 60 * 1000; // 1 hour (reduced from 24 hours)
            
            if (age > maxAge) {
                // Clear expired data
                console.log('🕐 localStorage recordId expired (>1 hour old), clearing...');
                this.clearRecordIdFromStorage();
                return null;
            }
            
            return recordId;
        } catch (e) {
            console.warn('Failed to read from localStorage:', e);
            return null;
        }
    }
    
    /**
     * @description Clear recordId from localStorage
     */
    clearRecordIdFromStorage() {
        try {
            localStorage.removeItem('onboarding_recordId');
            localStorage.removeItem('onboarding_recordId_timestamp');
        } catch (e) {
            console.warn('Failed to clear localStorage:', e);
        }
    }
    
    /**
     * @description Start a new application (clear recordId)
     */
    startNewApplication() {
        this.recordId = null;
        this.clearRecordIdFromStorage();
        // Remove recordId from URL
        try {
            const url = new URL(window.location.href);
            url.searchParams.delete('recordId');
            url.searchParams.delete('id');
            window.history.replaceState({}, '', url.toString());
        } catch (e) {
            console.warn('Failed to update URL:', e);
        }
    }

    @track personalInfo = {
        salutation: '',
        firstName: '',
        middleName: '',
        lastName: '',
        suffix: '',
        dateOfBirth: '',
        nationality: '',
        countryOfResidence: '',
        governmentIdNumber: '',
        email: '',
        mobile: '',
        phone: '',
        website: '',
        isPEP: ''
    };

    @track countryPicklistOptions = [];

    @track addressInfo = {
        street: '',
        city: '',
        state: '',
        postalCode: '',
        country: '',
        addressType: '',
        addressVerified: false,
        verificationProvider: '',
        proofOfAddressUpload: []
    };

    @track addressSearchQuery = '';
    @track addressSuggestions = [];
    @track showAddressSuggestions = false;
    searchTimeout;

    @track riskInfo = {
        expectedMonthlyVolume: '',
        estimatedTransactionsPerMonth: '',
        sourceOfWealth: '',
        sourceOfWealthExplanation: '',
        geographicExposure: [],
        intendedUseOfAccount: '',
        sourceOfWealthUpload: []
    };

    @track shareholders = [];
    @track authorisedUsers = [];
    @track additionalParties = [];

    @track companyInfo = {
        legalEntityName: '',
        tradingName: '',
        legalEntityType: '',
        dateOfIncorporation: '',
        countryOfIncorporation: '',
        registrationNumber: '',
        // Registered Business Address (structured fields)
        registeredStreet: '',
        registeredCity: '',
        registeredState: '',
        registeredPostalCode: '',
        registeredCountry: '',
        isRegulatedFinancialInstitution: '',
        regulatorName: '',
        regulatoryLicenceNumber: '',
        regulatoryJurisdiction: '',
        website: '',
        email: '',
        phone: '',
        natureOfBusiness: '',
        restrictedActivities: [],
        expectedNumberOfEmployees: ''
    };

    @track businessContext = {
        purposeOfAccount: '',
        industry: '',
        productsAndServices: '',
        paymentFlowTypes: [],
        expectedTransactionsPerMonth: '',
        expectedAnnualVolume: '',
        typicalValuePerTransaction: '',
        currenciesToSend: [],
        currenciesToReceive: [],
        countriesFundsSentTo: [],
        countriesFundsReceivedFrom: [],
        largestSingleTransaction: '',
        primarySourceOfFunds: '',
        // sourceOfWealthForBusinessOwners: '', // Field removed - captured in Explanation
        sourceOfWealthExplanation: '',
        sourceOfFundsUpload: []
    };

    @track serviceSpecific = {
        currenciesToSend: [],
        currenciesToReceive: [],
        countriesFundsSentTo: [],
        countriesFundsReceivedFrom: [],
        fxForwardContractsRequired: '',
        fxHedgingNeeds: '',
        digitalAssets: [],
        expectedMonthlyCryptoVolume: '',
        averageCryptoTransactionSize: '',
        // isVASP: '', // Removed - regulatory status captured in Company Info step
        advisoryServicesRequired: [],
        investmentObjectives: [],
        riskAppetite: '',
        timeHorizon: '',
        existingAdvisoryRelationships: ''
    };

    @track regulatoryInfo = {
        additionalUBOs: '',
        onSanctionsList: '',
        financialCrimeConviction: '',
        pepInOrganization: '',
        providesMoneyServices: '',
        additionalComplianceNotes: ''
    };

    @track declarations = {
        agreeToTerms: false,
        signatoryFirstName: '',
        signatoryLastName: '',
        clientNotes: ''
    };

    @track stepCompleted = {
        entry: false,
        personal: false,
        address: false,
        risk: false,
        declarations: false
    };

    // Track uploaded files by field name
    @track uploadedFiles = {};

    salutationOptions = TITLE_OPTIONS;
    clientTypeOptions = CLIENT_TYPE_OPTIONS;
    yesNoOptions = YES_NO_OPTIONS;
    sourceOfWealthOptions = SOURCE_OF_WEALTH_OPTIONS;
    sourceOfFundsOptions = SOURCE_OF_FUNDS_OPTIONS;
    shareholderTypeOptions = SHAREHOLDER_TYPE_OPTIONS;
    roleOptions = [
        { label: 'Shareholder', value: 'Shareholder' },
        { label: 'Director', value: 'Director' }
    ];
    additionalRoleOptions = ADDITIONAL_ROLE_OPTIONS;
    channelOptions = CHANNEL_OPTIONS;
    addressTypeOptions = ADDRESS_TYPE_OPTIONS;
    legalEntityTypeOptions = LEGAL_ENTITY_TYPE_OPTIONS;
    // restrictedActivitiesOptions = RESTRICTED_ACTIVITIES_OPTIONS; // Field removed from UI
    paymentFlowTypeOptions = PAYMENT_FLOW_TYPE_OPTIONS;
    tradingExperienceOptions = TRADING_EXPERIENCE_OPTIONS;
    tradeFrequencyOptions = TRADE_FREQUENCY_OPTIONS;
    advisoryServicesOptions = ADVISORY_SERVICES_OPTIONS;
    investmentObjectivesOptions = INVESTMENT_OBJECTIVES_OPTIONS;
    riskAppetiteOptions = RISK_APPETITE_OPTIONS;
    digitalAssetOptions = DIGITAL_ASSET_OPTIONS;
    countryOptions = COUNTRY_OPTIONS;
    currencyOptions = CURRENCY_OPTIONS;
    currencyPairOptions = CURRENCY_PAIR_OPTIONS;
    acceptedFileTypes = ACCEPTED_FILE_TYPES;

    // Industry picklist from Account.Industry via LDS
    industryOptions = [];
    accountRecordTypeId;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredAccountObjectInfo({ error, data }) {
        if (data) {
            this.accountRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error('Error loading Account object info:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$accountRecordTypeId', fieldApiName: INDUSTRY_FIELD })
    wiredIndustryPicklist({ error, data }) {
        if (data) {
            this.industryOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error loading Industry picklist values:', error);
        }
    }

    @wire(getCountryPicklistValues)
    wiredCountryPicklist({ error, data }) {
        if (data) {
            this.countryPicklistOptions = data.map(item => ({
                label: item.label || item.Label,
                value: item.value || item.Value
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load country picklist values', 'error');
            console.error('Error loading country picklist:', error);
        }
    }

    get logoUrl() {
        return LYDIAM_LOGO;
    }

    get totalSteps() {
        if (!this.clientType) {
            return 1;
        }
        return this.getStepsConfig().length;
    }

    get currentStepNumber() {
        if (!this.clientType) {
            return 1;
        }
        const index = this.getCurrentStepIndex();
        return index >= 0 ? index + 1 : 1;
    }

    get progressPercentage() {
        if (this.totalSteps === 0) return 0;
        return Math.round((this.currentStepNumber / this.totalSteps) * 100);
    }
    
    /* ============================================
       PHASE 2: MOBILE NAVIGATION HELPERS
       ============================================ */
    
    /**
     * @description Check if current step is the first step
     */
    get isFirstStep() {
        return this.currentStep === 'entry';
    }
    
    /**
     * @description Check if current step is the last step
     */
    get isLastStep() {
        return this.currentStep === 'declarations';
    }
    
    /**
     * @description Get mobile navigation "Next" button label
     */
    get mobileNavNextLabel() {
        return this.isLastStep ? 'Submit' : 'Next';
    }
    
    /**
     * @description Get mobile navigation "Next" button icon
     */
    get mobileNavNextIcon() {
        return this.isLastStep ? 'utility:check' : 'utility:forward';
    }
    
    /**
     * @description Handle mobile navigation "Next" button click
     */
    handleMobileNavNext() {
        if (this.isLastStep) {
            this.handleSubmit();
        } else {
            this.handleContinue();
        }
    }

    // Computed property getters for name field split support
    get shareholdersWithComputedFields() {
        if (!this.shareholders || this.shareholders.length === 0) {
            return [];
        }
        
        return this.shareholders.map(sh => {
            const isIndividual = sh.type === 'Individual';
            const isCorporate = sh.type === 'Corporate';
            
            let displayName = '';
            if (isIndividual) {
                const nameParts = [sh.firstName, sh.middleName, sh.lastName].filter(n => n);
                displayName = nameParts.join(' ');
            } else if (isCorporate) {
                displayName = sh.legalEntityName || '';
            } else {
                displayName = sh.name || '';  // Fallback for old data
            }
            
            return {
                ...sh,
                isIndividual: isIndividual,
                isCorporate: isCorporate,
                displayName: displayName,
                pepRadioName: `isPEP_${sh.id}`  // Unique name for each shareholder's PEP radio
            };
        });
    }

    get authorisedUsersWithComputedFields() {
        if (!this.authorisedUsers || this.authorisedUsers.length === 0) {
            return [];
        }
        
        return this.authorisedUsers.map(user => {
            const nameParts = [user.firstName, user.middleName, user.lastName].filter(n => n);
            const displayName = nameParts.join(' ') || user.name || '';  // Fallback to old name
            
            // Determine if this user is copied from a shareholder
            const isCopiedFromShareholder = Boolean(user.selectedShareholderId);
            
            return {
                ...user,
                displayName: displayName,
                isCopiedFromShareholder: isCopiedFromShareholder
            };
        });
    }

    get additionalPartiesWithComputedFields() {
        if (!this.additionalParties || this.additionalParties.length === 0) {
            return [];
        }
        
        return this.additionalParties.map(party => {
            const isIndividual = party.type === 'Individual';
            const isCorporate = party.type === 'Corporate';
            
            let displayName = '';
            if (isIndividual) {
                const nameParts = [party.firstName, party.middleName, party.lastName].filter(n => n);
                displayName = nameParts.join(' ');
            } else if (isCorporate) {
                displayName = party.legalEntityName || '';
            } else {
                displayName = party.name || '';  // Fallback
            }
            
            return {
                ...party,
                isIndividual: isIndividual,
                isCorporate: isCorporate,
                displayName: displayName
            };
        });
    }

    renderedCallback() {
        this.updateProgressBarWidth();
    }

    updateProgressBarWidth() {
        const bar = this.template.querySelector('.progress-bar-fill');
        if (bar) {
            bar.style.width = `${this.progressPercentage}%`;
        }
    }

    get progressSteps() {
        const steps = [];
        const stepsConfig = this.getStepsConfig();
        
        stepsConfig.forEach((stepDef, index) => {
            const isActive = this.currentStep === stepDef.key;
            const isCompleted = this.isStepCompleted(stepDef.key);
            const stepNumber = index + 1;
            const showConnector = index < stepsConfig.length - 1;
            
            let stepClass = 'fancy-step';
            if (isActive) {
                stepClass += ' fancy-step-active';
            } else if (isCompleted) {
                stepClass += ' fancy-step-completed';
            } else {
                stepClass += ' fancy-step-inactive';
            }
            
            let connectorClass = 'step-connector-line';
            if (isCompleted) {
                connectorClass += ' step-connector-completed';
            } else if (isActive) {
                connectorClass += ' step-connector-active';
            } else {
                connectorClass += ' step-connector-inactive';
            }
            
            let labelClass = 'step-label';
            if (isActive) {
                labelClass += ' step-label-active';
            } else if (isCompleted) {
                labelClass += ' step-label-completed';
            } else {
                labelClass += ' step-label-inactive';
            }
            
            let mobileDotClass = 'mobile-progress-dot';
            if (isCompleted) {
                mobileDotClass += ' completed';
            } else if (isActive) {
                mobileDotClass += ' active';
            }
            
            steps.push({
                key: stepDef.key,
                label: stepDef.label,
                step: stepDef.key,
                stepNumber: stepNumber,
                stepClass: stepClass,
                isActive: isActive,
                isCompleted: isCompleted,
                showConnector: showConnector,
                connectorClass: connectorClass,
                labelClass: labelClass,
                mobileDotClass: mobileDotClass
            });
        });
        
        return steps;
    }

    isStepCompleted(step) {
        if (step === 'entry') {
            return this.stepCompleted.entry;
        }
        if (step === 'personal') {
            return this.stepCompleted.personal;
        }
        if (step === 'address') {
            return this.stepCompleted.address;
        }
        if (step === 'risk') {
            return this.stepCompleted.risk;
        }
        if (step === 'shareholders' || step === 'company' || step === 'business' || 
            step === 'service' || step === 'regulatory' || step === 'documents') {
            return this.currentStep !== step && this.getStepIndex(this.currentStep) > this.getStepIndex(step);
        }
        return false;
    }

    getStepIndex(step) {
        const config = this.getStepsConfig();
        return config.findIndex(s => s.key === step);
    }

    // ============================================
    // CONFIGURATION-DRIVEN NAVIGATION HELPERS
    // ============================================

    /**
     * @description Get the appropriate step configuration based on client type
     * @returns {Array} Array of step configuration objects
     */
    getStepsConfig() {
        if (this.isPrivateClient) {
            return PRIVATE_STEPS_CONFIG;
        } else if (this.isCorporateClient) {
            return CORPORATE_STEPS_CONFIG;
        }
        return [{ key: 'entry', label: 'Get Started', onEnter: null, onExit: null }];
    }

    /**
     * @description Get current step configuration object
     * @returns {Object} Current step config
     */
    getCurrentStepConfig() {
        const config = this.getStepsConfig();
        return config.find(s => s.key === this.currentStep) || config[0];
    }

    /**
     * @description Get current step index in the configuration
     * @returns {Number} Current step index
     */
    getCurrentStepIndex() {
        return this.getStepIndex(this.currentStep);
    }

    /**
     * @description Get the next step configuration
     * @returns {Object|null} Next step config or null if at last step
     */
    getNextStepConfig() {
        const config = this.getStepsConfig();
        const currentIndex = this.getCurrentStepIndex();
        if (currentIndex >= 0 && currentIndex < config.length - 1) {
            return config[currentIndex + 1];
        }
        return null;
    }

    /**
     * @description Get the previous step configuration
     * @returns {Object|null} Previous step config or null if at first step
     */
    getPreviousStepConfig() {
        const config = this.getStepsConfig();
        const currentIndex = this.getCurrentStepIndex();
        if (currentIndex > 0) {
            return config[currentIndex - 1];
        }
        return null;
    }

    /**
     * @description Execute step lifecycle hooks (onEnter/onExit)
     * @param {String} hookName - Name of the lifecycle hook to execute
     */
    async executeStepLifecycle(hookName) {
        if (!hookName) return;

        switch (hookName) {
            case 'loadDraftCompanyInfo':
                if (this.recordId) {
                    await this.loadDraftCompanyInfo();
                }
                break;
            case 'autoSave':
                this.autoSaveDraft('lifecycle');
                break;
            case 'autoSaveAndWait':
                await this.autoSaveDraft('lifecycle');
                break;
            default:
                console.warn(`Unknown lifecycle hook: ${hookName}`);
        }
    }

    get formTitle() {
        if (this.showSuccessMessage) {
            return 'Application Submitted';
        }
        if (this.currentStep === 'entry') {
            return 'Client Onboarding - Get Started';
        }
        if (this.isPrivateClient) {
            return 'Private Client Onboarding';
        }
        if (this.isCorporateClient) {
            return 'Corporate Client Onboarding';
        }
        return 'Client Onboarding';
    }

    // ============================================
    // BANNER LOGIC
    // ============================================
    
    /**
     * @description Show orange "Agent Banner" for internal agents ONLY
     * CRITICAL: Never show in client mode (?mode=client)
     */
    get showAgentBanner() {
        // Double-check URL directly to prevent showing in client mode
        const urlParams = new URLSearchParams(window.location.search);
        const mode = urlParams.get('mode');
        
        // NEVER show if ?mode=client in URL
        if (mode === 'client' || this.isClientMode) {
            return false;
        }
        
        // Show for agents with saved applications
        return this.recordId && !this.showSuccessMessage;
    }
    
    /**
     * @description Show friendly blue "Client Banner" for returning clients
     * ONLY show when ?mode=client in URL
     */
    get showClientBanner() {
        // Double-check URL directly
        const urlParams = new URLSearchParams(window.location.search);
        const mode = urlParams.get('mode');
        
        // ONLY show if ?mode=client in URL
        return (mode === 'client' || this.isClientMode) && this.recordId && !this.showSuccessMessage;
    }
    
    get isPrivateClient() {
        return this.clientType === 'Private' || this.clientType === 'Private Individual';
    }

    get isCorporateClient() {
        return this.clientType === 'Corporate' || this.clientType === 'Corporate entity';
    }

    get showCorporateBranch() {
        return this.isCorporateClient && this.currentStep !== 'entry';
    }

    get showPrivateBranch() {
        return this.isPrivateClient && this.currentStep !== 'entry';
    }

    get serviceOptions() {
        return SERVICE_OPTIONS;
    }

    get showEntryStep() {
        return this.currentStep === 'entry';
    }

    get showShareholdersStep() {
        return this.isCorporateClient && this.currentStep === 'shareholders';
    }

    get showCompanyInfoStep() {
        return this.isCorporateClient && this.currentStep === 'company';
    }

    get showBusinessContextStep() {
        return this.isCorporateClient && this.currentStep === 'business';
    }

    get showDeclarationsStep() {
        return this.currentStep === 'declarations';
    }

    get showPersonalInfoStep() {
        return this.isPrivateClient && this.currentStep === 'personal';
    }

    get showAddressStep() {
        return this.isPrivateClient && this.currentStep === 'address';
    }

    get showRiskStep() {
        return this.isPrivateClient && this.currentStep === 'risk';
    }

    get isResumingSavedDraft() {
        return this.recordId != null && this.currentStep !== 'entry';
    }

    get showRiskSection() {
        return this.isPrivateClient;
    }

    get showTradingExperience() {
        return true; // Always show trading experience fields for authorized users
    }

    get hasFXService() {
        return this.servicesRequired.includes('FX');
    }

    get hasCryptoService() {
        return this.servicesRequired.includes('Crypto');
    }

    get hasAdvisoryService() {
        return this.servicesRequired.includes('Advisory');
    }

    get showHedgingNeeds() {
        return this.serviceSpecific?.fxForwardContractsRequired === 'Yes';
    }

    get showTradingExperience() {
        return this.hasFXService || this.hasCryptoService;
    }

    get hasShareholders() {
        return Array.isArray(this.shareholders) && this.shareholders.length > 0;
    }

    get shareholderOptions() {
        return (this.shareholders || []).map(sh => {
            // Use displayName from computed fields or build from split names
            let displayName = '';
            if (sh.type === 'Individual') {
                const nameParts = [sh.firstName, sh.middleName, sh.lastName].filter(n => n);
                displayName = nameParts.join(' ') || sh.name || 'Shareholder';
            } else if (sh.type === 'Corporate') {
                displayName = sh.legalEntityName || sh.name || 'Corporate Shareholder';
            } else {
                displayName = sh.name || 'Shareholder';
            }
            return {
                label: displayName,
                value: sh.id
            };
        });
    }

    get shareholderOptionsWithNone() {
        const options = [
            { label: '-- None (Enter Manually) --', value: '' }
        ];
        // Only include Individual shareholders (authorized users are always individuals)
        const individualShareholderOptions = (this.shareholders || [])
            .filter(sh => sh.type === 'Individual')
            .map(sh => {
                const nameParts = [sh.firstName, sh.middleName, sh.lastName].filter(n => n);
                const displayName = nameParts.join(' ') || sh.name || 'Individual Shareholder';
                return {
                    label: displayName,
                    value: sh.id
                };
            });
        return options.concat(individualShareholderOptions);
    }

    get shareholderCopyDisabled() {
        return !this.hasShareholders;
    }

    get showRegulatoryDetails() {
        return this.companyInfo.isRegulatedFinancialInstitution === 'Yes';
    }

    get showHedgingDetails() {
        return this.serviceSpecific.fxForwardContractsRequired === 'Yes';
    }

    get isEntryStepDisabled() {
        return !this.servicesRequired.length || !this.clientType;
    }

    get isPersonalInfoStepDisabled() {
        const info = this.personalInfo;
        
        const hasSalutation = info.salutation && String(info.salutation).trim().length > 0;
        const hasFirstName = info.firstName && String(info.firstName).trim().length > 0;
        const hasLastName = info.lastName && String(info.lastName).trim().length > 0;
        const hasDateOfBirth = info.dateOfBirth && String(info.dateOfBirth).trim().length > 0;
        const hasNationality = info.nationality && String(info.nationality).trim().length > 0;
        const hasCountryOfResidence = info.countryOfResidence && String(info.countryOfResidence).trim().length > 0;
        const hasGovernmentId = info.governmentIdNumber && String(info.governmentIdNumber).trim().length > 0;
        const hasEmail = info.email && String(info.email).trim().length > 0;
        const hasPEP = info.isPEP === 'Yes' || info.isPEP === 'No';
        
        const isValid = hasSalutation && hasFirstName && hasLastName && hasDateOfBirth && 
                        hasNationality && hasCountryOfResidence && hasGovernmentId && hasEmail && hasPEP;
        
        return !isValid;
    }

    get isAddressStepDisabled() {
        return !this.addressInfo.street ||
               !this.addressInfo.city ||
               !this.addressInfo.state ||
               !this.addressInfo.postalCode ||
               !this.addressInfo.country;
    }

    get isCompanyInfoStepDisabled() {
        const validations = {
            legalEntityName: !this.companyInfo.legalEntityName,
            legalEntityType: !this.companyInfo.legalEntityType,
            dateOfIncorporation: !this.companyInfo.dateOfIncorporation,
            countryOfIncorporation: !this.companyInfo.countryOfIncorporation,
            registrationNumber: !this.companyInfo.registrationNumber,
            registeredStreet: !this.companyInfo.registeredStreet,
            registeredCity: !this.companyInfo.registeredCity,
            registeredCountry: !this.companyInfo.registeredCountry,
            email: !this.companyInfo.email
            // natureOfBusiness validation removed - captured in Business Context step
        };
        
        const missingFields = Object.keys(validations).filter(key => validations[key]);
        if (missingFields.length > 0) {
            console.log('🚫 Company Info - Missing required fields:', JSON.stringify(missingFields));
            console.log('📋 Company Info current values:', JSON.stringify({
                legalEntityName: String(this.companyInfo.legalEntityName || ''),
                legalEntityType: String(this.companyInfo.legalEntityType || ''),
                dateOfIncorporation: String(this.companyInfo.dateOfIncorporation || ''),
                countryOfIncorporation: String(this.companyInfo.countryOfIncorporation || ''),
                registrationNumber: String(this.companyInfo.registrationNumber || ''),
                registeredStreet: String(this.companyInfo.registeredStreet || ''),
                registeredCity: String(this.companyInfo.registeredCity || ''),
                registeredCountry: String(this.companyInfo.registeredCountry || ''),
                email: String(this.companyInfo.email || '')
            }));
        }
        
        return missingFields.length > 0;
    }

    get isBusinessContextStepDisabled() {
        // Business Context validation
        const businessContextInvalid = 
               !this.businessContext.purposeOfAccount ||
               !this.businessContext.industry ||
               !this.businessContext.productsAndServices ||
               !this.businessContext.paymentFlowTypes.length ||
               !this.businessContext.expectedTransactionsPerMonth ||
               !this.businessContext.expectedAnnualVolume ||
               !this.businessContext.typicalValuePerTransaction ||
               !this.businessContext.countriesFundsSentTo.length ||
               !this.businessContext.countriesFundsReceivedFrom.length ||
               !this.businessContext.primarySourceOfFunds ||
               !this.businessContext.sourceOfWealthExplanation;
        
        if (businessContextInvalid) {
            return true;
        }
        
        // Service-specific validation (merged into this step)
        // FX Service validation (only if FX selected)
        if (this.hasFXService) {
            // Currencies required for FX
            if (!this.businessContext.currenciesToSend.length || !this.businessContext.currenciesToReceive.length) {
                return true;
            }
            // Forward contracts question required
            if (!this.serviceSpecific.fxForwardContractsRequired) {
                return true;
            }
            // If Yes to forward contracts, hedging needs required
            if (this.serviceSpecific.fxForwardContractsRequired === 'Yes' && !this.serviceSpecific.fxHedgingNeeds) {
                return true;
            }
        }
        
        // Crypto Service validation (only if Crypto selected)
        if (this.hasCryptoService) {
            if (!this.serviceSpecific.digitalAssets.length ||
                !this.serviceSpecific.expectedMonthlyCryptoVolume ||
                !this.serviceSpecific.averageCryptoTransactionSize) {
                // isVASP validation removed - regulatory status captured in Company Info step
                return true;
            }
        }
        
        // Advisory Service validation (only if Advisory selected)
        if (this.hasAdvisoryService) {
            if (!this.serviceSpecific.advisoryServicesRequired.length ||
                !this.serviceSpecific.investmentObjectives.length ||
                !this.serviceSpecific.riskAppetite) {
                return true;
            }
        }
        
        return false;
    }

    get isRiskStepDisabled() {
        if (!this.isPrivateClient) {
            return false;
        }

        const riskInvalid =
            !this.riskInfo.sourceOfWealth ||
            !this.riskInfo.sourceOfWealthExplanation ||
            !this.riskInfo.estimatedTransactionsPerMonth ||
            !this.riskInfo.intendedUseOfAccount ||
            !Array.isArray(this.riskInfo.geographicExposure) ||
            this.riskInfo.geographicExposure.length === 0;
        if (riskInvalid) {
            return true;
        }

        if (this.hasFXService) {
            if (
                !Array.isArray(this.serviceSpecific.currenciesToSend) ||
                this.serviceSpecific.currenciesToSend.length === 0 ||
                !Array.isArray(this.serviceSpecific.currenciesToReceive) ||
                this.serviceSpecific.currenciesToReceive.length === 0 ||
                !this.serviceSpecific.fxForwardContractsRequired
            ) {
                return true;
            }
            if (this.serviceSpecific.fxForwardContractsRequired === 'Yes' && !this.serviceSpecific.fxHedgingNeeds) {
                return true;
            }
        }

        if (this.hasCryptoService) {
            if (
                !Array.isArray(this.serviceSpecific.digitalAssets) ||
                this.serviceSpecific.digitalAssets.length === 0 ||
                !this.serviceSpecific.expectedMonthlyCryptoVolume ||
                !this.serviceSpecific.averageCryptoTransactionSize
            ) {
                return true;
            }
        }

        if (this.hasAdvisoryService) {
            if (
                !Array.isArray(this.serviceSpecific.advisoryServicesRequired) ||
                this.serviceSpecific.advisoryServicesRequired.length === 0 ||
                !Array.isArray(this.serviceSpecific.investmentObjectives) ||
                this.serviceSpecific.investmentObjectives.length === 0 ||
                !this.serviceSpecific.riskAppetite
            ) {
                return true;
            }
        }

        return false;
    }

    get isShareholdersStepDisabled() {
        if (!this.isCorporateClient) {
            return false;
        }

        const activeShareholders = (Array.isArray(this.shareholders) ? this.shareholders : [])
            .filter(shareholder => this.hasShareholderInput(shareholder));
        const activeAuthorisedUsers = (Array.isArray(this.authorisedUsers) ? this.authorisedUsers : [])
            .filter(user => this.hasAuthorisedUserInput(user));
        const hasShareholders = activeShareholders.length > 0;
        const hasAuthorisedUsers = activeAuthorisedUsers.length > 0;

        // Allow either section to satisfy the step. At least one must exist.
        if (!hasShareholders && !hasAuthorisedUsers) {
            return true;
        }

        if (hasShareholders) {
            for (const shareholder of activeShareholders) {
                const isShareholder = shareholder?.isShareholder === true;
                const isDirector = shareholder?.isDirector === true;
                if (!isShareholder && !isDirector) {
                    return true;
                }

                if (shareholder?.type === 'Corporate') {
                    if (!shareholder?.legalEntityName) {
                        return true;
                    }
                } else if (!shareholder?.firstName || !shareholder?.lastName) {
                    return true;
                }

                if (
                    !shareholder?.dateOfBirthOrIncorporation ||
                    !shareholder?.countryOfResidenceOrIncorporation ||
                    !shareholder?.nationalityOrCountryOfIncorporation ||
                    !shareholder?.governmentIdOrRegistrationNumber ||
                    !shareholder?.isPEP ||
                    !shareholder?.email
                ) {
                    return true;
                }

                if (isShareholder && !shareholder?.ownershipPercentage) {
                    return true;
                }
            }
        }

        if (hasAuthorisedUsers) {
            const requiresTradingFrequency = this.hasFXService || this.hasCryptoService;
            for (const user of activeAuthorisedUsers) {
                if (
                    !user?.firstName ||
                    !user?.lastName ||
                    !user?.email ||
                    !user?.dateOfBirth ||
                    !user?.countryOfResidence ||
                    !user?.nationality ||
                    !user?.governmentIdNumber
                ) {
                    return true;
                }
                if (requiresTradingFrequency && !user?.tradeFrequency) {
                    return true;
                }
            }
        }

        return false;
    }

    hasShareholderInput(shareholder) {
        if (!shareholder) {
            return false;
        }
        return Boolean(
            shareholder.isShareholder === true ||
            shareholder.isDirector === true ||
            (shareholder.type && String(shareholder.type).trim()) ||
            (shareholder.firstName && String(shareholder.firstName).trim()) ||
            (shareholder.lastName && String(shareholder.lastName).trim()) ||
            (shareholder.legalEntityName && String(shareholder.legalEntityName).trim()) ||
            (shareholder.email && String(shareholder.email).trim()) ||
            (shareholder.dateOfBirthOrIncorporation && String(shareholder.dateOfBirthOrIncorporation).trim())
        );
    }

    hasAuthorisedUserInput(user) {
        if (!user) {
            return false;
        }
        return Boolean(
            (user.firstName && String(user.firstName).trim()) ||
            (user.lastName && String(user.lastName).trim()) ||
            (user.email && String(user.email).trim()) ||
            (user.dateOfBirth && String(user.dateOfBirth).trim()) ||
            (user.countryOfResidence && String(user.countryOfResidence).trim()) ||
            (user.nationality && String(user.nationality).trim()) ||
            (user.governmentIdNumber && String(user.governmentIdNumber).trim()) ||
            (user.tradeFrequency && String(user.tradeFrequency).trim())
        );
    }

    // Service validation is now part of Business Context step validation
    // Kept for backward compatibility but no longer actively used
    get isServiceSpecificStepDisabled() {
        // No longer used - service fields are now part of Business Context
        return false;
    }

    get isSubmitButtonDisabled() {
        return this.isSubmitDisabled || this.isSubmitting;
    }

    get isSubmitDisabled() {
        return !this.declarations.agreeToTerms ||
               !this.declarations.signatoryFirstName ||
               !this.declarations.signatoryLastName ||
               !this.declarations.signatoryFirstName.trim() ||
               !this.declarations.signatoryLastName.trim();
    }

    handleServicesChange(event) {
        const value = event.detail ? event.detail.value : (event.target ? event.target.value : []);
        this.servicesRequired = Array.isArray(value) ? value : [];
        console.log('Services changed:', this.servicesRequired);
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleClientTypeChange(event) {
        const value = event.detail ? event.detail.value : (event.target ? event.target.value : '');
        this.clientType = value || '';
        console.log('Client type changed:', this.clientType);
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleChannelChange(event) {
        const value = event.detail ? event.detail.value : (event.target ? event.target.value : '');
        this.channel = value || '';
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handlePersonalInfoChange(event) {
        const field = event.target.name;
        let value;
        
        if (event.detail && event.detail.value !== undefined) {
            value = event.detail.value;
        } else if (event.target.value !== undefined) {
            value = event.target.value;
        } else {
            value = '';
        }
        
        this.personalInfo = { ...this.personalInfo, [field]: value };
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleAddressChange(event) {
        const field = event.target.name;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.addressInfo = { ...this.addressInfo, [field]: value };
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleAddressSearchChange(event) {
        this.addressSearchQuery = event.target.value;
    }

    handleAddressSearchKeyup(event) {
        const query = event.target.value;
        this.addressSearchQuery = query;
        
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
        
        if (query && query.length >= 3) {
            this.searchTimeout = setTimeout(() => {
                this.performAddressSearch(query);
            }, 500);
        } else {
            this.showAddressSuggestions = false;
            this.addressSuggestions = [];
        }
    }

    async performAddressSearch(query) {
        try {
            const results = await searchAddress({ searchQuery: query });
            if (results && results.length > 0) {
                this.addressSuggestions = results;
                this.showAddressSuggestions = true;
            } else {
                this.showAddressSuggestions = false;
                this.addressSuggestions = [];
            }
        } catch (error) {
            console.error('Error searching address:', error);
            this.showAddressSuggestions = false;
            this.addressSuggestions = [];
        }
    }

    handleAddressSelect(event) {
        const placeId = event.currentTarget.dataset.placeId;
        const selectedAddress = this.addressSuggestions.find(addr => addr.placeId === placeId);
        
        if (selectedAddress) {
            this.addressInfo = {
                ...this.addressInfo,
                street: selectedAddress.street || '',
                city: selectedAddress.city || '',
                state: selectedAddress.state || '',
                postalCode: selectedAddress.postalCode || '',
                country: selectedAddress.country || ''
            };
            this.addressSearchQuery = selectedAddress.formattedAddress;
            this.showAddressSuggestions = false;
            this.addressSuggestions = [];
        }
    }

    handleRiskInfoChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.riskInfo = { ...this.riskInfo, [field]: value };
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleCompanyInfoChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        console.log(`📝 Company Info Changed - Field: ${field}, Value: "${value}"`);
        this.companyInfo = { ...this.companyInfo, [field]: value };
        console.log(`✅ Company Info Updated - ${field} is now: "${this.companyInfo[field]}"`);
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleBusinessContextChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.businessContext = { ...this.businessContext, [field]: value };
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleServiceSpecificChange(event) {
        const field = event.target ? event.target.name : (event.detail ? event.detail.name : '');
        
        // Handle different input types - dual-listbox uses event.detail.value (array)
        // while other inputs use event.target.value
        let value;
        if (event.detail && event.detail.value !== undefined) {
            value = event.detail.value; // For dual-listbox, combobox, etc.
        } else if (event.target && event.target.value !== undefined) {
            value = event.target.value; // For text inputs
        } else {
            value = '';
        }
        
        // Ensure arrays are properly handled - create a new array to break Proxy reference
        if (field === 'digitalAssets' || 
            field === 'advisoryServicesRequired' || 
            field === 'investmentObjectives' ||
            field === 'currenciesToSend' ||
            field === 'currenciesToReceive' ||
            field === 'countriesFundsSentTo' ||
            field === 'countriesFundsReceivedFrom') {
            if (Array.isArray(value)) {
                // Create a new array to break Proxy reference
                value = [...value];
            } else {
                value = [];
            }
        }
        
        // Create a new object to ensure reactivity and break Proxy references
        const updatedServiceSpecific = { ...this.serviceSpecific };
        updatedServiceSpecific[field] = value;
        this.serviceSpecific = updatedServiceSpecific;
        
        // Log with actual values extracted
        const logValue = Array.isArray(value) ? [...value] : String(value || '');
        console.log('Service specific changed:', field, '| Value:', logValue, '| Type:', typeof value, '| IsArray:', Array.isArray(value));
        
        // Log the current state of serviceSpecific to verify it's being stored
        console.log('serviceSpecific changed:', field, value);
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleRegulatoryChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        this.regulatoryInfo = { ...this.regulatoryInfo, [field]: value };
        this.markAsChanged(); // PHASE 2: Track changes
    }

    handleDeclarationsChange(event) {
        const field = event.target.name;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        // Ensure declarations object exists
        if (!this.declarations) {
            this.declarations = {
                agreeToTerms: false,
                signatoryFirstName: '',
                signatoryLastName: '',
                clientNotes: ''
            };
        }
        this.declarations = { ...this.declarations, [field]: value };
        console.log('Declarations changed:', field, value, JSON.parse(JSON.stringify(this.declarations)));
    }

    handleShareholderChange(event) {
        const shareholderId = event.target.dataset.id;
        // Check data-field first (for fields with dynamic names like PEP radio), then fall back to name
        let field = event.target.dataset.field || event.target.name;
        const value = event.target.value;

        // Map UI field names to DTO property names
        if (field === 'shareholderName') {
            field = 'name';
        } else if (field === 'shareholderType') {
            field = 'type';
        }
        
        this.shareholders = this.shareholders.map(shareholder => {
            if (shareholder.id === shareholderId) {
                let updated = { ...shareholder, [field]: value };
                
                // Clear name fields when type changes
                if (field === 'type') {
                    if (value === 'Individual') {
                        // Clear corporate fields
                        updated.legalEntityName = '';
                        // Initialize individual fields if not present
                        if (!updated.firstName) updated.firstName = '';
                        if (!updated.middleName) updated.middleName = '';
                        if (!updated.lastName) updated.lastName = '';
                    } else if (value === 'Corporate') {
                        // Clear individual fields
                        updated.firstName = '';
                        updated.middleName = '';
                        updated.lastName = '';
                        // Initialize corporate field
                        if (!updated.legalEntityName) updated.legalEntityName = '';
                    }
                }
                
                return updated;
            }
            return shareholder;
        });
    }

    handleShareholderRoleChange(event) {
        const shareholderId = event.target.dataset.id;
        const selectedRoles = event.detail.value; // Array like ['Shareholder', 'Director']
        
        this.shareholders = this.shareholders.map(shareholder => {
            if (shareholder.id === shareholderId) {
                const updated = {
                    ...shareholder,
                    selectedRoles: selectedRoles,
                    isShareholder: selectedRoles.includes('Shareholder'),
                    isDirector: selectedRoles.includes('Director')
                };
                return updated;
            }
            return shareholder;
        });
    }

    handleAuthorisedUserChange(event) {
        const userId = event.target.dataset.id;
        let field = event.target.name;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        // Map UI field names to DTO property names
        if (field === 'userName') {
            field = 'name';
        }
        
        // Initialize name fields if not present
        this.authorisedUsers = this.authorisedUsers.map(user => {
            if (user.id === userId) {
                // Ensure split name fields exist
                if (!user.firstName && field !== 'firstName') user.firstName = '';
                if (!user.middleName && field !== 'middleName') user.middleName = '';
                if (!user.lastName && field !== 'lastName') user.lastName = '';
                
                let updatedUser = { ...user, [field]: value };

                // Handle shareholder selection dropdown (no checkbox needed)
                if (field === 'selectedShareholderId') {
                    if (value) {
                        // Shareholder selected - copy fields
                        const targetShareholder = this.shareholders.find(sh => sh.id === value);
                        if (targetShareholder) {
                            updatedUser = this.copyShareholderFieldsToUser(updatedUser, targetShareholder);
                        }
                    } else {
                        // "None" selected or cleared - enable manual entry
                        updatedUser = this.clearShareholderCopiedFields(updatedUser);
                    }
                }

                return updatedUser;
            }
            return user;
        });
    }

    copyShareholderFieldsToUser(user, shareholder) {
        if (!shareholder) return user;
        const updated = { ...user };
        
        // Only copy from Individual shareholders (authorized users are always individuals)
        if (shareholder.type === 'Individual') {
            // Copy split name fields
            updated.salutation = shareholder.salutation || '';
            updated.firstName = shareholder.firstName || '';
            updated.middleName = shareholder.middleName || '';
            updated.lastName = shareholder.lastName || '';
            updated.suffix = shareholder.suffix || '';
            updated.dateOfBirth = shareholder.dateOfBirthOrIncorporation || '';
            updated.countryOfResidence = shareholder.countryOfResidenceOrIncorporation || '';
            updated.nationality = shareholder.nationalityOrCountryOfIncorporation || '';
            updated.governmentIdNumber = shareholder.governmentIdOrRegistrationNumber || '';
            updated.isPEP = shareholder.isPEP || '';
            updated.email = shareholder.email || '';
            updated.mobileNumber = shareholder.mobile || '';
            updated.phone = shareholder.phone || '';
            // Copy address fields
            updated.street = shareholder.street || '';
            updated.city = shareholder.city || '';
            updated.state = shareholder.state || '';
            updated.postalCode = shareholder.postalCode || '';
            updated.country = shareholder.country || '';
        } else {
            // Cannot copy from Corporate shareholder to Individual authorized user
            this.showToast('Warning', 'Cannot copy from Corporate shareholder. Authorized users must be individuals. Please enter manually or select an individual shareholder.', 'warning');
            // Clear the selection
            updated.selectedShareholderId = '';
        }
        
        return updated;
    }

    clearShareholderCopiedFields(user) {
        const cleared = { ...user };
        cleared.salutation = '';
        cleared.firstName = '';
        cleared.middleName = '';
        cleared.lastName = '';
        cleared.suffix = '';
        cleared.name = '';
        cleared.dateOfBirth = '';
        cleared.countryOfResidence = '';
        cleared.nationality = '';
        cleared.governmentIdNumber = '';
        cleared.isPEP = '';
        cleared.email = '';
        cleared.mobileNumber = '';
        cleared.phone = '';
        // Clear address fields
        cleared.street = '';
        cleared.city = '';
        cleared.state = '';
        cleared.postalCode = '';
        cleared.country = '';
        return cleared;
    }

    handleAdditionalPartyChange(event) {
        const partyId = event.target.dataset.id;
        const field = event.target.name;
        const value = event.target.value;
        
        this.additionalParties = this.additionalParties.map(p => {
            if (p.id === partyId) {
                let updated = { ...p, [field]: value };
                
                // Clear name fields when type changes
                if (field === 'type') {
                    if (value === 'Individual') {
                        // Clear corporate fields
                        updated.legalEntityName = '';
                        // Initialize individual fields if not present
                        if (!updated.firstName) updated.firstName = '';
                        if (!updated.middleName) updated.middleName = '';
                        if (!updated.lastName) updated.lastName = '';
                    } else if (value === 'Corporate') {
                        // Clear individual fields
                        updated.firstName = '';
                        updated.middleName = '';
                        updated.lastName = '';
                        // Initialize corporate field
                        if (!updated.legalEntityName) updated.legalEntityName = '';
                    }
                }
                
                return updated;
            }
            return p;
        });
    }

    handleAddShareholder() {
        const newShareholder = {
            id: `shareholder_${Date.now()}`,
            type: 'Individual',
            // Role identifiers
            isShareholder: false,
            isDirector: false,
            selectedRoles: [], // Array for checkbox group: ['Shareholder', 'Director']
            // Individual name fields
            salutation: '',
            firstName: '',
            middleName: '',
            lastName: '',
            suffix: '',
            // Corporate name fields
            legalEntityName: '',
            // Keep for backward compatibility
            name: '',
            dateOfBirthOrIncorporation: '',
            countryOfResidenceOrIncorporation: '',
            nationalityOrCountryOfIncorporation: '',
            ownershipPercentage: '',
            governmentIdOrRegistrationNumber: '',
            isPEP: '',
            sourceOfWealth: '',
            sourceOfWealthExplanation: '',
            email: '',
            mobile: '',
            phone: '',
            website: '',
            positionOrRole: '',
            // Address fields
            street: '',
            city: '',
            state: '',
            postalCode: '',
            country: ''
        };
        this.shareholders = [...this.shareholders, newShareholder];
    }

    handleAddAdditionalParty() {
        const newParty = {
            id: `additional_${Date.now()}`,
            role: '',
            type: 'Individual',
            // Individual name fields
            salutation: '',
            firstName: '',
            middleName: '',
            lastName: '',
            suffix: '',
            // Corporate name fields
            legalEntityName: '',
            // Keep for backward compatibility
            name: '',
            ownershipPercentage: '',
            isPEP: '',
            dateOfBirthOrIncorporation: '',
            countryOfResidenceOrIncorporation: '',
            nationalityOrCountryOfIncorporation: '',
            governmentIdOrRegistrationNumber: '',
            positionOrRole: '',
            email: '',
            mobile: '',
            phone: '',
            website: '',
            // Address fields
            street: '',
            city: '',
            state: '',
            postalCode: '',
            country: ''
        };
        this.additionalParties = [...this.additionalParties, newParty];
    }

    handleRemoveAdditionalParty(event) {
        const partyId = event.target.dataset.id;
        this.additionalParties = this.additionalParties.filter(p => p.id !== partyId);
    }

    handleRemoveShareholder(event) {
        const shareholderId = event.target.dataset.id;
        this.shareholders = this.shareholders.filter(s => s.id !== shareholderId);
    }

    handleRemoveAuthorisedUser(event) {
        const userId = event.target.dataset.id;
        this.authorisedUsers = this.authorisedUsers.filter(u => u.id !== userId);
    }

    handleAddAuthorisedUser() {
        const newUser = {
            id: `user_${Date.now()}`,
            selectedShareholderId: '', // Empty = manual entry
            // Split name fields
            salutation: '',
            firstName: '',
            middleName: '',
            lastName: '',
            suffix: '',
            // Keep for backward compatibility
            name: '',
            position: '',
            email: '',
            mobileNumber: '',
            phone: '',
            dateOfBirth: '',
            countryOfResidence: '',
            nationality: '',
            governmentIdNumber: '',
            isPEP: '',
            tradingExperience: [],
            tradeFrequency: '',
            // Address fields
            street: '',
            city: '',
            state: '',
            postalCode: '',
            country: ''
        };
        this.authorisedUsers = [...this.authorisedUsers, newUser];
    }

    /**
     * @description Maps upload field name to document type and level
     * @param {String} fieldName - The name attribute from lightning-file-upload
     * @return {Object} Object with documentType and level
     */
    mapUploadFieldToDocumentType(fieldName) {
        const mapping = {
            // Personal Info documents
            // Note: For Private clients, Apex creates 'Passport' document type, not 'Govt_ID'
            'governmentIdUpload': { documentType: 'Passport', level: 'Application' },
            
            // Address documents
            'proofOfAddressUpload': { documentType: 'Proof_of_Address', level: 'Application' },
            
            // Risk Info documents (Private)
            'sourceOfWealthUpload': { documentType: 'Source_of_Wealth_Evidence', level: 'Application' },
            
            // Business Context documents (Corporate)
            'sourceOfFundsUpload': { documentType: 'Source_of_Wealth_Evidence', level: 'Application' },
            
            // Corporate Documents
            'certificateOfIncorporation': { documentType: 'Certificate_of_Incorporation', level: 'Application' },
            'memorandumArticles': { documentType: 'Memorandum_and_Articles', level: 'Application' },
            'proofOfRegisteredAddress': { documentType: 'Proof_of_Registered_Address', level: 'Application' },
            'authorisedSignatoriesId': { documentType: 'Govt_ID', level: 'Application' },
            'proofOfBeneficialOwnership': { documentType: 'Proof_of_Beneficial_Ownership', level: 'Application' },
            'financialStatements': { documentType: 'Financial_Statements', level: 'Application' },
            'pepEvidence': { documentType: 'Other', level: 'Application' },
            'additionalPartyId': { documentType: 'Govt_ID', level: 'Application' }
        };
        
        return mapping[fieldName] || { documentType: 'Other', level: 'Application' };
    }

    /**
     * @description Handles file upload completion from lightning-file-upload component
     * @param {Object} event - Event from lightning-file-upload with detail.files array
     */
    handleFileUpload(event) {
        const uploadedFiles = event.detail.files;
        const uploadFieldName = event.target.name;
        const dataset = event.target.dataset || {};
        
        if (!uploadFieldName) {
            console.error('File upload field name is missing');
            this.showToast('Error', 'Unable to process file upload. Please try again.', 'error');
            return;
        }

        // Get document type mapping
        const docMapping = this.mapUploadFieldToDocumentType(uploadFieldName);
        
        // Initialize array for this field if it doesn't exist
        if (!this.uploadedFiles[uploadFieldName]) {
            this.uploadedFiles[uploadFieldName] = [];
        }

        // Process each uploaded file
        const processedFiles = [];
        uploadedFiles.forEach(file => {
            if (file.documentId) {
                const fileInfo = {
                    contentDocumentId: file.documentId,
                    fileName: file.name,
                    documentType: docMapping.documentType,
                    level: docMapping.level,
                    relatedPartyId: uploadFieldName === 'additionalPartyId' && dataset.partyId
                        ? `Additional_${dataset.partyId}`
                        : null,
                    uploadFieldName: uploadFieldName // Keep reference for mapping
                };
                
                this.uploadedFiles[uploadFieldName].push(fileInfo);
                processedFiles.push(fileInfo);
            } else {
                console.warn('File uploaded but no documentId:', file);
            }
        });

        if (processedFiles.length > 0) {
            // Update related form data arrays if needed
            this.updateFormDataWithFiles(uploadFieldName, processedFiles);
            
            this.showToast('Success', `${processedFiles.length} file(s) uploaded successfully`, 'success');
        } else {
            this.showToast('Warning', 'Files uploaded but could not be processed. Please try again.', 'warning');
        }
    }

    /**
     * @description Updates form data arrays with uploaded file IDs
     * @param {String} uploadFieldName - The field name from the upload component
     * @param {Array} fileInfos - Array of file info objects
     */
    updateFormDataWithFiles(uploadFieldName, fileInfos) {
        const documentIds = fileInfos.map(file => file.contentDocumentId);
        
        // Map to appropriate form data arrays based on field name
        switch (uploadFieldName) {
            case 'proofOfAddressUpload':
                this.addressInfo.proofOfAddressUpload = [
                    ...(this.addressInfo.proofOfAddressUpload || []),
                    ...documentIds
                ];
                break;
            case 'sourceOfWealthUpload':
                this.riskInfo.sourceOfWealthUpload = [
                    ...(this.riskInfo.sourceOfWealthUpload || []),
                    ...documentIds
                ];
                break;
            case 'sourceOfFundsUpload':
                this.businessContext.sourceOfFundsUpload = [
                    ...(this.businessContext.sourceOfFundsUpload || []),
                    ...documentIds
                ];
                break;
            // Other document types are tracked in uploadedFiles but not in specific arrays
            // They will be included in the fileUploads array in prepareFormData()
        }
    }

    /**
     * @description Handles file upload errors
     * @param {Object} event - Error event from lightning-file-upload
     */
    handleFileUploadError(event) {
        const error = event.detail;
        console.error('File upload error:', error);
        this.showToast('Error', 'File upload failed. Please check file size and format, then try again.', 'error');
    }

    get uploadsDisabled() {
        return !this.recordId;
    }

    /**
     * @description Loads draft company information from Salesforce when navigating to Company Information step
     * Pre-populates companyInfo fields from existing Party__c record
     */
    async loadDraftCompanyInfo() {
        if (!this.recordId) {
            return;
        }

        try {
            const draftDataJson = await getDraftApplicationData({ applicationId: this.recordId });
            
            if (!draftDataJson) {
                return;
            }

            const draftData = JSON.parse(draftDataJson);
            
            // Pre-populate companyInfo if it exists in draft data
            if (draftData.companyInfo) {
                const savedCompanyInfo = draftData.companyInfo;
                
                // Load saved data - prioritize saved data if it exists, but keep user's current input if they've already entered something
                // This ensures we always show what's saved in Salesforce when first navigating to this step
                if (savedCompanyInfo.legalEntityName) {
                    // Only overwrite if field is empty or if saved data differs (to show what's actually saved)
                    if (!this.companyInfo.legalEntityName || this.companyInfo.legalEntityName !== savedCompanyInfo.legalEntityName) {
                        this.companyInfo.legalEntityName = savedCompanyInfo.legalEntityName;
                    }
                }
                if (savedCompanyInfo.tradingName) {
                    if (!this.companyInfo.tradingName || this.companyInfo.tradingName !== savedCompanyInfo.tradingName) {
                        this.companyInfo.tradingName = savedCompanyInfo.tradingName;
                    }
                }
                if (savedCompanyInfo.legalEntityType) {
                    if (!this.companyInfo.legalEntityType || this.companyInfo.legalEntityType !== savedCompanyInfo.legalEntityType) {
                        this.companyInfo.legalEntityType = savedCompanyInfo.legalEntityType;
                    }
                }
                if (savedCompanyInfo.dateOfIncorporation) {
                    if (!this.companyInfo.dateOfIncorporation || this.companyInfo.dateOfIncorporation !== savedCompanyInfo.dateOfIncorporation) {
                        this.companyInfo.dateOfIncorporation = savedCompanyInfo.dateOfIncorporation;
                    }
                }
                if (savedCompanyInfo.countryOfIncorporation) {
                    if (!this.companyInfo.countryOfIncorporation || this.companyInfo.countryOfIncorporation !== savedCompanyInfo.countryOfIncorporation) {
                        this.companyInfo.countryOfIncorporation = savedCompanyInfo.countryOfIncorporation;
                    }
                }
                if (savedCompanyInfo.registrationNumber) {
                    if (!this.companyInfo.registrationNumber || this.companyInfo.registrationNumber !== savedCompanyInfo.registrationNumber) {
                        this.companyInfo.registrationNumber = savedCompanyInfo.registrationNumber;
                    }
                }
                if (savedCompanyInfo.registeredBusinessAddress) {
                    if (!this.companyInfo.registeredBusinessAddress || this.companyInfo.registeredBusinessAddress !== savedCompanyInfo.registeredBusinessAddress) {
                        this.companyInfo.registeredBusinessAddress = savedCompanyInfo.registeredBusinessAddress;
                    }
                }
                if (savedCompanyInfo.principalPlaceOfBusiness) {
                    if (!this.companyInfo.principalPlaceOfBusiness || this.companyInfo.principalPlaceOfBusiness !== savedCompanyInfo.principalPlaceOfBusiness) {
                        this.companyInfo.principalPlaceOfBusiness = savedCompanyInfo.principalPlaceOfBusiness;
                    }
                }
                if (savedCompanyInfo.isRegulatedFinancialInstitution) {
                    if (!this.companyInfo.isRegulatedFinancialInstitution || this.companyInfo.isRegulatedFinancialInstitution !== savedCompanyInfo.isRegulatedFinancialInstitution) {
                        this.companyInfo.isRegulatedFinancialInstitution = savedCompanyInfo.isRegulatedFinancialInstitution;
                    }
                }
                if (savedCompanyInfo.regulatorName) {
                    if (!this.companyInfo.regulatorName || this.companyInfo.regulatorName !== savedCompanyInfo.regulatorName) {
                        this.companyInfo.regulatorName = savedCompanyInfo.regulatorName;
                    }
                }
                if (savedCompanyInfo.regulatoryLicenceNumber) {
                    if (!this.companyInfo.regulatoryLicenceNumber || this.companyInfo.regulatoryLicenceNumber !== savedCompanyInfo.regulatoryLicenceNumber) {
                        this.companyInfo.regulatoryLicenceNumber = savedCompanyInfo.regulatoryLicenceNumber;
                    }
                }
                if (savedCompanyInfo.regulatoryJurisdiction) {
                    if (!this.companyInfo.regulatoryJurisdiction || this.companyInfo.regulatoryJurisdiction !== savedCompanyInfo.regulatoryJurisdiction) {
                        this.companyInfo.regulatoryJurisdiction = savedCompanyInfo.regulatoryJurisdiction;
                    }
                }
                if (savedCompanyInfo.website) {
                    if (!this.companyInfo.website || this.companyInfo.website !== savedCompanyInfo.website) {
                        this.companyInfo.website = savedCompanyInfo.website;
                    }
                }
                if (savedCompanyInfo.email) {
                    if (!this.companyInfo.email || this.companyInfo.email !== savedCompanyInfo.email) {
                        this.companyInfo.email = savedCompanyInfo.email;
                    }
                }
                if (savedCompanyInfo.phone) {
                    if (!this.companyInfo.phone || this.companyInfo.phone !== savedCompanyInfo.phone) {
                        this.companyInfo.phone = savedCompanyInfo.phone;
                    }
                }
                if (savedCompanyInfo.natureOfBusiness) {
                    if (!this.companyInfo.natureOfBusiness || this.companyInfo.natureOfBusiness !== savedCompanyInfo.natureOfBusiness) {
                        this.companyInfo.natureOfBusiness = savedCompanyInfo.natureOfBusiness;
                    }
                }
                if (savedCompanyInfo.restrictedActivities && savedCompanyInfo.restrictedActivities.length > 0) {
                    // Compare arrays - only update if different
                    const currentRestricted = this.companyInfo.restrictedActivities || [];
                    const savedRestricted = savedCompanyInfo.restrictedActivities || [];
                    if (currentRestricted.length === 0 || JSON.stringify(currentRestricted.sort()) !== JSON.stringify(savedRestricted.sort())) {
                        this.companyInfo.restrictedActivities = savedCompanyInfo.restrictedActivities;
                    }
                }
                if (savedCompanyInfo.expectedNumberOfEmployees) {
                    if (!this.companyInfo.expectedNumberOfEmployees || this.companyInfo.expectedNumberOfEmployees !== savedCompanyInfo.expectedNumberOfEmployees) {
                        this.companyInfo.expectedNumberOfEmployees = savedCompanyInfo.expectedNumberOfEmployees;
                    }
                }
                
                console.log('Loaded draft company information:', this.companyInfo);
            }
        } catch (error) {
            console.error('Error loading draft company information:', error);
            // Don't show error toast - this is a background operation and shouldn't interrupt user flow
        }
    }

    async handleContinue() {
        if (this.isSubmitting) {
            return;
        }

        // Special validation for entry step
        if (this.currentStep === 'entry') {
            if (!this.clientType || this.clientType.trim() === '') {
                this.showToast('Error', 'Please select a client type before continuing.', 'error');
                this.scrollToFirstError();
                return;
            }
            if (!this.servicesRequired || !Array.isArray(this.servicesRequired) || this.servicesRequired.length === 0) {
                this.showToast('Error', 'Please select at least one service before continuing.', 'error');
                this.scrollToFirstError();
                return;
            }
            if (!this.recordId) {
                await this.createDraftApp();
            }
            
            console.log('Entry step validated - proceeding:', {
                clientType: this.clientType,
                servicesRequired: this.servicesRequired
            });
        }

        // Get current and next step configuration
        const currentStepConfig = this.getCurrentStepConfig();
        const nextStepConfig = this.getNextStepConfig();

        if (!nextStepConfig) {
            console.warn('Already at last step');
            return;
        }

        // Execute onExit lifecycle hook for current step
        if (currentStepConfig.onExit) {
            await this.executeStepLifecycle(currentStepConfig.onExit);
        }

        // Mark step completion (for private client steps with explicit tracking)
        if (this.stepCompleted.hasOwnProperty(this.currentStep)) {
            this.stepCompleted[this.currentStep] = true;
        }

        // Navigate to next step
        this.currentStep = nextStepConfig.key;

        // Execute onEnter lifecycle hook for next step
        if (nextStepConfig.onEnter) {
            await this.executeStepLifecycle(nextStepConfig.onEnter);
        }

        // Auto-save draft after step change (if not already saved by lifecycle hook)
        if (this.currentStep !== 'entry' && currentStepConfig.onExit !== 'autoSaveAndWait' && currentStepConfig.onExit !== 'autoSave') {
            this.autoSaveDraft('continue');
        }
    }

    async handleBack() {
        if (this.isSubmitting) {
            return;
        }

        // Get previous step configuration
        const previousStepConfig = this.getPreviousStepConfig();

        if (!previousStepConfig) {
            console.warn('Already at first step');
            return;
        }

        // Auto-save current draft before navigating back
        await this.autoSaveDraft('back');

        // Navigate to previous step
        this.currentStep = previousStepConfig.key;
    }

    /**
     * @description Handler for "Start New Application" button
     * Confirms with user before discarding saved progress
     */
    handleStartNewApplication() {
        const confirmed = confirm(
            '⚠️ Are you sure you want to start a new application?\n\n' +
            'This will discard your current progress and cannot be undone.\n\n' +
            'Click OK to start fresh, or Cancel to continue with the current application.'
        );
        
        if (confirmed) {
            console.log('🆕 User confirmed: Starting new application');
            this.startNewApplication();
            // Reload page with ?new=true to ensure clean state
            window.location.href = window.location.pathname + '?new=true';
        } else {
            console.log('❌ User cancelled: Continuing with current application');
        }
    }

    /**
     * @description Automatically saves/updates draft application on step change
     * @param {String} source - 'continue' or 'back'
     */
    async autoSaveDraft(source) {
        try {
            const rawFormData = this.prepareFormData();
            
            // DEBUG: Log what we're sending
            console.log('=== AUTO-SAVE DRAFT DEBUG ===');
            console.log('Source:', source);
            console.log('Shareholders:', rawFormData.shareholders);
            console.log('Shareholders count:', rawFormData.shareholders ? rawFormData.shareholders.length : 0);
            if (rawFormData.shareholders && rawFormData.shareholders.length > 0) {
                rawFormData.shareholders.forEach((sh, idx) => {
                    if (sh.type === 'Individual') {
                        console.log(`  Shareholder ${idx}: id=${sh.id}, type=${sh.type}, firstName=${sh.firstName}, middleName=${sh.middleName}, lastName=${sh.lastName}`);
                    } else if (sh.type === 'Corporate') {
                        console.log(`  Shareholder ${idx}: id=${sh.id}, type=${sh.type}, legalEntityName=${sh.legalEntityName}`);
                    } else {
                        console.log(`  Shareholder ${idx}: id=${sh.id}, type=${sh.type}, name=${sh.name}`);
                    }
                });
            }
            console.log('=== END AUTO-SAVE DEBUG ===');
            
            let formDataJsonString = '';
            try {
                // For draft saves we can serialize the raw form data directly.
                // prepareFormData() already returns a plain JSON-serializable structure.
                formDataJsonString = JSON.stringify(rawFormData);
            } catch (e) {
                console.error('Auto-save: failed to serialize form data:', e);
                return;
            }
            const result = await saveOnboardingApplication({ formDataJson: formDataJsonString });
            
            // DEBUG: Log what Apex returned
            console.log('=== AUTO-SAVE RESULT ===');
            console.log('Success:', result?.isSuccess);
            console.log('ApplicationId:', result?.applicationId);
            console.log('Previous recordId:', this.recordId);
            console.log('Errors:', result?.errors);
            if (result?.debugInfo?.apexReceivedData) {
                console.log('Apex received shareholders:', result.debugInfo.apexReceivedData.shareholdersSize);
                console.log('Apex received shareholders details:', result.debugInfo.apexReceivedData.shareholdersDetails);
            }
            
            if (result && result.isSuccess && result.applicationId) {
                const isNewRecord = !this.recordId; // Track if this is a new record
                this.recordId = result.applicationId;
                
                if (isNewRecord) {
                    console.log('🆕 NEW APPLICATION CREATED:', result.applicationId);
                } else {
                    console.log('✅ EXISTING APPLICATION UPDATED:', result.applicationId);
                }
                
                // Persist recordId to URL and storage for Experience Sites
                this.saveRecordIdToStorage(result.applicationId);
                this.updateUrlWithRecordId(result.applicationId);
                console.log('💾 RecordId saved to storage and URL');
                
                // Generate shareable client links now that we have a recordId
                this.generateClientLinks();
            } else {
                console.warn('❌ Auto-save did not succeed:', result);
            }
            console.log('=== END RESULT ===');
        } catch (e) {
            console.error('Auto-save draft failed from', source, e);
        }
    }

    /**
     * @description Normalizes prepareFormData output into a plain object that matches OnboardingFormDTO
     *              and is safe for JSON serialization / Apex deserialization.
     * @param {Object} rawFormData - Result of prepareFormData()
     * @return {Object} Plain object ready to be serialized and sent to Apex
     */
    serializeFormDataForApex(rawFormData) {
        // Normalize top-level primitives
        const clientTypePlain = String(rawFormData.clientType || '').trim();

        // Always send a plain string array for servicesRequired
        let servicesRequiredPlain = [];
        if (Array.isArray(rawFormData.servicesRequired)) {
            servicesRequiredPlain = rawFormData.servicesRequired
                .map(s => String(s || '').trim())
                .filter(s => s !== '');
        }

        // Declarations are optional for drafts; send an array (can be empty)
        const declarationsPlain = Array.isArray(rawFormData.declarations)
            ? rawFormData.declarations
            : [];

        // Build a plain object matching OnboardingFormDTO structure
        const formData = {
            // Core DTO metadata
            applicationId: rawFormData.applicationId || null,
            currentStep: rawFormData.currentStep || '',
            channel: rawFormData.channel || '',
            clientType: clientTypePlain,
            servicesRequired: servicesRequiredPlain,
            declarations: declarationsPlain,

            // Nested DTOs / aggregates
            personalInfo: rawFormData.personalInfo || null,
            addressInfo: rawFormData.addressInfo || null,
            riskInfo: rawFormData.riskInfo || null,
            companyInfo: rawFormData.companyInfo || null,
            businessContext: rawFormData.businessContext || null,

            // Party collections
            shareholders: Array.isArray(rawFormData.shareholders) && rawFormData.shareholders.length > 0
                ? rawFormData.shareholders.slice()
                : null,
            authorisedUsers: Array.isArray(rawFormData.authorisedUsers) && rawFormData.authorisedUsers.length > 0
                ? rawFormData.authorisedUsers.slice()
                : null,
            additionalParties: Array.isArray(rawFormData.additionalParties) && rawFormData.additionalParties.length > 0
                ? rawFormData.additionalParties.slice()
                : null,

            // Service profiles
            serviceProfiles: Array.isArray(rawFormData.serviceProfiles) && rawFormData.serviceProfiles.length > 0
                ? rawFormData.serviceProfiles.slice()
                : null,

            // Regulatory and files
            regulatoryInfo: rawFormData.regulatoryInfo || null,
            fileUploads: Array.isArray(rawFormData.fileUploads) && rawFormData.fileUploads.length > 0
                ? rawFormData.fileUploads.slice()
                : null,

            // Metadata
            userAgent: String(rawFormData.userAgent || ''),
            ipAddress: String(rawFormData.ipAddress || '')
        };

        return formData;
    }

    // ========== Phone Validation Getters ==========
    
    getPhoneFormat(country) {
        const formats = {
            'US': { code: '+1', example: '+1 (555) 123-4567', pattern: '[\\+]?1?[0-9\\s\\-\\(\\)]{10,15}' },
            'GB': { code: '+44', example: '+44 20 1234 5678', pattern: '[\\+]?44?[0-9\\s\\-]{10,15}' },
            'AE': { code: '+971', example: '+971 50 123 4567', pattern: '[\\+]?971?[0-9\\s\\-]{9,15}' },
            'SG': { code: '+65', example: '+65 9123 4567', pattern: '[\\+]?65?[0-9\\s\\-]{8,12}' },
            'IN': { code: '+91', example: '+91 98765 43210', pattern: '[\\+]?91?[0-9\\s\\-]{10,13}' },
            'AU': { code: '+61', example: '+61 4 1234 5678', pattern: '[\\+]?61?[0-9\\s\\-]{9,15}' },
            'CA': { code: '+1', example: '+1 (555) 123-4567', pattern: '[\\+]?1?[0-9\\s\\-\\(\\)]{10,15}' },
            'DEFAULT': { code: '+', example: '+1234567890', pattern: '[\\+]?[0-9\\s\\-\\(\\)]{10,20}' }
        };
        return formats[country] || formats['DEFAULT'];
    }

    get phoneFormatHint() {
        const country = this.personalInfo?.countryOfResidence || 'DEFAULT';
        const format = this.getPhoneFormat(country);
        return `${format.code} (e.g., ${format.example})`;
    }

    get phonePlaceholder() {
        const country = this.personalInfo?.countryOfResidence || 'DEFAULT';
        return this.getPhoneFormat(country).example;
    }

    get phonePattern() {
        const country = this.personalInfo?.countryOfResidence || 'DEFAULT';
        return this.getPhoneFormat(country).pattern;
    }

    get phonePatternError() {
        const country = this.personalInfo?.countryOfResidence || 'DEFAULT';
        const format = this.getPhoneFormat(country);
        return `Please enter a valid phone number with country code (e.g., ${format.example})`;
    }

    get corporatePhoneFormatHint() {
        const country = this.companyInfo?.countryOfIncorporation || 'DEFAULT';
        const format = this.getPhoneFormat(country);
        return `${format.code} (e.g., ${format.example})`;
    }

    get corporatePhonePlaceholder() {
        const country = this.companyInfo?.countryOfIncorporation || 'DEFAULT';
        return this.getPhoneFormat(country).example;
    }

    get corporatePhonePattern() {
        const country = this.companyInfo?.countryOfIncorporation || 'DEFAULT';
        return this.getPhoneFormat(country).pattern;
    }

    get corporatePhonePatternError() {
        const country = this.companyInfo?.countryOfIncorporation || 'DEFAULT';
        const format = this.getPhoneFormat(country);
        return `Please enter a valid phone number with country code (e.g., ${format.example})`;
    }

    /**
     * @description Helper method to safely get value from object property
     * Handles null, undefined, and empty string values
     * @param {Object} obj - Object to get value from
     * @param {String} prop - Property name
     * @param {*} defaultValue - Default value if property is null/undefined/empty
     * @return {*} Property value or default value
     */
    safeGet(obj, prop, defaultValue = '') {
        if (!obj || obj === null || obj === undefined) {
            return defaultValue;
        }
        const value = obj[prop];
        if (value === null || value === undefined || value === '') {
            return defaultValue;
        }
        return value;
    }

    /**
     * @description Helper method to safely get array value from object property
     * @param {Object} obj - Object to get value from
     * @param {String} prop - Property name
     * @return {Array} Property value as array or empty array
     */
    safeGetArray(obj, prop) {
        const value = this.safeGet(obj, prop, []);
        return Array.isArray(value) ? value : [];
    }

    /**
     * @description Formats date string to YYYY-MM-DD format for Apex
     * lightning-input-date already provides dates in this format, but this ensures consistency
     * @param {String} dateStr - Date string from input
     * @return {String} Formatted date string or empty string
     */
    formatDateForApex(dateStr) {
        if (!dateStr || dateStr === '') {
            return '';
        }
        // lightning-input-date already provides YYYY-MM-DD format
        // Just ensure it's a valid format
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (dateRegex.test(dateStr)) {
            return dateStr;
        }
        // If date is in different format, try to convert
        try {
            const date = new Date(dateStr);
            if (!isNaN(date.getTime())) {
                const year = date.getFullYear();
                const month = String(date.getMonth() + 1).padStart(2, '0');
                const day = String(date.getDate()).padStart(2, '0');
                return `${year}-${month}-${day}`;
            }
        } catch (e) {
            console.warn('Date formatting error:', e);
        }
        return '';
    }

    /**
     * @description Captures client metadata (IP address and user agent)
     * @return Object with ipAddress and userAgent
     */
    captureMetadata() {
        const metadata = {
            ipAddress: '',
            userAgent: navigator.userAgent || ''
        };

        // Note: IP address cannot be directly captured from browser for security reasons
        // In a real implementation, you might need to use a third-party service
        // or capture it server-side. For now, we'll leave it empty and let Apex handle it.
        // The Apex method has a fallback to capture IP from request headers.

        return metadata;
    }

    /**
     * @description Prepares form data to match OnboardingFormDTO structure
     * @return Object matching OnboardingFormDTO structure
     */
    prepareFormData() {
        const metadata = this.captureMetadata();
        
        // Prepare service profiles array from serviceSpecific object
        const serviceProfiles = [];
        if (this.servicesRequired && this.servicesRequired.length > 0) {
            this.servicesRequired.forEach(serviceType => {
                const serviceProfile = {
                    serviceType: serviceType
                };

                if (serviceType === 'FX') {
                    // FX-specific fields
                    // Note: For Corporate, currency/country selection is in businessContext
                    // For Private, currency/country selection is in serviceSpecific
                    console.log('=== FX SERVICE PROFILE PREPARATION ===');
                    console.log('fxForwardContractsRequired:', this.safeGet(this.serviceSpecific, 'fxForwardContractsRequired'));
                    console.log('fxHedgingNeeds:', this.safeGet(this.serviceSpecific, 'fxHedgingNeeds'));
                    console.log('currenciesToSend:', this.safeGetArray(this.serviceSpecific, 'currenciesToSend'));
                    console.log('currenciesToReceive:', this.safeGetArray(this.serviceSpecific, 'currenciesToReceive'));
                    console.log('countriesFundsSentTo:', this.safeGetArray(this.serviceSpecific, 'countriesFundsSentTo'));
                    console.log('countriesFundsReceivedFrom:', this.safeGetArray(this.serviceSpecific, 'countriesFundsReceivedFrom'));
                    
                    serviceProfile.currenciesToSend = this.safeGetArray(this.serviceSpecific, 'currenciesToSend');
                    serviceProfile.currenciesToReceive = this.safeGetArray(this.serviceSpecific, 'currenciesToReceive');
                    serviceProfile.countriesFundsSentTo = this.safeGetArray(this.serviceSpecific, 'countriesFundsSentTo');
                    serviceProfile.countriesFundsReceivedFrom = this.safeGetArray(this.serviceSpecific, 'countriesFundsReceivedFrom');
                    serviceProfile.fxForwardContractsRequired = this.safeGet(this.serviceSpecific, 'fxForwardContractsRequired');
                    serviceProfile.fxHedgingNeeds = this.safeGet(this.serviceSpecific, 'fxHedgingNeeds');
                    console.log('=== END FX SERVICE PROFILE PREPARATION ===');
                } else if (serviceType === 'Crypto') {
                    // Debug logging for Crypto fields
                    console.log('=== CRYPTO SERVICE PROFILE PREPARATION ===');
                    console.log('digitalAssets:', this.safeGetArray(this.serviceSpecific, 'digitalAssets'));
                    console.log('expectedMonthlyCryptoVolume:', this.safeGet(this.serviceSpecific, 'expectedMonthlyCryptoVolume'));
                    console.log('averageCryptoTransactionSize:', this.safeGet(this.serviceSpecific, 'averageCryptoTransactionSize'));
                    // isVASP removed - regulatory status captured in Company Info step
                    console.log('serviceSpecific object:', JSON.parse(JSON.stringify(this.serviceSpecific)));
                    
                    serviceProfile.digitalAssets = this.safeGetArray(this.serviceSpecific, 'digitalAssets');
                    serviceProfile.expectedMonthlyCryptoVolume = this.safeGet(this.serviceSpecific, 'expectedMonthlyCryptoVolume');
                    serviceProfile.averageCryptoTransactionSize = this.safeGet(this.serviceSpecific, 'averageCryptoTransactionSize');
                    // serviceProfile.isVASP removed - regulatory status captured in Company Info step
                    console.log('=== END CRYPTO SERVICE PROFILE PREPARATION ===');
                } else if (serviceType === 'Advisory') {
                    // Debug logging for Advisory fields
                    console.log('=== ADVISORY SERVICE PROFILE PREPARATION ===');
                    console.log('advisoryServicesRequired:', this.safeGetArray(this.serviceSpecific, 'advisoryServicesRequired'));
                    console.log('investmentObjectives:', this.safeGetArray(this.serviceSpecific, 'investmentObjectives'));
                    console.log('riskAppetite:', this.safeGet(this.serviceSpecific, 'riskAppetite'));
                    console.log('timeHorizon:', this.safeGet(this.serviceSpecific, 'timeHorizon'));
                    console.log('existingAdvisoryRelationships:', this.safeGet(this.serviceSpecific, 'existingAdvisoryRelationships'));
                    console.log('serviceSpecific object:', JSON.parse(JSON.stringify(this.serviceSpecific)));
                    
                    serviceProfile.advisoryServicesRequired = this.safeGetArray(this.serviceSpecific, 'advisoryServicesRequired');
                    serviceProfile.investmentObjectives = this.safeGetArray(this.serviceSpecific, 'investmentObjectives');
                    serviceProfile.riskAppetite = this.safeGet(this.serviceSpecific, 'riskAppetite');
                    serviceProfile.timeHorizon = this.safeGet(this.serviceSpecific, 'timeHorizon');
                    serviceProfile.existingAdvisoryRelationships = this.safeGet(this.serviceSpecific, 'existingAdvisoryRelationships');
                    console.log('=== END ADVISORY SERVICE PROFILE PREPARATION ===');
                }

                serviceProfiles.push(serviceProfile);
            });
        }
        
        // Debug log ALL service profiles being sent
        console.log('📦 === TOTAL SERVICE PROFILES PREPARED ===');
        console.log('Number of service profiles:', serviceProfiles.length);
        
        // Critical: Log the ACTUAL JSON being sent (not Proxy)
        try {
            const serializedProfiles = JSON.parse(JSON.stringify(serviceProfiles));
            console.log('✅ Service profiles (JSON serialized):', serializedProfiles);
            console.log('✅ Service profiles (RAW JSON string):', JSON.stringify(serializedProfiles));
        } catch (e) {
            console.error('❌ Failed to serialize service profiles:', e);
        }
        
        console.log('📦 === END SERVICE PROFILES ===');

        // Prepare declarations array
        const declarations = [];
        // Ensure we check the actual value, not just truthy - handle both boolean and string
        const agreeToTermsValue = this.declarations ? this.declarations.agreeToTerms : false;
        const agreeToTerms = agreeToTermsValue === true || agreeToTermsValue === 'true';
        
        if (agreeToTerms) {
            // Create declaration records for all required types
            const requiredDeclarations = [
                'Terms_of_Business',
                'Risk_Disclosure',
                'AML_Consent',
                'Accuracy_Declaration'
            ];

            const signatoryFirstName = this.safeGet(this.declarations, 'signatoryFirstName');
            const signatoryLastName = this.safeGet(this.declarations, 'signatoryLastName');
            const signatureName = `${signatoryFirstName} ${signatoryLastName}`.trim();
            const clientNotes = this.safeGet(this.declarations, 'clientNotes');
            
            requiredDeclarations.forEach(declType => {
                declarations.push({
                    declarationType: declType,
                    accepted: true,
                    signatoryFirstName: signatoryFirstName,
                    signatoryLastName: signatoryLastName,
                    signatureName: signatureName,
                    clientNotes: clientNotes
                });
            });
        }
        
        // Debug logging for declarations (extract actual values)
        const declarationsDebug = {
            hasDeclarations: !!this.declarations,
            agreeToTermsValue: agreeToTermsValue,
            agreeToTerms: agreeToTerms,
            declarationsLength: declarations.length,
            signatoryFirstName: this.declarations ? String(this.declarations.signatoryFirstName || '') : '',
            signatoryLastName: this.declarations ? String(this.declarations.signatoryLastName || '') : ''
        };
        console.log('prepareFormData - Declarations:', JSON.parse(JSON.stringify(declarationsDebug)));

        // Prepare file uploads from uploadedFiles tracking object
        const fileUploads = [];
        if (this.uploadedFiles && Object.keys(this.uploadedFiles).length > 0) {
            // Iterate through all uploaded file groups
            Object.keys(this.uploadedFiles).forEach(fieldName => {
                const files = this.uploadedFiles[fieldName];
                if (Array.isArray(files) && files.length > 0) {
                    files.forEach(fileInfo => {
                        // Create FileUploadDTO object
                        const fileUpload = {
                            contentDocumentId: fileInfo.contentDocumentId,
                            fileName: fileInfo.fileName,
                            documentType: fileInfo.documentType,
                            level: fileInfo.level,
                            relatedPartyId: fileInfo.relatedPartyId || null
                        };
                        fileUploads.push(fileUpload);
                    });
                }
            });
        }

        // Build the form data object matching OnboardingFormDTO structure
        // Ensure clientType and servicesRequired are properly captured
        // Use the actual tracked properties directly - force read from reactive properties
        const rawClientType = this.clientType;
        const rawServicesRequired = this.servicesRequired;
        
        // Convert to plain values to avoid Proxy issues
        const clientTypeValue = (rawClientType && typeof rawClientType === 'string' && rawClientType.trim() !== '') 
            ? String(rawClientType).trim() 
            : '';
        
        // Ensure servicesRequired is always an array
        let servicesRequiredValue = [];
        if (rawServicesRequired) {
            if (Array.isArray(rawServicesRequired)) {
                // Create a new array to break Proxy reference
                servicesRequiredValue = rawServicesRequired.slice().filter(s => {
                    const str = String(s || '');
                    return str.trim() !== '';
                });
            } else if (typeof rawServicesRequired === 'string') {
                servicesRequiredValue = [String(rawServicesRequired)];
            } else {
                // Try to convert to array
                try {
                    servicesRequiredValue = Array.from(rawServicesRequired).filter(s => {
                        const str = String(s || '');
                        return str.trim() !== '';
                    });
                } catch (e) {
                    servicesRequiredValue = [];
                }
            }
        }
        
        // Debug logging (using JSON.stringify to handle Proxy objects)
        try {
            const debugInfo = {
                clientType: String(this.clientType || ''),
                clientTypeType: typeof this.clientType,
                clientTypeValue: clientTypeValue,
                servicesRequired: Array.isArray(this.servicesRequired) ? [...this.servicesRequired] : String(this.servicesRequired || ''),
                servicesRequiredType: typeof this.servicesRequired,
                servicesRequiredIsArray: Array.isArray(this.servicesRequired),
                servicesRequiredValue: servicesRequiredValue,
                declarationsAgreeToTerms: this.declarations ? Boolean(this.declarations.agreeToTerms) : false,
                declarationsSignatoryFirstName: this.declarations ? String(this.declarations.signatoryFirstName || '') : '',
                declarationsSignatoryLastName: this.declarations ? String(this.declarations.signatoryLastName || '') : ''
            };
            console.log('prepareFormData - Raw values:', JSON.parse(JSON.stringify(debugInfo)));
        } catch (e) {
            console.log('prepareFormData - Raw values (fallback):', {
                clientType: String(this.clientType || ''),
                servicesRequiredLength: this.servicesRequired ? String(this.servicesRequired.length) : '0'
            });
        }
        
        const formData = {
            applicationId: this.recordId || null,
            currentStep: this.currentStep,
            channel: this.channel,
            clientType: clientTypeValue,
            servicesRequired: servicesRequiredValue,
            personalInfo: this.clientType === 'Private' ? {
                salutation: this.safeGet(this.personalInfo, 'salutation'),
                firstName: this.safeGet(this.personalInfo, 'firstName'),
                middleName: this.safeGet(this.personalInfo, 'middleName'),
                lastName: this.safeGet(this.personalInfo, 'lastName'),
                suffix: this.safeGet(this.personalInfo, 'suffix'),
                dateOfBirth: this.formatDateForApex(this.safeGet(this.personalInfo, 'dateOfBirth')),
                nationality: this.safeGet(this.personalInfo, 'nationality'),
                countryOfResidence: this.safeGet(this.personalInfo, 'countryOfResidence'),
                governmentIdNumber: this.safeGet(this.personalInfo, 'governmentIdNumber'),
                email: this.safeGet(this.personalInfo, 'email'),
                mobile: this.safeGet(this.personalInfo, 'mobile'),
                phone: this.safeGet(this.personalInfo, 'phone'),
                website: this.safeGet(this.personalInfo, 'website'),
                isPEP: this.safeGet(this.personalInfo, 'isPEP', 'No')
            } : null,
            addressInfo: {
                street: this.safeGet(this.addressInfo, 'street'),
                city: this.safeGet(this.addressInfo, 'city'),
                state: this.safeGet(this.addressInfo, 'state'),
                postalCode: this.safeGet(this.addressInfo, 'postalCode'),
                country: this.safeGet(this.addressInfo, 'country'),
                addressType: this.safeGet(this.addressInfo, 'addressType')
            },
            riskInfo: this.clientType === 'Private' ? {
                expectedMonthlyVolume: this.safeGet(this.riskInfo, 'expectedMonthlyVolume'),
                estimatedTransactionsPerMonth: this.safeGet(this.riskInfo, 'estimatedTransactionsPerMonth'),
                sourceOfWealth: this.safeGet(this.riskInfo, 'sourceOfWealth'),
                sourceOfWealthExplanation: this.safeGet(this.riskInfo, 'sourceOfWealthExplanation'),
                geographicExposure: this.safeGetArray(this.riskInfo, 'geographicExposure'),
                intendedUseOfAccount: this.safeGet(this.riskInfo, 'intendedUseOfAccount')
            } : null,
            companyInfo: this.clientType === 'Corporate' ? {
                legalEntityName: this.safeGet(this.companyInfo, 'legalEntityName'),
                tradingName: this.safeGet(this.companyInfo, 'tradingName'),
                legalEntityType: this.safeGet(this.companyInfo, 'legalEntityType'),
                dateOfIncorporation: this.formatDateForApex(this.safeGet(this.companyInfo, 'dateOfIncorporation')),
                countryOfIncorporation: this.safeGet(this.companyInfo, 'countryOfIncorporation'),
                registrationNumber: this.safeGet(this.companyInfo, 'registrationNumber'),
                // Registered Business Address (structured fields)
                registeredStreet: this.safeGet(this.companyInfo, 'registeredStreet'),
                registeredCity: this.safeGet(this.companyInfo, 'registeredCity'),
                registeredState: this.safeGet(this.companyInfo, 'registeredState'),
                registeredPostalCode: this.safeGet(this.companyInfo, 'registeredPostalCode'),
                registeredCountry: this.safeGet(this.companyInfo, 'registeredCountry'),
                isRegulatedFinancialInstitution: this.safeGet(this.companyInfo, 'isRegulatedFinancialInstitution'),
                regulatorName: this.safeGet(this.companyInfo, 'regulatorName'),
                regulatoryLicenceNumber: this.safeGet(this.companyInfo, 'regulatoryLicenceNumber'),
                regulatoryJurisdiction: this.safeGet(this.companyInfo, 'regulatoryJurisdiction'),
                website: this.safeGet(this.companyInfo, 'website'),
                email: this.safeGet(this.companyInfo, 'email'),
                phone: this.safeGet(this.companyInfo, 'phone'),
                natureOfBusiness: this.safeGet(this.companyInfo, 'natureOfBusiness'),
                restrictedActivities: this.safeGetArray(this.companyInfo, 'restrictedActivities'),
                expectedNumberOfEmployees: this.safeGet(this.companyInfo, 'expectedNumberOfEmployees')
            } : null,
            businessContext: this.clientType === 'Corporate' ? {
                purposeOfAccount: this.safeGet(this.businessContext, 'purposeOfAccount'),
                industry: this.safeGet(this.businessContext, 'industry'),
                productsAndServices: this.safeGet(this.businessContext, 'productsAndServices'),
                paymentFlowTypes: this.safeGetArray(this.businessContext, 'paymentFlowTypes'),
                expectedTransactionsPerMonth: this.safeGet(this.businessContext, 'expectedTransactionsPerMonth'),
                expectedAnnualVolume: this.safeGet(this.businessContext, 'expectedAnnualVolume'),
                typicalValuePerTransaction: this.safeGet(this.businessContext, 'typicalValuePerTransaction'),
                currenciesToSend: this.safeGetArray(this.businessContext, 'currenciesToSend'),
                currenciesToReceive: this.safeGetArray(this.businessContext, 'currenciesToReceive'),
                countriesFundsSentTo: this.safeGetArray(this.businessContext, 'countriesFundsSentTo'),
                countriesFundsReceivedFrom: this.safeGetArray(this.businessContext, 'countriesFundsReceivedFrom'),
                largestSingleTransaction: this.safeGet(this.businessContext, 'largestSingleTransaction'),
                highRiskJurisdictionExposure: this.safeGet(this.businessContext, 'highRiskJurisdictionExposure', 'No'),
                highRiskJurisdictionDetails: this.safeGet(this.businessContext, 'highRiskJurisdictionDetails'),
                anticipatedSanctionedCounterparties: this.safeGet(this.businessContext, 'anticipatedSanctionedCounterparties', 'No'),
                primarySourceOfFunds: this.safeGet(this.businessContext, 'primarySourceOfFunds'),
                // sourceOfWealthForBusinessOwners removed - captured in Explanation field
                sourceOfWealthExplanation: this.safeGet(this.businessContext, 'sourceOfWealthExplanation'),
                sourceOfFundsUpload: this.safeGetArray(this.businessContext, 'sourceOfFundsUpload')
            } : null,
            shareholders: Array.isArray(this.shareholders) ? this.shareholders.map(sh => ({
                id: this.safeGet(sh, 'id'),
                type: this.safeGet(sh, 'type'),
                // Role boolean fields - CRITICAL for backend
                isShareholder: this.safeGet(sh, 'isShareholder', false),
                isDirector: this.safeGet(sh, 'isDirector', false),
                // Split name fields for individuals
                salutation: this.safeGet(sh, 'salutation'),
                firstName: this.safeGet(sh, 'firstName'),
                middleName: this.safeGet(sh, 'middleName'),
                lastName: this.safeGet(sh, 'lastName'),
                suffix: this.safeGet(sh, 'suffix'),
                // Legal entity name for corporates
                legalEntityName: this.safeGet(sh, 'legalEntityName'),
                // Keep old name field for backward compatibility
                name: this.safeGet(sh, 'name'),
                dateOfBirthOrIncorporation: this.formatDateForApex(this.safeGet(sh, 'dateOfBirthOrIncorporation')),
                countryOfResidenceOrIncorporation: this.safeGet(sh, 'countryOfResidenceOrIncorporation'),
                nationalityOrCountryOfIncorporation: this.safeGet(sh, 'nationalityOrCountryOfIncorporation'),
                ownershipPercentage: this.safeGet(sh, 'ownershipPercentage'),
                governmentIdOrRegistrationNumber: this.safeGet(sh, 'governmentIdOrRegistrationNumber'),
                isPEP: this.safeGet(sh, 'isPEP', 'No'),
                phone: this.safeGet(sh, 'phone'),
                website: this.safeGet(sh, 'website'),
                positionOrRole: this.safeGet(sh, 'positionOrRole'),
                sourceOfWealth: this.safeGet(sh, 'sourceOfWealth'),
                sourceOfWealthExplanation: this.safeGet(sh, 'sourceOfWealthExplanation'),
                email: this.safeGet(sh, 'email'),
                mobile: this.safeGet(sh, 'mobile'),
                // Address fields
                street: this.safeGet(sh, 'street'),
                city: this.safeGet(sh, 'city'),
                state: this.safeGet(sh, 'state'),
                postalCode: this.safeGet(sh, 'postalCode'),
                country: this.safeGet(sh, 'country')
            })) : [],
            authorisedUsers: Array.isArray(this.authorisedUsers) ? this.authorisedUsers.map(user => ({
                id: this.safeGet(user, 'id'),
                selectedShareholderId: this.safeGet(user, 'selectedShareholderId'),
                // Split name fields
                salutation: this.safeGet(user, 'salutation'),  // ADD
                firstName: this.safeGet(user, 'firstName'),
                middleName: this.safeGet(user, 'middleName'),
                lastName: this.safeGet(user, 'lastName'),
                suffix: this.safeGet(user, 'suffix'),  // ADD
                // Keep old name field for backward compatibility
                name: this.safeGet(user, 'name'),
                position: this.safeGet(user, 'position'),
                email: this.safeGet(user, 'email'),
                mobileNumber: this.safeGet(user, 'mobileNumber'),
                phone: this.safeGet(user, 'phone'),
                dateOfBirth: this.formatDateForApex(this.safeGet(user, 'dateOfBirth')),
                countryOfResidence: this.safeGet(user, 'countryOfResidence'),
                nationality: this.safeGet(user, 'nationality'),
                governmentIdNumber: this.safeGet(user, 'governmentIdNumber'),
                isPEP: this.safeGet(user, 'isPEP', 'No'),
                tradingExperience: this.safeGetArray(user, 'tradingExperience'),
                tradeFrequency: this.safeGet(user, 'tradeFrequency'),
                // Address fields
                street: this.safeGet(user, 'street'),
                city: this.safeGet(user, 'city'),
                state: this.safeGet(user, 'state'),
                postalCode: this.safeGet(user, 'postalCode'),
                country: this.safeGet(user, 'country')
            })) : [],
            additionalParties: Array.isArray(this.additionalParties) ? this.additionalParties.map(party => ({
                id: this.safeGet(party, 'id'),
                role: this.safeGet(party, 'role'),
                type: this.safeGet(party, 'type'),
                // Split name fields for individuals
                salutation: this.safeGet(party, 'salutation'),  // ADD
                firstName: this.safeGet(party, 'firstName'),
                middleName: this.safeGet(party, 'middleName'),
                lastName: this.safeGet(party, 'lastName'),
                suffix: this.safeGet(party, 'suffix'),  // ADD
                // Legal entity name for corporates
                legalEntityName: this.safeGet(party, 'legalEntityName'),
                // Keep old name field for backward compatibility
                name: this.safeGet(party, 'name'),
                dateOfBirthOrIncorporation: this.formatDateForApex(this.safeGet(party, 'dateOfBirthOrIncorporation')),
                countryOfResidenceOrIncorporation: this.safeGet(party, 'countryOfResidenceOrIncorporation'),
                nationalityOrCountryOfIncorporation: this.safeGet(party, 'nationalityOrCountryOfIncorporation'),
                ownershipPercentage: this.safeGet(party, 'ownershipPercentage'),
                governmentIdOrRegistrationNumber: this.safeGet(party, 'governmentIdOrRegistrationNumber'),
                isPEP: this.safeGet(party, 'isPEP', 'No'),
                positionOrRole: this.safeGet(party, 'positionOrRole'),
                email: this.safeGet(party, 'email'),
                mobile: this.safeGet(party, 'mobile'),
                phone: this.safeGet(party, 'phone'),
                website: this.safeGet(party, 'website'),
                // Address fields
                street: this.safeGet(party, 'street'),
                city: this.safeGet(party, 'city'),
                state: this.safeGet(party, 'state'),
                postalCode: this.safeGet(party, 'postalCode'),
                country: this.safeGet(party, 'country')
            })) : [],
            serviceProfiles: serviceProfiles,
            regulatoryInfo: this.clientType === 'Corporate' ? {
                additionalUBOs: this.safeGet(this.regulatoryInfo, 'additionalUBOs', 'No'),
                onSanctionsList: this.safeGet(this.regulatoryInfo, 'onSanctionsList', 'No'),
                financialCrimeConviction: this.safeGet(this.regulatoryInfo, 'financialCrimeConviction', 'No'),
                pepInOrganization: this.safeGet(this.regulatoryInfo, 'pepInOrganization', 'No'),
                providesMoneyServices: this.safeGet(this.regulatoryInfo, 'providesMoneyServices', 'No'),
                additionalComplianceNotes: this.safeGet(this.regulatoryInfo, 'additionalComplianceNotes')
            } : null,
            declarations: declarations,
            fileUploads: fileUploads,
            userAgent: metadata.userAgent,
            ipAddress: metadata.ipAddress
        };

        // Critical: Log the ACTUAL serviceProfiles data being sent to Apex
        console.log('🔍 === FINAL FORM DATA BEFORE APEX ===');
        console.log('serviceProfiles count:', formData.serviceProfiles ? formData.serviceProfiles.length : 0);
        if (formData.serviceProfiles && formData.serviceProfiles.length > 0) {
            console.log('serviceProfiles (RAW JSON):', JSON.stringify(formData.serviceProfiles));
            formData.serviceProfiles.forEach((sp, idx) => {
                console.log(`  Profile ${idx}: serviceType=${sp.serviceType}`);
                console.log(`    Full data:`, JSON.stringify(sp));
            });
        }
        console.log('🔍 === END FINAL FORM DATA ===');

        return formData;
    }

    async createDraftApp() {
        try {
            const metadata = this.captureMetadata();
            const draftId = await createDraftApplication({
                clientType: this.clientType,
                servicesRequired: this.servicesRequired,
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                channel: this.channel,
                currentStep: this.currentStep
            });
            this.recordId = draftId;
        } catch (error) {
            console.error('Error creating draft application:', error);
            this.showToast('Error', 'Unable to create draft application for file uploads.', 'error');
        }
    }

    /**
     * @description Parses Apex error and returns user-friendly message
     * @param {Object} error - Error object from Apex call
     * @return {String} User-friendly error message
     */
    parseApexError(error) {
        let errorMessage = 'An error occurred while submitting your application.';
        
        if (!error) {
            return errorMessage;
        }

        // Handle AuraHandledException (thrown by Apex)
        if (error.body) {
            if (error.body.message) {
                errorMessage = error.body.message;
            } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                errorMessage = error.body.pageErrors[0].message;
            } else if (error.body.fieldErrors) {
                // Handle field-level errors
                const fieldErrors = [];
                Object.keys(error.body.fieldErrors).forEach(field => {
                    const fieldError = error.body.fieldErrors[field];
                    if (fieldError && fieldError.length > 0) {
                        fieldErrors.push(fieldError[0].message);
                    }
                });
                if (fieldErrors.length > 0) {
                    errorMessage = fieldErrors.join(' ');
                }
            } else if (error.body.output && error.body.output.errors && error.body.output.errors.length > 0) {
                errorMessage = error.body.output.errors[0].message;
            }
        } else if (error.message) {
            // Handle standard JavaScript errors
            errorMessage = error.message;
        } else if (typeof error === 'string') {
            // Handle string errors
            errorMessage = error;
        }

        // Clean up technical error messages for user display
        errorMessage = this.sanitizeErrorMessage(errorMessage);

        return errorMessage;
    }

    /**
     * @description Sanitizes error messages to be more user-friendly
     * @param {String} errorMessage - Raw error message
     * @return {String} Sanitized error message
     */
    sanitizeErrorMessage(errorMessage) {
        if (!errorMessage) {
            return 'An error occurred while submitting your application.';
        }

        // Remove technical details that users don't need to see
        let sanitized = errorMessage
            .replace(/\[.*?\]/g, '') // Remove brackets and content
            .replace(/\(.*?\)/g, '') // Remove parentheses and content
            .replace(/Line \d+:/gi, '') // Remove line numbers
            .replace(/Column \d+:/gi, '') // Remove column numbers
            .trim();

        // If message is too technical, provide generic message
        if (sanitized.includes('Exception') || sanitized.includes('Error:') || sanitized.includes('FATAL_ERROR')) {
            return 'An unexpected error occurred. Please check your input and try again, or contact support if the problem persists.';
        }

        // Capitalize first letter if needed
        if (sanitized.length > 0 && sanitized[0] === sanitized[0].toLowerCase()) {
            sanitized = sanitized.charAt(0).toUpperCase() + sanitized.slice(1);
        }

        return sanitized || 'An error occurred while submitting your application.';
    }

    /**
     * @description Safely serializes an object to avoid circular references
     * @param {Object} obj - Object to serialize
     * @param {Number} depth - Maximum depth to serialize
     * @return {Object} Serialized object
     */
    safeSerialize(obj, depth = 3) {
        if (depth === 0) {
            return '[Max Depth Reached]';
        }
        
        if (obj === null || obj === undefined) {
            return obj;
        }
        
        if (typeof obj === 'string' || typeof obj === 'number' || typeof obj === 'boolean') {
            return obj;
        }
        
        if (Array.isArray(obj)) {
            return obj.map(item => this.safeSerialize(item, depth - 1));
        }
        
        if (obj instanceof Error) {
            return {
                name: obj.name,
                message: obj.message,
                stack: obj.stack
            };
        }
        
        try {
            const serialized = {};
            for (const key in obj) {
                if (obj.hasOwnProperty(key)) {
                    try {
                        const value = obj[key];
                        // Skip functions and circular references
                        if (typeof value !== 'function') {
                            serialized[key] = this.safeSerialize(value, depth - 1);
                        }
                    } catch (e) {
                        serialized[key] = '[Unable to serialize]';
                    }
                }
            }
            return serialized;
        } catch (e) {
            return '[Serialization Error]';
        }
    }

    /**
     * @description Logs error details for debugging
     * @param {Object} error - Error object
     * @param {String} context - Context where error occurred
     */
    logError(error, context = 'Form Submission') {
        try {
            // Safely extract error information
            let errorMessage = 'Unknown error';
            let errorType = 'UnknownError';
            let stackTrace = 'No stack trace available';
            let errorBody = null;
            
            if (error) {
                // Handle Apex errors
                if (error.body) {
                    errorType = 'ApexError';
                    errorBody = this.safeSerialize(error.body);
                    errorMessage = error.body.message || error.body.error || String(error);
                } else if (error.message) {
                    errorType = 'JavaScriptError';
                    errorMessage = error.message;
                    stackTrace = error.stack || stackTrace;
                } else if (typeof error === 'string') {
                    errorMessage = error;
                } else if (error.errors && Array.isArray(error.errors)) {
                    errorMessage = error.errors.join('. ');
                } else {
                    errorMessage = String(error);
                }
            }
            
            const errorDetails = {
                context: context,
                timestamp: new Date().toISOString(),
                errorType: errorType,
                errorMessage: errorMessage,
                stackTrace: stackTrace,
                errorBody: errorBody,
                formData: {
                    clientType: String(this.clientType || ''),
                    servicesRequired: Array.isArray(this.servicesRequired) ? [...this.servicesRequired] : String(this.servicesRequired || ''),
                    currentStep: String(this.currentStep || '')
                }
            };

            // Log safely without circular references (using JSON.stringify to handle Proxy objects)
            try {
                console.error(`[${context}] Error Details:`, JSON.parse(JSON.stringify(errorDetails)));
            } catch (e) {
                console.error(`[${context}] Error Details (fallback):`, {
                    context: context,
                    errorType: errorType,
                    errorMessage: errorMessage
                });
            }
            
            // In production, you might want to send this to a logging service
            // Example: sendErrorToLoggingService(errorDetails);
        } catch (logError) {
            // Fallback if logging itself fails
            console.error(`[${context}] Error occurred but could not be logged:`, logError);
        }
    }

    getSubmissionValidationErrors() {
        const errors = [];
        const isBlank = value => !value || String(value).trim() === '';
        const isEmptyArray = value => !Array.isArray(value) || value.length === 0;

        if (this.isPrivateClient) {
            const pi = this.personalInfo || {};
            const ai = this.addressInfo || {};
            const ri = this.riskInfo || {};

            if (isBlank(pi.salutation)) errors.push('Salutation is required.');
            if (isBlank(pi.firstName)) errors.push('First name is required.');
            if (isBlank(pi.lastName)) errors.push('Last name is required.');
            if (isBlank(pi.dateOfBirth)) errors.push('Date of birth is required.');
            if (isBlank(pi.nationality)) errors.push('Nationality is required.');
            if (isBlank(pi.countryOfResidence)) errors.push('Country of residence is required.');
            if (isBlank(pi.governmentIdNumber)) errors.push('Government ID number is required.');
            if (isBlank(pi.email)) errors.push('Email is required.');
            if (isBlank(pi.isPEP)) errors.push('PEP response is required.');

            if (isBlank(ai.street)) errors.push('Address street is required.');
            if (isBlank(ai.city)) errors.push('Address city is required.');
            if (isBlank(ai.state)) errors.push('Address state/province is required.');
            if (isBlank(ai.postalCode)) errors.push('Address postal code is required.');
            if (isBlank(ai.country)) errors.push('Address country is required.');

            if (isBlank(ri.sourceOfWealth)) errors.push('Source of wealth is required.');
            if (isBlank(ri.sourceOfWealthExplanation)) errors.push('Source of wealth explanation is required.');
            if (isBlank(ri.estimatedTransactionsPerMonth)) errors.push('Estimated transactions per month is required.');
            if (isEmptyArray(ri.geographicExposure)) errors.push('At least one geographic exposure country is required.');
            if (isBlank(ri.intendedUseOfAccount)) errors.push('Intended use of account is required.');
        }

        if (this.isCorporateClient) {
            const ci = this.companyInfo || {};
            const bc = this.businessContext || {};

            if (isBlank(ci.legalEntityName)) errors.push('Legal entity name is required.');
            if (isBlank(ci.legalEntityType)) errors.push('Legal entity type is required.');
            if (isBlank(ci.dateOfIncorporation)) errors.push('Date of incorporation is required.');
            if (isBlank(ci.countryOfIncorporation)) errors.push('Country of incorporation is required.');
            if (isBlank(ci.registrationNumber)) errors.push('Registration number is required.');
            if (isBlank(ci.registeredStreet)) errors.push('Registered street is required.');
            if (isBlank(ci.registeredCity)) errors.push('Registered city is required.');
            if (isBlank(ci.registeredCountry)) errors.push('Registered country is required.');
            if (isBlank(ci.email)) errors.push('Corporate email is required.');

            if (isBlank(bc.purposeOfAccount)) errors.push('Purpose of account is required.');
            if (isBlank(bc.industry)) errors.push('Industry is required.');
            if (isBlank(bc.productsAndServices)) errors.push('Products and services description is required.');
            if (isEmptyArray(bc.paymentFlowTypes)) errors.push('Payment flow types is required.');
            if (isBlank(bc.expectedTransactionsPerMonth)) errors.push('Expected transactions per month is required.');
            if (isBlank(bc.expectedAnnualVolume)) errors.push('Expected annual volume is required.');
            if (isBlank(bc.typicalValuePerTransaction)) errors.push('Typical value per transaction is required.');
            if (isEmptyArray(bc.countriesFundsSentTo)) errors.push('Countries funds sent to is required.');
            if (isEmptyArray(bc.countriesFundsReceivedFrom)) errors.push('Countries funds received from is required.');
            if (isBlank(bc.primarySourceOfFunds)) errors.push('Primary source of funds is required.');
            if (isBlank(bc.sourceOfWealthExplanation)) errors.push('Source of wealth explanation is required.');

            const activeShareholders = (Array.isArray(this.shareholders) ? this.shareholders : [])
                .filter(shareholder => this.hasShareholderInput(shareholder));
            const activeAuthorisedUsers = (Array.isArray(this.authorisedUsers) ? this.authorisedUsers : [])
                .filter(user => this.hasAuthorisedUserInput(user));
            const hasShareholders = activeShareholders.length > 0;
            const hasAuthorisedUsers = activeAuthorisedUsers.length > 0;
            if (!hasShareholders && !hasAuthorisedUsers) {
                errors.push('At least one shareholder/director or authorised user is required.');
            }

            if (hasShareholders) {
                activeShareholders.forEach((shareholder, index) => {
                    const prefix = `Shareholder/Director ${index + 1}: `;
                    const isShareholder = shareholder?.isShareholder === true;
                    const isDirector = shareholder?.isDirector === true;
                    if (!isShareholder && !isDirector) errors.push(prefix + 'at least one role is required.');
                    if (shareholder?.type === 'Corporate') {
                        if (isBlank(shareholder?.legalEntityName)) errors.push(prefix + 'legal entity name is required.');
                    } else {
                        if (isBlank(shareholder?.firstName)) errors.push(prefix + 'first name is required.');
                        if (isBlank(shareholder?.lastName)) errors.push(prefix + 'last name is required.');
                    }
                    if (isBlank(shareholder?.dateOfBirthOrIncorporation)) errors.push(prefix + 'date is required.');
                    if (isBlank(shareholder?.countryOfResidenceOrIncorporation)) errors.push(prefix + 'country is required.');
                    if (isBlank(shareholder?.nationalityOrCountryOfIncorporation)) errors.push(prefix + 'nationality/country of incorporation is required.');
                    if (isBlank(shareholder?.governmentIdOrRegistrationNumber)) errors.push(prefix + 'government ID/registration number is required.');
                    if (isBlank(shareholder?.isPEP)) errors.push(prefix + 'PEP response is required.');
                    if (isBlank(shareholder?.email)) errors.push(prefix + 'email is required.');
                    if (isShareholder && isBlank(shareholder?.ownershipPercentage)) {
                        errors.push(prefix + 'ownership percentage is required for shareholder role.');
                    }
                });
            }

            if (hasAuthorisedUsers) {
                const needsTradeFrequency = this.hasFXService || this.hasCryptoService;
                activeAuthorisedUsers.forEach((user, index) => {
                    const prefix = `Authorised user ${index + 1}: `;
                    if (isBlank(user?.firstName)) errors.push(prefix + 'first name is required.');
                    if (isBlank(user?.lastName)) errors.push(prefix + 'last name is required.');
                    if (isBlank(user?.email)) errors.push(prefix + 'email is required.');
                    if (isBlank(user?.dateOfBirth)) errors.push(prefix + 'date of birth is required.');
                    if (isBlank(user?.countryOfResidence)) errors.push(prefix + 'country of residence is required.');
                    if (isBlank(user?.nationality)) errors.push(prefix + 'nationality is required.');
                    if (isBlank(user?.governmentIdNumber)) errors.push(prefix + 'government ID number is required.');
                    if (needsTradeFrequency && isBlank(user?.tradeFrequency)) {
                        errors.push(prefix + 'trade frequency is required for FX/Crypto services.');
                    }
                });
            }
        }

        if (this.hasFXService) {
            // Corporate client captures FX currencies in businessContext.
            // Private client captures FX currencies in serviceSpecific.
            const fxCurrenciesToSend = this.isCorporateClient
                ? this.businessContext?.currenciesToSend
                : this.serviceSpecific?.currenciesToSend;
            const fxCurrenciesToReceive = this.isCorporateClient
                ? this.businessContext?.currenciesToReceive
                : this.serviceSpecific?.currenciesToReceive;

            if (isEmptyArray(fxCurrenciesToSend)) errors.push('FX: currencies to send is required.');
            if (isEmptyArray(fxCurrenciesToReceive)) errors.push('FX: currencies to receive is required.');
            if (isBlank(this.serviceSpecific.fxForwardContractsRequired)) errors.push('FX: forward contracts/hedging response is required.');
            if (this.serviceSpecific.fxForwardContractsRequired === 'Yes' && isBlank(this.serviceSpecific.fxHedgingNeeds)) {
                errors.push('FX: hedging needs is required when forward contracts are required.');
            }
        }

        if (this.hasCryptoService) {
            if (isEmptyArray(this.serviceSpecific.digitalAssets)) errors.push('Crypto: digital assets selection is required.');
            if (isBlank(this.serviceSpecific.expectedMonthlyCryptoVolume)) errors.push('Crypto: expected monthly volume is required.');
            if (isBlank(this.serviceSpecific.averageCryptoTransactionSize)) errors.push('Crypto: average transaction size is required.');
        }

        if (this.hasAdvisoryService) {
            if (isEmptyArray(this.serviceSpecific.advisoryServicesRequired)) errors.push('Advisory: services required is required.');
            if (isEmptyArray(this.serviceSpecific.investmentObjectives)) errors.push('Advisory: investment objectives is required.');
            if (isBlank(this.serviceSpecific.riskAppetite)) errors.push('Advisory: risk appetite is required.');
        }

        return errors;
    }

    /**
     * @description Handles form submission by calling Apex method
     */
    async handleSubmit() {
        // Prevent multiple submissions
        if (this.isSubmitting) {
            return;
        }

        // Clear previous errors
        this.submissionError = null;
        this.showRetryButton = false;

        // Client-side validation before submission
        const validationErrors = [];
        
        // Log current state for debugging (extract actual values, not Proxy objects)
        const currentState = {
            clientType: String(this.clientType || ''),
            servicesRequired: Array.isArray(this.servicesRequired) ? [...this.servicesRequired] : [],
            servicesRequiredType: typeof this.servicesRequired,
            servicesRequiredIsArray: Array.isArray(this.servicesRequired),
            servicesRequiredLength: this.servicesRequired ? this.servicesRequired.length : 0,
            declarationsAgreeToTerms: this.declarations ? Boolean(this.declarations.agreeToTerms) : false,
            declarationsSignatoryFirstName: this.declarations ? String(this.declarations.signatoryFirstName || '') : '',
            declarationsSignatoryLastName: this.declarations ? String(this.declarations.signatoryLastName || '') : ''
        };
        console.log('handleSubmit - Current state:', JSON.parse(JSON.stringify(currentState)));
        
        if (!this.clientType || this.clientType.trim() === '') {
            validationErrors.push('Client type is required. Please go back to the "Get Started" step and select a client type.');
        }
        
        if (!this.servicesRequired || !Array.isArray(this.servicesRequired) || this.servicesRequired.length === 0) {
            validationErrors.push('At least one service is required. Please go back to the "Get Started" step and select at least one service.');
        }
        
        if (!this.declarations || !this.declarations.agreeToTerms) {
            validationErrors.push('You must agree to the Terms & Conditions. Please check the "I agree to Terms & Conditions" checkbox.');
        }

        // Additional Party validation (role-based required fields)
        if (Array.isArray(this.additionalParties) && this.additionalParties.length > 0) {
            this.additionalParties.forEach((party, index) => {
                const missing = [];
                const idx = index + 1;
                const role = (party && party.role || '').trim();
                const type = (party && party.type || '').trim();

                // Check name based on party type
                if (type === 'Individual') {
                    const firstName = (party && party.firstName || '').trim();
                    const lastName = (party && party.lastName || '').trim();
                    if (!firstName) missing.push('First Name');
                    if (!lastName) missing.push('Last Name');
                } else if (type === 'Corporate') {
                    const legalEntityName = (party && party.legalEntityName || '').trim();
                    if (!legalEntityName) missing.push('Legal Entity Name');
                }

                if (!role) missing.push('Role');
                if (!type) missing.push('Type');

                const dob = (party && party.dateOfBirthOrIncorporation || '').trim();
                const country = (party && party.countryOfResidenceOrIncorporation || '').trim();
                const nationality = (party && party.nationalityOrCountryOfIncorporation || '').trim();
                const govId = (party && party.governmentIdOrRegistrationNumber || '').trim();

                if (type === 'Individual') {
                    if (!dob) missing.push('Date of Birth');
                    if (!country) missing.push('Country of Residence');
                    if (!nationality) missing.push('Nationality');
                    if (!govId) missing.push('Government ID Number');
                } else if (type === 'Corporate') {
                    if (!dob) missing.push('Date of Incorporation');
                    if (!country) missing.push('Country of Incorporation');
                    if (!govId) missing.push('Registration Number');
                }

                if (missing.length > 0) {
                    validationErrors.push(`Additional party ${idx}: ${missing.join(', ')} required.`);
                }
            });
        }

        validationErrors.push(...this.getSubmissionValidationErrors());
        
        if (validationErrors.length > 0) {
            this.submissionError = {
                message: validationErrors.join(' '),
                errors: validationErrors,
                type: 'ClientValidationError'
            };
            this.showRetryButton = false;
            this.showToast('Error', validationErrors.join(' '), 'error');
            console.error('Client-side validation failed:', validationErrors);
            return;
        }

        try {
            this.isSubmitting = true;
            this.showToast('Info', 'Submitting your application...', 'info');

            // Prepare form data
            const rawFormData = this.prepareFormData();
            
            // CRITICAL: Create a completely plain object structure that Lightning can serialize
            // Lightning serialization is very strict - we must ensure all fields are explicitly set
            // and match the Apex DTO structure exactly
            
            // Extract values explicitly to avoid Proxy issues
            // CRITICAL: Use JSON serialization to break Proxy references completely
            const clientTypePlain = String(rawFormData.clientType || '').trim();
            
            // For arrays, serialize and deserialize to ensure they're plain arrays, not Proxy arrays
            let servicesRequiredPlain = [];
            if (rawFormData.servicesRequired) {
                try {
                    const servicesJson = JSON.stringify(rawFormData.servicesRequired);
                    servicesRequiredPlain = JSON.parse(servicesJson).map(s => String(s || '').trim()).filter(s => s !== '');
                } catch (e) {
                    console.error('Failed to serialize servicesRequired:', e);
                    servicesRequiredPlain = [];
                }
            }
            
            let declarationsPlain = [];
            if (rawFormData.declarations) {
                try {
                    const declarationsJson = JSON.stringify(rawFormData.declarations);
                    declarationsPlain = JSON.parse(declarationsJson);
                } catch (e) {
                    console.error('Failed to serialize declarations:', e);
                    declarationsPlain = [];
                }
            }
            
            // Create a completely new plain object (not a copy, but a new structure)
            // This ensures Lightning can properly serialize it
            // CRITICAL: Apex expects non-null values - send empty arrays/strings, not null
            const formData = {
                clientType: clientTypePlain || '', // Always send a string, never null
                servicesRequired: servicesRequiredPlain, // Always send an array, even if empty
                declarations: declarationsPlain, // Always send an array, even if empty
                // Copy other fields
                applicationId: rawFormData.applicationId || null,
                currentStep: rawFormData.currentStep || '',
                isSubmission: true, // Explicit flag: this is a final submission, not an auto-save
                channel: rawFormData.channel || '',
                personalInfo: rawFormData.personalInfo || null,
                addressInfo: rawFormData.addressInfo || null,
                riskInfo: rawFormData.riskInfo || null,
                companyInfo: rawFormData.companyInfo || null,
                businessContext: rawFormData.businessContext || null,
                shareholders: Array.isArray(rawFormData.shareholders) && rawFormData.shareholders.length > 0 ? rawFormData.shareholders.slice() : null,
                authorisedUsers: Array.isArray(rawFormData.authorisedUsers) && rawFormData.authorisedUsers.length > 0 ? rawFormData.authorisedUsers.slice() : null,
                additionalParties: Array.isArray(rawFormData.additionalParties) && rawFormData.additionalParties.length > 0 ? rawFormData.additionalParties.slice() : null,
                serviceProfiles: (() => {
                    if (Array.isArray(rawFormData.serviceProfiles) && rawFormData.serviceProfiles.length > 0) {
                        // Deep clone service profiles to ensure arrays inside are plain arrays
                        return rawFormData.serviceProfiles.map(sp => {
                            const plainSP = {
                                serviceType: String(sp.serviceType || ''),
                                // fxCurrencyPairs: Array.isArray(sp.fxCurrencyPairs) ? [...sp.fxCurrencyPairs] : [], // Deprecated - replaced with currenciesToSend/Receive
                                currenciesToSend: Array.isArray(sp.currenciesToSend) ? [...sp.currenciesToSend] : [],
                                currenciesToReceive: Array.isArray(sp.currenciesToReceive) ? [...sp.currenciesToReceive] : [],
                                countriesFundsSentTo: Array.isArray(sp.countriesFundsSentTo) ? [...sp.countriesFundsSentTo] : [],
                                countriesFundsReceivedFrom: Array.isArray(sp.countriesFundsReceivedFrom) ? [...sp.countriesFundsReceivedFrom] : [],
                                fxForwardContractsRequired: String(sp.fxForwardContractsRequired || ''),
                                fxHedgingNeeds: String(sp.fxHedgingNeeds || ''),
                                digitalAssets: Array.isArray(sp.digitalAssets) ? [...sp.digitalAssets] : [],
                                expectedMonthlyCryptoVolume: String(sp.expectedMonthlyCryptoVolume || ''),
                                averageCryptoTransactionSize: String(sp.averageCryptoTransactionSize || ''),
                                // isVASP removed - regulatory status captured in Company Info step
                                advisoryServicesRequired: Array.isArray(sp.advisoryServicesRequired) ? [...sp.advisoryServicesRequired] : [],
                                investmentObjectives: Array.isArray(sp.investmentObjectives) ? [...sp.investmentObjectives] : [],
                                riskAppetite: String(sp.riskAppetite || ''),
                                timeHorizon: String(sp.timeHorizon || ''),
                                existingAdvisoryRelationships: String(sp.existingAdvisoryRelationships || '')
                            };
                            return plainSP;
                        });
                    }
                    return null;
                })(),
                regulatoryInfo: rawFormData.regulatoryInfo || null,
                fileUploads: Array.isArray(rawFormData.fileUploads) && rawFormData.fileUploads.length > 0 ? rawFormData.fileUploads.slice() : null,
                userAgent: String(rawFormData.userAgent || ''),
                ipAddress: String(rawFormData.ipAddress || '')
            };
            
            // Log the plain values we extracted
            console.log('=== EXTRACTED PLAIN VALUES ===');
            console.log('clientTypePlain:', clientTypePlain, '| Length:', clientTypePlain.length);
            console.log('servicesRequiredPlain:', servicesRequiredPlain, '| Length:', servicesRequiredPlain.length);
            console.log('declarationsPlain:', declarationsPlain, '| Length:', declarationsPlain.length);
            if (formData.serviceProfiles && formData.serviceProfiles.length > 0) {
                console.log('serviceProfiles count:', formData.serviceProfiles.length);
                formData.serviceProfiles.forEach((sp, idx) => {
                    // Extract actual values to avoid Proxy objects in console
                    const spData = {
                        serviceType: String(sp.serviceType || ''),
                        currenciesToSend: Array.isArray(sp.currenciesToSend) ? [...sp.currenciesToSend] : [],
                        currenciesToReceive: Array.isArray(sp.currenciesToReceive) ? [...sp.currenciesToReceive] : [],
                        countriesFundsSentTo: Array.isArray(sp.countriesFundsSentTo) ? [...sp.countriesFundsSentTo] : [],
                        countriesFundsReceivedFrom: Array.isArray(sp.countriesFundsReceivedFrom) ? [...sp.countriesFundsReceivedFrom] : [],
                        fxForwardContractsRequired: String(sp.fxForwardContractsRequired || ''),
                        fxHedgingNeeds: String(sp.fxHedgingNeeds || '')
                    };
                    console.log(`  Service Profile ${idx}:`, JSON.parse(JSON.stringify(spData)));
                });
            } else {
                console.log('serviceProfiles: null or empty');
            }
            console.log('=== END EXTRACTED VALUES ===');
            
            // CRITICAL: Validate the cloned data before sending to Apex
            const validationCheck = {
                clientType: formData.clientType || '',
                clientTypeIsValid: formData.clientType && formData.clientType.trim() !== '',
                servicesRequired: formData.servicesRequired || [],
                servicesRequiredIsArray: Array.isArray(formData.servicesRequired),
                servicesRequiredLength: formData.servicesRequired ? formData.servicesRequired.length : 0,
                servicesRequiredIsValid: formData.servicesRequired && Array.isArray(formData.servicesRequired) && formData.servicesRequired.length > 0,
                declarations: formData.declarations || [],
                declarationsIsArray: Array.isArray(formData.declarations),
                declarationsLength: formData.declarations ? formData.declarations.length : 0,
                declarationsIsValid: formData.declarations && Array.isArray(formData.declarations) && formData.declarations.length > 0
            };
            
            // Log the actual values (not Proxy objects)
            console.log('=== FORM DATA VALIDATION CHECK ===');
            console.log('Client Type:', validationCheck.clientType, '| Valid:', validationCheck.clientTypeIsValid);
            console.log('Services Required:', validationCheck.servicesRequired, '| Length:', validationCheck.servicesRequiredLength, '| Valid:', validationCheck.servicesRequiredIsValid);
            console.log('Declarations Length:', validationCheck.declarationsLength, '| Valid:', validationCheck.declarationsIsValid);
            console.log('Full Validation Object:', JSON.parse(JSON.stringify(validationCheck)));
            console.log('=== END VALIDATION CHECK ===');
            
            // Final validation - if data is still invalid after cloning, throw error
            if (!validationCheck.clientTypeIsValid || !validationCheck.servicesRequiredIsValid || !validationCheck.declarationsIsValid) {
                const missingFields = [];
                if (!validationCheck.clientTypeIsValid) missingFields.push('clientType');
                if (!validationCheck.servicesRequiredIsValid) missingFields.push('servicesRequired');
                if (!validationCheck.declarationsIsValid) missingFields.push('declarations');
                
                throw new Error(`Data validation failed after cloning. Missing or invalid fields: ${missingFields.join(', ')}. This indicates a data capture issue.`);
            }

            // CRITICAL: Log the actual structure being sent to Apex (extract actual values)
            const finalStructure = {
                clientType: String(formData.clientType || ''),
                clientTypeType: typeof formData.clientType,
                servicesRequired: Array.isArray(formData.servicesRequired) ? [...formData.servicesRequired] : [],
                servicesRequiredType: typeof formData.servicesRequired,
                servicesRequiredIsArray: Array.isArray(formData.servicesRequired),
                servicesRequiredLength: formData.servicesRequired ? formData.servicesRequired.length : 0,
                declarations: Array.isArray(formData.declarations) ? formData.declarations.map(d => ({
                    declarationType: String(d.declarationType || ''),
                    accepted: Boolean(d.accepted),
                    signatureName: String(d.signatureName || '')
                })) : [],
                declarationsType: typeof formData.declarations,
                declarationsIsArray: Array.isArray(formData.declarations),
                declarationsLength: formData.declarations ? formData.declarations.length : 0,
                formDataKeys: Object.keys(formData)
            };
            console.log('=== FINAL FORM DATA STRUCTURE (BEFORE APEX CALL) ===');
            console.log(JSON.parse(JSON.stringify(finalStructure)));
            console.log('=== END FINAL STRUCTURE ===');

            // CRITICAL: Log exactly what we're sending to Apex (before serialization)
            console.log('=== EXACT DATA BEING SENT TO APEX ===');
            console.log('formData.clientType:', formData.clientType, '| Type:', typeof formData.clientType, '| Value:', String(formData.clientType || 'NULL'));
            console.log('formData.servicesRequired:', formData.servicesRequired, '| Type:', typeof formData.servicesRequired, '| IsArray:', Array.isArray(formData.servicesRequired), '| Length:', formData.servicesRequired ? formData.servicesRequired.length : 0);
            console.log('formData.declarations:', formData.declarations, '| Type:', typeof formData.declarations, '| IsArray:', Array.isArray(formData.declarations), '| Length:', formData.declarations ? formData.declarations.length : 0);
            
            // CRITICAL: Final JSON round-trip to ensure ALL Proxy references are broken
            // Lightning serialization requires completely plain objects
            let serializedFormData;
            try {
                const jsonString = JSON.stringify(formData);
                console.log('Serialized JSON string length:', jsonString.length);
                console.log('Serialized JSON (first 500 chars):', jsonString.substring(0, 500));
                serializedFormData = JSON.parse(jsonString);
                
                // Verify critical fields after serialization
                console.log('After JSON round-trip:');
                console.log('  clientType:', serializedFormData.clientType, '| Type:', typeof serializedFormData.clientType, '| Value:', String(serializedFormData.clientType || 'NULL'));
                console.log('  servicesRequired:', serializedFormData.servicesRequired, '| Type:', typeof serializedFormData.servicesRequired, '| IsArray:', Array.isArray(serializedFormData.servicesRequired), '| Length:', serializedFormData.servicesRequired ? serializedFormData.servicesRequired.length : 0);
                if (serializedFormData.servicesRequired && serializedFormData.servicesRequired.length > 0) {
                    console.log('  servicesRequired[0]:', serializedFormData.servicesRequired[0]);
                }
                console.log('  declarations:', serializedFormData.declarations, '| Type:', typeof serializedFormData.declarations, '| IsArray:', Array.isArray(serializedFormData.declarations), '| Length:', serializedFormData.declarations ? serializedFormData.declarations.length : 0);
                if (serializedFormData.declarations && serializedFormData.declarations.length > 0) {
                    console.log('  declarations[0]:', JSON.stringify(serializedFormData.declarations[0]));
                }
                
                // Final verification - ensure these are NOT Proxy objects
                const isPlainArray = (arr) => {
                    return Array.isArray(arr) && !(arr instanceof Proxy);
                };
                console.log('  servicesRequired is plain array:', isPlainArray(serializedFormData.servicesRequired));
                console.log('  declarations is plain array:', isPlainArray(serializedFormData.declarations));
            } catch (serializeError) {
                console.error('❌ Serialization error detected! Building plain object manually...', serializeError);
                
                // CRITICAL: If serialization fails, build a completely new plain object manually
                // This avoids any Proxy object issues
                
                // Build declarations array manually (plain objects only)
                const declarationsPlainArray = [];
                if (Array.isArray(declarationsPlain) && declarationsPlain.length > 0) {
                    for (let i = 0; i < declarationsPlain.length; i++) {
                        try {
                            const declJson = JSON.stringify(declarationsPlain[i]);
                            const declPlain = JSON.parse(declJson);
                            declarationsPlainArray.push({
                                declarationType: String(declPlain.declarationType || ''),
                                accepted: Boolean(declPlain.accepted),
                                signatoryFirstName: String(declPlain.signatoryFirstName || ''),
                                signatoryLastName: String(declPlain.signatoryLastName || ''),
                                signatureName: String(declPlain.signatureName || '')
                            });
                        } catch (e) {
                            console.error(`Failed to serialize declaration ${i}:`, e);
                        }
                    }
                }
                
                // Build the final plain object structure manually
                serializedFormData = {
                    // CRITICAL: Include applicationId and currentStep to prevent duplicate record creation!
                    applicationId: rawFormData.applicationId || null,
                    currentStep: rawFormData.currentStep || '',
                    isSubmission: true, // Explicit flag: this is a final submission, not an auto-save
                    channel: rawFormData.channel || 'ExperienceCloud',
                    ipAddress: rawFormData.ipAddress || '',
                    userAgent: rawFormData.userAgent || '',
                    
                    // Data fields
                    clientType: clientTypePlain || '',
                    servicesRequired: servicesRequiredPlain.length > 0 ? [...servicesRequiredPlain] : [],
                    declarations: declarationsPlainArray.length > 0 ? declarationsPlainArray : [],
                    // Copy other fields (they should already be plain from prepareFormData)
                    personalInfo: rawFormData.personalInfo || null,
                    addressInfo: rawFormData.addressInfo || null,
                    riskInfo: rawFormData.riskInfo || null,
                    companyInfo: rawFormData.companyInfo || null,
                    businessContext: rawFormData.businessContext || null,
                    regulatoryInfo: rawFormData.regulatoryInfo || null,
                    shareholders: Array.isArray(rawFormData.shareholders) && rawFormData.shareholders.length > 0 ? rawFormData.shareholders.slice() : null,
                    authorisedUsers: Array.isArray(rawFormData.authorisedUsers) && rawFormData.authorisedUsers.length > 0 ? rawFormData.authorisedUsers.slice() : null,
                    additionalParties: Array.isArray(rawFormData.additionalParties) && rawFormData.additionalParties.length > 0 ? rawFormData.additionalParties.slice() : null,
                    fileUploads: Array.isArray(rawFormData.fileUploads) && rawFormData.fileUploads.length > 0 ? rawFormData.fileUploads.slice() : null,
                    serviceProfiles: (() => {
                    if (Array.isArray(rawFormData.serviceProfiles) && rawFormData.serviceProfiles.length > 0) {
                        // Deep clone service profiles to ensure arrays inside are plain arrays
                        return rawFormData.serviceProfiles.map(sp => {
                            const plainSP = {
                                serviceType: String(sp.serviceType || ''),
                                // fxCurrencyPairs: Array.isArray(sp.fxCurrencyPairs) ? [...sp.fxCurrencyPairs] : [], // Deprecated - replaced with currenciesToSend/Receive
                                currenciesToSend: Array.isArray(sp.currenciesToSend) ? [...sp.currenciesToSend] : [],
                                currenciesToReceive: Array.isArray(sp.currenciesToReceive) ? [...sp.currenciesToReceive] : [],
                                countriesFundsSentTo: Array.isArray(sp.countriesFundsSentTo) ? [...sp.countriesFundsSentTo] : [],
                                countriesFundsReceivedFrom: Array.isArray(sp.countriesFundsReceivedFrom) ? [...sp.countriesFundsReceivedFrom] : [],
                                fxForwardContractsRequired: String(sp.fxForwardContractsRequired || ''),
                                fxHedgingNeeds: String(sp.fxHedgingNeeds || ''),
                                averageFxTradeSize: String(sp.averageFxTradeSize || ''),
                                expectedMonthlyFxVolume: String(sp.expectedMonthlyFxVolume || ''),
                                digitalAssets: Array.isArray(sp.digitalAssets) ? [...sp.digitalAssets] : [],
                                expectedMonthlyCryptoVolume: String(sp.expectedMonthlyCryptoVolume || ''),
                                averageCryptoTransactionSize: String(sp.averageCryptoTransactionSize || ''),
                                // isVASP removed - regulatory status captured in Company Info step
                                advisoryServicesRequired: Array.isArray(sp.advisoryServicesRequired) ? [...sp.advisoryServicesRequired] : [],
                                investmentObjectives: Array.isArray(sp.investmentObjectives) ? [...sp.investmentObjectives] : [],
                                riskAppetite: String(sp.riskAppetite || ''),
                                timeHorizon: String(sp.timeHorizon || ''),
                                existingAdvisoryRelationships: String(sp.existingAdvisoryRelationships || '')
                            };
                            return plainSP;
                        });
                    }
                    return null;
                })(),
                    regulatoryInfo: rawFormData.regulatoryInfo || null,
                    fileUploads: Array.isArray(rawFormData.fileUploads) && rawFormData.fileUploads.length > 0 ? rawFormData.fileUploads.slice() : null,
                    userAgent: String(rawFormData.userAgent || ''),
                    ipAddress: String(rawFormData.ipAddress || '')
                };
                
                // Verify the manually built structure can be serialized
                try {
                    const testJson = JSON.stringify(serializedFormData);
                    console.log('✅ Manually built object serializes successfully! JSON length:', testJson.length);
                    console.log('  clientType:', serializedFormData.clientType);
                    console.log('  servicesRequired length:', serializedFormData.servicesRequired.length);
                    console.log('  declarations length:', serializedFormData.declarations.length);
                } catch (testError) {
                    console.error('❌ Even manually built object fails serialization:', testError);
                    throw new Error('Cannot serialize form data even with manual object creation.');
                }
            }
            console.log('=== END EXACT DATA ===');
            
            // CRITICAL: Pass as JSON string to avoid Lightning serialization issues
            // Lightning has trouble serializing complex nested objects, so we serialize to JSON string
            // and let Apex deserialize it
            let formDataJsonString;
            try {
                formDataJsonString = JSON.stringify(serializedFormData);
                console.log('✅ Final JSON string created successfully. Length:', formDataJsonString.length);
                console.log('JSON preview (first 300 chars):', formDataJsonString.substring(0, 300));
            } catch (jsonError) {
                console.error('❌ Failed to create JSON string:', jsonError);
                throw new Error('Cannot serialize form data to JSON string.');
            }
            
            // Call Apex method with JSON string instead of object
            const result = await saveOnboardingApplication({ formDataJson: formDataJsonString });

            // DEBUG: Log Apex debug info if available (extract actual values)
            if (result.debugInfo) {
                try {
                    const debugInfoPlain = JSON.parse(JSON.stringify(result.debugInfo));
                    console.log('=== APEX DEBUG INFO (RETURNED IN RESPONSE) ===');
                    console.log(JSON.stringify(debugInfoPlain, null, 2));
                    if (debugInfoPlain.apexReceivedData) {
                        console.log('Client Type:', debugInfoPlain.apexReceivedData.clientType, '| IsBlank:', debugInfoPlain.apexReceivedData.clientTypeIsBlank);
                        console.log('Services Required Size:', debugInfoPlain.apexReceivedData.servicesRequiredSize, '| IsEmpty:', debugInfoPlain.apexReceivedData.servicesRequiredIsEmpty, '| Values:', debugInfoPlain.apexReceivedData.servicesRequiredValues);
                        console.log('Declarations Size:', debugInfoPlain.apexReceivedData.declarationsSize, '| IsEmpty:', debugInfoPlain.apexReceivedData.declarationsIsEmpty);
                    }
                    console.log('=== END APEX DEBUG INFO ===');
                } catch (e) {
                    console.error('Failed to parse debug info:', e);
                    console.log('Raw debugInfo:', result.debugInfo);
                }
            }
            
            // Handle result
            if (result.isSuccess) {
                this.submissionDate = new Date().toLocaleString();
                this.showSuccessMessage = true;
                this.currentStep = 'success';
                this.showProgress = false;
                this.submissionError = null;
                this.showRetryButton = false;
                
                this.showToast('Success', 'Your onboarding application has been submitted successfully!', 'success');
                
                console.log('Application submitted successfully:', {
                    applicationId: result.applicationId,
                    recordIds: result.recordIds
                });
            } else {
                // Handle validation errors or other errors from Apex
                const errorMessage = result.errors && result.errors.length > 0 
                    ? result.errors.join('. ') 
                    : (result.message || 'An error occurred while submitting your application.');
                
                this.submissionError = {
                    message: errorMessage,
                    errors: result.errors || [],
                    type: 'ValidationError',
                    debugInfo: result.debugInfo || null
                };
                this.showRetryButton = true;
                
                this.showToast('Error', errorMessage, 'error');
                
                // Log Apex debug info for troubleshooting (what Apex actually received)
                if (result.debugInfo) {
                    try {
                        const debugInfoPlain = JSON.parse(JSON.stringify(result.debugInfo));
                        console.error('=== APEX VALIDATION ERROR - DEBUG INFO ===');
                        console.error('Full Debug Info:', JSON.stringify(debugInfoPlain, null, 2));
                        if (debugInfoPlain.apexReceivedData) {
                            const apexData = debugInfoPlain.apexReceivedData;
                            console.error('--- What Apex Received ---');
                            console.error('formDataIsNull:', apexData.formDataIsNull);
                            console.error('clientType:', apexData.clientType, '| IsBlank:', apexData.clientTypeIsBlank);
                            console.error('servicesRequiredSize:', apexData.servicesRequiredSize, '| IsEmpty:', apexData.servicesRequiredIsEmpty, '| Values:', apexData.servicesRequiredValues);
                            console.error('declarationsSize:', apexData.declarationsSize, '| IsEmpty:', apexData.declarationsIsEmpty);
                            if (apexData.declarationsDetails) {
                                console.error('declarationsDetails:', apexData.declarationsDetails);
                            }
                        }
                        console.error('Validation errors:', result.errors);
                        console.error('=== END APEX VALIDATION ERROR DEBUG ===');
                    } catch (e) {
                        console.error('Failed to parse debug info:', e);
                        console.error('Raw debugInfo:', result.debugInfo);
                    }
                }
                
                this.logError({ message: errorMessage, errors: result.errors, debugInfo: result.debugInfo }, 'Apex Validation Error');
            }
        } catch (error) {
            // Handle unexpected errors (network, Apex exceptions, etc.)
            const userFriendlyMessage = this.parseApexError(error);
            
            this.submissionError = {
                message: userFriendlyMessage,
                originalError: error,
                type: 'UnexpectedError'
            };
            this.showRetryButton = true;
            
            this.showToast('Error', userFriendlyMessage, 'error');
            this.logError(error, 'Unexpected Submission Error');
        } finally {
            this.isSubmitting = false;
        }
    }

    /**
     * @description Retries form submission after an error
     */
    handleRetrySubmission() {
        this.submissionError = null;
        this.showRetryButton = false;
        this.handleSubmit();
    }

    // ============================================
    // CLIENT LINK COPYING (HYBRID APPROACH)
    // ============================================
    
    /**
     * @description Copy Client Link to clipboard
     */
    async handleCopyClientLink() {
        // Ensure we have a recordId first
        if (!this.recordId) {
            this.showToast('Warning', 'Please save the form first before copying the link.', 'warning');
            return;
        }
        
        try {
            // Regenerate link to ensure it's fresh
            this.generateClientLinks();
            
            // Copy to clipboard
            await navigator.clipboard.writeText(this.clientLink);
            this.showToast('Success', 'Client Link copied to clipboard!', 'success');
            console.log('📋 Copied Client Link:', this.clientLink);
        } catch (error) {
            console.error('Failed to copy link:', error);
            this.showToast('Error', 'Failed to copy link. Please copy manually: ' + this.clientLink, 'error');
        }
    }
    
    /**
     * @description Start a completely new application (clears storage and refreshes)
     */
    handleStartNewApplication() {
        this.clearRecordIdFromStorage();
        window.location.href = window.location.origin + window.location.pathname + '?new=true';
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
}

