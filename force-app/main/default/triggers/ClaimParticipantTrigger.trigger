trigger ClaimParticipantTrigger on ClaimParticipant (after update) {
    ClaimParticipantTriggerHandler.handleClaimParticipant(trigger.new,trigger.oldMap);
}