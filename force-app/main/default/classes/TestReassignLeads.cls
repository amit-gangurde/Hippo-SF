@isTest
private class TestReassignLeads {
    
    @isTest 
    static void testgetNewLeadsIncorrectRecordType() 
    {
        Id RecordTypeIdLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2B Leads').getRecordTypeId();
        Lead l = new Lead(LastName= 'T200Test', Status = 'New', RecordTypeId = RecordTypeIdLead);
        insert l;
        
        Test.startTest();
        List<Lead> leads = ReassignLeads.getNewLeads(System.now());
        Test.stopTest();
        
        //Only B2C Lead record type are processed for this logic
        System.assertEquals(0, leads.size());
    }
    
    @isTest 
    static void testgetNewLeadsCorrectRecordTypePastCutOffTime() 
    {
        Datetime pasthour = Datetime.now().addHours(-1);
        Id RecordTypeIdLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales').getRecordTypeId();
        Lead l = new Lead(LastName= 'T200Test', Status = 'New', RecordTypeId = RecordTypeIdLead, Work_Accepted_Time__c = pasthour);
        insert l;

        Test.startTest();  
        List<Lead> leads = ReassignLeads.getNewLeads(pasthour);
        Test.stopTest();
        
        //One lead is past cut off time
		System.assertEquals(1, leads.size());
    }

     @isTest 
    static void testgetNewLeadsCorrectRecordTypeWithinCutOffTime() 
    {
        Datetime pasthour = Datetime.now().addHours(-1);
        Id RecordTypeIdLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales').getRecordTypeId();
        Lead l = new Lead(LastName= 'T200Test', Status = 'New', RecordTypeId = RecordTypeIdLead, Work_Accepted_Time__c = Datetime.now());
        insert l;

        Test.startTest();  
        List<Lead> leads = ReassignLeads.getNewLeads(pasthour);
        Test.stopTest();
        
		System.assertEquals(0, leads.size());
    }
        
    @isTest 
    static void testNoReassignToQueue() 
    {
        Datetime past30min = Datetime.now().addMinutes(-30);
        Id RecordTypeIdLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales').getRecordTypeId();
        Lead l = new Lead(LastName= 'T200Test', Status = 'New', RecordTypeId = RecordTypeIdLead, Work_Accepted_Time__c = past30min,OwnerId = UserInfo.getUserId());
        insert l;

        Test.startTest();  
        ReassignLeads.reassignToQueue();
        Test.stopTest();
        
        //As the leads are within cutoff time, the owner is still the agent
        System.assertEquals(l.OwnerId, UserInfo.getUserId());
    }
    
    @isTest 
    static void testReassignToQueue() 
    {
        Lead_Reassignment__mdt leadType = [SELECT LeadAcceptedTimeCutOff__c FROM Lead_Reassignment__mdt WHERE DeveloperName = 'B2C_Lead'];
        Integer acceptCO = leadType.LeadAcceptedTimeCutOff__c.intValue();
        
        Datetime pasthour = Datetime.now().addHours(-acceptCO);
        Id RecordTypeIdLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales').getRecordTypeId();
        Lead l = new Lead(LastName= 'T200Test', Status = 'New', RecordTypeId = RecordTypeIdLead, Work_Accepted_Time__c = pasthour,OwnerId = UserInfo.getUserId());
        insert l;

        Test.startTest();  
        ReassignLeads.reassignToQueue();
        Test.stopTest();
        
        //Lead is past cut off time so reassigned to the queue
        Lead ol = [SELECT LastName, OwnerId FROM Lead WHERE LastName = 'T200Test'];
        Group leadQueue = [SELECT Id, Name FROM Group Where DeveloperName = 'B2C_Sales' and Type = 'Queue'];
        System.assertEquals(leadQueue.Id, ol.OwnerId);
    }
}