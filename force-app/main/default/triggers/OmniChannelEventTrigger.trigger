trigger OmniChannelEventTrigger on Omni_Channel_Event__e (after insert) {

    List<String> serialized_agentwork = new List<String>();

    // the assumption that there will always be on event of this type but we need to take into account Salesforce
    // internal bulkification and prepare for that. So, if that will be the case - each item in the list is a set
    // of up to 200 AgentWork records that came from multiple trigger transactions
    for (Omni_Channel_Event__e event : Trigger.New) {

        System.debug('Pending_Agent_Work__c: ' + event.Pending_Agent_Work__c); // SFDC-710

        if ( String.isNotBlank(event.Pending_Agent_Work__c) )
            serialized_agentwork.add(event.Pending_Agent_Work__c);
    }

    // SFDC-710
    for ( String triggerContextSerializedAgentWork : serialized_agentwork ) {

        OmniChannelEventTriggerHandler.handleAgentWorkCreation(triggerContextSerializedAgentWork);
    }
}