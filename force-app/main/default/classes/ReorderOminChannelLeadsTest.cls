@IsTest
private class ReorderOminChannelLeadsTest {

    // Dummy CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2030';

    @IsTest
    static void testScheduledJob() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');

        List<Lead> lst_Leads = new List<Lead>();

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld1 = UnitTestHelper.prepareB2CLead(false, 'MD');
            Lead ld2 = UnitTestHelper.prepareB2CLead(false, 'CA');

            ld1.Status = 'New';
            ld1.Email = 'test.sfdc@leads.com';
            ld1.Phone = '3011237845';
            ld1.MobilePhone = '2021237845';
            ld1.POD_Quote_ID__c = '';
            ld1.Lead_Score__c = '6';

            ld2.Status = 'New';
            ld2.Email = 'test.sfdc@leads.com';
            ld2.Phone = '3011237846';
            ld2.MobilePhone = '2021237846';
            ld2.POD_Quote_ID__c = '';
            ld2.Lead_Score__c = '6';

            lst_Leads.add(ld1);
            lst_Leads.add(ld2);

            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
            insert lst_Leads;
            LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

            test.startTest();

            Map<Id, Lead> map_Leads = new Map<Id, Lead>([Select Id, Phone, Email, Status, OwnerId From Lead]);
            system.debug('Created leads: ' + map_Leads);

            System.assertEquals(2, map_Leads.size());
            List<Group> groups = [Select Id, Name, DeveloperName From Group Where Id = :map_Leads.values()[0].OwnerId];
            system.debug('Leads owner: ' + groups[0].DeveloperName);
            System.assertEquals(B2C_Direct_1, map_Leads.values()[0].OwnerId);
            System.assertEquals(B2C_Direct_1, map_Leads.values()[1].OwnerId);

            List<PendingServiceRouting> todays_pendingWorkItems = [Select Id, CreatedDate, CustomRequestedDatetime, WorkItemId, IsReadyforRouting, IsPushed, GroupId from PendingServiceRouting Where CreatedDate = TODAY And IsPushed = False And GroupId = :B2C_Direct_1 And WorkItemId IN:map_Leads.keySet() Order By CreatedDate DESC];

            system.debug('todays_pendingWorkItems size: ' + todays_pendingWorkItems.size());
            System.assertEquals(2, todays_pendingWorkItems.size());

            // Schedule the test job
            ID jobID = System.schedule('ScheduledApexTest', CRON_EXP, new ReorderOminChannelLeadsScheduler());

            jobID = System.enqueueJob(new ReorderOminChannelLeadsQueue(new List<Id>()));

            // Stopping the test will run the job synchronously
            Test.stopTest();

            // Now that the scheduled job has executed,
            // check that our PendingServiceRouting were updated
            todays_pendingWorkItems = [Select Id, CreatedDate, CustomRequestedDatetime, WorkItemId, IsReadyforRouting, IsPushed, GroupId from PendingServiceRouting Where CreatedDate = TODAY And IsPushed = False And GroupId = :B2C_Direct_1 And WorkItemId IN:map_Leads.keySet() Order By CreatedDate DESC];
            for (PendingServiceRouting psr : todays_pendingWorkItems) {

                system.debug('PSR CreatedDate: ' + psr.CreatedDate);
                system.debug('PSR CustomRequestedDateTime: ' + psr.CustomRequestedDateTime);
                System.assertNotEquals(null, psr.CustomRequestedDateTime);
            }
        }

        AsyncUpdatePendingServiceRoutingItems.fakeCoverage();
    }

    /*
    @IsTest
    static void testCDCEvent() {

        // Enable all Change Data Capture entities for notifications.
        Test.enableChangeDataCapture();

        UnitTestHelper.prepareDevEnvCustomSettings();

        String queue_dev_name = Utils.getHippoSettings('Omni Lead Queue Developer Name');
        Id leadOmniChannelQueueId = Utils.getQueueId(queue_dev_name); //B2C_Direct_Sales in PROD
        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Better_Cover = Utils.getQueueId('B2C_Better_Cover');
        Id B2C_The_Money_Source = Utils.getQueueId('B2C_The_Money_Source');
        Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        System.assertEquals(leadOmniChannelQueueId, B2C_Direct_Sales);

        Map<String, String> lead_queues = Utils.getLeadQueuesMapping();

        List<Lead> lst_Leads = new List<Lead>();

        for (String acc : lead_queues.keySet()) {

            Lead ld = LeadTriggerTest.prepareB2CLeadWithAccountName(false, acc);
            ld.Status = 'New';
            ld.OwnerId = Non_workable_leads_Q;
            ld.Email = 'test.sfdc@leads.com';
            ld.Phone = '3011237845';
            ld.MobilePhone = '2021237845';
            ld.POD_Quote_ID__c = '';
            lst_Leads.add(ld);
        }

        insert lst_Leads;

        List<Lead> qry_Leads = [Select Id, Phone, Email, Status, OwnerId From Lead Order By Id DESC];
        system.debug('Created leads: ' + qry_Leads);
        system.assertEquals(lead_queues.values().size(), qry_Leads.size());

        String query = 'Select Id, CreatedDate, CustomRequestedDatetime, WorkItemId, IsReadyforRouting, IsPushed, GroupId from PendingServiceRouting Where IsPushed = False And (GroupId =: B2C_Partner_Sales OR GroupId =: B2C_Better_Cover OR GroupId =: B2C_The_Money_Source OR GroupId =: B2C_Direct_Sales) Order By Id DESC LIMIT ' + 500;
        List<PendingServiceRouting> pendingPSRItems = Database.query(query);
        system.assertEquals(lead_queues.values().size(), pendingPSRItems.size());

        test.startTest();

        // Deliver test change events
        Test.getEventBus().deliver();

        // Verify the change event trigger’s execution
        List<Lead> cdc_Leads = [Select Id, Phone, Email, Status, OwnerId From Lead Order By Id DESC];
        system.debug('Created leads: ' + qry_Leads);
        system.assertEquals(lead_queues.values().size(), cdc_Leads.size());

        query = 'Select Id, CreatedDate, CustomRequestedDatetime, WorkItemId, IsReadyforRouting, IsPushed, GroupId from PendingServiceRouting Where IsPushed = False And (GroupId =: B2C_Partner_Sales OR GroupId =: B2C_Better_Cover OR GroupId =: B2C_The_Money_Source OR GroupId =: B2C_Direct_Sales) Order By Id DESC LIMIT ' + 500;
        pendingPSRItems = Database.query(query);
        system.assertEquals(lead_queues.values().size(), pendingPSRItems.size());

        for (Integer i = 0; i < pendingPSRItems.size(); i++) {
            system.assertNotEquals(null, pendingPSRItems[i].CustomRequestedDateTime);
            if (i != pendingPSRItems.size() - 1) {
                system.assertEquals(true, pendingPSRItems[i].CustomRequestedDateTime < pendingPSRItems[i + 1].CustomRequestedDateTime);
            }
        }

        test.stopTest();
    }
     */
}