@RestResource(urlMapping='/brdge/v1/payments/*')
global with sharing class BrdgePaymentService {

    @HttpGet
    global static void getPayments() {
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

            Id accountId = accounts[0].Id;
            String tradeId = req.params.get('tradeId');
            String statusFilter = req.params.get('status');
            Integer queryLimit = parseIntParam(req.params.get('limit'), 50, 1, 200);
            Integer queryOffset = parseIntParam(req.params.get('offset'), 0, 0, 2000);

            String countSoql = 'SELECT COUNT() FROM Payment__c WHERE Account__c = :accountId';
            String dataSoql = 'SELECT Id, Name, Amount__c, Status__c, Payment_Reference__c, ' +
                'Date_Receivd__c, Description__c, Beneficiary__c, Beneficiary__r.Name, ' +
                'Beneficiary__r.Beneficiary_Name__c, Beneficiary__r.Bank_Name__c, Trade__c, Type__c, ' +
                'CurrencyIsoCode, CreatedDate ' +
                'FROM Payment__c WHERE Account__c = :accountId';

            if (String.isNotBlank(tradeId)) {
                countSoql += ' AND Trade__c = :tradeId';
                dataSoql += ' AND Trade__c = :tradeId';
            }

            if (String.isNotBlank(statusFilter)) {
                countSoql += ' AND Status__c = :statusFilter';
                dataSoql += ' AND Status__c = :statusFilter';
            }

            dataSoql += ' ORDER BY CreatedDate DESC LIMIT :queryLimit OFFSET :queryOffset';

            Integer totalCount = Database.countQuery(countSoql);
            List<Payment__c> payments = Database.query(dataSoql);

            List<Map<String, Object>> results = new List<Map<String, Object>>();
            for (Payment__c p : payments) {
                results.add(mapPayment(p));
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'data' => results,
                'limit' => queryLimit,
                'offset' => queryOffset,
                'totalCount' => totalCount
            }));

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    private static Map<String, Object> mapPayment(Payment__c p) {
        return new Map<String, Object>{
            'id' => p.Id,
            'name' => p.Name,
            'amount' => p.Amount__c,
            'status' => p.Status__c,
            'paymentReference' => p.Payment_Reference__c,
            'dateReceived' => p.Date_Receivd__c,
            'description' => p.Description__c,
            'beneficiaryId' => p.Beneficiary__c,
            'beneficiaryName' => p.Beneficiary__r != null ? p.Beneficiary__r.Beneficiary_Name__c : null,
            'beneficiaryRecordName' => p.Beneficiary__r != null ? p.Beneficiary__r.Name : null,
            'beneficiaryBankName' => p.Beneficiary__r != null ? p.Beneficiary__r.Bank_Name__c : null,
            'tradeId' => p.Trade__c,
            'type' => p.Type__c,
            'currencyIsoCode' => p.CurrencyIsoCode,
            'createdDate' => p.CreatedDate
        };
    }

    private static Integer parseIntParam(String value, Integer defaultVal, Integer minVal, Integer maxVal) {
        if (String.isBlank(value)) {
            return defaultVal;
        }
        try {
            Integer parsed = Integer.valueOf(value);
            return Math.max(minVal, Math.min(maxVal, parsed));
        } catch (Exception e) {
            return defaultVal;
        }
    }

    private static void sendError(RestResponse res, Integer statusCode, String message, String errorCode) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'error' => message,
            'errorCode' => errorCode
        }));
    }
}
