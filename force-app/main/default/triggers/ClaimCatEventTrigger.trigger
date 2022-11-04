trigger ClaimCatEventTrigger on Claim_Cat_Event__c (after insert, after update) {

    new ClaimCatEventTriggerHandler().run();
}