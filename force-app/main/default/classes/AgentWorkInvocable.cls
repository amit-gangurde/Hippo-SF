public with sharing class AgentWorkInvocable {

    @InvocableMethod(label='Update WorkItems' description='Update the associated work items and returns the IDs of the update work items.')
    public static void updateWorkItems(List<AgentWork> agentWorks) {

        system.debug('agentWorks sent to InvocableMethod: ' + agentWorks);

        List<sObject> results = AgentWorkTriggerHandler.handleAgentWorkAcceptFromProcessBuilder(agentWorks);
    }
}