trigger LicenseTrigger on License__c (after insert, after update) {

    new LicenseTriggerHandler().run();
}