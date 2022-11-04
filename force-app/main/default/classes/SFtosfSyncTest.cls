@isTest
public class SFtosfSyncTest {
    @TestSetup static void initiateTestData(){
        Hippo_Last_Sync__c sync = new Hippo_Last_Sync__c();
        sync.Producer_Last_Updated_DateTime__c = DateTime.now();
        sync.LicenseLast_Update_DateTime__c = DateTime.now();
        sync.Account_Trigger_Active__c = true;
        sync.Contact_Trigger_Active__c = true;
        
        insert sync;
        
        Account accOBJ = new Account();
        accOBJ.Name = 'Test';
        accOBJ.Sync_to_AgentSync__c = 'Yes';
        insert accOBJ;
        
        AccountSync.isRecursive = false;
        
        Account accOBJUpd = new Account();
        accOBJUpd.Id = accOBJ.Id;
        update accOBJUpd;
        
        AccountSync.isRecursive = false;
        
        Contact con = new Contact();
        con.LastName = 'Test';
        con.AccountId = accOBJ.ID;
        con.Sync_to_AgentSync__c = 'Yes';
        insert con;
        AccountSync.isRecursive  = false;
        Contact conUpd = new Contact();
        conUpd.Id = con.Id;
        update conUpd;
        
        Integration_Log__c intLog = new Integration_Log__c();
        intLog.Name = 'test';
        intLog.Object_Name__c = 'Account';
        insert intLog;
        
        Hippo_Last_Sync__c syncUpd = new Hippo_Last_Sync__c();
        syncUpd.Id = sync.Id;
        syncUpd.Integration_Log_ID__c = [SELECT ID FROM Integration_Log__c LIMIT 1].ID;
        update syncUpd;
    }
    @isTest static void ProducerSyncSchedulerBatchTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new ProducerSyncSchedulerBatch(null,null,false,null));
        Test.stopTest();
    }
    @isTest static void ProducerSyncSchedulerBatchResyncTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new ProducerSyncSchedulerBatch(DateTime.now(),DateTime.now().addMinutes(5),True,null));
        Test.stopTest();
    }
    @isTest static void LicenseSchedulerBatchTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new LicenseSyncSchedulerBatch(null,null,false,null));
        Test.stopTest();
    }
    @isTest static void LicenseBatchResyncTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new LicenseSyncSchedulerBatch(DateTime.now(),DateTime.now().addMinutes(5),True,null));
        Test.stopTest();
    }
    @isTest static void CarrierAppointmentSyncSchedulerBatchTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new CarrierAppointmentSyncSchedulerBatch(null,null,false,null));
        Test.stopTest();
    }
    @isTest static void CarrierAppointmentSyncSchedulerBatchResyncTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new CarrierAppointmentSyncSchedulerBatch(DateTime.now(),DateTime.now().addMinutes(5),True,null));
        Test.stopTest();
    }
    @isTest static void LOASyncSchedulerBatchTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new LineOfAuthoritySync(null,null,false,null));
        Test.stopTest();
    }
    @isTest static void LOASyncSchedulerBatchResyncTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null,'GET'));
        Database.executeBatch(new LineOfAuthoritySync(DateTime.now(),DateTime.now().addMinutes(5),True,null));
        Test.stopTest();
    }
    @isTest static void accountSyncErrorTest(){
        Id accID = [SELECT ID FROM Account LIMIT 1].ID;
        AccountErrorSync.reSyncHandler(accID);
    }
    @isTest static void ContactErrorSyncTest(){ //IntegrationErrorSync
        Id conID = [SELECT ID FROM Contact LIMIT 1].ID;
        ContactErrorSync.reSyncHandler(conID);
    }
    @isTest static void IntegrationErrorSyncTest(){
        Id intID = [SELECT ID FROM Integration_Log__c LIMIT 1].ID;
        IntegrationErrorSync.reSyncHandler(intID);
    }
    @isTest static void IntegrationErrorSyncContactTest(){
        Id intID = [SELECT ID FROM Integration_Log__c LIMIT 1].ID;
        Integration_Log__c updInt = new Integration_Log__c();
        updInt.Id = intID;
        updInt.Object_Name__c = 'Contact';
        update updInt;
        IntegrationErrorSync.reSyncHandler(intID);
    }
    @isTest static void IntegrationErrorSyncProdLicTest(){
        Id intID = [SELECT ID FROM Integration_Log__c LIMIT 1].ID;
        Integration_Log__c updInt = new Integration_Log__c();
        updInt.Id = intID;
        updInt.Object_Name__c = 'Producer_Licensing__c';
        updInt.Batch_Start_Date__c = DateTime.now();
        updInt.Batch_End_Date__c   = DateTime.now();
        update updInt;
        IntegrationErrorSync.reSyncHandler(intID);
    }
    @isTest static void IntegrationErrorSyncLicTest(){
        RecursiveTriggerHandler.isFirstTime = false;
        Id intID = [SELECT ID FROM Integration_Log__c LIMIT 1].ID;
        Integration_Log__c updInt = new Integration_Log__c();
        updInt.Id = intID;
        updInt.Object_Name__c = 'License__c';
        updInt.Batch_Start_Date__c = DateTime.now();
        updInt.Batch_End_Date__c   = DateTime.now();
        update updInt;
        IntegrationErrorSync.reSyncHandler(intID);
    }
    @isTest static void IntegrationLoggerTest(){
        IntegrationLogger.createIntegrationLog('name', 'className', 'functionaName', 'method', 'endPoint', 'request', 'response', 'Success', 'ObjectName', 'RecordID', 'ExternalID', DateTime.now(), DateTime.now());
    }
}