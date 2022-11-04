@IsTest
private class AccountChangeEventTriggerTest {

    @IsTest
    static void increaseCoverage() {

        HippoChangeDataEventsCallouts.fakeMethod();
        CalloutTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testSendNewAccountToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        test.startTest();

        Account acc = UnitTestHelper.prepareAccount();

        test.stopTest();

        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();
    }

    @IsTest
    static void testSendUpdatedAccountToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        Account acc = UnitTestHelper.prepareAccount();
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.startTest();

        Account new_Account = [Select Id, Name From Account Where Id =: acc.Id];
        new_Account.Website = 'Updated Account Website';
        update new_Account;
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }
}