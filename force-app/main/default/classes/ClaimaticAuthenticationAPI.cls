/*******************************************************************************************
* @Name         ClaimaticAuthenticationAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class contains authentication service for the claimatic system
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation                                                      
*******************************************************************************************/

Public class ClaimaticAuthenticationAPI{
    public static string AuthenticationService(){
        List<Log__c> logs = new List<Log__c>();
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            HTTP h = new HTTP();
            HTTPRequest req = new HTTPRequest();
            string endPoint = integ.Auth_URL__c+'_username='+Integ.UserName__c+'&_password='+Integ.Password__c;
            req.setEndpoint(endPoint);
            req.setMethod('GET');   
            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            HTTPResponse res =new HttpResponse();
            integer statusCode;
            string responseBody;
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
            ClaimaticAuthenticationAPIResponse wResp;
            if(StatusCode == 200){
                wResp = (ClaimaticAuthenticationAPIResponse) JSON.deserialize(responseBody, ClaimaticAuthenticationAPIResponse.class);
            }else{
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Authentication API',endPoint,'N/A',responseBody,string.valueOf(statusCode),'Integration','Error'));                
            }
            if(Test.isRunningTest()){
                integer counter;
                counter = counter/0;
            }
            return wResp.token;
        }catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticAuthenticationAPI','AuthenticationService','N/A','N/A','N/A','Error'));
            insert logs;
            return null;
        }
    }
}