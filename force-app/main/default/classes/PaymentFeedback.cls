@RestResource(urlMapping='/PaymentFeedbackTrigger/*')
global class PaymentFeedback {
    public static Id logId;
    @HttpPost
    global static String getPayment(){
        paymentResWrapper payWrapRes = new paymentResWrapper();
        try{
            String requestJSON = RestContext.request.requestBody.toString();

            String responseBody = requestJSON;
            Integration_Log__c errorLog = ErrorLogCapture.integrationLog('PaymentFeedback','Call From OneInc','POST','getPayment','Transaction/Claim Payment',null,'Success',null);
            insert errorLog;
            logId = errorLog.Id;
            ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);

            System.debug('requestJSON####'+requestJSON);
            paymentWrapper payWrap = (paymentWrapper) JSON.deserialize(requestJSON,paymentWrapper.class);
            payWrapRes.PM_IP_PaymentID = payWrap.PM_IP_PaymentID;
            payWrapRes.Status = 'Success';
            System.debug('payWrap####'+payWrap);

            Transaction__c transOBJ = new Transaction__c();
            transOBJ.Amount__c =  payWrap.PM_Amount!=null?Decimal.valueOf(payWrap.PM_Amount):null;
            transOBJ.CheckNumber__c =  payWrap.PM_CheckNumber!=null?String.valueOf(payWrap.PM_CheckNumber):null;
            transOBJ.Claim_Payment__c = [SELECT ID FROM Claim_Payment__c WHERE ID =: payWrap.PM_CR_PaymentID]?.ID;
            transOBJ.Cleared_Date__c =  payWrap.PM_ClearedDate!=null?Date.valueOf(payWrap.PM_ClearedDate):null;
            transOBJ.CR_Payment_ID__c = payWrap.PM_CR_PaymentID;
            transOBJ.ErrorCode__c =  payWrap.PM_ErrorCode;
            transOBJ.ErrorMessage__c = payWrap.PM_ErrorMessage;
            transOBJ.EscheatDate__c = payWrap.PM_EscheatDate!=null?Date.valueOf(payWrap.PM_EscheatDate):null;
            transOBJ.Funded__c =  payWrap.PM_Funded;
            transOBJ.IP_PaymentID__c = payWrap.PM_IP_PaymentID;
            transOBJ.MailTracking_Number__c =  payWrap.PM_MailTrackingNumber;
            transOBJ.MethodID__c =   payWrap.PM_MethodID;
            transOBJ.Method_Last4Digit__c = payWrap.PM_Method_Last4Digit!=null?String.valueOf(payWrap.PM_Method_Last4Digit):null;
            transOBJ.New_Method__c =  payWrap.PM_New_Method;
            transOBJ.Original_Method__c =  payWrap.PM_Orig_Method;
            transOBJ.PaidDate__c =  payWrap.PM_PaidDate!=null?Date.valueOf(payWrap.PM_PaidDate):null;
            transOBJ.ReIssue__c =  payWrap.PM_ReIssue;
            transOBJ.Selection__c = payWrap.PM_Selection;
            transOBJ.Status__c = 'Success';
            transOBJ.Payment_Status__c =  payWrap.PM_Status;
            transOBJ.incoming_From_Webhook__c = true;
            insert transOBJ;

            if(transOBJ.Claim_Payment__c != null){
                Claim_Payment__c claim = new Claim_Payment__c();
                claim.Id = transOBJ.Claim_Payment__c;
                claim.Transaction_Status__c = payWrap.PM_Status;
                update claim;
            }
            Integration_Log__c errorLogUpd = new   Integration_Log__c();
            errorLogUpd.Id = errorLog.Id;
            errorLogUpd.Transaction__c = transOBJ.Id;
            update errorLogUpd;

        }catch(Exception ex){
            ErrorLogCapture.integrationErrorLog('PaymentFeedback',ex,logId,'Stoppayment','Error','DML');
            payWrapRes.Status = 'Error '+ex.getMessage();
        }

        return JSON.serialize(payWrapRes);
    }
    @AuraEnabled
    public static auraWrapper getWebHookInfo(Id recordId){
        auraWrapper auraWrap = new auraWrapper();
        auraWrap.isWebHookData = false;
        if(recordId!=null){
            auraWrap.Id = [SELECT ID FROM Transaction__c WHERE Claim_Payment__c =: recordId AND incoming_From_Webhook__c =: True ORDER BY CreatedDate DESC LIMIT 1]?.ID;
            if( auraWrap.Id!=null){
                auraWrap.isWebHookData = true;
            }
        }
        return auraWrap;
    }
    public class auraWrapper{
        @AuraEnabled public boolean isWebHookData;
        @AuraEnabled public Id Id;
    }
    public class paymentWrapper{
        public String PM_CR_PaymentID;
        public String PM_IP_PaymentID;
        public String PM_Amount;
        public Boolean PM_Funded;
        public String PM_Status;
        public String PM_PaidDate;
        public String PM_ClearedDate;
        public String PM_EscheatDate;
        public String PM_CheckNumber;
        public String PM_MailTrackingNumber;
        public String PM_MethodID;
        public String PM_New_Method;
        public String PM_Orig_Method;
        public String PM_Selection;
        public String PM_Method_Last4Digit;
        public String PM_ReIssue;
        public String PM_ErrorCode;
        public String PM_ErrorMessage;
    }
    public class paymentResWrapper{
        public String PM_IP_PaymentID;
        public String Status;
    }
}