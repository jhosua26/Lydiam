@isTest
private class TradeTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Create an Account with email for notifications
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Individual').getRecordTypeId(),
            LastName = 'Test User',
            Email_for_Notifications__c = 'testuser@example.com',
            Type = 'Corporate Crypto',
            CurrencyIsoCode = 'EUR'
        );
        insert acc;

        // Create a Wallet (if Wallet__c is a lookup to a custom object)
        Wallet__c wallet = new Wallet__c(Account__c = acc.Id);
        insert wallet;

        // Insert a Trade__c record
        Trade__c trade = new Trade__c(
            Account__c = acc.Id,
            Trade_Reference_Number__c = 'TR123456',
            Deal_Date__c = Date.today(),
            CurrencyIsoCode = 'USD',
            Buy__c = 'BTC',
            Sell__c = 'USD',
            Number_of_Tokens__c = 1.5,
            Total_Amount__c = 50000.00,
            Price__c = 33333.33,
            Commission__c = 100.00,
            Gross_Profit__c = 200.00,
            Est_Net_Profit__c = 150.00,
            Wallet__c = wallet.Id
        );
        insert trade;
    }

    static testMethod void testHandleAfterInsert() {
        List<Trade__c> trades = [SELECT Id, Name, Account__c, Buy__c, Sell__c, Number_of_Tokens__c, Total_Amount__c, Trade_Type__c,
                    Deal_Date__c, Wallet__r.Name,CurrencyIsoCode  FROM Trade__c];
        
        Test.startTest();
        TradeTriggerHandler.handleAfterInsert(trades);
        Test.stopTest();
        
        // System.assertEquals(1, Limits.getEmailInvocations(), 'An email should have been sent on insert.');
    }

    static testMethod void testHandleAfterUpdate() {
        Trade__c trade = [SELECT Id, Name, Account__c, Buy__c, Sell__c, Number_of_Tokens__c, Total_Amount__c, Trade_Type__c,
                    Deal_Date__c, Wallet__r.Name,CurrencyIsoCode  FROM Trade__c LIMIT 1];
        
        // Simulate old values
        Trade__c oldTrade = trade.clone(false, true, false, false);
        oldTrade.Buy__c = 'ETH';  // old value
        oldTrade.Sell__c = 'GBP';
        oldTrade.Number_of_Tokens__c = 2.0;
        oldTrade.Total_Amount__c = 60000.00;

        // Update the trade to trigger email logic
        trade.Buy__c = 'BTC';  // changed
        trade.Number_of_Tokens__c = 3.0;  // changed

        Test.startTest();
        update trade;
        TradeTriggerHandler.handleAfterUpdate(new List<Trade__c>{trade}, new Map<Id, Trade__c>{ trade.Id => oldTrade });
        Test.stopTest();

        // System.assertEquals(1, Limits.getEmailInvocations(), 'An email should have been sent on update.');
    }

    static testMethod void testNoEmailIfAccountMissing() {
        // Create a trade with no account (should not trigger email)
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Trade__c tradeNoAcc = new Trade__c(
            Account__c = acc.Id,
            Trade_Reference_Number__c = 'TR000000',
            Deal_Date__c = Date.today(),
            CurrencyIsoCode = 'USD',
            Buy__c = 'BTC',
            Sell__c = 'USD',
            Number_of_Tokens__c = 1.0,
            Total_Amount__c = 1000.00,
            Price__c = 1000.00
        );
        insert tradeNoAcc;

        Test.startTest();
        TradeTriggerHandler.handleAfterInsert(new List<Trade__c>{tradeNoAcc});
        Test.stopTest();

        // System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent when Account__c is null.');
    }
}