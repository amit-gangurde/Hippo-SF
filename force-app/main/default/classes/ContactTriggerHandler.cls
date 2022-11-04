public with sharing class ContactTriggerHandler extends TriggerHandler {

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public ContactTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

        //Loggly.SETTING_NAME = '';
    }

    public override void afterInsert() {

        createAgentCampaigns();
    }

    private void createAgentCampaigns() {

        if (Trigger.isAfter && Trigger.isInsert) {

            List<Contact> lst_ContactsOfInterest = [SELECT Id, AccountId, Account.RecordTypeId FROM Contact WHERE Id IN: trigger.newMap.keySet()];
            system.debug('ContactTriggerHandler: lst_ContactsOfInterest: ' + lst_ContactsOfInterest);

            Set<Id> set_ContactIdsOfInterest = new Set<Id>();
            Set<Id> set_AccountIds = new Set<Id>();

            Id IndustriesBusinessRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();

            for (Contact con : lst_ContactsOfInterest) {

                if (con.Account.RecordTypeId == IndustriesBusinessRTId) {

                    set_ContactIdsOfInterest.add(con.Id);
                    set_AccountIds.add(con.AccountId);
                }
            }

            system.debug('ContactTriggerHandler: set_ContactIdsOfInterest: ' + set_ContactIdsOfInterest);
            system.debug('ContactTriggerHandler: set_AccountIds: ' + set_AccountIds);

            Map<Id, Account> map_AccountIdsOfInterest = new Map<Id, Account>((List<Account>) Database.query('Select Id, Name, (select Id, Name from contacts WHERE Id IN: set_ContactIdsOfInterest) From Account WHERE Id IN: set_AccountIds'));
            system.debug('ContactTriggerHandler: map_AccountIdsOfInterest: ' + map_AccountIdsOfInterest);

            if (map_AccountIdsOfInterest.size() > 0) {

                // ==== SFDC=509 ====
                Map<Id, Map<String, License__c>> map_LicensesByContactId = ContactTriggerHandler.getContactsLicensesByState(set_ContactIdsOfInterest);
                System.debug('ContactTriggerHandler: map_LicensesByContactId: ' + map_LicensesByContactId);
                Map<Id, Campaign> map_Restricted2StateCampaigns = CampaignTriggerHandler.getRestricted2StateCampaigns('Producer_Incentive_Campaign'); //new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = TRUE AND RecordType.DeveloperName = 'Producer_Incentive_Campaign' ORDER BY Reward_Amount__c, CreatedDate DESC]);
                System.debug('ContactTriggerHandler: map_Restricted2StateCampaigns: ' + map_Restricted2StateCampaigns);
                Map<Id, Campaign> map_NonRestricted2StateCampaigns = CampaignTriggerHandler.getMostAttractiveNonRestricted2StateCampaign('Producer_Incentive_Campaign'); //new Map<Id, Campaign>([SELECT Id, Duration__c, IsActive, State__c, Restricted_To_State__c, Reward_Amount__c, CreatedDate FROM Campaign WHERE Restricted_To_State__c = FALSE AND RecordType.DeveloperName = 'Producer_Incentive_Campaign' ORDER BY Reward_Amount__c, CreatedDate DESC LIMIT 1]);
                System.debug('ContactTriggerHandler: map_NonRestricted2StateCampaigns: ' + map_NonRestricted2StateCampaigns);
                CreateOrganizationCampaigns coc = new CreateOrganizationCampaigns(map_Restricted2StateCampaigns, map_NonRestricted2StateCampaigns, map_AccountIdsOfInterest, map_LicensesByContactId);
                // ==== SFDC=509 ====

                //CreateOrganizationCampaigns coc = new CreateOrganizationCampaigns(map_AccountIdsOfInterest, null, false, true);
                system.debug('ContactTriggerHandler: Limits.getQueueableJobs() : ' + Limits.getQueueableJobs());
                system.debug('ContactTriggerHandler: Limits.getLimitQueueableJobs() : ' + Limits.getLimitQueueableJobs());
                if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !Test.isRunningTest() )
                    Id jobId = System.enqueueJob(coc);
                else
                    coc.execute(null);
            }
        }
    }

    /*
    Method: getContactsLicensesByState
    Description: Trivial
    Return: Map<Id, Map<String,License__c>> - Map between Contact Id to a Map of State to License to this specific Contact
    */
    public static Map<Id, Map<String, License__c>> getContactsLicensesByState(Set<Id> contactIds) {

        Map<Id, Map<String, License__c>> results = new Map<Id, Map<String, License__c>>();

        try {

            List<License__c> licenses  = [Select Id, Contact__c, State_Code__c FROM License__c WHERE Contact__c IN: contactIds];

            for ( License__c license : licenses ) {

                if ( !results.containsKey(license.Contact__c) ) {

                    if ( String.isNotBlank(license.State_Code__c) ) {

                        results.put(license.Contact__c, new Map<String, License__c>{
                                license.State_Code__c => license
                        });
                    }
                }
                else {

                    if ( !results.get(license.Contact__c).containsKey(license.State_Code__c) ) {

                        results.get(license.Contact__c).put(license.State_Code__c, license);
                    }
                }
            }

            // go over all contacts and add to the map the missing ones as it could be that some of the contacts won't have any single license so we'll add with empty list of licenses
            for (Id contactId: contactIds) {

                if ( !results.containsKey(contactId) ) {

                    results.put(contactId, new Map<String, License__c>{});
                }
            }
        }
        catch (Exception ex) {

            System.debug('Exception from getContactsLicensesByState : ' + ex.getMessage() + ex.getStackTraceString());
        }

        return results;
    }

    /*
    Method: getContactsLicensesByState
    Description: Trivial
    Return: Map<Id, Map<String,License__c>> - Map between Contact Id to a Map of State to License to this specific Contact
    */
    public static Map<Id, Map<String, License__c>> getContactsLicensesByState(Set<Id> contactIds, Set<Id> licenseIds) {

        Map<Id, Map<String, License__c>> results = new Map<Id, Map<String, License__c>>();

        try {

            List<License__c> licenses  = [Select Id, Contact__c, State_Code__c FROM License__c WHERE Id IN: licenseIds AND Contact__c IN: contactIds];

            for ( License__c license : licenses ) {

                if ( !results.containsKey(license.Contact__c) ) {

                    if ( String.isNotBlank(license.State_Code__c) ) {

                        results.put(license.Contact__c, new Map<String, License__c>{
                                license.State_Code__c => license
                        });
                    }
                }
                else {

                    if ( !results.get(license.Contact__c).containsKey(license.State_Code__c) ) {

                        results.get(license.Contact__c).put(license.State_Code__c, license);
                    }
                }
            }

            // go over all contacts and add to the map the missing ones as it could be that some of the contacts won't have any single license so we'll add with empty list of licenses
            for (Id contactId: contactIds) {

                if ( !results.containsKey(contactId) ) {

                    results.put(contactId, new Map<String, License__c>{});
                }
            }
        }
        catch (Exception ex) {

            System.debug('Exception from getContactsLicensesByState : ' + ex.getMessage() + ex.getStackTraceString());
        }

        return results;
    }
}