/************************************************************************************************************************************
Author : Baban Shinde
Description : Batch class for case creation in new business and renewal.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
  1         SFDC-2059  	       21/09/2022    Baban Shinde
**************************************************************************************************************************************/
public class BatchForNewBusinessAndRenewal implements Database.Batchable<sObject>,Schedulable {
    public BatchForNewBusinessAndRenewal() {}
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        List<Batch_New_Business_And_Renewal_Helper__mdt> metadataSetting = [SELECT Id, Query__c FROM Batch_New_Business_And_Renewal_Helper__mdt WHERE DeveloperName= 'BatchForNewBusinessAndRenewal' LIMIT 1];
        if(metadataSetting != null && metadataSetting.size() > 0 && metadataSetting[0].Query__c != null && metadataSetting[0].Query__c != ''){
            //Off the trigger setting to avoid future exicution.
            TriggerSetting__c setting = TriggerSetting__c.getInstance('LangCaseTrigger');
            setting.Is_Active__c = false;
            update setting;
            
            String query = metadataSetting[0].Query__c;
            return Database.getQueryLocator(query);
        }
        return null;
    }
    
    public void execute(Database.BatchableContext BC, List<InsurancePolicy> lstInsurancePolicy){
        try {
            if(!lstInsurancePolicy.isEmpty()) {
                BatchForNewBusinessAndRenewalHelper.createCaseAssociatedToInsurancePolicy(lstInsurancePolicy);
            }
        }
        catch(exception ex) {
            system.debug('exception : ' + ex);
            smagicinteract__Error_Log__c exceptionLog = new smagicinteract__Error_Log__c();
            exceptionLog.smagicinteract__Class_Name__c = 'BatchForNewBusinessAndRenewal';
            exceptionLog.smagicinteract__Error_Message__c = ex.getMessage();
            exceptionLog.smagicinteract__Error_Type__c = 'Custom';
            exceptionLog.smagicinteract__Batch_Id__c = BC.getJobId();
            insert exceptionLog;
        }
    }
    
    public void finish(Database.BatchableContext BC){
        //On the trigger setting to avoid future exicution.
        TriggerSetting__c setting = TriggerSetting__c.getInstance('LangCaseTrigger');
        setting.Is_Active__c = true;
        update setting;
    }

    public void execute(SchedulableContext SC) {
        BatchForNewBusinessAndRenewal batchForNewBusinessAndRenewal = new BatchForNewBusinessAndRenewal(); 
        database.executebatch(batchForNewBusinessAndRenewal);
     }
}