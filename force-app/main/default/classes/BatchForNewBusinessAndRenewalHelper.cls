/************************************************************************************************************************************
Author : Baban Shinde
Description : Batch class  helper for case creation in new business and renewal.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
  1         SFDC-2059  	       21/09/2022    Baban Shinde
**************************************************************************************************************************************/
public class BatchForNewBusinessAndRenewalHelper {
    public static string newBusinessRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-New Business').getRecordTypeId();
    public static string renewalRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-Renewal').getRecordTypeId();

    public static void createCaseAssociatedToInsurancePolicy(List<InsurancePolicy> listInsurancePolicy) {
        if(!listInsurancePolicy.isempty()) {
            List<Case> caseLst = new List<Case>();
            map<Id, Inspection__c> mapIdInspection = new map<Id, Inspection__c>();
            List<InsurancePolicy> lstNewBusinessInsurancePolicy = new List<InsurancePolicy>();
            List<InsurancePolicy> lstRenewalInsurancePolicy = new List<InsurancePolicy>();
            for(InsurancePolicy insurancePolicy : listInsurancePolicy) {
                if(insurancePolicy.Is_New_Business_Case_Required__c) {
                    lstNewBusinessInsurancePolicy.add(insurancePolicy);
                } else if(insurancePolicy.Is_Renewal_Case_Required__c) {
                    lstRenewalInsurancePolicy.add(insurancePolicy);
                }
            }
            
            //Build cases for New Business.
            if(!lstNewBusinessInsurancePolicy.isEmpty()) {
                caseResult newCaseResult = buildCaseAssociatedToInsurancePolicy(lstNewBusinessInsurancePolicy, newBusinessRecId);
                if(!newCaseResult.cases.isempty()) {
                    if(!newCaseResult.mapIdInspection.isEmpty()) {
                        mapIdInspection.putAll(newCaseResult.mapIdInspection);
                    }
                    List<Case> cases = removeDuplicateCases(newCaseResult.cases,'New Business', newBusinessRecId);
                    if(!cases.isempty()){
                        caseLst.addAll(cases);
                    }
                }
            }
            
            //Build cases for Renewal.
            if(!lstRenewalInsurancePolicy.isEmpty()) {
                caseResult newCaseResult = buildCaseAssociatedToInsurancePolicy(lstRenewalInsurancePolicy, renewalRecId);
                if(!newCaseResult.cases.isempty()) {
                    if(!newCaseResult.mapIdInspection.isEmpty()) {
                        mapIdInspection.putAll(newCaseResult.mapIdInspection);
                    }
                    List<Case> cases = removeDuplicateCases(newCaseResult.cases,'Renewal', renewalRecId);
                    if(!cases.isempty()){
                        caseLst.addAll(cases);
                    }
                }
            }
            
            if(!caseLst.isempty()) {
                upsert caseLst;
                
                //collect only new business cases to create tasks related to it
                List<Case> casesToCreateTask = new List<Case>();
                for(Case caseObj : caseLst) {
                    if(caseObj.RecordTypeId == newBusinessRecId) {
                        casesToCreateTask.add(caseObj);
                    }
                }
                
                if(!casesToCreateTask.isEmpty()) {
                    List<Task> lstTask = buildTasksRelatedToCases(casesToCreateTask);
                    if(!lstTask.isempty()) {
                        insert lstTask;
                    }
                }
            }

            //Update related inspection with newly created case if that inspection dosent contains any case related to it.
            if(!mapIdInspection.isEmpty()) {
                List<Inspection__c> lstInspection = buildInspectionWithCase(caseLst, mapIdInspection);
                if(!lstInspection.isEmpty()) {
                    update lstInspection;
                }
            }
            
            //Update the policy.
            for(InsurancePolicy insurancePolicy : listInsurancePolicy) {
                if(insurancePolicy.Is_New_Business_Case_Required__c) {
                    insurancePolicy.Is_New_Business_Case_Required__c = false;
                } else if(insurancePolicy.Is_Renewal_Case_Required__c) {
                    insurancePolicy.Is_Renewal_Case_Required__c = false;
                }
            }
            update listInsurancePolicy;
        }
    }
    
    public static caseResult buildCaseAssociatedToInsurancePolicy(List<InsurancePolicy> listInsurancePolicy, string recId) {
        List<Case> lstCase = new List<Case>();
        map<Id, Inspection__c> mapIdInspection = new map<Id, Inspection__c>();
        for(InsurancePolicy insurancePolicy : listInsurancePolicy) {
            Case objCase = new Case();
            objCase.RecordTypeId = recId;
            objCase.Client_Email_Address__c = insurancePolicy.NameInsured.PersonEmail;
            objCase.Client_Secondary_Phone__c = insurancePolicy.NameInsured.Phone;
            objCase.Street__c = insurancePolicy.NameInsured.BillingStreet;
            objCase.State__c = insurancePolicy.NameInsured.BillingState;
            objCase.Source__c = 'Underwriting Pilot';
            objCase.City__c = insurancePolicy.NameInsured.BillingCity;
            objCase.Zip__c = String.ValueOf(insurancePolicy.NameInsured.Zipcode__c);
            objCase.Name_of_Primary_Insured__c = insurancePolicy.NameInsuredId;
            objCase.Insurance_Policy__c = insurancePolicy.Id;
            //if any inspection is related to policy then we need to link inspection(recently created) with case.
            if(insurancePolicy.Inspections__r != null && !insurancePolicy.Inspections__r.isEmpty()) {
                mapIdInspection.put(insurancePolicy.Id, insurancePolicy.Inspections__r[0]);
            }
            lstCase.add(objCase);
        }
        return New caseResult(lstCase, mapIdInspection);
    }
   
    Public static List<Case> removeDuplicateCases(List<Case> caseLst, String queueName, String recId) {
        List<Case> lstCase = new List<Case>();
        set<Id> accountIds = new set<Id>();
        Id queueId = null;
        set<Id> setCaseID = new set<Id>();
        List<Group> lstGroup = [SELECT Id FROM Group where Type='Queue' and name = :queueName LIMIT 1];
        if(!lstGroup.isempty()) {
            queueId = lstGroup[0].Id;
        }
        for(Case objCase : caseLst) {
            if(objCase.Name_of_Primary_Insured__c != null) {
                accountIds.add(objCase.Name_of_Primary_Insured__c);
            }
        }
        if(!accountIds.isempty()) {
            lstCase = [SELECT Id , Name_of_Primary_Insured__c, OwnerId FROM Case WHERE RecordTypeId = :recId 
                                      AND Name_of_Primary_Insured__c IN : accountIds AND (Status ='Open' OR Status ='New')
                                      ORDER BY CreatedDate DESC];
        }
        
        if(!lstCase.isempty()) {
            for(Case objCase : caseLst) {
                for(Case caseObj : lstCase) {
                    if(objCase.Name_of_Primary_Insured__c == caseObj.Name_of_Primary_Insured__c) {
                        objCase.Id = caseObj.Id;
                        setCaseID.add(caseObj.Id);
                        break;
                    }
                }
            }
        }
        if(queueId != null) {
            for(Case objCase : caseLst) {
                if (!setCaseID.contains(objCase.Id)){
                    objCase.OwnerId = queueId;
                }
            }
        }
        return caseLst;
    }
    
    public static List<Inspection__c> buildInspectionWithCase(List<Case> listCase, map<Id, Inspection__c> mapIdInspection) {
        List<Inspection__c> lstInspection = new List<Inspection__c>();
        for(Case caseObj : listCase) {
            if(mapIdInspection.containsKey(caseObj.Insurance_Policy__c)) {
                Inspection__c inspection = mapIdInspection.get(caseObj.Insurance_Policy__c);
                Inspection__c newInspection = new Inspection__c();
                newInspection.Id = inspection.Id;
                newInspection.Case__c = caseObj.Id;
                lstInspection.add(newInspection);
            }
        }
        return lstInspection;
    }
    
    Public static List<Task> buildTasksRelatedToCases(List<Case> lstCase) {
        
        String UnderwritingRecId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Underwriting').getRecordTypeId();
        
        //Fech the metadata for task subjects.
        List<Task_Subjects__mdt> taskSubjects = [SELECT Id, Task_Subjects__c FROM Task_Subjects__mdt WHERE DeveloperName='UnderwritingTasksSubjects' LIMIT 1];
        List<String> subjects = new List<String>();
        
        if(taskSubjects != null && taskSubjects.size() > 0 && taskSubjects[0].Task_Subjects__c != '') {
            subjects = taskSubjects[0].Task_Subjects__c.split(',');
        }
        
        //Create the tasks depending upon the number of subjects.
        List<Task> lstTask = new List<Task>();
        if(!subjects.isEmpty()) {
            for(Case caseObj : lstCase) {
                for(integer index = 0; index < subjects.size() ; index++) {
                    Task task = new Task();
                    if(caseObj.OwnerId != null)
                        task.OwnerId = caseObj.OwnerId;
                    task.Priority = 'Normal';
                    task.Status = 'Open';
                    task.Subject = subjects[index];
                    task.RecordTypeId = UnderwritingRecId;
                    lstTask.add(task);
                }
            }
        }
        return lstTask;
    }
    
    public class caseResult {
        public List<Case> cases;
        public map<Id, Inspection__c> mapIdInspection;
        public caseResult (List<Case> cases, map<Id, Inspection__c> mapIdInspection) {
            this.cases = cases;
            this.mapIdInspection = mapIdInspection;
        }
    }
}