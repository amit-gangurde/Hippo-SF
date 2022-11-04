public with sharing class ReorderOminChannelLeadsQueue implements Queueable {

    // Keep the id's of the newly created leads from the trigger transaction that kicked off this queueable
    // Currently this list of record id's is not in use
    private List<Id> lead_ids;

    public ReorderOminChannelLeadsQueue(List<Id> lead_ids) {

        system.debug('inside ReorderOminChannelLeadsQueue ctor');
        this.lead_ids = lead_ids;
    }

    public void execute(QueueableContext context) {

        try {

            Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
            Id B2C_Better_Cover = Utils.getQueueId('B2C_Better_Cover');
            Id B2C_The_Money_Source = Utils.getQueueId('B2C_The_Money_Source');
            Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id SMS_Reactivation = Utils.getQueueId('SMS_Reactivation'); // SMS Reactivation Queue
            Id Facebook_Leads = Utils.getQueueId('Facebook_Leads'); // Facebook Leads
            //Id Hippo_Agency_Sales = Utils.getQueueId('Hippo_Agency_Sales'); (removed also from the query by GroupId in line 31)
            Id HAS_UW_Referrals_Queue = Utils.getQueueId('HAS_UW_Referrals');
            Id HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');
            Id Workable_by_Hippo_1 = Utils.getQueueId('Workable_by_Hippo_1');
            Id Workable_by_Hippo_2 = Utils.getQueueId('Workable_by_Hippo_2');
            Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
            Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');
            Id UW_Referrals_1 = Utils.getQueueId('UW_Referrals_1');
            Id UW_Referrals_2 = Utils.getQueueId('UW_Referrals_2');
            Id HCR_Queue = Utils.getQueueId('Loan_Depot');
            Id HCR_Clicked_on_Link = Utils.getQueueId('HCR_Clicked_on_Link');
            Id HCR_Reached_Prelim_Quote = Utils.getQueueId('HCR_Reached_Prelim_Quote');
            Id PennyMac_Leads = Utils.getQueueId('PennyMac_Leads');
            Id PennyMac_HCR_New_Purchase = Utils.getQueueId('PennyMac_HCR_New_Purchase');
            Id PMIS_HCR_Clicked_on_Link = Utils.getQueueId('PMIS_HCR_Clicked_on_Link');
            Id PMIS_HCR_N_Purchase_Reached_Prelim_Quote = Utils.getQueueId('PMIS_HCR_N_Purchase_Reached_Prelim_Quote');
            Id PMIS_Hippo_Leads_1 = Utils.getQueueId('PMIS_Hippo_Leads_1');
            Id PMIS_HCR_Reached_Prelim_Quote = Utils.getQueueId('PMIS_HCR_Reached_Prelim_Quote');
            Id PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2');
            Id AIA_HCR_Clicked_on_Link = Utils.getQueueId('AIA_HCR_Clicked_on_Link');
            Id AIA_HCR_Reached_Prelim_Quote = Utils.getQueueId('AIA_HCR_Reached_Prelim_Quote');
            Id AIA_Leads = Utils.getQueueId('AIA_Leads');

            String psr_value = Utils.getHippoSettings('PSR_LAST_N_DAYS');

            // List of all LAST_N_DAYS pending PSR's ordered by their CreatedDate DESC
            String query = 'Select Id, CreatedDate, CustomRequestedDatetime, WorkItemId, IsReadyforRouting, IsPushed, GroupId from PendingServiceRouting Where CreatedDate = '
                            + (!Test.isRunningTest() ? 'LAST_N_DAYS:' + psr_value : 'TODAY')
                            + ' And IsPushed = False ' +
                              'And (GroupId =: B2C_Partner_Sales OR GroupId =: B2C_Better_Cover OR GroupId =: B2C_The_Money_Source OR GroupId =: B2C_Direct_Sales ' +
                              'OR GroupId =: SMS_Reactivation OR GroupId =: Facebook_Leads OR GroupId =: HAS_UW_Referrals_Queue OR GroupId =: HAS_UW_Declinations_Queue ' +
                              'OR GroupId =: B2C_Direct_1 OR GroupId =: B2C_Direct_2 OR GroupId =: Workable_by_Hippo_1 OR GroupId =: Workable_by_Hippo_2 ' +
                              'OR GroupId =: B2C_Partner_Sales_1 OR GroupId =: B2C_Partner_Sales_2 OR GroupId =: UW_Referrals_1 OR GroupId =: UW_Referrals_2 ' +
                              'OR GroupId =: HCR_Queue OR GroupId =: HCR_Clicked_on_Link OR GroupId =: HCR_Reached_Prelim_Quote ' +
                              'OR GroupId =: PennyMac_HCR_New_Purchase OR GroupId =: PMIS_HCR_Clicked_on_Link OR GroupId =: PMIS_HCR_N_Purchase_Reached_Prelim_Quote ' +
                              'OR GroupId =: AIA_HCR_Clicked_on_Link OR GroupId =: AIA_HCR_Reached_Prelim_Quote OR GroupId =: AIA_Leads ' +
                              'OR GroupId =: PMIS_Hippo_Leads_1 OR GroupId =: PMIS_HCR_Reached_Prelim_Quote OR GroupId =: PMIS_Hippo_Leads_2 ' +
                              'OR GroupId =: PennyMac_Leads) Order By CreatedDate DESC LIMIT 50000';

            system.debug('query: ' + query);

            List<PendingServiceRouting> lastNDays_pendingWorkItems = Database.query(query);
            if ( FeatureFlags.instance.ff_reSort_PSR ) lastNDays_pendingWorkItems = AsyncUpdatePendingServiceRoutingItems.reSort(lastNDays_pendingWorkItems);
            system.debug('lastNDays_pendingWorkItems size: ' + lastNDays_pendingWorkItems.size());

            DateTime oldest_creation_date = null;

            if ( lastNDays_pendingWorkItems.size() > 0 ) {

                // query for the minimal value (the lowest date) of CustomRequestedDateTime
                List<PendingServiceRouting> minValueOfCustomRequestDateTimePSR = [SELECT Id, Name, CreatedDate, CustomRequestedDateTime FROM PendingServiceRouting ORDER BY CustomRequestedDateTime ASC NULLS LAST LIMIT 1];
                system.debug('minValueOfCustomRequestDateTimePSR: ' + minValueOfCustomRequestDateTimePSR);
                System.debug('FeatureFlags.instance.ff_Fix_Old_Leads_Popping_Into_OmniChannel: ' + FeatureFlags.instance.ff_Fix_Old_Leads_Popping_Into_OmniChannel);

                if ( minValueOfCustomRequestDateTimePSR.size() == 0 || !FeatureFlags.instance.ff_Fix_Old_Leads_Popping_Into_OmniChannel ) {

                    // Highly unlikely to reach here as PSR table is always full, however just in case we, leave the old
                    // implementation as is although it is not good as the minimal value here is not accurate since we only query PSR_LAST_N_DAYS PSR's
                    oldest_creation_date = lastNDays_pendingWorkItems[lastNDays_pendingWorkItems.size() - 1].CreatedDate;
                }
                else { // SFDC-600

                    Integer numOfPendingPSRs = lastNDays_pendingWorkItems.size();
                    DateTime minDateTimeToBeUsed = System.now().addDays(-1 * numOfPendingPSRs); // substract the number of pending items from the current system date (each item is like a day)
                    oldest_creation_date = Test.isRunningTest() ? minValueOfCustomRequestDateTimePSR[0].CreatedDate : minDateTimeToBeUsed; /*minValueOfCustomRequestDateTimePSR[0].CustomRequestedDateTime*/
                }
                // Since during test the creation of records is very fast, we decrease the oldest
                // date in 1 day so not to fail with exception of setting a future date in the code
                // few lines below where we add 1 minute to each custom requested date time
                if ( Test.isRunningTest() ) oldest_creation_date = oldest_creation_date.addDays(-1);
                System.debug('oldest_creation_date: ' + oldest_creation_date);
            }

            if ( !Test.isRunningTest() ) {

                Id jobId = System.enqueueJob(new AsyncUpdatePendingServiceRoutingItems(lastNDays_pendingWorkItems, oldest_creation_date, 1));
            }
            else {

                AsyncUpdatePendingServiceRoutingItems sync_update_pending_items = new AsyncUpdatePendingServiceRoutingItems(lastNDays_pendingWorkItems, oldest_creation_date, 1);
                sync_update_pending_items.execute(null);
            }

        }
        catch(Exception ex) {

            System.debug('Exception from ReorderOminChannelLeadsQueue execution: ' + ex.getMessage());
        }
    }
}