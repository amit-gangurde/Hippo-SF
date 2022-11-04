/************************************************************************************************************************************
Author : Baban Shinde
Description : Batch class for creating case records related to inspection on which case in missing.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         	SFDC-2027, 2028     01/09/2022     Baban Shinde
**************************************************************************************************************************************/
public class BatchForPreBindCaseCreation implements Database.Batchable<sObject>,Schedulable {
    public BatchForPreBindCaseCreation() {}
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        List<Batch_Pre_Bind_Helper__mdt> metadataSetting = [SELECT Id, Time_In_Minutes_For_Query__c, Query__c FROM Batch_Pre_Bind_Helper__mdt WHERE DeveloperName= 'BatchPreBindMapInspectionCase' LIMIT 1];
        if(metadataSetting != null && metadataSetting.size() > 0 && metadataSetting[0].Query__c != null && metadataSetting[0].Query__c != ''){
            //Off the trigger setting to avoid future exicution.
            TriggerSetting__c setting = TriggerSetting__c.getInstance('LangCaseTrigger');
            if(setting.Is_Active__c) {
                setting.Is_Active__c = false;
            	update setting;
            }
            
            String query = metadataSetting[0].Query__c;
            if(metadataSetting[0].Time_In_Minutes_For_Query__c != null) {
                Integer timeValue = Integer.valueOf(metadataSetting[0].Time_In_Minutes_For_Query__c);
            	Datetime inspectionCreatedTime = datetime.now().addhours(timeValue);
                query = query + ' AND createdDate >=:inspectionCreatedTime';
            }
            return Database.getQueryLocator(query);
        }
        return null;
    }
    
    public void execute(Database.BatchableContext BC, List<Inspection__c> lstInspection){
        try {
            Set<Id> inspectionIds = new Set<Id>();
            for(Inspection__c inspection : lstInspection){
                inspectionIds.add(inspection.Id);
            }
            if(!inspectionIds.isEmpty()) {
                BatchForPreBindCaseCreationHelper.createCaseAssociatedToInspectionAndUpdate(inspectionIds);
            }
        } catch(exception ex) {
            smagicinteract__Error_Log__c exceptionLog = new smagicinteract__Error_Log__c();
            exceptionLog.smagicinteract__Class_Name__c = 'BatchForPreBindCaseCreation';
            exceptionLog.smagicinteract__Error_Message__c = ex.getMessage();
            exceptionLog.smagicinteract__Error_Type__c = 'Custom';
            exceptionLog.smagicinteract__Batch_Id__c = BC.getJobId();
            insert exceptionLog;
        }
    }
    
    public void finish(Database.BatchableContext BC){
        //On the trigger setting deactivated in start method.
        TriggerSetting__c setting = TriggerSetting__c.getInstance('LangCaseTrigger');
        setting.Is_Active__c = true;
        update setting;
    }

    public void execute(SchedulableContext SC) {
        BatchForPreBindCaseCreation batchForPreBindCaseCreation = new BatchForPreBindCaseCreation(); 
        database.executebatch(batchForPreBindCaseCreation);
     }
}