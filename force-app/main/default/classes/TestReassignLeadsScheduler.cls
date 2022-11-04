@isTest
private class TestReassignLeadsScheduler {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
	@isTest 
    static void testScheduledJob()
    {
        //Just to get test coverage, Actual test cases are handled in a different test class
        Test.startTest();
        String jobId = System.schedule('TestReassignLeadsScheduler', CRON_EXP, new ReassignLeadsScheduler());         
        Test.stopTest();
    }
}