public class CallUnassignAllUsersCtrl {
    public Case cs;
    public ApexPages.StandardController ctrl;
    public CallUnassignAllUsersCtrl(ApexPages.StandardController controller) {
        cs = new Case();
        ctrl = controller;
    }
    
    public void callUnassignAll(){
        cs = (case)ctrl.getRecord();
        cs.Claims_Adjuster__c = null;
        cs.Claim_Vendor__c = null;
        update cs;
        set<id> caseIds = new set<id>();
        caseIds.add(cs.id);
        ClaimaticClaimUnassignmentAllAPI.UnassignAllClaim(caseIds);        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Unassign users on claim has been initiated successfully.'));  
    }
    
    public void callUnassignVendor(){
        cs = (case)ctrl.getRecord();
        string AccountId = cs.Claim_Vendor__c;       
        cs.Claim_Vendor__c = null;
        update cs;
        set<id> caseIds = new set<id>();
        caseIds.add(cs.id);
        ClaimaticClaimUnassignmentAPI.UnassignClaim(caseIds,AccountId);        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Unassign Vendor on claim has been initiated successfully.'));  
    }
    
    
    public void callUnassignAdjustor(){
        cs = (case)ctrl.getRecord();
        string UserId = cs.Claims_Adjuster__c;       
        cs.Claims_Adjuster__c = null;
        update cs;
        set<id> caseIds = new set<id>();
        caseIds.add(cs.id);
        ClaimaticClaimAdjustorUnassignmentAPI.UnassignAdjustorClaim(caseIds,UserId);        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Unassign Adjustor on claim has been initiated successfully.'));  
    }
    
    public void callUnassignAllUserNoResponse(){
        callUnassignVendor();
        callUnassignAdjustor();
    }
    

}