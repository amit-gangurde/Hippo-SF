global class IntegrationErrorLogBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful,Schedulable  {
    global void execute(SchedulableContext SC) {
    	 Database.executeBatch(new IntegrationErrorLogBatch());
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(Test.isRunningTest()){
           String query = 'SELECT Id, Name FROM Integration_Error_Log__c';
        return Database.getQueryLocator(query); 
        }else{
         String query = 'SELECT Id, Name FROM Integration_Error_Log__c WHERE CreatedDate = LAST_N_DAYS:90';
        return Database.getQueryLocator(query);
        }
    }
    global void execute(Database.BatchableContext bc, List<sObject> records){
        delete records;
    }    
    global void finish(Database.BatchableContext bc){
       
    }
}