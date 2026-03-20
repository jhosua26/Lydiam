/**
 * @description AuraEnabled controller that exposes the OnboardingConversionService
 *              to LWC components. Thin controller — delegates all business logic to the service.
 * 
 * @Jhosua Arda
 * LinkedIn - https://www.linkedin.com/in/jhosua-arda/
 * @date 2026
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
            SELECT Id, Status__c, Client_Type__c, Client_Name__c, Target_Account__c
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

        if (app.Status__c == 'Converted') {
            result.put('eligible', false);
            result.put('reason', 'This application has already been converted.');
            result.put('alreadyConvertedAccountId', app.Target_Account__c);
            return result;
        }

        if (app.Status__c != 'Approved' && app.Status__c != 'Submitted') {
            result.put('eligible', false);
            result.put('reason', 'Only applications with Status "Approved" or "Submitted" can be converted. Current status: ' + app.Status__c);
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