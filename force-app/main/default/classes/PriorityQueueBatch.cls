/************************************************************************************************************************************
Author : Amit Gangurde
Description : Batch class for On case Object for decide priority of case on the basis of lastaction,probability and inspection score.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         	SFDC-2192          17/10/2022    Amit Gangurde       Initial Development
**************************************************************************************************************************************/
global class PriorityQueueBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc){ 
        
        Set<String> recordTypes = new Set<String>();
        String Query = null;
        
        List <UW_Record_Type__mdt> recordTypeSetting = [SELECT MasterLabel FROM UW_Record_Type__mdt where Lead_Based__c != true ]; 
        for(UW_Record_Type__mdt obj : recordTypeSetting ){
            recordTypes.add(obj.MasterLabel);
        }        
        
        Query ='select Id,Recordtype.name, Inspection_Score__c, Last_Action_Date__c, Priority_Score__c  FROM Case where Last_Action_Date__c != null and Priority_Score__c != null and Inspection_Score__c != null and Recordtype.name IN : recordTypes';
        return Database.getQueryLocator(Query);
        
    }
    global void execute(Database.BatchableContext bc,  List<Case> caseList){
        
        try{
            if(!caseList.isEmpty()) {    
                PriorityQueueBatchHelper.processCases(caseList);
            }
        }
        catch(exception ex) {
            smagicinteract__Error_Log__c exceptionLog = new smagicinteract__Error_Log__c();
            exceptionLog.smagicinteract__Class_Name__c = 'PriorityQueueBatch';
            exceptionLog.smagicinteract__Error_Message__c = ex.getMessage();
            insert exceptionLog;
        }
        
        
    }
    global void finish(Database.BatchableContext bc){
        
    }
    
}