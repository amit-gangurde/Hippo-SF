@IsTest
private class CloseOldLeadsTest {

    // Dummy CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2025';

    @IsTest
    static void testScheduledJob() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        List<Lead> lst_Leads = new List<Lead>();
        Lead ld1 = UnitTestHelper.prepareB2CLead(false, false);
        Lead ld2 = UnitTestHelper.prepareB2CLead(false, false);
        lst_Leads.add(ld1);
        lst_Leads.add(ld2);

        insert lst_Leads;

        Set<Id> lead_ids = new Set<Id> {ld1.Id, ld2.Id};

        Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');

        String formatted_query = String.format(CloseOldLeads.query, new List<Object>{'\'New\'', '\'' + String.valueOf(Outside_Sales_Queue) + '\''});
        System.debug('formatted_query: ' + formatted_query);
        
        List<Lead> leads = Database.query(formatted_query);

        System.assertEquals(2, leads.size());
        System.assertEquals('New', leads[0].Status);
        System.assertEquals('New', leads[1].Status);

        test.startTest();

        // Schedule the test job
        ID jobID = System.schedule('ScheduledApexTest', CRON_EXP, new CloseOldLeadsScheduler());
        CronTrigger ct = [SELECT Id, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobID];
        // TimesTriggered should be 0 because the job hasn't started yet.
        System.assertEquals(0, ct.TimesTriggered);
        jobID = database.executeBatch(new CloseOldLeads());

        test.stopTest();

        //Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');

        leads = [Select Id, Status, OwnerId From Lead Where Id IN: lead_ids];
        System.assertEquals(2, leads.size());
        System.assertEquals('New', leads[0].Status);
        System.assertEquals(Outside_Sales_Queue, leads[0].OwnerId);
        System.assertEquals('New', leads[1].Status);
        System.assertEquals(Outside_Sales_Queue, leads[1].OwnerId);
    }
}