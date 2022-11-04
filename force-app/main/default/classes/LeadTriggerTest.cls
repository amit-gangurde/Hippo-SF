@IsTest
public class LeadTriggerTest {

    public static Boolean NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    public static Boolean TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR = false;

    @testsetup
    public static void testSetup() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));
    }

    @IsTest
    static void testGo2SleepESTLeadsInsideBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
        String estPendingLeadsQueueId = Utils.getQueueId(est_pending_queue_dev_name);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
            ld.Declination_Reason__c = 'routable_reason';

            //LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;

            test.startTest();

            insert ld;

            test.stopTest();

            //User currentUser = [Select TimeZoneSidKey from User where id =: UserInfo.getUserId()];
            BusinessHours bh_EST = [SELECT Id FROM BusinessHours WHERE Name = 'EST'];
            List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
            System.assertEquals(1, lst_CreatedLeads.size());
            Boolean isWithin = BusinessHours.isWithin(bh_EST.id, system.now()) || LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS || QACockpit.instance.qacp_Force_Inside_Business_Hours_for_EST.enabled;
            System.debug('isWithin: ' + isWithin);

            //LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            if (isWithin) {

                System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, lst_CreatedLeads[0].OwnerId);
                System.assertEquals(null, lst_CreatedLeads[0].Pending_Queue_Id__c);
            } else {

                System.assertEquals(estPendingLeadsQueueId, lst_CreatedLeads[0].OwnerId);
                System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, lst_CreatedLeads[0].Pending_Queue_Id__c);
            }
        }
    }

    @IsTest
    static void testGo2SleepESTLeadsOutsideOfBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
        String estPendingLeadsQueueId = Utils.getQueueId(est_pending_queue_dev_name);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
            ld.Declination_Reason__c = 'routable_reason';

            test.startTest();

            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;

            test.stopTest();

            List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
            System.assertEquals(1, lst_CreatedLeads.size());
            System.assertEquals(estPendingLeadsQueueId, lst_CreatedLeads[0].OwnerId);
            System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, lst_CreatedLeads[0].Pending_Queue_Id__c);
        }
    }

    @IsTest
    static void testGo2SleepPSTLeadsInsideBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;
        System.debug('ffUnderwritingDeclinationsLead2HASQueue: ' + ffUnderwritingDeclinationsLead2HASQueue);
        
        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');
            ld.Declination_Reason__c = 'routable_reason';

            test.startTest();

            insert ld;

            test.stopTest();

            //User currentUser = [Select TimeZoneSidKey from User where id =: UserInfo.getUserId()];
            BusinessHours bh_PST = [SELECT Id FROM BusinessHours WHERE Name = 'PST'];
            List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
            System.assertEquals(1, lst_CreatedLeads.size());
            Boolean isWithin = BusinessHours.isWithin(bh_PST.id, system.now()) || LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS || QACockpit.instance.qacp_Force_Inside_Business_Hours_for_PST.enabled;
            if (isWithin) {

                System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, lst_CreatedLeads[0].OwnerId);
                System.assertEquals(null, lst_CreatedLeads[0].Pending_Queue_Id__c);
            } else {

                System.assertEquals(pstPendingLeadsQueueId, lst_CreatedLeads[0].OwnerId);
                System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, lst_CreatedLeads[0].Pending_Queue_Id__c);
            }
        }
    }

    @IsTest
    static void testGo2SleepPSTLeadsOutsideOfBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');
            ld.Declination_Reason__c = 'routable_reason';

            test.startTest();

            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;

            test.stopTest();

            List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
            System.assertEquals(1, lst_CreatedLeads.size());
            System.assertEquals(pstPendingLeadsQueueId, lst_CreatedLeads[0].OwnerId);
            System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Non_workable_leads_Q, lst_CreatedLeads[0].Pending_Queue_Id__c);
        }
    }

    @IsTest
    static void testFakeLeads() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id Hippo_Agency_Sales = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.FirstName = 'First';
            ld1.LastName = 'Last';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals('Cancelled', ld1_new.Status);
            System.assertEquals('Fake Contact Info', ld1_new.Disqualified_Reason__c);
            System.assertEquals(Non_workable_leads_Q, ld1_new.OwnerId);

            ld1_new.FirstName = 'Test';
            ld1_new.LastName = 'Test';
            update ld1_new;

            test.stopTest();

            Lead ld1_updated = [Select Id, Status, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals('Cancelled', ld1_updated.Status);
            System.assertEquals('Fake Contact Info', ld1_updated.Disqualified_Reason__c);
            System.assertEquals(Non_workable_leads_Q, ld1_updated.OwnerId);
        }
    }

    /*
    @IsTest
    static void testNonWorkableWithDetailsLeads() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

        Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

        ld1.FirstName = 'my Lead FirstName';
        ld1.LastName = 'my Lead LastName';
        ld1.Status = 'Closed';
        ld1.OwnerId = Non_workable_leads_Q;

        test.startTest();

        insert ld1;
        update ld1;

        test.stopTest();

        Lead ld1_new = [Select Id, Status, Disqualified_Reason__c, OwnerId From Lead Where Id =: ld1.Id Limit 1]?.get(0);
        System.assertEquals('New', ld1_new.Status);
    }
     */

    @IsTest
    static void testCloseLeadsIfInNonWorkableQ() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

        Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');
        ld1.OwnerId = Non_workable_leads_Q;

        test.startTest();

        insert ld1;
        Lead ld1_new = [Select Id, Status, Disqualified_Reason__c, OwnerId From Lead Where Id =: ld1.Id Limit 1]?.get(0);
        System.assertNotEquals('Closed', ld1_new.Status);

        update ld1_new;

        test.stopTest();

        Lead ld1_updated = [Select Id, Status, Disqualified_Reason__c, OwnerId From Lead Where Id =: ld1.Id Limit 1]?.get(0);
        System.assertEquals('New', ld1_updated.Status);
    }

    @IsTest
    static void testAssignLeads2NonWorkableQ() {

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'HomeLight');

            test.startTest();

            insert ld1;
            //update ld1;

            test.stopTest();

            Lead ld1_new = [Select Id, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(Non_workable_leads_Q, ld1_new.OwnerId);

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testAssignLeads2B2CPartnerSalesQ() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'HomeLight', true, true);

            test.startTest();

            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            insert ld1;

            test.stopTest();

            Lead ld1_new = [Select Id, OwnerId, Lead_Source__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals('HomeLight', ld1_new.Organization__r.Name);
            System.assertEquals(B2C_Partner_Sales_1, ld1_new.OwnerId);
            System.assertEquals('Partner Referral', ld1_new.Lead_Source__c);

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testAssignLeads2B2CBetterCoverQ() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_Better_Cover = Utils.getQueueId('B2C_Better_Cover');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Better Cover');

            test.startTest();

            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            insert ld1;

            test.stopTest();

            Lead ld1_new = [Select Id, OwnerId, Organization__r.Name From Lead Where Id =: ld1.Id Limit 1]?.get(0);
            System.assertEquals('Better Cover', ld1_new.Organization__r.Name);
            System.assertEquals(B2C_Better_Cover, ld1_new.OwnerId);

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testAssignLeads2B2CTheMoneySourceQ() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_The_Money_Source = Utils.getQueueId('B2C_The_Money_Source');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'TMS Insurance LLC');

            test.startTest();

            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            insert ld1;

            test.stopTest();

            Lead ld1_new = [Select Id, OwnerId, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals('TMS Insurance LLC', ld1_new.Organization__r.Name);
            System.assertEquals(B2C_The_Money_Source, ld1_new.OwnerId);

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testAssignLeads2B2CDirectSalesQ() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
        Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            //Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');
            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'MD');

            test.startTest();

            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            insert ld1;

            test.stopTest();

            Lead ld1_new = [Select Id, OwnerId, Organization__r.Name, Lead_Source__c From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            //System.assertEquals('Truebill', ld1_new.Organization__r.Name);
            //System.assertEquals(B2C_Direct_Sales, ld1_new.OwnerId);
            System.assertEquals(B2C_Direct_1, ld1_new.OwnerId);
            System.assertEquals('Hippo Direct Leads', ld1_new.Lead_Source__c);

            System.runAs(infra_bot) {

                ld1_new.Lead_Score__c = '4';

                update ld1_new;
            }

            Lead ld1_new_updated = [Select Id, OwnerId, Organization__r.Name, Lead_Source__c From Lead Where Id = :ld1_new.Id Limit 1];
            System.assertEquals(B2C_Direct_2, ld1_new_updated.OwnerId);
            System.assertEquals('Hippo Direct Leads', ld1_new.Lead_Source__c);

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    public static Account prepareAccount(Boolean create, String accountName) {

        Account testAccount = new Account(Name = accountName);
        testAccount.BillingStreet = Utils.getRandomString(5);
        testAccount.BillingCity = Utils.getRandomString(5);
        testAccount.BillingCountry  = 'United States';
        testAccount.Website = Utils.getRandomString(5);
        testAccount.NPN__c = '12345';
        testAccount.FEIN_number__c = '12345';

        if ( create ) insert testAccount;

        return testAccount;
    }

    public static Account prepareAccount(Boolean create, String accountName, Boolean workable_By_Hippo) {

        Account testAccount = new Account(Name = accountName);
        testAccount.BillingStreet = Utils.getRandomString(5);
        testAccount.BillingCity = Utils.getRandomString(5);
        testAccount.BillingCountry  = 'United States';
        testAccount.Website = Utils.getRandomString(5);
        testAccount.Workable_by_Hippo_picklist__c = workable_By_Hippo ? 'Yes' : 'No';
        testAccount.NPN__c = '12345';
        testAccount.FEIN_number__c = '12345';

        if ( create ) insert testAccount;

        return testAccount;
    }

    public static Account prepareAccount(Boolean create, String accountName, Boolean workable_By_Hippo, Boolean B2B2C) {

        Account testAccount = new Account(Name = accountName);
        testAccount.BillingStreet = Utils.getRandomString(5);
        testAccount.BillingCity = Utils.getRandomString(5);
        testAccount.BillingCountry  = 'United States';
        testAccount.Website = Utils.getRandomString(5);
        testAccount.Workable_by_Hippo_picklist__c = workable_By_Hippo ? 'Yes' : 'No';
        testAccount.B2B2C__c = B2B2C ? 'Yes' : 'No';
        testAccount.NPN__c = '12345';
        testAccount.FEIN_number__c = '12345';

        if ( create ) insert testAccount;

        return testAccount;
    }

    public static Lead prepareB2CLeadWithAccountName(Boolean create, String accountName) {

        Account acc = LeadTriggerTest.prepareAccount(true, accountName);

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        //ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Organization__c = acc.Id;
        ld.Account__c = acc.Id;

        if ( create ) insert ld;

        return ld;
    }

    public static Lead prepareB2CLeadWithAccountName(Boolean create, String accountName, Boolean workable_By_Hippo) {

        Account acc = LeadTriggerTest.prepareAccount(true, accountName, workable_By_Hippo);

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        //ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Organization__c = acc.Id;
        ld.Account__c = acc.Id;
        //ld.Workable_by_Hippo__c = workable_By_Hippo; // redundant as we are using the workable by hippo formula

        if ( create ) insert ld;

        return ld;
    }

    public static Lead prepareB2CLeadWithAccountName(Boolean create, String accountName, Boolean workable_By_Hippo, Boolean B2B2C) {

        Account acc = LeadTriggerTest.prepareAccount(true, accountName, workable_By_Hippo, B2B2C);

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        //ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Organization__c = acc.Id;
        ld.Account__c = acc.Id;
        //ld.Workable_by_Hippo__c = workable_By_Hippo; // redundant as we are using the workable by hippo formula

        if ( create ) insert ld;

        return ld;
    }

    public static Lead preparePennyMacLeadWithAccountName(Boolean create, String accountName) {

        Account acc = LeadTriggerTest.prepareAccount(true, accountName);

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('PennyMac Lead', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        //ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Organization__c = acc.Id;

        if ( create ) insert ld;

        return ld;
    }

    @IsTest
    static void testNonWorkableWithRiskReferral() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        //Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.Non_Cat_Risk_Class__c = 'referral';
            ld1.Cat_Risk_Class__c = 'referral';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
            Lead ld1_new = [Select Id, Status, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            //System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? Hippo_Agency_Sales_Q : Non_workable_leads_Q, ld1_new.OwnerId);
            System.assertEquals(Non_workable_leads_Q, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);

            test.stopTest();

            update ld1_new;
            Lead ld1_updated = [Select Id, Status, Disqualified_Reason__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            //System.assertEquals(ffUnderwritingDeclinationsLead2HASQueue ? Hippo_Agency_Sales_Q : Non_workable_leads_Q, ld1_updated.OwnerId);
            System.assertEquals(Non_workable_leads_Q, ld1_updated.OwnerId);
        }
    }

    // Test use cases where direct sales is the initial target but then based on empty email it is being moved to non workable and closed
    @IsTest
    static void testAssignLeads2B2CDirectSalesQAndMove2NonWorkableQ() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
        //Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            //Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');
            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            insert ld1;

            Lead ld1_new = [Select Id, Email, Status, OwnerId, Organization__r.Name, Lead_Source__c From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            //System.assertEquals('Truebill', ld1_new.Organization__r.Name);
            //System.assertEquals(B2C_Direct_Sales, ld1_new.OwnerId);
            System.assertEquals(B2C_Direct_1, ld1_new.OwnerId);
            System.assertEquals('New', ld1_new.Status);
            System.assertEquals('Hippo Direct Leads', ld1_new.Lead_Source__c);

            /* SFDC-1540 - DEPRECATED ?!
            test.startTest();

            ld1_new.Email = '';
            update ld1_new;

            test.stopTest();

            Lead ld1_updated = [Select Id, OwnerId, Status, Organization__r.Name From Lead Where Id = :ld1_new.Id Limit 1]?.get(0);
            System.assertEquals(Non_workable_leads_Q, ld1_updated.OwnerId);
            //System.assertNotEquals('Closed', ld1_updated.Status);
             */

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testAssignLeads2InsideSalesContractorsQ() {

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Inside_Sales_Contractors = Utils.getQueueId('Inside_Sales_Contractors');

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');

        test.startTest();

        ld1.Status = 'New';
        ld1.OwnerId = Non_workable_leads_Q;
        ld1.Email = 'test.sfdc@leads.com';
        ld1.Phone = '3011237845';
        ld1.MobilePhone = '2021237845';
        ld1.POD_Quote_ID__c = '';
        ld1.Lead_Score__c = '3';
        ld1.State = 'CA';

        insert ld1;

        test.stopTest();

        Lead ld1_new = [Select Id, OwnerId, Organization__r.Name From Lead Where Id =: ld1.Id Limit 1]?.get(0);
        System.assertEquals('Truebill', ld1_new.Organization__r.Name);

        if ( FeatureFlags.instance.ff_Use_Inside_Sales_Contractor_Queue )
            System.assertEquals(Inside_Sales_Contractors, ld1_new.OwnerId);
        else
            System.assertEquals(Non_workable_leads_Q, ld1_new.OwnerId);

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    }

    @IsTest
    static void testAssignLeads2TerritoryManager() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        User_Assignment__c ua = UnitTestHelper.prepareTerritoryManagerUserAssignment('AL;AK;FL;GA;KY;MS;NC;SC;TN;VA;WV');
        system.assertNotEquals(null, ua.Id);

        User infra_bot = [SELECT Id, Name, Profile.Id, Profile.Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld1 = UnitTestHelper.prepareLeadByRecordTypeName(false, 'Web Leads - Producers');
        ld1.State = 'AL';

        System.runAs(infra_bot) {

            test.startTest();

            insert ld1;

            test.stopTest();
        }

        Lead my_Lead = [SELECT Id, OwnerId FROM Lead WHERE Id =: ld1.Id Limit 1];
        system.assertNotEquals(null, my_Lead);
        system.assertEquals(UserInfo.getUserId(), my_Lead.OwnerId);
    }

    @IsTest
    static void testAssignLeadsBySpecificLeadSourceInsideOfBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Simplisafe', true, true);
            ld1.Status = 'New';
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            test.startTest();

            ld1.State = 'CA';
            ld1.UTM_Source__c = 'TEST UTM SOURCE';

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true; // test while ignoring business hours (will be handled in a different test)
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead my_Lead = [SELECT Id, OwnerId, Lead_Source__c FROM Lead WHERE Id = :ld1.Id Limit 1];
            system.assertNotEquals(null, my_Lead);
            system.assertEquals(B2C_Partner_Sales_1, my_Lead.OwnerId);
            System.assertEquals('Partner Referral', my_Lead.Lead_Source__c);
        }
    }

    @IsTest
    static void testAssignLeadsBySpecificLeadSourceOutsideOfBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Simplisafe', true, true);
            ld1.Status = 'New';
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            test.startTest();

            ld1.State = 'CA';
            ld1.UTM_Source__c = 'TEST UTM SOURCE';

            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
            System.assertNotEquals(null, ld1.Organization__c);
            insert ld1;
            LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;

            test.stopTest();

            Lead my_Lead = [SELECT Id, OwnerId, Lead_Source__c, Pending_Queue_Id__c FROM Lead WHERE Id = :ld1.Id Limit 1];
            system.assertNotEquals(null, my_Lead);
            system.assertEquals(B2C_Partner_Sales_1, my_Lead.Pending_Queue_Id__c);
            System.assertEquals('Partner Referral', my_Lead.Lead_Source__c);
            system.assertEquals(pstPendingLeadsQueueId, my_Lead.OwnerId);
        }
    }

    @IsTest
    static void testAssignLeads2HighUrgencyQueueIgnoreBusinessHours() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id High_Urgency_Queue = Utils.getQueueId('High_Urgency_Queue');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'SFDC-451-PAID');
            ld1.Status = 'New';
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            test.startTest();

            ld1.State = 'CA';
            ld1.UTM_Source__c = 'TEST UTM SOURCE';

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true; // test while ignoring business hours
            insert ld1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead my_Lead = [SELECT Id, OwnerId FROM Lead WHERE Id = :ld1.Id Limit 1];
            system.assertNotEquals(null, my_Lead);
            system.assertEquals(High_Urgency_Queue, my_Lead.OwnerId);
        }
    }

    @IsTest
    static void testDeduplicationsRule1Positive() { // SFDC-408

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffDDupCheckByExistingPolicy = FeatureFlags.instance.ff_DDup_Check_By_Existing_Policy;
        System.debug('ffDDupCheckByExistingPolicy: ' + ffDDupCheckByExistingPolicy);

        if ( ffDDupCheckByExistingPolicy ) {
            
            Id Duplicate_Leads_Q = Utils.getQueueId('Already_Purchased');

            User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

            System.runAs(infra_bot) {

                Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
                system.assertEquals(null, ld.Id);

                Account acc = UnitTestHelper.prepareAccountFromLead(ld);
                system.assertNotEquals(null, acc.Id);

                InsurancePolicy ins = UnitTestHelper.prepareInsurancePolicyFromLead(ld, acc);
                system.assertNotEquals(null, ins.Id);

                test.startTest();

                insert ld;

                test.stopTest();

                List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
                System.assertEquals(1, lst_CreatedLeads.size());
                system.assertEquals(Duplicate_Leads_Q, lst_CreatedLeads[0].OwnerId);
            }
        }
    }

    @IsTest
    static void testDeduplicationsRule1InternalReferral() { // SFDC-1464

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id 	Duplicate_Leads_Q = Utils.getQueueId('Already_Purchased');

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
        system.assertEquals(null, ld.Id);

        Account acc = UnitTestHelper.prepareAccountFromLead(ld);
        system.assertNotEquals(null, acc.Id);

        InsurancePolicy ins = UnitTestHelper.prepareInsurancePolicyFromLead(ld, acc);
        system.assertNotEquals(null, ins.Id);

        test.startTest();

        ld.Lead_Source__c = 'Internal Referral Cold Transfer';
        insert ld;

        test.stopTest();

        List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
        System.assertEquals(1, lst_CreatedLeads.size());
        system.assertNotEquals(Duplicate_Leads_Q, lst_CreatedLeads[0].OwnerId);
    }

    @IsTest
    static void testDeduplicationsRule1Negative() { // SFDC-408

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id 	Duplicate_Leads_Q = Utils.getQueueId('Already_Purchased');

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
        system.assertEquals(null, ld.Id);

        Account acc = UnitTestHelper.prepareAccountFromLead(ld);
        system.assertNotEquals(null, acc.Id);

        InsurancePolicy ins = UnitTestHelper.prepareInsurancePolicyFromLead(ld, acc);
        system.assertNotEquals(null, ins.Id);

        test.startTest();

        ld.FirstName = 'Modified';
        ld.LastName = 'Modified';
        ld.Phone = 'Modified';
        ld.MobilePhone = 'Modified';
        ld.Email = 'Modified@Email.COM';
        insert ld;

        test.stopTest();

        List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead];
        System.assertEquals(1, lst_CreatedLeads.size());
        system.assertNotEquals(Duplicate_Leads_Q, lst_CreatedLeads[0].OwnerId);
    }

    @IsTest
    static void testDeduplicationsRule2_Scenario1() { // SFDC-561, 1st use case (New lead to Partner Sales vs Similar existing Lead assigned to Direct Sales agent)

        UnitTestHelper.prepareDevEnvCustomSettings();

        // preparing the base system state with a b2c direct sales lead assigned to an agent

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'MD');

        System.runAs(infra_bot) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            //Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');
            ld1.FirstName = 'Lead_First_Name';
            ld1.LastName = 'Lead_Last_Name';
            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';
            insert ld1;
        }

        Lead ld1_new = [Select Id, OwnerId, Organization__r.Name, Lead_Source__c From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.debug('ld1_new.Id: ' + ld1_new.Id);
        //System.assertEquals('Truebill', ld1_new.Organization__r.Name);
        //System.assertEquals(B2C_Direct_Sales, ld1_new.OwnerId);
        System.assertEquals(B2C_Direct_1, ld1_new.OwnerId);
        System.assertEquals('Hippo Direct Leads', ld1_new.Lead_Source__c);

        // Simulate OmniChannel routing to an available agent (using the current running user. no need to get a real user id from b2c direct sales queue for this test)

        ld1.OwnerId = UserInfo.getUserId();
        ld1.Status = 'Working';
        update ld1;
        ld1_new = [Select Id, OwnerId, Organization__r.Name, Status, Lead_Source__c From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals(UserInfo.getUserId(), ld1_new.OwnerId);
        System.assertEquals('Working', ld1_new.Status);
        System.assertEquals('Hippo Direct Leads', ld1_new.Lead_Source__c);

        // starting the actual test - preparing a similar lead to ld1 but that should go to partner sales queue

        System.runAs(infra_bot) {

            test.startTest();

            //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
            Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
            Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

            Lead ld2 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'HomeLight', true, true);
            ld2.FirstName = 'Lead_First_Name';
            ld2.LastName = 'Lead_Last_Name';
            ld2.Status = 'New';
            //ld2.OwnerId = Non_workable_leads_Q;
            ld2.State = 'MD';
            ld2.Email = 'test.sfdc@leads.com';
            ld2.Phone = '3011237845';
            ld2.MobilePhone = '2021237845';
            ld2.POD_Quote_ID__c = '';
            ld2.Lead_Score__c = '6';

            insert ld2;

            test.stopTest();

            Lead ld2_new = [Select Id, OwnerId, Organization__r.Name, Dup_Parent__c From Lead Where Id = :ld2.Id Limit 1]?.get(0);
            System.debug('ld2_new.Id: ' + ld2_new.Id);
            System.assertEquals('HomeLight', ld2_new.Organization__r.Name);
            System.assertNotEquals(B2C_Partner_Sales_1, ld2_new.OwnerId);
            System.assertEquals(Non_workable_leads_Q, ld2_new.OwnerId);
            System.assertEquals(ld1_new.Id, ld2_new.Dup_Parent__c);

            List<Task> tsks = [SELECT Id, WhoId, WhatId, Original_Lead__c FROM Task];
            System.debug('tsks: ' + tsks);

            List<Task> tsk = [SELECT Id, WhoId, WhatId, Original_Lead__c FROM Task WHERE WhoId = :ld2_new.Id AND Original_Lead__c = :ld1_new.Id];
            System.assertEquals(1, tsk.size());

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testDeduplicationsRule2_Scenario2() { // SFDC-561, 2nd use case (New lead to Direct Sales vs Similar existing Lead assigned to Partner Sales agent)

        UnitTestHelper.prepareDevEnvCustomSettings();

        // preparing the base system state with a b2c partner sales lead assigned to an agent

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Comcast', true, true);

        System.runAs(infra_bot) {

            ld1.FirstName = 'Lead_First_Name';
            ld1.LastName = 'Lead_Last_Name';
            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';
            insert ld1;
        }

        Lead ld1_new = [Select Id, OwnerId, Lead_Source__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals('Comcast', ld1_new.Organization__r.Name);
        System.assertEquals(B2C_Partner_Sales_1, ld1_new.OwnerId);
        System.assertEquals('Partner Referral', ld1_new.Lead_Source__c);

        // Simulate OmniChannel routing to an available agent (using the current running user. no need to get a real user id from b2c partner sales queue for this test)

        ld1.OwnerId = UserInfo.getUserId();
        ld1.Status = 'Working';
        update ld1;
        ld1_new = [Select Id, OwnerId, Organization__r.Name, Status From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals(UserInfo.getUserId(), ld1_new.OwnerId);
        System.assertEquals('Working', ld1_new.Status);

        //Lead ld2 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');
        Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

        System.runAs(infra_bot) {

            // starting the actual test - preparing a similar lead to ld1 but that should go to direct sales queue

            test.startTest();

            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');

            ld2.FirstName = 'Lead_First_Name';
            ld2.LastName = 'Lead_Last_Name';
            ld2.Status = 'New';
            //ld2.OwnerId = Non_workable_leads_Q;
            ld2.State = 'CA';
            ld2.Email = 'test.sfdc@leads.com';
            ld2.Phone = '3011237845';
            ld2.MobilePhone = '2021237845';
            ld2.POD_Quote_ID__c = '';
            ld2.Lead_Score__c = '6';
            insert ld2;

            test.stopTest();
        }

        //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');

        Lead ld2_new = [Select Id, OwnerId, Organization__r.Name, Dup_Parent__c, Lead_Source__c From Lead Where Id = :ld2.Id Limit 1]?.get(0);
        //System.assertEquals('Truebill', ld2_new.Organization__r.Name);
        System.assertNotEquals(B2C_Direct_1, ld2_new.OwnerId);
        System.assertEquals('Hippo Direct Leads', ld2_new.Lead_Source__c);
        System.assertEquals(Non_workable_leads_Q, ld2_new.OwnerId);
        System.assertEquals(ld1_new.Id, ld2_new.Dup_Parent__c);

        List<Task> tsk = [SELECT Id, WhatId, Original_Lead__c, OwnerId FROM Task WHERE WhoId = :ld2_new.Id AND Original_Lead__c = :ld1_new.Id];
        System.assertEquals(1, tsk.size());
        System.assertEquals(ld1_new.OwnerId, tsk[0].OwnerId);

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    }

    @IsTest
    static void testDeduplicationsRule2_Scenario3() { // SFDC-1464, Internal Referral)

        UnitTestHelper.prepareDevEnvCustomSettings();

        // preparing the base system state with a b2c partner sales lead assigned to an agent

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Comcast', true, true);

        System.runAs(infra_bot) {

            ld1.FirstName = 'Lead_First_Name';
            ld1.LastName = 'Lead_Last_Name';
            ld1.Status = 'New';
            //ld1.OwnerId = Non_workable_leads_Q;
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';
            insert ld1;
        }

        Lead ld1_new = [Select Id, OwnerId, Lead_Source__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals('Comcast', ld1_new.Organization__r.Name);
        System.assertEquals(B2C_Partner_Sales_1, ld1_new.OwnerId);
        System.assertEquals('Partner Referral', ld1_new.Lead_Source__c);

        // Simulate OmniChannel routing to an available agent (using the current running user. no need to get a real user id from b2c partner sales queue for this test)

        ld1.OwnerId = UserInfo.getUserId();
        ld1.Status = 'Working';
        update ld1;
        ld1_new = [Select Id, OwnerId, Organization__r.Name, Status From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals(UserInfo.getUserId(), ld1_new.OwnerId);
        System.assertEquals('Working', ld1_new.Status);

        // starting the actual test - preparing a similar lead to ld1 but that should go to direct sales queue


        //Lead ld2 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');
        Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'Truebill');

        System.runAs(infra_bot) {

            test.startTest();

            ld2.FirstName = 'Lead_First_Name';
            ld2.LastName = 'Lead_Last_Name';
            ld2.Status = 'New';
            ld2.State = 'CA';
            //ld2.OwnerId = Non_workable_leads_Q;
            ld2.Email = 'test.sfdc@leads.com';
            ld2.Phone = '3011237845';
            ld2.MobilePhone = '2021237845';
            ld2.POD_Quote_ID__c = '';
            ld2.Lead_Score__c = '6';
            ld2.Lead_Source__c = 'Internal Referral Cold Transfer';
            insert ld2;

            test.stopTest();
        }

        //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
        Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

        Lead ld2_new = [Select Id, OwnerId, Organization__r.Name, Dup_Parent__c, Lead_Source__c From Lead Where Id = :ld2.Id Limit 1]?.get(0);
        //System.assertEquals('Truebill', ld2_new.Organization__r.Name);
        System.assertEquals(B2C_Direct_1, ld2_new.OwnerId);
        System.assertNotEquals('Hippo Direct Leads', ld2_new.Lead_Source__c);
        System.assertEquals('Internal Referral Cold Transfer', ld2_new.Lead_Source__c);
        System.assertNotEquals(Non_workable_leads_Q, ld2_new.OwnerId);
        System.assertEquals(null, ld2_new.Dup_Parent__c);

        List<Task> tsk = [SELECT Id, WhatId, Original_Lead__c, OwnerId FROM Task WHERE WhoId = :ld2_new.Id AND Original_Lead__c = :ld1_new.Id];
        System.assertEquals(0, tsk.size());

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    }

    @IsTest
    static void testLeadOwnersThatCannotGetChanged() { // SFDC-714

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Techsee_Queue = Utils.getQueueId('Techsee_Queue');
        Id Lead_Prebind_UW_Referrals = Utils.getQueueId('Prebind_UW_Referrals');

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');
        ld1.Status = 'New';
        ld1.OwnerId = Techsee_Queue;
        ld1.Email = 'test.sfdc1@leads.com';
        ld1.Phone = '30112378451';
        ld1.MobilePhone = '20212378452';
        ld1.POD_Quote_ID__c = '';
        ld1.Lead_Score__c = '6';

        Lead ld2 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Truebill');
        ld2.Status = 'New';
        ld2.OwnerId = Lead_Prebind_UW_Referrals;
        ld2.Email = 'test.sfdc2@leads.com';
        ld2.Phone = '30112378453';
        ld2.MobilePhone = '20212378454';
        ld2.POD_Quote_ID__c = '';
        ld2.Lead_Score__c = '6';

        test.startTest();

        insert ld1;
        insert ld2;

        test.stopTest();

        Lead ld1_new = [Select Id, OwnerId, Organization__r.Name From Lead Where Id =: ld1.Id Limit 1]?.get(0);
        System.assertEquals('Truebill', ld1_new.Organization__r.Name);
        System.assertEquals(Techsee_Queue, ld1_new.OwnerId);

        Lead ld2_new = [Select Id, OwnerId, Organization__r.Name From Lead Where Id =: ld2.Id Limit 1]?.get(0);
        System.assertEquals('Truebill', ld2_new.Organization__r.Name);
        System.assertEquals(Lead_Prebind_UW_Referrals, ld2_new.OwnerId);

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    }

    @IsTest
    static void testFacebookLead() { // SFDC-883

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Facebook_Leads = Utils.getQueueId('Facebook_Leads');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'leadgen-internal-org');
            ld.FirstName = 'Asdf';
            ld.LastName = 'Asdf';
            ld.Status = 'New';
            ld.Email = 'ddd@gg.com';
            ld.Phone = '3563546546';
            ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Palo Alto';
            ld.State = 'ca';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'FB_Social_Call';

            test.startTest();

            insert ld;

            test.stopTest();

            Lead ld_new = [Select Id, OwnerId, Lead_Source__c, Organization__r.Name From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals('leadgen-internal-org', ld_new.Organization__r.Name);
            System.assertNotEquals(Non_workable_leads_Q, ld_new.OwnerId);
            System.assertEquals(Facebook_Leads, ld_new.OwnerId);
            System.assertEquals('Facebook', ld_new.Lead_Source__c);
        }
    }

    @IsTest
    static void testDeadLead_Scenario1() { // SFDC-883

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id SMS_Reactivation = Utils.getQueueId('SMS_Reactivation');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
            ld.FirstName = 'Asdf';
            ld.LastName = 'Asdf';
            ld.Status = 'New';
            ld.Email = 'ddd@gg.com';
            ld.Phone = '3563546546';
            ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Palo Alto';
            ld.State = 'ca';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'SMS_Reactivation';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead ld_new = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(null, ld_new.Organization__c);
            System.assertNotEquals(Non_workable_leads_Q, ld_new.OwnerId);
            System.assertEquals(SMS_Reactivation, ld_new.OwnerId);
        }
    }

    @IsTest
    static void testDeadLead_Scenario2() { // SFDC-883

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id SMS_Reactivation = Utils.getQueueId('SMS_Reactivation');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
            ld.FirstName = 'Asdf';
            ld.LastName = 'Asdf';
            ld.Status = 'Cancelled';
            ld.Disqualified_Reason__c = 'More Expensive';
            ld.Email = 'ddd@gg.com';
            ld.Phone = '3563546546';
            ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Palo Alto';
            ld.State = 'ca';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'SMS_Reactivation';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead ld_new = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(null, ld_new.Organization__c);
            System.assertNotEquals(Non_workable_leads_Q, ld_new.OwnerId);
            System.assertEquals(SMS_Reactivation, ld_new.OwnerId);
            System.assertEquals('New', ld_new.Status);
            System.assertEquals(null, ld_new.Disqualified_Reason__c);
        }
    }

    @IsTest
    static void testDeadLead_Scenario3() { // SFDC-883

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id SMS_Reactivation = Utils.getQueueId('SMS_Reactivation');
        Id Hippo_Agency_Sales = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
            ld.FirstName = 'First';
            ld.LastName = 'Last';
            //ld.Status = 'Cancelled'; will be set to this status on lead creation because of first name and last name
            ld.Disqualified_Reason__c = 'More Expensive';
            ld.Email = 'ddd@gg.com';
            ld.Phone = '3563546546';
            ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Palo Alto';
            ld.State = 'ca';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            Lead ld_new1 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals('Cancelled', ld_new1.Status);
            System.assertEquals(Non_workable_leads_Q, ld_new1.OwnerId);
            System.assertNotEquals(null, ld_new1.Disqualified_Reason__c);

            test.startTest();

            ld.FirstName = 'Asdf';
            ld.LastName = 'Asdf';
            ld.UTM_Source__c = 'SMS_Reactivation';
            update ld;

            test.stopTest();

            Lead ld_new2 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(null, ld_new2.Organization__c);
            System.assertNotEquals(Hippo_Agency_Sales, ld_new2.OwnerId);
            System.assertEquals(SMS_Reactivation, ld_new2.OwnerId);
            System.assertEquals('New', ld_new2.Status);
            System.assertEquals(null, ld_new2.Disqualified_Reason__c);
        }
    }

    @IsTest
    static void testDeadLead_Scenario4() { // SFDC-883

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id SMS_Reactivation = Utils.getQueueId('SMS_Reactivation');
        //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
        Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
        //Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Everquote');

        System.runAs(infra_bot) {

            ld.FirstName = 'Angela';
            ld.LastName = 'Nino';
            ld.Status = 'New';
            ld.Email = 'ddd@gg.com';
            ld.Phone = '3563546546';
            ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Palo Alto';
            ld.State = 'ca';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '4';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
        }

        Lead ld_new1 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, UTM_Source__c, Lead_Source__c From Lead Where Id =: ld.Id Limit 1];
        System.assertEquals('New', ld_new1.Status);
        System.assertEquals(B2C_Direct_2, ld_new1.OwnerId);
        System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
        System.assertEquals(null, ld_new1.UTM_Source__c);

        ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'Working';
        ld.Work_Accepted_Time__c = System.now();
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
        update ld;
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

        Lead ld_new2 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, UTM_Source__c From Lead Where Id =: ld.Id Limit 1];
        System.assertEquals('Working', ld_new2.Status);
        System.assertEquals(UserInfo.getUserId(), ld_new2.OwnerId);
        System.assertEquals(null, ld_new2.UTM_Source__c);

        System.runAs(infra_bot) {

            ld.POD_Quote_ID__c = '7110107';
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            update ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
        }

        Lead ld_new3 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, UTM_Source__c From Lead Where Id =: ld.Id Limit 1];
        System.assertEquals('Working', ld_new3.Status);
        System.assertEquals(UserInfo.getUserId(), ld_new3.OwnerId);
        System.assertEquals(null, ld_new3.UTM_Source__c);

        ld.Status = 'Cancelled';
        ld.Disqualified_Reason__c = 'Unable to contact';
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
        update ld;
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

        Lead ld_new4 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, UTM_Source__c From Lead Where Id =: ld.Id Limit 1];
        System.assertEquals('Cancelled', ld_new4.Status);
        System.assertEquals(UserInfo.getUserId(), ld_new4.OwnerId);
        System.assertEquals(null, ld_new4.UTM_Source__c);
        System.assertNotEquals(null, ld_new4.Disqualified_Reason__c);

        test.startTest();

        System.runAs(infra_bot) {

            ld.UTM_Source__c = 'SMS_Reactivation';
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            update ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
        }

        test.stopTest();

        Lead ld_new5 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c From Lead Where Id =: ld.Id Limit 1];
        //System.assertNotEquals(null, ld_new5.Organization__c);
        System.assertEquals(null, ld_new5.Organization__c);
        System.assertNotEquals(Non_workable_leads_Q, ld_new5.OwnerId);
        //System.assertEquals(SMS_Reactivation, ld_new5.OwnerId); /*1492*/
        System.assertEquals(UserInfo.getUserId(), ld_new5.OwnerId); /*1492*/
        System.assertEquals('New', ld_new5.Status);
        System.assertEquals(null, ld_new5.Disqualified_Reason__c);
    }

    @IsTest
    static void testPennymacLead_Scenario1() { // SFDC-1022

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffPennyMacRoute2NonWorkableQueue = FeatureFlags.instance.ff_PennyMac_Leads_to_Non_Workable_Queue;
        System.debug('ffPennyMacRoute2NonWorkableQueue: ' + ffPennyMacRoute2NonWorkableQueue);

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2'); // SFDC-1752
        //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'PennyMac');
            ld.FirstName = 'Asdf';
            ld.LastName = 'Asdf';
            ld.Status = 'New';
            ld.Email = 'ddd@gg.com';
            ld.Phone = '3563546546';
            ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Palo Alto';
            ld.State = 'ca';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'sfmc pennymac SR';

            test.startTest();

            insert ld;

            test.stopTest();

            RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
            Lead ld_new = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new.Organization__c);
            //System.assertNotEquals(Hippo_Agency_Sales_Q, ld_new.OwnerId);
            System.assertEquals(ffPennyMacRoute2NonWorkableQueue ? Non_workable_leads_Q : PMIS_Hippo_Leads_2, ld_new.OwnerId);
            System.assertEquals(pmRecordType.getRecordTypeId(), ld_new.RecordTypeId);
        }
    }

    @IsTest
    static void testPennymacLead_Scenario2() { // SFDC-1022

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');

        Boolean ffPennyMacRoute2NonWorkableQueue = FeatureFlags.instance.ff_PennyMac_Leads_to_Non_Workable_Queue;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id PMIS_Hippo_Leads_1 = Utils.getQueueId('PMIS_Hippo_Leads_1'); // SFDC-1752
        //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752
        //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');

            ld.Status = 'New';
            //ld.OwnerId = Non_workable_leads_Q;
            ld.Email = 'test.sfdc@leads.com';
            ld.Phone = '3011237845';
            ld.MobilePhone = '2021237845';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName, Lead_Source__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals(B2C_Direct_1, ld_new1.OwnerId);
            System.assertEquals('Hippo Direct Leads', ld_new1.Lead_Source__c);
            System.assertNotEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            test.startTest();

            ld.UTM_Source__c = 'sfmc pennymac SR';
            ld.Lead_Source__c = '';
            update ld;

            test.stopTest();

            Lead ld_new2 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(ffPennyMacRoute2NonWorkableQueue ? Non_workable_leads_Q : PMIS_Hippo_Leads_1, ld_new2.OwnerId);
            System.assertEquals('New', ld_new2.Status);
            System.assertEquals(pmRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
        }
    }

    @IsTest
    static void testPennymacLead_Scenario3() { // SFDC-1022

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');

        Boolean ffPennyMacRoute2NonWorkableQueue = FeatureFlags.instance.ff_PennyMac_Leads_to_Non_Workable_Queue;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');
        Id PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2'); // SFDC-1752
        //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'PennyMac');

        System.runAs(infra_bot) {

            ld.Status = 'New';
            //ld.OwnerId = Non_workable_leads_Q;
            ld.POD_Quote_ID__c = '';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'pennymacinsurance';

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals(JV_Non_workable_leads_Q/*Non_workable_leads_Q*/, ld_new1.OwnerId);
            System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            test.startTest();

            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            update ld;

            test.stopTest();
        }

        Lead ld_new2 = [Select Id, Status, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id =: ld.Id Limit 1];
        System.assertEquals(ffPennyMacRoute2NonWorkableQueue ? Non_workable_leads_Q : PMIS_Hippo_Leads_2, ld_new2.OwnerId);
        System.assertEquals('New', ld_new2.Status);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
    }

    @IsTest
    static void testPennymacLead_Scenario4() { // SFDC-1113

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
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(PMIS_Hippo_Leads_2, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }

    @IsTest
    static void testPennymacLead_Scenario5() { // SFDC-1113

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            //ld.OwnerId = Non_workable_leads_Q;
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            //ld.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(JV_Non_workable_leads_Q, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }

    @IsTest
    static void testPennymacLead_Scenario6() { // SFDC-1113

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');

        Id JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');
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
            //ld.Phone = '4026404310';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            //ld.UTM_Source__c = 'pennymacinsurance';

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals(JV_Non_workable_leads_Q, ld_new1.OwnerId);
            System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            ld.Phone = '4026404310';
            update ld;
        }

        test.stopTest();

        Lead ld_new2 = [Select Id, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new2.Organization__r.Name);
        System.assertEquals(PMIS_Hippo_Leads_2, ld_new2.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
    }

    @IsTest
    static void testPennymacLead_Scenario7() { // SFDC-1443

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffPennyMacRoute2NonWorkableQueue = FeatureFlags.instance.ff_PennyMac_Leads_to_Non_Workable_Queue;
        System.debug('ffPennyMacRoute2NonWorkableQueue: ' + ffPennyMacRoute2NonWorkableQueue);

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2'); // SFDC-1752
        //Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads'); // SFDC-1752
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'PennyMac');
            ld.FirstName = 'Asdf';
            ld.LastName = 'Asdf';
            ld.Status = 'New';
            ld.Email = 'ddd@gg.com';
            ld.Phone = '3563546546';
            ld.MobilePhone = '2021237845';
            ld.Street = '435 Homer Ave';
            ld.City = 'Palo Alto';
            ld.State = 'ca';
            ld.PostalCode = '94301';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'referral';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'sfmc pennymac SR';

            test.startTest();

            insert ld;

            test.stopTest();

            RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
            Lead ld_new = [Select Id, Lead_Source__c, Status, Disqualified_Reason__c, OwnerId, Organization__c, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new.Organization__c);
            //System.assertNotEquals(Hippo_Agency_Sales_Q, ld_new.OwnerId);
            System.assertEquals(ffPennyMacRoute2NonWorkableQueue ? Non_workable_leads_Q : PMIS_Hippo_Leads_2, ld_new.OwnerId);
            System.assertEquals(pmRecordType.getRecordTypeId(), ld_new.RecordTypeId);
            System.assertEquals('UW Referral', ld_new.Lead_Source__c);
        }
    }

    @IsTest
    static void testOutsideSalesLeads() { // SFDC-1272

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');
        Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
        //Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

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

            test.startTest();

            ld_new1.Lead_Score__c = '1';
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            update ld_new1;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead ld_new2 = [Select Id, OwnerId, Organization__c, Lead_Score__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(Outside_Sales_Queue, ld_new2.OwnerId);
        }
    }

    @IsTest
    static void testCarInsuranceNetLeads() { // SFDC-1259

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'CarInsurance.net');
            ld.Email = 'test.sfdc@leads.com';
            ld.Phone = '3011237845';
            ld.MobilePhone = '2021237845';
            ld.POD_Quote_ID__c = '';
            ld.Lead_Score__c = '6';

            test.startTest();

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert ld;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.stopTest();

            Lead ld_new1 = [Select Id, OwnerId, Organization__r.Name, Lead_Score__c From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals('CarInsurance.net', ld_new1.Organization__r.Name);
            System.assertEquals(Non_workable_leads_Q, ld_new1.OwnerId);
        }
    }

}