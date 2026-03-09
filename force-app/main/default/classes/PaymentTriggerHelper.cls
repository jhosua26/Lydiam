public class PaymentTriggerHelper {

    public static void handleAfterInsert(List<Payment__c> newPayments) {
        List<Payment__c> receivedPayments = new List<Payment__c>();
        List<Payment__c> paidOutPayments = new List<Payment__c>();

        for (Payment__c p : newPayments) {
            if (shouldSendEmailInsert(p)) {
                if (p.Type__c == 'Received') {
                    receivedPayments.add(p);
                } else if (p.Type__c == 'Paid Out') {
                    paidOutPayments.add(p);
                }
            }
        }

        if (!receivedPayments.isEmpty() && Label.Error_in_Received_Payment_Trigger == 'No') {
            sendReceivedPaymentNotification(receivedPayments);
        }

        if (!paidOutPayments.isEmpty() && Label.Error_in_PaidOut_Payment_Trigger == 'No') {
            sendPaidOutPaymentNotification(paidOutPayments);
        }
    }

    public static void handleAfterUpdate(List<Payment__c> newPayments, Map<Id, Payment__c> oldMap) {
        List<Payment__c> receivedPayments = new List<Payment__c>();
        List<Payment__c> paidOutPayments = new List<Payment__c>();

        for (Payment__c p : newPayments) {
            Payment__c oldP = oldMap.get(p.Id);
            if (shouldSendEmailUpdate(p, oldP)) {
                if (p.Type__c == 'Received') {
                    receivedPayments.add(p);
                } else if (p.Type__c == 'Paid Out') {
                    paidOutPayments.add(p);
                }
            }
        }

        if (!receivedPayments.isEmpty() && Label.Error_in_Received_Payment_Trigger == 'No') {
            sendReceivedPaymentNotification(receivedPayments);
        }

        if (!paidOutPayments.isEmpty() && Label.Error_in_PaidOut_Payment_Trigger == 'No') {
            sendPaidOutPaymentNotification(paidOutPayments);
        }
    }

    private static Boolean shouldSendEmailInsert(Payment__c p) {
        return (
            (p.Type__c == 'Received' || p.Type__c == 'Paid Out') &&
            p.isEmailSent__c == false &&
            p.Account__c != null
        );
    }

    private static Boolean shouldSendEmailUpdate(Payment__c p, Payment__c oldP) {
        return (
            (p.Type__c == 'Received' || p.Type__c == 'Paid Out') &&
            p.isEmailSent__c == false &&
            p.Account__c != null &&
            p.Type__c != oldP.Type__c
        );
    }

    public static void sendReceivedPaymentNotification(List<Payment__c> payments) {
        sendPaymentEmails(payments, 'Received', 'Funds Received', 'Received_Email_Template_1756825734312');
    }

    public static void sendPaidOutPaymentNotification(List<Payment__c> payments) {
        sendPaymentEmails(payments, 'Paid Out', 'Payment Sent', 'Paid_Out_Email_Template_1756824508144');
    }

    public static void sendPaymentEmails(List<Payment__c> payments, String type, String subject, String templateApiName) {
        if (payments == null || payments.isEmpty()) return;

        Set<Id> paymentIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Payment__c p : payments) {
            paymentIds.add(p.Id);
            if (p.Account__c != null) {
                accountIds.add(p.Account__c);
            }
        }

        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Email_for_Notifications__c, Name
             FROM Account
             WHERE Id IN :accountIds]
        );

        Map<Id, Payment__c> paymentMap = new Map<Id, Payment__c>(
            [SELECT Id, Name, Type__c, Amount__c, Date_Receivd__c, CurrencyIsoCode, Description__c,
                    Payment_Reference__c,
                    Account__c, Account_Client_Code__c, Trade__r.Wallet__r.Name,
                    Beneficiary__r.Name,
                    Beneficiary__r.Bank_Name__c,
                    Beneficiary__r.Bank_Address__c,
                    Beneficiary__r.Bank_Country__c,
                    Beneficiary__r.Sort_Code__c,
                    Beneficiary__r.Beneficiary_Name__c,
                    Beneficiary__r.Bank_Account_Number__c,
                    Beneficiary__r.IBAN__c
             FROM Payment__c
             WHERE Id IN :paymentIds]
        );

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Payment__c> toUpdate = new List<Payment__c>();

        for (Payment__c p : paymentMap.values()) {
            if (p.Type__c != type) continue;

            Account acc = accountMap.get(p.Account__c);
            if (acc == null || String.isBlank(acc.Email_for_Notifications__c)) continue;

            String body = buildEmailFromTemplate(templateApiName, p, acc);
            if (String.isBlank(body)) continue;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { acc.Email_for_Notifications__c });
            email.setCcAddresses(new List<String>{
                'ayaz.khan@lydiamgroup.com'
            });
            email.setSubject(subject);
            email.setHtmlBody(body);
            emails.add(email);

            toUpdate.add(new Payment__c(Id = p.Id, isEmailSent__c = true));
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static String buildEmailFromTemplate(String templateApiName, Payment__c p, Account acc) {
        EmailTemplate et = [
            SELECT Id, HtmlValue, Body
            FROM EmailTemplate
            WHERE DeveloperName = :templateApiName
            LIMIT 1
        ];

        String templateBody = String.isNotBlank(et.HtmlValue) ? et.HtmlValue : et.Body;

        if (templateApiName == 'Received_Email_Template_1756825734312') {
            templateBody = templateBody
                .replace('{{ClientName}}', acc.Name != null ? acc.Name : '')
                .replace('{{ClientRefNo.}}', p.Account_Client_Code__c != null ? p.Account_Client_Code__c : '')
                .replace('{{Amount}}', (p.Amount__c != null ? p.CurrencyIsoCode + ' ' + p.Amount__c.setScale(2) : ''))
                .replace('{{Description}}', p.Description__c != null ? p.Description__c : '');
        }
        else if (templateApiName == 'Paid_Out_Email_Template_1756824508144') {
            // Replace all merge fields
            templateBody = templateBody
                .replace('{{ClientName}}', acc.Name != null ? acc.Name : '')
                .replace('{{ClientRefNo}}', p.Account_Client_Code__c != null ? p.Account_Client_Code__c : '')
                .replace('{{PaymentAmount}}', (p.Amount__c != null ? p.CurrencyIsoCode + ' ' + p.Amount__c.setScale(2) : ''))
                .replace('{{PaymentDate}}', p.Date_Receivd__c != null ? p.Date_Receivd__c.format() : '')
                .replace('{{BeneficiaryName}}', (p.Beneficiary__r != null && p.Beneficiary__r.Beneficiary_Name__c != null) ? p.Beneficiary__r.Beneficiary_Name__c : '')
                .replace('{{BeneficiaryAddress}}', (p.Beneficiary__r != null && p.Beneficiary__r.Bank_Address__c != null) ? p.Beneficiary__r.Bank_Address__c : '')
                .replace('{{BankCountry}}', (p.Beneficiary__r != null && p.Beneficiary__r.Bank_Country__c != null) ? p.Beneficiary__r.Bank_Country__c : '')
                .replace('{{AccountNumber}}', (p.Beneficiary__r != null && p.Beneficiary__r.Bank_Account_Number__c != null) ? p.Beneficiary__r.Bank_Account_Number__c : '')
                .replace('{{SortCode}}', (p.Beneficiary__r != null && p.Beneficiary__r.Sort_Code__c != null) ? p.Beneficiary__r.Sort_Code__c : '')
                .replace('{{BankName}}', (p.Beneficiary__r != null && p.Beneficiary__r.Bank_Name__c != null) ? p.Beneficiary__r.Bank_Name__c : '')
                .replace('{{PaymentRef}}', p.Payment_Reference__c != null ? p.Payment_Reference__c : '');

            // Map of field placeholders to their HTML line regex
            Map<String, String> fieldDivs = new Map<String, String>{
                'ClientName' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Payment sent from:</strong>.*?</div>',
                'ClientRefNo' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Account reference:</strong>.*?</div>',
                'PaymentAmount' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Payment amount:</strong>.*?</div>',
                'PaymentDate' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Payment date:</strong>.*?</div>',
                'BeneficiaryName' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Beneficiary name:</strong>.*?</div>',
                'BeneficiaryAddress' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Beneficiary Address:</strong>.*?</div>',
                'BankCountry' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Bank Country:</strong>.*?</div>',
                'AccountNumber' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Account Number:</strong>.*?</div>',
                'SortCode' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Sort Code:</strong>.*?</div>',
                'BankName' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Bank Name:</strong>.*?</div>',
                'PaymentRef' => '<div style="margin: 5px 0; padding: 5px;">\\s*<strong>Payment reference:</strong>.*?</div>'
            };

            // Remove lines if the corresponding value is null/blank
            if (String.isBlank(acc.Name)) templateBody = templateBody.replaceAll(fieldDivs.get('ClientName'), '');
            if (String.isBlank(p.Account_Client_Code__c)) templateBody = templateBody.replaceAll(fieldDivs.get('ClientRefNo'), '');
            if (p.Amount__c == null) templateBody = templateBody.replaceAll(fieldDivs.get('PaymentAmount'), '');
            if (p.Date_Receivd__c == null) templateBody = templateBody.replaceAll(fieldDivs.get('PaymentDate'), '');
            if (p.Beneficiary__r == null || String.isBlank(p.Beneficiary__r.Beneficiary_Name__c)) templateBody = templateBody.replaceAll(fieldDivs.get('BeneficiaryName'), '');
            if (p.Beneficiary__r == null || String.isBlank(p.Beneficiary__r.Bank_Address__c)) templateBody = templateBody.replaceAll(fieldDivs.get('BeneficiaryAddress'), '');
            if (p.Beneficiary__r == null || String.isBlank(p.Beneficiary__r.Bank_Country__c)) templateBody = templateBody.replaceAll(fieldDivs.get('BankCountry'), '');
            if (p.Beneficiary__r == null || String.isBlank(p.Beneficiary__r.Bank_Account_Number__c)) templateBody = templateBody.replaceAll(fieldDivs.get('AccountNumber'), '');
            if (p.Beneficiary__r == null || String.isBlank(p.Beneficiary__r.Sort_Code__c)) templateBody = templateBody.replaceAll(fieldDivs.get('SortCode'), '');
            if (p.Beneficiary__r == null || String.isBlank(p.Beneficiary__r.Bank_Name__c)) templateBody = templateBody.replaceAll(fieldDivs.get('BankName'), '');
            if (String.isBlank(p.Payment_Reference__c)) templateBody = templateBody.replaceAll(fieldDivs.get('PaymentRef'), '');
        }


        return templateBody;
    }
}