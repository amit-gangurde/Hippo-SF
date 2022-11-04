/************************************************************************************************************************************
Author : Baban Shinde
Description : Test class for batch which will create case records related to inspection on which case in missing.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
  1         			       19/09/2022    Baban Shinde
**************************************************************************************************************************************/
@isTest
public class TestBatchForPreBindCaseCreation {
    
    //Create the records for batch test.
    @testSetup
    static void setup() {
        TriggerSetting__c setting = new TriggerSetting__c();
        setting.Is_Active__c = true;
        setting.Name = 'LangCaseTrigger';
        insert setting;
        
        //This settings are used for lead trigger.
        List<Hippo_Settings__c> hippoSettings = new List<Hippo_Settings__c>();
        Hippo_Settings__c hippoSetting = new Hippo_Settings__c();
        hippoSetting.Name = 'Excluded Lead Record Types';
        hippoSetting.Value__c = 'Web Leads - Producers;Web Leads - Default;Email Lead';
        hippoSettings.add(hippoSetting);
        
        Hippo_Settings__c newHippoSetting = new Hippo_Settings__c();
        newHippoSetting.Name = 'Inside Sales Contractors States';
        newHippoSetting.Value__c = 'CA;ca;IL;il;md;MD';
        hippoSettings.add(newHippoSetting);
        insert hippoSettings; 

        //Create Account, related lead.
        Lead objLead = UnitTestHelper.prepareB2BLeadWithAccount(true, true);
        String InspectionName = objLead.FirstName + ' ' + objLead.LastName;
        Inspection__c inspection = UnitTestHelper.prepareInspectionWithGivenLead(true, objLead.Id, objLead.Account__c, InspectionName);
        
        //Create lead without account but matching account is exist in database.
        Lead newObjLead = UnitTestHelper.prepareB2BLeadWithAccount(true, false);
        Inspection__c newInspection = UnitTestHelper.prepareInspectionWithGivenLead(true, newObjLead.Id, null, InspectionName);
        
        //Create lead without account and no matching account is exist in database.
        Lead newLeadObj = UnitTestHelper.prepareB2BLeadWithoutAccount(true);
        Inspection__c objInspection = UnitTestHelper.prepareInspectionWithGivenLead(true, newLeadObj.Id, null, newLeadObj.FirstName + ' ' + newLeadObj.LastName);
    }

    //Positive scenario.
    static testMethod void BatchForPreBindCaseCreationTest() {
        Datetime inspectionCreatedTime = datetime.now().addhours(-72);
        List<Inspection__c> lstInspections = [SELECT Id, Lead__c FROM Inspection__c WHERE createdDate >=:inspectionCreatedTime AND Case__c = null];
        system.assertEquals(3, lstInspections.size());
        
        Test.startTest();
        BatchForPreBindCaseCreation obj = new BatchForPreBindCaseCreation();
        Database.executeBatch(obj);
        Test.stopTest();
       
        List<Inspection__c> lstInspection = [SELECT Id, Lead__c FROM Inspection__c WHERE createdDate >=:inspectionCreatedTime AND Case__c = null];
        system.assertEquals(0, lstInspection.size());
    }
    
    //Negative scenario
    static testMethod void BatchForPreBindCaseCreationTestException() {
        String preBindRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-Prebind').getRecordTypeId();
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        Case objCase = new Case();
        objCase.RecordTypeId = preBindRecId;
        objCase.Name_of_Primary_Insured__c = lstAccount[0].Id;
        insert objCase;
        
        Test.startTest();
        BatchForPreBindCaseCreation obj = new BatchForPreBindCaseCreation();
        Database.executeBatch(obj);
        Test.stopTest();
        
        Datetime inspectionCreatedTime = datetime.now().addhours(-72);
        List<Inspection__c> lstInspection = [SELECT Id, Lead__c FROM Inspection__c WHERE createdDate >=:inspectionCreatedTime AND Case__c = null];
        system.assertEquals(3, lstInspection.size());
    }
}