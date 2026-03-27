/**
 * AccountBalanceCalculator
 *
 * Nightly batch job that aggregates settled Trade__c records per Account
 * and updates the running balance currency fields on Account.
 *
 * Balance logic (net position):
 *   GBP/EUR/USD = SUM(Total_Amount__c where Sell = currency) - SUM(Total_Amount__c where Buy = currency)
 *   Crypto      = SUM(Total_Amount__c) for all settled crypto trades
 *
 * Schedule via: System.schedule('Account Balance Nightly', '0 0 1 * * ?', new AccountBalanceCalculator());
 */
public with sharing class AccountBalanceCalculator implements Database.Batchable<SObject>, Schedulable {

    // Currencies handled by dedicated balance fields
    private static final Set<String> FIAT_CURRENCIES = new Set<String>{ 'GBP', 'EUR', 'USD' };
    private static final Set<String> CRYPTO_TRADE_TYPES = new Set<String>{
        'Crypto Off-ramp', 'Crypto On-ramp', 'Crypto-to-Crypto'
    };

    // ── Schedulable ──────────────────────────────────────────────────────────

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountBalanceCalculator(), 50);
    }

    // ── Batchable ─────────────────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Process every Account that has at least one settled Trade
        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            WHERE Id IN (
                SELECT Account__c
                FROM Trade__c
                WHERE Status__c = 'Settled'
                AND Account__c != NULL
            )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Set<Id> accountIds = new Map<Id, Account>(scope).keySet();

        // Aggregate settled trades grouped by Account + Sell currency
        Map<Id, Map<String, Decimal>> sellTotals = aggregateByCurrency(accountIds, 'Sell__c');
        // Aggregate settled trades grouped by Account + Buy currency
        Map<Id, Map<String, Decimal>> buyTotals  = aggregateByCurrency(accountIds, 'Buy__c');
        // Aggregate settled crypto trades grouped by Account
        Map<Id, Decimal> cryptoTotals = aggregateCrypto(accountIds);

        List<Account> toUpdate = new List<Account>();
        Datetime now = Datetime.now();

        for (Account acc : scope) {
            Map<String, Decimal> sold   = sellTotals.containsKey(acc.Id)  ? sellTotals.get(acc.Id)  : new Map<String, Decimal>();
            Map<String, Decimal> bought = buyTotals.containsKey(acc.Id)   ? buyTotals.get(acc.Id)   : new Map<String, Decimal>();

            acc.Balance_GBP__c          = netBalance(sold, bought, 'GBP');
            acc.Balance_EUR__c          = netBalance(sold, bought, 'EUR');
            acc.Balance_USD__c          = netBalance(sold, bought, 'USD');
            acc.Balance_Crypto__c       = cryptoTotals.containsKey(acc.Id) ? cryptoTotals.get(acc.Id) : 0;
            acc.Balance_Last_Updated__c = now;

            toUpdate.add(acc);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // No post-processing required
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    /**
     * Returns Map<AccountId, Map<CurrencyCode, TotalAmount>> for settled trades
     * grouped by a given currency picklist field (Sell__c or Buy__c).
     */
    @TestVisible
    private Map<Id, Map<String, Decimal>> aggregateByCurrency(Set<Id> accountIds, String currencyField) {
        Map<Id, Map<String, Decimal>> result = new Map<Id, Map<String, Decimal>>();

        // Exclude crypto trades — those are aggregated separately into Balance_Crypto__c
        String query =
            'SELECT Account__c, ' + currencyField + ', SUM(Total_Amount__c) total ' +
            'FROM Trade__c ' +
            'WHERE Status__c = \'Settled\' ' +
            'AND Account__c IN :accountIds ' +
            'AND Total_Amount__c != NULL ' +
            'AND Trade_Type__c NOT IN :CRYPTO_TRADE_TYPES ' +
            'GROUP BY Account__c, ' + currencyField;

        for (AggregateResult ar : Database.query(query)) {
            Id    accountId    = (Id)     ar.get('Account__c');
            String currencyCode = (String) ar.get(currencyField);
            Decimal total       = (Decimal) ar.get('total');

            if (currencyCode == null || total == null) {
                continue;
            }

            if (!result.containsKey(accountId)) {
                result.put(accountId, new Map<String, Decimal>());
            }
            result.get(accountId).put(currencyCode, total);
        }

        return result;
    }

    /**
     * Returns Map<AccountId, CryptoTotal> for all settled crypto trades.
     * Sums Total_Amount__c where Trade_Type__c is a crypto variant.
     */
    @TestVisible
    private Map<Id, Decimal> aggregateCrypto(Set<Id> accountIds) {
        Map<Id, Decimal> result = new Map<Id, Decimal>();

        for (AggregateResult ar : [
            SELECT Account__c, SUM(Total_Amount__c) total
            FROM Trade__c
            WHERE Status__c = 'Settled'
            AND Account__c IN :accountIds
            AND Trade_Type__c IN :CRYPTO_TRADE_TYPES
            AND Total_Amount__c != NULL
            GROUP BY Account__c
        ]) {
            Id      accountId = (Id)      ar.get('Account__c');
            Decimal total     = (Decimal) ar.get('total');
            if (accountId != null && total != null) {
                result.put(accountId, total);
            }
        }

        return result;
    }

    /** Net balance = amount sold in currencyCode − amount bought in currencyCode */
    private Decimal netBalance(Map<String, Decimal> sold, Map<String, Decimal> bought, String currencyCode) {
        Decimal sellAmt = sold.containsKey(currencyCode)   ? sold.get(currencyCode)   : 0;
        Decimal buyAmt  = bought.containsKey(currencyCode) ? bought.get(currencyCode) : 0;
        return sellAmt - buyAmt;
    }
}
