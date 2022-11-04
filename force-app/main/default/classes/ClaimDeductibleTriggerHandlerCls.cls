public class ClaimDeductibleTriggerHandlerCls {

    public static Boolean SKIP_TRIGGER = false;

    public void onAfterInsert(List<Claim_Deductible__c> lstClaimDeductible) {

        ClaimDeductibleTriggerHelperCls.updateSeletedBasedonName(lstClaimDeductible);
    }

    public void onBeforeUpdate(List<Claim_Deductible__c> lstClaimDeductible) {

        ClaimDeductibleTriggerHelperCls.verifyIfUpdateAllowed(lstClaimDeductible);
    }

    public void onAfterUpdate(List<Claim_Deductible__c> lstClaimDeductible) {

        ClaimDeductibleTriggerHelperCls.launchClaimPaymentItemFlows(lstClaimDeductible);
    }
}