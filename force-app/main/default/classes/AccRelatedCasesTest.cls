/************************************************************************************************************************************
Author : Amit Gangurde
Description : This Test class used in the LWC component for the Case Realted Application .
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         			           19/09/2022     Amit Gangurde     Initial Development
**************************************************************************************************************************************/
@isTest
public class AccRelatedCasesTest {
    @testSetup 
    static void setup() {  
        
        //Trigger Setting for the LangCaseTrigger
        TriggerSetting__c setting = New TriggerSetting__c();
        setting.Is_Active__c = true;
        setting.Name = 'LangCaseTrigger';
        insert setting;  
        
        //Create test Account with the helper method
        Account acc = UnitTestHelper.prepareAccount(true,'test'); 
        System.debug('accacc ='+acc);
        
        List<Case> caseList = New List<Case>();
        //Create Test Case with record type with helper UW-Renewal      
        Case testCase = UnitTestHelper.prepareCaseWithRecordType('UW-Renewal');
        testCase.AccountId = acc.Id;
        caseList.add(testCase);
        
        //Create Test Case with record type with helper UW-Prebind      
        Case testCase1 = UnitTestHelper.prepareCaseWithRecordType('UW-Renewal');
        testCase1.AccountId = acc.Id;
        caseList.add(testCase1);
        
        //Create Test Case with record type with helper UW-New Business      
        Case testCase2 = UnitTestHelper.prepareCaseWithRecordType('UW-Renewal');
        testCase2.AccountId = acc.Id;
        caseList.add(testCase2);
        update caseList;
        
    }
    static testmethod void test() { 
        Case obj = [SELECT id FROM Case LIMIT 1];
        List<Case> caseList = AccRelatedCases.fetchCases(obj.Id);
        System.debug('caseListcaseList :'+caseList);
        System.assertNotEquals(null, caseList);
        
        
    }
    
}