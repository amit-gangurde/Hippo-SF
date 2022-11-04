public class GetDocument {

    public static PaymentAuth_Integration_System__c payAuthSetting;
    public static Id logId;
    @AuraEnabled
    public static String AccessGetDocument(Id RecordId){

        String sessionId = PaymentAuth.getSessionID();
        return accessGetDocumentBase(RecordId, sessionId);
    }
    @InvocableMethod
    public static void AccessGetDocumentFlow(List<Claim_Payment__c> claimPaymentLst){
        if(claimPaymentLst.size()>0){
            Id RecordId = claimPaymentLst[0].id;
     futureCallout(RecordId);
             }
    }
    @future(callout=true)
    public static void futureCallout(id RecordId){
           String sessionId = PaymentAuth.getSessionID();
        accessGetDocumentBase(RecordId, sessionId);
    }
    public static String accessGetDocumentBase(Id RecordId, String sessionId){

        try{
            payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults();
            GetDocumentAttribute GetDocObj = new GetDocumentAttribute();
            GetDocObj.PM_PaymentID = RecordId;

            String JSONRes = '{"session":"'+sessionId+'","str_json":"'+ JSON.serialize(JSON.serialize(GetDocObj,true))+'"}';
            JSONRes = JSONRes.replace('""', '"');
            System.debug(JSONRes);

            String logWrap = '';

            String urlEncodedBody = CalloutHelper.buildMethodCall(Constants.method_GetDocument, JSONRes);
            System.debug('urlEncodedBody=='+urlEncodedBody);

            HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);

            String responseBody = response.getBody().replace('\\', '');
            responseBody = responseBody.replace('"{', '{');
            responseBody = responseBody.replace('}"', '}');
            System.debug('response=='+response.getBody().replace('\\', ''));

            if(response.getStatusCode() == 200){

                // Integration_Log__c errorLog = ErrorLogCapture.integrationLog('GetDocument',payAuthSetting.Base_URL__c,'POST','GetDocument','Transaction/Claim Payment',recordId,'Success',null);
                // insert errorLog;
                // logId = errorLog.Id;
                // ErrorLogCapture.createAttachment('Response',response.getBody(),errorLog.Id);

                Map<String, String> results = (Map<String, String>) JSON.deserialize(responseBody, Map<String, String>.class);
                GetDocumentresponsewrapper ResponObj = new GetDocumentresponsewrapper(results);
                Integration_Log__c errorLog;
                if(ResponObj.Status == 'Error'){
                    errorLog = ErrorLogCapture.integrationLog('GetDocument',payAuthSetting.Base_URL__c,'POST','GetDocument','Transaction/Claim Payment',recordId,'Failure',null);
                    insert errorLog;
                    logId = errorLog.Id;
                    ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
                }

                Transaction__c TransObj = new Transaction__c();
                TransObj.CR_Payment_ID__c = ResponObj.PM_PaymentID ;

                TransObj.Status__c        = ResponObj.Status;
                if(!String.isEmpty(ResponObj.Error_Code))
                {
                    TransObj.ErrorCode__c     = ResponObj.Error_Code;
                    TransObj.ErrorMessage__c  = ResponObj.Error_Message;
                }
                insert(TransObj);

                //Create Document
                ContentVersion cv = new ContentVersion();
                cv.Title = ResponObj.PM_Filename;
                cv.PathOnClient = ResponObj.PM_Filename;
                if(!Test.isRunningTest()){
                cv.VersionData = EncodingUtil.base64Decode(ResponObj.PM_Document);
                }else{
                  cv.VersionData = EncodingUtil.base64Decode('Test');  
                      cv.Title = 'Test';
                      cv.PathOnClient ='\test';
                }
                cv.IsMajorVersion = true;
                insert cv;

                //Get Content Documents
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

                //Create ContentDocumentLink
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = RecordId;
                cdl.ContentDocumentId = conDocId;
                cdl.ShareType = 'V';
                insert cdl;
                if(errorLog!=null && errorLog.Id!=null){
                    Integration_Log__c errorLogUpd = new   Integration_Log__c();
                    errorLogUpd.Id = errorLog.Id;
                    errorLogUpd.Transaction__c = TransObj.Id;
                    update errorLogUpd;
                }
                if(!String.isEmpty(ResponObj.Error_Code))
                {
                    return 'Error: '+ResponObj.Error_Message;
                }
            }else{
                Integration_Log__c errorLog = ErrorLogCapture.integrationLog('GetDocument',payAuthSetting.Base_URL__c,'POST','GetDocument','Transaction/Claim Payment',recordId,'Success',null);
                insert errorLog;
                logId = errorLog.Id;
                ErrorLogCapture.createAttachment('Response',response.getBody(),errorLog.Id);
            }

        }
        catch(DmlException ex){
            System.debug('Exceptionsoninsert=='+ ex.getMessage());
                System.debug('geline number=='+ ex.getLineNumber());
            System.assertEquals(ex.getMessage(), ex.getMessage());
            return 'Error: '+ex.getMessage();
        }
        return 'Success';
    }

    public class GetDocumentAttribute{

        public String PM_PaymentID;
    }

    public class GetDocumentresponsewrapper {
        public String PM_PaymentID;
        public String PM_Filename;
        public String PM_Document_Link;
        public String Status;
        public String Error_Code;
        public String Error_Message;
        public String PM_Document;

        public GetDocumentresponsewrapper ( Map<String,String> SObj) {
            PM_PaymentID = (String)SObj.get('PM_PaymentID');
            PM_Filename = (String)SObj.get('PM_Filename');
            PM_Document_Link = (String)SObj.get('PM_Document_Link');
            Status = (String)SObj.get('Status');
            Error_Code = (String)SObj.get('Error Code');
            Error_Message = (String)SObj.get('Error Message');
            PM_Document = (String)SObj.get('PM_Document');
        }
    }
}