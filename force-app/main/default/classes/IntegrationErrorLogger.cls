public class IntegrationErrorLogger {
   public static Integration_Error_Log__c createErrorLog(String ClassName,String MethodName,Exception ex,String Name,Id integrationLogID,String typeOfError,String DMLerror,String status,String errorDetails){
        Integration_Error_Log__c errorLog = new Integration_Error_Log__c();
        errorLog.Name = Name+' Log-'+DateTime.now();
        errorLog.Type__c = status;
        errorLog.Type_Of_Error__c = typeOfError;
        errorLog.Class_Name__c = ClassName;
        errorLog.Method_Name__c = MethodName;
        if(ex!=null){
        errorLog.Error_Line__c = String.valueOf(ex.getLineNumber());
        errorLog.Error_Details__c =ex.getMessage();
        }else{
            errorLog.Error_Details__c = errorDetails;   
        }
        errorLog.DML_Error__c = DMLerror;
        errorLog.Integration_Log__c = integrationLogID;
        return errorLog;
    }
    public static void beforeInsert(List<Integration_Error_Log__c> errorLogs){
        try{
        Set<Id> updateParentIntegrationLog = new Set<Id>();
        List<Integration_Log__c> updateErrorLog = new List<Integration_Log__c>();
        for(Integration_Error_Log__c error:errorLogs ){
            if(error.Type__c == 'Error'){
                if(error.Integration_Log__c!=null){
                updateParentIntegrationLog.add(error.Integration_Log__c);
                }
            }
        }
        for(Integration_Log__c iLog:[SELECT ID,status__c FROM Integration_Log__c WHERE ID IN: updateParentIntegrationLog]){
            iLog.status__c = 'Failure';
            updateErrorLog.add(iLog);
        }
        update updateErrorLog;
        }catch(Exception ex){
            
        }
    }
}