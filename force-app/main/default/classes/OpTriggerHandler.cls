public with sharing class  OpTriggerHandler extends TriggerHandler {
    public static Boolean SKIP_RECURSION = false;
    public static Boolean SEND_FNOL_CLAIM_SUBMISSION_EMAILS = false;
       /*  SFDC 492- commenting because it is no longer required to create task on status change   

    public OpTriggerHandler() {        
        if (!Test.isRunningTest())
            this.setMaxLoopCount(100);
    }
    
    public override void afterUpdate(){
        createTaskOnStatusChange();
    }
    
    public void createTaskOnStatusChange(){  
        BusinessHours  bh = DateUtilityCls.getBusinessHours();
        List<Holiday>  lstHolyday  = DateUtilityCls.getHolidays();              
        List<Task> lstTask = new List<Task> ();        
        for (Sobject obj : Trigger.new) {
            Op__c new_cs = (Op__c)obj;
            Op__c old_cs = (Op__c)Trigger.oldMap.get(new_cs.Id);           
            if(new_cs.Status__c != NULL && new_cs.Status__c != old_cs.Status__c && new_cs.Status__c =='Working'){               
                Task objTask  = new Task();
                objTask.Subject = 'Follow up task on '+new_cs.Name; 
                objTask.OwnerId = new_cs.OwnerId ; 
                objTask.WhatId = new_cs.Id;
                objTask.Priority = 'Normal';
                objTask.Status ='Not Started';
                objTask.ActivityDate = DateUtilityCls.getFutureBusinessDate(bh,lstHolyday,Date.Today(),1); 
                lstTask.add(objTask);
            }
            if(new_cs.Status__c != NULL && new_cs.Status__c != old_cs.Status__c && new_cs.Status__c =='Quoted'){               
                Task objTask1  = new Task();
                objTask1.Subject = 'Follow up task on '+new_cs.Name; 
                objTask1.OwnerId = new_cs.OwnerId ; 
                objTask1.WhatId = new_cs.Id;
                objTask1.Priority = 'Normal';
                objTask1.Status ='Not Started';
                objTask1.ActivityDate = DateUtilityCls.getFutureBusinessDate(bh,lstHolyday,Date.Today(),2);
                lstTask.add(objTask1);
            }            
        }        
        system.debug('lstTask==> '+lstTask);
        if(!lstTask.isEmpty()){
            try{
                Database.insert(lstTask,False);
            }catch(Exception ex){
                System.debug('createTaskOnStatusChange ==> '+ex);
            }
        }
    }
    */
}