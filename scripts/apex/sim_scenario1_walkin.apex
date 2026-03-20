// ============================================================
// SIMULATION - Scenario 1: Walk-in client (no pre-existing Account)
// ============================================================
System.debug('=== SCENARIO 1: WALK-IN CLIENT ===');

// Step 1: Create Application (Draft first, then flip to Submitted to trigger flow)
Onboarding_Application__c app = new Onboarding_Application__c(
    Client_Type__c       = 'Private individual',
    Status__c            = 'Draft',
    Services_Required__c = 'FX',
    Channel__c           = 'ExperienceCloud',
    Client_Name__c       = '[SIM1] Jane Smith'
);
insert app;
System.debug('Application created: ' + app.Id);

// Step 2: Create Party (applicant personal details)
Party__c party = new Party__c(
    Party_Type__c                  = 'Individual',
    First_Name__c                  = 'Jane',
    Last_Name__c                   = 'Smith',
    Full_Legal_Name__c             = 'Jane Smith',
    Email__c                       = 'jane.smith.sim1@example.com',
    Phone__c                       = '+447700900000',
    Mobile__c                      = '+447700900001',
    Date_of_Birth__c               = Date.newInstance(1988, 3, 22),
    Nationality__c                 = 'United Kingdom',
    Country_of_Residence__c        = 'United Kingdom',
    Government_ID_Number__c        = 'PP778899',
    Is_PEP__c                      = false,
    Source_of_Wealth__c            = 'Employment',
    Source_of_Wealth_Explanation__c = 'Software engineer at a tech company'
);
insert party;

// Step 3: Link Party to Application via Role
Application_Party_Role__c apr = new Application_Party_Role__c(
    Onboarding_Application__c = app.Id,
    Party__c                  = party.Id,
    Role__c                   = 'Applicant',
    Is_Primary__c             = true
);
insert apr;

// Step 4: Create Address
Party_Address__c addr = new Party_Address__c(
    Party__c      = party.Id,
    Street__c     = '10 Downing Street',
    City__c       = 'London',
    State__c      = 'Greater London',
    Postal_Code__c = 'SW1A 2AA',
    Country__c    = 'United Kingdom',
    Address_Type__c = 'Residential',
    Is_Primary__c = true
);
insert addr;

// Step 5: Create Risk Assessment
Risk_Assessment__c ra = new Risk_Assessment__c(
    Onboarding_Application__c              = app.Id,
    Risk_Rating__c                         = 'Low',
    PEP_Flag__c                            = false,
    Sanctions_Flag__c                      = false,
    EDD_Required__c                        = false,
    Private_Source_of_Wealth__c            = 'Employment',
    Private_Source_of_Wealth_Explanation__c = 'Software engineer salary',
    Private_Estimated_Transactions_per_Month__c = 5,
    Private_Expected_Monthly_Volume__c     = 10000,
    Private_Geographic_Exposure__c         = 'United Kingdom',
    Private_Intended_Use_of_Account__c     = 'Personal FX transfers'
);
insert ra;

System.debug('All related records created. Triggering submission...');

// Step 6: Flip Status to Submitted — this triggers the flow
app.Status__c = 'Submitted';
update app;

System.debug('Status set to Submitted. Checking results...');

// Step 7: Verify results
Onboarding_Application__c updatedApp = [
    SELECT Id, Status__c, Target_Account__c, Primary_Contact__c
    FROM Onboarding_Application__c WHERE Id = :app.Id
];

System.debug('--- APPLICATION ---');
System.debug('Status:          ' + updatedApp.Status__c);
System.debug('Target Account:  ' + updatedApp.Target_Account__c);
System.debug('Primary Contact: ' + updatedApp.Primary_Contact__c);

if (updatedApp.Target_Account__c != null) {
    Account acct = [
        SELECT Id, Name, Client_Type__c, Stage__c,
               Email_for_Notifications__c, Phone,
               BillingStreet, BillingCity, BillingCountry,
               Onboarding_Application__c, Services_Required__c,
               Has_Submitted_Application__c
        FROM Account WHERE Id = :updatedApp.Target_Account__c
    ];
    System.debug('--- ACCOUNT ---');
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
    System.debug('Services:        ' + acct.Services_Required__c);

    List<Contact> contacts = [
        SELECT Id, FirstName, LastName, Email, Phone, Birthdate, Nationality__c, Source_of_Wealth__c
        FROM Contact WHERE AccountId = :acct.Id
    ];
    System.debug('--- CONTACTS (' + contacts.size() + ') ---');
    for (Contact c : contacts) {
        System.debug('Name: ' + c.FirstName + ' ' + c.LastName
            + ' | Email: ' + c.Email
            + ' | DOB: ' + c.Birthdate
            + ' | Nationality: ' + c.Nationality__c
            + ' | SOW: ' + c.Source_of_Wealth__c);
    }

    System.debug('=== SCENARIO 1 RESULT: SUCCESS ===');
} else {
    System.debug('=== SCENARIO 1 RESULT: FAILED — No Account linked to application ===');
}
