/**
 * Created by jonathanschwartz on 7/29/21.
 */

/*******************************************************************************************
* @Name         ClaimaticClaimUnassignmentAPI
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
public class ClaimaticCaseUnassignmentAPI {
    @future(callout=true)
    public static void UnassignClaim(set<id> caseIds,string accountId){
        Case oldCase = new Case();
        string token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Log__c> logs = new List<Log__c>();
        Case csRec = new Case();
        integer statusCode;
        string responseBody;
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            List<Case> newCaseList = new List<Case>();
            newCaseList = [select id,Claim_Vendor__r.PersonEmail,
                    POD_Claim_ID__c,Claim_Vendor__r.Resource_Username__c,Claim_Vendor__r.Resource_Number__c,Claim_Vendor__r.Claimatic_Integration_ID__c
            from Case where id IN: caseIds];
            Case c = new Case();
            c = newCaseList[0];
            Account acc = new Account();
            acc = [select Resource_Username__c,Resource_Number__c,Claimatic_Integration_ID__c,PersonEmail from Account where id=: accountId];
            HTTP h = new HTTP();
            HTTPRequest req = new HTTPRequest();
            req.setEndpoint(integ.Unassign_Claim_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type','application/xml');
            req.setHeader('Authorization','Bearer '+token);
            req.setBody(generateJSON(c,acc));
            system.debug(generateJSON(c,acc));
            HTTPResponse res =new HttpResponse();
            if(!test.isRunningTest()){
                res = h.send(req);
                responseBody = res.getBody();
                statusCode = res.getStatusCode();
            }else{
                statusCode = 200;
                StaticResource SR = new StaticResource();
                SR = [Select body from StaticResource where Name = 'ClaimaticAuth'];
                ResponseBody = SR.body.toString();
            }
            csRec = c;
            if(statusCode == 200){
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment API',integ.Unassign_Claim_URL__c,req.getBody(),responseBody,string.valueOf(StatusCode),'Integration','Success'));
            }else{
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment API',integ.Unassign_Claim_URL__c,req.getBody(),responseBody,string.valueOf(StatusCode),'Integration','Error'));
            }
        }Catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimUnassignmentAPI','UnassignClaim','Case',csRec.id,'N/A','Error'));
        }
        insert logs;
    }


    public static string generateJSON(Case c,Account acc){
        ClaimaticClaimUnassignmentRequest request = new ClaimaticClaimUnassignmentRequest();
        request.claim_number = c.id;
        ClaimaticClaimUnassignmentRequest.cls_assignments assignment = new ClaimaticClaimUnassignmentRequest.cls_assignments();
        assignment.resource_email = acc.PersonEmail;
        assignment.username = acc.Resource_Username__c;
        assignment.resource_num =acc.Claimatic_Integration_ID__c;
        assignment.assignment_party_id = 0;
        assignment.is_primary = 0;
        request.unassignments.add(assignment);
        string RequestString = JSON.serialize(request);
        return RequestString;
    }
}