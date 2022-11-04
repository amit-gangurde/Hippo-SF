global class ProducerSyncSchedulerBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.stateful,Schedulable  {
    public  DateTime startDate = DateTime.now();
    public  DateTime endDate = DateTime.now();
    public boolean isReprocessed = false;
    global String nextUrl;
    
    global void execute(SchedulableContext SC) {
     Database.executeBatch(new ProducerSyncSchedulerBatch(null,null,false,null));
    }
    global ProducerSyncSchedulerBatch(DateTime startDate,DateTime endDate,boolean isReprocessed,String nextUrlvar){
        System.debug('nextUrl==='+nextUrl);
        if(isReprocessed == false){
            Hippo_Last_Sync__c lastSync = Hippo_Last_Sync__c.getOrgDefaults();
            if(lastSync.Producer_Last_Updated_DateTime__c!=null){
                this.startDate = lastSync.Producer_Last_Updated_DateTime__c;
                  this.endDate = lastSync.End_Date__c;
                System.debug('startDate==='+startDate);
            }
            nextUrl = nextUrlvar;
        }else{
            this.startDate = startDate; 
            this.endDate = endDate; 
            this.isReprocessed = isReprocessed;
            nextUrl = nextUrlvar;
        }
    }
    global Iterable<sObject> start(Database.BatchableContext info){
         Hippo_Last_Sync__c lastSync = Hippo_Last_Sync__c.getOrgDefaults();
         System.debug('StartnextUrl==='+nextUrl);
       
        AccountSync.loggerWrapper recordsList = AccountSync.getProducerInfo(startDate,endDate,nextUrl); 
        List<sObject> listObj = new List<sObject>();
        if(recordsList!=null && recordsList.sObjectList!= null && recordsList.sObjectList.size()>0){
            if(nextUrl!= recordsList.nextRecordsUrl){
            nextUrl = recordsList.nextRecordsUrl;
            System.debug('nextUrl==='+nextUrl);
            lastSync.NextUrl__c = nextUrl;
            }else{
                lastSync.NextUrl__c = null; 
            }
            update lastSync;
            return new CustomIterable(recordsList.sObjectList); 
        }
        return listObj;
    }
    global void execute(Database.BatchableContext info, List<sObject> sObjectList){
        boolean isSuccess = true;  integer i = 0,result = 0;
        
        Hippo_Last_Sync__c sycn = Hippo_Last_Sync__c.getOrgDefaults();
         List<Integration_Error_Log__c> intLogLst = new List<Integration_Error_Log__c>();
        try{
            
            List<Database.UpsertResult> results = Database.upsert(sObjectList, Producer_Licensing__c.Hippo_CRM_Identifier__c, false);
            result = results.size();
            for(Database.UpsertResult res: results){
                if(!res.isSuccess()){
                    i++;
                    isSuccess = false;
                    intLogLst.add(IntegrationErrorLogger.createErrorLog('ProducerSyncSchedulerBatch', 'ProducerSyncSchedulerBatch', null, 'Error', sycn.Integration_Log_ID__c, 'DML',String.valueOf(res.errors),'Error',String.valueOf(res)));
                } 
            } 
            System.debug('logID==='+sycn.Integration_Log_ID__c);
            System.debug('isSuccess==='+isSuccess);
            System.debug('results==='+results);
            if(isSuccess == true){
                intLogLst.add(IntegrationErrorLogger.createErrorLog('ProducerSyncSchedulerBatch-Batch', 'ProducerSyncSchedulerBatch-Batch', null, 'Success', sycn.Integration_Log_ID__c, 'DML',null,'Success',null));
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
            intLogLst.add(IntegrationErrorLogger.createErrorLog('ProducerSyncSchedulerBatch-Batch', 'ProducerSyncSchedulerBatch-Batch', ex, 'Error',sycn.Integration_Log_ID__c, 'DML',String.valueOf(ex.getMessage()),'Error',null));
        }
        
        
    }    
    global void finish(Database.BatchableContext bc){
        Hippo_Last_Sync__c lastSync = Hippo_Last_Sync__c.getOrgDefaults();
        if(isReprocessed == false){
            lastSync.Producer_Last_Updated_DateTime__c = DateTime.now();
            if(!String.isBlank(lastSync.NextUrl__c) && lastSync.NextUrl__c!=null){
                Database.executeBatch(new ProducerSyncSchedulerBatch(null,null,false,lastSync.NextUrl__c),100);
                lastSync.NextUrl__c = null;
                  lastSync.Integration_Log_ID__c = '';
               // update lastSync;
            }else{
                // Database.executeBatch(new LicenseSyncSchedulerBatch(null,null,false,null),50);
                lastSync.NextUrl__c = null;
                  lastSync.Integration_Log_ID__c = '';
               // update lastSync;
            }
            update lastSync;
        }  
    }
}