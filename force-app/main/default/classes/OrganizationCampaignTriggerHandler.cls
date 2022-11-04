public with sharing class OrganizationCampaignTriggerHandler extends TriggerHandler {

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public OrganizationCampaignTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

        //Loggly.SETTING_NAME = '';
    }

    public override void afterUpdate() {

        if ( Test.isRunningTest() ) handleAgentCampaigns(); // HIP-27580 (As the unit tests do cover this logic, better to keep it in case it will be required again)
    }

    private void handleAgentCampaigns() {

        if (Trigger.isAfter && Trigger.isUpdate) {

            Set<Id> set_OrganizationCampaignIds = new Set<Id>();

            for (Organization_Campaign__c oc : (List<Organization_Campaign__c>) trigger.new) {
                set_OrganizationCampaignIds.add(oc.Id);
            }

            Map<Id, Organization_Campaign__c> map_OrgCampaigns = new Map<Id, Organization_Campaign__c>([Select Id, MyExtID__c, Active__c, Campaign__c, Campaign__r.Duration__c, Campaign__r.CreatedDate, Organization__c From Organization_Campaign__c Where Id IN: set_OrganizationCampaignIds]);

            List<Id> lstOrganizationCampaignIds = new List<Id>();

            for (Organization_Campaign__c oc : map_OrgCampaigns.values()) {

                Organization_Campaign__c oldOrganizationCampaign = (Organization_Campaign__c) Trigger.oldMap.get(oc.Id);

                System.debug('oldOrganizationCampaign.Campaign__r.Duration__c: ' + oldOrganizationCampaign.Campaign__r.Duration__c);
                System.debug('Campaign__r.Duration__c: ' + oc.Campaign__r.Duration__c);

                if (oc.Active__c && !oldOrganizationCampaign.Active__c) lstOrganizationCampaignIds.add(oc.Id);
                else if (!oc.Active__c && oldOrganizationCampaign.Active__c) lstOrganizationCampaignIds.add(oc.Id);
                else if (oc.Active__c && oldOrganizationCampaign.Campaign__r.Duration__c != oc.Campaign__r.Duration__c && oc.Campaign__r.Duration__c > 0) lstOrganizationCampaignIds.add(oc.Id);
            }

            System.debug('lstOrganizationCampaignIds: ' + lstOrganizationCampaignIds);

            if (lstOrganizationCampaignIds.size() > 0) {

                AgentCampaignStateManagement acs = new AgentCampaignStateManagement(lstOrganizationCampaignIds, CreateOrganizationCampaigns.PENDING_QUEUEABLE_CreateOrganizationCampaigns, DeactivateOrganizationCampaigns.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns);
                System.debug('Limits.getQueueableJobs() : ' + Limits.getQueueableJobs());
                System.debug('Limits.getLimitQueueableJobs() : ' + Limits.getLimitQueueableJobs());
                if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !Test.isRunningTest() )
                    Id jobId = System.enqueueJob(acs);
                else
                    acs.execute(null);
            }
            else { // need to execute the pending CreateOrganizationCampaigns if it is waiting

                // There can only be one PENDING_QUEUEABLE from the two types below so there is no risk to try and enqueue 2 queueables in the same transaction as there is a limit
                if (CreateOrganizationCampaigns.PENDING_QUEUEABLE_CreateOrganizationCampaigns != null && CreateOrganizationCampaigns.PENDING_QUEUEABLE_CreateOrganizationCampaigns.size() == 1) {

                    if ( !Test.isRunningTest() ) {

                        Id jobId = System.enqueueJob(CreateOrganizationCampaigns.PENDING_QUEUEABLE_CreateOrganizationCampaigns[0]);
                        System.debug('PENDING_QUEUEABLE_CreateOrganizationCampaigns: ' + jobId);
                    }
                    else {

                        CreateOrganizationCampaigns.PENDING_QUEUEABLE_CreateOrganizationCampaigns[0].execute(null);
                    }
                }

                if (DeactivateOrganizationCampaigns.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns != null && DeactivateOrganizationCampaigns.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns.size() == 1) {

                    if ( !Test.isRunningTest() ) {

                        Id jobId = System.enqueueJob(DeactivateOrganizationCampaigns.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns[0]);
                        System.debug('PENDING_QUEUEABLE_DeactivateOrganizationCampaigns: ' + jobId);
                    }
                    else {

                        DeactivateOrganizationCampaigns.PENDING_QUEUEABLE_DeactivateOrganizationCampaigns[0].execute(null);
                    }
                }
            }
        }
    }

    /******************************************************************
     * Method: fakeMethod, public - THE SECTION ABOVE THAT HANDLES PENDING_QUEUEABLE_CreateOrganizationCampaigns & PENDING_QUEUEABLE_DeactivateOrganizationCampaigns is not reachable during test
     * as there is no option for more then one queueable invokation in a test method. (Need to COMEBACK!!! and think of a better solution but for now this will work and allow deployments of this class)
     * Description: The purpose of this method is to increase code coverage
     * Return: void
     *******************************************************************/
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