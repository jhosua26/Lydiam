@RestResource(urlMapping='/brdge/v1/deals/*')
global with sharing class BrdgeDealTicketService {

    @HttpPost
    global static void createDeal() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            List<String> missingFields = new List<String>();
            String externalReference = getStringParam(body, 'externalReference');
            String clientCode = getStringParam(body, 'clientCode');
            String buyCurrency = getStringParam(body, 'buyCurrency');
            String sellCurrency = getStringParam(body, 'sellCurrency');
            Object amountObj = body.get('amount');

            if (String.isBlank(externalReference)) { missingFields.add('externalReference'); }
            if (String.isBlank(clientCode)) { missingFields.add('clientCode'); }
            if (String.isBlank(buyCurrency)) { missingFields.add('buyCurrency'); }
            if (String.isBlank(sellCurrency)) { missingFields.add('sellCurrency'); }
            if (amountObj == null) { missingFields.add('amount'); }

            if (!missingFields.isEmpty()) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'error' => 'Missing required fields: ' + String.join(missingFields, ', '),
                    'errorCode' => 'MISSING_REQUIRED_FIELDS',
                    'missingFields' => missingFields
                }));
                return;
            }

            Decimal amount;
            try {
                amount = Decimal.valueOf(String.valueOf(amountObj));
            } catch (Exception e) {
                sendError(res, 400, 'amount must be a valid number', 'INVALID_AMOUNT');
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

            List<Trade__c> existingTrades = [
                SELECT Id, Status__c, Account__c FROM Trade__c
                WHERE External_Reference__c = :externalReference
                LIMIT 1
            ];

            Boolean existedBefore = !existingTrades.isEmpty();

            if (existedBefore) {
                if (existingTrades[0].Account__c != accountId) {
                    sendError(res, 409, 'externalReference is already used by another client', 'EXTERNAL_REFERENCE_ACCOUNT_CONFLICT');
                    return;
                }

                Set<String> lockedStatuses = new Set<String>{
                    'In Review', 'In Progress', 'Complete', 'Cancelled'
                };
                if (lockedStatuses.contains(existingTrades[0].Status__c)) {
                    sendError(res, 409, 'Cannot update a deal that is past Submitted status', 'INVALID_STATUS_TRANSITION');
                    return;
                }
            }

            Trade__c trade = new Trade__c(
                Account__c = accountId,
                External_Reference__c = externalReference,
                Buy__c = buyCurrency,
                Sell__c = sellCurrency,
                Total_Amount__c = amount,
                Status__c = 'Submitted',
                Source__c = 'Web Platform',
                Submitted_Date__c = Datetime.now()
            );

            String clientBankIncomingId = getStringParam(body, 'clientBankIncomingId');
            String clientBankOutgoingId = getStringParam(body, 'clientBankOutgoingId');

            Set<Id> bankIdsToValidate = new Set<Id>();
            Id incomingBankId;
            Id outgoingBankId;
            try {
                if (String.isNotBlank(clientBankIncomingId)) {
                    incomingBankId = Id.valueOf(clientBankIncomingId);
                    bankIdsToValidate.add(incomingBankId);
                }
                if (String.isNotBlank(clientBankOutgoingId)) {
                    outgoingBankId = Id.valueOf(clientBankOutgoingId);
                    bankIdsToValidate.add(outgoingBankId);
                }
            } catch (Exception e) {
                sendError(res, 400, 'clientBankIncomingId/clientBankOutgoingId must be valid Salesforce Id values', 'INVALID_BANK_ACCOUNT_ID');
                return;
            }

            if (!bankIdsToValidate.isEmpty()) {
                List<Bank_Account__c> validBanks = [
                    SELECT Id
                    FROM Bank_Account__c
                    WHERE Id IN :bankIdsToValidate
                      AND Account__c = :accountId
                ];

                if (validBanks.size() != bankIdsToValidate.size()) {
                    sendError(res, 404, 'One or more bank accounts do not belong to this client', 'BANK_ACCOUNT_NOT_FOUND_FOR_CLIENT');
                    return;
                }

                if (incomingBankId != null) {
                    trade.Client_Bank_Incoming__c = incomingBankId;
                }
                if (outgoingBankId != null) {
                    trade.Client_Bank_Outgoing__c = outgoingBankId;
                }
            }

            String clientNotes = getStringParam(body, 'clientNotes');
            if (String.isNotBlank(clientNotes)) {
                trade.Client_Notes__c = clientNotes;
            }

            Schema.SObjectField extRefField = Trade__c.Fields.External_Reference__c;
            Database.UpsertResult upsertResult = Database.upsert(trade, extRefField, false);

            if (!upsertResult.isSuccess()) {
                Database.Error firstError = upsertResult.getErrors()[0];
                if (firstError.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
                    sendError(res, 409, 'Conflict: duplicate External_Reference__c', 'UPSERT_CONFLICT');
                    return;
                }
                sendError(res, 500, firstError.getMessage(), 'DML_ERROR');
                return;
            }

            Integer statusCode = existedBefore ? 200 : 201;

            res.statusCode = statusCode;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'tradeId' => trade.Id,
                'externalReference' => trade.External_Reference__c,
                'status' => trade.Status__c
            }));

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    @HttpGet
    global static void getDeals() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String clientCode = req.params.get('clientCode');
            String externalRef = extractExternalRefFromPath(req.requestURI);

            if (String.isNotBlank(externalRef)) {
                getSingleDeal(res, externalRef, clientCode);
            } else {
                listDeals(res, clientCode, req.params.get('status'), req.params);
            }

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    @HttpPatch
    global static void cancelDeal() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String externalRef = extractExternalRefForCancel(req.requestURI);
            String clientCode = req.params.get('clientCode');

            if (String.isBlank(clientCode)) {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
                clientCode = getStringParam(body, 'clientCode');
            }

            if (String.isBlank(externalRef) || String.isBlank(clientCode)) {
                sendError(res, 400, 'externalReference and clientCode are required', 'MISSING_REQUIRED_FIELDS');
                return;
            }

            List<Trade__c> trades = [
                SELECT Id, External_Reference__c, Status__c
                FROM Trade__c
                WHERE External_Reference__c = :externalRef
                  AND Account__r.Client_Code__c = :clientCode
                LIMIT 1
            ];

            if (trades.isEmpty()) {
                sendError(res, 404, 'Deal not found', 'DEAL_NOT_FOUND');
                return;
            }

            Trade__c trade = trades[0];

            if (trade.Status__c != 'Submitted') {
                sendError(res, 409, 'Only deals in Submitted status can be cancelled', 'INVALID_STATUS_TRANSITION');
                return;
            }

            trade.Status__c = 'Cancelled';
            update trade;

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'tradeId' => trade.Id,
                'externalReference' => trade.External_Reference__c,
                'status' => 'Cancelled'
            }));

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    private static void getSingleDeal(RestResponse res, String externalRef, String clientCode) {
        if (String.isBlank(clientCode)) {
            sendError(res, 400, 'clientCode query parameter is required', 'MISSING_CLIENT_CODE');
            return;
        }

        List<Trade__c> trades = [
            SELECT Id, Name, External_Reference__c, Trade_Type__c, Buy__c, Sell__c,
                   Total_Amount__c, Number_of_Tokens__c, Price__c, Transaction_Fee__c,
                   Deal_Date__c, Status__c, Source__c, Submitted_Date__c, Processed_Date__c,
                   Trade_Reference_Number__c, Client_Notes__c, Rejection_Reason__c,
                   Client_Bank_Incoming__c, Client_Bank_Incoming__r.Name, Client_Bank_Incoming__r.Bank_Name__c,
                   Client_Bank_Outgoing__c, Client_Bank_Outgoing__r.Name, Client_Bank_Outgoing__r.Bank_Name__c,
                   Account_Client_Code__c, CurrencyIsoCode, CreatedDate
            FROM Trade__c
            WHERE External_Reference__c = :externalRef
              AND Account__r.Client_Code__c = :clientCode
            LIMIT 1
        ];

        if (trades.isEmpty()) {
            sendError(res, 404, 'Deal not found', 'DEAL_NOT_FOUND');
            return;
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(mapTradeDetail(trades[0])));
    }

    private static void listDeals(RestResponse res, String clientCode, String statusFilter, Map<String, String> params) {
        if (String.isBlank(clientCode)) {
            sendError(res, 400, 'clientCode query parameter is required', 'MISSING_CLIENT_CODE');
            return;
        }

        Integer queryLimit = parseIntParam(params.get('limit'), 50, 1, 200);
        Integer queryOffset = parseIntParam(params.get('offset'), 0, 0, 2000);

        String countSoql = 'SELECT COUNT() FROM Trade__c WHERE Account__r.Client_Code__c = :clientCode AND Source__c = \'Web Platform\'';
        String dataSoql = 'SELECT Id, Name, External_Reference__c, Trade_Type__c, Buy__c, Sell__c, ' +
            'Total_Amount__c, Number_of_Tokens__c, Price__c, Transaction_Fee__c, ' +
            'Deal_Date__c, Status__c, Source__c, Submitted_Date__c, Processed_Date__c, ' +
            'Trade_Reference_Number__c, Client_Notes__c, Rejection_Reason__c, Account_Client_Code__c, CurrencyIsoCode, CreatedDate ' +
            'FROM Trade__c WHERE Account__r.Client_Code__c = :clientCode AND Source__c = \'Web Platform\'';

        if (String.isNotBlank(statusFilter)) {
            countSoql += ' AND Status__c = :statusFilter';
            dataSoql += ' AND Status__c = :statusFilter';
        }

        dataSoql += ' ORDER BY Submitted_Date__c DESC NULLS LAST, CreatedDate DESC LIMIT :queryLimit OFFSET :queryOffset';

        Integer totalCount = Database.countQuery(countSoql);
        List<Trade__c> trades = Database.query(dataSoql);

        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (Trade__c t : trades) {
            results.add(mapTradeSummary(t));
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'data' => results,
            'limit' => queryLimit,
            'offset' => queryOffset,
            'totalCount' => totalCount
        }));
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

    private static Map<String, Object> mapTradeDetail(Trade__c t) {
        Map<String, Object> m = mapTradeSummary(t);
        m.put('clientBankIncomingId', t.Client_Bank_Incoming__c);
        m.put('clientBankOutgoingId', t.Client_Bank_Outgoing__c);
        m.put('clientBankIncomingName', t.Client_Bank_Incoming__r != null ? t.Client_Bank_Incoming__r.Name : null);
        m.put('clientBankIncomingBankName', t.Client_Bank_Incoming__r != null ? t.Client_Bank_Incoming__r.Bank_Name__c : null);
        m.put('clientBankOutgoingName', t.Client_Bank_Outgoing__r != null ? t.Client_Bank_Outgoing__r.Name : null);
        m.put('clientBankOutgoingBankName', t.Client_Bank_Outgoing__r != null ? t.Client_Bank_Outgoing__r.Bank_Name__c : null);
        m.put('source', t.Source__c);
        return m;
    }

    private static Map<String, Object> mapTradeSummary(Trade__c t) {
        return new Map<String, Object>{
            'id' => t.Id,
            'externalReference' => t.External_Reference__c,
            'name' => t.Name,
            'tradeType' => t.Trade_Type__c,
            'buyCurrency' => t.Buy__c,
            'sellCurrency' => t.Sell__c,
            'amountSold' => t.Total_Amount__c,
            'amountBought' => t.Number_of_Tokens__c,
            'rate' => t.Price__c,
            'transactionFee' => t.Transaction_Fee__c,
            'dealDate' => t.Deal_Date__c,
            'status' => t.Status__c,
            'source' => t.Source__c,
            'submittedDate' => t.Submitted_Date__c,
            'processedDate' => t.Processed_Date__c,
            'tradeReferenceNumber' => t.Trade_Reference_Number__c,
            'clientNotes' => t.Client_Notes__c,
            'rejectionReason' => t.Rejection_Reason__c,
            'accountClientCode' => t.Account_Client_Code__c,
            'currencyIsoCode' => t.CurrencyIsoCode,
            'createdDate' => t.CreatedDate
        };
    }

    private static String extractExternalRefFromPath(String uri) {
        if (String.isBlank(uri)) {
            return null;
        }
        String afterBase = uri.substringAfter('/brdge/v1/deals/');
        if (String.isBlank(afterBase) || afterBase == 'deals') {
            return null;
        }
        return afterBase;
    }

    private static String extractExternalRefForCancel(String uri) {
        if (String.isBlank(uri) || !uri.contains('/cancel')) {
            return null;
        }
        String afterBase = uri.substringAfter('/brdge/v1/deals/');
        if (String.isBlank(afterBase)) {
            return null;
        }
        return afterBase.substringBefore('/cancel');
    }

    private static String getStringParam(Map<String, Object> body, String key) {
        Object val = body.get(key);
        return val != null ? String.valueOf(val) : null;
    }

    private static void sendError(RestResponse res, Integer statusCode, String message, String errorCode) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'error' => message,
            'errorCode' => errorCode
        }));
    }
}
