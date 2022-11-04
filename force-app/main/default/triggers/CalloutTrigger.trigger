trigger CalloutTrigger on Callout__c (after insert, after update) {

    new CalloutTriggerHandler().run();
}