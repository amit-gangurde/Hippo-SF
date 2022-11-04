trigger ClaimDeductibleTrigger on Claim_Deductible__c (before insert, after insert, before update, after update) {

    if ( ClaimDeductibleTriggerHandlerCls.SKIP_TRIGGER ) return;

    ClaimDeductibleTriggerHandlerCls objClaimDedHandler = new ClaimDeductibleTriggerHandlerCls();

	if (Trigger.isInsert) {

        if (Trigger.isBefore) {
           
        }
        else {

            objClaimDedHandler.onAfterInsert(Trigger.New);
        }
    }
    else if (Trigger.isUpdate){

        if (Trigger.isBefore) {

            objClaimDedHandler.onBeforeUpdate(Trigger.new);
        }
        else {

            objClaimDedHandler.onAfterUpdate(Trigger.new);
        }
    }
}