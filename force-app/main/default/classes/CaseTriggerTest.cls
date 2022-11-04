@IsTest
private class CaseTriggerTest {

    @IsTest
    static void testSetWorkingStatus() {

        UnitTestHelper.prepareDevEnvCustomSettings();
        
        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Cases PST Queue');
        
        Case cs = UnitTestHelper.prepareB2CSupportCase('unit test with b2c support case');
        cs.OwnerId = Utils.getQueueId(pst_pending_queue_dev_name);
        update cs;
        
        test.startTest();
        
        cs.OwnerId = UserInfo.getUserId();
        update cs;
        
        test.stopTest();
        
        Case cs_updated = [Select Id, Status From Case Where Id =: cs.Id Limit 1];
        System.assertEquals('Working', cs_updated.Status);
    }
    
    @testsetup
    public static void createCaseRecord() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;

        Integration__c integ = new Integration__c();
        integ.Auth_URL__c = 'https://www.authurl.com';
        integ.MultiClaim_Status_Update_URL__c = 'https://test.com';
        integ.Multiclaim_URL__c = 'https://test.com';
        integ.Password__c = 'password';
        integ.Reassign_Claim_URL__c = 'http://test.com';
        integ.Unassign_Claim_URL__c = 'http://test.com';
        integ.Username__c = 'username';
        insert integ;

        Integration__c integ_OrgDefaults = Integration__c.getOrgDefaults();
        integ_OrgDefaults.Auth_URL__c = 'https://www.authurl.com';
        integ_OrgDefaults.MultiClaim_Status_Update_URL__c = 'https://test.com';
        integ_OrgDefaults.Multiclaim_URL__c = 'https://test.com';
        integ_OrgDefaults.Password__c = 'password';
        integ_OrgDefaults.Reassign_Claim_URL__c = 'http://test.com';
        integ_OrgDefaults.Unassign_Claim_URL__c = 'http://test.com';
        integ_OrgDefaults.Username__c = 'username';
        upsert integ_OrgDefaults Integration__c.Id;
        
        Account acc = new Account();
        acc.LastName = 'test';
        acc.RecordTypeId = '0126g000001JEVB';
        acc.PersonEmail = 'acc@Gmail.com';
        acc.Resource_Username__c = 'test';
        acc.Resource_Number__c = 'w453';
        insert acc;
        
        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = 'test';
        insert ins;
        
        string ClaimRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Claim').getRecordTypeId();
        Case cs = new Case();
        cs.AccountId = acc.id;
        //cs.Claim_Vendor__c = acc.id;
        cs.POD_Claim_ID__c = '12434';
        cs.POD_Diary_ID__c = '3344';
        //cs.Claims_Adjuster__c = userinfo.getUserId();
        cs.Date_of_Loss__c = system.today();
        cs.CATCode__c = '1234';
        cs.Insurance_Policy__c = ins.id;
        cs.Have_a_Contractor__c = true;        
        cs.RecordTypeId = ClaimRecId;
        cs.status = 'New';
        cs.Claims_Adjuster__c = userinfo.getUserId();
        cs.Sent_to_Claimatic__c = true;
        cs.Claims_Agreement__c = 'Agree';
        Database.SaveResult sr1 = Database.insert(cs, dml);
        System.assertEquals(true, sr1.success);
        System.debug('Created Case with POD_Claim_ID__c: ' + cs.POD_Claim_ID__c + ', ' + cs);
        //insert cs;
        
        Case cs1 = new Case();
        cs1.Ignore_Dupe__c = true;
        cs1.AccountId = acc.id;
        cs.Claim_Vendor__c = acc.id;
        cs1.POD_Claim_ID__c = '124341';
        cs1.POD_Diary_ID__c = '33441';
        //cs.Claims_Adjuster__c = userinfo.getUserId();
        cs1.Date_of_Loss__c = system.today();
        cs1.CATCode__c = '1234';
        cs1.Insurance_Policy__c = ins.id;
        cs1.Have_a_Contractor__c = true;        
        cs1.RecordTypeId = ClaimRecId;
        cs1.status = 'New';
        cs1.Claims_Adjuster__c = userinfo.getUserId();
        cs1.Sent_to_Claimatic__c = true;
        cs1.Claims_Agreement__c = 'Agree';
        Database.SaveResult sr2 = Database.insert(cs1, dml);
        System.assertEquals(true, sr2.success);
        //insert cs1;
        
        ClaimaticCaseTriggerActivation__c setting = new ClaimaticCaseTriggerActivation__c();
        setting.Activate__c = true;
        insert setting;
    }
    
    public static testmethod void testClaimaticIntegration() {

        UnitTestHelper.prepareDevEnvCustomSettings();
         Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
                User u = new User(Alias = 'standt13', Email='standarduser12hippoorgmain.123@testorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        TimeZoneSidKey='America/Los_Angeles', Username='standarduser12hippoorgmain@testorg.com');
        
                insert u;

        ClaimaticCaseTriggerActivation__c setting = ClaimaticCaseTriggerActivation__c.getInstance();
        Case cs = new case();
        cs = [select id from case where POD_Claim_ID__c = '12434' LIMIT 1];
        
        Account acc = new Account();
        acc = [select id from account LIMIT 1];
        
        Test.startTest();

        cs.Claims_Adjuster__c = null;
        cs.Claim_Vendor__c = acc.id;
        cs.AccountId = acc.id;
        cs.Status = 'Closed';
        cs.Sent_to_Claimatic__c = true;
        update cs;

        
        Test.stopTest();
    }
    
    public static testmethod void testClaimaticIntegrationVendor() {

        UnitTestHelper.prepareDevEnvCustomSettings();
        
         Account acc1 = new Account();
        acc1.LastName = 'test acc1';
        acc1.RecordTypeId = '0126g000001JEVB';
        acc1.PersonEmail = 'acc.acc1@Gmail.com';
        acc1.Resource_Username__c = 'test acc1';
        acc1.Resource_Number__c = 'w453';
        insert acc1;
        

         Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
                User u1 = new User(Alias = 'standt13', Email='standarduser12@testorg.com',
                        EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', ProfileId = p.Id,
                        TimeZoneSidKey='America/Los_Angeles', Username='standarduser23.hippomain123@testorg.com');
        
                insert u1;
        
        ClaimaticCaseTriggerActivation__c setting = ClaimaticCaseTriggerActivation__c.getInstance();
        Case cs = new case();
        cs = [select id from case where POD_Claim_ID__c = '124341' LIMIT 1];
        
        Account acc = new Account();
        acc = [select id from account LIMIT 1];
        
        User u = new User();
        u = [select id from User where id !=: Userinfo.getUserId() LIMIT 1];
        
        Test.startTest();

        cs.Claims_Adjuster__c = null;
        cs.Claim_Vendor__c = null;
        cs.Status = 'Closed';
        cs.Sent_to_Claimatic__c = true;
        update cs;       
       RecursiveTriggerHandler.isFirstTime = true; 
         Case cs1 = new case();
        cs1.id = cs.id;
        cs1.Claim_Vendor__c =  acc.id;
        cs1.Claims_Adjuster__c = Userinfo.getUserId();
        update cs1;  
        RecursiveTriggerHandler.isFirstTime = true;
          Case cs2 = new case(); 
        cs2.id = cs1.id;
        cs2.CLaims_Adjuster__c = u1.id;
           cs2.Claim_Vendor__c =  acc1.id;
        update cs2;

        Test.stopTest();
    }

    public static testmethod void testClaimaticIntegrationAdjuster() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        ClaimaticCaseTriggerActivation__c setting = ClaimaticCaseTriggerActivation__c.getInstance();
        Case cs = new case();
        cs = [select id from case where POD_Claim_ID__c = '124341' LIMIT 1];
        
        Account acc = new Account();
        acc = [select id from account LIMIT 1];
        
        Account acc1 = new Account();
        acc1.LastName = 'test';
        acc1.RecordTypeId = '0126g000001JEVB';
        acc1.PersonEmail = 'acc@Gmail.com';
        acc1.Resource_Username__c = 'test';
        acc1.Resource_Number__c = 'w453';
        insert acc1;
        
        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = 'test';
        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(ins, dml);
        //insert ins;
        
        User u = new User();
        u = [select id from User where id !=: Userinfo.getUserId() LIMIT 1];
        
        Test.startTest();

        cs.Claims_Adjuster__c = null;
        cs.Claim_Vendor__c = acc1.id;
        //cs.AccountId =  acc1.id; // Fails on VR: Can not change Account or Insurance Policy fields
        //cs.Insurance_Policy__c = ins.Id; // Fails on VR: Can not change Account or Insurance Policy fields
        cs.Status = 'Closed';
        cs.Sent_to_Claimatic__c = true;
        update cs;

        Test.stopTest();
    }
}