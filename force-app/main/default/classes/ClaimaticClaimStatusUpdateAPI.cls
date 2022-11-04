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
public class ClaimaticClaimStatusUpdateAPI {

    public static List<Claim> loadClaimData(Set<Id> claimIds) {
        return [SELECT Id,Status FROM Claim WHERE Id IN: claimIds];
    }

    static String baseXml = '<?xml version="1.0" encoding="UTF-8"?>' +
    '<Request>' +
        '<Claims>' +
            '<Claim ClaimNumber="{0}">' +
                '<Status Name="{1}"/>' +
            '</Claim>' +
        '</Claims>' +
    '</Request>';

    @Future(Callout=true)
    public static void UpdateClaim(Set<Id> claimIds){
        List<Log__c> logs = new List<Log__c>();
        Integration__c integ = Integration__c.getOrgDefaults();
        String token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Claim> newClaimList = loadClaimData(claimIds);
        Claim c;
        Integer statusCode;
        String responseBody;
        try{
            for(Claim claim : newClaimList) {
                //so it can be indicated in the outer catch block as to which claim failed
                c = claim;
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(integ.MultiClaim_Status_Update_URL__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/xml');
                req.setHeader('Authorization', 'Bearer ' + token);
                String body = generateXML(claim);
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
                if (statusCode == 200) {
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Status Update API', integ.MultiClaim_Status_Update_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Success'));
                } else {
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Status Update API', integ.MultiClaim_Status_Update_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Error'));
                }
            }
        }catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimStatusUpdateAPI','UpdateClaim','Case',c.Id,'N/A','Error'));
        }
        insert logs;
    }


    public static String generateXML(Claim c){
        List<Object> arguments = new List<Object>{c.Id, c.Status};
        return String.format(baseXml, arguments);
    }
}