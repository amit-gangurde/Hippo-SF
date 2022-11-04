/************************************************************************************************************************************
Author : Baban Shinde
Description : Test class to update the task owner if case owner get changed..
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
  1         			       19/09/2022    Baban Shinde   prepareCaseWithRecordType
**************************************************************************************************************************************/
@isTest
public class TestNewCaseTrigger {
    
    //Create the records for batch test.
    @testSetup
    static void setup() {
        //Create cases lead.
        list<Case> lstCase = new list<Case>();
        Case objCase = UnitTestHelper.prepareCaseWithRecordType('UW-Prebind');
        
        Case objCase1 = UnitTestHelper.prepareCaseWithRecordType('B2B Support');
        objCase1.Source__c = 'NPS';
        lstCase.add(objCase1);
        Case objCaseNew = UnitTestHelper.prepareCaseWithRecordType('B2B Support');
        objCaseNew.Source__c = 'Smart Home';
        lstCase.add(objCaseNew);
        Case newObjCase = UnitTestHelper.prepareCaseWithRecordType('B2B Support');
        newObjCase.Source__c = 'Renewal Outbound';
        lstCase.add(newObjCase);
        Case newObjCaseNew = UnitTestHelper.prepareCaseWithRecordType('B2B Support');
        newObjCaseNew.Source__c = 'Non-Payment';
        lstCase.add(newObjCaseNew);
        
        Update lstCase;
        
        String UnderwritingRecId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Underwriting').getRecordTypeId();
        List<Task> lstTask = new List<Task>();
        for(Integer index = 0; index < 4 ; index++) {
            Task task = new Task();
            task.Priority = 'Normal';
            task.Status = 'Open';
            task.Subject = 'Loss History';
            task.WhatId = objCase.Id;
            task.RecordTypeId = UnderwritingRecId;
            lstTask.add(task);
        }
        insert lstTask;
    }
    
    //Positive scenario.
    static testMethod void TestNewCaseTriggerTest() {
		List<Case> LstCase = [SELECT Id, OwnerId FROM Case];
        User user = UnitTestHelper.createuser();
        Set<Id> caseIds = new Set<Id>();
        for(Case objCase : LstCase) {
            objCase.OwnerId = user.Id;
            caseIds.add(objCase.Id);
        }
        Test.startTest();
        update LstCase;
        Test.stopTest();
        
        List<Task> lstTask = [SELECT Id, OwnerId FROM Task WHERE WhatId IN : caseIds];
        for(Task taskObj : lstTask) {
            system.assertEquals(taskObj.OwnerId , user.Id);
        }
    }
}