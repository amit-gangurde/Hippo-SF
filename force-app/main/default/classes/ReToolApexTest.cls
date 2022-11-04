/************************************************************************************************************************************
Author : Amit Gangurde
Description : This Test class used in the LWC component for the ReTool Application .
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         			           22/09/2022     Amit Gangurde     Initial Development
**************************************************************************************************************************************/
@isTest
public class ReToolApexTest {
    @testSetup 
    static void setup() {       
        
        //Trigger Setting for the LangCaseTrigger
        TriggerSetting__c setting = New TriggerSetting__c();
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
        
        //Create Test Lead with record type with helper  
        Lead leadObj =UnitTestHelper.prepareB2CLead(false,'test');
        System.debug('leadObj'+leadObj);
        leadObj.POD_Lead_Id__c = 'test';
        insert leadObj;        
        
        //Create Test Case with record type with helper UW-Renewal      
        Case testCase = UnitTestHelper.prepareCaseWithRecordType('UW-Renewal');
        //Create test Account with the helper method
        Account acc = UnitTestHelper.prepareAccount(true,'test');
        
        //Create test InsurancePolicy with the helper method
        InsurancePolicy ins = UnitTestHelper.createInsurancePolicy(acc.id);
        ins.POD_Policy_Uuid__c = 'test';
        ins.Case__c = testCase.Id;
        update ins;  
        
        //Create Test Case with record type with helper for UW-Prebind
        Case testCase1 = UnitTestHelper.prepareCaseWithRecordType('UW-Prebind');  
        testCase1.Lead_and_Referral__c = leadObj.Id;
        update testCase1;
        
    }
    
    static testmethod void test() { 
        List<Case> testcase =[SELECT Id FROM Case LIMIT 2];
        String result = ReToolApex.PodLeadIds(testCase[0].id);
        System.assertNotEquals(null, result);
        String result1 = ReToolApex.PodLeadIds(testCase[1].id);
        System.assertNotEquals(null, result1);
        
    }
}