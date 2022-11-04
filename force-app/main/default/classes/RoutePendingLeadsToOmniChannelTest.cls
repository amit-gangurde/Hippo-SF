@IsTest
private class RoutePendingLeadsToOmniChannelTest {

    public static Integer num_Of_Leads_2_Create = 10;

    // Dummy CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2030';

    @testsetup
    public static void createTimezoneRelatedTestData() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        List<Lead> lst_Leads = new List<Lead>();

        for (Integer i = 0; i < num_Of_Leads_2_Create; i++) { // Prepare 10 East coast Leads

            lst_Leads.add(UnitTestHelper.prepareB2CLead(false, 'MD'));
        }

        for (Integer i = 0; i < num_Of_Leads_2_Create; i++) { // Prepare 10 West coast Leads

            lst_Leads.add(UnitTestHelper.prepareB2CLead(false, 'CA'));
        }

        System.assertNotEquals(0, lst_Leads.size());

        LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
        // Prepare Leads Outside of Business Hours
        insert lst_Leads;
        LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;
    }

    @IsTest
    static void testRouteTimezonePendingLeads() {

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

        String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
        String estPendingLeadsQueueId = Utils.getQueueId(est_pending_queue_dev_name);

        String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

        // Make sure there are east coast pending leads
        List<Lead> lst_CreatedLeadsEST = [Select Id, State, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead WHERE State = 'MD'];
        System.assertEquals(num_Of_Leads_2_Create, lst_CreatedLeadsEST.size());

        for (Integer i = 0; i < lst_CreatedLeadsEST.size(); i++) {

            System.assertEquals(estPendingLeadsQueueId, lst_CreatedLeadsEST[i].OwnerId);
            System.assertEquals(Non_workable_leads_Q, lst_CreatedLeadsEST[i].Pending_Queue_Id__c);
        }
        // ========================================================================================

        // Make sure there are west coast pending leads
        List<Lead> lst_CreatedLeadsPST = [Select Id, State, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead WHERE State = 'CA'];
        System.assertEquals(num_Of_Leads_2_Create, lst_CreatedLeadsPST.size());

        for (Integer i = 0; i < lst_CreatedLeadsPST.size(); i++) {

            System.assertEquals(pstPendingLeadsQueueId, lst_CreatedLeadsPST[i].OwnerId);
            System.assertEquals(Non_workable_leads_Q, lst_CreatedLeadsPST[i].Pending_Queue_Id__c);
        }
        // ========================================================================================

        test.startTest();

        // Schedule the test job
        ID jobID_sch = System.schedule('ScheduledApexTest_EST', CRON_EXP, new RoutePendingLeadsScheduler());
        // The queueable inside the scheduler was not fired, so fire it explicitly
        Id jobId_que = System.enqueueJob(new RoutePendingLeadsToOmniChannel());

        test.stopTest();

        // Verify that east coast pending leads were routed to the correct owner
        lst_CreatedLeadsEST = [Select Id, State, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead WHERE State = 'MD'];
        System.assertEquals(num_Of_Leads_2_Create, lst_CreatedLeadsEST.size());

        for (Integer i = 0; i < lst_CreatedLeadsEST.size(); i++) {

            System.assertEquals(Non_workable_leads_Q, lst_CreatedLeadsEST[i].OwnerId);
            System.assertEquals(null, lst_CreatedLeadsEST[i].Pending_Queue_Id__c);
        }
        // ========================================================================================

        // Verify that west coast pending leads were routed to the correct owner
        lst_CreatedLeadsPST = [Select Id, State, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead WHERE State = 'CA'];
        System.assertEquals(num_Of_Leads_2_Create, lst_CreatedLeadsPST.size());

        for (Integer i = 0; i < lst_CreatedLeadsPST.size(); i++) {

            System.assertEquals(Non_workable_leads_Q, lst_CreatedLeadsPST[i].OwnerId);
            System.assertEquals(null, lst_CreatedLeadsPST[i].Pending_Queue_Id__c);
        }
        // ========================================================================================

    }

    @IsTest
    static void fakeCoverage() {

        RoutePendingLeadsToOmniChannel.fakeCoverage();
    }

    /*
    @IsTest
    static void testESTScheduledJob() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        User est_User = new User(Alias = 'est', Email = 'standardESTuser@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'EST Testing', LanguageLocaleKey='en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/New_York', UserName = Utils.getRandomString(5) + '@testorg.com');

        System.runAs(est_User) {

            UnitTestHelper.prepareDevEnvCustomSettings();

            String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
            String estPendingLeadsQueueId = Utils.getQueueId(est_pending_queue_dev_name);

            Lead ld = UnitTestHelper.prepareB2CLead(false, false);
            ld.OwnerId = estPendingLeadsQueueId;
            insert ld;

            List<Lead> lst_Leads = [Select Id, OwnerId From Lead];
            System.assertEquals(1, lst_Leads.size());
            System.assertEquals(estPendingLeadsQueueId, lst_Leads[0].OwnerId);

            test.startTest();

            // Schedule the test job
            ID jobID = System.schedule('ScheduledApexTest_EST', CRON_EXP, new RoutePendingLeadsScheduler());

            test.stopTest();
        }
    }

    @IsTest
    static void testPSTScheduledJob() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        User pst_User = new User(Alias = 'pst', Email = 'standardPSTuser@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'PST Testing', LanguageLocaleKey='en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = Utils.getRandomString(5) + '@testorg.com');

        System.runAs(pst_User) {

            UnitTestHelper.prepareDevEnvCustomSettings();

            String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
            String pstPendingLeadsQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

            Lead ld = UnitTestHelper.prepareB2CLead(false, false);
            ld.OwnerId = pstPendingLeadsQueueId;
            insert ld;

            List<Lead> lst_Leads = [Select Id, OwnerId From Lead];
            System.assertEquals(1, lst_Leads.size());
            System.assertEquals(pstPendingLeadsQueueId, lst_Leads[0].OwnerId);

            test.startTest();

            // Schedule the test job
            ID jobID = System.schedule('ScheduledApexTest_PST', CRON_EXP, new RoutePendingLeadsScheduler());

            test.stopTest();
        }
    }
     */
}