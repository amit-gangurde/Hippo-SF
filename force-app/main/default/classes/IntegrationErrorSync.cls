public class IntegrationErrorSync {
    @AuraEnabled
    public static String reSyncHandler(Id recordId){
       Id logID = null; boolean isSuccess = true;String ObjectName;
       try{ 
            Integration_Log__c intLog = [SELECT ID,Object_Name__c,Batch_End_Date__c,Batch_Start_Date__c,RecordID__c FROM Integration_Log__c WHERE ID=: recordId LIMIT 1];
            if(intLog.Object_Name__c == 'Producer_Licensing__c'){
                Database.executeBatch(new ProducerSyncSchedulerBatch(intLog.Batch_Start_Date__c,intLog.Batch_End_Date__c,true,null));
            }else if(intLog.Object_Name__c == 'License__c'){
                Database.executeBatch(new LicenseSyncSchedulerBatch(intLog.Batch_Start_Date__c,intLog.Batch_End_Date__c,true,null));
            }else if(intLog.Object_Name__c == 'Carrier_Appointment__c'){
                Database.executeBatch(new CarrierAppointmentSyncSchedulerBatch(intLog.Batch_Start_Date__c,intLog.Batch_End_Date__c,true,null));
            }else if(intLog.Object_Name__c == 'Line_of_Authority__c'){
                 Database.executeBatch(new LineOfAuthoritySync(intLog.Batch_Start_Date__c,intLog.Batch_End_Date__c,true,null));
            }else if(intLog.Object_Name__c == 'Account'){
                AccountErrorSync.reSyncHandler(intLog.RecordID__c);
            }
            else if(intLog.Object_Name__c == 'Contact'){
                ContactErrorSync.reSyncHandler(intLog.RecordID__c);
            }
            if(isSuccess == true){
                Integration_Log__c logUpd = new Integration_Log__c();
                logUpd.Id = recordId;
                logUpd.Status__c = 'Re - Processed';
                update logUpd;
                
                IntegrationErrorLogger.createErrorLog('IntegrationErrorSync', 'IntegrationErrorSync', null, 'Success', logID, 'DML',null,'Success',null);
            }
            return 'Re-Process Initiated...!';
        }catch(Exception ex){
            IntegrationErrorLogger.createErrorLog('IntegrationErrorSync', 'IntegrationErrorSync', ex, 'Error',logID, 'DML',String.valueOf(ex.getMessage()),'Error',null);
         return 'Error: '+ex.getMessage();
        }
    }
}