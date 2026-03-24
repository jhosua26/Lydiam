/**
 * @description Invocable action called by the Application Submitted Account Stage Update flow.
 *              Triggers a full conversion of the submitted Onboarding_Application__c into a
 *              populated Account and Contact records immediately on form submission.
 *              Wraps OnboardingConversionService — all business logic lives there.
 *              Throws on failure so the flow's fault connector can surface the error.
 */
public without sharing class AutoConvertApplicationAction {

    public class Request {
        @InvocableVariable(required=true label='Application Id')
        public Id applicationId;
    }

    public class AutoConvertException extends Exception {}

    @InvocableMethod(
        label='Auto-Convert Application to Account'
        description='Converts a submitted Onboarding Application into a full Account and Contacts immediately on form submission.'
    )
    public static void execute(List<Request> requests) {
        OnboardingConversionService service = new OnboardingConversionService();
        for (Request req : requests) {
            if (req.applicationId == null) {
                continue;
            }
            OnboardingConversionService.ConversionResult result = service.convert(req.applicationId);
            if (!result.isSuccess) {
                throw new AutoConvertException(result.message);
            }
        }
    }
}
