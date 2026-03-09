@RestResource(urlMapping='/brdge/v1/beneficiaries/*')
global with sharing class BrdgeBeneficiaryService {
    private static final String ROUTING_REGION_UK = 'UK';
    private static final String ROUTING_REGION_US = 'US';
    private static final String ROUTING_REGION_INTL = 'INTERNATIONAL';

    private static final Set<String> UK_COUNTRY_VALUES = new Set<String>{
        'UK', 'GB', 'UNITED KINGDOM', 'GREAT BRITAIN'
    };
    private static final Set<String> US_COUNTRY_VALUES = new Set<String>{
        'US', 'USA', 'UNITED STATES', 'UNITED STATES OF AMERICA'
    };

    @HttpGet
    global static void getBeneficiaries() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String clientCode = req.params.get('clientCode');

            if (String.isBlank(clientCode)) {
                sendError(res, 400, 'clientCode query parameter is required', 'MISSING_CLIENT_CODE');
                return;
            }

            List<Account> accounts = [
                SELECT Id FROM Account WHERE Client_Code__c = :clientCode LIMIT 1
            ];

            if (accounts.isEmpty()) {
                sendError(res, 404, 'Account not found for clientCode: ' + clientCode, 'ACCOUNT_NOT_FOUND');
                return;
            }

            List<Bank_Account__c> beneficiaries = [
                SELECT Id, Name, Beneficiary_Name__c, Bank_Name__c, Bank_Account_Number__c,
                       Bank_Country__c, IBAN__c, Swift_Code__c, Sort_Code__c, ABA_Number__c,
                       Bank_Address__c, Bank_Account_Name__c, Verified__c, Active__c,
                       Account__r.Client_Code__c, CurrencyIsoCode, CreatedDate
                FROM Bank_Account__c
                WHERE Account__r.Client_Code__c = :clientCode
                  AND Active__c = true
                ORDER BY CreatedDate DESC
            ];

            List<Map<String, Object>> results = new List<Map<String, Object>>();
            for (Bank_Account__c b : beneficiaries) {
                results.add(mapBeneficiary(b));
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(results));

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    @HttpPost
    global static void createBeneficiary() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            List<String> missingFields = new List<String>();
            String beneficiaryName = getStringParam(body, 'beneficiaryName');
            String bankName = getStringParam(body, 'bankName');
            String bankAccountNumber = getStringParam(body, 'bankAccountNumber');
            String bankCountry = getStringParam(body, 'bankCountry');
            String clientCode = getStringParam(body, 'clientCode');

            if (String.isBlank(beneficiaryName)) { missingFields.add('beneficiaryName'); }
            if (String.isBlank(bankName)) { missingFields.add('bankName'); }
            if (String.isBlank(bankAccountNumber)) { missingFields.add('bankAccountNumber'); }
            if (String.isBlank(bankCountry)) { missingFields.add('bankCountry'); }
            if (String.isBlank(clientCode)) { missingFields.add('clientCode'); }

            if (!missingFields.isEmpty()) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'error' => 'Missing required fields: ' + String.join(missingFields, ', '),
                    'errorCode' => 'MISSING_REQUIRED_FIELDS',
                    'missingFields' => missingFields
                }));
                return;
            }

            List<String> missingRoutingFields = getMissingRoutingFields(
                bankCountry,
                getStringParam(body, 'sortCode'),
                getStringParam(body, 'abaNumber'),
                getStringParam(body, 'iban'),
                getStringParam(body, 'swiftCode')
            );
            if (!missingRoutingFields.isEmpty()) {
                sendConditionalFieldError(res, bankCountry, missingRoutingFields);
                return;
            }

            List<Account> accounts = [
                SELECT Id, Name FROM Account WHERE Client_Code__c = :clientCode LIMIT 1
            ];

            if (accounts.isEmpty()) {
                sendError(res, 404, 'Account not found for clientCode: ' + clientCode, 'ACCOUNT_NOT_FOUND');
                return;
            }

            Account acc = accounts[0];

            Bank_Account__c newBeneficiary = new Bank_Account__c(
                Beneficiary_Name__c = beneficiaryName,
                Bank_Name__c = bankName,
                Bank_Account_Number__c = bankAccountNumber,
                Bank_Country__c = bankCountry,
                Account__c = acc.Id,
                Active__c = true,
                Verified__c = false,
                IBAN__c = getStringParam(body, 'iban'),
                Swift_Code__c = getStringParam(body, 'swiftCode'),
                Sort_Code__c = getStringParam(body, 'sortCode'),
                ABA_Number__c = getStringParam(body, 'abaNumber'),
                Bank_Address__c = getStringParam(body, 'bankAddress'),
                Bank_Account_Name__c = getStringParam(body, 'bankAccountName')
            );

            String currencyParam = getStringParam(body, 'currencyIsoCode');
            if (String.isNotBlank(currencyParam)) {
                newBeneficiary.CurrencyIsoCode = currencyParam;
            }

            insert newBeneficiary;

            sendComplianceNotification(acc.Name, beneficiaryName, bankName, bankCountry, bankAccountNumber);

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'id' => newBeneficiary.Id,
                'name' => newBeneficiary.Name
            }));

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    private static void sendComplianceNotification(
        String clientName, String beneficiaryName, String bankName,
        String bankCountry, String bankAccountNumber
    ) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            List<OrgWideEmailAddress> owas = [
                SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Lydiam' LIMIT 1
            ];
            if (!owas.isEmpty()) {
                mail.setOrgWideEmailAddressId(owas[0].Id);
            }

            // Compliance email address — should be moved to Custom Metadata or Custom Label for configurability
            mail.setToAddresses(new List<String>{ 'compliance@lydiam.com' });
            mail.setSubject('New Beneficiary Pending Verification');
            mail.setPlainTextBody(
                'A new beneficiary has been added and requires verification.\n\n' +
                'Client Name: ' + clientName + '\n' +
                'Beneficiary Name: ' + beneficiaryName + '\n' +
                'Bank Name: ' + bankName + '\n' +
                'Bank Country: ' + bankCountry + '\n' +
                'Bank Account Number: ' + bankAccountNumber
            );

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send compliance notification: ' + e.getMessage());
        }
    }

    @HttpPatch
    global static void updateBeneficiary() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            String beneficiaryId = getStringParam(body, 'id');
            String clientCode = getStringParam(body, 'clientCode');

            if (String.isBlank(beneficiaryId) || String.isBlank(clientCode)) {
                sendError(res, 400, 'id and clientCode are required', 'MISSING_REQUIRED_FIELDS');
                return;
            }

            if (body.containsKey('active') || body.containsKey('verified')) {
                sendError(res, 400, 'Cannot modify protected fields: active, verified', 'PROTECTED_FIELD');
                return;
            }

            List<Bank_Account__c> beneficiaries = [
                SELECT Id, Name, Beneficiary_Name__c, Bank_Name__c, Bank_Account_Number__c,
                       Bank_Country__c, IBAN__c, Swift_Code__c, Sort_Code__c, ABA_Number__c,
                       Bank_Address__c, Bank_Account_Name__c, Verified__c, Active__c,
                       Account__r.Client_Code__c, CurrencyIsoCode, CreatedDate
                FROM Bank_Account__c
                WHERE Id = :beneficiaryId
                  AND Account__r.Client_Code__c = :clientCode
                LIMIT 1
            ];

            if (beneficiaries.isEmpty()) {
                sendError(res, 404, 'Beneficiary not found for the given id and clientCode', 'BENEFICIARY_NOT_FOUND');
                return;
            }

            Bank_Account__c beneficiary = beneficiaries[0];

            if (body.containsKey('beneficiaryName')) { beneficiary.Beneficiary_Name__c = getStringParam(body, 'beneficiaryName'); }
            if (body.containsKey('bankName')) { beneficiary.Bank_Name__c = getStringParam(body, 'bankName'); }
            if (body.containsKey('bankAccountNumber')) { beneficiary.Bank_Account_Number__c = getStringParam(body, 'bankAccountNumber'); }
            if (body.containsKey('bankCountry')) { beneficiary.Bank_Country__c = getStringParam(body, 'bankCountry'); }
            if (body.containsKey('iban')) { beneficiary.IBAN__c = getStringParam(body, 'iban'); }
            if (body.containsKey('swiftCode')) { beneficiary.Swift_Code__c = getStringParam(body, 'swiftCode'); }
            if (body.containsKey('sortCode')) { beneficiary.Sort_Code__c = getStringParam(body, 'sortCode'); }
            if (body.containsKey('abaNumber')) { beneficiary.ABA_Number__c = getStringParam(body, 'abaNumber'); }
            if (body.containsKey('bankAddress')) { beneficiary.Bank_Address__c = getStringParam(body, 'bankAddress'); }
            if (body.containsKey('bankAccountName')) { beneficiary.Bank_Account_Name__c = getStringParam(body, 'bankAccountName'); }

            String currencyParam = getStringParam(body, 'currencyIsoCode');
            if (body.containsKey('currencyIsoCode') && String.isNotBlank(currencyParam)) {
                beneficiary.CurrencyIsoCode = currencyParam;
            }

            String effectiveBankCountry = body.containsKey('bankCountry') ? getStringParam(body, 'bankCountry') : beneficiary.Bank_Country__c;
            String effectiveSortCode = body.containsKey('sortCode') ? getStringParam(body, 'sortCode') : beneficiary.Sort_Code__c;
            String effectiveAbaNumber = body.containsKey('abaNumber') ? getStringParam(body, 'abaNumber') : beneficiary.ABA_Number__c;
            String effectiveIban = body.containsKey('iban') ? getStringParam(body, 'iban') : beneficiary.IBAN__c;
            String effectiveSwiftCode = body.containsKey('swiftCode') ? getStringParam(body, 'swiftCode') : beneficiary.Swift_Code__c;

            List<String> missingRoutingFields = getMissingRoutingFields(
                effectiveBankCountry,
                effectiveSortCode,
                effectiveAbaNumber,
                effectiveIban,
                effectiveSwiftCode
            );
            if (!missingRoutingFields.isEmpty()) {
                sendConditionalFieldError(res, effectiveBankCountry, missingRoutingFields);
                return;
            }

            update beneficiary;

            Bank_Account__c refreshed = [
                SELECT Id, Name, Beneficiary_Name__c, Bank_Name__c, Bank_Account_Number__c,
                       Bank_Country__c, IBAN__c, Swift_Code__c, Sort_Code__c, ABA_Number__c,
                       Bank_Address__c, Bank_Account_Name__c, Verified__c, Active__c,
                       Account__r.Client_Code__c, CurrencyIsoCode, CreatedDate
                FROM Bank_Account__c
                WHERE Id = :beneficiary.Id
                LIMIT 1
            ];

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(mapBeneficiary(refreshed)));

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    private static Map<String, Object> mapBeneficiary(Bank_Account__c b) {
        return new Map<String, Object>{
            'id' => b.Id,
            'name' => b.Name,
            'beneficiaryName' => b.Beneficiary_Name__c,
            'bankName' => b.Bank_Name__c,
            'bankAccountNumber' => b.Bank_Account_Number__c,
            'bankCountry' => b.Bank_Country__c,
            'iban' => b.IBAN__c,
            'swiftCode' => b.Swift_Code__c,
            'sortCode' => b.Sort_Code__c,
            'abaNumber' => b.ABA_Number__c,
            'bankAddress' => b.Bank_Address__c,
            'bankAccountName' => b.Bank_Account_Name__c,
            'verified' => b.Verified__c,
            'active' => b.Active__c,
            'clientCode' => b.Account__r != null ? b.Account__r.Client_Code__c : null,
            'currencyIsoCode' => b.CurrencyIsoCode,
            'createdDate' => b.CreatedDate
        };
    }

    private static String getStringParam(Map<String, Object> body, String key) {
        Object val = body.get(key);
        return val != null ? String.valueOf(val) : null;
    }

    private static List<String> getMissingRoutingFields(
        String bankCountry,
        String sortCode,
        String abaNumber,
        String iban,
        String swiftCode
    ) {
        List<String> missingFields = new List<String>();
        String routingRegion = resolveRoutingRegion(bankCountry);

        if (routingRegion == ROUTING_REGION_UK && String.isBlank(sortCode)) {
            missingFields.add('sortCode');
        } else if (routingRegion == ROUTING_REGION_US && String.isBlank(abaNumber)) {
            missingFields.add('abaNumber');
        } else if (routingRegion == ROUTING_REGION_INTL) {
            if (String.isBlank(iban)) {
                missingFields.add('iban');
            }
            if (String.isBlank(swiftCode)) {
                missingFields.add('swiftCode');
            }
        }

        return missingFields;
    }

    private static String resolveRoutingRegion(String bankCountry) {
        String normalizedCountry = normalizeCountry(bankCountry);
        if (UK_COUNTRY_VALUES.contains(normalizedCountry)) {
            return ROUTING_REGION_UK;
        }
        if (US_COUNTRY_VALUES.contains(normalizedCountry)) {
            return ROUTING_REGION_US;
        }
        return ROUTING_REGION_INTL;
    }

    private static String normalizeCountry(String bankCountry) {
        if (String.isBlank(bankCountry)) {
            return '';
        }
        return bankCountry.trim().toUpperCase();
    }

    private static void sendConditionalFieldError(RestResponse res, String bankCountry, List<String> missingFields) {
        res.statusCode = 400;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'error' => 'Missing required routing fields for bankCountry: ' + bankCountry,
            'errorCode' => 'MISSING_CONDITIONAL_FIELDS',
            'missingFields' => missingFields
        }));
    }

    private static void sendError(RestResponse res, Integer statusCode, String message, String errorCode) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'error' => message,
            'errorCode' => errorCode
        }));
    }
}
