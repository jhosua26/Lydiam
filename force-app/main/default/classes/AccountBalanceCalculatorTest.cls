@IsTest
private class AccountBalanceCalculatorTest {

    // ── Test data setup ───────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Client');
        insert acc;

        List<Trade__c> trades = new List<Trade__c>{
            // GBP sell 1000 (client sold GBP → bought EUR)
            makeTrade(acc.Id, 'GBP', 'EUR', 1000, 'Settled', 'FX'),
            // GBP buy 200 (client sold EUR → bought GBP)
            makeTrade(acc.Id, 'EUR', 'GBP', 200,  'Settled', 'FX'),
            // EUR sell 500
            makeTrade(acc.Id, 'EUR', 'USD', 500,  'Settled', 'FX'),
            // USD buy 300
            makeTrade(acc.Id, 'GBP', 'USD', 300,  'Settled', 'FX'),
            // Crypto trade
            makeTrade(acc.Id, 'GBP', 'USDT', 750, 'Settled', 'Crypto On-ramp'),
            // Pending trade — must NOT affect balances
            makeTrade(acc.Id, 'GBP', 'EUR', 9999, 'Pending', 'FX')
        };
        insert trades;
    }

    private static Trade__c makeTrade(Id accountId, String sell, String buy, Decimal amount, String status, String tradeType) {
        return new Trade__c(
            Account__c      = accountId,
            Sell__c         = sell,
            Buy__c          = buy,
            Total_Amount__c = amount,
            Status__c       = status
            // Trade_Type__c is a formula — cannot be set directly
        );
    }

    // ── Tests ─────────────────────────────────────────────────────────────────

    @IsTest
    static void testBatchCalculatesBalances() {
        Test.startTest();
        AccountBalanceCalculator job = new AccountBalanceCalculator();
        Database.executeBatch(job, 200);
        Test.stopTest();

        Account result = [
            SELECT Balance_GBP__c, Balance_EUR__c, Balance_USD__c,
                   Balance_Crypto__c, Balance_Last_Updated__c
            FROM Account
            WHERE Name = 'Test Client'
            LIMIT 1
        ];

        // GBP net: sold 1000 + 300 = 1300 sell; bought 200 GBP → net = 1300 - 200 = 1100
        System.assertEquals(1100, result.Balance_GBP__c, 'GBP balance should be 1100');

        // EUR net: sold 200 + 500 = 700 sell; bought 1000 EUR → net = 700 - 1000 = -300
        System.assertEquals(-300, result.Balance_EUR__c, 'EUR balance should be -300');

        // USD net: sold 0; bought 300 + 500 = 800 → net = 0 - 800 = -800
        System.assertEquals(-800, result.Balance_USD__c, 'USD balance should be -800');

        // Balance_Last_Updated__c should be set
        System.assertNotEquals(null, result.Balance_Last_Updated__c, 'Balance Last Updated should be set');
    }

    @IsTest
    static void testSchedulableExecutes() {
        Test.startTest();
        String cronExpr = '0 0 1 * * ?';
        System.schedule('Test Balance Calc', cronExpr, new AccountBalanceCalculator());
        Test.stopTest();
        // No assertion needed — verifies no exception thrown during schedule
    }

    @IsTest
    static void testNoSettledTradesLeavesBalancesNull() {
        // Insert an account with only a Pending trade
        Account acc2 = new Account(Name = 'No Settled Trades');
        insert acc2;
        insert new Trade__c(
            Account__c      = acc2.Id,
            Sell__c         = 'GBP',
            Buy__c          = 'EUR',
            Total_Amount__c = 500,
            Status__c       = 'Pending'
        );

        Test.startTest();
        Database.executeBatch(new AccountBalanceCalculator(), 200);
        Test.stopTest();

        Account result = [
            SELECT Balance_GBP__c, Balance_EUR__c, Balance_USD__c,
                   Balance_Crypto__c, Balance_Last_Updated__c
            FROM Account
            WHERE Name = 'No Settled Trades'
            LIMIT 1
        ];

        // Account has no settled trades so it won't be in the batch scope — fields stay null
        System.assertEquals(null, result.Balance_GBP__c,    'Balance GBP should be null');
        System.assertEquals(null, result.Balance_Last_Updated__c, 'Balance Last Updated should be null');
    }

    @IsTest
    static void testEmptyScopeHandledGracefully() {
        // Delete all trades so scope is empty
        delete [SELECT Id FROM Trade__c];

        Test.startTest();
        Database.executeBatch(new AccountBalanceCalculator(), 200);
        Test.stopTest();
        // Verifies no exception when there are no settled trades
    }
}
