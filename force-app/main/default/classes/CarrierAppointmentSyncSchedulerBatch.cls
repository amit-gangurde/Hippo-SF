global class CarrierAppointmentSyncSchedulerBatch  implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.stateful,Schedulable  {
    
    public  DateTime startDate = DateTime.now();
    public  DateTime endDate = DateTime.now();
    public boolean isReprocessed = false;
    global String nextUrl ;
    global void execute(SchedulableContext SC) {
    	 Database.executeBatch(new CarrierAppointmentSyncSchedulerBatch(null,null,false,null),50);  
    }
    
    global CarrierAppointmentSyncSchedulerBatch(DateTime startDate,DateTime endDate,boolean isReprocessed,String nextUrlvar){
        if(isReprocessed == false){
            Hippo_Last_Sync__c lastSync = Hippo_Last_Sync__c.getOrgDefaults();
            if(lastSync.Carrier_Appointment_Last_Update_DateTime__c!=null){
                this.startDate = lastSync.Carrier_Appointment_Last_Update_DateTime__c;
                  this.endDate = lastSync.End_Date__c;
            }
            nextUrl = nextUrlvar;
        }else{
            nextUrl = nextUrlvar;
            this.startDate = startDate; 
            this.endDate = endDate; 
            this.isReprocessed = isReprocessed;
        }
        
    }
    global Iterable<sObject> start(Database.BatchableContext info){
        Hippo_Last_Sync__c lastSync = Hippo_Last_Sync__c.getOrgDefaults();
        AccountSync.loggerWrapper recordsList = AccountSync.getCarrierAppointmentInfo(StartDate,endDate,nextUrl);
        List<sObject> listObj = new List<sObject>();
        system.debug('@@recordsList'+recordsList);
        if(recordsList!=null && recordsList.sObjectList!=null && recordsList.sObjectList.size()>0){
            if(nextUrl!= recordsList.nextRecordsUrl){
            nextUrl = recordsList.nextRecordsUrl;
            System.debug('nextUrl==='+nextUrl);
            lastSync.NextUrl__c = nextUrl;
            }else{
                lastSync.NextUrl__c = null; 
            }
            system.debug('@@nextUrl'+nextUrl);
            update lastSync;
            return new CustomIterable(recordsList.sObjectList);
        }
        return listObj;
    }
    global void execute(Database.BatchableContext bc, List<sObject> records){
        Hippo_Last_Sync__c sycn = Hippo_Last_Sync__c.getOrgDefaults();
        boolean isSuccess = true;  integer i = 0,result = 0;
           List<Integration_Error_Log__c> intLogLst = new List<Integration_Error_Log__c>();
        try{  
           // boolean isSuccess = true;
            List<Database.UpsertResult> results = Database.upsert(records, Carrier_Appointment__c.Hippo_CRM_Identifier__c, false);
            result = results.size();
            for(Database.UpsertResult res: results){
                if(!res.isSuccess()){
                    isSuccess = false;
                    intLogLst.add(IntegrationErrorLogger.createErrorLog('CarrierAppointmentSyncSchedulerBatch', 'CarrierAppointmentSyncSchedulerBatch', null, 'Error',sycn.Integration_Log_ID__c, 'DML',String.valueOf(res.errors),'Error',String.valueOf(res)));
                }else{
                 //   intLogLst.add(IntegrationErrorLogger.createErrorLog('CarrierAppointmentSyncSchedulerBatch', 'CarrierAppointmentSyncSchedulerBatch', null, 'Success',sycn.Integration_Log_ID__c, 'DML',String.valueOf(res.errors),'Success',String.valueOf(res)));
 
                } 
            }
            if(isSuccess == true){
                intLogLst.add(IntegrationErrorLogger.createErrorLog('CarrierAppointmentSyncSchedulerBatch-Batch', 'CarrierAppointmentSyncSchedulerBatch', null, 'Success', sycn.Integration_Log_ID__c, 'DML',null,'Success',null));
            }
            
                    if(!String.isBlank(sycn.Integration_Log_ID__c) || Test.isRunningTest()){
            Integration_Log__c log = new Integration_Log__c();
            log.Id = sycn.Integration_Log_ID__c;
            log.Success_Records_Count__c =result-i;
            log.Failure_Records_Count__c = i;
            update log;
        }
        
       // sycn.Integration_Log_ID__c = null;
        update sycn;
        insert intLogLst;
        }catch(Exception ex){
            intLogLst.add(IntegrationErrorLogger.createErrorLog('CarrierAppointmentSyncSchedulerBatch-Batch', 'CarrierAppointmentSyncSchedulerBatch', ex, 'Error',sycn.Integration_Log_ID__c, 'DML',String.valueOf(ex.getMessage()),'Error',null));
        }
        

    }    
    global void finish(Database.BatchableContext bc){
        if(isReprocessed == false){
            Hippo_Last_Sync__c lastSync = Hippo_Last_Sync__c.getOrgDefaults();
            lastSync.Carrier_Appointment_Last_Update_DateTime__c = DateTime.now();
          
            if(!String.isBlank(lastSync.NextUrl__c) && lastSync.NextUrl__c!=null){
                Database.executeBatch(new CarrierAppointmentSyncSchedulerBatch(null,null,false,lastSync.NextUrl__c),100); 
                lastSync.NextUrl__c = null;
                  lastSync.Integration_Log_ID__c = '';
               // update lastSync;
               
            }
            else{
                lastSync.NextUrl__c = null;
                  lastSync.Integration_Log_ID__c = '';
               // update lastSync;
               // Database.executeBatch(new LineOfAuthoritySync(null,null,false,null),50);
            }
            update lastSync;
        }
    }    
}