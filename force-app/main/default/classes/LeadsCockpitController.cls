public class LeadsCockpitController {

    @AuraEnabled
    public static Boolean isUserAllowed() {

        Boolean res = false;

        String required_permission_set = Utils.getHippoSettings('Leads Cockpit Permission Set API Name');

        List<PermissionSetAssignment> psa = [SELECT Id, AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId =: UserInfo.getUserId() AND PermissionSet.Name =: required_permission_set];

        res = psa.size() > 0 ? true : false;
        
        return res;
    }
}