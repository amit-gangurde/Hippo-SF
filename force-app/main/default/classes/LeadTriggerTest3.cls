@IsTest
public class LeadTriggerTest3 {

    @testsetup
    public static void testSetup() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));
    }

    @IsTest
    static void testWorkableByHippo_Scenario1() { // SFDC-1540

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Workable_by_Hippo_1 = Utils.getQueueId('Workable_by_Hippo_1');
        Id Workable_by_Hippo_2 = Utils.getQueueId('Workable_by_Hippo_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        String HippoAnalytics_Org_Name = Utils.getHippoSettings('Hippo Analytics Org');
        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, HippoAnalytics_Org_Name, true);

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

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals(HippoAnalytics_Org_Name, ld_new1.Organization__r.Name);
            System.assertNotEquals(null, ld_new1.Account__c);
            System.assertNotEquals(null, ld_new1.Account__r.Name);
            System.assertEquals(HippoAnalytics_Org_Name, ld_new1.Organization__r.Name);
            System.assertEquals(Workable_by_Hippo_1, ld_new1.OwnerId);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            test.startTest();

            ld.Lead_Score__c = '4';
            update ld;

            test.stopTest();

            Lead ld_new2 = [Select Id, OwnerId, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new2.Organization__c);
            System.assertNotEquals(null, ld_new2.Organization__r.Name);
            System.assertEquals(HippoAnalytics_Org_Name, ld_new2.Organization__r.Name);
            System.assertNotEquals(null, ld_new2.Account__c);
            System.assertNotEquals(null, ld_new2.Account__r.Name);
            System.assertEquals(HippoAnalytics_Org_Name, ld_new2.Organization__r.Name);
            System.assertEquals(Workable_by_Hippo_2, ld_new2.OwnerId);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
        }
    }

    @IsTest
    static void testHCRClickedOnLinkLead() { // SFDC-1540

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'hcr organization', true);

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
            ld.Last_Page_Visited__c = 'Clicked Link';

            insert ld;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__c);
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals('hcr organization', ld_new1.Organization__r.Name);
        System.assertNotEquals(null, ld_new1.Account__c);
        System.assertNotEquals(null, ld_new1.Account__r.Name);
        System.assertEquals('hcr organization', ld_new1.Organization__r.Name);
        System.assertEquals(HCR_Clicked_on_Link_Q, ld_new1.OwnerId);
        System.assertEquals('HCR Clicked on Link', ld_new1.Lead_Source__c);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }

    @IsTest
    static void testHCRReachedPrelimQuoteLead() { // SFDC-1540

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HCR_Reached_Prelim_Quote_Q = Utils.getQueueId('HCR_Reached_Prelim_Quote');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'hcr organization', true);

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
            ld.Last_Page_Visited__c = 'Reached Prelim Quote';

            insert ld;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__c);
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals('hcr organization', ld_new1.Organization__r.Name);
        System.assertNotEquals(null, ld_new1.Account__c);
        System.assertNotEquals(null, ld_new1.Account__r.Name);
        System.assertEquals('hcr organization', ld_new1.Organization__r.Name);
        System.assertEquals(HCR_Reached_Prelim_Quote_Q, ld_new1.OwnerId);
        System.assertEquals('HCR Reached Prelim Quote', ld_new1.Lead_Source__c);
        System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
    }

    @IsTest
    static void testWorkableByHippo_Scenario2() { // SFDC-1679

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Workable_by_Hippo_1 = Utils.getQueueId('Workable_by_Hippo_1');
        Id Workable_by_Hippo_2 = Utils.getQueueId('Workable_by_Hippo_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Quote Wizard', true);

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

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals('Quote Wizard', ld_new1.Organization__r.Name);
            System.assertNotEquals(null, ld_new1.Account__c);
            System.assertNotEquals(null, ld_new1.Account__r.Name);
            System.assertEquals('Quote Wizard', ld_new1.Organization__r.Name);
            System.assertEquals(Workable_by_Hippo_1, ld_new1.OwnerId);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            test.startTest();

            ld.Lead_Score__c = '4';
            update ld;

            test.stopTest();

            Lead ld_new2 = [Select Id, OwnerId, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new2.Organization__c);
            System.assertNotEquals(null, ld_new2.Organization__r.Name);
            System.assertEquals('Quote Wizard', ld_new2.Organization__r.Name);
            System.assertNotEquals(null, ld_new2.Account__c);
            System.assertNotEquals(null, ld_new2.Account__r.Name);
            System.assertEquals('Quote Wizard', ld_new2.Organization__r.Name);
            System.assertEquals(Workable_by_Hippo_2, ld_new2.OwnerId);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new2.RecordTypeId);
        }
    }

    @IsTest
    static void testNonWorkable1() { // Reported in PROD, 5/19

        LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Simple Nexus', true, true);

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.Email = 'test.sfdc@leads.com';
            ld.Phone = '3011237845';
            ld.MobilePhone = '2021237845';
            ld.POD_Quote_ID__c = '';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Score__c = 0;
            ld.UTM_Source__c = 'simplenexusNL';

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Pending_Queue_Id__c, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals('Simple Nexus', ld_new1.Organization__r.Name);
            System.assertNotEquals(null, ld_new1.Account__c);
            System.assertNotEquals(null, ld_new1.Account__r.Name);
            System.assertEquals('Simple Nexus', ld_new1.Account__r.Name);
            System.assertEquals(pstPendingLeadsQueueId, ld_new1.OwnerId);
            System.assertEquals(Non_workable_leads_Q, ld_new1.Pending_Queue_Id__c);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            ld.Lead_Score__c = '7';

            update ld;

            Lead ld_updated = [Select Id, OwnerId, Pending_Queue_Id__c, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(pstPendingLeadsQueueId, ld_updated.OwnerId);
            System.assertEquals(B2C_Partner_Sales_1, ld_updated.Pending_Queue_Id__c);
        }

        test.stopTest();

        LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;
    }

    /*
    @IsTest
    static void testNonWorkable2() { // Reported in PROD, 5/19

        //LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true; // TEST AS ALL DAY IS WORKABLE - THIS SIMULATES THAT THE LEADS STAYS ON INFRA BOT ?!?!

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Lennar Insurance_direct', false, true);

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.Email = 'vladsonnik@yahoo.com';
            ld.Phone = '9168493002';
            //ld.MobilePhone = '2021237845';
            ld.POD_Quote_ID__c = '';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Cat_Risk_Score__c = 0;
            ld.Non_Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Score__c = 0;
            //ld.UTM_Source__c = 'simplenexusNL';

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Pending_Queue_Id__c, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.debug('ld_new1.Pending_Queue_Id__c: ' + ld_new1.Pending_Queue_Id__c);
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals('Lennar Insurance_direct', ld_new1.Organization__r.Name);
            System.assertNotEquals(null, ld_new1.Account__c);
            System.assertNotEquals(null, ld_new1.Account__r.Name);
            System.assertEquals('Lennar Insurance_direct', ld_new1.Account__r.Name);
            System.assertEquals(pstPendingLeadsQueueId, ld_new1.OwnerId);
            System.assertEquals(Non_workable_leads_Q, ld_new1.Pending_Queue_Id__c);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            ld.Lead_Score__c = '10';

            update ld;

            Lead ld_updated = [Select Id, OwnerId, Pending_Queue_Id__c, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(pstPendingLeadsQueueId, ld_updated.OwnerId);
            System.assertEquals(Non_workable_leads_Q, ld_updated.Pending_Queue_Id__c);
            //System.assertEquals(B2C_Partner_Sales_1, ld_updated.Pending_Queue_Id__c); NOT B2C_Partner_Sales_1 since org workable by hippo is FALSE
        }

        test.stopTest();

        //LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;
    }
     */

    @IsTest
    static void testLeadStaysOnInfraBot() { // Reported in PROD, 5/19

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Comcast', true, true);

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.Email = '94546+hippo@gmail.com';
            ld.Phone = '2222222333';
            //ld.MobilePhone = '2021237845';
            ld.POD_Quote_ID__c = '';
            //ld.Lead_Score__c = '6';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Cat_Risk_Score__c = 0;
            ld.Non_Cat_Risk_Class__c = 'exterior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 1.1278900755;
            ld.UTM_Source__c = 'xfinity';

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertNotEquals(null, ld_new1.Organization__r.Name);
            System.assertEquals('Comcast', ld_new1.Organization__r.Name);
            System.assertNotEquals(null, ld_new1.Account__c);
            System.assertNotEquals(null, ld_new1.Account__r.Name);
            System.assertEquals('Comcast', ld_new1.Account__r.Name);
            System.assertEquals(Non_workable_leads_Q, ld_new1.OwnerId);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            ld.Lead_Score__c = '9';

            update ld;

            Lead ld_updated = [Select Id, OwnerId, Lead_Source__c, Account__c, Account__r.Name, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertEquals(B2C_Partner_Sales_1, ld_updated.OwnerId);
        }

        test.stopTest();

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    }

    @IsTest
    static void testLoanDepotNot2NonWorkable() { // SFDC-1694

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales');

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        //Lead ld = UnitTestHelper.prepareB2CLead(false, 'CA');
        Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Loan Depot', true, true);

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.FirstName = 'Jennifer';
            ld.MiddleName = 'A';
            ld.LastName = 'Varan';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'jennifer.varan13@albright.edu';
            ld.Phone = '2157765971';
            ld.Street = '613 E 21th Stret';
            ld.State = 'PA';
            ld.City = 'Chester';
            ld.PostalCode = '19013';
            ld.Line_of_Business__c = 'HO3';
            ld.Quote_Number__c = '135c1633-d68c-46a4-bc3b-88b404d46c04';
            ld.Last_Page_Visited__c = 'Clicked Link';

            insert ld;

            Lead ld_new1 = [Select Id, OwnerId, Lead_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_new1.Organization__c);
            System.assertEquals(Non_workable_leads_Q, ld_new1.OwnerId);
            System.assertNotEquals(HCR_Clicked_on_Link_Q, ld_new1.OwnerId);
            //System.assertEquals('HCR Clicked on Link', ld_new1.Lead_Source__c);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_new1.RecordTypeId);

            /*
            ld.UTM_Source__c = 'realtime';
            update ld;

            Lead ld_updated = [Select Id, OwnerId, Lead_Source__c, Organization__c, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
            System.assertNotEquals(null, ld_updated.Organization__c);
            System.assertNotEquals(Non_workable_leads_Q, ld_updated.OwnerId);
            System.assertEquals(HCR_Clicked_on_Link_Q, ld_updated.OwnerId);
            System.assertEquals('HCR Clicked on Link', ld_updated.Lead_Source__c);
            System.assertEquals(b2cRecordType.getRecordTypeId(), ld_updated.RecordTypeId);

             */
        }

        test.stopTest();
    }

    /*
    @IsTest
    static void testHASUWReferral_Scenario3() { // Repored in PRDD, 5/19. Test flow and data is based on the reported lead history: 00Q4V00001cF5voUAC

        UnitTestHelper.prepareDevEnvCustomSettings();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id UW_Referrals_1 = Utils.getQueueId('UW_Referrals_1');
        Id UW_Referrals_2 = Utils.getQueueId('UW_Referrals_2');
        Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');

        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareNonWorkableB2CLead(true, 'GA');

            Lead ld1_new = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_new.Organization__c);
            System.assertEquals(Non_workable_leads_Q, ld1_new.OwnerId);
            System.assertNotEquals('Closed', ld1_new.Status);
            System.assertNotEquals('UW Referral', ld1_new.Lead_Source__c);

            test.startTest();

            ld1.FirstName = 'Eric';
            ld1.LastName = 'Gullickson';
            ld1.MiddleName = 'G';
            ld1.Email = 'glrick060@aol.com';
            ld1.Non_Cat_Risk_Class__c = 'no_action'; // ??????
            //ld1.Non_Cat_Risk_Score__c = 1.30;
            ld1.Phone = '7156612476';
            //ld1.MobilePhone = '2021237845';
            //ld1.Cat_Risk_Class__c = 'no_action';

            update ld1;

            Lead ld1_updated_1stTime = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_updated_1stTime.Organization__c);
            System.assertEquals(Non_workable_leads_Q, ld1_updated_1stTime.OwnerId);
            System.assertNotEquals('Closed', ld1_updated_1stTime.Status);
            System.assertNotEquals('UW Referral', ld1_updated_1stTime.Lead_Source__c);

            ld1.POD_Quote_ID__c = '9380205';
            ld1.Cat_Risk_Class__c = 'no_action';
            //ld1.Non_Cat_Risk_Class__c = 'referral';
            //ld1.Non_Cat_Risk_Score__c = 1.30;

            update ld1;

            Lead ld1_updated_2ndTime = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_updated_2ndTime.Organization__c);
            System.assertEquals(Non_workable_leads_Q, ld1_updated_2ndTime.OwnerId);
            System.assertNotEquals('Closed', ld1_updated_2ndTime.Status);
            System.assertNotEquals('UW Referral', ld1_updated_2ndTime.Lead_Source__c);

            ld1.POD_Quote_ID__c = '9380204';

            update ld1;

            Lead ld1_updated_3rdTime = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_updated_3rdTime.Organization__c);
            System.assertEquals(Non_workable_leads_Q, ld1_updated_3rdTime.OwnerId);
            System.assertNotEquals('Closed', ld1_updated_2ndTime.Status);
            System.assertNotEquals('UW Referral', ld1_updated_3rdTime.Lead_Source__c);


            ld1.Non_Cat_Risk_Class__c = 'referral';
            ld1.POD_Quote_ID__c = '9380205';

            update ld1;

            Lead ld1_updated_4thTime = [Select Id, Status, Lead_Source__c, Organization__c, OwnerId From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_updated_4thTime.Organization__c);
            System.assertEquals(UW_Referrals_2, ld1_updated_4thTime.OwnerId);
            System.assertNotEquals('Closed', ld1_updated_4thTime.Status);
            System.assertEquals('UW Referral', ld1_updated_4thTime.Lead_Source__c);

            test.stopTest();
        }

        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
    }
     */

    @IsTest
    static void testAssignLead2HCR() { // SFDC-1694

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');
        Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Loan Depot', true, true);

            test.startTest();

            ld1.Status = 'New';
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.UTM_Source__c = 'realtime';
            ld1.Last_Page_Visited__c = 'Clicked Link';

            insert ld1;

            test.stopTest();

            Lead ld1_new = [Select Id, OwnerId, Lead_Source__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals('Loan Depot', ld1_new.Organization__r.Name);
            System.assertNotEquals(B2C_Partner_Sales_1, ld1_new.OwnerId);
            System.assertNotEquals(B2C_Partner_Sales_2, ld1_new.OwnerId);
            System.assertNotEquals('Partner Referral', ld1_new.Lead_Source__c);
            System.assertEquals(HCR_Clicked_on_Link_Q, ld1_new.OwnerId);
            System.assertEquals('HCR Clicked on Link', ld1_new.Lead_Source__c);

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testAssignLead2FacebookDirect() { // SFDC-1516

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Facebook_Direct = Utils.getQueueId('Facebook_Direct');

        User facebook_integration_user = [SELECT Id, Name FROM User WHERE Name = 'Facebook Integration User' LIMIT 1];

        System.runAs(facebook_integration_user) {

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

            Lead ld1 = UnitTestHelper.prepareFacebookDirectLead(false);

            test.startTest();

            insert ld1;

            test.stopTest();

            Lead ld1_new = [Select Id, OwnerId, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
            System.assertEquals(null, ld1_new.Organization__c);
            System.assertNotEquals(Non_workable_leads_Q, ld1_new.OwnerId);
            System.assertEquals(Facebook_Direct, ld1_new.OwnerId);
            System.assertEquals('Facebook Direct', ld1_new.Lead_Source__c);

            LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
        }
    }

    @IsTest
    static void testRoutingToWorkablebyHippo2() { // Prod lead reported as routed to outside sales (00Q4V00001cWOlVUAW)

        UnitTestHelper.prepareDevEnvCustomSettings();

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id Workable_by_Hippo_2 = Utils.getQueueId('Workable_by_Hippo_2');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'ca');

        System.runAs(infra_bot) {

            ld1.FirstName = 'Laqueena';
            ld1.MiddleName = 'Renea';
            ld1.LastName = 'Smith';
            ld1.Email = 'laqueena1417@icloud.com';
            ld1.Phone = '4144910721';
            ld1.Non_Cat_Risk_Class__c = 'no_action';
            ld1.Non_Cat_Risk_Score__c = 0;
            ld1.UTM_Source__c = 'google_experiment_new';
            ld1.UTM_Campaign__c = 'Generic_Phrase_Zip_H-13438888247_-122841440546';
            ld1.UTM_Medium__c = 'cpc';
            ld1.Street = '5324 N Lovers Lane Rd Unit 2';
            ld1.City = 'Milwaukee';
            ld1.State = 'wi';
            ld1.PostalCode = '53225';
            ld1.POD_Lead_Id__c = '2ea20165-8842-41fc-9bf2-87725bff5c34';
            //ld1.Lead_Score__c = '6';

            insert ld1;
        }

        Lead ld1_new = [Select Id, OwnerId, Status, Declination_Reason__c, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals(Non_workable_leads_Q, ld1_new.OwnerId); // by design as there is no lead score
        //System.assertEquals(Workable_by_Hippo_2, ld1_new.OwnerId); // expected per Michael Dodge. In prod it eventually routed to outside sales after 10 days (by design)
    }

     @IsTest
     static void testCreatedByUser() { // SFDC-1838

         UnitTestHelper.prepareDevEnvCustomSettings();

         LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

         Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

         Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Lennar Insurance_direct', false, true);

         ld1.FirstName = 'Kathleen';
         ld1.LastName = 'Aguilera';
         ld1.Lead_Source__c = 'Email';
         ld1.Email = 'aguilerakat@aol.com';
         ld1.Phone = '8052525669';
         ld1.Line_of_Business__c = 'Auto';
         ld1.Carrier_Name__c = 'spinnaker';
         ld1.Street = '8185 Benevento Dr';
         ld1.City = 'El Dorado Hills';
         ld1.State = 'ca';
         ld1.PostalCode = '95762';
         ld1.Policy_Types__c = 'Auto';
         ld1.Cat_Risk_Class__c = 'no_action';
         ld1.Non_Cat_Risk_Class__c = 'no_action';
         ld1.Cat_Risk_Score__c = 0;
         ld1.Non_Cat_Risk_Score__c = 0;
         ld1.Referral_Notes__c = 'Home quoted with Hippo';
         ld1.External_referring_Team__c = 'LIA';
         ld1.POD_Lead_Id__c = '86779dd9-51e3-45d2-9e5e-e1ec33787fa8';

         insert ld1;

         Lead ld1_new = [Select Id, OwnerId, Status, Declination_Reason__c, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
         System.assertEquals(UserInfo.getUserId(), ld1_new.OwnerId);

         User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

         System.runAs(infra_bot) {

             ld1.POD_Quote_ID__c = '9725914';
             ld1.Lead_Score__c = '6';

             update ld1;
         }

         ld1_new = [Select Id, OwnerId, Status, Declination_Reason__c, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
         System.assertEquals(UserInfo.getUserId(), ld1_new.OwnerId);

         LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    }

    @IsTest
    static void testColdTransferToNonWorkableQueue() { // Prod lead reported as routed to non workable queue (00Q4V00001cXMz6UAG), SFDC-1868

        UnitTestHelper.prepareDevEnvCustomSettings();

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id HAS_Internal_Referrals_Queue = Utils.getQueueId('HAS_Internal_Referrals');

        Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'ca');

        ld1.FirstName = 'Pamela';
        ld1.MiddleName = 'J';
        ld1.LastName = 'Williamson';
        ld1.Email = 'pjwilliamson55@gmail.com';
        ld1.Phone = '4792766247';
        ld1.Lead_Source__c = 'Internal Referral Cold Transfer';
        ld1.Referral_Notes__c = 'Client is on a strict budget';
        ld1.Street = '102 Cambridge St';
        ld1.City = 'Carl Junction';
        ld1.State = 'mo';
        ld1.PostalCode = '64834';
        ld1.Policy_Types__c = 'HO3';
        ld1.OwnerId = HAS_Internal_Referrals_Queue;
        //ld1.Lead_Score__c = '6';

        insert ld1;

        Lead ld1_new = [Select Id, OwnerId, Status, Declination_Reason__c, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals(HAS_Internal_Referrals_Queue, ld1_new.OwnerId); // by design as there is no lead score

        User application_user = [SELECT Id, Name FROM User WHERE Name = 'Application User' LIMIT 1];

        System.runAs(application_user) {

            ld1_new.PostalCode = '43846';
            update ld1_new;
        }

        Lead ld1_updated = [Select Id, OwnerId, Status, Declination_Reason__c, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld1_new.Id Limit 1]?.get(0);
        System.assertEquals(HAS_Internal_Referrals_Queue, ld1_updated.OwnerId); // by design as there is no lead score
    }

    @IsTest
    static void testPennymacLead_HCR_New_Purchase() { // SFDC-1752

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id PennyMac_HCR_New_Purchase = Utils.getQueueId('PennyMac_HCR_New_Purchase');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'realtime';
            ld.Partner_UTM_Source__c = 'New Purchase';
            ld.Last_Page_Visited__c = 'Clicked Link';

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, Lead_Source__c, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(PennyMac_HCR_New_Purchase, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals('PMIS HCR New Purchase Clicked on Link', ld_new1.Lead_Source__c);
    }

    @IsTest
    static void testPennymacLead_PMIS_HCR_Clicked_on_Link() { // SFDC-1752

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id PMIS_HCR_Clicked_on_Link = Utils.getQueueId('PMIS_HCR_Clicked_on_Link');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'realtime';
            //ld.Partner_UTM_Source__c = 'New Purchase';
            ld.Last_Page_Visited__c = 'Clicked Link';

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, Lead_Source__c, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(PMIS_HCR_Clicked_on_Link, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals('PMIS HCR Clicked on Link', ld_new1.Lead_Source__c);
    }

    @IsTest
    static void testPennymacLead_PMIS_HCR_N_Purchase_Reached_Prelim_Quote() { // SFDC-1752

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id PMIS_HCR_N_Purchase_Reached_Prelim_Quote = Utils.getQueueId('PMIS_HCR_N_Purchase_Reached_Prelim_Quote');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'realtime';
            ld.Partner_UTM_Source__c = 'New Purchase';
            ld.Last_Page_Visited__c = 'Reached Prelim Quote';

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, Lead_Source__c, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(PMIS_HCR_N_Purchase_Reached_Prelim_Quote, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals('PMIS HCR New Purchase Reached Prelim Quote', ld_new1.Lead_Source__c);
    }

    @IsTest
    static void testPennymacLead_PMIS_HCR_Reached_Prelim_Quote() { // SFDC-1752

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id PMIS_HCR_Reached_Prelim_Quote = Utils.getQueueId('PMIS_HCR_Reached_Prelim_Quote');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Lead ld = LeadTriggerTest.preparePennyMacLeadWithAccountName(false, 'Penny Mac Insurance Services');

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'realtime';
            //ld.Partner_UTM_Source__c = 'New Purchase';
            ld.Last_Page_Visited__c = 'Reached Prelim Quote';

            insert ld;
        }

        test.stopTest();

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('PennyMac Lead');
        Lead ld_new1 = [Select Id, Lead_Source__c, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(PMIS_HCR_Reached_Prelim_Quote, ld_new1.OwnerId);
        System.assertEquals(pmRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals('PMIS HCR Reached Prelim Quote', ld_new1.Lead_Source__c);
    }

    @IsTest
    static void testAmerisaveLead_AIA_HCR_Clicked_on_Link() { // SFDC-1848

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('AmeriSave Lead');

        Id AIA_HCR_Clicked_on_Link = Utils.getQueueId('AIA_HCR_Clicked_on_Link');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Account acc = LeadTriggerTest.prepareAccount(true, 'AmeriSave Insurance Agency');

        Lead ld = UnitTestHelper.prepareLeadByRecordTypeName(false, amsRecordType.getName());

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'realtime';
            //ld.Partner_UTM_Source__c = '';
            ld.Last_Page_Visited__c = 'Clicked Link';

            insert ld;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, Lead_Source__c, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(AIA_HCR_Clicked_on_Link, ld_new1.OwnerId);
        System.assertEquals(amsRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals('AIA HCR Clicked on Link', ld_new1.Lead_Source__c);
    }

    @IsTest
    static void testAmerisaveLead_AIA_HCR_Reached_Prelim_Quote() { // SFDC-1848

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        UnitTestHelper.prepareDevEnvCustomSettings();

        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('AmeriSave Lead');

        Id AIA_HCR_Reached_Prelim_Quote = Utils.getQueueId('AIA_HCR_Reached_Prelim_Quote');

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        Account acc = LeadTriggerTest.prepareAccount(true, 'AmeriSave Insurance Agency');

        Lead ld = UnitTestHelper.prepareLeadByRecordTypeName(false, amsRecordType.getName());

        test.startTest();

        System.runAs(infra_bot) {

            ld.Status = 'New';
            ld.POD_Quote_ID__c = '';
            ld.Email = 'kkgallardo@outlook.com';
            ld.Phone = '4026404310';
            ld.Cat_Risk_Class__c = 'no_action';
            ld.Non_Cat_Risk_Class__c = 'interior_inspection_required';
            ld.Non_Cat_Risk_Score__c = 0.060428;
            ld.UTM_Source__c = 'realtime';
            //ld.Partner_UTM_Source__c = '';
            ld.Last_Page_Visited__c = 'Reached Prelim Quote';

            insert ld;
        }

        test.stopTest();

        Lead ld_new1 = [Select Id, Lead_Source__c, OwnerId, Organization__r.Name, RecordTypeId, RecordType.DeveloperName From Lead Where Id = :ld.Id Limit 1];
        System.assertNotEquals(null, ld_new1.Organization__r.Name);
        System.assertEquals(AIA_HCR_Reached_Prelim_Quote, ld_new1.OwnerId);
        System.assertEquals(amsRecordType.getRecordTypeId(), ld_new1.RecordTypeId);
        System.assertEquals('AIA HCR Reached Prelim Quote', ld_new1.Lead_Source__c);
    }

    /*
    @IsTest
    static void testCreatedByUserGettingCancelled() { // Prod lead getting cancelled (00Q4V00001cY4DRUA0)

        // Lead in context: 00Q4V00001cY4DRUA0

        // Name_Deduplication_Key__c: KathleenAguilera8185 Benevento DrEl Dorado Hillsca95762
        // Phone_Deduplication_Key__c: 80525256698185 Benevento DrEl Dorado Hillsca95762
        // Mobile_Deduplication_Key__c: 8185 Benevento DrEl Dorado Hillsca95762
        // Email_Deduplication_Key__c: aguilerakat@aol.com8185 Benevento DrEl Dorado Hillsca95762

        // ==>

        // SELECT Id,CreatedDate, IsJVLead__c,Is_HCR_Lead__c,Name_Deduplication_Key__c,Phone_Deduplication_Key__c,Mobile_Deduplication_Key__c,
        // Email_Deduplication_Key__c FROM Lead WHERE Name_Deduplication_Key__c = 'KathleenAguilera8185 Benevento DrEl Dorado Hillsca95762'
        // OR Phone_Deduplication_Key__c = '80525256698185 Benevento DrEl Dorado Hillsca95762'
        // OR Mobile_Deduplication_Key__c = '8185 Benevento DrEl Dorado Hillsca95762'
        // OR Email_Deduplication_Key__c = 'aguilerakat@aol.com8185 Benevento DrEl Dorado Hillsca95762'

        // ==> dup lead in prod: 00Q4V00001cXenhUAC

        UnitTestHelper.prepareDevEnvCustomSettings();

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = true;

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

        Lead ld1 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Lennar Insurance_direct', false, true);

        Account accLennar = LeadTriggerTest.prepareAccount(true, 'Lennar Insurance', false, true);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            ld1.FirstName = 'Kathleen';
            ld1.LastName = 'Aguilera';
            ld1.Lead_Source__c = 'Email';
            ld1.Email = 'aguilerakat@aol.com';
            ld1.Phone = '8052525669';
            ld1.Line_of_Business__c = 'Auto';
            ld1.Carrier_Name__c = 'spinnaker';
            ld1.Street = '8185 Benevento Dr';
            ld1.City = 'El Dorado Hills';
            ld1.State = 'ca';
            ld1.PostalCode = '95762';
            ld1.Policy_Types__c = 'Auto';
            ld1.Cat_Risk_Class__c = 'no_action';
            ld1.Non_Cat_Risk_Class__c = 'no_action';
            ld1.Cat_Risk_Score__c = 0;
            ld1.Non_Cat_Risk_Score__c = 0;
            ld1.Referral_Notes__c = 'Home quoted with Hippo';
            ld1.External_referring_Team__c = 'LIA';
            ld1.POD_Lead_Id__c = '86779dd9-51e3-45d2-9e5e-e1ec33787fa8';

            insert ld1;

            ld1.Organization__c = accLennar.Id;
            ld1.POD_Quote_ID__c = '9725914';

            update ld1;
        }

        Lead ld1_new = [Select Id, OwnerId, Status, Declination_Reason__c, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld1.Id Limit 1]?.get(0);
        System.assertEquals(UserInfo.getUserId(), ld1_new.OwnerId);

        test.startTest();

        //Lead ld2 = LeadTriggerTest.prepareB2CLeadWithAccountName(false, 'Lennar Insurance', false, true);
        Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'ca');

        ld2.Organization__c = accLennar.Id;
        ld2.FirstName = 'Kathleen';
        ld2.LastName = 'Aguilera';
        ld2.Lead_Source__c = 'Email';
        ld2.Email = 'aguilerakat@aol.com';
        ld2.Phone = '8052525669';
        ld2.Line_of_Business__c = 'Auto';
        ld2.Carrier_Name__c = 'spinnaker';
        ld2.Street = '8185 Benevento Dr';
        ld2.City = 'El Dorado Hills';
        ld2.State = 'ca';
        ld2.PostalCode = '95762';
        ld2.Policy_Types__c = 'Auto';

        insert ld2;

        test.stopTest();

        Lead ld2_new = [Select Id, OwnerId, Lead_Source__c, Organization__c, Organization__r.Name From Lead Where Id = :ld2.Id Limit 1]?.get(0);
        System.assertEquals(UserInfo.getUserId(), ld2_new.OwnerId);

        LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING = false;
    }
    */
}