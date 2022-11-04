trigger ClaimReserveTrigger on Claim_Reserve__c (before insert, after insert, before update, after update) {
    new ClaimReserveTriggerHandler().run();
}