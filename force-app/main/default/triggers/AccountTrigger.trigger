trigger AccountTrigger on Account (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountStatusHandler.handleStatusChange(Trigger.new, Trigger.oldMap);
    }
}