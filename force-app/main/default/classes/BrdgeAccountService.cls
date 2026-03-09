@RestResource(urlMapping='/brdge/v1/accounts/*')
global with sharing class BrdgeAccountService {

    @HttpGet
    global static void getAccount() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String clientCode = resolveClientCode(req);

            if (String.isBlank(clientCode)) {
                sendError(res, 400, 'clientCode is required', 'MISSING_CLIENT_CODE');
                return;
            }

            Boolean hasStageField = Account.SObjectType.getDescribe().fields.getMap().containsKey('Stage__c');
            String soql = 'SELECT Id, Name, Client_Code__c, Client_Status__c, ' +
                'Email_for_Notifications__c, Phone, CurrencyIsoCode, CreatedDate';
            if (hasStageField) {
                soql += ', Stage__c';
            }
            soql += ' FROM Account WHERE Client_Code__c = :clientCode LIMIT 1';

            List<SObject> accountRecords = Database.query(soql);

            if (accountRecords.isEmpty()) {
                sendError(res, 404, 'Account not found for clientCode: ' + clientCode, 'ACCOUNT_NOT_FOUND');
                return;
            }

            Account acc = (Account) accountRecords[0];
            Map<String, Object> result = new Map<String, Object>{
                'clientCode' => acc.Client_Code__c,
                'id' => acc.Id,
                'name' => acc.Name,
                'status' => acc.Client_Status__c,
                'email' => acc.Email_for_Notifications__c,
                'phone' => acc.Phone,
                'currency' => acc.CurrencyIsoCode,
                'stage' => hasStageField ? acc.get('Stage__c') : null,
                'createdDate' => acc.CreatedDate
            };

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(result));

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    private static String resolveClientCode(RestRequest req) {
        String clientCodeFromPath = extractClientCodeFromPath(req.requestURI, '/brdge/v1/accounts/');
        if (!String.isBlank(clientCodeFromPath)) {
            return clientCodeFromPath.trim();
        }

        String clientCodeFromQuery = req.params != null ? req.params.get('clientCode') : null;
        return String.isBlank(clientCodeFromQuery) ? null : clientCodeFromQuery.trim();
    }

    private static String extractClientCodeFromPath(String uri, String basePath) {
        if (String.isBlank(uri) || !uri.contains(basePath)) {
            return null;
        }
        String value = uri.substringAfter(basePath);
        if (!String.isBlank(value) && value.endsWith('/')) {
            value = value.substring(0, value.length() - 1);
        }
        return String.isBlank(value) ? null : value;
    }

    private static void sendError(RestResponse res, Integer statusCode, String message, String errorCode) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'error' => message,
            'errorCode' => errorCode
        }));
    }
}
