trigger AgentCampaignTrigger on Agent_Campaign__c (before insert, after insert, before update, after update) {

    new AgentCampaignTriggerHandler().run();
}