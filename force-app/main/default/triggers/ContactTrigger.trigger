trigger ContactTrigger on Contact (after insert, after delete,after update) {

       new ContactTriggerHandler().run();
  
    
       Hippo_Last_Sync__c hippo = Hippo_Last_Sync__c.getOrgDefaults();

   if( Trigger.isAfter && !Trigger.isDelete && AccountSync.isRecursive == false && hippo.Contact_Trigger_Active__c){
        AccountSync.isRecursive = true;
        AccountSyncHelper.getContact(trigger.new,trigger.oldMap);
    }
}