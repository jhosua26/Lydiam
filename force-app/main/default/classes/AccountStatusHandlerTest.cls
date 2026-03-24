@isTest
public class AccountStatusHandlerTest {
    @testSetup
    static void setupData() {
        List<Account> accounts = new List<Account>();

        Id privateRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Individual').getRecordTypeId();

        accounts.add(new Account(
            RecordTypeId = privateRtId,
            FirstName = 'Test',
            LastName = 'Account1',
            Stage__c = 'Lead',
            Email_for_Notifications__c = 'client1@example.com',
            Client_Code__c = 'LYD123'
        ));

        accounts.add(new Account(
            RecordTypeId = privateRtId,
            FirstName = 'Test',
            LastName = 'Account2',
            Stage__c = 'Lead',
            Email_for_Notifications__c = 'client2@example.com',
            Client_Code__c = 'LYD456'
        ));

        accounts.add(new Account(
            RecordTypeId = privateRtId,
            FirstName = 'Missing',
            LastName = 'EmailAccount',
            Stage__c = 'Lead',
            Email_for_Notifications__c = null,
            Client_Code__c = 'LYD789'
        ));

        insert accounts;
    }

    @isTest
    static void testClientStatusEmailTrigger() {
        // Step 1: Query existing Accounts
        List<Account> accountsToUpdate = [
            SELECT Id, FirstName, LastName, Stage__c, Email_for_Notifications__c, Client_Code__c
            FROM Account
            WHERE Email_for_Notifications__c != null
        ];

        // Step 2: Create a deep copy for oldMap
        Map<Id, Account> oldMap = new Map<Id, Account>();
        for (Account acc : accountsToUpdate) {
            oldMap.put(acc.Id, acc.clone(false, true, false, false));
        }

        // Step 3: Update Stage__c to "Client coded"
        for (Account acc : accountsToUpdate) {
            acc.Stage__c = 'Client coded';
            acc.Compliance_Approved__c = true;
        }
        update accountsToUpdate;

        // Step 4: Call the handler manually to simulate trigger behavior
        List<Account> updatedAccounts = [
            SELECT Id, FirstName, LastName, Name, Stage__c, Email_for_Notifications__c, Client_Code__c
            FROM Account
            WHERE Id IN :accountsToUpdate
        ];

        Test.startTest();
        AccountStatusHandler.handleStatusChange(updatedAccounts, oldMap);
        Test.stopTest();
    }

    @isTest
    static void testNoEmailIfStageNotChanged() {
        List<Account> accounts = [
            SELECT Id, FirstName, LastName,Name, Stage__c, Email_for_Notifications__c, Client_Code__c
            FROM Account
        ];
        Map<Id, Account> oldMap = new Map<Id, Account>();
        for (Account acc : accounts) {
            oldMap.put(acc.Id, acc.clone(false, true, false, false));
        }

        // No change in Stage__c
        Test.startTest();
        AccountStatusHandler.handleStatusChange(accounts, oldMap);
        Test.stopTest();
    }

    @isTest
    static void testSkipAccountsWithNoEmail() {
        // Get the account with missing email
        Account accWithNoEmail = [
            SELECT Id, FirstName, LastName, Stage__c, Email_for_Notifications__c, Client_Code__c
            FROM Account
            WHERE Email_for_Notifications__c = null
            LIMIT 1
        ];

        Account accBefore = accWithNoEmail.clone(false, true, false, false);
        accWithNoEmail.Stage__c = 'Client coded';
        accWithNoEmail.Compliance_Approved__c = true;
        update accWithNoEmail;

        Account accAfter = [
            SELECT Id, FirstName, LastName, Stage__c,Name, Email_for_Notifications__c, Client_Code__c
            FROM Account
            WHERE Id = :accWithNoEmail.Id
        ];

        Test.startTest();
        AccountStatusHandler.handleStatusChange(new List<Account>{accAfter}, new Map<Id, Account>{accAfter.Id => accBefore});
        Test.stopTest();
    }
}