trigger OrganizationCampaignTrigger on Organization_Campaign__c (after update) {

    new OrganizationCampaignTriggerHandler().run();
}