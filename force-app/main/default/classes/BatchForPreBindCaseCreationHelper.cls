/************************************************************************************************************************************
Author : Baban Shinde
Description : Handler class of batch for creating case records related to inspection on which case in missing.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         	SFDC-2027, 2028    01/09/2022    Baban Shinde
**************************************************************************************************************************************/
public class BatchForPreBindCaseCreationHelper {
    
    public static string preBindRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-Prebind').getRecordTypeId();
    
    public static void createCaseAssociatedToInspectionAndUpdate(Set<Id> inspectionIds) {
        if(!inspectionIds.isempty()) {
            List<Inspection__c> lstInspection = [SELECT Id, Lead__c, Case__c, Account__c FROM Inspection__c WHERE Id IN : inspectionIds];
            Set<Id> leadIds = new Set<Id>();
            
            //Collect Lead Id's to query lead and related Account information.
            for(Inspection__c inspection : lstInspection){
                if(inspection.Lead__c != null) {
                    leadIds.add(inspection.Lead__c);
                }
            }
            
            //Query the lead and create missing case for each inspections.
            if(!leadIds.isempty()) {
                List<Case> lstCase = new List<Case>();
                List<Lead> leadWithAccount = new List<Lead>();
                List<Lead> leadWithoutAccount = new List<Lead>();
                List<Lead> leadWithNewAccount = new List<Lead>();
                List<Lead> newLeadWithNewAccount = new List<Lead>();
                List<Case> casesToCreate = new List<Case>();
                
                List<Lead> lstLead = [SELECT Id, FirstName, LastName, Email, Phone, Name, Street, City, State, Country, Zip_code__c, Account__c, Account__r.PersonBirthdate, Account__r.PersonEmail, Account__r.Phone, Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry, Account__r.Zipcode__c  FROM Lead WHERE Id IN : leadIds ORDER BY CreatedDate DESC];
                for(Lead lead : lstLead) {
                    if(lead.Account__c != null) {
                        leadWithAccount.add(lead);
                    } else {
                        leadWithoutAccount.add(lead);
                    }
                }
                
                //Create cases with existing accounts.
                if(!leadWithAccount.isempty()) {
                    List<Case> caseResult = buildCasesWithExistingAccount(leadWithAccount);
                    if(!caseResult.isempty()) {
                        casesToCreate.addAll(caseResult);
                    }
                }
                
                //map the existing accounts to the lead if found.
                if(!leadWithoutAccount.isempty()) {
                    leadWithNewAccount = mapExistingAccountWithLead(leadWithoutAccount);
                }
                
                //Create cases with existing account if found, else create new account and assign.
                if(!leadWithNewAccount.isempty()) {                   
                    List<Case> caseResult = buildCasesWithNewAccount(leadWithNewAccount);
                    casesToCreate.addAll(caseResult);
                }
                //Remove the duplicate cases.
                if(!casesToCreate.isempty()) {
                    lstCase = removeDuplicateCases(casesToCreate, 'Prebind', preBindRecId);
                }
                if(!lstCase.isempty()) {
                    upsert lstCase;
                    
                    //Create the tasks related to cases.
                    List<Task> lstTask = buildTasksRelatedToCases(lstCase);
                    if(!lstTask.isempty()) {
                        insert lstTask;
                    }
                }

                //Map the cases to respective Inspection record.
                if(!lstCase.isempty()) {
                    for(Inspection__c inspection : lstInspection){
                        for(Lead objLead : lstLead){
                            for(Case objCase : lstCase) {
                                if(inspection.Lead__c == objLead.Id && objLead.Account__c == objCase.Name_of_Primary_Insured__c) {
                                    inspection.Case__c = objCase.Id;
                                    inspection.Account__c = objCase.Name_of_Primary_Insured__c;
                                }
                            }
                        }
                    }
                    Update lstInspection;
                }
            }
        }
    }
    
    Public static List<Case> buildCasesWithExistingAccount(List<Lead> lstLead) {
        List<Case> lstCaseResult = new List<Case>();
        for(Lead lead : lstLead) {
            Case objCase = new Case();
            objCase.RecordTypeId = preBindRecId;
            objCase.Client_Email_Address__c = lead.Account__r.PersonEmail;
            objCase.Client_Secondary_Phone__c = lead.Account__r.Phone;
            objCase.Street__c = lead.Account__r.BillingStreet;
            objCase.State__c = lead.Account__r.BillingState;
            objCase.Source__c = 'Underwriting Pilot';
            objCase.City__c = lead.Account__r.BillingCity;
            if(lead.Account__r != null && lead.Account__r.Zipcode__c != null ) {
                objCase.Zip__c = String.ValueOf(lead.Account__r.Zipcode__c);
            }
            objCase.Name_of_Primary_Insured__c = lead.Account__c;
            objCase.Lead_and_Referral__c = lead.Id;
            lstCaseResult.add(objCase);
        }
        return lstCaseResult;
    }
    
    Public static List<Lead> mapExistingAccountWithLead(List<Lead> lstLead) {
        set<string> emailIds = new set<string>();
        for(Lead lead : lstLead) {
            if(lead.Email != null && lead.Email != '') {
                emailIds.add(lead.Email);
            }
        }
        if(!emailIds.isempty()) {
            List<Account> lstAccount = [SELECT Id, PersonEmail, BillingCity, BillingState, BillingCountry, Phone, BillingStreet, Name FROM Account WHERE PersonEmail IN :emailIds ORDER BY CreatedDate DESC];
            if(!lstAccount.isempty()) {
                for(Lead lead : lstLead) {
                    for(Account account : lstAccount) {
                        if(account.PersonEmail == lead.Email && account.Phone == lead.Phone && account.Name == lead.Name ) {
                            if(account.BillingStreet == lead.Street && account.BillingCity == lead.City && account.BillingState == lead.State && account.BillingCountry == lead.Country) {
                                lead.Account__c = account.Id;
                                break;
                            }
                        }
                    }
                }
            }
        }
        return lstLead;
    }
    
    Public static List<Case> buildCasesWithNewAccount(List<Lead> lstLead) {
        List<Case> lstCaseResult = new List<Case>();
        List<Account> lstAccount = new List<Account>();
        if(!lstLead.isempty()) {
            lstAccount = buildAccountWithLead(lstLead);
        }
        if(!lstAccount.isempty()) {
            insert lstAccount;
        }
        if(!lstAccount.isempty()) {
            for(Lead lead : lstLead) {
                for(Account account : lstAccount) {
                    if(account.PersonEmail == lead.Email && account.FirstName == lead.FirstName && account.LastName == lead.LastName && account.BillingCity == lead.City && account.BillingState == lead.State && account.BillingStreet == lead.Street && account.Phone == lead.Phone) {
                        lead.Account__c = account.Id;
                    }
                } 
            }
        }
        if(!lstLead.isempty()) {
            lstCaseResult = buildCasesWithExistingLead(lstLead);
            update lstLead;
        }
        return lstCaseResult;
    }
    
    Public static List<Case> buildCasesWithExistingLead(List<Lead> lstLead) {
        List<Case> lstCaseResult = new List<Case>();
        for(Lead lead : lstLead) {
            Case objCase = new Case();
            objCase.RecordTypeId = preBindRecId;
            objCase.Client_Email_Address__c = lead.Email;
            objCase.Client_Secondary_Phone__c = lead.Phone;
            objCase.Street__c = lead.Street;
            objCase.State__c = lead.State;
            objCase.Source__c = 'Underwriting Pilot';
            objCase.City__c = lead.City;
            objCase.Zip__c = String.ValueOf(lead.Zip_code__c);
            objCase.Name_of_Primary_Insured__c = lead.Account__c;
            objCase.Lead_and_Referral__c = lead.Id;
            lstCaseResult.add(objCase);
        }
        return lstCaseResult;
    }
    
    Public static List<Case> removeDuplicateCases(List<Case> lstCaseResult, String queueName, String recId) {
        List<Case> lstCase = new List<Case>();
        set<Id> accountIds = new set<Id>();
        set<Id> setCaseID = new set<Id>();
        Map<Id, List<Case>> mapAccountCase = new Map<Id, List<Case>>();
        Id queueId = null;
        List<Group> lstGroup = [SELECT Id FROM Group where Type='Queue' and name = :queueName LIMIT 1];
        if(!lstGroup.isempty()) {
            queueId = lstGroup[0].Id;
        }
        for(Case caseResult : lstCaseResult) {
            if(caseResult.Name_of_Primary_Insured__c != null) {
                accountIds.add(caseResult.Name_of_Primary_Insured__c);
            }
        }
        if(!accountIds.isempty()) {
            lstCase = [SELECT Id , Name_of_Primary_Insured__c, OwnerId FROM Case WHERE RecordTypeId = :recId 
                                      AND Name_of_Primary_Insured__c IN : accountIds AND (Status ='Open' OR Status ='New')
                                      ORDER BY CreatedDate DESC];
        }
        if(!lstCase.isempty()) {
            for(Case objCase : lstCaseResult) {
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
            for(Case objCase : lstCaseResult) {
                if (!setCaseID.contains(objCase.Id)){
                    objCase.OwnerId = queueId;
                }
            }
        }
        return lstCaseResult;
    }
    
    Public static List<Account> buildAccountWithLead(List<Lead> lstLead) {
        List<Account> lstAccount = new List<Account>();
        for(Lead lead : lstLead) {
            if(lead.Account__c == null) {
                Account account = new Account();
                account.BillingCity = lead.City;
                account.BillingCountry = lead.Country;
                account.BillingState = lead.State;
                account.BillingStreet = lead.Street;
                account.FirstName = lead.FirstName;
                account.LastName = lead.LastName;
                if(lead.Zip_Code__c != null && lead.Zip_Code__c != '') {
                    account.Zipcode__c = Integer.valueOf(lead.Zip_Code__c);
                }
                account.PersonEmail = lead.Email;
                account.Phone = lead.Phone;
                lstAccount.add(account);
            }
        }
        return lstAccount;
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
                    task.WhatId = caseObj.Id;
                    lstTask.add(task);
                }
            }
        }
        return lstTask;
    }
}