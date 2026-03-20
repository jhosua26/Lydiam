public class AccountStatusHandler {
    public static void handleStatusChange(List<Account> newList, Map<Id, Account> oldMap) {
        List<Account> changedToClient = new List<Account>();
        
        for (Account newAcc : newList) {
            Account oldAcc = oldMap.get(newAcc.Id);
            if (oldAcc.Stage__c != 'Client coded' && newAcc.Stage__c == 'Client coded') {
                changedToClient.add(newAcc);
            }
        }

        if (!changedToClient.isEmpty()) {
            sendClientStatusEmail(changedToClient);
        }
    }

    public static void sendClientStatusEmail(List<Account> accounts) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Fetch HTML template once
        EmailTemplate template = [
            SELECT Id, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'Welcome_Email_Template_1756819238885'
            LIMIT 1
        ];

        // Fetch Org-Wide Email Address for consistent, trusted sender
        List<OrgWideEmailAddress> owas = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = 'technology@lydiamgroup.com' LIMIT 1
        ];

        for (Account acc : accounts) {
            String toAddress = acc.Email_for_Notifications__c;
            if (String.isBlank(toAddress)) continue;

            // Recipient name logic
            String recipientName;
            if (String.isNotBlank(acc.Name)) {
                recipientName = acc.Name;
            } else if (String.isNotBlank(acc.FirstName) || String.isNotBlank(acc.LastName)) {
                recipientName = acc.FirstName + ' ' + acc.LastName;
            } else {
                recipientName = 'Client';
            }

            // Reference number (Client Code)
            String referenceNumber = String.isNotBlank(acc.Client_Code__c) ? acc.Client_Code__c : 'N/A';

            // Replace placeholders inside HTML
            String htmlBody = template.HtmlValue;
            htmlBody = htmlBody.replace('{{RecipientName}}', recipientName);
            htmlBody = htmlBody.replace('{{ReferenceNumber}}', referenceNumber);
            // htmlBody = htmlBody.replace('{{RecipientEmail}}', toAddress);

            // Build email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { toAddress });
            email.setCcAddresses(new List<String>{
                'compliance@lydiamgroup.com',
                'technology@lydiamgroup.com',
                'joshua.flanagan@lydiamgroup.com',
                'ayaz.khan@lydiamgroup.com'
            });
            email.setSubject('Welcome to Lydiam');
            email.setHtmlBody(htmlBody);
            if (!owas.isEmpty()) {
                email.setOrgWideEmailAddressId(owas[0].Id);
            } else {
                email.setSenderDisplayName('Lydiam');
            }

            emails.add(email);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);

                List<Account> accountsToUpdate = new List<Account>();
                for (Account acc : accounts) {
                    accountsToUpdate.add(new Account(
                        Id = acc.Id,
                        Welcome_Email_Sent__c = true
                    ));
                }
                update accountsToUpdate;
            } catch (Exception e) {
                System.debug('Welcome email failed to send: ' + e.getMessage());
            }
        }
    }

    // public static String formatDate(Date inputDate) {
    //     String[] daysOfWeek = new String[] {
    //         'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday','Sunday'
    //     };
    //     String[] months = new String[] {
    //         '', 'January', 'February', 'March', 'April', 'May', 'June',
    //         'July', 'August', 'September', 'October', 'November', 'December'
    //     };

    //     String dayName = daysOfWeek[inputDate.toStartOfWeek().daysBetween(inputDate)];
    //     Integer dayNum = inputDate.day();
    //     String suffix = 'th';

    //     if (dayNum == 1 || dayNum == 21 || dayNum == 31) {
    //         suffix = 'st';
    //     } else if (dayNum == 2 || dayNum == 22) {
    //         suffix = 'nd';
    //     } else if (dayNum == 3 || dayNum == 23) {
    //         suffix = 'rd';
    //     }

    //     String monthName = months[inputDate.month()];
    //     return dayName + ' ' + dayNum + suffix + ' ' + monthName;
    // }
}