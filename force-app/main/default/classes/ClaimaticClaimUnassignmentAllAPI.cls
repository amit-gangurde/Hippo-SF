/*******************************************************************************************
* @Name         ClaimaticClaimUnassignmentAllAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class contains to unassign all parties from a case
                in claimatic system
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/
public class ClaimaticClaimUnassignmentAllAPI {
    @Future(Callout=true)
    public static void UnassignAllClaim(Set<Id> claimIds){
        List<Log__c> logs = new List<Log__c>();
        Id faultId;
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            Http h = new Http();
            String token = ClaimaticAuthenticationAPI.AuthenticationService();
            for(Id claimId : claimIds) {
                faultId = claimId;
                HttpRequest req = new HttpRequest();
                req.setEndpoint(integ.Unassign_Claim_URL__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/xml');
                req.setHeader('Authorization', 'Bearer ' + token);
                req.setBody(generateJSON(claimId));
                HttpResponse res = new HttpResponse();
                res = h.send(req);
                System.debug(res.getBody());
                if (res.getStatusCode() == 200) {
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment All API', integ.Unassign_Claim_URL__c, req.getBody(), res.getBody(), String.valueOf(res.getStatusCode()), 'Integration', 'Success'));
                } else {
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment All API', integ.Unassign_Claim_URL__c, req.getBody(), res.getBody(), String.valueOf(res.getStatusCode()), 'Integration', 'Error'));
                }
            }
        }catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimUnassignmentAllAPI','UnassignAllClaim','Claim',faultId,'N/A','Error'));
        }
        insert logs;
    }


    public static String generateJSON(Id id){
        String RequestString = String.format('\'{\'"claim_number": "{0}"\'}\'', new List<Object> {id});
        System.debug(RequestString);
        return RequestString;
    }
}