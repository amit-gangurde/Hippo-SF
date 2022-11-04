public with sharing class TaskTriggerHandler extends TriggerHandler {

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public TaskTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);
    }

    public override void beforeDelete() {
        if (!FeatureManagement.checkPermission('AllowDeleteTasksAndDocs')) {
            for (SObject task : Trigger.old) {
                task.addError('You do not have permission to delete tasks');
            }
        }
    }

    public override void afterInsert() {

        updateParentLeads();
        createFollowUpTasks();
    }

    public override void afterUpdate() {

        updateParentLeads();
    }

    private void updateParentLeads() {

        if ( Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {

            RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');

            Set<Id> lead_Ids = new Set<Id>();

            // collect all parent Leads
            for (sObject obj : Trigger.new) {

                Task new_tsk = (Task)obj;
                if ( String.isNotBlank(new_tsk.WhoId) && String.valueOf(new_tsk.WhoId).startsWith('00Q') ) {

                    lead_Ids.add(new_tsk.WhoId);
                }
            }

            // iterate on all Tasks with parent Leads
            if ( lead_Ids.size() > 0 ) {

                // only works on 'B2C Sales' record type of Lead
                Map<Id, Lead> map_Id2Lead = new Map<Id, Lead>([Select Id, Status, Disqualified_Reason__c From Lead Where Id IN:lead_Ids And RecordTypeId = : rtInfo.getRecordTypeId()]);

                for (Sobject obj : Trigger.new) {

                    Task old_tsk = null;
                    Task new_tsk = (Task) obj;
                    if (Trigger.isUpdate) old_tsk = (Task) Trigger.oldMap.get(new_tsk.Id);

                    if (String.isNotBlank(new_tsk.WhoId) && String.valueOf(new_tsk.WhoId).startsWith('00Q') && map_Id2Lead.containsKey(new_tsk.WhoId)) { // confirm that the parent is Lead

                        if (((Trigger.isInsert && String.isNotBlank(new_tsk.Disposition__c)) ||
                            (Trigger.isUpdate && String.isNotBlank(new_tsk.Disposition__c) && new_tsk.Disposition__c != old_tsk.Disposition__c)) &&
                            (new_tsk.Disposition__c.equalsIgnoreCase('Inside Rep') || new_tsk.Disposition__c.equalsIgnoreCase('Outside Partner') ||
                             new_tsk.Disposition__c.equalsIgnoreCase('DNC') || new_tsk.Disposition__c.equalsIgnoreCase('Fake Lead') ||
                             new_tsk.Disposition__c.equalsIgnoreCase('Already Purchased with another company'))
                            ) {

                            map_Id2Lead.get(new_tsk.WhoId).Status = 'Cancelled';
                            map_Id2Lead.get(new_tsk.WhoId).Disqualified_Reason__c = getLeadCancellationReason(new_tsk.Disposition__c);
                        }
                    }
                }

                LeadTriggerHandler.SKIP_AFTER_UPDATE = true;
                update map_Id2Lead.values();
                LeadTriggerHandler.SKIP_AFTER_UPDATE = false;
            }
        }
    }

    private String getLeadCancellationReason(String disposition) {

        String res = '';

        if ( String.isNotBlank(disposition) ) {
            if ( disposition.equalsIgnoreCase('Inside Rep') ) res = 'Inside Agent';
            if ( disposition.equalsIgnoreCase('Outside Partner') ) res = 'Outside Agent';
            if ( disposition.equalsIgnoreCase('DNC') ) res = 'Unable to contact';
            if ( disposition.equalsIgnoreCase('Fake Lead') ) res = 'Fake Contact Info';
            if ( disposition.equalsIgnoreCase('Already Purchased with another company') ) res = 'Not Interested';
        }
        return res;
    }
    //Added below method as part of SFDC-284 by Rama Nagalla on 01/07/2021
    public  string findObjectAPIName( String recordId ){
        String objectAPIName;
        if(recordId != null && recordId != ''){
            Id myId = Id.valueOf(recordId);
             objectAPIName = myId.getSObjectType().getDescribe().getName();
        }
            return objectAPIName;
        }
    // End of modification of SFDC-284
    
    private void createFollowUpTasks() {
        if ( Trigger.isAfter && Trigger.isInsert ) {
            List<Task> follow_up_tasks = new List<Task>();
            // Added below code as part of SFDC-284 by Rama Nagalla on Jan 01/07/2021
            // This scenario will ignore Task creation when an email is sent for "Claim" Record type in Case object
            Id idCaseClaimRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Claim').getRecordTypeId();
            Set<Id> setCaseId = new Set<Id> ();
            Set<ID> setCaseIdtoIgnore = new Set<Id> ();
            for (Sobject obj : Trigger.new) {
                  Task new_tsk = (Task) obj;
                if(findObjectAPIName(new_tsk.WhatId) =='Case'){
                    setCaseId.add(new_tsk.WhatId);
                }
            }
            if(!setCaseId.isEmpty()){
                for(case objcase: [select id,recordtypeId from case where Id IN:setCaseId ]){
                    if(objcase.recordtypeId == idCaseClaimRT){
                        setCaseIdtoIgnore.add(objcase.id);
                    }
                }
            }
     //End of modification (SFDC-284)
            for (Sobject obj : Trigger.new) {
                Task new_tsk = (Task) obj;
                if ( String.isNotBlank(new_tsk.TaskSubtype) && new_tsk.TaskSubtype.equalsIgnoreCase('Email') ) {                    
                    //Added below line as part of SFDC-284
                   // if ((findObjectAPIName(new_tsk.WhatId) !='Claim')&& (setCaseIdtoIgnore.isEmpty()  || (!setCaseIdtoIgnore.isEmpty() && !setCaseIdtoIgnore.contains(new_tsk.WhatId)))){
                   // // Added (findObjectAPIName(new_tsk.WhatId) =='Case') as part of JVOX-122
                     if ((findObjectAPIName(new_tsk.WhatId) =='Case')&& (setCaseIdtoIgnore.isEmpty()  || (!setCaseIdtoIgnore.isEmpty() && !setCaseIdtoIgnore.contains(new_tsk.WhatId)))){
                        Task follow_up_task = new Task();
                        follow_up_task.OwnerId = new_tsk.OwnerId;
                        follow_up_task.WhoId = new_tsk.WhoId;
                        follow_up_task.WhatId = new_tsk.WhatId;
                        follow_up_task.Status = 'Open';
                        follow_up_task.Priority = 'Normal';
                        follow_up_task.Subject = 'Follow up on email';
                        DateTime due_date = System.now().addDays(1);
                        follow_up_task.ActivityDate = date.newInstance(due_date.year(), due_date.month(), due_date.day());
                        follow_up_tasks.add(follow_up_task);
                    }
                }
            }
            insert follow_up_tasks;
        }
    }
}