trigger PaymentTrigger on Payment__c (before insert, after insert, after update) {
    // if (Trigger.isBefore && Trigger.isInsert) {
    //     PaymentTriggerHelper.handleBeforeInsert(Trigger.new);
    // }

    if (Trigger.isAfter && Trigger.isInsert) {
        if(Label.Error_in_Payment_Trigger=='No'){
            PaymentTriggerHelper.handleAfterInsert(Trigger.new);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        if(Label.Error_in_Payment_Trigger=='No'){
            PaymentTriggerHelper.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}