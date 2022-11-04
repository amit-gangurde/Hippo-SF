public with sharing class DeactivateOrganizationCampaigns implements Queueable {

    /*
    Description for the purpose of List<CreateOrganizationCampaigns>

    This transaction only gets deactivated campaigns and can do the following actions:

    1. Deactivate existing organization campaigns

    However, internally in organization campaign trigger, a recalculate of start/end date for agent campaign may be required based on campaign duration that might get updated as well.
    Therefore, if an UPDATE DML is initiated for existing organization campaign, it will enqueue an AgentCampaignStateManagement to work on related agent campaigns, so it won't be possible
    to keep handling additional chained DeactivateOrganizationCampaigns so they will be kept here in this array and will be chained to AgentCampaignStateManagement (See OrganizationCampaignTriggerHandler)
     */
    public static List<DeactivateOrganizationCampaigns> PENDING_QUEUEABLE_DeactivateOrganizationCampaigns = new List<DeactivateOrganizationCampaigns>();

    private List<Id> lst_CampaignIds;
    private Integer batch_size;
    private List<Organization_Campaign__c> lst_Organization_Campaigns;
    private Id last_Processed_Organization_Campaign_Index;

    public DeactivateOrganizationCampaigns(List<Id> lst_CampaignIds) {

        this.lst_CampaignIds = lst_CampaignIds;
        system.debug('lst_CampaignIds: ' + lst_CampaignIds);
        batch_size = Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size'));
        system.debug('batch_size: ' + batch_size);
        lst_Organization_Campaigns = Database.query('Select Id From Organization_Campaign__c Where Campaign__c IN: lst_CampaignIds Order By Id ASC LIMIT ' + batch_size);
        system.debug('lst_Organization_Campaigns: ' + lst_Organization_Campaigns);
        last_Processed_Organization_Campaign_Index = null;
    }

    public DeactivateOrganizationCampaigns(List<Id> lst_CampaignIds, Id last_Processed_Organization_Campaign_Index) {

        this.lst_CampaignIds = lst_CampaignIds;
        batch_size = Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size'));
        this.last_Processed_Organization_Campaign_Index = last_Processed_Organization_Campaign_Index;
        System.debug('last_Processed_Organization_Campaign_Index: ' + last_Processed_Organization_Campaign_Index);
        lst_Organization_Campaigns = Database.query('Select Id From Organization_Campaign__c Where Campaign__c IN: lst_CampaignIds AND Id >: this.last_Processed_Organization_Campaign_Index Order By Id ASC LIMIT ' + batch_size);
    }

    public void execute(QueueableContext context) {

        try {

            System.debug('Inside DeactivateOrganizationCampaigns');

            List<Organization_Campaign__c> lst_oOrganizationCampaigns = new List<Organization_Campaign__c>();

            System.debug('lst_Organization_Campaigns: ' + lst_Organization_Campaigns);

            for (Organization_Campaign__c oc : lst_Organization_Campaigns) {

                oc.Active__c = false;
                lst_oOrganizationCampaigns.add(oc);
            }

            System.debug('lst_oOrganizationCampaigns: ' + lst_oOrganizationCampaigns);

            if (lst_oOrganizationCampaigns.size() > 0) {

                //Database.SaveResult[] results = Database.update(lst_oOrganizationCampaigns);

                if (lst_Organization_Campaigns.size() > 0 && lst_Organization_Campaigns.size() == batch_size) { // there might be more organization campaigns

                    DeactivateOrganizationCampaigns doc = getNextQueueable();

                    // the AfterUpdate trigger on Organization_Campaign__c may kick off a queueable (AgentCampaignStateManagement). so the next DeactivateOrganizationCampaigns is parked and will continue
                    // once all AgentCampaignStateManagement queueable are completed (See code in AgentCampaignStateManagement)
                    if ( !Test.isRunningTest() ) {

                        DeactivateOrganizationCampaigns.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns.add(doc);
                    }
                    else {

                        doc.execute(null);
                    }
                }

                // Update existing records
                Database.SaveResult[] results = Database.update(lst_oOrganizationCampaigns);
                System.debug('--> Deactivating existing Organization Campaign records');
                Utils.debugSaveResults(results);
            }
            else {

                if (lst_Organization_Campaigns.size() > 0 && lst_Organization_Campaigns.size() == batch_size) { // there might be more organization campaigns

                    DeactivateOrganizationCampaigns doc = getNextQueueable();
                    if ( !Test.isRunningTest() ) {

                        Id jobId = System.enqueueJob(doc);
                        System.debug('DeactivateOrganizationCampaigns jobId: ' + jobId);
                    }
                    else {

                        doc.execute(null);
                    }
                }
            }
        }
        catch(Exception ex) {

            System.debug('Exception from DeactivateOrganizationCampaigns execution: ' + ex.getMessage());
            System.debug('Exception from DeactivateOrganizationCampaigns execution: ' + ex.getStackTraceString());
        }
    }

    private DeactivateOrganizationCampaigns getNextQueueable() {

        return new DeactivateOrganizationCampaigns(lst_CampaignIds, lst_Organization_Campaigns[batch_size - 1].Id);
    }
}