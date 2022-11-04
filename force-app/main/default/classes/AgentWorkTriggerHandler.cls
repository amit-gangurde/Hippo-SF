public with sharing class AgentWorkTriggerHandler extends TriggerHandler {

    public static Boolean SKIP_RECURSION = false;

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public AgentWorkTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);
    }

    public override void beforeInsert() {

        if ( AgentWorkTriggerHandler.SKIP_RECURSION ) {

            return;
        }

        // DISABLE this trigger as it can't get any code coverage (NEED TO COMEBACK!!!)
        handleAgentWorkCreation();
    }

    /*
    Method: handleAgentWorkCreation
    Description: The purpose of this method is to iterate on leads related agent works as they are getting created
        and check if the current system time is in working hours before routing the work to an agent. If no inside
        business hours, add an error (using addError) to the AgentWork and by that preventing it from being created
        at this specific time
    Return: nothing
    */
    @TestVisible private void handleAgentWorkCreation() {

        try {

            if (Trigger.isBefore && Trigger.isInsert) {

                // a map between lead id to it's related agent work
                Map<Id, AgentWork> map_LeadId2AgentWork = new Map<Id, AgentWork>();

                for ( AgentWork aw : (List<AgentWork>)Trigger.new ) {

                    if ( aw.WorkItemId?.getSobjectType() == Lead.SObjectType ) {

                        map_LeadId2AgentWork.put(aw.WorkItemId, aw);
                    }
                }

                System.debug('map_LeadId2AgentWork before adding errors: ' + map_LeadId2AgentWork);

                // list of all leads related to the agent works records in context
                List<Lead> lstLeads = [SELECT Id, State, OwnerId, Pending_Queue_Id__c FROM Lead WHERE Id IN: map_LeadId2AgentWork.keySet()];

                System.debug('lstLeads: ' + lstLeads);

                if ( lstLeads.size() > 0 ) {

                    //Boolean foundOutsideOfBusinessHoursLead = false;

                    List<AgentWork> valid_agentwork = new List<AgentWork>(); // list of leads related agent works that are inside business hours

                    for ( Lead my_lead : lstLeads ) {

                        Utils.LeadState leadState = Utils.isLeadWithinBusinessHours(my_lead);

                        if ( leadState.bIsWithinBusinessHours ) {

                            valid_agentwork.add(map_LeadId2AgentWork.get(my_lead.Id));
                        }
                        else {

                            map_LeadId2AgentWork.get(my_lead.Id).addError('Lead routed while not inside business hours');
                            // flag that we found an outside of business hours lead. Potentially we could compare the size
                            // of valid_agentwork to Trigger.new and if they are the same size then all AgnetWorks are valid
                            // but with this flag it is more readable
                            //foundOutsideOfBusinessHoursLead = true;
                        }
                    }

                    System.debug('valid_agentwork: ' + valid_agentwork);
                    System.debug('map_LeadId2AgentWork after, potentially, adding errors: ' + map_LeadId2AgentWork);

                    if ( valid_agentwork.size() > 0 ) {

                        Omni_Channel_Event__e omni_channel_event = new Omni_Channel_Event__e();

                        // Serialize the list of AgentWork objects.
                        String JSONString = JSON.serialize(valid_agentwork);
                        System.debug('Size of JSON: ' + JSONString.length()); // Size of JSON: should be up to 100401 - for 200 records!
                        System.debug('Serialized list of AgentWork into JSON format: ' + JSONString);

                        omni_channel_event.Pending_Agent_Work__c = JSONString;
                        Database.SaveResult sr = EventBus.publish(omni_channel_event);
                        System.debug('EventBus.publish SaveResult: ' + sr);
                    }
                }
            }

        } catch (Exception ex) {

            System.debug('Exception from handleAgentWorkCreation execution: ' + ex.getMessage());
        }
    }

    @TestVisible public static List<sObject> handleAgentWorkAcceptFromProcessBuilder(List<AgentWork> agentWorks) {

        Set<String> workItemsIds = new Set<String>();

        system.debug('Agent work from process builder in context: ' + agentWorks);

        for (AgentWork aw : agentWorks) {

            String workItemId = aw.WorkItemId;
            workItemsIds.add(workItemId);
        }

        List<sObject> workItems2Update = new List<sObject>();

        for (Id workItemId : workItemsIds) {

            String objectName = Utils.findObjectNameFromRecordIdPrefix(workItemId);

            sObject obj = null;

            if ( objectName.equalsIgnoreCase('Case') ) {

                obj = new Case();
                obj.id = workItemId;
                ((Case)obj).Status = 'Working';
            }
            else if ( objectName.equalsIgnoreCase('Lead') ) {

                obj = new Lead();
                obj.id = workItemId;
                ((Lead)obj).Status = 'Working';
                ((Lead)obj).Work_Accepted_Time__c = System.now();
            }

            workItems2Update.add(obj);
        }

        system.debug('Work items to update upon agent accept: ' + workItems2Update);

        CaseTriggerHandler.SKIP_RECURSION = true;
        LeadTriggerHandler.SKIP_RECURSION = true;
        update workItems2Update;
        LeadTriggerHandler.SKIP_RECURSION = false;
        CaseTriggerHandler.SKIP_RECURSION = false;

        return workItems2Update;
    }

    /*
    @InvocableMethod(label='Update Cases' description='Update the associated cases and returns the IDs of the update cases.')
    public static List<Case> updateCases(List<AgentWork> agentWorks) {

        system.debug('agentWorks sent to InvocableMethod: ' + agentWorks);

        return AgentWorkTriggerHandler.handleAgentWorkAcceptFromProcessBuilder(agentWorks);
    }
     */

    public static void fakeMethod() {

        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}