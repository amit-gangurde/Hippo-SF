@isTest
public class AgentSyncTest {
    @TestSetup static void initiateTestData(){
      Id accountBusinessRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
      Id contactBusinessRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business').getRecordTypeId();
        
         Hippo_Last_Sync__c lastSync = new Hippo_Last_Sync__c();
        lastSync.Account_Trigger_Active__c = true;
        lastSync.Contact_Trigger_Active__c= true;
        insert lastSync;
        
          Hippo_Settings__c hsProperty = new Hippo_Settings__c();
        hsProperty.Name = 'test';
        hsProperty.Value__c= 'test';
        insert hsProperty;
        
        Account acc = new Account();
        acc.recordTypeId = accountBusinessRecTypeId;
        acc.Name= 'test';
        acc.Sync_to_AgentSync__c = 'Yes';
        acc.NPN__c = '123N';
        acc.Home_State__c = 'AK';
        acc.FEIN_number__c = 'TES123';
        acc.Support_Service_Email__c = 'test@test.com';
        insert acc;
        
        AccountSync.isRecursive = false;
        Contact con = new Contact();
        con.recordTypeId = contactBusinessRecTypeId;
        con.LastName = 'test';
        con.Sync_to_AgentSync__c = 'Yes';
        con.National_Producer_Number__c = '123NO';
        con.NPN__c = '123N';
        con.Phone = '1234432';
        con.Email = 'test@test.com1';
        con.AccountId = acc.Id;
        con.PodRoleAdmin__c = true;
        insert con;
        
        AccountSync.isRecursive = false;
        
          Integration_Log__c log = IntegrationLogger.createLogs('name','className','functionaName','method','endPoint','request','response','Success','ObjectName','RecordID','ExternalID',DateTime.now(),DateTime.now());
        insert log;
        
        Integration_Error_Log__c  eLog = IntegrationErrorLogger.createErrorLog( 'ClassName', 'MethodName',null, 'Name',String.valueOf(log.Id), 'DML', 'DMLerror', 'Error', 'errorDetails');
   insert eLog;
            }
    @isTest static void producerSync(){
        String body ='{"totalSize":2,"done":true,"records":[{"attributes":{"type":"agentsync__Producer_Licensing__c","url":"/services/data/v49.0/sobjects/agentsync__Producer_Licensing__c/a0P550000028ZxKEAU"},"Id":"a0P550000028ZxKEAU","Name":"shahprai1"},{"attributes":{"type":"agentsync__Producer_Licensing__c","url":"/services/data/v49.0/sobjects/agentsync__Producer_Licensing__c/a0P550000028if8EAA"},"Id":"a0P550000028if8EAA","Name":"shahprai2"}]}';
        Test.setMock(HttpCalloutMock.class, new AgentSyncMockTest(body)); 
        String jobID = System.schedule('ProducerSyncSchedulerBatchTest', '0 0 22 * * ? *' , new ProducerSyncSchedulerBatch(null,null,false,null));
        Database.executeBatch(new ProducerSyncSchedulerBatch(null,null,false,null));
        
        List<Integration_Error_Log__c> errorLogs = [SELECT ID,Integration_Log__c FROM Integration_Error_Log__c];
        IntegrationErrorLogger.beforeInsert(errorLogs);
    }
    @isTest static void licenseSync(){
        String body ='{"totalSize":7,"done":true,"records":[{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005zhMSEAY"},"Name":"9820725900","agentsync__Account__c":"0015500001Jk6owAAB","agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__STATE__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__Unique_ID__c":null,"Id":"a0H55000005zhMSEAY"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005zhMwEAI"},"Name":"9820725901","agentsync__Account__c":null,"agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":"0035500001CNCZRAA5","agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__STATE__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__Unique_ID__c":null,"Id":"a0H55000005zhMwEAI"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005zhNBEAY"},"Name":"9820725902","agentsync__Account__c":null,"agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":"0035500001CNCZRAA5","agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__STATE__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__Unique_ID__c":null,"Id":"a0H55000005zhNBEAY"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005zpP9EAI"},"Name":"CAregression1","agentsync__Account__c":null,"agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":"0035500001CQS8IAAX","agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__STATE__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__Unique_ID__c":null,"Id":"a0H55000005zpP9EAI"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005zpPEEAY"},"Name":"AZregression2","agentsync__Account__c":null,"agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":"0035500001CQS8IAAX","agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__STATE__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__Unique_ID__c":null,"Id":"a0H55000005zpPEEAY"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005zpPTEAY"},"Name":"CAregression3","agentsync__Account__c":"0015500001JrmZbAAJ","agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__STATE__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__Unique_ID__c":null,"Id":"a0H55000005zpPTEAY"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005zpPYEAY"},"Name":"TXRegression4","agentsync__Account__c":"0015500001JrmZbAAJ","agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__STATE__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__Unique_ID__c":null,"Id":"a0H55000005zpPYEAY"}]}';
        Test.setMock(HttpCalloutMock.class, new AgentSyncMockTest(body)); 
        String jobID = System.schedule('licenseSyncTest', '0 0 22 * * ? *' , new LicenseSyncSchedulerBatch(null,null,false,null));
        Database.executeBatch(new LicenseSyncSchedulerBatch(null,null,false,null));
    }
    @isTest static void carrierSync(){
         String body = '{"totalSize":979,"done":true,"records":[{"attributes":{"type":"agentsync__Carrier_Appointment__c","url":"/services/data/v49.0/sobjects/agentsync__Carrier_Appointment__c/a045500000B5X1BAAV"},"Name":"CA-2655971","agentsync__Account__c":"0015500001Jk6owAAB","agentsync__Agency_Name__c":null,"agentsync__FEIN_State_Co_ID__c":null,"agentsync__Branch_ID__c":null,"agentsync__COCODE__c":null,"agentsync__COMPANY_NAME__c":"carrier apt test1","agentsync__Contact__c":null,"agentsync__Appointment_Effective_Date__c":"2021-05-01","agentsync__FEIN__c":null,"agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__COUNTY_CODE__c":null,"agentsync__LINE_OF_AUTHORITY__c":null,"agentsync__LOA_CODE__c":null,"agentsync__NPN__c":null,"agentsync__APPONT_RENEWAL_DATE__c":null,"agentsync__Source__c":"PDB","agentsync__State_Code__c":"CA","agentsync__Status__c":"Active","agentsync__STATUS_REASON_DATE__c":null,"agentsync__Termination_Effective_Date__c":"2028-05-09","agentsync__TERMINATION_REASON__c":null,"agentsync__Unique_ID__c":null,"Id":"a045500000B5X1BAAV"},{"attributes":{"type":"agentsync__Carrier_Appointment__c","url":"/services/data/v49.0/sobjects/agentsync__Carrier_Appointment__c/a045500000B5X1aAAF"},"Name":"CA-2655972","agentsync__Account__c":null,"agentsync__Agency_Name__c":null,"agentsync__FEIN_State_Co_ID__c":null,"agentsync__Branch_ID__c":null,"agentsync__COCODE__c":null,"agentsync__COMPANY_NAME__c":"aeiou test company","agentsync__Contact__c":"0035500001CNCZRAA5","agentsync__Appointment_Effective_Date__c":"2021-04-05","agentsync__FEIN__c":"982165684","agentsync__Producer_Licensing__c":"a0P550000028ZxKEAU","agentsync__COUNTY_CODE__c":null,"agentsync__LINE_OF_AUTHORITY__c":null,"agentsync__LOA_CODE__c":null,"agentsync__NPN__c":null,"agentsync__APPONT_RENEWAL_DATE__c":null,"agentsync__Source__c":"PDB","agentsync__State_Code__c":"CA","agentsync__Status__c":"Active","agentsync__STATUS_REASON_DATE__c":null,"agentsync__Termination_Effective_Date__c":"2026-05-05","agentsync__TERMINATION_REASON__c":null,"agentsync__Unique_ID__c":null,"Id":"a045500000B5X1aAAF"}]}';
        Test.setMock(HttpCalloutMock.class, new AgentSyncMockTest(body)); 
        String jobID = System.schedule('CarrierAppointmentSyncSchedulerBatchTest', '0 0 22 * * ? *' , new CarrierAppointmentSyncSchedulerBatch(null,null,false,null));
        Database.executeBatch(new CarrierAppointmentSyncSchedulerBatch(null,null,false,null));
    }
    @isTest static void LOASync(){
         String body = '{"totalSize":180,"done":true,"records":[{"attributes":{"type":"agentsync__Line_of_Authority__c","url":"/services/data/v49.0/sobjects/agentsync__Line_of_Authority__c/a0I55000003GswoEAC"},"agentsync__AUTHORITY_ISSUE_DATE__c":"2021-01-20","agentsync__Categories__c":"health;life","agentsync__CE_COMPLIANCE__c":"TEST","agentsync__CE_CREDITS_NEEDED__c":12.0,"agentsync__CE_RENEWAL_DATE__c":"2021-01-20","agentsync__License__c":"a0H55000005fo54EAA","agentsync__License_Number__c":null,"agentsync__LOA__c":"ConvenceLOA","agentsync__LOA_CODE__c":"1234","agentsync__NPN__c":null,"agentsync__STATUS_REASON__c":"ST123","agentsync__STATUS_REASON_DATE__c":"2021-01-20","agentsync__Unique_ID__c":null,"Name":"LOA-338064","Id":"a0I55000003GswoEAC"},{"attributes":{"type":"agentsync__Line_of_Authority__c","url":"/services/data/v49.0/sobjects/agentsync__Line_of_Authority__c/a0I55000003GaxMEAS"},"agentsync__AUTHORITY_ISSUE_DATE__c":"2021-01-18","agentsync__Categories__c":"health","agentsync__CE_COMPLIANCE__c":"Compliance","agentsync__CE_CREDITS_NEEDED__c":1234.0,"agentsync__CE_RENEWAL_DATE__c":"2021-01-18","agentsync__License__c":"a0H55000005fe8REAQ","agentsync__License_Number__c":null,"agentsync__LOA__c":"LOA test123","agentsync__LOA_CODE__c":"LA123456","agentsync__NPN__c":null,"agentsync__STATUS_REASON__c":"abc","agentsync__STATUS_REASON_DATE__c":"2021-01-18","agentsync__Unique_ID__c":null,"Name":"LOA-338063","Id":"a0I55000003GaxMEAS"},{"attributes":{"type":"agentsync__Line_of_Authority__c","url":"/services/data/v49.0/sobjects/agentsync__Line_of_Authority__c/a0I55000003GY8iEAG"},"agentsync__AUTHORITY_ISSUE_DATE__c":"2021-01-18","agentsync__Categories__c":"health","agentsync__CE_COMPLIANCE__c":"Compliance","agentsync__CE_CREDITS_NEEDED__c":1234.0,"agentsync__CE_RENEWAL_DATE__c":"2021-01-18","agentsync__License__c":"a0H55000005fVRrEAM","agentsync__License_Number__c":null,"agentsync__LOA__c":"lineOfAuth","agentsync__LOA_CODE__c":"test1234","agentsync__NPN__c":null,"agentsync__STATUS_REASON__c":"LoA","agentsync__STATUS_REASON_DATE__c":"2021-01-18","agentsync__Unique_ID__c":null,"Name":"LOA-338062","Id":"a0I55000003GY8iEAG"}]}}';
        Test.setMock(HttpCalloutMock.class, new AgentSyncMockTest(body)); 
        String jobID = System.schedule('LineOfAuthoritySyncTest', '0 0 22 * * ? *' , new LineOfAuthoritySync(null,null,false,null));
        Database.executeBatch(new LineOfAuthoritySync(null,null,false,null));
    }
    @isTest static void ErrorSync(){
         AccountSync.isRecursive = false;
        String jobID = System.schedule('IntegrationLogBatchTest', '0 0 22 * * ? *' , new IntegrationLogBatch());
        Database.executeBatch(new IntegrationLogBatch()); 
    }
    @isTest static void logErrorSync(){
        String jobID = System.schedule('IntegrationErrorLogBatchTest', '0 0 22 * * ? *' , new IntegrationErrorLogBatch());
        Database.executeBatch(new IntegrationErrorLogBatch()); 
    }
}