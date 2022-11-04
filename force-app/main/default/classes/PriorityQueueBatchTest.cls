@isTest
public class PriorityQueueBatchTest {
    //Create the records for Batch Test.
    @testSetup
    static void setup() {
        
        TriggerSetting__c setting = new TriggerSetting__c();
        setting.Is_Active__c = true;
        setting.Name = 'LangCaseTrigger';
        insert setting;
        
        Id renewalRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-Renewal').getRecordTypeId();
        Id newBusinessRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('UW-New Business').getRecordTypeId();
        
        //Create Test Record For Renewal
        List<Case> renewalCase_lst = new List<Case>();
                List<Case> newBusinessCase_lst = new List<Case>();
        List<Decimal> probabiliyScoreList = new list<Decimal> { 0.78 , 0.54 , 0.31, 0.07 };
        List<Integer> inspectionScoreList = new list<Integer> { 1875 , 1250 , 625, 620 };               
                

        for(Integer i=0 ; i <4 ; i++){
            Case obj = new Case();
            obj.Last_Action_Date__c = Date.today();
            obj.Probability_Score__c = probabiliyScoreList[i];
            obj.Inspection_Score__c = inspectionScoreList[i];
            obj.RecordTypeId = newBusinessRecTypeId;
            newBusinessCase_lst.add(obj); 
        }     
        
        insert newBusinessCase_lst;
        
        for(Integer i=0 ; i <4 ; i++){
            Case obj = new Case();
            obj.Last_Action_Date__c = Date.today();
            obj.Probability_Score__c = probabiliyScoreList[i];
            obj.Inspection_Score__c = inspectionScoreList[i];
            obj.RecordTypeId = renewalRecTypeId;
            renewalCase_lst.add(obj); 
        }     
        
        insert renewalCase_lst;
        
    }
    static testmethod void priorityQueueBatchTest() {
        
        Test.startTest();
        PriorityQueueBatch ba = new PriorityQueueBatch();
        Id jobid= Database.executeBatch(ba);        
        System.assertNotEquals(null, jobid);
        Test.stopTest();
    }
    
}