public with sharing class AccountTriggerHandler extends TriggerHandler {

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public AccountTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

        //Loggly.SETTING_NAME = '';
    }

    public override void afterInsert() {
        
        createOrganizationCampaigns();
    }

    private void createOrganizationCampaigns() {

        if (Trigger.isAfter && Trigger.isInsert) {

            Set<Id> set_AccountIds = new Set<Id>();

            Id IndustriesBusinessRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();

            for (Account acc : (List<Account>) trigger.new) {

                if (acc.RecordTypeId == IndustriesBusinessRTId) set_AccountIds.add(acc.Id);
            }

            Map<Id, Account> map_NewAccountIds = new Map<Id, Account>((List<Account>) Database.query('Select Id, Name, (select Id, Name from contacts) From Account WHERE Id IN: set_AccountIds'));
            system.debug('map_NewAccountIds: ' + map_NewAccountIds);

            if (map_NewAccountIds.size() > 0) {

                CreateOrganizationCampaigns coc = new CreateOrganizationCampaigns(map_NewAccountIds, null, true, false);
                system.debug('AccountTriggerHandler: Limits.getQueueableJobs() : ' + Limits.getQueueableJobs());
                system.debug('AccountTriggerHandler: Limits.getLimitQueueableJobs() : ' + Limits.getLimitQueueableJobs());
                if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !Test.isRunningTest() )
                    Id jobId = System.enqueueJob(coc);
                else
                    coc.execute(null);
            }
        }
    }
}