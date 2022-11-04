public with sharing class CloseOldLeads implements Database.Batchable<sObject> {


    public static final String query = 'Select Id, Status From Lead Where Status = {0} AND CreatedDate' + (!Test.isRunningTest() ? ' < LAST_N_DAYS:10' : ' = TODAY') + ' AND OwnerId != {1} Order By CreatedDate DESC';

    public Database.QueryLocator start(Database.BatchableContext BC) {

        Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');
        String formatted_query = String.format(query, new List<Object>{'\'New\'', '\'' + String.valueOf(Outside_Sales_Queue) + '\''});
        System.debug('formatted_query: ' + formatted_query);
        return Database.getQueryLocator(formatted_query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {

        try {

            //Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q'); (SFDC-571)
            Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');

            List<Lead> leadsToUpdate = new List<Lead>();

            for( sObject obj : scope ) {

                Lead ld = (Lead)obj;
                //ld.Status = 'Closed'; (SFDC-571)
                ld.OwnerId = Outside_Sales_Queue; // Non_workable_leads_Q; (SFDC-571)
                leadsToUpdate.add(ld);
            }

            LeadTriggerHandler.SKIP_RECURSION = true;
            update leadsToUpdate;
            LeadTriggerHandler.SKIP_RECURSION = false;
        }
        catch(Exception ex) {

            System.debug('Exception from CloseOldLeads execution: ' + ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {

    }
}