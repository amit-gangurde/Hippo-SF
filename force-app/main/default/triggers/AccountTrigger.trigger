trigger AccountTrigger on Account (after insert, after delete, after update) {

    new AccountTriggerHandler().run();

     Hippo_Last_Sync__c hippo = Hippo_Last_Sync__c.getOrgDefaults();
    if( Trigger.isAfter &&  !Trigger.isDelete && AccountSync.isRecursive == false && hippo.Account_Trigger_Active__c){
        AccountSync.isRecursive = true;
        AccountSyncHelper.getAccount(trigger.new,trigger.oldMap);
    }
    
}