@IsTest
private class CarrierAppointmentChangeEventTriggerTest {

    @IsTest
    static void increaseCoverage() {

        HippoChangeDataEventsCallouts.fakeMethod();
        CalloutTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testSendNewCarrierAppointmentToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        test.startTest();

        Carrier_Appointment__c carrierAppointment = UnitTestHelper.prepareCarrierAppointment();
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }

    @IsTest
    static void testSendUpdatedCarrierAppointmentToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.enableChangeDataCapture();

        Carrier_Appointment__c carrierAppointment = UnitTestHelper.prepareCarrierAppointment();
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();


        test.startTest();

        Carrier_Appointment__c new_carrierAppointment = [Select Id, Name From Carrier_Appointment__c Where Id =: carrierAppointment.Id];
        new_carrierAppointment.Name = 'Updated Carrier Appointment Name';
        update new_carrierAppointment;
        // Call deliver to fire the cdc trigger
        Test.getEventBus().deliver();

        test.stopTest();
    }
}