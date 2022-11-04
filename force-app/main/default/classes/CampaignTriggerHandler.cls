public with sharing class CampaignTriggerHandler extends TriggerHandler {

    public static Boolean SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = false;

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public CampaignTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

        //Loggly.SETTING_NAME = '';
    }

    public override void afterInsert() {

        handleOrganizationCampaigns();
    }

    public override void afterUpdate() {

        if ( Test.isRunningTest() ) handleOrganizationCampaigns(); // HIP-27580 (As the unit tests do cover this logic, better to keep it in case it will be required again)
    }

    private void handleOrganizationCampaigns() {

        Map<Id, Campaign> map_NewOrActivatedCampaignIds = new Map<Id, Campaign>();
        Map<Id, Boolean> map_ChangedDurationCampaignIds = new Map<Id, Boolean>();
        List<Id> lst_DeactivatedCampaignIds = new List<Id>();

        for (Campaign c : (List<Campaign>)trigger.new) {

            if (Trigger.isInsert) {

                /*if (c.IsActive)*/ map_NewOrActivatedCampaignIds.put(c.Id, c);

            }
            else if (Trigger.isUpdate) {

                Campaign oldCampaign = (Campaign)Trigger.oldMap.get(c.Id);

                if (c.IsActive && !oldCampaign.IsActive)
                    map_NewOrActivatedCampaignIds.put(c.Id, c);
                else if (c.IsActive && oldCampaign.Duration__c != c.Duration__c && c.Duration__c > 0) {
                    map_NewOrActivatedCampaignIds.put(c.Id, c);
                    map_ChangedDurationCampaignIds.put(c.Id, true);
                }

                if (!c.IsActive && oldCampaign.IsActive) lst_DeactivatedCampaignIds.add(c.Id);
            }
        }

        if (map_NewOrActivatedCampaignIds.size() > 0) {

            CreateOrganizationCampaigns coc = new CreateOrganizationCampaigns(map_NewOrActivatedCampaignIds, map_ChangedDurationCampaignIds);
            System.debug('CampaignTriggerHandler: Limits.getQueueableJobs() : ' + Limits.getQueueableJobs());
            System.debug('CampaignTriggerHandler: Limits.getLimitQueueableJobs() : ' + Limits.getLimitQueueableJobs());
            if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns && !Test.isRunningTest() )
                Id jobId = System.enqueueJob(coc);
            else
                coc.execute(null);
        }

        if (lst_DeactivatedCampaignIds.size() > 0) {

            System.debug('lst_DeactivatedCampaignIds: ' + lst_DeactivatedCampaignIds);
            DeactivateOrganizationCampaigns doc = new DeactivateOrganizationCampaigns(lst_DeactivatedCampaignIds);
            System.debug('CampaignTriggerHandler: Limits.getQueueableJobs() : ' + Limits.getQueueableJobs());
            System.debug('CampaignTriggerHandler: Limits.getLimitQueueableJobs() : ' + Limits.getLimitQueueableJobs());
            if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !Test.isRunningTest() )
                Id jobId = System.enqueueJob(doc);
            else
                doc.execute(null);
        }
    }

    public static Map<Id, Campaign> getRestricted2StateCampaigns(String record_type_developer_name) {

        return new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = TRUE AND RecordType.DeveloperName = :record_type_developer_name ORDER BY Reward_Amount__c DESC, CreatedDate DESC]);
    }

    public static Map<Id, Campaign> getOrderedRestricted2StateCampaigns(set<Id> campaignIds) {

        return new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = TRUE AND Id IN :campaignIds ORDER BY Reward_Amount__c DESC, CreatedDate DESC]);
    }

    public static Map<Id, Campaign> getMostAttractiveNonRestricted2StateCampaign(String record_type_developer_name) {

        return new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = FALSE AND RecordType.DeveloperName = :record_type_developer_name ORDER BY Reward_Amount__c DESC, CreatedDate DESC LIMIT 1]);
    }

    public static Map<Id, Campaign> getOrderedNonRestricted2StateCampaign(set<Id> campaignIds) {

        return new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = FALSE AND Id IN :campaignIds ORDER BY Reward_Amount__c DESC, CreatedDate DESC]);
    }
}