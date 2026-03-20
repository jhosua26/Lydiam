/**
 * @description Invocable action called by the Application Submitted Account Stage Update flow.
 *              Creates a stub Account for walk-in onboarding applications and links it back
 *              to the application via Target_Account__c.
 *              Uses Database.DMLOptions to bypass duplicate detection rules — necessary because
 *              Salesforce Flow has no native mechanism to override duplicate rules on record creation.
 */
public without sharing class CreateStubAccountAction {

    public class Request {
        @InvocableVariable(required=true label='Application Id')
        public Id applicationId;

        @InvocableVariable(required=true label='Client Name')
        public String clientName;

        @InvocableVariable(required=true label='Client Type')
        public String clientType;

        @InvocableVariable(label='Onboarding Date')
        public Date onboardingDate;
    }

    @InvocableMethod(
        label='Create and Link Stub Account'
        description='Creates a stub Account for a walk-in application, bypassing duplicate detection rules, then sets Target_Account__c on the application.'
    )
    public static void execute(List<Request> requests) {
        List<Account> toInsert = new List<Account>();
        for (Request req : requests) {
            toInsert.add(new Account(
                Name                         = req.clientName,
                Client_Type__c               = req.clientType,
                Stage__c                     = 'Opportunity',
                Has_Submitted_Application__c = true,
                Onboarding_Date__c           = req.onboardingDate,
                Onboarding_Application__c    = req.applicationId
            ));
        }

        Database.DMLOptions opts = new Database.DMLOptions();
        opts.DuplicateRuleHeader.allowSave = true;
        List<Database.SaveResult> saveResults = Database.insert(toInsert, opts);

        List<Onboarding_Application__c> appsToUpdate = new List<Onboarding_Application__c>();
        for (Integer i = 0; i < requests.size(); i++) {
            if (saveResults[i].isSuccess()) {
                appsToUpdate.add(new Onboarding_Application__c(
                    Id = requests[i].applicationId,
                    Target_Account__c = saveResults[i].getId()
                ));
            }
        }
        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }
    }
}
