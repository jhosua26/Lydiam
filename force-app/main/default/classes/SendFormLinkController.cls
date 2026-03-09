public with sharing class SendFormLinkController {
    @AuraEnabled
    public static void sendFormLinkEmail(Id leadId, List<String> formRoutes, List<String> formLabels) {
        Lead lead = [SELECT Id, FirstName, Email FROM Lead WHERE Id = :leadId LIMIT 1];

        if (String.isBlank(lead.Email)) {
            throw new AuraHandledException('Lead email is not available.');
        }

        if (formRoutes.size() != formLabels.size()) {
            throw new AuraHandledException('Mismatch between routes and labels.');
        }

        String baseUrl = Label.Base_URL;
        List<String> fullLinks = new List<String>();

        for (Integer i = 0; i < formRoutes.size(); i++) {
            String fullUrl = baseUrl + formRoutes[i];
            String label = formLabels[i];
            fullLinks.add('<strong>' + label + '</strong> – <a href="' + fullUrl + '" target="_blank">' + fullUrl + '</a>');
        }

        // ---------------- HEADER ----------------
        String header = 
            '<div style="display: flex; background-color: #222; color: white; width: 100%; font-family: Arial, sans-serif;">' +
                '<div style="padding: 20px; text-align: left; width: 50%;">' +
                    '<h1 style="margin: 0; font-size: 16px;">LYDIAM</h1>' +
                    '<p style="font-size: 10px; margin: 2px 0 8px 0;">' + Date.today().format() + '</p>' +
                    '<h2 style="font-size: 20px; margin: 0;">Welcome To Lydiam</h2>' +
                '</div>' +
                '<div style="padding: 20px; text-align: right; width: 50%;">' +
                    '<p style="font-size: 10px; margin: 0;">Canada&nbsp;&nbsp;Switzerland&nbsp;&nbsp;UK&nbsp;&nbsp;Poland&nbsp;&nbsp;Dubai&nbsp;&nbsp;India</p>' +
                '</div>' +
            '</div><br>';

        // ---------------- ORIGINAL BODY WITH 3 BR BEFORE & AFTER ----------------
        String body = '<br><br><br>' +
            'Hello ' + lead.FirstName + ',<br/><br/>' +
            'Please complete the following application form(s):<br/><br/>' +
            String.join(fullLinks, '<br/><br/>') +
            '<br/><br/>Thank you!' +
            '<br><br><br>';

        // ---------------- FOOTER ----------------
        String footer = 
            '<table width="100%" cellpadding="20" cellspacing="0" style="background-color: #1c1c1c; color: white; font-size: 14px; text-align: center; margin-top: 20px; font-family: Arial, sans-serif;">' +
                '<tr><td>' +
                    '<p style="margin: 0; line-height: 1.5;">' +
                        '3rd Floor, 100 New Bond Street,' +
                        ' London, W1 1SP<br>' +
                        'Company Registration 04675786<br>' +
                        'FCA FRN - 504346' +
                    '</p>' +
                '</td></tr>' +
            '</table>';

        // ---------------- FINAL EMAIL ----------------
        String emailBody = header + body + footer;

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { lead.Email });
        email.setSubject('Your Application Form(s)');
        email.setHtmlBody(emailBody);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}