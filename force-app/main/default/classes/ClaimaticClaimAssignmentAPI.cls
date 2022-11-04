/*******************************************************************************************
* @Name         ClaimaticClaimAssignmentAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class has a call out service to unassign vendor added to a claim
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/
public class ClaimaticClaimAssignmentAPI{

    //public static User loadUserData(Idid) { //old
    public static User loadUserData(String id) {  //new
        return [SELECT Email,Username,Claimatic_Integration_ID__c FROM User WHERE Id = :id];
    }

    public static Claim loadClaimData(Id claimId) {
        return [SELECT Id FROM Claim WHERE Id = :claimId];
    }

    //public static Claim_Vendor__c loadVendorData(Id id) {   //old
    public static Claim_Vendor__c loadVendorData(String id) {   //new
        return [SELECT Id, Claimatic_Integration_ID__c FROM Claim_Vendor__c WHERE Id = :id];
    }

    @Future(Callout=true)
    public static void AssignClaim(List<Id> claimIds,List<Id> vendorIds,List<Id> userIds){
        if (claimIds.size() != userIds.size()) {
            throw new IllegalArgumentException('calling assignment api with mismatched counts of claims and users');
        }
        if (claimIds.size() != vendorIds.size()) {
            throw new IllegalArgumentException('calling assignment api with mismatched counts of claims and vendors');
        }
        String token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Log__c> logs = new List<Log__c>();
        Claim csRec = new Claim();
        Integer statusCode;
        String responseBody;
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            for(Integer i = 0; i < claimIds.size(); i++) {
                Id claimId = claimIds[i];
                Id vendorId = vendorIds[i];
                Id userId = userIds[i];
                Claim c = loadClaimData(claimId);
                Claim_Vendor__c vendor = new Claim_Vendor__c();
                //if (vendorId != null && vendorId != 'Null') {    //old
                String vendorSId  = String.valueOf(vendorId );    //new
                if (vendorSId  != '' && vendorSId  != null) {    //new
                    vendor = loadVendorData(vendorSId );
                }

                User u = new User();
                //if (userId != null && userId != 'Null') { // old
                String userSId = String.valueOf(userId ); //new
                if (userSId != '' && userSId != null ) { //new
                    u = loadUserData(userSId );
                }

                Http h = new Http();
                HttpRequest req = new HttpRequest();
                // unassign url is also used to assign
                req.setEndpoint(integ.Unassign_Claim_URL__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/xml');
                req.setHeader('Authorization', 'Bearer ' + token);
                String body = generateJSON(c, vendor, u);
                req.setBody(body);
                System.debug(body);
                HttpResponse res = new HttpResponse();
                if (!Test.isRunningTest()) {
                    res = h.send(req);
                    statusCode = res.getStatusCode();
                    responseBody = res.getBody();
                } else {
                    statusCode = 200;
                    StaticResource SR = new StaticResource();
                    SR = [SELECT Body FROM StaticResource WHERE Name = 'ClaimaticAuth'];
                    responseBody = SR.Body.toString();
                }

                System.debug(res.getBody());
                csRec = c;
                if (statusCode == 200) {
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Assignment API', integ.Unassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Success'));
                } else {
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Assignment API', integ.Unassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Error'));
                }
            }
        }catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimAssignmentAPI','AssignClaim','Case',csRec.Id,'N/A','Error'));
        }
        insert logs;
    }


    public static String generateJSON(Claim c,Claim_Vendor__c v,User u){
        ClaimaticClaimAssignmentRequest request = new ClaimaticClaimAssignmentRequest();
        request.claim_number = c.Id;
        if(u.Id != null){
            ClaimaticClaimAssignmentRequest.cls_assignments adjuster = new ClaimaticClaimAssignmentRequest.cls_assignments();
            adjuster.resource_email = '';
            adjuster.username = '';
            adjuster.resource_num =u.Claimatic_Integration_ID__c;
            adjuster.assignment_party_id = 1;
            adjuster.is_primary = 0;
            request.assignments.add(adjuster);
        }
        if(v.Id != null){
            ClaimaticClaimAssignmentRequest.cls_assignments vendor = new ClaimaticClaimAssignmentRequest.cls_assignments();
            vendor.resource_email = '';
            vendor.username = '';
            vendor.resource_num = v.Claimatic_Integration_ID__c;
            vendor.assignment_party_id = 0;
            vendor.is_primary = 0;
            request.assignments.add(vendor);
        }
        String RequestString = JSON.serialize(request);
        return RequestString;
    }
}