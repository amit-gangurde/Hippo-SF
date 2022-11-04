@IsTest
private class MadSkyIntegrationTest {

    @IsTest
    static void test_Send2MadSkyOnInsert() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Account acc = UnitTestHelper.prepareAccount(true, 'MadSky');
        System.assertNotEquals(null, acc.Id);

        test.startTest();

        Case cs1 = UnitTestHelper.prepareClaimCase('Wind', 'Topa', 'DFW', acc);
        System.assertNotEquals(null, cs1.Id);

        Case cs2 = UnitTestHelper.prepareClaimCase('Hail', 'Topa', 'DFW', acc);
        System.assertNotEquals(null, cs2.Id);

        Test.getEventBus().deliver();

        test.stopTest();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('MadSky', 'Callout__c');

        List<Callout__c> call1 = [SELECT Id, RecordTypeId, Status__c FROM Callout__c WHERE Case__c =: cs1.Id AND RecordTypeId =: rtInfo.getRecordTypeId()];
        System.assertEquals(1, call1.size());
        System.assertEquals('OK', call1[0].Status__c);

        List<Callout__c> call2 = [SELECT Id, RecordTypeId, Status__c FROM Callout__c WHERE Case__c =: cs2.Id AND RecordTypeId =: rtInfo.getRecordTypeId()];
        System.assertEquals(1, call2.size());
        System.assertEquals('OK', call2[0].Status__c);
    }

    @IsTest
    static void test_Send2MadSkyOnUpdate() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Account acc_MadSky = UnitTestHelper.prepareAccount(true, 'MadSky');
        System.assertNotEquals(null, acc_MadSky.Id);

        Account acc_Dummy = UnitTestHelper.prepareAccount(true, 'Dummy');
        System.assertNotEquals(null, acc_Dummy.Id);

        Case cs1 = UnitTestHelper.prepareClaimCase('Wind', 'Topa', 'DFW', acc_Dummy);
        System.assertNotEquals(null, cs1.Id);

        test.startTest();

        cs1.Claim_Vendor__c = acc_MadSky.Id;
        update cs1;

        Test.getEventBus().deliver();

        test.stopTest();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('MadSky', 'Callout__c');

        List<Callout__c> call1 = [SELECT Id, RecordTypeId, Status__c FROM Callout__c WHERE Case__c =: cs1.Id AND RecordTypeId =: rtInfo.getRecordTypeId()];
        System.assertEquals(1, call1.size());
        System.assertEquals('OK', call1[0].Status__c);

    }
}