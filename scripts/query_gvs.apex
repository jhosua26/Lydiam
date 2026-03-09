for(Schema.PicklistEntry pe : Schema.Account.Nationality__c.getDescribe().getPicklistValues()) {
    System.debug('Nationality: ' + pe.getValue() + ' active=' + pe.isActive());
}
for(Schema.PicklistEntry pe : Schema.Account.Legal_Entity_Type__c.getDescribe().getPicklistValues()) {
    System.debug('Legal_Entity_Type: ' + pe.getValue() + ' active=' + pe.isActive());
}
