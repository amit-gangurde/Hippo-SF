trigger ClaimTrigger on Claim (after insert, after update) {

    new ClaimTriggerHandler().run();
    
}