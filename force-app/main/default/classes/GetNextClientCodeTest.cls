@isTest
private class GetNextClientCodeTest {

    @isTest
    static void testGetNextCode_NoExistingCodes() {
        GetNextClientCode.Request req = new GetNextClientCode.Request();
        req.accountId = null;
        List<GetNextClientCode.Result> results = GetNextClientCode.getNextCode(
            new List<GetNextClientCode.Request>{ req }
        );
        System.assertEquals(1, results.size());
        System.assertEquals('28786001', results[0].nextClientCode);
    }

    @isTest
    static void testGetNextCode_WithExistingCodes() {
        Account acc = new Account(
            Name = 'Test Client',
            Client_Code__c = '28786010'
        );
        insert acc;

        GetNextClientCode.Request req = new GetNextClientCode.Request();
        req.accountId = acc.Id;
        List<GetNextClientCode.Result> results = GetNextClientCode.getNextCode(
            new List<GetNextClientCode.Request>{ req }
        );
        System.assertEquals(1, results.size());
        System.assertEquals('28786011', results[0].nextClientCode);
    }

    @isTest
    static void testGetNextCode_PaddingLogic() {
        Account acc = new Account(
            Name = 'Test Client 2',
            Client_Code__c = '28786009'
        );
        insert acc;

        GetNextClientCode.Request req = new GetNextClientCode.Request();
        List<GetNextClientCode.Result> results = GetNextClientCode.getNextCode(
            new List<GetNextClientCode.Request>{ req }
        );
        System.assertEquals('28786010', results[0].nextClientCode);
    }
}
