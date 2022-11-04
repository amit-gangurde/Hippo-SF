trigger CampaignTrigger on Campaign (after insert, after update) {

    new CampaignTriggerHandler().run();
}