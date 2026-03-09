trigger TradeTrigger on Trade__c (after insert, after update) {
    if (Label.Error_in_Trade_Trigger == 'No') {
        if (Trigger.isAfter && Trigger.isInsert) {
            TradeTriggerHandler.handleAfterInsert(Trigger.new);
        }

        if (Trigger.isAfter && Trigger.isUpdate) {
            TradeTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}