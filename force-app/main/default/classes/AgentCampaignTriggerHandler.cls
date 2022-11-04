public with sharing class AgentCampaignTriggerHandler extends TriggerHandler {

    public static Boolean SKIP_RECURSION = false;

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public AgentCampaignTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

        //Loggly.SETTING_NAME = '';
    }

    public override void beforeInsert() {

        confirmOneActiveAgentCampaign();
    }

    public override void afterInsert() {

        if ( AgentCampaignTriggerHandler.SKIP_RECURSION ) {

            return;
        }

        handleAgentCampaigns();
    }

    public override void beforeUpdate() {

        confirmOneActiveAgentCampaign();
    }

    public override void afterUpdate() {

        if ( AgentCampaignTriggerHandler.SKIP_RECURSION ) {

            return;
        }

        handleAgentCampaigns();
    }

    private void handleAgentCampaigns() {

        updateAgentCampaigns();
    }

    private void updateAgentCampaigns() {

        if ( Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {

            Set<Id> set_AgentCampaignIds = new Set<Id>();

            for (Agent_Campaign__c ac : (List<Agent_Campaign__c>) trigger.new) {

                set_AgentCampaignIds.add(ac.Id);
            }

            Map<Id, Agent_Campaign__c> map_AgentCampaignsByIds = new Map<Id, Agent_Campaign__c>([Select Id, Active__c, CreatedDate, Start_Date__c, End_Date__c, Num_Leads_Generated__c, Num_Policies_Bound__c, Organization_Campaign__r.Campaign__r.IsActive, Organization_Campaign__r.Campaign__r.Duration__c, Organization_Campaign__r.Campaign__r.CreatedDate, Organization_Campaign__r.Campaign__r.Min_Leads_Generated__c, Organization_Campaign__r.Campaign__r.Min_Policies_Bound__c FROM Agent_Campaign__c WHERE Id IN: set_AgentCampaignIds]);

            System.debug('map_AgentCampaignsByIds: ' + map_AgentCampaignsByIds);

            for (Agent_Campaign__c ac : map_AgentCampaignsByIds.values()) {

                if ( Trigger.isInsert && (ac.Start_Date__c == null && ac.End_Date__c == null) ) {

                    AgentCampaignStateManagement.setDates(ac);
                }
                else if ( Trigger.isUpdate ) {

                    Agent_Campaign__c oldAC = (Agent_Campaign__c)Trigger.oldMap.get(ac.Id);

                    if ( ac.Num_Leads_Generated__c >= ac.Organization_Campaign__r.Campaign__r.Min_Leads_Generated__c &&
                         ac.Num_Policies_Bound__c >=  ac.Organization_Campaign__r.Campaign__r.Min_Policies_Bound__c ) {

                        ac.Achieved__c = true;
                    }
                    else if ( ac.Num_Leads_Generated__c < ac.Organization_Campaign__r.Campaign__r.Min_Leads_Generated__c ||
                              ac.Num_Policies_Bound__c <  ac.Organization_Campaign__r.Campaign__r.Min_Policies_Bound__c ) {

                        ac.Achieved__c = false;
                    }
                }
            }

            AgentCampaignTriggerHandler.SKIP_RECURSION = true;
            Database.SaveResult[] results = Database.update(map_AgentCampaignsByIds.values());
            AgentCampaignTriggerHandler.SKIP_RECURSION = false;

            Utils.debugSaveResults(results);
        }
    }

    /*
    Valid Context: Before Insert/Update
    Description: Do not allow to create/update an agent campaign in/to active state if it already have an active sibling (SFDC-755)
    */
    private void confirmOneActiveAgentCampaign() {

        if ( Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {

            Set<Id> set_contactsIds = new Set<Id>();

            // prepare a set with all contacts that the AC in trigger context were set to active
            for (Agent_Campaign__c ac : (List<Agent_Campaign__c>) trigger.new) {

                if( ac.Active__c ) {

                    set_contactsIds.add(ac.Agent__c);
                }
            }

            // select all contacts in context with their current active agent campaigns (siblings of the agent compaigns in this trigger context)
            Map<Id, Contact> map_Id2ContactWithAgentCampaigns = null;
            if ( Trigger.isUpdate )
                map_Id2ContactWithAgentCampaigns = new Map<Id, Contact>([SELECT Id, Name, (SELECT Id, Active__c FROM Agent_Campaigns__r WHERE Id NOT IN: Trigger.newMap.keySet() AND Active__c = TRUE) FROM Contact WHERE Id IN: set_contactsIds]);
            else // Trigger.isInsert
                map_Id2ContactWithAgentCampaigns = new Map<Id, Contact>([SELECT Id, Name, (SELECT Id, Active__c FROM Agent_Campaigns__r WHERE Active__c = TRUE) FROM Contact WHERE Id IN: set_contactsIds]);


            System.debug('map_Id2ContactWithAgentCampaigns: ' + map_Id2ContactWithAgentCampaigns);

            for (Agent_Campaign__c ac : (List<Agent_Campaign__c>) trigger.new) {

                if ( ac.Active__c && map_Id2ContactWithAgentCampaigns.get(ac.Agent__c)?.Agent_Campaigns__r.size() > 0 ) {

                    System.debug('Agent Campaign cannot set as active as it has active sibling: ' + map_Id2ContactWithAgentCampaigns.get(ac.Agent__c).Agent_Campaigns__r);

                    // if we are here, it means that the contact in context (a parent of an AC in this trigger context) has other active AC's (siblings)
                    ac.addError(Label.Error_Enforce_One_Active_Agent_Campaign_Per_Agent);
                }
            }
        }
    }
}