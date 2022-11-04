/*******************************************************************************************
* @Name         InsurencePolicyMatchingJob
* @Author       Convene-tech
* @Date         12/16/2021
* @Description  This class query Insurency Policy and perform license matching
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      12/24/2021          Modified
*******************************************************************************************/
public class InsurencePolicyMatchingJob implements Database.Batchable<sObject>,Schedulable{
    public void execute (SchedulableContext ctx) { 
        Database.executeBatch(new InsurencePolicyMatchingJob(),50);
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        if(!Test.isRunningTest()){  
        String query = 'SELECT Id,Name,ProducerId,Producer.ContactId,Producer__c,State__c FROM InsurancePolicy WHERE Producer__c!=null and LastModifiedDate=YESTERDAY';//
        return Database.getQueryLocator(query);
        }else{
        String query = 'SELECT Id,Name,ProducerId,Producer.ContactId,State__c,Producer__c FROM InsurancePolicy WHERE Producer__c!=null ';//AND Id =\'0YT210000005QkVGAU\'';
        return Database.getQueryLocator(query);    
        }
    }
     
    public void execute(Database.BatchableContext BC, List<InsurancePolicy> insurepolicyLst) {
       InsurencePolicyMatchingJobHandler.handlePolicyLicenseMatching(insurepolicyLst);
    }   
     
    public void finish(Database.BatchableContext BC) {
       System.debug('****InsurencePolicyMatchingJob Executed Successfully***********');
    }
}