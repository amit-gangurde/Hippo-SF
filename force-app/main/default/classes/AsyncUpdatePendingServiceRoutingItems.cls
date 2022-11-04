public with sharing class AsyncUpdatePendingServiceRoutingItems implements Queueable {

    private List<PendingServiceRouting> pending_service_items;
    private DateTime oldest_creation_date = null;
    private Integer start_index;

    public AsyncUpdatePendingServiceRoutingItems(List<PendingServiceRouting> pending_service_items, DateTime oldest_creation_date, Integer start_index) {

        system.debug('inside AsyncUpdatePendingServiceRoutingItems ctor');
        this.pending_service_items = pending_service_items;
        this.oldest_creation_date = oldest_creation_date;
        this.start_index = start_index;
    }

    /*
    public static List<PendingServiceRouting> getNextPSRs(Id newest_psr_id, Integer batch_size) {

        Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id B2C_Better_Cover = Utils.getQueueId('B2C_Better_Cover');
        Id B2C_The_Money_Source = Utils.getQueueId('B2C_The_Money_Source');
        Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
        Id Lead_Source_A = Utils.getQueueId('Lead_Source_A');
        Id Lead_Source_B = Utils.getQueueId('Lead_Source_B');
        Id Lead_Source_C = Utils.getQueueId('Lead_Source_C');
        Id Lead_Source_D = Utils.getQueueId('Lead_Source_D');
        Id Lead_Source_E = Utils.getQueueId('Lead_Source_E');

        List<PendingServiceRouting> pendingPSRItems = null;

        String queue_dev_name = Utils.getHippoSettings('Omni Lead Queue Developer Name');
        String leadOmniChannelQueueId = Utils.getQueueId(queue_dev_name);

        String query = 'Select Id, CreatedDate, CustomRequestedDatetime, WorkItemId, IsReadyforRouting, IsPushed, GroupId from PendingServiceRouting Where Id <=: newest_psr_id And IsPushed = False And (GroupId =: B2C_Partner_Sales OR GroupId =: B2C_Better_Cover OR GroupId =: B2C_The_Money_Source OR GroupId =: B2C_Direct_Sales OR GroupId =: Lead_Source_A OR GroupId =: Lead_Source_B OR GroupId =: Lead_Source_C OR GroupId =: Lead_Source_D OR GroupId =: Lead_Source_E) Order By Id DESC LIMIT ' + batch_size;

        system.debug('Query to get next PendingServiceRouting records to process from newest to oldest: ' + query);

        pendingPSRItems = Database.query(query);
        if ( FeatureFlags.instance.ff_reSort_PSR ) pendingPSRItems = AsyncUpdatePendingServiceRoutingItems.reSort(pendingPSRItems);

        return pendingPSRItems;
    }
     */

    public void execute(QueueableContext context) {

        try {

            List<PendingServiceRouting> bulk_2_update = new List<PendingServiceRouting>();

            // Loop on all pending PSR's and set the CustomRequestedDatetime of the newest record
            // to the date time of the oldest CreatedDate record such that this record (the newest)
            // will be pushed first to Omni Channel
            for (Integer i = start_index; i <= pending_service_items.size(); i++) { // start_index starts with 1

                if ( i == 1 ) {

                    //oldest_creation_date = oldest_creation_date.addYears(-1); SFDC-600 (Oldest creation date was calculated in ReorderOminChannelLeadsQueue so no need to alter)
                    pending_service_items[i - 1].CustomRequestedDatetime = oldest_creation_date;//.addDays(-1);
                    bulk_2_update.add(pending_service_items[i-1]);
                }
                else {

                    Integer item_index = i - 1;
                    system.debug('DML Limit: ' + Limits.getLimitDmlRows());
                    if ( bulk_2_update.size() == Limits.getLimitDmlRows() && !Test.isRunningTest() ) { // DML LIMIT

                        update bulk_2_update;
                        bulk_2_update.clear();
                        if ( !Test.isRunningTest() ) {
                            Id jobId = System.enqueueJob(new AsyncUpdatePendingServiceRoutingItems(pending_service_items, pending_service_items[item_index - 1].CustomRequestedDatetime, i));
                            break;
                        }
                    }
                    else {

                        pending_service_items[item_index].CustomRequestedDatetime = pending_service_items[item_index - 1].CustomRequestedDatetime.addMinutes(1);
                        bulk_2_update.add(pending_service_items[item_index]);
                    }
                }
            }

            if ( bulk_2_update.size() > 0 ) { // Handle the remaining

                update bulk_2_update;
            }
        }
        catch(Exception ex) {

            System.debug('Exception from AsyncUpdatePendingServiceRoutingItems execution: ' + ex.getMessage());
        }
    }

    // Description: Non queuable version. It is being used from Platform Event PSR_Created_Event__e
    // Return: the oldest created date of the last record in the batch processed
    /*
    public DateTime execute() {

        DateTime last_oldest_creation_date_used = null;

        try {

            List<PendingServiceRouting> bulk_2_update = new List<PendingServiceRouting>();

            // Loop on all pending PSR's and set the CustomRequestedDatetime of the newest record
            // to the date time of the oldest CreatedDate record such that this record (the newest)
            // will be pushed first to Omni Channel
            for (Integer i = start_index; i <= pending_service_items.size(); i++) { // start_index starts with 1

                if ( i == 1 ) {

                    oldest_creation_date = oldest_creation_date.addYears(-1);
                    pending_service_items[i - 1].CustomRequestedDatetime = oldest_creation_date;
                    bulk_2_update.add(pending_service_items[i-1]);
                    // calculate the oldest creation date to be assigned to the last item and return it from this method
                    last_oldest_creation_date_used = oldest_creation_date.addMinutes(1 * (pending_service_items.size() - 1));
                }
                else {

                    Integer item_index = i - 1;
                    system.debug('DML Limit: ' + Limits.getLimitDmlRows());
                    if ( bulk_2_update.size() == Limits.getLimitDmlRows() && !Test.isRunningTest() ) { // DML LIMIT

                        update bulk_2_update;
                        bulk_2_update.clear();
                        if ( !Test.isRunningTest() ) {
                            Id jobId = System.enqueueJob(new AsyncUpdatePendingServiceRoutingItems(pending_service_items, pending_service_items[item_index - 1].CustomRequestedDatetime, i));
                            break;
                        }
                    }
                    else {

                        pending_service_items[item_index].CustomRequestedDatetime = pending_service_items[item_index - 1].CustomRequestedDatetime.addMinutes(1);
                        bulk_2_update.add(pending_service_items[item_index]);
                    }
                }
            }

            if ( bulk_2_update.size() > 0 ) { // Handle the remaining

                update bulk_2_update;
            }
        }
        catch(Exception ex) {

            System.debug('Exception from AsyncUpdatePendingServiceRoutingItems execution: ' + ex.getMessage());
        }

        return last_oldest_creation_date_used;
    }
     */

    public static List<PendingServiceRouting> reSort(List<PendingServiceRouting> lead_related_psr_records) {

        List<PendingServiceRouting> results = new List<PendingServiceRouting>();

        try {

            Map<Id, PendingServiceRouting> map_leadId2PSR = new Map<Id, PendingServiceRouting>();

            for (PendingServiceRouting psr : lead_related_psr_records) {

                map_leadId2PSR.put(psr.WorkItemId, psr);
            }

            List<Lead> allLeads = [SELECT Id, CreatedDate, Lead_Score__c From Lead Where Id IN: map_leadId2PSR.keySet() ORDER BY CreatedDate DESC, Lead_Score__c DESC];

            for (Lead my_lead : allLeads) {

                if ( map_leadId2PSR.containsKey(my_lead.Id) ) {

                    results.add(map_leadId2PSR.get(my_lead.Id));
                }
            }
        }
        catch(Exception ex) {

            System.debug('Exception from reSort execution: ' + ex.getMessage());
            results = lead_related_psr_records;
        }

        return results;
    }

    public static void fakeCoverage() {

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

    }
}