// ============================================================
// SIMULATION - Scenario 2: Staff-initiated (Account created first, form sent to client)
// ============================================================
System.debug('=== SCENARIO 2: STAFF-INITIATED CLIENT ===');

String uniqueSuffix = String.valueOf(DateTime.now().getTime());

// Step 1: Staff creates the Account manually before the client fills the form
Account staffAccount = new Account(
    Name           = '[SIM2] Michael Johnson ' + uniqueSuffix,
    RecordTypeId   = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                         .get('Private_Individual').getRecordTypeId(),
    Client_Type__c = 'Private individual',
    Stage__c       = 'Opportunity'
);
Database.DMLOptions opts = new Database.DMLOptions();
opts.DuplicateRuleHeader.allowSave = true;
Database.insert(staffAccount, opts);
System.debug('Staff Account created: ' + staffAccount.Id);

// Step 2: Staff also pre-creates a Contact on the Account (common scenario)
Contact staffContact = new Contact(
    AccountId  = staffAccount.Id,
    FirstName  = 'Michael',
    LastName   = 'Johnson',
    Email      = 'michael.johnson.' + uniqueSuffix + '@example.com'
);
Database.DMLOptions contactOpts = new Database.DMLOptions();
contactOpts.DuplicateRuleHeader.allowSave = true;
Database.insert(staffContact, contactOpts);
System.debug('Staff Contact pre-created: ' + staffContact.Id);

// Step 3: Staff creates Application linked to the Account (simulates Send Form Link)
Onboarding_Application__c app = new Onboarding_Application__c(
    Client_Type__c       = 'Private individual',
    Status__c            = 'Draft',
    Services_Required__c = 'FX',
    Channel__c           = 'ExperienceCloud',
    Client_Name__c       = '[SIM2] Michael Johnson ' + uniqueSuffix,
    Target_Account__c    = staffAccount.Id
);
insert app;
System.debug('Application created with Target_Account__c: ' + app.Id);

// Step 4: Client fills the form — creates Party with full details
Party__c party = new Party__c(
    Party_Type__c                  = 'Individual',
    First_Name__c                  = 'Michael',
    Last_Name__c                   = 'Johnson',
    Full_Legal_Name__c             = 'Michael Johnson',
    Email__c                       = 'michael.johnson.' + uniqueSuffix + '@example.com',
    Phone__c                       = '+447911123456',
    Mobile__c                      = '+447911123457',
    Date_of_Birth__c               = Date.newInstance(1975, 11, 5),
    Nationality__c                 = 'United States',
    Country_of_Residence__c        = 'United Kingdom',
    Government_ID_Number__c        = 'US123456789',
    Is_PEP__c                      = false,
    Source_of_Wealth__c            = 'Business Income',
    Source_of_Wealth_Explanation__c = 'Director of private limited company'
);
insert party;

Application_Party_Role__c apr = new Application_Party_Role__c(
    Onboarding_Application__c = app.Id,
    Party__c                  = party.Id,
    Role__c                   = 'Applicant',
    Is_Primary__c             = true
);
insert apr;

Party_Address__c addr = new Party_Address__c(
    Party__c       = party.Id,
    Street__c      = '221B Baker Street',
    City__c        = 'London',
    State__c       = 'Greater London',
    Postal_Code__c = 'NW1 6XE',
    Country__c     = 'United Kingdom',
    Address_Type__c = 'Residential',
    Is_Primary__c  = true
);
insert addr;

Risk_Assessment__c ra = new Risk_Assessment__c(
    Onboarding_Application__c              = app.Id,
    Risk_Rating__c                         = 'Medium',
    PEP_Flag__c                            = false,
    Sanctions_Flag__c                      = false,
    EDD_Required__c                        = false,
    Private_Source_of_Wealth__c            = 'Business Income',
    Private_Source_of_Wealth_Explanation__c = 'Director of private limited company',
    Private_Estimated_Transactions_per_Month__c = 10,
    Private_Expected_Monthly_Volume__c     = 50000,
    Private_Geographic_Exposure__c         = 'United States;United Kingdom',
    Private_Intended_Use_of_Account__c     = 'Business FX transfers'
);
insert ra;

System.debug('All related records created. Triggering submission...');

// Step 5: Client submits the form — triggers the flow
app.Status__c = 'Submitted';
update app;

System.debug('Status set to Submitted. Checking results...');

// Step 6: Verify results
Onboarding_Application__c updatedApp = [
    SELECT Id, Status__c, Target_Account__c, Primary_Contact__c
    FROM Onboarding_Application__c WHERE Id = :app.Id
];

System.debug('--- APPLICATION ---');
System.debug('Status:          ' + updatedApp.Status__c);
System.debug('Target Account:  ' + updatedApp.Target_Account__c);
System.debug('Primary Contact: ' + updatedApp.Primary_Contact__c);

// Verify the SAME account was used (not a new one created)
Boolean usedSameAccount = updatedApp.Target_Account__c == staffAccount.Id;
System.debug('Used original staff Account: ' + usedSameAccount);

if (updatedApp.Target_Account__c != null) {
    Account acct = [
        SELECT Id, Name, Client_Type__c, Stage__c,
               Email_for_Notifications__c, Phone,
               BillingStreet, BillingCity, BillingCountry,
               Onboarding_Application__c, Services_Required__c
        FROM Account WHERE Id = :updatedApp.Target_Account__c
    ];
    System.debug('--- ACCOUNT (should be staff-created, now updated with form data) ---');
    System.debug('Id:              ' + acct.Id);
    System.debug('Name:            ' + acct.Name);
    System.debug('Client Type:     ' + acct.Client_Type__c);
    System.debug('Stage:           ' + acct.Stage__c);
    System.debug('Email:           ' + acct.Email_for_Notifications__c);
    System.debug('Phone:           ' + acct.Phone);
    System.debug('Billing Street:  ' + acct.BillingStreet);
    System.debug('Billing City:    ' + acct.BillingCity);
    System.debug('Billing Country: ' + acct.BillingCountry);
    System.debug('Linked to App:   ' + acct.Onboarding_Application__c);

    Integer totalAccounts = [SELECT COUNT() FROM Account WHERE Id = :staffAccount.Id];
    System.debug('Total accounts with staff Id (should be 1, no duplicates): ' + totalAccounts);

    List<Contact> contacts = [
        SELECT Id, FirstName, LastName, Email, Phone, Birthdate, Nationality__c, Source_of_Wealth__c
        FROM Contact WHERE AccountId = :acct.Id
    ];
    System.debug('--- CONTACTS (' + contacts.size() + ', should be 1 — staff contact updated not duplicated) ---');
    for (Contact c : contacts) {
        System.debug('Name: ' + c.FirstName + ' ' + c.LastName
            + ' | Email: ' + c.Email
            + ' | DOB: ' + c.Birthdate
            + ' | Nationality: ' + c.Nationality__c
            + ' | SOW: ' + c.Source_of_Wealth__c);
    }

    System.debug('=== SCENARIO 2 RESULT: ' + (usedSameAccount ? 'SUCCESS' : 'FAILED — wrong account used') + ' ===');
} else {
    System.debug('=== SCENARIO 2 RESULT: FAILED — No Account linked to application ===');
}
