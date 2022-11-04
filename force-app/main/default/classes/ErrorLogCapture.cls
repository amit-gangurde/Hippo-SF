public class ErrorLogCapture {
    public static void errorLog(){
        //integrationLog();
      //  integrationErrorLog();
    }
    public static Integration_Log__c integrationLog(String className,String endPoint,String method,String methodName,String objName,String recordId,String Status,Id transactionId){
        Integration_Log__c intLog = new Integration_Log__c();
        intLog.Name = className+'-'+DateTime.now();
        intLog.Class_Name__c = className;
        intLog.End_Point__c = endPoint;
        intLog.ExternalID__c = '';
        intLog.Method__c = method;
        intLog.Method_Name__c = methodName;
        intLog.Object_Name__c = objName;
        intLog.RecordID__c = recordId;
        intLog.Status__c = Status;
        intLog.Transaction__c = transactionId; //Payment Integration
        intLog.recordTypeId = Schema.getGlobalDescribe().get('Integration_Log__c').getDescribe().getRecordTypeInfosByName().get('Payment Integration').getRecordTypeId();
        return intLog;
    }
    
    public static Integration_Error_Log__c integrationErrorLog(String className,Exception ex,Id integrationLog,String methodName,String typeString,String typeOfError){
        Integration_Error_Log__c errorLog = new Integration_Error_Log__c();
        errorLog.Name = className+'-'+DateTime.now();
        errorLog.Class_Name__c = className;
        if(ex!=null){
        errorLog.DML_Error__c = ex.getMessage();
        errorLog.Error_Details__c = ex.getMessage();
        errorLog.Error_Line__c = String.valueOf(ex.getLineNumber());
        }
        errorLog.Integration_Log__c =integrationLog;
        errorLog.Method_Name__c = methodName;
        errorLog.Type__c = typeString;
        errorLog.Type_Of_Error__c = typeOfError;
        errorLog.recordTypeId = Schema.getGlobalDescribe().get('Integration_Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Payment Integration').getRecordTypeId();

        return errorLog;
    }
    public static void createAttachment(String title,String responseBody,String recordId){
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = title+'.txt';
        cv.VersionData = Blob.valueOf(responseBody);
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = recordId;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    }
}