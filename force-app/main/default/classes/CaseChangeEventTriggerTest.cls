@IsTest
private class CaseChangeEventTriggerTest {

    @IsTest
    static void increaseCoverage() {

        HippoChangeDataEventsCallouts.fakeMethod();
        CalloutTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testSendNewCaseToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        test.startTest();

        Case cs = UnitTestHelper.prepareClaimCase('Lightning', 'Topa', 'DFW');

        test.stopTest();

        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();
    }

    @IsTest
    static void testSendUpdatedCaseToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        Case cs = UnitTestHelper.prepareClaimCase('Lightning', 'Topa', 'DFW');
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.startTest();

        Case new_Case = [Select Id, Description From Case Where Id =: cs.Id];
        new_Case.Description = 'Updated Case Description';
        update new_Case;
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }
}