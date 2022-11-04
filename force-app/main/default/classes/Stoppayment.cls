public class Stoppayment {
    
    public static PaymentAuth_Integration_System__c payAuthSetting;
    public static Id logId;
    
    @AuraEnabled
    Public static String Accessstoppayment(Id RecordId){
        
        try{
            payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults(); 
            
            
            StoppaymentAttributes StpayObj = new StoppaymentAttributes();
            StpayObj.PM_PaymentID = RecordId;
            StpayObj.PM_StopReason = 'Stop Payment';
            
            String JSONRes = '{"session":"'+PaymentAuth.getSessionID()+'","str_json":"'+ JSON.serialize(JSON.serialize(StpayObj,true))+'"}';
            JSONRes = JSONRes.replace('""', '"');
            System.debug(JSONRes);
            
            
            String logWrap = '';
            String urlEncodedBody = Constants.method+'='+Constants.method_StopPayment+'&';
            urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
            urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
            urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSONRes, 'UTF-8'); 
            
            System.debug('urlEncodedBody=='+urlEncodedBody);
            
            HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
            
            System.debug('response=='+response.getBody());
            
            if(response.getStatusCode() == 200){
                
                String responseBody = response.getBody();
              //  Integration_Log__c errorLog = ErrorLogCapture.integrationLog('Stoppayment',payAuthSetting.Base_URL__c,'POST','Accessstoppayment','Transaction/Claim Payment',recordId,'Success',null);
              //  insert errorLog;
              //  logId = errorLog.Id;
              //  ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
                
                //ResponObj = (Stoppaymentresponsewrapper) JSON.deserialize(response.getBody(), Stoppaymentresponsewrapper.class);
                Map<String, String> results = (Map<String, String>) JSON.deserialize(response.getBody(), Map<String, String>.class);
                Stoppaymentresponsewrapper ResponObj = new Stoppaymentresponsewrapper(results);
                Integration_Log__c errorLog;
                 if(ResponObj.Status == 'Error'){
                    errorLog = ErrorLogCapture.integrationLog('StopPayment',payAuthSetting.Base_URL__c,'POST','StopPayment','Transaction/Claim Payment',recordId,'Failure',null);
                    insert errorLog;
                    logId = errorLog.Id;
                    ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
                    }
                System.debug('ResponObj =='+results );                    
                System.debug('ResponObj1 =='+ResponObj ); 
                try {
                    
                    Transaction__c TransObj = new Transaction__c();
                    TransObj.Claim_Payment__c = RecordId;
                    TransObj.CR_Payment_ID__c = ResponObj.PM_PaymentID ;
                    if(!String.IsEmpty(ResponObj.PM_AmountUnloaded))
                    {
                        TransObj.Amount__c = Decimal.valueOf(ResponObj.PM_AmountUnloaded);
                        System.debug('error=='+ results.get('PM_AmountUnloaded'));
                    }
                    
                    TransObj.Payment_Status__c= ResponObj.PM_Status;
                    TransObj.Status__c        = ResponObj.Status;
                    System.debug('error=='+ results.get('Error Code'));
                    if(!String.IsEmpty(ResponObj.Error_Code))
                    {
                        TransObj.ErrorCode__c     = ResponObj.Error_Code;
                        TransObj.ErrorMessage__c  = ResponObj.Error_Message;
                    }
                    insert(TransObj);
                    
                    if(errorLog!=null && errorLog.Id!=null){
                    Integration_Log__c errorLogUpd = new   Integration_Log__c();
                    errorLogUpd.Id = errorLog.Id;
                    errorLogUpd.Transaction__c = transOBJ.Id;
                        update errorLogUpd;
                    }
                    
                    Claim_Payment__c cPay = new Claim_Payment__c();
                    cPay.Transaction_Status__c = ResponObj.PM_Status;
                    cPay.Id = RecordId;
                    update cPay;
                    
                    
                    if(!String.isBlank(ResponObj.Error_Message)){
                        return 'Error: '+ResponObj.Error_Message;
                    }
                    return ResponObj.PM_Status;
                }
                
                catch(DMLException ex)
                {
                    System.debug('Exceptionsoninsert=='+ ex.getMessage());
                    System.assertEquals(ex.getMessage(), ex.getMessage());
                    ErrorLogCapture.integrationErrorLog('Stoppayment',ex,logId,'Stoppayment','Error','DML');
                    return 'Error: '+ex.getMessage();
                    
                }  
            }else{
                  String responseBody = response.getBody();
                Integration_Log__c errorLog = ErrorLogCapture.integrationLog('Stoppayment',payAuthSetting.Base_URL__c,'POST','Accessstoppayment','Transaction/Claim Payment',recordId,'Success',null);
                insert errorLog;
                logId = errorLog.Id;
                ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
            }
            return null;
        }catch(Exception ex){
           // PaymentAuth.endSession();
           System.debug('EX::'+ex.getMessage());
               
            ErrorLogCapture.integrationErrorLog('Stoppayment',ex,logId,'Stoppayment','Error','DML');
            return 'Error: '+ex.getMessage();
        }
        
        
        
    }
    
    
    public class StoppaymentAttributes {
        
        public String PM_PaymentID;
        public String PM_StopReason;
        
    }
    
    public class Stoppaymentresponsewrapper {
        
        public String PM_PaymentID;
        public String PM_AmountUnloaded;
        public String PM_Status;
        public String Status;
        public string Error_Code;
        public string Error_Message;
        
        public Stoppaymentresponsewrapper( Map<String,String> Spayment)
        {
            PM_PaymentID = (String)Spayment.get('PM_PaymentID');
            PM_AmountUnloaded = (String)Spayment.get('PM_AmountUnloaded');
            PM_Status = (String)Spayment.get('PM_Status');
            Status = (String)Spayment.get('Status');
            Error_Code = (String)Spayment.get('Error Code');
            Error_Message = (String)Spayment.get('Error Message');
        }
    }
    
    
    
    
}