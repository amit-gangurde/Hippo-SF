trigger NewCaseTrigger on Case (after update , before update , before insert) {
    try {
        if(Trigger.isAfter && Trigger.isUpdate){
            // Whenever case owner get changed , change the owner of related Tasks.
            NewCaseTriggerHelper.checkOwnerChangeCasesAndUpdate(trigger.new, trigger.oldMap); 
        }
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ){
            // This is used for Omni Channel Secondary Routing.
            NewCaseTriggerHelper.sourceBasedPriorityDecision(Trigger.new); 
        }
    } catch(exception ex) {
        smagicinteract__Error_Log__c exceptionLog = new smagicinteract__Error_Log__c();
        exceptionLog.smagicinteract__Class_Name__c = 'NewCaseTrigger';
        exceptionLog.smagicinteract__Error_Message__c = ex.getMessage();
        exceptionLog.smagicinteract__Error_Type__c = 'Custom';
        insert exceptionLog;
    }
}