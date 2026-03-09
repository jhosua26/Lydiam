@RestResource(urlMapping='/brdge/v1/documents/*')
global with sharing class BrdgeDocumentService {
    private static final String BASE_PATH = '/brdge/v1/documents/';
    private static final String DOC_TYPE_DEAL_TICKET = 'DEAL_TICKET_PDF';
    private static final String DOC_TYPE_MT103 = 'MT103';
    private static final String DOC_TYPE_BANKING = 'BANKING_DOCUMENT';
    private static final String DOC_TYPE_OTHER = 'OTHER';

    @HttpGet
    global static void getDocument() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String pathDocumentId = extractPathDocumentId(req.requestURI);
            String clientCode = req.params.get('clientCode');
            String tradeId = req.params.get('tradeId');

            if (String.isBlank(clientCode)) {
                sendError(res, 400, 'clientCode is required', 'MISSING_CLIENT_CODE');
                return;
            }

            if (String.isBlank(pathDocumentId)) {
                listDocuments(req, res, clientCode, tradeId);
            } else {
                downloadDocument(req, res, clientCode, tradeId, pathDocumentId);
            }

        } catch (Exception e) {
            sendError(res, 500, e.getMessage(), 'INTERNAL_ERROR');
        }
    }

    private static void listDocuments(RestRequest req, RestResponse res, String clientCode, String tradeIdParam) {
        if (String.isBlank(tradeIdParam)) {
            sendError(res, 400, 'tradeId query parameter is required', 'MISSING_TRADE_ID');
            return;
        }

        Id tradeRecordId = parseIdOrSendError(res, tradeIdParam, 'tradeId must be a valid Salesforce Id', 'INVALID_TRADE_ID');
        if (tradeRecordId == null) {
            return;
        }

        Trade__c trade = resolveTradeForClientOrSendError(res, tradeRecordId, clientCode);
        if (trade == null) {
            return;
        }

        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId,
                   ContentDocument.Title,
                   ContentDocument.FileType,
                   ContentDocument.CreatedDate,
                   ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :trade.Id
            ORDER BY ContentDocument.CreatedDate DESC
        ];

        List<Map<String, Object>> documents = new List<Map<String, Object>>();
        for (ContentDocumentLink link : docLinks) {
            documents.add(new Map<String, Object>{
                'documentId' => link.ContentDocumentId,
                'tradeId' => trade.Id,
                'title' => link.ContentDocument.Title,
                'fileType' => link.ContentDocument.FileType,
                'docType' => resolveDocType(link.ContentDocument.Title, link.ContentDocument.FileType),
                'createdDate' => link.ContentDocument.CreatedDate
            });
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'data' => documents,
            'totalCount' => documents.size()
        }));
    }

    private static void downloadDocument(
        RestRequest req,
        RestResponse res,
        String clientCode,
        String tradeIdParam,
        String pathDocumentId
    ) {
        if (String.isBlank(tradeIdParam)) {
            sendError(res, 400, 'tradeId query parameter is required', 'MISSING_TRADE_ID');
            return;
        }

        Id tradeRecordId = parseIdOrSendError(res, tradeIdParam, 'tradeId must be a valid Salesforce Id', 'INVALID_TRADE_ID');
        if (tradeRecordId == null) {
            return;
        }

        Trade__c trade = resolveTradeForClientOrSendError(res, tradeRecordId, clientCode);
        if (trade == null) {
            return;
        }

        Id documentId = parseIdOrSendError(res, pathDocumentId, 'documentId must be a valid Salesforce Id', 'INVALID_DOCUMENT_ID');
        if (documentId == null) {
            return;
        }

        List<ContentDocumentLink> linkCheck = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :trade.Id
              AND ContentDocumentId = :documentId
            LIMIT 1
        ];
        if (linkCheck.isEmpty()) {
            sendError(res, 404, 'Document not found for this trade', 'DOCUMENT_NOT_FOUND');
            return;
        }

        List<ContentVersion> versions = [
            SELECT ContentDocumentId, Title, VersionData, FileType, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId = :documentId
              AND IsLatest = true
            LIMIT 1
        ];
        if (versions.isEmpty()) {
            sendError(res, 404, 'Document content is not available', 'DOCUMENT_CONTENT_NOT_FOUND');
            return;
        }

        ContentVersion version = versions[0];
        String extension = String.isBlank(version.FileExtension) ? version.FileType : version.FileExtension.toLowerCase();
        String contentType = extension == 'pdf' ? 'application/pdf' : 'application/octet-stream';
        String fileName = String.isBlank(version.FileExtension)
            ? version.Title
            : version.Title + '.' + version.FileExtension.toLowerCase();

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'documentId' => version.ContentDocumentId,
            'tradeId' => trade.Id,
            'fileName' => fileName,
            'title' => version.Title,
            'fileType' => version.FileType,
            'docType' => resolveDocType(version.Title, version.FileType),
            'contentType' => contentType,
            'body' => EncodingUtil.base64Encode(version.VersionData)
        }));
    }

    private static Trade__c resolveTradeForClientOrSendError(RestResponse res, Id tradeId, String clientCode) {
        List<Trade__c> trades = [
            SELECT Id, Status__c
            FROM Trade__c
            WHERE Id = :tradeId
              AND Account__r.Client_Code__c = :clientCode
            LIMIT 1
        ];
        if (trades.isEmpty()) {
            sendError(res, 404, 'Trade not found', 'TRADE_NOT_FOUND');
            return null;
        }

        Trade__c trade = trades[0];
        if (trade.Status__c != 'Complete') {
            sendError(res, 409, 'Documents are only available for completed trades', 'TRADE_NOT_COMPLETE');
            return null;
        }
        return trade;
    }

    private static Id parseIdOrSendError(RestResponse res, String inputValue, String message, String errorCode) {
        try {
            return Id.valueOf(inputValue);
        } catch (Exception e) {
            sendError(res, 400, message, errorCode);
            return null;
        }
    }

    private static String extractPathDocumentId(String uri) {
        if (String.isBlank(uri) || !uri.contains(BASE_PATH)) {
            return null;
        }
        String afterBase = uri.substringAfter(BASE_PATH);
        if (String.isBlank(afterBase)) {
            return null;
        }
        String segment = afterBase.substringBefore('/');
        return String.isBlank(segment) ? null : segment;
    }

    private static String resolveDocType(String title, String fileType) {
        String normalizedTitle = String.isBlank(title) ? '' : title.toLowerCase();
        String normalizedFileType = String.isBlank(fileType) ? '' : fileType.toLowerCase();

        if (normalizedTitle.contains('mt103')) {
            return DOC_TYPE_MT103;
        }
        if (normalizedTitle.contains('deal') && normalizedTitle.contains('ticket') && normalizedFileType == 'pdf') {
            return DOC_TYPE_DEAL_TICKET;
        }
        if (
            normalizedTitle.contains('bank') ||
            normalizedTitle.contains('swift') ||
            normalizedTitle.contains('wire')
        ) {
            return DOC_TYPE_BANKING;
        }
        return DOC_TYPE_OTHER;
    }

    private static void sendError(RestResponse res, Integer statusCode, String message, String errorCode) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'error' => message,
            'errorCode' => errorCode
        }));
    }
}
