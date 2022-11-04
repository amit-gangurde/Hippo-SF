/**
 * Created by jonathanschwartz on 7/29/21.
 */

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
public class ClaimaticCaseAssignmentAPI {
    @future(callout=true)
    public static void AssignClaim(string caseId,string accountId,string UserId){
        Case oldCase = new Case();
        string token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Log__c> logs = new List<Log__c>();
        Case csRec = new Case();
        integer statusCode;
        string responseBody;
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            List<Case> newCaseList = new List<Case>();
            system.debug(caseId);
            newCaseList = [select id,Claim_Vendor__r.PersonEmail,
                    POD_Claim_ID__c,Claim_Vendor__r.Resource_Username__c,Claim_Vendor__r.Resource_Number__c,Claim_Vendor__r.Claimatic_Integration_ID__c
            from Case where id =: caseId];
            Case c = new Case();
            c = newCaseList[0];
            Account acc = new Account();
            if(accountId != Null && AccountId != 'Null')
                acc = [select Resource_Username__c,Resource_Number__c,Claimatic_Integration_ID__c,PersonEmail from Account where id=: accountId];

            user u = new User();
            if(UserId != Null && UserId != 'Null')
                u = [select Email,UserName,Claimatic_Integration_ID__c from User where id=: UserId];

            HTTP h = new HTTP();
            HTTPRequest req = new HTTPRequest();
            req.setEndpoint(integ.Unassign_Claim_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type','application/xml');
            req.setHeader('Authorization','Bearer '+token);
            req.setBody(generateJSON(c,acc,u));
            system.debug(generateJSON(c,acc,u));
            HTTPResponse res =new HttpResponse();
            if(!Test.isRunningTest()){
                res = h.send(req);
                statusCode = res.getStatusCode();
                responseBody = res.getBody();
            }else{
                statusCode = 200;
                StaticResource SR = new StaticResource();
                SR = [Select body from StaticResource where Name = 'ClaimaticAuth'];
                ResponseBody = SR.body.toString();
            }

            system.debug(res.getBody());
            csRec = c;
            if(statusCode == 200){
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Assignment API',integ.Unassign_Claim_URL__c,req.getBody(),responseBody,string.valueOf(statusCode),'Integration','Success'));
            }else{
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Assignment API',integ.Unassign_Claim_URL__c,req.getBody(),responseBody,string.valueOf(statusCode),'Integration','Error'));
            }
        }Catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimAssignmentAPI','AssignClaim','Case',csRec.id,'N/A','Error'));
        }
        insert logs;
    }


    public static string generateJSON(Case c,Account acc,User u){
        ClaimaticClaimAssignmentRequest request = new ClaimaticClaimAssignmentRequest();
        request.claim_number = c.id;
        if(u.id != Null){
            ClaimaticClaimAssignmentRequest.cls_assignments adjuster = new ClaimaticClaimAssignmentRequest.cls_assignments();
            adjuster.resource_email = '';
            adjuster.username = '';
            adjuster.resource_num =u.Claimatic_Integration_ID__c;
            adjuster.assignment_party_id = 1;
            adjuster.is_primary = 0;
            request.assignments.add(adjuster);
        }
        if(acc.id != Null){
            ClaimaticClaimAssignmentRequest.cls_assignments vendor = new ClaimaticClaimAssignmentRequest.cls_assignments();
            vendor.resource_email = '';
            vendor.username = '';
            vendor.resource_num =acc.Claimatic_Integration_ID__c;
            vendor.assignment_party_id = 0;
            vendor.is_primary = 0;
            request.assignments.add(vendor);
        }
        string RequestString = JSON.serialize(request);
        return RequestString;
    }
}