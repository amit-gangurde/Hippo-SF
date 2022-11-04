/**
 * Created by lironkeren on 26/06/2022.
 */

trigger InspectionTrigger on Inspection__c (after insert, after update) {

    new InspectionTriggerHandler().run();
}