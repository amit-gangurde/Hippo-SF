public with sharing class LicenseTriggerHandler extends TriggerHandler {

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public LicenseTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

    }

    public override void afterInsert() {

        reValidateAgentCampaigns();
    }

    public override void afterUpdate() {

        if ( Utils.isCurrentUserAPI() ) {

            return;
        }

        reValidateAgentCampaigns();
    }

    /******************************************************************
    * Method: reValidateAgentCampaigns, private
    * Description: Go through all agent campaigns related to the contacts of the license records and if they are not active,
    *               assign them to the higher reward amount campaign (SFDC-509)
    * Return: void
    *******************************************************************/
    private void reValidateAgentCampaigns() {

        try {

            if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

                List<License__c> lst_LicensesOfInterest = [SELECT Id, State_Code__c, Contact__c, Contact__r.AccountId, Contact__r.Account.RecordTypeId FROM License__c WHERE Id IN: trigger.newMap.keySet()];

                Set<Id> set_ContactIdsOfInterest = new Set<Id>();
                Set<Id> set_AccountIds = new Set<Id>();

                Id IndustriesBusinessRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();

                for (License__c lic : lst_LicensesOfInterest) {

                    if (lic.Contact__r.Account.RecordTypeId == IndustriesBusinessRTId) {

                        set_ContactIdsOfInterest.add(lic.Contact__c);
                        set_AccountIds.add(lic.Contact__r.AccountId);
                    }
                }

                system.debug('LicenseTriggerHandler: set_ContactIdsOfInterest: ' + set_ContactIdsOfInterest);
                system.debug('LicenseTriggerHandler: set_AccountIds: ' + set_AccountIds);

                Map<Id, Account> map_AccountIdsOfInterest = new Map<Id, Account>((List<Account>) Database.query('Select Id, Name, (select Id, Name from contacts WHERE Id IN: set_ContactIdsOfInterest) From Account WHERE Id IN: set_AccountIds'));
                system.debug('LicenseTriggerHandler: map_AccountIdsOfInterest: ' + map_AccountIdsOfInterest);

                if (map_AccountIdsOfInterest.size() > 0) {

                    // ==== SFDC=509 ====
                    Map<Id, Map<String, License__c>> map_LicensesByContactId = ContactTriggerHandler.getContactsLicensesByState(set_ContactIdsOfInterest, Trigger.newMap.keySet());
                    System.debug('LicenseTriggerHandler: map_LicensesByContactId: ' + map_LicensesByContactId);
                    Map<Id, Campaign> map_Restricted2StateCampaigns    = CampaignTriggerHandler.getRestricted2StateCampaigns('Producer_Incentive_Campaign'); //new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = TRUE AND RecordType.DeveloperName = 'Producer_Incentive_Campaign' ORDER BY Reward_Amount__c DESC, CreatedDate DESC]);
                    System.debug('LicenseTriggerHandler: map_Restricted2StateCampaigns: ' + map_Restricted2StateCampaigns);
                    Map<Id, Campaign> map_NonRestricted2StateCampaigns = CampaignTriggerHandler.getMostAttractiveNonRestricted2StateCampaign('Producer_Incentive_Campaign'); //new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = FALSE AND RecordType.DeveloperName = 'Producer_Incentive_Campaign' ORDER BY Reward_Amount__c DESC, CreatedDate DESC LIMIT 1]);
                    System.debug('LicenseTriggerHandler: map_NonRestricted2StateCampaigns: ' + map_NonRestricted2StateCampaigns);
                    CreateOrganizationCampaigns coc = new CreateOrganizationCampaigns(map_Restricted2StateCampaigns, map_NonRestricted2StateCampaigns, map_AccountIdsOfInterest, map_LicensesByContactId);
                    // ==== SFDC=509 ====

                    system.debug('LicenseTriggerHandler: Limits.getQueueableJobs() : ' + Limits.getQueueableJobs());
                    system.debug('LicenseTriggerHandler: Limits.getLimitQueueableJobs() : ' + Limits.getLimitQueueableJobs());
                    if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !Test.isRunningTest() )
                        Id jobId = System.enqueueJob(coc);
                    else
                        coc.execute(null);
                }
            }
        }
        catch (Exception ex) {

        }
    }
}