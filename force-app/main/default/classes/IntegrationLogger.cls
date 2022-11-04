public class IntegrationLogger {
    public static Id createIntegrationLog(String name,String className,String functionaName,String method,String endPoint,String request,String response,String status,String ObjectName,String RecordID,String ExternalID,DateTime startDate,DateTime endDate){
        Integration_Log__c log = createLogs(name,className,functionaName,method,endPoint,request,response,status,ObjectName,RecordID,ExternalID,startDate,endDate);
        insert log;
        
        Hippo_Last_Sync__c hippoSync =  Hippo_Last_Sync__c.getOrgDefaults();
        hippoSync.Integration_Log_ID__c = log.ID;
        update hippoSync;
        
        System.debug('Loggger>>>'+log);
        System.debug('request>>>'+request);
        System.debug('response>>>'+response);
        if(!String.isBlank(request)){
            ContentVersion cv = createFileContent(log.Id,'Request.txt',request);
            insert cv;
            ContentDocumentLink cd = createFileContentDoc(log.Id,cv.id);
            insert cd;
        } if(!String.isBlank(response)){
            ContentVersion cv =  createFileContent(log.Id,'Response.txt',response);
            insert cv;
            ContentDocumentLink cd = createFileContentDoc(log.Id,cv.id);
            insert cd;
        }
        return log.Id;
    }
    public static ContentVersion createFileContent(Id objId, String fileName,String file){
        ContentVersion cv=new ContentVersion();
        cv.ContentLocation='S';
        cv.PathOnClient=fileName; 
        cv.Title=fileName;
        cv.VersionData=Blob.valueOf(file);
        return cv;
    }
    public static ContentDocumentLink createFileContentDoc(Id objId,Id cvID){
        ContentDocumentLink link=new ContentDocumentLink();
        link.LinkedEntityId = objId; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
        link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE ID =: cvID].ContentDocumentId;  //ContentDocumentId Id from ContentVersion
        link.shareType = 'V';
        return link; 
    }
    public static Integration_Log__c createLogs(String name,String className,String functionaName,String method,String endPoint,String request,String response,String status,String ObjectName,String RecordID,String ExternalID,DateTime startDate,DateTime endDate){
        Integration_Log__c log = new Integration_Log__c();
        log.Name = name;
        log.Class_Name__c = className;
        log.End_Point__c = endPoint;
        log.Method__c = method;
        log.Method_Name__c = functionaName;
        log.status__c = status;
        log.Object_Name__c = ObjectName;
        log.RecordID__c = RecordID;
        log.ExternalID__c = ExternalID;
        log.Batch_Start_Date__c = startDate;
        log.Batch_End_Date__c = endDate;
        return log;
    }
}