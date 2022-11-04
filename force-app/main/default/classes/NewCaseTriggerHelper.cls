/************************************************************************************************************************************
Author : Baban Shinde
Description : Class to update the task owner if case owner get changed.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
  1         			       05/10/2022    Baban Shinde
**************************************************************************************************************************************/
public class NewCaseTriggerHelper {
    
    //Check whether case owner is changed and update related tasks owner also.
    public static void checkOwnerChangeCasesAndUpdate(List<Case> listCase, map<Id, Case> oldCaseMap) {
        List<Case> cases = new List<Case>();
        set<Id> caseIds = new set<Id>();
        List<Task> lstTask = new List<Task>();
        
        for(Case objCase : listCase) {
            if(oldCaseMap.containsKey(objCase.Id)) {
                Case oldCase = oldCaseMap.get(objCase.Id);
                if (oldCase != null && oldCase.OwnerId != objCase.OwnerId)
                {
                    caseIds.add(objCase.Id);
                }
            }
        }
        if(!caseIds.isEmpty()) {
            lstTask = updateTasksRelatedToCases(caseIds);
        }
    }
    
    //Update the related tasks owner with changed case owner.
    Public static List<Task> updateTasksRelatedToCases(set<Id> caseIds) {
        List<Task> lstTask = new List<Task>();
        
        if(!caseIds.isEmpty()) {
            List<Case> listCase = [SELECT Id, OwnerId, (SELECT Id, OwnerId FROM Tasks) FROM Case WHERE Id = :caseIds];
            if(!listCase.isEmpty()) {
                for(Case objCase : listCase) {
                    if(objCase.Tasks != null && objCase.Tasks.size() > 0) {
                        for(Task objTask : objCase.Tasks) {
                            objTask.OwnerId = objCase.OwnerId;
                            lstTask.add(objTask);
                        }
                    }
                }
            }
        }
        if(!lstTask.isEmpty()) {
            update lstTask;
        }
        return lstTask;
    }
    
    public static void sourceBasedPriorityDecision(List<Case> listCase) {

        Set<String> recordIds = new Set<String>();
        
        string newBusinessRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-New Business').getRecordTypeId();
        string renewalRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-Prebind').getRecordTypeId();
        string prebindRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-Renewal').getRecordTypeId();
        
        recordIds.add(newBusinessRecId);
        recordIds.add(renewalRecId);
        recordIds.add(prebindRecId);
        
        for(Case objCase : listCase) {
            system.debug('objCase.Source__c === ' + objCase.Source__c);
            system.debug('recordIds == ' + recordIds);
             system.debug('objCase.RecordTypeId == ' + objCase.RecordTypeId);
            if( objCase.Source__c != null && !recordIds.contains(objCase.RecordTypeId)){
                if(objCase.Source__c == 'Non-Payment' || objCase.Source__c == 'Warm Transfer'){
                    objCase.Case_Priority__c='1';                    
                }
                else if(objCase.Source__c == 'Smart Home' || objCase.Source__c == 'Voicemail'){
                    objCase.Case_Priority__c='2';
                }
                else if(objCase.Source__c == 'Renewal Outbound' || objCase.Source__c == 'Missing Loan Number'){
                    objCase.Case_Priority__c='4';
                }    
                else if(objCase.Source__c == 'NPS'){
                    objCase.Case_Priority__c='5';
                } 
              
            }            
        } 
        
    }
}