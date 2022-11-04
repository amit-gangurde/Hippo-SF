public with sharing class AgentCampaignStateManagement implements Queueable {

    // See comments re the purpose of these arrays in CreateOrganizationCampaigns and DeactivateOrganizationCampaigns classes (member's comments)
    // in any given transaction, only one of these arrays can have an item while the other will be null/empty. That is since they each gets their
    // items from CreateOrganizationCampaigns and DeactivateOrganizationCampaigns executed queueables and they cannot coexist in the same transaction !!!
    public List<CreateOrganizationCampaigns> PENDING_QUEUEABLE_CreateOrganizationCampaigns;
    public List<DeactivateOrganizationCampaigns> PENDING_QUEUEABLE_DeactivateOrganizationCampaigns;

    private List<Id> lst_OrganizationCampaignIds;
    private Integer batch_size;
    private List<Agent_Campaign__c> lst_Agent_Campaigns;
    private Id last_Processed_Agent_Campaign_Index;

    public AgentCampaignStateManagement(List<Id> lst_OrganizationCampaignIds, List<CreateOrganizationCampaigns> PENDING_QUEUEABLE_CreateOrganizationCampaigns, List<DeactivateOrganizationCampaigns> PENDING_QUEUEABLE_DeactivateOrganizationCampaigns) {

        this.lst_OrganizationCampaignIds = lst_OrganizationCampaignIds;
        this.PENDING_QUEUEABLE_CreateOrganizationCampaigns = PENDING_QUEUEABLE_CreateOrganizationCampaigns;
        this.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns = PENDING_QUEUEABLE_DeactivateOrganizationCampaigns;
        batch_size = Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size'));
        lst_Agent_Campaigns = Database.query('Select Id, Organization_Campaign__r.Active__c, Organization_Campaign__r.Campaign__r.IsActive, Organization_Campaign__r.Campaign__r.CreatedDate, Organization_Campaign__r.Campaign__r.Duration__c From Agent_Campaign__c Where Organization_Campaign__c IN: lst_OrganizationCampaignIds Order By Id ASC LIMIT ' + batch_size);
        last_Processed_Agent_Campaign_Index = null;
    }

    public AgentCampaignStateManagement(List<Id> lst_OrganizationCampaignIds, Id last_Processed_Agent_Campaign_Index, List<CreateOrganizationCampaigns> PENDING_QUEUEABLE_CreateOrganizationCampaigns, List<DeactivateOrganizationCampaigns> PENDING_QUEUEABLE_DeactivateOrganizationCampaigns) {

        this.lst_OrganizationCampaignIds = lst_OrganizationCampaignIds;
        this.PENDING_QUEUEABLE_CreateOrganizationCampaigns = PENDING_QUEUEABLE_CreateOrganizationCampaigns;
        this.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns = PENDING_QUEUEABLE_DeactivateOrganizationCampaigns;
        batch_size = Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size'));
        this.last_Processed_Agent_Campaign_Index = last_Processed_Agent_Campaign_Index;
        lst_Agent_Campaigns = Database.query('Select Id, Organization_Campaign__r.Active__c, Organization_Campaign__r.Campaign__r.IsActive, Organization_Campaign__r.Campaign__r.CreatedDate, Organization_Campaign__r.Campaign__r.Duration__c From Agent_Campaign__c Where Organization_Campaign__c IN: lst_OrganizationCampaignIds AND Id >: this.last_Processed_Agent_Campaign_Index Order By Id ASC LIMIT ' + batch_size);
    }

    public void execute(QueueableContext context) {

        try {

            List<Agent_Campaign__c> lst_oAgentCampaigns = new List<Agent_Campaign__c>();

            System.debug('lst_Agent_Campaigns: ' + lst_Agent_Campaigns);

            for (Agent_Campaign__c ac : lst_Agent_Campaigns) {

                System.debug('ac.Organization_Campaign__r.Active__c: ' + ac.Organization_Campaign__r.Active__c);
                ac.Active__c = ac.Organization_Campaign__r.Active__c;
                AgentCampaignStateManagement.setDates(ac);
                lst_oAgentCampaigns.add(ac);
            }

            if (lst_oAgentCampaigns.size() > 0) {

                System.debug('lst_oAgentCampaigns: ' + lst_oAgentCampaigns);

                Database.SaveResult[] results = Database.update(lst_oAgentCampaigns);

                Utils.debugSaveResults(results);
            }

            if (lst_Agent_Campaigns.size() > 0 && lst_Agent_Campaigns.size() == batch_size) { // there might be more agent campaigns

                AgentCampaignStateManagement acs = new AgentCampaignStateManagement(lst_OrganizationCampaignIds, lst_Agent_Campaigns[batch_size - 1].Id, this.PENDING_QUEUEABLE_CreateOrganizationCampaigns, this.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns);
                if ( !Test.isRunningTest() ) {

                    Id jobId = System.enqueueJob(acs);
                    System.debug('AgentCampaignStateManagement jobId: ' + jobId);
                }
                else {

                    acs.execute(null);
                }
            }
            else {

                // As stated above in the members comments, there can only be one PENDING_QUEUEABLE from the two types below so there is no risk to try and enqueue 2 queueables in the same transaction as there is a limit
                if (this.PENDING_QUEUEABLE_CreateOrganizationCampaigns != null && this.PENDING_QUEUEABLE_CreateOrganizationCampaigns.size() == 1) {

                    if ( !Test.isRunningTest() ) {

                        Id jobId = System.enqueueJob(this.PENDING_QUEUEABLE_CreateOrganizationCampaigns[0]);
                        System.debug('PENDING_QUEUEABLE_CreateOrganizationCampaigns jobId: ' + jobId);
                    }
                    else {

                        this.PENDING_QUEUEABLE_CreateOrganizationCampaigns[0].execute(null);
                    }
                }

                if (this.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns != null && this.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns.size() == 1) {

                    if ( !Test.isRunningTest() ) {

                        Id jobId = System.enqueueJob(this.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns[0]);
                        System.debug('PENDING_QUEUEABLE_DeactivateOrganizationCampaigns jobId: ' + jobId);
                    }
                    else {

                        this.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns[0].execute(null);
                    }
                }
            }
        }
        catch(Exception ex) {

            System.debug('Exception from AgentCampaignStateManagement execution: ' + ex.getMessage());
        }
    }

    public static void setDates(Agent_Campaign__c ac) {

        if ( ac.Active__c && ac.Organization_Campaign__r.Campaign__r.IsActive ) {

            ac.Start_Date__c = ac.CreatedDate.date(); //System.now().date().addDays(1);
            ac.End_Date__c = String.isNotBlank(String.valueOf(ac.Organization_Campaign__r.Campaign__r.Duration__c)) ? ac.Start_Date__c.addDays(Integer.valueOf(ac.Organization_Campaign__r.Campaign__r.Duration__c)) : ac.End_Date__c;
        }
    }
}