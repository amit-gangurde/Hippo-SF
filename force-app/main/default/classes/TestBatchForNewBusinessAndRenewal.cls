/************************************************************************************************************************************
Author : Baban Shinde
Description : Test class for batch which will create case records related to Policy.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
  1         			       22/09/2022    Baban Shinde
**************************************************************************************************************************************/
@isTest
public class TestBatchForNewBusinessAndRenewal {
    
    //Create the records for Batch Test.
    @testSetup
    static void setup() {
        TriggerSetting__c setting = new TriggerSetting__c();
        setting.Is_Active__c = true;
        setting.Name = 'LangCaseTrigger';
        insert setting;

        //Create Account and related policy.
        Account account = UnitTestHelper.preparePersonAccount();
        List<InsurancePolicy> lstInsurancePolicy = new List<InsurancePolicy>();
        
        InsurancePolicy insurancePolicy = UnitTestHelper.createInsurancePolicyWithAccount(false, account.Id, 'policy one');
        insurancePolicy.Is_New_Business_Case_Required__c = true;        
        lstInsurancePolicy.add(insurancePolicy);
        
        Account newAccount = UnitTestHelper.prepareAccount();
        InsurancePolicy newInsurancePolicy = UnitTestHelper.createInsurancePolicyWithAccount(false, newAccount.Id, 'policy two');
        newInsurancePolicy.Is_Renewal_Case_Required__c = true;
        lstInsurancePolicy.add(newInsurancePolicy);
       
        insert lstInsurancePolicy;
        
        List<Inspection__c> lstInspection = new List<Inspection__c>();
        
        Inspection__c inspection = UnitTestHelper.createInspection(false, null);
        inspection.Insurance_Policy__c = lstInsurancePolicy[1].Id;
        lstInspection.add(inspection);

        Inspection__c newInspection = UnitTestHelper.createInspection(false, null);
        newInspection.Insurance_Policy__c = lstInsurancePolicy[0].Id;
        lstInspection.add(newInspection);
        
        insert lstInspection;
    }
    
    //Positive scenario.
    static testMethod void BatchForNewBusinessAndRenewalTest() {
		List<insurancePolicy> insurancePolicy = [SELECT Id FROM InsurancePolicy WHERE Is_New_Business_Case_Required__c = true OR Is_Renewal_Case_Required__c = true];
        system.assertEquals(2, insurancePolicy.size());
        
        Test.startTest();
        BatchForNewBusinessAndRenewal obj = new BatchForNewBusinessAndRenewal();
        Database.executeBatch(obj);
        Test.stopTest();
        
        List<insurancePolicy> newInsurancePolicy = [SELECT Id FROM InsurancePolicy WHERE Is_New_Business_Case_Required__c = true OR Is_Renewal_Case_Required__c = true];
        system.assertEquals(0, newInsurancePolicy.size());
    }
    
    //Negative scenario.
    static testMethod void BatchForNewBusinessAndRenewalTestException() {
        
        String newBusinessRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-New Business').getRecordTypeId();
        List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        Case objCase = new Case();
        objCase.RecordTypeId = newBusinessRecId;
        objCase.Name_of_Primary_Insured__c = lstAccount[0].Id;
        insert objCase;
        
        List<insurancePolicy> insurancePolicy = [SELECT Id FROM InsurancePolicy WHERE Is_New_Business_Case_Required__c = true OR Is_Renewal_Case_Required__c = true];
        system.assertEquals(2, insurancePolicy.size());
        
        Test.startTest();
        BatchForNewBusinessAndRenewal obj = new BatchForNewBusinessAndRenewal();
        Database.executeBatch(obj);
        Test.stopTest();
        
        List<insurancePolicy> newInsurancePolicy = [SELECT Id FROM InsurancePolicy WHERE Is_New_Business_Case_Required__c = true OR Is_Renewal_Case_Required__c = true];
        system.assertEquals(0, newInsurancePolicy.size());
    }
}