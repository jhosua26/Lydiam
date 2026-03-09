/**
 * @description AuraEnabled controller that exposes the OnboardingConversionService
 *              to LWC components. Thin controller — delegates all business logic to the service.
 */
public with sharing class OnboardingConversionController {

    /**
     * @description Checks whether the given application is eligible for conversion.
     * @param applicationId The Onboarding_Application__c record Id
     * @return Map with keys: eligible (Boolean), reason (String), alreadyConvertedAccountId (String)
     */
    @AuraEnabled
    public static Map<String, Object> checkConversionEligibility(Id applicationId) {
        Map<String, Object> result = new Map<String, Object>();

        if (applicationId == null) {
            result.put('eligible', false);
            result.put('reason', 'Application Id is required.');
            return result;
        }

        List<Onboarding_Application__c> apps = [
            SELECT Id, Status__c, Client_Type__c, Client_Name__c
            FROM Onboarding_Application__c
            WHERE Id = :applicationId
            LIMIT 1
        ];

        if (apps.isEmpty()) {
            result.put('eligible', false);
            result.put('reason', 'Onboarding Application record not found.');
            return result;
        }

        Onboarding_Application__c app = apps[0];

        List<Account> existingAccounts = [
            SELECT Id, Name FROM Account
            WHERE Onboarding_Application__c = :applicationId
            LIMIT 1
        ];

        if (!existingAccounts.isEmpty()) {
            result.put('eligible', false);
            result.put('reason', 'This application has already been converted to Account: ' + existingAccounts[0].Name);
            result.put('alreadyConvertedAccountId', existingAccounts[0].Id);
            return result;
        }

        if (app.Status__c != 'Approved') {
            result.put('eligible', false);
            result.put('reason', 'Only applications with Status "Approved" can be converted. Current status: ' + app.Status__c);
            return result;
        }

        result.put('eligible', true);
        result.put('reason', 'Application "' + app.Client_Name__c + '" (' + app.Client_Type__c + ') is ready for conversion.');
        result.put('clientName', app.Client_Name__c);
        result.put('clientType', app.Client_Type__c);

        return result;
    }

    /**
     * @description Converts an Onboarding Application into Account + Contacts.
     * @param applicationId The Onboarding_Application__c record Id
     * @return OnboardingConversionService.ConversionResult
     */
    @AuraEnabled
    public static OnboardingConversionService.ConversionResult convertToAccountAndContacts(Id applicationId) {
        OnboardingConversionService service = new OnboardingConversionService();
        return service.convert(applicationId);
    }
}
