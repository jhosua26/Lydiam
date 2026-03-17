public with sharing class AccountSendWelcomeEmail {

    public class Request {
        @InvocableVariable(required=true label='Account Record Id')
        public Id recordId;
    }

    @InvocableMethod(label='Send Client Status Email' description='Sends the onboarding email to the Account\'s notification address')
    public static void sendEmail(List<Request> requests) {
        Set<Id> accountIds = new Set<Id>();
        for (Request req : requests) {
            if (req.recordId != null) {
                accountIds.add(req.recordId);
            }
        }

        if (accountIds.isEmpty()) return;

        List<Account> accounts = [
            SELECT Id, Name, FirstName, LastName, Client_Code__c, Email_for_Notifications__c, PersonEmail
            FROM Account
            WHERE Id IN :accountIds
        ];

        if (!accounts.isEmpty()) {
            sendClientStatusEmail(accounts);
        }
    }

    public static void sendClientStatusEmail(List<Account> accounts) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Fetch the HTML body from template
        EmailTemplate template = [
            SELECT Id, HtmlValue 
            FROM EmailTemplate 
            WHERE DeveloperName = 'Welcome_Email_Template_1756819238885' 
            LIMIT 1
        ];

        for (Account acc : accounts) {
            String toAddress = !String.isBlank(acc.Email_for_Notifications__c) 
                                ? acc.Email_for_Notifications__c 
                                : acc.PersonEmail;
            if (String.isBlank(toAddress)) continue;

            // Prepare dynamic values
            String recipientName;
            if (String.isNotBlank(acc.Name)) {
                recipientName = acc.Name;
            } else if (String.isNotBlank(acc.FirstName) || String.isNotBlank(acc.LastName)) {
                recipientName = acc.FirstName + ' ' + acc.LastName;
            } else {
                recipientName = 'Client';
            }

            String referenceNumber = acc.Client_Code__c != null ? acc.Client_Code__c : 'N/A';

            // Replace placeholders in HTML
            String htmlBody = template.HtmlValue;
            htmlBody = htmlBody.replace('{{RecipientName}}', recipientName);
            htmlBody = htmlBody.replace('{{ReferenceNumber}}', referenceNumber);

            // Build email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { toAddress });
            email.setCcAddresses(new List<String>{
                'compliance@lydiamgroup.com',
                'ayaz.khan@lydiamgroup.com'
            });
            email.setSubject('Welcome to Lydiam');
            email.setHtmlBody(htmlBody);

            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}