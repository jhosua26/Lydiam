@RestResource(urlMapping='/accounts/v1/*')
global with sharing class GetDataWebhook {

    @HttpGet
    global static void getAccountData() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Extract clientCode from URL or query param
            String clientCode;
            if (req.requestURI != null && req.requestURI.contains('/accounts/v1/')) {
                clientCode = req.requestURI.substringAfter('/accounts/v1/');
            } else {
                clientCode = req.params.get('clientCode');
            }

            if (String.isBlank(clientCode)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Missing Client Code in request');
                return;
            }

            // Fetch Account safely
            List<Account> accounts = [
                SELECT Id, Name, Phone, Email_for_Notifications__c, CurrencyIsoCode, CreatedDate
                FROM Account
                WHERE Client_Code__c = :clientCode
                LIMIT 1
            ];

            if (accounts.isEmpty()) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf('Account not found for Client Code: ' + clientCode);
                return;
            }

            Account acc = accounts[0];

            // Fetch Payments
            List<Payment__c> payments = [
                SELECT Id, Name, Amount__c, Type__c, Status__c, Beneficiary__c, CreatedDate
                FROM Payment__c
                WHERE Account__c = :acc.Id
                ORDER BY CreatedDate DESC
            ];

            // Fetch Trades
            List<Trade__c> trades = [
                SELECT Id, Name, Trade_Type__c, Number_of_Tokens__c, Total_Amount__c, Price__c, 
                       Trade_Reference_Number__c, CreatedDate, Transaction_Fee__c
                FROM Trade__c
                WHERE Account__c = :acc.Id
                ORDER BY CreatedDate DESC
            ];

            // Structure Response
            Map<String, Object> result = new Map<String, Object>{
                'account' => new Map<String, Object>{
                    'id' => acc.Id,
                    'name' => acc.Name,
                    'phone' => acc.Phone,
                    'email' => acc.Email_for_Notifications__c,
                    'currency' => acc.CurrencyIsoCode,
                    'createdDate' => acc.CreatedDate
                },
                'payments' => payments,
                'trades' => trades
            };

            // Return JSON
            res.statusCode = 200;
            res.addHeader('Content-Type', 'application/json');
            res.responseBody = Blob.valueOf(JSON.serializePretty(result));

        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
}