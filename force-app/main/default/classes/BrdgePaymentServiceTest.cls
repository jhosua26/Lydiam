@IsTest
private class BrdgePaymentServiceTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Client Ltd',
            Client_Code__c = 'TEST-001',
            Client_Status__c = 'Active',
            CurrencyIsoCode = 'GBP'
        );
        insert testAccount;

        Trade__c testTrade = new Trade__c(
            Account__c = testAccount.Id,
            External_Reference__c = 'BRDGE-TRADE-001',
            Buy__c = 'USD',
            Sell__c = 'GBP',
            Total_Amount__c = 10000,
            Status__c = 'Complete',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now()
        );
        insert testTrade;

        Bank_Account__c beneficiary = new Bank_Account__c(
            Account__c = testAccount.Id,
            Beneficiary_Name__c = 'Acme Treasury',
            Bank_Name__c = 'HSBC',
            Bank_Account_Number__c = '12345678',
            Bank_Country__c = 'United Kingdom',
            Active__c = true,
            Verified__c = true,
            Sort_Code__c = '10-20-30'
        );
        insert beneficiary;

        Payment__c receivedPayment = new Payment__c(
            Account__c = testAccount.Id,
            Trade__c = testTrade.Id,
            Beneficiary__c = beneficiary.Id,
            Amount__c = 5000,
            Status__c = 'New',
            Type__c = 'Received',
            Payment_Reference__c = 'PAY-001',
            Description__c = 'First payment'
        );
        insert receivedPayment;

        Payment__c pendingPayment = new Payment__c(
            Account__c = testAccount.Id,
            Amount__c = 3000,
            Status__c = 'Verified',
            Type__c = 'Paid Out',
            Payment_Reference__c = 'PAY-002',
            Description__c = 'Pending payment'
        );
        insert pendingPayment;
    }

    // --- Positive Cases ---

    @IsTest
    static void givenValidClientCode_whenGetPayments_thenReturnsPaymentList() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/payments';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgePaymentService.getPayments();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> results = (List<Object>) wrapper.get('data');
        System.assertEquals(2, results.size());
        System.assertEquals(50, wrapper.get('limit'));
        System.assertEquals(0, wrapper.get('offset'));
        System.assertEquals(2, wrapper.get('totalCount'));

        Boolean foundBeneficiaryDetails = false;
        for (Object item : results) {
            Map<String, Object> payment = (Map<String, Object>) item;
            if ('PAY-001' == (String) payment.get('paymentReference')) {
                System.assertEquals('Acme Treasury', payment.get('beneficiaryName'));
                System.assertEquals('HSBC', payment.get('beneficiaryBankName'));
                foundBeneficiaryDetails = true;
            }
        }
        System.assertEquals(true, foundBeneficiaryDetails, 'Expected beneficiary details in payment response');
    }

    @IsTest
    static void givenTradeIdFilter_whenGetPayments_thenReturnsFilteredList() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'BRDGE-TRADE-001' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/payments';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', trade.Id);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgePaymentService.getPayments();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> results = (List<Object>) wrapper.get('data');
        System.assertEquals(1, results.size());
        System.assertEquals(1, wrapper.get('totalCount'));

        Map<String, Object> payment = (Map<String, Object>) results[0];
        System.assertEquals('PAY-001', payment.get('paymentReference'));
    }

    @IsTest
    static void givenStatusFilter_whenGetPayments_thenReturnsFilteredList() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/payments';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('status', 'Verified');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgePaymentService.getPayments();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> results = (List<Object>) wrapper.get('data');
        System.assertEquals(1, results.size());

        Map<String, Object> payment = (Map<String, Object>) results[0];
        System.assertEquals('Verified', payment.get('status'));
    }

    @IsTest
    static void givenLimitAndOffset_whenGetPayments_thenReturnsPaginatedResults() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/payments';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('limit', '1');
        req.params.put('offset', '0');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgePaymentService.getPayments();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> results = (List<Object>) wrapper.get('data');
        System.assertEquals(1, results.size(), 'Should return only 1 record when limit=1');
        System.assertEquals(1, wrapper.get('limit'));
        System.assertEquals(0, wrapper.get('offset'));
        System.assertEquals(2, wrapper.get('totalCount'), 'Total count should reflect all matching records');
    }

    // --- Negative Cases ---

    @IsTest
    static void givenMissingClientCode_whenGetPayments_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/payments';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgePaymentService.getPayments();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CLIENT_CODE', result.get('errorCode'));
    }

    @IsTest
    static void givenNonExistentClientCode_whenGetPayments_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/payments';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'NONEXISTENT');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgePaymentService.getPayments();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('ACCOUNT_NOT_FOUND', result.get('errorCode'));
    }
}
