// public class TradeTriggerHandler {
//     public static void handleAfterInsert(List<Trade__c> newTrades) {
//         List<Trade__c> toEmail = new List<Trade__c>();
//         for (Trade__c t : newTrades) {
//             if (shouldSendEmailInsert(t)) {
//                 toEmail.add(t);
//             }
//         }
//         if (!toEmail.isEmpty()) sendTradeNotification(toEmail, true);
//     }

//     public static void handleAfterUpdate(List<Trade__c> newTrades, Map<Id, Trade__c> oldMap) {
//         List<Trade__c> toEmail = new List<Trade__c>();
//         for (Trade__c t : newTrades) {
//             Trade__c oldT = oldMap.get(t.Id);
//             if (shouldSendEmailUpdate(t, oldT)) {
//                 toEmail.add(t);
//             }
//         }
//         if (!toEmail.isEmpty()) sendTradeNotification(toEmail, false);
//     }

//     private static Boolean shouldSendEmailInsert(Trade__c t) {
//         return t.Account__c != null &&
//             t.Buy__c != null &&
//             t.Sell__c != null &&
//             t.Number_of_Tokens__c != null &&
//             t.Total_Amount__c != null;
//     }

//     private static Boolean shouldSendEmailUpdate(Trade__c t, Trade__c oldT) {
//         return t.Account__c != null &&
//             t.Buy__c != null &&
//             t.Sell__c != null &&
//             t.Number_of_Tokens__c != null &&
//             t.Total_Amount__c != null &&
//             (
//                 t.Buy__c != oldT.Buy__c ||
//                 t.Sell__c != oldT.Sell__c ||
//                 t.Number_of_Tokens__c != oldT.Number_of_Tokens__c ||
//                 t.Total_Amount__c != oldT.Total_Amount__c
//             );
//     }


//     public static void sendTradeNotification(List<Trade__c> trades, Boolean isInsert) {
//         Set<Id> accountIds = new Set<Id>();
//         for (Trade__c t : trades) if (t.Account__c != null) accountIds.add(t.Account__c);

//         Map<Id, Account> accountMap = new Map<Id, Account>(
//             [SELECT Id, Name, Email_for_Notifications__c, Client_Code__c FROM Account WHERE Id IN :accountIds]
//         );

//         Map<Id, Trade__c> tradeMap = new Map<Id, Trade__c>(
//             [SELECT Id, Name, Account__c, Buy__c, Sell__c, Number_of_Tokens__c, Total_Amount__c, Trade_Type__c,
//                     Deal_Date__c, Wallet__r.Name,CurrencyIsoCode 
//              FROM Trade__c WHERE Id IN :trades]
//         );

//         List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

//         for (Trade__c t : trades) {
//             Trade__c trade = tradeMap.get(t.Id);
//             Account acc = accountMap.get(trade.Account__c);
//             if (acc == null || String.isBlank(acc.Email_for_Notifications__c)) continue;

//             Boolean isSameCurrency = trade.Buy__c == trade.Sell__c;
//             String subject = isSameCurrency
//                 ? 'Same Currency Payment Confirmed'
//                 : 'Foreign Currency Payment Confirmed';

//             // String body = isSameCurrency
//             //     ? buildSameCurrencyBody(trade, acc, isInsert)
//             //     : buildForeignCurrencyBody(trade, acc, isInsert);
//             String body = isSameCurrency
//                 ? buildForeignCurrencyBody(trade, acc, isInsert)
//                 : buildForeignCurrencyBody(trade, acc, isInsert);

//             if (String.isBlank(body)) continue;

//             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//             mail.setToAddresses(new String[] { acc.Email_for_Notifications__c });
//             mail.setSubject(subject);
//             mail.setHtmlBody(body);
//             emails.add(mail);
//         }

//         if (!emails.isEmpty()) {
//             Messaging.sendEmail(emails, false);
//         }
//     }

//     private static String buildSameCurrencyBody(Trade__c trade, Account acc, Boolean isInsert) {
//         String html =
//             '<html><body style="font-family:sans-serif;background:#f8f8f8;padding:20px;">' +
//             '<div style="max-width:700px;margin:auto;background:white;border-radius:8px;overflow:hidden;">' +

//             // Header
//             '<div style="background:#ffffff;padding:40px 20px;text-align:center;border-bottom:1px solid #eee;">' +
//             '<h1 style="margin:0;font-size:32px;letter-spacing:8px;color:#1A1A1A;">LYDIAM</h1>' +
//             '</div>' +

//             // Intro
//             '<div style="padding:30px;">' +
//             '<h2>Details of your transaction</h2>' +
//             '<p>Here\'s a summary of your transaction. If you need further details you can view and download them from your account.</p>' +

//             // Account info
//             '<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:25px;">' +
//                 row('Account name', acc.Name) +
//                 row('Account reference', acc.Client_Code__c) +
//             '</table>' +

//             // Same currency section
//             '<h3>Same currency payment</h3>' +
//             '<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:25px;">' +
//                 row('Total payment amount', formatMoney(trade.Total_Amount__c, trade.Buy__c)) +
//                 row('Transaction fee', '0.00 ' + trade.Buy__c) +
//             '</table>' +

//             // Funded box
//             '<div style="border:1px solid #ddd;padding:15px;margin-bottom:20px;">' +
//             '<strong>Funded from your ' + trade.Buy__c + ' balance</strong><br>' +
//             '-' + formatMoney(trade.Total_Amount__c, trade.Buy__c) + '<br>' +
//             'No further action required' +
//             '</div></div></div></body></html>';

//             // Recipient box
//             // '<div style="border:1px solid #ddd;padding:15px;">' +
//             // '<strong>EDEN ASSET MANAGEMENT LTD</strong><br>' +
//             // formatMoney(trade.Total_Amount__c, trade.Buy__c) + '<br>' +
//             // trade.Buy__c + ' account ending in 9969' +
//             // '</div>';

//         return html;
//     }

//     private static String buildForeignCurrencyBody(Trade__c trade, Account acc, Boolean isInsert) {
//         String html =
//             '<html><body style="font-family:sans-serif;background:#f8f8f8;padding:20px;">' +
//             '<div style="max-width:700px;margin:auto;background:white;border-radius:8px;overflow:hidden;">' +

//             // Header
//             // '<div style="background:#ffffff;padding:40px 20px;text-align:center;border-bottom:1px solid #eee;">' +
//             // '<h1 style="margin:0;font-size:32px;letter-spacing:8px;color:#1A1A1A;">LYDIAM</h1>' +
//             // '</div>' +
//             '<table width="100%" cellpadding="0" cellspacing="0" style="max-width: 700px; margin: auto; background-color: #fff; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">' +
//                 '<tr>' +
//                     '<td style="background-color: #222; color: white; padding: 20px; text-align: left;">' +
//                         '<h1 style="margin: 0; font-size: 18px;">LYDIAM</h1>' +
//                         '<p style="font-size: 14px; margin: 0;">'+ formatDate(Date.today()) +'</p>' +
//                         '<h2 style="font-size: 20px; margin: 0;">Welcome To Lydiam</h2>' +
//                     '</td>' +
//                     '<td style="background-color: #222; color: white; padding: 20px; text-align: left;">' +
//                         '<p style="font-size: 12px; margin-left: 20px;">Canada Switzerland UK Poland Dubai India</p>' +
//                     '</td>' +
//                 '</tr>' +
//             '</table>'+

//             // Intro
//             '<div style="padding:30px;">' +
//             '<p>Hello '+ acc.Name +'</p>' +
//             '<p>I\'m pleased to inform you that your a '+trade.Trade_Type__c+' trade has been book on your behalf.</p>' +

//             // Account info
//             '<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:25px;">' +
//                 row('Buying: ', trade.Buy__c) +
//                 row('Selling: ', trade.Sell__c) +
//             '</table>' +

//             // Conversion section
//             // '<h3>Currency conversion details</h3>' +
//             '<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:25px;">' +
//                 row('Amount', formatMoney(trade.Total_Amount__c, trade.CurrencyIsoCode)) +
//                 // row('Exchange rate', '1.37587') + // update as needed
//                 // row('Settlement date', formatDate(trade.Deal_Date__c)) +
//                 // row('Buy currency', formatMoney(trade.Number_of_Tokens__c, trade.Buy__c)) +
//             '</table>' +

//             // Funded box
//             // '<div style="border:1px solid #ddd;padding:15px;margin-bottom:20px;">' +
//             // '<strong>Funded from your ' + trade.Sell__c + ' balance</strong><br>' +
//             // '-' + formatMoney(trade.Total_Amount__c, trade.Sell__c) + '<br>' +
//             // 'No further action required' +
//             '  <div class="footer">'
//             + '    Lydiam Group. All rights reserved. Lydiam Group 17 Hannover Square, London, W1S 1BN<br><br>'
//             + '    This email is intended for the named recipient only. It may contain privileged and confidential information. '
//             + 'If you are not the intended recipient, notify the sender immediately and destroy this email. You must not copy, distribute or take action in reliance upon it.<br><br>'
//             + '    Whilst all efforts are made to safeguard emails, we cannot guarantee that attachments are virus free or compatible with your systems '
//             + 'and does not accept liability in respect of viruses or computer problems experienced. We reserve the right to monitor all email communications through its internal and external networks.'
//             + '  </div>'
//             +
//             '</div></div></body></html>';

//             // Recipient box
//             // '<div style="border:1px solid #ddd;padding:15px;">' +
//             // '<strong>EDEN ASSET MANAGEMENT LTD</strong><br>' +
//             // formatMoney(trade.Number_of_Tokens__c, trade.Buy__c) + '<br>' +
//             // trade.Buy__c + ' account ending in 9969' +
//             // '</div>';

//         return html;
//     }
//     private static String buildForeignCurrencyBody(Trade__c trade, Account acc, Boolean isInsert) {
//         String html =
//             '<html><body style="font-family:sans-serif;background:#f8f8f8;padding:20px;">' +
//             '<div style="max-width:700px;margin:auto;background:white;border-radius:8px;overflow:hidden;">' +

//             // Header section with left and right alignment
//             '<table width="100%" cellpadding="0" cellspacing="0" style="width:100%; background-color: #222; color: #fff;">' +
//                 '<tr>' +
//                     '<td style="padding: 20px; text-align: left;">' +
//                         '<h1 style="margin: 0; font-size: 18px; color: #fff;">LYDIAM</h1>' +
//                         '<p style="font-size: 14px; margin: 0;">' + formatDate(Date.today()) + '</p>' +
//                         '<h2 style="font-size: 20px; margin: 0;">Trade Confirmation</h2>' +
//                     '</td>' +
//                     '<td style="padding: 20px; text-align: right; vertical-align: top;">' +
//                         '<p style="font-size: 12px; margin: 0;">Canada&nbsp;&nbsp;Switzerland&nbsp;&nbsp;UK&nbsp;&nbsp;Poland&nbsp;&nbsp;Dubai&nbsp;&nbsp;India</p>' +
//                     '</td>' +
//                 '</tr>' +
//             '</table>' +

//             // Intro
//             '<div style="padding:30px;">' +
//             '<p>Hello ' + acc.Name + ',</p>' +
//             '<p>I\'m pleased to inform you that your a ' + trade.Trade_Type__c + ' trade has been book on your behalf.</p>' +

//             // Trade Details
//             '<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:25px;">' +
//                 row('Buying Currency:', trade.Buy__c) +
//                 row('Selling Currency:', trade.Sell__c) +
//             '</table>' +
//             //trade.CurrencyIsoCode
//             '<table style="width:100%;border-collapse:collapse;font-size:14px;margin-bottom:25px;">' +
//                 row('Buying Amount', formatMoney(trade.Number_of_Tokens__c, trade.Buy__c)) +
//                 row('Selling Amount', formatMoney(trade.Total_Amount__c, trade.Sell__c)) +
//             '</table>' +

//             // Footer
//             '<div class="footer" style="font-size:10px; color:#666; margin-top:30px;">' +
//             'Lydiam Group. All rights reserved. Lydiam Group 17 Hannover Square, London, W1S 1BN<br><br>' +
//             'This email is intended for the named recipient only. It may contain privileged and confidential information. ' +
//             'If you are not the intended recipient, notify the sender immediately and destroy this email. You must not copy, distribute or take action in reliance upon it.<br><br>' +
//             'Whilst all efforts are made to safeguard emails, we cannot guarantee that attachments are virus free or compatible with your systems ' +
//             'and do not accept liability in respect of viruses or computer problems experienced. We reserve the right to monitor all email communications through its internal and external networks.' +
//             '</div>' +

//             '</div></div>'+
//                 '<table width="100%" cellpadding="20" cellspacing="0" style="background-color: #1c1c1c; color: white; font-size: 14px; text-align: center; margin-top: 20px;">' +
//                   '<tr><td>' +
//                     '<p style="margin: 0;">' +
//                       '3rd Floor, 100 New Bond Street, ' +
//                       'London, W1 1SP<br>' +
//                       'Company Registration 04675786<br>' +
//                       'FCA FRN - 504346' +
//                     '</p><br>' +
//                     // '<p style="margin: 0;">' +
//                     //   '<a href="#" style="color: white; margin: 0 10px;">Manage Preferences</a> | ' +
//                     //   '<a href="#" style="color: white; margin: 0 10px;">Unsubscribe</a>' +
//                     // '</p><br>' +
//                   '</td></tr>' +
//                 '</table>' +
//                 '</body></html>';

//         return html;
//     }


//     private static String row(String label, Object value) {
//         String val = (value != null ? String.valueOf(value) : 'N/A');
//         return '<tr><td style="padding:5px 0;width:150px;"><strong>' + label + '</strong></td><td>' + val + '</td></tr>';
//     }

//     private static String formatMoney(Decimal amt, String curr) {
//         if (amt == null || curr == null) return 'N/A';
//         return String.valueOf(amt.setScale(2)) + ' ' + curr;
//     }

//     private static String formatDate(Date d) {
//         return (d != null ? d.format() : 'N/A');
//     }
// }

public class TradeTriggerHandler {
    public static void handleAfterInsert(List<Trade__c> newTrades) {
        List<Trade__c> toEmail = new List<Trade__c>();
        for (Trade__c t : newTrades) {
            if (shouldSendEmailInsert(t)) {
                toEmail.add(t);
            }
        }
        if (!toEmail.isEmpty()) sendTradeNotification(toEmail, true);
    }

    public static void handleAfterUpdate(List<Trade__c> newTrades, Map<Id, Trade__c> oldMap) {
        List<Trade__c> toEmail = new List<Trade__c>();
        for (Trade__c t : newTrades) {
            Trade__c oldT = oldMap.get(t.Id);
            if (shouldSendEmailUpdate(t, oldT)) {
                toEmail.add(t);
            }
        }
        if (!toEmail.isEmpty()) sendTradeNotification(toEmail, false);
    }

    private static Boolean shouldSendEmailInsert(Trade__c t) {
        return t.Account__c != null &&
            t.Buy__c != null &&
            t.Sell__c != null &&
            t.Number_of_Tokens__c != null &&
            t.Total_Amount__c != null;
    }

    private static Boolean shouldSendEmailUpdate(Trade__c t, Trade__c oldT) {
        return t.Account__c != null &&
            t.Buy__c != null &&
            t.Sell__c != null &&
            t.Number_of_Tokens__c != null &&
            t.Total_Amount__c != null &&
            (
                t.Buy__c != oldT.Buy__c ||
                t.Sell__c != oldT.Sell__c ||
                t.Number_of_Tokens__c != oldT.Number_of_Tokens__c ||
                t.Total_Amount__c != oldT.Total_Amount__c
            );
    }

    public static void sendTradeNotification(List<Trade__c> trades, Boolean isInsert) {
        Set<Id> accountIds = new Set<Id>();
        for (Trade__c t : trades) if (t.Account__c != null) accountIds.add(t.Account__c);

        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Name, Email_for_Notifications__c, Client_Code__c 
             FROM Account WHERE Id IN :accountIds]
        );

        Map<Id, Trade__c> tradeMap = new Map<Id, Trade__c>(
            [SELECT Id, Name, Account__c, Buy__c, Sell__c, Number_of_Tokens__c, 
                    Total_Amount__c, Trade_Type__c, Deal_Date__c, Transaction_Fee__c,CurrencyIsoCode,
                    Price__c
             FROM Trade__c WHERE Id IN :trades]
        );

        // Fetch template
        EmailTemplate tmpl = [
            SELECT HtmlValue, Subject 
            FROM EmailTemplate 
            WHERE DeveloperName = 'Trade_Confirmation_Email_Template_1756826551851'
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Trade__c t : trades) {
            Trade__c trade = tradeMap.get(t.Id);
            Account acc = accountMap.get(trade.Account__c);
            if (acc == null || String.isBlank(acc.Email_for_Notifications__c)) continue;

            Boolean isSameCurrency = trade.Buy__c == trade.Sell__c;
            String subject = isSameCurrency
                ? 'Same Currency Payment Confirmed'
                : 'Foreign Currency Payment Confirmed';

            // Replace placeholders
            String body = tmpl.HtmlValue;
            body = body.replace('{{ClientName}}', acc.Name != null ? acc.Name : 'N/A');
            body = body.replace('{{ClientRefNumber}}', acc.Client_Code__c != null ? acc.Client_Code__c : 'N/A');
            body = body.replace('{{Amount}}', trade.Total_Amount__c != null ? trade.Total_Amount__c.setScale(2).format() : '0.00');
            body = body.replace('{{TickerSell}}', trade.Sell__c != null ? trade.Sell__c : 'N/A');
            body = body.replace('{{TickerBuy}}', trade.Buy__c != null ? trade.Buy__c : 'N/A');
            body = body.replace('{{ExchangeRate}}', trade.Price__c != null ? String.valueOf(trade.Price__c) : 'N/A');
            body = body.replace('{{TransactionFee}}', trade.Transaction_Fee__c != null ? String.valueOf(trade.Transaction_Fee__c) : '0.00');
            body = body.replace('{{Ticker}}', trade.CurrencyIsoCode != null ? String.valueOf(trade.CurrencyIsoCode) : '0.00');
            body = body.replace('{{SettlementDate}}', trade.Deal_Date__c != null ? trade.Deal_Date__c.format() : 'N/A');
            body = body.replace('{{BuyAmount}}', trade.Number_of_Tokens__c != null ? trade.Number_of_Tokens__c.setScale(2).format() : '0.00');
            body = body.replace('{{BuyTicker}}', trade.Buy__c != null ? trade.Buy__c : 'N/A');
            body = body.replace('{{ClientDealNumber}}', acc.Client_Code__c != null ? acc.Client_Code__c : 'N/A');

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { acc.Email_for_Notifications__c });
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }
}