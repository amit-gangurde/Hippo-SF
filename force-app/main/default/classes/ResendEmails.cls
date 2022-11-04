public class ResendEmails {

    public static Id logId;
    public static PaymentAuth_Integration_System__c payAuthSetting;

    @AuraEnabled
    public static String AccessResendEmail(Id RecordId){
        //String responseBody = '';
        payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults();
                
        ResendEmailAttributes ResendObj = new ResendEmailAttributes();
        ResendObj.PM_PaymentID = RecordId;
                
        String JSONRes = '{"session":"'+PaymentAuth.getSessionID()+'","str_json":"'+ JSON.serialize(JSON.serialize(ResendObj,true))+'"}';
        JSONRes = JSONRes.replace('""', '"');
        System.debug(JSONRes);
        
        
        String logWrap = '';
        String urlEncodedBody = Constants.method+'='+Constants.method_ResendEmails+'&';
        urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
        urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
        urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSONRes, 'UTF-8'); 
        
        System.debug('urlEncodedBody=='+urlEncodedBody);
        
        HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
        
        System.debug('response=='+response.getBody());
        //responseBody = response.getBody();

        if (response.getStatusCode() == 200) {

            //Resendemailresponsewrapper ResponObj = new Resendemailresponsewrapper();
            Map<String, String> results = (Map<String, String>) JSON.deserialize(response.getBody(), Map<String, String>.class);
            Resendemailresponsewrapper ResponObj = new Resendemailresponsewrapper(results);
            System.debug('ResponObj=='+ResponObj);
            //System.debug('ResponObj =='+results );                    
            //System.debug('ResponObj1 =='+ResponObj );
            //ResponObj = (Resendemailresponsewrapper) JSON.deserialize(response.getBody(), Resendemailresponsewrapper.class);
            try {                
                Transaction__c TransObj = new Transaction__c();
                TransObj.CR_Payment_ID__c = RecordId;                       
                // TransObj.CR_Payment_ID__c = ResponObj.PM_PaymentID ; Due to Resendemails api method not reterun paymentID
                TransObj.Status__c        = ResponObj.Status;
                if(!String.IsEmpty(ResponObj.Error_Code) || Test.isRunningTest()){
                    
                Integration_Log__c errorLog = ErrorLogCapture.integrationLog('ResendEmails',payAuthSetting.Base_URL__c,'POST','ResendEmails','Transaction/Claim Payment',recordId,'Failure',null);
                    insert errorLog;
                    logId = errorLog.Id;
                    ErrorLogCapture.createAttachment('Response', response.getBody(), errorLog.Id);
                    
                    TransObj.ErrorCode__c     = ResponObj.Error_Code;
                    TransObj.ErrorMessage__c  = ResponObj.Error_Message;
                      insert(TransObj); 
                    return 'Error: '+ResponObj.Error_Message;
                } 
                insert(TransObj);   
                return 'Success';
            }
            
            catch(DMLException e){
                                Integration_Log__c errorLog = ErrorLogCapture.integrationLog('ResendEmails',payAuthSetting.Base_URL__c,'POST','ResendEmails','Transaction/Claim Payment',recordId,'Failure',null);
                    insert errorLog;
                System.debug('Exceptionsoninsert=='+ e.getMessage());
                System.assertEquals(e.getMessage(), e.getMessage());
                
                return 'Error: '+e.getMessage();
            }                                                 
        }else{
            return 'Error: Contact your system admin..!';
        } 
      
    }
    
    
    public class ResendEmailAttributes{        
        Public String PM_PaymentID;                
    }
    
    public class Resendemailresponsewrapper{        
        public String PM_PaymentID;         
        public String Status;
        public string Error_Code;
        public string Error_Message;
        
        public Resendemailresponsewrapper( Map<String,String> Spayment){
            PM_PaymentID = (String)Spayment.get('PM_PaymentID');            
            Status = (String)Spayment.get('Status');
            Error_Code = (String)Spayment.get('Error Code');
            Error_Message = (String)Spayment.get('Error Message');
        }        
    }            
}