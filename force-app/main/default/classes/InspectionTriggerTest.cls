/**
 * Created by lironkeren on 26/06/2022.
 */

@IsTest
private class InspectionTriggerTest {

    @testsetup
    public static void testSetup() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));
    }

    @IsTest
    static void testCreateHazardsDuringInspectionCreate() {

        Lead ld = UnitTestHelper.prepareB2CLead(true, 'CA');

        Inspection__c inspection = UnitTestHelper.createInspection(false, ld.Id);

        test.startTest();

        inspection.Hazards__c = InspectionTriggerHandler.test_hazards_json;
        insert inspection;
        Inspection__c inspection_new = [Select Id From Inspection__c Limit 1];
        System.assertNotEquals(null, inspection_new.Id);

        test.stopTest();

        List<Hazard__c> lst_hHazards = [SELECT Id, Category__c, Sub_Category__c, Hazard_Key__c, Score__c FROM Hazard__c];
        System.assertEquals(2, lst_hHazards.size());

        System.assertEquals('General Information', lst_hHazards[0].Category__c);
        System.assertEquals('Vacant and uninhabitable', lst_hHazards[0].Sub_Category__c);
        System.assertEquals('GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ', lst_hHazards[0].Hazard_Key__c);
        System.assertEquals(200, lst_hHazards[0].Score__c);

        System.assertEquals('General Information', lst_hHazards[1].Category__c);
        System.assertEquals('Vacant and uninhabitable', lst_hHazards[1].Sub_Category__c);
        System.assertEquals('GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ_2', lst_hHazards[1].Hazard_Key__c);
        System.assertEquals(300, lst_hHazards[1].Score__c);
    }

    @IsTest
    static void testCreateHazardsDuringInspectionUpdate() {

        Lead ld = UnitTestHelper.prepareB2CLead(true, 'CA');

        Inspection__c inspection = UnitTestHelper.createInspection(false, ld.Id);

        inspection.Hazards__c = InspectionTriggerHandler.test_hazards_json;
        insert inspection;
        Inspection__c inspection_new = [Select Id From Inspection__c Limit 1];
        System.assertNotEquals(null, inspection_new.Id);

        List<Hazard__c> lst_hHazards = [SELECT Id, Category__c, Sub_Category__c, Hazard_Key__c, Score__c FROM Hazard__c];
        System.assertEquals(2, lst_hHazards.size());

        System.assertEquals('General Information', lst_hHazards[0].Category__c);
        System.assertEquals('Vacant and uninhabitable', lst_hHazards[0].Sub_Category__c);
        System.assertEquals('GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ', lst_hHazards[0].Hazard_Key__c);
        System.assertEquals(200, lst_hHazards[0].Score__c);

        System.assertEquals('General Information', lst_hHazards[1].Category__c);
        System.assertEquals('Vacant and uninhabitable', lst_hHazards[1].Sub_Category__c);
        System.assertEquals('GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ_2', lst_hHazards[1].Hazard_Key__c);
        System.assertEquals(300, lst_hHazards[1].Score__c);

        delete lst_hHazards;
        lst_hHazards = [SELECT Id, Category__c, Sub_Category__c, Hazard_Key__c, Score__c FROM Hazard__c];
        System.assertEquals(0, lst_hHazards.size());

        test.startTest();

        inspection.Inspection_Provider__c = 'Muller';
        update inspection;

        test.stopTest();

        lst_hHazards = [SELECT Id, Category__c, Sub_Category__c, Hazard_Key__c, Score__c FROM Hazard__c];
        System.assertEquals(2, lst_hHazards.size());

        System.assertEquals('General Information', lst_hHazards[0].Category__c);
        System.assertEquals('Vacant and uninhabitable', lst_hHazards[0].Sub_Category__c);
        System.assertEquals('GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ', lst_hHazards[0].Hazard_Key__c);
        System.assertEquals(200, lst_hHazards[0].Score__c);

        System.assertEquals('General Information', lst_hHazards[1].Category__c);
        System.assertEquals('Vacant and uninhabitable', lst_hHazards[1].Sub_Category__c);
        System.assertEquals('GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ_2', lst_hHazards[1].Hazard_Key__c);
        System.assertEquals(300, lst_hHazards[1].Score__c);
    }
}