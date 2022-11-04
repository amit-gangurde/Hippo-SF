@IsTest
public with sharing class RouteRetentionCasesTest {

    // Dummy CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    @IsTest
    static void testESTScheduledJob() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        User est_User = new User(Alias = 'est', Email = 'standardESTuser@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'EST Testing', LanguageLocaleKey='en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/New_York', UserName = Utils.getRandomString(5) + '@testorg.com');

        System.runAs(est_User) {

            UnitTestHelper.prepareDevEnvCustomSettings();

            String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Cases EST Queue');
            String estPendingCasesQueueId = Utils.getQueueId(est_pending_queue_dev_name);

            Case theCase = UnitTestHelper.prepareRetentionCase(false, 'AL');
            theCase.OwnerId = estPendingCasesQueueId;
            insert theCase;

            List<Case> lst_Cases = [Select Id, OwnerId From Case];
            System.assertEquals(1, lst_Cases.size());
            System.assertEquals(estPendingCasesQueueId, lst_Cases[0].OwnerId);

            test.startTest();

            // Schedule the test job
            ID jobID = System.schedule('ScheduledApexTest_EST', CRON_EXP, new RouteRetentionCasesScheduler());

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

            String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Cases PST Queue');
            String pstPendingCasesQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

            Case theCase = UnitTestHelper.prepareRetentionCase(false, 'AK');
            theCase.OwnerId = pstPendingCasesQueueId;
            insert theCase;

            List<Case> lst_Cases = [Select Id, OwnerId From Case];
            System.assertEquals(1, lst_Cases.size());
            System.assertEquals(pstPendingCasesQueueId, lst_Cases[0].OwnerId);

            test.startTest();

            // Schedule the test job
            ID jobID = System.schedule('ScheduledApexTest_PST', CRON_EXP, new RouteRetentionCasesScheduler());

            test.stopTest();
        }
    }
}