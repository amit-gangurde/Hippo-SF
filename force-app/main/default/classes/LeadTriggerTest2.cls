@IsTest
public class LeadTriggerTest2 {

    @testsetup
    public static void testSetup() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));
    }

    public static Lead prepareLeadByRecordType(Boolean create, RecordTypeInfo recordTypeInfo) {

        Lead ld = new Lead();
        //RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('PennyMac Lead', 'Lead');
        ld.RecordTypeId = recordTypeInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        //ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Organization__c = null;

        if ( create ) insert ld;

        return ld;
    }

    @IsTest
    static void testHomePointFinancialLeads_Scenario1() { // SFDC-1281

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'home point financial', true, true);
            ld.FirstName = 'James';
            ld.LastName = 'Jones';
            ld.Email = 'jj@gmail.com';
            ld.Street = '1701 Painter Road';
            ld.City = 'Salem';
            ld.State = 'OH';
            ld.Country = 'United States';
            ld.Phone = '3011237845';
            ld.Lead_Score__c = '4';
            //ld.MobilePhone = '2021237845';
            //ld.POD_Quote_ID__c = '';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, Organization__r.Name, Lead_Score__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals('home point financial', ld_new1.Organization__r.Name);
            System.assertEquals(B2C_Partner_Sales_2, ld_new1.OwnerId);
            System.assertEquals('Partner Referral', ld_new1.Lead_Source__c);
        }
    }

    @IsTest
    static void testHomePointFinancialLeads_Scenario2() { // SFDC-1281

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');
        //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
            ld.Lead_Score__c = '1';
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, Lead_Score__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(Outside_Sales_Queue, ld_new1.OwnerId);

            test.startTest();

            Account acc = LeadTriggerTest.prepareAccount(true, 'home point financial', true, true);
            ld.Organization__c = acc.Id;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            update ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead ld_new2 = [Select Id, OwnerId, Lead_Source__c, Organization__r.Name, Lead_Score__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals('home point financial', ld_new2.Organization__r.Name);
            System.assertEquals(B2C_Partner_Sales_2, ld_new2.OwnerId);
            System.assertEquals('Partner Referral', ld_new2.Lead_Source__c);
        }
    }

    @IsTest
    static void testOutsideSalesLeadsWithManualReassignToAgent() { // SFDC-1317

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Id lead_id_in_context = null;

        System.runAs(infra_bot) {

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
            ld.Declination_Reason__c = 'routable_reason';
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            System.assertNotEquals(null, ld.Id);

            Lead ld_new1 = [Select Id, OwnerId, Organization__c, Lead_Score__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(null, ld_new1.Organization__c);
            System.assertEquals(null, ld_new1.Lead_Score__c);
            System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, ld_new1.OwnerId);

            ld_new1.Lead_Score__c = '1';
            ld_new1.Cat_Risk_Class__c = 'no_action';
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            update ld_new1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            Lead ld_new2 = [Select Id, OwnerId, Organization__c, Lead_Score__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(Outside_Sales_Queue, ld_new2.OwnerId);
            lead_id_in_context = ld_new2.Id;
        }

        test.startTest();

        Lead ld_new3 = [Select Id, OwnerId, Organization__c, Lead_Score__c From Lead Where Id = :lead_id_in_context Limit 1];
        ld_new3.OwnerId = UserInfo.getUserId();
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
        update ld_new3;
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

        test.stopTest();

        Lead ld_new4 = [Select Id, OwnerId, Organization__c, Lead_Score__c From Lead Where Id = :ld_new3.Id Limit 1];
        System.assertEquals(UserInfo.getUserId(), ld_new4.OwnerId);
    }

    @IsTest
    static void testHASInternalReferral() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_Internal_Referrals_Queue = Utils.getQueueId('HAS_Internal_Referrals');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];
        Id initiated_user_id = UserInfo.getUserId();

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.FinServ__ReferredByUser__c = initiated_user_id;

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Lead_Source__c, FinServ__ReferredByUser__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(HAS_Internal_Referrals_Queue, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertEquals('Internal Referral Cold Transfer', ld1_new.Lead_Source__c);

            test.stopTest();

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Lead_Source__c, FinServ__ReferredByUser__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(HAS_Internal_Referrals_Queue, ld1_updated.OwnerId);
            System.assertEquals('Internal Referral Cold Transfer', ld1_updated.Lead_Source__c);
        }
    }

    @IsTest
    static void testHASUWReferral_Scenario1() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id HAS_UW_Referrals_Queue = Utils.getQueueId('HAS_UW_Referrals');
        Id UW_Referrals_1 = Utils.getQueueId('UW_Referrals_1');
        Id UW_Referrals_2 = Utils.getQueueId('UW_Referrals_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'UW Referral Organization', true);
            ld1.State = 'GA';
            ld1.Non_Cat_Risk_Class__c = 'referral';
            ld1.Non_Cat_Risk_Score__c = 1.30;
            //ld1.Workable_by_Hippo__c = true;

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(UW_Referrals_2, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertEquals('UW Referral', ld1_new.Lead_Source__c);

            test.stopTest();

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(UW_Referrals_2, ld1_updated.OwnerId);
            System.assertEquals('UW Referral', ld1_updated.Lead_Source__c);
        }
    }

    @IsTest
    static void testHASUWReferral_Scenario2() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id HAS_UW_Referrals_Queue = Utils.getQueueId('HAS_UW_Referrals');
        Id UW_Referrals_1 = Utils.getQueueId('UW_Referrals_1');
        Id UW_Referrals_2 = Utils.getQueueId('UW_Referrals_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'GA');
            ld1.Non_Cat_Risk_Class__c = 'referral';
            ld1.Non_Cat_Risk_Score__c = 1.30;

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_new.Organization__c);
            System.assertEquals(UW_Referrals_2, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertEquals('UW Referral', ld1_new.Lead_Source__c);

            test.stopTest();

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_updated.Organization__c);
            System.assertEquals(UW_Referrals_2, ld1_updated.OwnerId);
            System.assertEquals('UW Referral', ld1_updated.Lead_Source__c);
        }
    }

    @IsTest
    static void testDeduplicationsRule3Positive() { // SFDC-1469

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2'); // SFDC-1752
        //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752
        Id  JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld1 = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        System.runAs(infra_bot) {

            ld1.Status = 'New';
            ld1.Line_of_Business__c = 'HO3';
            //ld.OwnerId = Non_workable_leads_Q;
            ld1.POD_Quote_ID__c = '';
            ld1.Email = 'kkgallardo@outlook.com';
            ld1.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld1.Cat_Risk_Class__c = 'no_action';
            //ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            //ld1.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld1;
        }

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(PMIS_Hippo_Leads_2, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

        test.startTest();

        Lead ld2 = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        System.runAs(infra_bot) {

            ld2.Status = 'New';
            ld2.Line_of_Business__c = 'HO3';
            //ld.OwnerId = Non_workable_leads_Q;
            ld2.POD_Quote_ID__c = '123456';
            ld2.POD_Lead_Id__c = '654321';
            ld2.Email = 'kkgallardo@outlook.com';
            ld2.Phone = '4026404310';
            ld2.Lead_Score__c = '6';
            ld2.Cat_Risk_Class__c = 'no_action';
            ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld2.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld2;
        }

        test.stopTest();

        List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c, Lead_Score__c,
                                              Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
                                       From Lead Where Id =: ld2.Id];
        System.assertEquals(1, lst_CreatedLeads.size());
        ld2 = lst_CreatedLeads[0]; // just for convenience
        system.assertEquals(JV_Non_workable_leads_Q, ld2.OwnerId);

        // check if merge occurred between the leads data (SFDC-1476)
        Lead ld_new1_updated = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName, Lead_Score__c,
                                       Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
                                From Lead Where Id = :ld1.Id Limit 1];
        System.assertEquals(ld2.Lead_Score__c, ld_new1_updated.Lead_Score__c);
        System.assertEquals(ld2.Non_Cat_Risk_Class__c, ld_new1_updated.Non_Cat_Risk_Class__c);
        System.assertEquals(ld2.Non_Cat_Risk_Score__c, ld_new1_updated.Non_Cat_Risk_Score__c);
        System.assertEquals(ld2.POD_Quote_ID__c, ld_new1_updated.POD_Quote_ID__c);
        System.assertEquals(ld2.POD_Lead_Id__c, ld_new1_updated.POD_Lead_Id__c);
        System.assertEquals(ld2.Organization__c, ld_new1_updated.Organization__c);
        System.assertEquals(ld2.POD_Quote_Link__c, ld_new1_updated.POD_Quote_Link__c);
        System.assertEquals(ld2.POD_Lead_Link__c, ld_new1_updated.POD_Lead_Link__c);
        System.assertEquals(PMIS_Hippo_Leads_2, ld_new1_updated.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1_updated.RecordTypeId);
    }

    @IsTest
    static void testDeduplicationsRule3Negative() { // SFDC-1469 (Different line of business)

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2'); // SFDC-1752
        //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752
        Id  JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld1 = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        System.runAs(infra_bot) {

            ld1.Status = 'New';
            ld1.Line_of_Business__c = 'HO3';
            //ld.OwnerId = Non_workable_leads_Q;
            ld1.POD_Quote_ID__c = '';
            ld1.Email = 'kkgallardo@outlook.com';
            ld1.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld1.Cat_Risk_Class__c = 'no_action';
            ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld1.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld1;
        }

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(PMIS_Hippo_Leads_2, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

        test.startTest();

        Lead ld2 = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        System.runAs(infra_bot) {

            ld2.Status = 'New';
            ld2.Line_of_Business__c = 'HO5';
            //ld.OwnerId = Non_workable_leads_Q;
            ld2.POD_Quote_ID__c = '';
            ld2.Email = 'kkgallardo@outlook.com';
            ld2.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld2.Cat_Risk_Class__c = 'no_action';
            ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld2.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld2;
        }

        test.stopTest();

        List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead Where Id =: ld2.Id];
        System.assertEquals(1, lst_CreatedLeads.size());
        system.assertNotEquals(JV_Non_workable_leads_Q, lst_CreatedLeads[0].OwnerId);
        System.assertEquals(PMIS_Hippo_Leads_2, lst_CreatedLeads[0].OwnerId);
    }

    @IsTest
    static void testStickyManualLeadAssignmentByAgent() { // Production bug

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id HAS_UW_Referrals_Queue = Utils.getQueueId('HAS_UW_Referrals');
        Id UW_Referrals_1 = Utils.getQueueId('UW_Referrals_1');
        Id UW_Referrals_2 = Utils.getQueueId('UW_Referrals_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'UW Referral Organization', true);

        System.runAs(infra_bot) {

            ld1.State = 'GA';
            ld1.Cat_Risk_Class__c = 'no_action';
            ld1.Non_Cat_Risk_Class__c = 'referral';
            ld1.Non_Cat_Risk_Score__c = 1.30;
            ld1.Email = 'kammererx4@gmail.com';
            ld1.Phone = '4172936753';
            ld1.FirstName = 'Christine';
            ld1.LastName = 'Kammerer';
            ld1.MiddleName = 'Heidi';
            ld1.Lead_Score__c = '6';

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(UW_Referrals_1, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertEquals('UW Referral', ld1_new.Lead_Source__c);

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(UW_Referrals_1, ld1_updated.OwnerId);
            System.assertEquals('UW Referral', ld1_updated.Lead_Source__c);
        }

        test.startTest();

        Lead ld1_updated = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        ld1_updated.OwnerId = UserInfo.getUserId(); // assign to an agent simulation
        update ld1_updated;
        ld1_updated = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertNotEquals(UW_Referrals_1, ld1_updated.OwnerId);
        System.assertEquals(UserInfo.getUserId(), ld1_updated.OwnerId);
        System.assertEquals('UW Referral', ld1_updated.Lead_Source__c);

        System.runAs(infra_bot) {

            ld1_updated.Lead_Score__c = '6';
            ld1_updated.POD_Quote_ID__c = '8466888';

            update ld1_updated;
        }

        ld1_updated = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertNotEquals(UW_Referrals_1, ld1_updated.OwnerId);
        System.assertEquals(UserInfo.getUserId(), ld1_updated.OwnerId);
        System.assertEquals('UW Referral', ld1_updated.Lead_Source__c);

        test.stopTest();
    }

    /*
    @IsTest
    static void testTransferPersonAccountToHasFlow() { // Production bug - Flow 'Transfer Person Account to HAS' - INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY on Lead creation

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.debug('infra_bot: ' + infra_bot);

        Account pa;

        System.runAs(infra_bot) {

            pa = UnitTestHelper.preparePersonAccount();

            System.assertNotEquals(null, pa.Id);

            InsurancePolicy ins = UnitTestHelper.prepareInsurancePolicyFromPersonAccount(pa);
        }

        Account pa_created = [Select Id, FirstName, MiddleName, LastName, Phone, PersonMailingCity, PersonMailingCountry, PersonMailingState, PersonMailingStreet, PersonMailingPostalCode, PersonEmail, OwnerId From Account WHERE Id =: pa.Id]?.get(0);
        System.assertNotEquals(null, pa_created);
        System.assertEquals(infra_bot.Id, pa_created.OwnerId);

        User support_user = [SELECT Id, Name FROM User WHERE Profile.Name = 'Support' AND IsActive = TRUE LIMIT 1];

        System.debug('support_user: ' + support_user);

        Lead ld1;

        System.runAs(support_user) {

            //System.assertNotEquals(null, pa);

            //Map<String, Object> flowInputs = new Map<String, Object>();
            //flowInputs.put('inputLead', null);
            //flowInputs.put('inputPersonAccount', pa);
            //flowInputs.put('inputCity', pa.PersonMailingCity);
            //flowInputs.put('inputCountry', pa.PersonMailingCountry);
            //flowInputs.put('PolicyTypesChoice', 'Auto');
            //flowInputs.put('inputZip', pa.PersonMailingPostalCode);
            //flowInputs.put('ReferralNotesFromInput', 'some referral notes');
            //flowInputs.put('ReferralNotesFromInput', 'some referral notes');
            //flowInputs.put('inputState', pa.PersonMailingState);
            //flowInputs.put('inputStreet', pa.PersonMailingStreet);

            test.startTest();

            //Flow.Interview.Create_HAS_Lead myFlow = new Flow.Interview.Create_HAS_Lead(flowInputs);
            //Flow.Interview myFlow = Flow.Interview.createInterview('Create_HAS_Lead', flowInputs);
            //myFlow.start();

            //test.stopTest();

            ld1 = UnitTestHelper.prepareLeadFromPersonAccount(false, pa_created, Hippo_Agency_Sales_Q);

            test.startTest();

            LeadTriggerHandler.TESTING_INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY = true;
            insert ld1;
            LeadTriggerHandler.TESTING_INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY = false;
            System.assertNotEquals(null, ld1.Id);

            test.stopTest();
        }

        //Lead ld_created = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Limit 1]?.get(0);
        //System.assertEquals(Hippo_Agency_Sales_Q, ld_created.OwnerId);

        Lead ld_created = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead WHERE Id =: ld1.Id]?.get(0);
        System.assertNotEquals(null, ld_created);
        System.assertEquals(Hippo_Agency_Sales_Q, ld_created.OwnerId);
    }
    */

    @IsTest
    static void testNonWorkablePennyMacLeadsOutsideOfBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');
        Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads');

        String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
        Id estPendingLeadsQueueId = Utils.getQueueId(est_pending_queue_dev_name);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'PennyMac Insurance Services_direct');

        System.runAs(infra_bot) {

            ld.FirstName = 'Asdf';
            ld.LastName = 'Asdf';
            ld.Status = 'New';
            //ld.Email = 'ddd@gg.com';
            //ld.Phone = '3563546546';
            //ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Rockville';
            ld.State = 'MD';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'no_action';
            ld.Cat_Risk_Score__c = 0.0000;
            ld.Non_Cat_Risk_Score__c = 0.0000;
            ld.UTM_Source__c = 'sfmc pennymac';

            test.startTest();

            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;

            test.stopTest();
        }

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        List<Lead> lst_CreatedLeads = [Select Id, RecordTypeId, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
        system.debug('lst_CreatedLeads: ' + lst_CreatedLeads);
        System.assertEquals(1, lst_CreatedLeads.size());
        System.assertEquals(pmRecordType.getRecordTypeId(), lst_CreatedLeads[0].RecordTypeId);
        System.assertEquals(estPendingLeadsQueueId, lst_CreatedLeads[0].OwnerId);
        System.assertEquals(JV_Non_workable_leads_Q, lst_CreatedLeads[0].Pending_Queue_Id__c);
    }

    @IsTest
    static void testHASUWDeclinationsRoutable_ffUnderwritingDeclinationsLead2HASQueueDisabled() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q = false;

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];
        Id initiated_user_id = UserInfo.getUserId();

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.Declination_Reason__c = 'routable_reason';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Lead_Source__c, Declination_Reason__c, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertEquals('UW Declinations', ld1_new.Lead_Source__c);
            System.assertEquals('routable_reason', ld1_new.Declination_Reason__c);
            System.assertEquals(null, ld1_new.Disqualified_Reason__c);

            test.stopTest();

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Lead_Source__c, Declination_Reason__c, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, ld1_updated.OwnerId);
            System.assertEquals('UW Declinations', ld1_updated.Lead_Source__c);
            System.assertEquals('routable_reason', ld1_updated.Declination_Reason__c);
            System.assertEquals(null, ld1_updated.Disqualified_Reason__c);
        }
    }

    @IsTest
    static void testHASUWDeclinationsRoutable_ffUnderwritingDeclinationsLead2HASQueueEnabled() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q = true;

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];
        Id initiated_user_id = UserInfo.getUserId();

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.Declination_Reason__c = 'routable_reason';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Lead_Source__c, Declination_Reason__c, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertEquals('UW Declinations', ld1_new.Lead_Source__c);
            System.assertEquals('routable_reason', ld1_new.Declination_Reason__c);
            System.assertEquals(null, ld1_new.Disqualified_Reason__c);

            test.stopTest();

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Lead_Source__c, Declination_Reason__c, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, ld1_updated.OwnerId);
            System.assertEquals('UW Declinations', ld1_updated.Lead_Source__c);
            System.assertEquals('routable_reason', ld1_updated.Declination_Reason__c);
            System.assertEquals(null, ld1_updated.Disqualified_Reason__c);
        }
    }

    @IsTest
    static void testHASUWDeclinationsNonRoutable() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        //Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];
        Id initiated_user_id = UserInfo.getUserId();

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.Declination_Reason__c = 'too_many_family_units';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Lead_Source__c, Declination_Reason__c, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(Non_workable_leads_Q, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertEquals('UW Declinations', ld1_new.Lead_Source__c);
            System.assertEquals('too_many_family_units', ld1_new.Declination_Reason__c);
            System.assertEquals('Nonworkable Declination', ld1_new.Disqualified_Reason__c);

            test.stopTest();

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Lead_Source__c, Declination_Reason__c, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(Non_workable_leads_Q, ld1_updated.OwnerId);
            System.assertEquals('UW Declinations', ld1_updated.Lead_Source__c);
            System.assertEquals('too_many_family_units', ld1_updated.Declination_Reason__c);
            System.assertEquals('Nonworkable Declination', ld1_updated.Disqualified_Reason__c);
        }
    }

    @IsTest
    static void testAmeriSaveLead_Scenario1() { // SFDC-1312/1326

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id AmeriSave_Q = Utils.getQueueId('AIA_Leads');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'AmeriSave');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            //ld.OwnerId = Non_workable_leads_Q;
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'amerisave';

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('AmeriSave Lead');
        Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(AmeriSave_Q, ld_new1.OwnerId);
        System.assertEquals(amsRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }

    /* - DEPRECATED - LOAN DEPOT RECORD TYPE IS NOT IN USE
    @IsTest
    static void testLoanDepotLead_Scenario1() {

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo ldRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Loan_Depot');

        Id LoanDepot_Q = Utils.getQueueId('Loan_Depot');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest2.prepareLeadByRecordType(false, ldRecordType);

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            //ld.OwnerId = Non_workable_leads_Q;
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;

            insert ld;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertEquals(null, ld_new1.Organization__c);
        System.assertEquals(LoanDepot_Q, ld_new1.OwnerId);
        System.assertEquals(ldRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }
     */

    @IsTest
    static void testLoanDepotLead_Scenario1() {

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        //Id LoanDepot_Q = Utils.getQueueId('Loan_Depot');
        Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        //Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');
        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Loan Depot', true);

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.FirstName = 'Terry';
            ld.LastName = 'Jones';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'tjones3242343@yopmail.com';
            ld.Phone = '9724548265';
            ld.Street = '10624 Lone Pine Ln';
            ld.State = 'TX';
            ld.City = 'Fort Worth';
            ld.PostalCode = '76108';
            ld.Policy_Type__c = 'HO3';
            ld.Quote_Number__c = '89d881d0-2f63-4ad3-a6d9-b2630adf49fe';
            ld.UTM_Source__c = 'realtime';
            ld.Last_Page_Visited__c = 'Clicked Link';
            //ld.Lead_Score__c = '6';
            //ld.Cat_Risk_Class__c = 'no_action';
            //ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            //ld.Non_Cat_Risk_Score__c = 0.060428;

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__c);
        System.assertEquals(HCR_Clicked_on_Link_Q, ld_new1.OwnerId);
        System.assertEquals('HCR Clicked on Link', ld_new1.Lead_Source__c);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }

    @IsTest
    static void testPennymacLead_Scenario8() { // SFDC-1559

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2'); // SFDC-1752
        //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            //ld.OwnerId = Non_workable_leads_Q;
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'realtime'; // SFDC-1559
            ld.Organization__c = null; // SFDC-1559

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertEquals(null, ld_new1.Organization__c);
        System.assertEquals(PMIS_Hippo_Leads_2, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }

    @IsTest
    static void testHCRLead_Insert() {

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.FirstName = 'Terry';
            ld.LastName = 'Jones';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'tjones3242343@yopmail.com';
            ld.Phone = '9724548265';
            ld.Street = '10624 Lone Pine Ln';
            ld.State = 'TX';
            ld.City = 'Fort Worth';
            ld.PostalCode = '76108';
            ld.Policy_Type__c = 'HO3';
            ld.UTM_Source__c = 'realtime';
            ld.Quote_Number__c = '89d881d0-2f63-4ad3-a6d9-b2630adf49fe';
            //ld.Lead_Score__c = '6';
            //ld.Cat_Risk_Class__c = 'no_action';
            //ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            //ld.Non_Cat_Risk_Score__c = 0.060428;

            insert ld;
        }

        test.stopTest();

        Lead ld_new = [Select Id, OwnerId, Is_HCR_Lead__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertEquals('Yes', ld_new.Is_HCR_Lead__c);
    }

    @IsTest
    static void testHCRLead_Update() {

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.FirstName = 'Terry';
            ld.LastName = 'Jones';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'tjones3242343@yopmail.com';
            ld.Phone = '9724548265';
            ld.Street = '10624 Lone Pine Ln';
            ld.State = 'TX';
            ld.City = 'Fort Worth';
            ld.PostalCode = '76108';
            ld.Policy_Type__c = 'HO3';
            ld.Quote_Number__c = '89d881d0-2f63-4ad3-a6d9-b2630adf49fe';
            //ld.Lead_Score__c = '6';
            //ld.Cat_Risk_Class__c = 'no_action';
            //ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            //ld.Non_Cat_Risk_Score__c = 0.060428;

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Is_HCR_Lead__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.debug('ld_new1: ' + ld_new1);
            System.assertEquals('No', ld_new1.Is_HCR_Lead__c);

            ld.UTM_Source__c = 'realtime';
            update ld;
        }

        test.stopTest();

        Lead ld_new2 = [Select Id, OwnerId, Is_HCR_Lead__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertEquals('Yes', ld_new2.Is_HCR_Lead__c);
    }

    @IsTest
    static void testDeduplicationsRule3HCRPositive() { // SFDC-1469 + modifictaion based on SFDC-1597 to include HCR leads

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        //Id LoanDepot_Q = Utils.getQueueId('Loan_Depot');
        Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');
        Id JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');
        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        //Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');
        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Loan Depot', true);

        System.runAs(infra_bot) {

            ld1.Status = 'New';
            ld1.FirstName = 'Terry';
            ld1.LastName = 'Jones';
            ld1.POD_Quote_ID__c = '';
            ld1.Email = 'tjones3242343@yopmail.com';
            ld1.Phone = '9724548265';
            ld1.Street = '10624 Lone Pine Ln';
            ld1.State = 'TX';
            ld1.City = 'Fort Worth';
            ld1.PostalCode = '76108';
            ld1.Policy_Type__c = 'HO3';
            ld1.Quote_Number__c = '89d881d0-2f63-4ad3-a6d9-b2630adf49fe';
            ld1.UTM_Source__c = 'realtime';
            ld1.Last_Page_Visited__c = 'Clicked Link';

            insert ld1;
        }

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');
        Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName, IsJVLead__c, Is_HCR_Lead__c From Lead Where Id = :ld1.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__c);
        System.assertEquals(HCR_Clicked_on_Link_Q, ld_new1.OwnerId);
        System.assertEquals('HCR Clicked on Link', ld_new1.Lead_Source__c);
        System.assertEquals(false, ld_new1.IsJVLead__c);
        System.assertEquals('Yes', ld_new1.Is_HCR_Lead__c);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

        test.startTest();

        Lead ld2 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Loan Depot', true);

        System.runAs(infra_bot) {

            ld2.Status = 'New';
            ld2.FirstName = 'Terry';
            ld2.LastName = 'Jones';
            ld2.POD_Quote_ID__c = '23232323';
            ld2.Email = 'tjones3242343@yopmail.com';
            ld2.Phone = '9724548265';
            ld2.Street = '10624 Lone Pine Ln';
            ld2.State = 'TX';
            ld2.City = 'Fort Worth';
            ld2.PostalCode = '76108';
            ld2.Policy_Type__c = 'HO3';
            ld2.Quote_Number__c = '89d881d0-2f63-4ad3-a6d9-b2630adf49fe';
            ld2.Cat_Risk_Class__c = 'no_action';
            ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld2.Non_Cat_Risk_Score__c = 0.060428;
            ld2.POD_Lead_Id__c = '12121212';
            ld2.UTM_Source__c = 'realtime';
            ld2.Last_Page_Visited__c = 'Clicked Link';

            insert ld2;
        }

        test.stopTest();

        List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c, Lead_Score__c, IsJVLead__c, Is_HCR_Lead__c, RecordTypeId,
                Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
        From Lead Where Id =: ld2.Id];

        System.assertEquals(1, lst_CreatedLeads.size());
        ld2 = lst_CreatedLeads[0]; // just for convenience

        System.assertNotEquals(null, ld2.Organization__c);
        System.assertEquals(false, ld2.IsJVLead__c);
        System.assertEquals('Yes', ld2.Is_HCR_Lead__c);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld2.RecordTypeId);

        System.assertNotEquals(HCR_Clicked_on_Link_Q, ld2.OwnerId);
        system.assertNotEquals(JV_Non_workable_leads_Q, ld2.OwnerId);
        system.assertEquals(Non_workable_leads_Q, ld2.OwnerId);

        // check if merge occurred between the leads data (SFDC-1476/SFDC-1597)
        Lead ld_new1_updated = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName, Lead_Score__c,
                Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
        From Lead Where Id = :ld1.Id Limit 1];

        System.assertEquals(ld2.Lead_Score__c, ld_new1_updated.Lead_Score__c);
        System.assertEquals(ld2.Non_Cat_Risk_Class__c, ld_new1_updated.Non_Cat_Risk_Class__c);
        System.assertEquals(ld2.Non_Cat_Risk_Score__c, ld_new1_updated.Non_Cat_Risk_Score__c);
        System.assertEquals(ld2.POD_Quote_ID__c, ld_new1_updated.POD_Quote_ID__c);
        System.assertEquals(ld2.POD_Lead_Id__c, ld_new1_updated.POD_Lead_Id__c);
        System.assertEquals(ld2.Organization__c, ld_new1_updated.Organization__c);
        System.assertEquals(ld2.POD_Quote_Link__c, ld_new1_updated.POD_Quote_Link__c);
        System.assertEquals(ld2.POD_Lead_Link__c, ld_new1_updated.POD_Lead_Link__c);
        System.assertEquals(HCR_Clicked_on_Link_Q, ld_new1_updated.OwnerId);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1_updated.RecordTypeId);
    }

    @IsTest
    static void testDeduplicationsRule4Positive_Scenario1() { // SFDC-1463

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupB2CSalesLeads = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        System.debug('ffDDupB2CSalesLeads: ' + ffDDupB2CSalesLeads);

        if ( ffDDupB2CSalesLeads ) {

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld1.Status = 'New';
                ld1.Email = 'test.sfdc1@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.Street = '435 Homer Ave';
                ld1.City = 'Palo Alto';
                ld1.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld1.PostalCode = '94301';

                insert ld1;

                Lead ld_new1 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
                System.assertEquals(null, ld_new1.Organization__c);
                System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new1.Status);
                System.assertNotEquals('Duplicate', ld_new1.Disqualified_Reason__c);

                test.startTest();

                Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld2.Status = 'New';
                ld2.Email = 'test.sfdc2@leads.com';
                ld2.Phone = '3011237845';
                ld2.MobilePhone = '2021237845';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.Street = '435 Homer Ave';
                ld2.City = 'Palo Alto';
                ld2.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld2.PostalCode = '94301';

                insert ld2;

                test.stopTest();

                Lead ld_new2 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
                System.assertEquals(Non_workable_leads_Q, ld_new2.OwnerId);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
                System.assertEquals('Cancelled', ld_new2.Status);
                System.assertEquals('Duplicate', ld_new2.Disqualified_Reason__c);
            }
        }
    }

    @IsTest
    static void testDeduplicationsRule4Positive_Scenario2() { // SFDC-1463

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupB2CSalesLeads = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        System.debug('ffDDupB2CSalesLeads: ' + ffDDupB2CSalesLeads);

        if ( ffDDupB2CSalesLeads ) {

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld1.Status = 'New';
                ld1.Email = 'test.sfdc1@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.Street = '435 Homer Ave';
                ld1.City = 'Palo Alto';
                ld1.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld1.PostalCode = '94301';
                ld1.Line_of_Business__c = 'HO3'; // Scenario2

                insert ld1;

                Lead ld_new1 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
                System.assertEquals(null, ld_new1.Organization__c);
                System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new1.Status);
                System.assertNotEquals('Duplicate', ld_new1.Disqualified_Reason__c);

                test.startTest();

                Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld2.Status = 'New';
                ld2.Email = 'test.sfdc2@leads.com';
                ld2.Phone = '3011237845';
                ld2.MobilePhone = '2021237845';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.Street = '435 Homer Ave';
                ld2.City = 'Palo Alto';
                ld2.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld2.PostalCode = '94301';
                ld2.Line_of_Business__c = 'HO3'; // Scenario2

                insert ld2;

                test.stopTest();

                Lead ld_new2 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
                System.assertEquals(Non_workable_leads_Q, ld_new2.OwnerId);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
                System.assertEquals('Cancelled', ld_new2.Status);
                System.assertEquals('Duplicate', ld_new2.Disqualified_Reason__c);
            }
        }
    }

    @IsTest
    static void testDeduplicationsRule4Positive_Scenario3() { // SFDC-1463

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupB2CSalesLeads = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        System.debug('ffDDupB2CSalesLeads: ' + ffDDupB2CSalesLeads);

        if ( ffDDupB2CSalesLeads ) {

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld1.Status = 'New';
                ld1.Email = 'test.sfdc1@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.Street = '435 Homer Ave';
                ld1.City = 'Palo Alto';
                ld1.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld1.PostalCode = '94301';
                ld1.Policy_Types__c = 'HO3'; // Scenario3

                insert ld1;

                Lead ld_new1 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
                System.assertEquals(null, ld_new1.Organization__c);
                System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new1.Status);
                System.assertNotEquals('Duplicate', ld_new1.Disqualified_Reason__c);

                test.startTest();

                Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld2.Status = 'New';
                ld2.Email = 'test.sfdc2@leads.com';
                ld2.Phone = '3011237845';
                ld2.MobilePhone = '2021237845';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.Street = '435 Homer Ave';
                ld2.City = 'Palo Alto';
                ld2.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld2.PostalCode = '94301';
                ld2.Policy_Types__c = 'HO3'; // Scenario3

                insert ld2;

                test.stopTest();

                Lead ld_new2 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
                System.assertEquals(Non_workable_leads_Q, ld_new2.OwnerId);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
                System.assertEquals('Cancelled', ld_new2.Status);
                System.assertEquals('Duplicate', ld_new2.Disqualified_Reason__c);
            }
        }
    }

    @IsTest
    static void testDeduplicationsRule4Negative_Scenario1() { // SFDC-1463

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupB2CSalesLeads = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        System.debug('ffDDupB2CSalesLeads: ' + ffDDupB2CSalesLeads);

        if ( ffDDupB2CSalesLeads ) {

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld1.Status = 'New';
                ld1.Email = 'test.sfdc1@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.Street = '435 Homer Ave';
                ld1.City = 'Palo Alto';
                ld1.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld1.PostalCode = '94301';
                ld1.Line_of_Business__c = 'HO3'; // Scenario1
                ld1.Policy_Types__c = 'HO3'; // Scenario1

                insert ld1;

                Lead ld_new1 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
                System.assertEquals(null, ld_new1.Organization__c);
                System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new1.Status);
                System.assertNotEquals('Duplicate', ld_new1.Disqualified_Reason__c);

                test.startTest();

                Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld2.Status = 'New';
                ld2.Email = 'test.sfdc2@leads.com';
                ld2.Phone = '3011237845';
                ld2.MobilePhone = '2021237845';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.Street = '435 Homer Ave';
                ld2.City = 'Palo Alto';
                ld2.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld2.PostalCode = '94301';
                ld2.Line_of_Business__c = 'Auto'; // Scenario1
                ld2.Policy_Types__c = 'Auto'; // Scenario1

                insert ld2;

                test.stopTest();

                Lead ld_new2 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
                System.assertNotEquals(Non_workable_leads_Q, ld_new2.OwnerId);
                System.assertEquals(B2C_Direct_1, ld_new2.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new2.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new2.Status);
                System.assertNotEquals('Duplicate', ld_new2.Disqualified_Reason__c);
            }
        }
    }

    @IsTest
    static void testDeduplicationsRule4Negative_Scenario2() { // SFDC-1463

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupB2CSalesLeads = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        System.debug('ffDDupB2CSalesLeads: ' + ffDDupB2CSalesLeads);

        if ( ffDDupB2CSalesLeads ) {

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld1.Status = 'New';
                ld1.Email = 'test.sfdc1@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.Street = '435 Homer Ave';
                ld1.City = 'Palo Alto';
                ld1.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld1.PostalCode = '94301';
                ld1.Line_of_Business__c = null; // Scenario2
                ld1.Policy_Types__c = null; // Scenario2

                insert ld1;

                Lead ld_new1 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
                System.assertEquals(null, ld_new1.Organization__c);
                System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new1.Status);
                System.assertNotEquals('Duplicate', ld_new1.Disqualified_Reason__c);

                test.startTest();

                Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld2.Status = 'New';
                ld2.Email = 'test.sfdc2@leads.com';
                ld2.Phone = '3011237845';
                ld2.MobilePhone = '2021237845';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.Street = '435 Homer Ave';
                ld2.City = 'Palo Alto';
                ld2.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld2.PostalCode = '94301';
                ld2.Line_of_Business__c = 'Flood'; // Scenario2
                ld2.Policy_Types__c = null; // Scenario2

                insert ld2;

                test.stopTest();

                Lead ld_new2 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
                System.assertNotEquals(Non_workable_leads_Q, ld_new2.OwnerId);
                System.assertEquals(B2C_Direct_1, ld_new2.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new2.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new2.Status);
                System.assertNotEquals('Duplicate', ld_new2.Disqualified_Reason__c);
            }
        }
    }

    @IsTest
    static void testDeduplicationsRule4Negative_Scenario3() { // SFDC-1463

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupB2CSalesLeads = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        System.debug('ffDDupB2CSalesLeads: ' + ffDDupB2CSalesLeads);

        if ( ffDDupB2CSalesLeads ) {

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld1.Status = 'New';
                ld1.Email = 'test.sfdc1@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.Street = '435 Homer Ave';
                ld1.City = 'Palo Alto';
                ld1.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld1.PostalCode = '94301';
                ld1.Line_of_Business__c = null; // Scenario3
                ld1.Policy_Types__c = 'Auto'; // Scenario3

                insert ld1;

                Lead ld_new1 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
                System.assertEquals(null, ld_new1.Organization__c);
                System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new1.Status);
                System.assertNotEquals('Duplicate', ld_new1.Disqualified_Reason__c);

                test.startTest();

                Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld2.Status = 'New';
                ld2.Email = 'test.sfdc2@leads.com';
                ld2.Phone = '3011237845';
                ld2.MobilePhone = '2021237845';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.Street = '435 Homer Ave';
                ld2.City = 'Palo Alto';
                ld2.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld2.PostalCode = '94301';
                ld2.Line_of_Business__c = 'Flood'; // Scenario3
                ld2.Policy_Types__c = 'Auto'; // Scenario3

                insert ld2;

                test.stopTest();

                Lead ld_new2 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
                System.assertNotEquals(Non_workable_leads_Q, ld_new2.OwnerId);
                System.assertEquals(B2C_Direct_1, ld_new2.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new2.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new2.Status);
                System.assertNotEquals('Duplicate', ld_new2.Disqualified_Reason__c);
            }
        }
    }

    @IsTest
    static void testDeduplicationsRule4Negative_Scenario4() { // SFDC-1463

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupB2CSalesLeads = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        System.debug('ffDDupB2CSalesLeads: ' + ffDDupB2CSalesLeads);

        if ( ffDDupB2CSalesLeads ) {

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld1.Status = 'New';
                ld1.Email = 'test.sfdc1@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.Street = '435 Homer Ave';
                ld1.City = 'Palo Alto';
                ld1.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld1.PostalCode = '94301';
                ld1.Line_of_Business__c = null; // Scenario4
                ld1.Policy_Types__c = 'Auto'; // Scenario4

                insert ld1;

                Lead ld_new1 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
                System.assertEquals(null, ld_new1.Organization__c);
                System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new1.Status);
                System.assertNotEquals('Duplicate', ld_new1.Disqualified_Reason__c);

                test.startTest();

                Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

                ld2.Status = 'New';
                ld2.Email = 'test.sfdc2@leads.com';
                ld2.Phone = '3011237845';
                ld2.MobilePhone = '2021237845';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.Street = '435 Homer Ave';
                ld2.City = 'Palo Alto';
                ld2.State = 'CA'; // Just for readability. state was provided in UnitTestHelper.prepareB2CLead
                ld2.PostalCode = '94301';
                ld2.Line_of_Business__c = 'Auto'; // Scenario4
                ld2.Policy_Types__c = 'Flood'; // Scenario4

                insert ld2;

                test.stopTest();

                Lead ld_new2 = [Select Id, Status, Lead_Source__c, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
                System.assertNotEquals(Non_workable_leads_Q, ld_new2.OwnerId);
                System.assertEquals(B2C_Direct_1, ld_new2.OwnerId);
                System.assertEquals('Hippo Direct Leads', ld_new2.Lead_Source__c);
                System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
                System.assertNotEquals('Cancelled', ld_new2.Status);
                System.assertNotEquals('Duplicate', ld_new2.Disqualified_Reason__c);
            }
        }
    }

    @IsTest
    static void test_ff_InjectOrgToPennyMacLead() { // SFDC-1610

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');

        Boolean ffInjectOrgToJVLeads = FeatureFlags.instance.ff_Inject_Org_to_JV_Leads;

        if ( ffInjectOrgToJVLeads ) {

            Id PMIS_Hippo_Leads_1 = Utils.getQueueId('PMIS_Hippo_Leads_1'); // SFDC-1752
            //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            Account acc = LeadTriggerTest.prepareAccount(true, 'PennyMac Insurance Agency');

            Lead ld = UnitTestHelper.prepareLeadByRecordTypeName(false, pmRecordType.getName());

            test.startTest();

            System.runAs(infra_bot) {

                ld.Status = 'New';
                ld.Email = 'test.sfdc@leads.com';
                ld.Phone = '3011237845';
                ld.MobilePhone = '2021237845';
                ld.POD_Quote_ID__c = '';
                ld.Lead_Score__c = '6';
                ld.Cat_Risk_Class__c = 'no_action';
                ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld.Non_Cat_Risk_Score__c = 0.060428;
                ld.UTM_Source__c = 'realtime';

                insert ld;
            }

            test.stopTest();

            Lead ld_new1 = [Select Id, OwnerId, IsJVLead__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals('PennyMac Insurance Agency', ld_new1.Organization__r.Name);
            System.assertEquals(true, ld_new1.IsJVLead__c);
            System.assertEquals(PMIS_Hippo_Leads_1, ld_new1.OwnerId);
            System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        }
    }

    @IsTest
    static void test_ff_InjectOrgToAmeriSaveLead() { // SFDC-1610

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('AmeriSave Lead');

        Boolean ffInjectOrgToJVLeads = FeatureFlags.instance.ff_Inject_Org_to_JV_Leads;

        if ( ffInjectOrgToJVLeads ) {

            Id AmeriSave_Q = Utils.getQueueId('AIA_Leads');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            Account acc = LeadTriggerTest.prepareAccount(true, 'AmeriSave Insurance Agency');

            Lead ld = UnitTestHelper.prepareLeadByRecordTypeName(false, amsRecordType.getName());

            test.startTest();

            System.runAs(infra_bot) {

                ld.Status = 'New';
                ld.Email = 'test.sfdc@leads.com';
                ld.Phone = '3011237845';
                ld.MobilePhone = '2021237845';
                ld.POD_Quote_ID__c = '';
                ld.Lead_Score__c = '6';
                ld.Cat_Risk_Class__c = 'no_action';
                ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld.Non_Cat_Risk_Score__c = 0.060428;
                ld.UTM_Source__c = 'realtime';

                insert ld;
            }

            test.stopTest();

            Lead ld_new1 = [Select Id, OwnerId, IsJVLead__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals('AmeriSave Insurance Agency', ld_new1.Organization__r.Name);
            System.assertEquals(true, ld_new1.IsJVLead__c);
            System.assertEquals(AmeriSave_Q, ld_new1.OwnerId);
            System.assertEquals(amsRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        }
    }

    @IsTest
    static void testIsJVLeadFlagBeingSetCorrectly1() { // SFDC-1610

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        Id  JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');
        Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Account acc = LeadTriggerTest.prepareAccount(true, 'PennyMac Insurance Services_direct');

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.Organization__c = acc.Id;
            ld.FirstName = 'Jovon';
            ld.LastName = 'Pittman';
            ld.Email = '';
            ld.Phone = '';
            ld.MobilePhone = '';
            ld.POD_Quote_ID__c = '';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'no_action';
            ld.UTM_Source__c = 'pennymacinsurance';

            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, OwnerId, Pending_Queue_Id__c, IsJVLead__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertEquals(pstPendingLeadsQueueId, ld_new1.OwnerId);
        System.assertEquals(JV_Non_workable_leads_Q, ld_new1.Pending_Queue_Id__c);
        System.assertNotEquals(null, ld_new1.Organization__c);
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals('PennyMac Insurance Services_direct', ld_new1.Organization__r.Name);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals(true, ld_new1.IsJVLead__c);
    }

    @IsTest
    static void testIsJVLeadFlagBeingSetCorrectly2() { // SFDC-1610

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        Id  JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');
        Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Account acc = LeadTriggerTest.prepareAccount(true, 'PennyMac Insurance Services_direct');

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.Organization__c = acc.Id;
            ld.FirstName = 'Jovon';
            ld.LastName = 'Pittman';
            ld.Email = '';
            ld.Phone = '';
            ld.MobilePhone = '';
            ld.POD_Quote_ID__c = '';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'no_action';
            ld.UTM_Source__c = 'pennymacinsurance';

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, OwnerId, IsJVLead__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertEquals(JV_Non_workable_leads_Q, ld_new1.OwnerId);
        System.assertNotEquals(null, ld_new1.Organization__c);
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals('PennyMac Insurance Services_direct', ld_new1.Organization__r.Name);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals(true, ld_new1.IsJVLead__c);
    }

    @IsTest
    static void test_ff_InjectOrgToHCRLead() { // SFDC-1628/1629

        LeadTriggerTest.TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR = true;

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');
        RecordTypeInfo rfRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Risk_Factor');
        RecordTypeInfo haRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Hippo_Analytics');

        Boolean ffInjectOrgToHCRLeads = FeatureFlags.instance.ff_Inject_Org_to_HCR_Leads || LeadTriggerTest.TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR;
        System.debug('ffInjectOrgToHCRLeads: ' + ffInjectOrgToHCRLeads);

        if ( ffInjectOrgToHCRLeads ) {

            Id HCR_Q = Utils.getQueueId('Loan_Depot');
            Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            Account acc1 = LeadTriggerTest.prepareAccount(true, 'Loan Depot', true);
            Account acc2 = LeadTriggerTest.prepareAccount(true, 'Risk Factor, LLC DBA First Street');
            Account acc3 = LeadTriggerTest.prepareAccount(true, 'Hippo Analytics, Inc.');

            Lead ld1 = UnitTestHelper.prepareLeadByRecordTypeName(false, b2cRecordType.getName());
            Lead ld2 = UnitTestHelper.prepareLeadByRecordTypeName(false, rfRecordType.getName());
            Lead ld3 = UnitTestHelper.prepareLeadByRecordTypeName(false, haRecordType.getName());

            test.startTest();

            System.runAs(infra_bot) {

                ld1.Status = 'New';
                ld1.Email = 'test1.sfdc@leads.com';
                ld1.Phone = '3011237845';
                ld1.MobilePhone = '2021237845';
                ld1.POD_Quote_ID__c = '';
                ld1.Lead_Score__c = '6';
                ld1.Cat_Risk_Class__c = 'no_action';
                ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld1.Non_Cat_Risk_Score__c = 0.060428;
                ld1.UTM_Source__c = 'realtime';
                ld1.Partner_UTM_Source__c = null;
                ld1.Last_Page_Visited__c = 'Clicked Link';

                insert ld1;

                ld2.Status = 'New';
                ld2.Email = 'test2.sfdc@leads.com';
                ld2.Phone = '3011237846';
                ld2.MobilePhone = '2021237846';
                ld2.POD_Quote_ID__c = '';
                ld2.Lead_Score__c = '6';
                ld2.Cat_Risk_Class__c = 'no_action';
                ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld2.Non_Cat_Risk_Score__c = 0.060428;
                ld2.UTM_Source__c = 'realtime';
                ld1.Last_Page_Visited__c = 'Clicked Link';

                insert ld2;

                ld3.Status = 'New';
                ld3.Email = 'test3.sfdc@leads.com';
                ld3.Phone = '3011237847';
                ld3.MobilePhone = '2021237847';
                ld3.POD_Quote_ID__c = '';
                ld3.Lead_Score__c = '6';
                ld3.Cat_Risk_Class__c = 'no_action';
                ld3.Non_Cat_Risk_Class__c = 'interior_inspection_required';
                ld3.Non_Cat_Risk_Score__c = 0.060428;
                ld3.UTM_Source__c = 'realtime';
                ld1.Last_Page_Visited__c = 'Clicked Link';

                insert ld3;
            }

            test.stopTest();

            LeadTriggerTest.TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR = false;

            Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, IsJVLead__c, Is_HCR_Lead__c, Partner_UTM_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals('Loan Depot', ld_new1.Organization__r.Name);
            System.assertEquals(false, ld_new1.IsJVLead__c);
            System.assertEquals('Yes', ld_new1.Is_HCR_Lead__c);
            System.assertEquals(HCR_Clicked_on_Link_Q, ld_new1.OwnerId);
            System.assertEquals('HCR Clicked on Link', ld_new1.Lead_Source__c);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            Lead ld_new2 = [Select Id, OwnerId, IsJVLead__c, Is_HCR_Lead__c, Partner_UTM_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
            System.assertNotEquals(null, ld_new2.Organization__c);
            System.assertNotEquals(null, ld_new2.Organization__r.Name);
            System.assertEquals('Risk Factor, LLC DBA First Street', ld_new2.Organization__r.Name);
            System.assertEquals(false, ld_new2.IsJVLead__c);
            System.assertEquals('Yes', ld_new2.Is_HCR_Lead__c);
            System.assertEquals(HCR_Q, ld_new2.OwnerId);
            System.assertEquals(rfRecordType.getRecordTypeId(), ld_new2.RecordTypeId);

            Lead ld_new3 = [Select Id, OwnerId, IsJVLead__c, Is_HCR_Lead__c, Partner_UTM_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld3.Id Limit 1];
            System.assertNotEquals(null, ld_new3.Organization__c);
            System.assertNotEquals(null, ld_new3.Organization__r.Name);
            System.assertEquals('Hippo Analytics, Inc.', ld_new3.Organization__r.Name);
            System.assertEquals(false, ld_new3.IsJVLead__c);
            System.assertEquals('Yes', ld_new3.Is_HCR_Lead__c);
            System.assertEquals(HCR_Q, ld_new3.OwnerId);
            System.assertEquals(haRecordType.getRecordTypeId(), ld_new3.RecordTypeId);
        }
    }

    @IsTest
    static void test_ff_DisableInjectOrgToHCRLead() { // SFDC-1540

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');
        //RecordTypeInfo rfRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Risk_Factor');
        //RecordTypeInfo haRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Hippo_Analytics');

        //Id HCR_Q = Utils.getQueueId('Loan_Depot');
        Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        //Account acc1 = LeadTriggerTest.prepareAccount(true, 'Loan Depot', true);
        //Account acc2 = LeadTriggerTest.prepareAccount(true, 'Risk Factor, LLC DBA First Street');
        //Account acc3 = LeadTriggerTest.prepareAccount(true, 'Hippo Analytics, Inc.');

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Loan Depot', true);
        Lead ld2 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Risk Factor, LLC DBA First Street', true);
        Lead ld3 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Hippo Analytics, Inc.', true);

        test.startTest();

        System.runAs(infra_bot) {

            ld1.Status = 'New';
            ld1.Email = 'test1.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';
            ld1.Cat_Risk_Class__c = 'no_action';
            ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld1.Non_Cat_Risk_Score__c = 0.060428;
            ld1.UTM_Source__c = 'realtime';
            ld1.Partner_UTM_Source__c = null;
            ld1.Last_Page_Visited__c = 'Clicked Link';

            insert ld1;

            ld2.Status = 'New';
            ld2.Email = 'test2.sfdc@leads.com';
            ld2.Phone = '3011237846';
            ld2.MobilePhone = '2021237846';
            ld2.POD_Quote_ID__c = '';
            ld2.Lead_Score__c = '6';
            ld2.Cat_Risk_Class__c = 'no_action';
            ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld2.Non_Cat_Risk_Score__c = 0.060428;
            ld2.UTM_Source__c = 'realtime';
            ld2.Last_Page_Visited__c = 'Clicked Link';

            insert ld2;

            ld3.Status = 'New';
            ld3.Email = 'test3.sfdc@leads.com';
            ld3.Phone = '3011237847';
            ld3.MobilePhone = '2021237847';
            ld3.POD_Quote_ID__c = '';
            ld3.Lead_Score__c = '6';
            ld3.Cat_Risk_Class__c = 'no_action';
            ld3.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld3.Non_Cat_Risk_Score__c = 0.060428;
            ld3.UTM_Source__c = 'realtime';
            ld3.Last_Page_Visited__c = 'Clicked Link';

            insert ld3;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, IsJVLead__c, Is_HCR_Lead__c, Partner_UTM_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__c);
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals('Loan Depot', ld_new1.Organization__r.Name);
        System.assertEquals(false, ld_new1.IsJVLead__c);
        System.assertEquals('Yes', ld_new1.Is_HCR_Lead__c);
        System.assertEquals(HCR_Clicked_on_Link_Q, ld_new1.OwnerId);
        System.assertEquals('HCR Clicked on Link', ld_new1.Lead_Source__c);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

        Lead ld_new2 = [Select Id, OwnerId, IsJVLead__c, Is_HCR_Lead__c, Partner_UTM_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld2.Id Limit 1];
        System.assertNotEquals(null, ld_new2.Organization__c);
        System.assertNotEquals(null, ld_new2.Organization__r.Name);
        System.assertEquals('Risk Factor, LLC DBA First Street', ld_new2.Organization__r.Name);
        System.assertEquals(false, ld_new2.IsJVLead__c);
        System.assertEquals('Yes', ld_new2.Is_HCR_Lead__c);
        System.assertEquals(HCR_Clicked_on_Link_Q, ld_new2.OwnerId);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);

        Lead ld_new3 = [Select Id, OwnerId, IsJVLead__c, Is_HCR_Lead__c, Partner_UTM_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld3.Id Limit 1];
        System.assertNotEquals(null, ld_new3.Organization__c);
        System.assertNotEquals(null, ld_new3.Organization__r.Name);
        System.assertEquals('Hippo Analytics, Inc.', ld_new3.Organization__r.Name);
        System.assertEquals(false, ld_new3.IsJVLead__c);
        System.assertEquals('Yes', ld_new3.Is_HCR_Lead__c);
        System.assertEquals(HCR_Clicked_on_Link_Q, ld_new3.OwnerId);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new3.RecordTypeId);
    }

    @IsTest
    static void testDeduplicationsRulesSuppressedForAnAgent() { // SFDC-1492/1534

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id AmeriSave_Q = Utils.getQueueId('AIA_Leads');
        Id JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'AmeriSave');

        System.runAs(infra_bot) {

            ld1.Status = 'New';
            ld1.Line_of_Business__c = 'HO3';
            //ld.OwnerId = Non_workable_leads_Q;
            ld1.POD_Quote_ID__c = '';
            ld1.Email = 'kkgallardo@outlook.com';
            ld1.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld1.Cat_Risk_Class__c = 'no_action';
            //ld1.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            //ld1.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld1;
        }

        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('AmeriSave Lead');
        Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld1.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(AmeriSave_Q, ld_new1.OwnerId);
        System.assertEquals(amsRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

        Lead ld2 = UnitTestHelper.prepareLeadByRecordTypeName(false, amsRecordType.getName()); //LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'AmeriSave');

        Profile amerisaveProfile = [select id from profile where name = 'AmeriSave' LIMIT 1];

        System.assertNotEquals(null, ameriSaveProfile);

        User amerisave_user = UnitTestHelper.createuser(amerisaveProfile.Id);
        System.assertNotEquals(null, amerisave_user);
        System.assertNotEquals(null, amerisave_user.Id);

        test.startTest();

        System.runAs(amerisave_user) {

            ld2.Status = 'New';
            ld2.Line_of_Business__c = 'HO3';
            //ld.OwnerId = Non_workable_leads_Q;
            ld2.POD_Quote_ID__c = '123456';
            ld2.POD_Lead_Id__c = '654321';
            ld2.Email = 'kkgallardo@outlook.com';
            ld2.Phone = '4026404310';
            ld2.Lead_Score__c = '6';
            ld2.Cat_Risk_Class__c = 'no_action';
            ld2.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld2.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld2;
        }

        test.stopTest();

        List<Lead> lst_CreatedLeads = [Select Id, RecordTypeId, FirstName, LastName, OwnerId, Pending_Queue_Id__c, Lead_Score__c,
                Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
        From Lead Where Id =: ld2.Id];
        System.assertEquals(1, lst_CreatedLeads.size());
        ld2 = lst_CreatedLeads[0]; // just for convenience
        System.assertNotEquals(JV_Non_workable_leads_Q, ld2.OwnerId);
        System.assertEquals(amerisave_user.Id, ld2.OwnerId);
        System.assertEquals(amsRecordType.getRecordTypeId(), ld2.RecordTypeId);

        // check if merge occurred between the leads data (SFDC-1476) - SHOULD NOT OCCURRED AS MERGED WAS SKIPPED FOR AN AGENT CREATED LEAD (SFDC-1492/1534)
        Lead ld_new1_updated = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName, Lead_Score__c,
                Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
        From Lead Where Id = :ld1.Id Limit 1];
        System.assertNotEquals(ld2.Lead_Score__c, ld_new1_updated.Lead_Score__c);
        System.assertNotEquals(ld2.Non_Cat_Risk_Class__c, ld_new1_updated.Non_Cat_Risk_Class__c);
        System.assertNotEquals(ld2.Non_Cat_Risk_Score__c, ld_new1_updated.Non_Cat_Risk_Score__c);
        System.assertNotEquals(ld2.POD_Quote_ID__c, ld_new1_updated.POD_Quote_ID__c);
        System.assertNotEquals(ld2.POD_Lead_Id__c, ld_new1_updated.POD_Lead_Id__c);
        System.assertNotEquals(ld2.Organization__c, ld_new1_updated.Organization__c);
        System.assertNotEquals(ld2.POD_Quote_Link__c, ld_new1_updated.POD_Quote_Link__c);
        System.assertNotEquals(ld2.POD_Lead_Link__c, ld_new1_updated.POD_Lead_Link__c);
        System.assertEquals(AmeriSave_Q, ld_new1_updated.OwnerId);
        System.assertEquals(amsRecordType.getRecordTypeId(), ld_new1_updated.RecordTypeId);

        System.runAs(infra_bot) {

            ld2.Lead_Score__c = '6';
            ld1.Cat_Risk_Class__c = 'no_action';
            update ld2;
        }

        Lead ld2_updated = [Select Id, RecordTypeId, FirstName, LastName, OwnerId, Pending_Queue_Id__c, Lead_Score__c,
                Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
        From Lead Where Id =: ld2.Id LIMIT 1];

        System.assertEquals(amerisave_user.Id, ld2_updated.OwnerId);
    }
}