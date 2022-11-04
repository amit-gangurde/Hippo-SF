/**
 * Created by jonathanschwartz on 7/29/21.
 */

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
public class ClaimaticCaseUnassignmentAllAPI {
    @future(callout=true)
    public static void UnassignAllClaim(set<id> caseIds){
        List<Log__c> logs = new List<Log__c>();
        Case csRec = new Case();
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            HTTP h = new HTTP();
            string token = ClaimaticAuthenticationAPI.AuthenticationService();
            List<Case> newCaseList = new List<Case>();
            newCaseList = [select id,Claim_Vendor__r.PersonEmail,
                    POD_Claim_ID__c,Claim_Vendor__r.Resource_Username__c,Claim_Vendor__r.Resource_Number__c,Claim_Vendor__r.Claimatic_Integration_ID__c,
                    Claim_Vendor__c,Claims_Adjuster__c
            from Case where id IN: caseIds];
            HTTPRequest req = new HTTPRequest();
            req.setEndpoint(integ.Unassign_Claim_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type','application/xml');
            req.setHeader('Authorization','Bearer '+token);
            req.setBody(generateJSON(newCaseList));
            HTTPResponse res =new HttpResponse();
            res = h.send(req);
            system.debug(res.getBody());
            csRec = newCaseList[0];
            if(res.getStatusCode() == 200){
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment All API',integ.Unassign_Claim_URL__c,req.getBody(),res.getBody(),string.valueOf(res.getStatusCode()),'Integration','Success'));
            }else{
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment All API',integ.Unassign_Claim_URL__c,req.getBody(),res.getBody(),string.valueOf(res.getStatusCode()),'Integration','Error'));
            }
        }Catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimUnassignmentAllAPI','UnassignAllClaim','Case',csRec.id,'N/A','Error'));
        }
        insert logs;
    }


    public static string generateJSON(list<case> newCaseList){
        Case CaseRec = new case();
        CaseRec = newCaseList[0];
        string RequestString = '{"claim_number": "'+caseRec.id+'"}';
        system.debug(requestString);
        return RequestString;
    }
}