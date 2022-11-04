/**
 * Created by jonathanschwartz on 7/29/21.
 */

/*******************************************************************************************
* @Name         ClaimaticClaimStatusUpdateAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class contains callout service for updating claim status
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/
public class ClaimaticCaseStatusUpdateAPI {
    @future(callout=true)
    public static void UpdateClaim(set<id> caseIds){
        List<Log__c> logs = new List<Log__c>();
        Integration__c integ = Integration__c.getOrgDefaults();
        string token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Case> newCaseList = new List<Case>();
        newCaseList = [select id,POD_Claim_ID__c,status from Case where id IN: caseIds];
        case c = new case();
        integer statusCode;
        string responseBody;
        try{
            c = newCaseList[0];
            HTTP h = new HTTP();
            HTTPRequest req = new HTTPRequest();
            req.setEndpoint(integ.MultiClaim_Status_Update_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type','application/xml');
            req.setHeader('Authorization','Bearer '+token);
            req.setBody(generateXML(c));
            system.debug(generateXML(c));
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
            if(statusCode == 200){
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Status Update API',integ.MultiClaim_Status_Update_URL__c,req.getBody(),responseBody,string.valueOf(StatusCode),'Integration','Success'));
            }else{
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Status Update API',integ.MultiClaim_Status_Update_URL__c,req.getBody(),responseBody,string.valueOf(StatusCode),'Integration','Error'));
            }
        }catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimStatusUpdateAPI','UpdateClaim','Case',c.id,'N/A','Error'));
        }
        insert logs;
    }


    public static string generateXML(Case c){
        string xmlString = '<?xml version="1.0" encoding="UTF-8"?><Request><Claims>';
        xmlString = xmlString + '<Claim ClaimNumber="'+c.id+'"><Status Name="'+c.status+'"/>';
        xmlString = xmlString + '</Claim></Claims></Request>';
        return xmlString;
    }
}