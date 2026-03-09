@IsTest
private class BrdgeDocumentServiceTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Client Ltd',
            Client_Code__c = 'TEST-001',
            Client_Status__c = 'Active',
            CurrencyIsoCode = 'GBP'
        );
        insert testAccount;

        Account otherAccount = new Account(
            Name = 'Other Client Ltd',
            Client_Code__c = 'TEST-002',
            Client_Status__c = 'Active',
            CurrencyIsoCode = 'USD'
        );
        insert otherAccount;

        Trade__c completeTrade = new Trade__c(
            Account__c = testAccount.Id,
            External_Reference__c = 'DOC-COMPLETE-001',
            Buy__c = 'EUR',
            Sell__c = 'GBP',
            Total_Amount__c = 5000,
            Status__c = 'Complete',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now().addDays(-5),
            Processed_Date__c = Datetime.now()
        );
        insert completeTrade;

        Trade__c submittedTrade = new Trade__c(
            Account__c = testAccount.Id,
            External_Reference__c = 'DOC-SUBMITTED-001',
            Buy__c = 'USD',
            Sell__c = 'GBP',
            Total_Amount__c = 10000,
            Status__c = 'Submitted',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now()
        );
        insert submittedTrade;

        Trade__c completeTradeNoDocs = new Trade__c(
            Account__c = testAccount.Id,
            External_Reference__c = 'DOC-COMPLETE-NODOCS-001',
            Buy__c = 'USD',
            Sell__c = 'GBP',
            Total_Amount__c = 2000,
            Status__c = 'Complete',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now().addDays(-3),
            Processed_Date__c = Datetime.now().addDays(-2)
        );
        insert completeTradeNoDocs;

        Trade__c otherClientTrade = new Trade__c(
            Account__c = otherAccount.Id,
            External_Reference__c = 'DOC-OTHER-001',
            Buy__c = 'EUR',
            Sell__c = 'USD',
            Total_Amount__c = 9000,
            Status__c = 'Complete',
            Source__c = 'Web Platform',
            Submitted_Date__c = Datetime.now().addDays(-4),
            Processed_Date__c = Datetime.now().addDays(-3)
        );
        insert otherClientTrade;

        ContentVersion cv = new ContentVersion(
            Title = 'Deal Ticket - DOC-COMPLETE-001',
            PathOnClient = 'Deal_Ticket_DOC_COMPLETE_001.pdf',
            VersionData = Blob.valueOf('PDF content placeholder'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = completeTrade.Id,
            ContentDocumentId = insertedCv.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        ContentVersion mt103 = new ContentVersion(
            Title = 'MT103 Advice DOC-COMPLETE-001',
            PathOnClient = 'MT103_DOC_COMPLETE_001.pdf',
            VersionData = Blob.valueOf('MT103 content placeholder'),
            IsMajorVersion = true
        );
        insert mt103;

        ContentVersion insertedMt103 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :mt103.Id LIMIT 1];
        insert new ContentDocumentLink(
            LinkedEntityId = completeTrade.Id,
            ContentDocumentId = insertedMt103.ContentDocumentId,
            ShareType = 'V'
        );

        ContentVersion otherClientDoc = new ContentVersion(
            Title = 'Other Client Deal Ticket',
            PathOnClient = 'Other_Client_Deal_Ticket.pdf',
            VersionData = Blob.valueOf('Other client content'),
            IsMajorVersion = true
        );
        insert otherClientDoc;

        ContentVersion insertedOtherDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :otherClientDoc.Id LIMIT 1];
        insert new ContentDocumentLink(
            LinkedEntityId = otherClientTrade.Id,
            ContentDocumentId = insertedOtherDoc.ContentDocumentId,
            ShareType = 'V'
        );
    }

    @IsTest
    static void givenCompleteTradeWithDocs_whenListDocuments_thenReturnsMetadataList() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-COMPLETE-001' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(null, res.responseBody);

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> data = (List<Object>) wrapper.get('data');
        System.assertEquals(2, data.size());
        System.assertEquals(2, wrapper.get('totalCount'));

        Set<String> docTypes = new Set<String>();
        for (Object row : data) {
            Map<String, Object> doc = (Map<String, Object>) row;
            System.assertNotEquals(null, doc.get('documentId'));
            System.assertNotEquals(null, doc.get('title'));
            docTypes.add((String) doc.get('docType'));
        }
        System.assert(docTypes.contains('DEAL_TICKET_PDF'));
        System.assert(docTypes.contains('MT103'));
    }

    @IsTest
    static void givenListedDocument_whenDownloadDocument_thenReturnsBase64Response() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-COMPLETE-001' LIMIT 1];
        ContentDocumentLink link = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :trade.Id
            ORDER BY ContentDocument.CreatedDate ASC
            LIMIT 1
        ];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents/' + link.ContentDocumentId;
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(link.ContentDocumentId, result.get('documentId'));
        System.assertEquals(String.valueOf(trade.Id), result.get('tradeId'));
        System.assertNotEquals(null, result.get('fileName'));
        System.assertNotEquals(null, result.get('docType'));
        System.assertNotEquals(null, result.get('body'));
    }

    @IsTest
    static void givenSubmittedTrade_whenListDocuments_thenReturns409() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-SUBMITTED-001' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(409, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('TRADE_NOT_COMPLETE', result.get('errorCode'));
    }

    @IsTest
    static void givenMissingTradeId_whenListDocuments_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_TRADE_ID', result.get('errorCode'));
    }

    @IsTest
    static void givenMissingClientCode_whenListDocuments_thenReturns400() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-COMPLETE-001' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('MISSING_CLIENT_CODE', result.get('errorCode'));
    }

    @IsTest
    static void givenNonExistentTradeId_whenListDocuments_thenReturns404() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', createFakeTradeId());
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('TRADE_NOT_FOUND', result.get('errorCode'));
    }

    @IsTest
    static void givenWrongClientCode_whenListDocuments_thenReturns404() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-COMPLETE-001' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'WRONG-CODE');
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
    }

    @IsTest
    static void givenInvalidTradeIdFormat_whenListDocuments_thenReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', 'not-a-valid-id');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('INVALID_TRADE_ID', result.get('errorCode'));
    }

    @IsTest
    static void givenCompleteTradeWithoutDocuments_whenListDocuments_thenReturnsEmptyData() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-COMPLETE-NODOCS-001' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        List<Object> data = (List<Object>) wrapper.get('data');
        System.assertEquals(0, data.size());
        System.assertEquals(0, wrapper.get('totalCount'));
    }

    @IsTest
    static void givenDocumentNotLinkedToTrade_whenDownload_thenReturns404() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-COMPLETE-001' LIMIT 1];
        Trade__c otherTrade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-OTHER-001' LIMIT 1];
        ContentDocumentLink otherTradeLink = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :otherTrade.Id
            LIMIT 1
        ];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents/' + otherTradeLink.ContentDocumentId;
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(404, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('DOCUMENT_NOT_FOUND', result.get('errorCode'));
    }

    @IsTest
    static void givenInvalidDocumentIdFormat_whenDownload_thenReturns400() {
        Trade__c trade = [SELECT Id FROM Trade__c WHERE External_Reference__c = 'DOC-COMPLETE-001' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/brdge/v1/documents/not-a-valid-document-id';
        req.httpMethod = 'GET';
        req.params.put('clientCode', 'TEST-001');
        req.params.put('tradeId', String.valueOf(trade.Id));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BrdgeDocumentService.getDocument();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals('INVALID_DOCUMENT_ID', result.get('errorCode'));
    }

    private static String createFakeTradeId() {
        Trade__c tempTrade = new Trade__c(
            Account__c = [SELECT Id FROM Account LIMIT 1].Id,
            Buy__c = 'USD',
            Sell__c = 'GBP',
            Total_Amount__c = 1,
            External_Reference__c = 'TEMP-FAKE-' + Datetime.now().getTime()
        );
        insert tempTrade;
        Id fakeId = tempTrade.Id;
        delete tempTrade;
        return String.valueOf(fakeId);
    }
}
