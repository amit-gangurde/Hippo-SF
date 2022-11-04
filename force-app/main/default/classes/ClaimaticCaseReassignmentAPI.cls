/**
 * Created by jonathanschwartz on 7/29/21.
 */

/*******************************************************************************************
* @Name         ClaimaticClaimReassignmentAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class contains REST service for Reassigning vendors in claim
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/

public class ClaimaticCaseReassignmentAPI {
    @future(callout=true)
    public static void ReassignClaim(Map<string,string> oldCaseMap,set<id> caseIds,string type){
        Case csRec = new Case();
        List<Log__c> logs = new List<Log__c>();
        integer statusCode;
        string responseBody;
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            HTTP h = new HTTP();
            string token = ClaimaticAuthenticationAPI.AuthenticationService();
            List<Case> newCaseList = new List<Case>();
            newCaseList = [select id,Claim_Vendor__r.PersonEmail,
                    POD_Claim_ID__c,Claim_Vendor__r.Resource_Username__c,Claim_Vendor__r.Resource_Number__c,Claim_Vendor__r.Claimatic_Integration_ID__c,
                    Claims_Adjuster__r.Claimatic_Integration_ID__c
            from Case where id IN: caseIds];
            HTTPRequest req = new HTTPRequest();
            req.setEndpoint(integ.Reassign_Claim_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type','application/xml');
            req.setHeader('Authorization','Bearer '+token);
            req.setBody(generateJSON(oldCaseMap,newCaseList,type));
            system.debug(generateJSON(oldCaseMap,newCaseList,type));
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
            if(StatusCode == 200){
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Reassignment API',integ.Reassign_Claim_URL__c,req.getBody(),responseBody,string.valueOf(statusCode),'Integration','Success'));
            }else{
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Reassignment API',integ.Reassign_Claim_URL__c,req.getBody(),responseBody,string.valueOf(statusCode),'Integration','Error'));
            }
            csRec = newCaseList[0];
        }Catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimReassignmentAPI','ReassignClaim','Case',csRec.id,'N/A','Error'));
            insert logs;
        }
    }


    public static string generateJSON(Map<string,string> oldCaseMap,list<case> newCaseList,string type){
        Case oldCase = new case();
        system.debug(newCaseList[0].id);
        oldCase  = (case)System.JSON.deserialize(oldCaseMap.get(newCaseList[0].id), case.class);

        Account acc = new Account();
        if(type == 'Vendor')
            acc = [select PersonEmail,Resource_Username__c,Claimatic_Integration_ID__c from account where id =: oldCase.Claim_Vendor__c];
        User u = new User();
        if(type == 'Adjuster')
            u = [select Email,UserName,Claimatic_Integration_ID__c from User where id=: oldCase.Claims_Adjuster__c];


        ClaimaticClaimReassignmentRequest request = new ClaimaticClaimReassignmentRequest();
        request.claim_number = newCaseList[0].id;
        ClaimaticClaimReassignmentRequest.cls_assignments assignment = new ClaimaticClaimReassignmentRequest.cls_assignments();
        if(type == 'Vendor'){
            //assignment.resource_email = newCaseList[0].Claim_Vendor__r.PersonEmail;
            assignment.resource_email = '';
            //assignment.username = newCaseList[0].Claim_Vendor__r.Resource_Username__c;
            assignment.username = '';
            assignment.resource_num =newCaseList[0].Claim_Vendor__r.Claimatic_Integration_ID__c;
            assignment.resource_id=newCaseList[0].Claim_Vendor__r.Claimatic_Integration_ID__c;
            assignment.assignment_party_id = 1;
            assignment.is_primary = 1;
            //assignment.to_remove_resource_email=acc.PersonEmail;
            //assignment.to_remove_resource_username=acc.Resource_Username__c;
            assignment.to_remove_resource_email='';
            assignment.to_remove_resource_username='';
            assignment.to_remove_resource_num=acc.Claimatic_Integration_ID__c;
            assignment.to_remove_resource_id=acc.Claimatic_Integration_ID__c;
            request.assignments.add(assignment);
        }else{
            //assignment.resource_email = newCaseList[0].Claim_Vendor__r.PersonEmail;
            assignment.resource_email = '';
            //assignment.username = newCaseList[0].Claim_Vendor__r.Resource_Username__c;
            assignment.username = '';
            assignment.resource_num =newCaseList[0].Claims_Adjuster__r.Claimatic_Integration_ID__c;
            assignment.resource_id=newCaseList[0].Claims_Adjuster__r.Claimatic_Integration_ID__c;
            assignment.assignment_party_id = 1;
            assignment.is_primary = 1;
            //assignment.to_remove_resource_email=acc.PersonEmail;
            //assignment.to_remove_resource_username=acc.Resource_Username__c;
            assignment.to_remove_resource_email='';
            assignment.to_remove_resource_username='';
            assignment.to_remove_resource_num=u.Claimatic_Integration_ID__c;
            assignment.to_remove_resource_id=u.Claimatic_Integration_ID__c;
            request.assignments.add(assignment);
        }
        string RequestString = JSON.serialize(request);
        return RequestString;
    }
}