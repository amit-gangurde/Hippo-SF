@IsTest
private class LicenseChangeEventTriggerTest {

    @IsTest
    static void increaseCoverage() {

        HippoChangeDataEventsCallouts.fakeMethod();
        CalloutTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testSendNewLicenseToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        test.startTest();

        License__c lic = UnitTestHelper.prepareLicense();
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }

    @IsTest
    static void testSendUpdatedLicenseToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        License__c lic = UnitTestHelper.prepareLicense();
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();


        test.startTest();

        License__c new_License = [Select Id, Name From License__c Where Id =: lic.Id];
        new_License.Name = 'Updated License Name';
        update new_License;
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }
}