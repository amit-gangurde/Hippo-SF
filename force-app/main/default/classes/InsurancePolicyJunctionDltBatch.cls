public class InsurancePolicyJunctionDltBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id FROM Insurance_Policy_License__c';//
            return Database.getQueryLocator(query);
     }
    
    public void execute(Database.BatchableContext BC, List<Insurance_Policy_License__c> insurepolicyLst) {
       delete insurepolicyLst;
    }   
    
    public void finish(Database.BatchableContext BC) {
        System.debug('****InsurencePolicyMatchingJob Executed Successfully***********');
    }
}