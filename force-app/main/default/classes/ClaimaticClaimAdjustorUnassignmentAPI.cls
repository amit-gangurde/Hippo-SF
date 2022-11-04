/*******************************************************************************************
* @Name         ClaimaticClaimAdjustorUnassignmentAPI
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
public class ClaimaticClaimAdjustorUnassignmentAPI {

    public static User loadUserData(Id id) {
        return [SELECT Email,Username,Claimatic_Integration_ID__c FROM User WHERE Id=: id];
    }

    public static List<Claim> loadClaimData(List<Id> claimIds) {
        return [SELECT Id,Claim_Adjuster__c FROM Claim WHERE Id IN :claimIds];
    }
 
    @Future(Callout=true)
    public static void UnassignAdjustorClaim(List<Id> claimIds, List<Id> UserIds){
        if (claimIds.size() != UserIds.size()) {
            throw new IllegalArgumentException('calling unassignment api with mismatched counts of claims and users');
        }
        String token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Log__c> logs = new List<Log__c>();
        Claim csRec = new Claim();
        Integer statusCode;
        String responseBody;
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            List<Claim> newClaimList = loadClaimData(claimIds);
            for(Integer i = 0; i < newClaimList.size(); i++) {
                Claim c = newClaimList[i];
                Id userId = UserIds[i];
                System.debug('===UserIds==='+UserIds);
                 System.debug('===Claim==='+c);
                 System.debug('===claimIds==='+claimIds);
            //*** Modify @ 12/01/21 ***    if (c.Claim_Adjuster__c.equals(userId)) {
          //*** Modify @ 12/01/21 ***   if (c.Claim_Adjuster__c!=null && c.Claim_Adjuster__c.equals(userId)) { ***//
                    User u = loadUserData(userId);
                    // so we know which one failed if we hit an exception
                    csRec = c;
                    Http h = new Http();
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(integ.Unassign_Claim_URL__c);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/xml');
                    req.setHeader('Authorization', 'Bearer ' + token);
                    req.setBody(generateJSON(c, u));
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
                    if (statusCode == 200) {
                        //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                        logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Adjustor Unassignment API', integ.Unassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Success'));
                    } else {
                        //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                        logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Adjustor Unassignment API', integ.Unassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Error'));
                    }
                 //*** Modify @ 12/01/21 ***}
            }
        }catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimAdjustorUnassignmentAPI','UnassignAdjustorClaim','Case',csRec.Id,'','Error'));
        }
        insert logs;
    }


    public static String generateJSON(Claim c,User u){
        ClaimaticClaimUnassignmentRequest request = new ClaimaticClaimUnassignmentRequest();
        request.claim_number = c.Id;
        ClaimaticClaimUnassignmentRequest.cls_assignments assignment = new ClaimaticClaimUnassignmentRequest.cls_assignments();
        // assignment.resource_email = 'EWeigend@claimatic.com';//u.Email;
        assignment.resource_email = '';
        // assignment.username = u.UserName;
        assignment.username = '';
        assignment.resource_num = u.Claimatic_Integration_ID__c;
        assignment.assignment_party_id = 1;
        //assignment.is_primary = 0;
        request.unassignments.add(assignment);
        String RequestString = JSON.serialize(request);
        return RequestString;
    }
}