global class BatchClaimCatEvent implements Database.Batchable<sObject>,Schedulable {
  

   global BatchClaimCatEvent(){
	 
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      String query = 'SELECT Id FROM Claim WHERE Claim_Cat_Event__c = NULL AND Peril__c != null AND State__c != null AND Date_of_Loss__c != null';
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
     Set<Id> claimIds = new Set<Id>();
       for(sobject s : scope){
     	 claimIds.add(s.Id);
       }
       if(!claimIds.isEmpty()) {
     		Map<Id, Claim> claimsToUpdate = ClaimTriggerHandler.buildClaimsToUpdate(claimIds, false);
            if (!claimsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(claimsToUpdate.values(), false);
        }
       }
    }

   global void finish(Database.BatchableContext BC){
   }
    global void execute(SchedulableContext SC) {
      
      BatchClaimCatEvent batchClaimCatEvent = new BatchClaimCatEvent(); 
      database.executebatch(batchClaimCatEvent);
   }
}