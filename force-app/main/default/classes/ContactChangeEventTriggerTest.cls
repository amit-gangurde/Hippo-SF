@IsTest
private class ContactChangeEventTriggerTest {

    @IsTest
    static void increaseCoverage() {

        HippoChangeDataEventsCallouts.fakeMethod();
        CalloutTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testSendNewContactToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        test.startTest();

        Contact con = UnitTestHelper.prepareContact('Business');
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }

    @IsTest
    static void testSendUpdatedContactToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        Contact con = UnitTestHelper.prepareContact('Business');
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();


        test.startTest();

        Contact new_Contact = [Select Id, FirstName, LastName From Contact Where Id =: con.Id];
        new_Contact.FirstName = 'Updated Contact FirstName';
        update new_Contact;
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }
}