public class Getpaymentstatus {
    public static Id logId = null;
    public static PaymentAuth_Integration_System__c payAuthSetting;
    @AuraEnabled
    Public static String AccessPaymentstatus(Id RecordId){
        try{
            payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults(); 
            paymentstatusAttributes PaymentstatusObj = new paymentstatusAttributes();
            PaymentstatusObj.PM_PaymentID = RecordId;
            
            String JSONRes = '{"session":"'+PaymentAuth.getSessionID()+'","str_json":"'+ JSON.serialize(JSON.serialize(PaymentstatusObj,true))+'"}';
            JSONRes = JSONRes.replace('""', '"');
            System.debug(JSONRes);
            
            String logWrap = '';
            String urlEncodedBody = Constants.method+'='+Constants.method_GetPaymentStatus+'&';
            urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
            urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
            urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSONRes, 'UTF-8'); 
            
            System.debug('urlEncodedBody=='+urlEncodedBody);       
            
            
            
            HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
            
            System.debug('response=='+response.getBody());
            if(response.getStatusCode() == 200){
                
                String responseBody = response.getBody(); 
                Map<String, String> results = (Map<String, String>) JSON.deserialize(response.getBody(), Map<String, String>.class);
                Paymentstatusresponsewrapper ResponObj = new Paymentstatusresponsewrapper(results);
                System.debug('ResponObj =='+results );                    
                System.debug('ResponObj1 =='+ResponObj );
                
                  if(ResponObj.Status == 'Error'){
                    Integration_Log__c errorLog = ErrorLogCapture.integrationLog('GetPaymentStatus',payAuthSetting.Base_URL__c,'POST','GetPaymentStatus','Transaction/Claim Payment',recordId,'Failure',null);
                    insert errorLog;
                    logId = errorLog.Id;
                    ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
                    }
                
                Transaction__c TransObj = new Transaction__c();
                TransObj.CR_Payment_ID__c = ResponObj.PM_PaymentID ;
                if(!String.IsEmpty(ResponObj.PM_Description))
                {
                    /* Need to clarify for saving this value into field at trasaction custom object*/
                    //TransObj.Amount__c = Decimal.valueOf(ResponObj.PM_Description);
                    System.debug('error=='+ results.get('PM_Description'));
                }
                
                TransObj.New_Method__c    = ResponObj.PM_PaymentMethod;
                TransObj.Payment_Status__c= ResponObj.PM_Status;
                TransObj.MethodID__c      = ResponObj.PMETHOD_Stored;
                TransObj.Status__c        = ResponObj.Status;
                System.debug('error=='+ results.get('Error Code'));
                if(!String.IsEmpty(ResponObj.Error_Code))
                {
                    TransObj.ErrorCode__c     = ResponObj.Error_Code;
                    TransObj.ErrorMessage__c  = ResponObj.Error_Message;
                    return 'Error: '+ TransObj.ErrorMessage__c;
                }
                //insert(TransObj);
                
                return ResponObj.PM_Status;
            }
            return null;
        }
        catch(DMLException ex){
            
            System.debug('Exceptionsoninsert=='+ ex.getMessage());
            System.assertEquals(ex.getMessage(), ex.getMessage());
            return 'Error: '+ex.getMessage();
            
        }
        
        
        
    }
    
    public class paymentstatusAttributes {
        
        public String PM_PaymentID;       
        
    }
    
    public class Paymentstatusresponsewrapper {
        public String PM_PaymentID;
        public String PM_Description;
        public String PM_Status;
        public String Status;
        public String PM_PaymentMethod;
        public string PMETHOD_Stored;
        public string Error_Code;
        public string Error_Message;
        
        public Paymentstatusresponsewrapper( Map<String,String> Spayment)
        {
            PM_PaymentID = (String)Spayment.get('PM_PaymentID');                    
            PM_Description = (String)Spayment.get('PM_Description');
            PM_Status = (String)Spayment.get('PM_Status');
            Status = (String)Spayment.get('Status');
            PM_PaymentMethod = (String)Spayment.get('PM_PaymentMethod');
            PMETHOD_Stored = (String)Spayment.get('PMETHOD_Stored');
            Error_Code = (String)Spayment.get('Error Code');
            Error_Message = (String)Spayment.get('Error Message');
        }
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
}