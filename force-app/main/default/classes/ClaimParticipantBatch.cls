global class ClaimParticipantBatch implements Database.Batchable<String>,Database.AllowsCallouts,Database.stateful  {
    public List<String> calloutLst = new List<String>();
    global ClaimParticipantBatch(List<String> calloutLst){
        this.calloutLst = calloutLst;
    }
    global Iterable<String> start(Database.BatchableContext info){
        return new CustomIterableString(calloutLst); 
    }
    global void execute(Database.BatchableContext info, List<String> sObjectList){
        for(String s: sObjectList){
            ClaimParticipantTriggerHandler.calloutHelper(s);
        }
    }    
    global void finish(Database.BatchableContext bc){
        System.debug('**********Batch Completed++++++++++++++++++');
    }
}