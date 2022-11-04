public with sharing class LeadTriggerHandler extends TriggerHandler {

    public static Boolean TESTING_INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY = false;

    public static Boolean SKIP_RECURSION = false;
    public static Boolean SKIP_AFTER_UPDATE = false;
    public static Boolean SKIP_DISTRIBUTED_UPDATE = false;

    public static Boolean TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;
    public static Boolean TESTING_ALLOW_24_7_BUSINESS_HOURS = false; // The purpose of this flag is to allow leads creation during TEST to skip EST/PST business hours logic

    public static Map<String, Boolean> map_toggledOffLeadScores = Utils.getToggledOffLeadScores();

    // Public Static Constants
    public static final Id Outside_Sales_Queue;
    public static final Id Non_workable_leads_Q;
    //public static final String est_pending_queue_dev_name;
    //public static final String pst_pending_queue_dev_name;
    public static final Id estPendingLeadsQueue;
    public static final Id pstPendingLeadsQueue;

    public static final Id Techsee_Queue;
    public static final Id SMS_Reactivation;
    public static final Id Facebook_Leads;
    public static final Id Lead_High_Urgency_Queue;
    public static final Id Lead_Prebind_UW_Referrals;
    public static final Id Lead_Partner_Channel_High_Urgency_Queue;
    //public static final Id Hippo_Agency_Sales_Queue;
    public static final Id HAS_Internal_Referrals_Queue;
    public static final Id HAS_UW_Referrals_Queue;
    public static final Id HAS_UW_Declinations_Queue;

    /* Start: Changes based on SFDC-1540. Once finalized need to remove some old redundant code and improve cleanups */
    public static final Id B2C_Direct_1;
    public static final Id B2C_Direct_2;
    public static final Id Workable_by_Hippo_1;
    public static final Id Workable_by_Hippo_2;
    public static final Id B2C_Partner_Sales_1;
    public static final Id B2C_Partner_Sales_2;
    public static final Id UW_Referrals_1;
    public static final Id UW_Referrals_2;
    public static final Id Facebook_Direct;
    /* End: Changes based on SFDC-1540 */

    /* Start: Changes based on SFDC-1752. New Lead Prioritization for PennyMac */
    public static final Id PennyMac_HCR_New_Purchase;
    public static final Id PMIS_HCR_Clicked_on_Link;
    public static final Id PMIS_HCR_N_Purchase_Reached_Prelim_Quote;
    public static final Id PMIS_Hippo_Leads_1;
    public static final Id PMIS_HCR_Reached_Prelim_Quote;
    public static final Id PMIS_Hippo_Leads_2;
    /* End: Changes based on SFDC-1752 */

    /* Start: Changes based on SFDC-1848. New Lead Prioritization for PennyMac */
    public static final Id AIA_HCR_Clicked_on_Link;
    public static final Id AIA_HCR_Reached_Prelim_Quote;
    public static final Id AIA_Leads;
    /* End: Changes based on SFDC-1848 */

    public static final Map<String, Utils.StateInfo> map_State2StateInfo;

    public List<String> Excluded_RecordTypes_by_Name;
    public List<String> Excluded_RecordTypes_by_Id;
    public List<String> Inside_Sales_Contractors_States;

    private Map<Id, Account> accounts_in_context;

    public static String SMS_Reactivation_Dummy_Account_Name = String.valueOf('SMS_Reactivation').toLowerCase();

    /* JV's */
    public static String Pennymac_Related_Token = String.valueOf('Pennymac').toLowerCase();
    public static String AmeriSave_Related_Token = String.valueOf('AmeriSave').toLowerCase();

    private Map<Id, Account> jv_accounts_in_context;
    private static Set<Id> jv_accounts_ids;
    public static String Pennymac_Org_Id = '';
    public static String AmeriSave_Org_Id = '';

    /* HCR's */
    private Map<Id, Account> hcr_accounts_in_context;
    private static Set<Id> hcr_accounts_ids;
    public static String FirstStreet_Org_Id = '';
    public static String LoanDepot_Org_Id = '';
    public static String HippoAnalytics_Org_Id = '';

    // Structure and variables for SFDC-1838 (Leads created by a Salesforce user should not route to a queue based on routing rules)

    /*
    class LeadItem
    ==============
    Structure to assign a realtime unique identifier for leads in context (trigger.new),
    that is since during Before Insert event we do not have Sfdc Id yet and we do need to make sure
    to properly capture leads creator during different phases of the transaction logic
    */
    public class LeadItem {

        public String unique_identifier;
        public Id created_by_id;
        public User created_by_user;
        public Lead my_lead;

        public LeadItem(Lead theLead) {

            this.my_lead = theLead;
            this.unique_identifier = Utils.getRandomString(5);

            System.debug('LeadItem ctor, theLead.CreatedById: ' + theLead.CreatedById);
            System.debug('LeadItem ctor, theLead.OwnerId: ' + theLead.OwnerId);

            if ( theLead.CreatedById == null ) // not available during Before Insert
                this.created_by_id = theLead.OwnerId;
            else
                this.created_by_id = theLead.CreatedById;
        }
    }

    /*
    class LeadItems
    ==============
    Collection of LeadItem(s)
    */
    public class LeadItems {

        public List<LeadItem> lst_LeadItems;
        public Set<Id> userIds;

        public LeadItems() {

            lst_LeadItems = new List<LeadItem>();
            userIds = new Set<Id>();
        }

        public void add(LeadItem leadItem) {

            if ( null != leadItem ) {

                lst_LeadItems.add(leadItem);

                if ( null != leadItem.created_by_id ) userIds.add(leadItem.created_by_id);
            }
        }

        public Set<Id> getUserIds() {

           return userIds;
        }

        public void injectUserInformation(Map<Id, User> map_UsersInContext) {

            for (LeadItem leadItem : lst_LeadItems) {

                if ( map_UsersInContext.containsKey(leadItem.created_by_id) ) {

                    leadItem.created_by_user = map_UsersInContext.get(leadItem.created_by_id);
                }
            }
        }
    }

    private LeadItems objLeadItems;
    private Map<String, Boolean> map_LeadUniqueId2IsCreatedByAgent;

    // Variables for SFDC-1838 (Leads created by a Salesforce user should not route to a queue based on routing rules)

    static {

        System.debug('LeadTriggerHandler static initialization');

        Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');
        Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
        //pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
        estPendingLeadsQueue = Utils.getQueueId('EST_Pending_Leads');//(est_pending_queue_dev_name);
        pstPendingLeadsQueue = Utils.getQueueId('PST_Pending_Leads');//(pst_pending_queue_dev_name);
        Techsee_Queue = Utils.getQueueId('Techsee_Queue');
        SMS_Reactivation = Utils.getQueueId('SMS_Reactivation');
        Facebook_Leads = Utils.getQueueId('Facebook_Leads');
        Lead_High_Urgency_Queue = Utils.getQueueId('High_Urgency_Queue');
        Lead_Prebind_UW_Referrals = Utils.getQueueId('Prebind_UW_Referrals');
        Lead_Partner_Channel_High_Urgency_Queue = Utils.getQueueId('Partner_Channel_High_Urgency_Queue');
        //Hippo_Agency_Sales_Queue = Utils.getQueueId('Hippo_Agency_Sales');
        HAS_Internal_Referrals_Queue = Utils.getQueueId('HAS_Internal_Referrals');
        HAS_UW_Referrals_Queue = Utils.getQueueId('HAS_UW_Referrals'); // deprecated
        HAS_UW_Declinations_Queue = Utils.getQueueId('HAS_UW_Declinations');
        B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
        B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');
        Workable_by_Hippo_1 = Utils.getQueueId('Workable_by_Hippo_1');
        Workable_by_Hippo_2 = Utils.getQueueId('Workable_by_Hippo_2');
        B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
        B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');
        UW_Referrals_1 = Utils.getQueueId('UW_Referrals_1');
        UW_Referrals_2 = Utils.getQueueId('UW_Referrals_2');
        Facebook_Direct = Utils.getQueueId('Facebook_Direct');
        PennyMac_HCR_New_Purchase = Utils.getQueueId('PennyMac_HCR_New_Purchase');
        PMIS_HCR_Clicked_on_Link = Utils.getQueueId('PMIS_HCR_Clicked_on_Link');
        PMIS_HCR_N_Purchase_Reached_Prelim_Quote = Utils.getQueueId('PMIS_HCR_N_Purchase_Reached_Prelim_Quote');
        PMIS_Hippo_Leads_1 = Utils.getQueueId('PMIS_Hippo_Leads_1');
        PMIS_HCR_Reached_Prelim_Quote = Utils.getQueueId('PMIS_HCR_Reached_Prelim_Quote');
        PMIS_Hippo_Leads_2 = Utils.getQueueId('PMIS_Hippo_Leads_2');
        AIA_HCR_Clicked_on_Link = Utils.getQueueId('AIA_HCR_Clicked_on_Link');
        AIA_HCR_Reached_Prelim_Quote = Utils.getQueueId('AIA_HCR_Reached_Prelim_Quote');
        AIA_Leads = Utils.getQueueId('AIA_Leads');

        map_State2StateInfo = Utils.getStates2StateInfo();

        /* JV's */

        jv_accounts_ids = new Set<Id>();

        if ( FeatureFlags.instance.ff_Inject_Org_to_JV_Leads ) {

            String Pennymac_Org_Name = Utils.getHippoSettings('PennyMac Org');
            System.debug('Pennymac_Org_Name: ' + Pennymac_Org_Name);
            if (String.isNotBlank(Pennymac_Org_Name)) {

                List<Account> accounts = [SELECT ID FROM Account WHERE Name = :Pennymac_Org_Name LIMIT 1];
                if (accounts.size() > 0) {
                    Pennymac_Org_Id = accounts[0].Id;
                    jv_accounts_ids.add(Pennymac_Org_Id);
                }
            }

            String AmeriSave_Org_Name = Utils.getHippoSettings('AmeriSave Org');
            System.debug('AmeriSave_Org_Name: ' + AmeriSave_Org_Name);
            if (String.isNotBlank(AmeriSave_Org_Name)) {

                List<Account> accounts = [SELECT ID FROM Account WHERE Name = :AmeriSave_Org_Name LIMIT 1];
                if (accounts.size() > 0) {
                    AmeriSave_Org_Id = accounts[0].Id;
                    jv_accounts_ids.add(AmeriSave_Org_Id);
                }
            }

            System.debug('Pennymac_Org_Id: ' + Pennymac_Org_Id);
            System.debug('AmeriSave_Org_Id: ' + AmeriSave_Org_Id);
        }

        /* HCR's */

        System.debug('FeatureFlags.instance.ff_Inject_Org_to_HCR_Leads: ' + FeatureFlags.instance.ff_Inject_Org_to_HCR_Leads);
        System.debug('LeadTriggerHandler.TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR: ' + LeadTriggerTest.TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR);

        hcr_accounts_ids = new Set<Id>();

        if ( FeatureFlags.instance.ff_Inject_Org_to_HCR_Leads || LeadTriggerTest.TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR ) {

            String FirstStreet_Org_Name = Utils.getHippoSettings('First Street Org');
            System.debug('FirstStreet_Org_Name: ' + FirstStreet_Org_Name);
            if (String.isNotBlank(FirstStreet_Org_Name)) {

                List<Account> accounts = [SELECT ID FROM Account WHERE Name = :FirstStreet_Org_Name LIMIT 1];
                if (accounts.size() > 0) {
                    FirstStreet_Org_Id = accounts[0].Id;
                    hcr_accounts_ids.add(FirstStreet_Org_Id);
                }
            }

            String LoanDepot_Org_Name = Utils.getHippoSettings('Loan Depot Org');
            System.debug('LoanDepot_Org_Name: ' + LoanDepot_Org_Name);
            if (String.isNotBlank(LoanDepot_Org_Name)) {

                List<Account> accounts = [SELECT ID FROM Account WHERE Name = :LoanDepot_Org_Name LIMIT 1];
                if (accounts.size() > 0) {
                    LoanDepot_Org_Id = accounts[0].Id;
                    hcr_accounts_ids.add(LoanDepot_Org_Id);
                }
            }

            System.debug('FirstStreet_Org_Id: ' + FirstStreet_Org_Id);
            System.debug('LoanDepot_Org_Id: ' + LoanDepot_Org_Id);
        }

        String HippoAnalytics_Org_Name = Utils.getHippoSettings('Hippo Analytics Org');
        System.debug('HippoAnalytics_Org_Name: ' + HippoAnalytics_Org_Name);
        if (String.isNotBlank(HippoAnalytics_Org_Name)) {

            List<Account> accounts = [SELECT ID FROM Account WHERE Name = :HippoAnalytics_Org_Name LIMIT 1];
            if (accounts.size() > 0) {
                HippoAnalytics_Org_Id = accounts[0].Id;
                hcr_accounts_ids.add(HippoAnalytics_Org_Id);
            }
        }

        System.debug('HippoAnalytics_Org_Id: ' + HippoAnalytics_Org_Id);
    }

    public class LeadRoutingInfo {

        public Boolean is_has;
        public String  queue_dev_name;
        public Id      queue_id;
        public String  lead_source;
        public String  disqualified_reason;

        public LeadRoutingInfo() {

            is_has = false;
            queue_dev_name = '';
            queue_id = null;
            lead_source = '';
            disqualified_reason = '';
        }
    }

    private void setupLeadContextInTransaction() {

        objLeadItems = new LeadItems();

        for (SObject theLead : trigger.new) {

            Lead my_lead = (Lead) theLead;

            objLeadItems.add(new LeadItem(my_lead));
        }

        Set<Id> userIds = objLeadItems.getUserIds();
        System.debug('userIds: ' + userIds);

        Map<Id, User> map_UsersInContext = new Map<Id, User>([SELECT Id, Profile.Id, Profile.Name FROM User WHERE Id IN: userIds]);
        System.debug('map_UsersInContext: ' + map_UsersInContext);

        objLeadItems.injectUserInformation(map_UsersInContext);

        map_LeadUniqueId2IsCreatedByAgent = new Map<String, Boolean>();
        System.debug('map_LeadUniqueId2IsCreatedByAgent: ' + map_LeadUniqueId2IsCreatedByAgent);
    }
    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public LeadTriggerHandler() {

        System.debug('LeadTriggerHandler ctor');

        setupLeadContextInTransaction();

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

        Excluded_RecordTypes_by_Name = new List<String>();
        String value_1 = Utils.getHippoSettings('Excluded Lead Record Types');
        Excluded_RecordTypes_by_Name = value_1.split(';');

        Excluded_RecordTypes_by_Id = new List<String>();
        for (String recTypeName : Excluded_RecordTypes_by_Name) {
            Excluded_RecordTypes_by_Id.add(Schema.SObjectType.Lead.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId());
        }

        Inside_Sales_Contractors_States = new List<String>();
        String value_2 = Utils.getHippoSettings('Inside Sales Contractors States');
        Inside_Sales_Contractors_States = value_2.split(';');
        System.debug('Inside_Sales_Contractors_States: ' + Inside_Sales_Contractors_States);
    }

    public override void beforeInsert() {

        // === START TEMP ==============================================
        // For testing purposes only. set the lead owner to an Omni Channel queue
        //((Lead)trigger.new[0]).OwnerId = Utils.getQueueId('Omni_Temp');
        // === END TEMP ================================================

        if ( isCurrentUserAPI() ) { // SFDC-1534

            routeLeads2PendingQueue2(); // Call to this method should always be first!
            assignLeads();
            updateLeadFields();
        }
    }

    public override void afterInsert() {

        if ( LeadTriggerHandler.SKIP_RECURSION ) {

            return;
        }

        if ( isCurrentUserAPI() ) { // SFDC-1492 (Should have been added with SDFC-1534)

            findDuplicates();
        }

        handleWeb2Lead();
    }

    public override void beforeUpdate() {

        if ( LeadTriggerHandler.SKIP_RECURSION ) {

            return;
        }

        if ( isCurrentUserAPI() ) { // SFDC-1534

            assignLeads();
            updateLeadFields();
        }
    }

    public override void afterUpdate() {

        if ( LeadTriggerHandler.SKIP_RECURSION || LeadTriggerHandler.SKIP_AFTER_UPDATE ) {

            return;
        }

        if ( isCurrentUserAPI() ) { // SFDC-1492 (Should have been added with SDFC-1534)

            findDuplicates();
            distributeUpdates2NonDuplicateLeads();
        }
    }

    /******************************************************************
    * Method: routeLeads2PendingQueue, private
    * Description: If the Lead is from the WEST/EAST Coast, route it to the PST_Pending_Leads/EST_Pending_Leads Queues
    * Return: void
    * Note: DEPRECATED: replaced with routeLeads2PendingQueue2
    *******************************************************************/
    /*
    private void routeLeads2PendingQueue() {

        if ( !FeatureFlags.instance.ff_Timezone_Routing && !Test.isRunningTest() ) return;

        System.debug('Inside routeLeads2PendingQueue()');

        if ( TESTING_ALLOW_24_7_BUSINESS_HOURS ) return; // Skip

        if ( Trigger.isBefore && Trigger.isInsert && !LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING ) {

            Map<String, String> map_State2Coast = Utils.getStates2CoastMap();

            System.debug('map_State2Coast: ' + map_State2Coast);

            for (sObject theLead : trigger.new) {

                Lead my_lead = (Lead)theLead;
                system.debug('my_lead.RecordTypeId: ' + my_lead.RecordTypeId);
                if ( Excluded_RecordTypes_by_Id.contains(my_lead.RecordTypeId) )
                    continue;

                String state = my_lead.State?.toUpperCase();

                if (String.isNotBlank(state) && map_State2Coast.containsKey(state)) {

                    if (map_State2Coast.get(state).toLowerCase().equals('west')) {

                        // Find whether the time is within the PST business hours
                        Boolean isWithin = Utils.isWithinPST(system.now());
                        System.debug('QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_PST: ' + QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_PST.enabled);
                        if ( !isWithin || TESTING_OUTSIDE_OF_BUSINESS_HOURS || QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_PST.enabled ) {
                            my_lead.OwnerId = pstPendingLeadsQueue;
                            System.debug('Set Owner for Lead Id: ' + my_lead.Id + ' to PST Pending Queue');
                        }
                    }
                    else if (map_State2Coast.get(state).toLowerCase().equals('east')) {

                        // Find whether the time is within the EST business hours
                        Boolean isWithin = Utils.isWithinEST(system.now());
                        System.debug('QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_EST: ' + QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_EST.enabled);
                        if ( !isWithin || TESTING_OUTSIDE_OF_BUSINESS_HOURS || QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_EST.enabled ) {
                            my_lead.OwnerId = estPendingLeadsQueue;
                            System.debug('Set Owner for Lead Id: ' + my_lead.Id + ' to EST Pending Queue');
                        }
                    }
                }
            }
        }
    }
     */

    /******************************************************************
    * Method: routeLeads2PendingQueue2, private
    * Description: If the Lead is from the WEST/EAST Coast, route it to the PST_Pending_Leads/EST_Pending_Leads Queues
    * Return: void
    *******************************************************************/
    private void routeLeads2PendingQueue2() {

        if ( !FeatureFlags.instance.ff_Timezone_Routing && !Test.isRunningTest() ) return;

        System.debug('Inside routeLeads2PendingQueue()');

        if ( TESTING_ALLOW_24_7_BUSINESS_HOURS ) return; // Skip

        if ( Trigger.isBefore && Trigger.isInsert && !LeadTriggerTest.NON_PST_EST_LEAD_TESTS_ARE_RUNNING ) {

            //Map<String, Utils.StateInfo> map_State2Coast = Utils.getStates2StateInfo();

            //System.debug('map_State2Coast: ' + map_State2Coast);

            for (LeadItem theLead : objLeadItems.lst_LeadItems) {

                Lead my_lead = theLead.my_lead;

                Boolean isCreatedByAgent = isLeadCreatedByAgentOrKnownProcess(theLead);
                system.debug('routeLeads2PendingQueue2, isCreatedByAgent: ' + isCreatedByAgent);
                if ( isCreatedByAgent ) continue;

                system.debug('my_lead.RecordTypeId: ' + my_lead.RecordTypeId);
                if ( Excluded_RecordTypes_by_Id.contains(my_lead.RecordTypeId) )
                    continue;

                Utils.LeadState leadState = Utils.isLeadWithinBusinessHours(my_lead);
                system.debug('routeLeads2PendingQueue2, leadState: ' + leadState);

                if ( !leadState.bIsWithinBusinessHours ) {

                    my_lead.OwnerId = leadState.pendingQueueId;
                    System.debug('Set Owner for Lead: ' + my_lead + ' to: ' + leadState.pendingQueueId);
                }
            }
        }
    }

    /******************************************************************
    * Method: updateLeadFields, private
    * Description: Business logic migrated from Workflow Rules: 'Close Fake Leads', 'Close Leads if in Non-workable Q'
    * Return: void
    *******************************************************************/
    private void updateLeadFields() {

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {

            system.debug('updateLeadFields, FeatureFlags ff_Prefer_Lead_Code_Execution_over_No_Code is Enabled');

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id Hippo_Agency_Sales = Utils.getQueueId('Hippo_Agency_Sales');

            for (LeadItem theLead : objLeadItems.lst_LeadItems) {

                Lead my_lead = theLead.my_lead;

                Boolean isCreatedByAgent = map_LeadUniqueId2IsCreatedByAgent.containsKey(theLead.unique_identifier) ? map_LeadUniqueId2IsCreatedByAgent.get(theLead.unique_identifier) : false;
                system.debug('isCreatedByAgent: ' + isCreatedByAgent);
                if ( isCreatedByAgent ) continue;

                LeadRoutingInfo lrInfo = isHASLead(my_Lead);
                system.debug('updateLeadFields, isHASLead: ' + lrInfo);

                system.debug('my_lead.RecordTypeId: ' + my_lead.RecordTypeId);
                if ( Excluded_RecordTypes_by_Id.contains(my_lead.RecordTypeId) )
                    continue;
                /*
                system.debug('Trigger.isInsert: ' + Trigger.isInsert);
                system.debug('Trigger.isUpdate: ' + Trigger.isUpdate);
                system.debug('my_lead (in updateLeadFields): ' + theLead);
                 */

                // Previously: 1 and 2 in the assignment rule named 'Lead 2 Queue by Org'
                if ( Trigger.isInsert && my_lead.Status.equalsIgnoreCase('New') && !isWorkableByCatRiskClass(my_lead)
                     /*((String.isNotBlank(my_lead.Non_Cat_Risk_Class__c) && my_lead.Non_Cat_Risk_Class__c.equalsIgnoreCase('referral')) ||
                     (String.isNotBlank(my_lead.Cat_Risk_Class__c) && my_lead.Cat_Risk_Class__c.equalsIgnoreCase('referral')))*/ ) {

                    setLeadOwner(my_lead, Non_workable_leads_Q, lrInfo);
                }
                // Previously workflow rule: 'Close Fake Leads'
                else if ( (String.isNotBlank(my_lead.FirstName) && (my_lead.FirstName.equalsIgnoreCase('First') || my_lead.FirstName.equalsIgnoreCase('test'))) ||
                          (String.isNotBlank(my_lead.LastName) && (my_lead.LastName.equalsIgnoreCase('Last') || my_lead.LastName.equalsIgnoreCase('test'))) ) {

                    my_lead.Status = 'Cancelled';
                    my_lead.Disqualified_Reason__c = 'Fake Contact Info';
                    setLeadOwner(my_lead, Non_workable_leads_Q, lrInfo);
                }

                // Previously workflow rule: 'Non Workable with Details'
                /* ===== LOGIC MOVED TO assignLeads =====
                if ( my_lead.Status.equalsIgnoreCase('Closed') &&
                     my_lead.OwnerId == Non_workable_leads_Q &&
                     String.isNotBlank(my_lead.FirstName) &&
                     String.isNotBlank(my_lead.LastName) &&
                     String.isNotBlank(my_lead.Email) ) {

                    my_lead.Status = 'New';
                }  ===== LOGIC MOVED TO assignLeads =====
                 */

                // Previously workflow rule: 'Close Leads if in Non-workable Q'
                else if ( !UserInfo.getUserId().startsWith('005') && my_lead.OwnerId == Non_workable_leads_Q && (my_lead.Status != 'Cancelled' && my_lead.Disqualified_Reason__c != 'Fake Contact Info') ) {

                    my_lead.Status = 'Closed';
                }

                /* MOVED to assignedLeads using flagHCRLead()

                if (String.isNotBlank(my_lead.UTM_Source__c) && my_lead.UTM_Source__c.equalsIgnoreCase('realtime')) { // SFDC-1476, 1628, 1629

                    my_lead.Is_HCR_Lead__c = 'Yes';

                    injectOrgtoHCRLeads(my_lead);
                }
                 */

                /*
                system.debug('my_lead.MobilePhone: ' + my_lead.MobilePhone);
                system.debug('my_lead.Phone: ' + my_lead.Phone);
                system.debug('my_lead.Email: ' + my_lead.Email);
                system.debug('my_lead.POD_Quote_ID__c: ' + my_lead.POD_Quote_ID__c);
                system.debug('my_lead.OwnerId: ' + my_lead.OwnerId);
                system.debug('my_lead.Status: ' + my_lead.Status);
                 */
            }
        }
    }

    /******************************************************************
    * Method: assignLeads, private
    * Description: Business logic migrated from lead assignment rules and process builder
    * Return: void
    *******************************************************************/
    private void assignLeads() {

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {

            system.debug('assignLeads, FeatureFlags ff_Prefer_Lead_Code_Execution_over_No_Code is Enabled');

            //Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');
            //Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            //Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
            Id B2C_Better_Cover = Utils.getQueueId('B2C_Better_Cover');
            Id B2C_The_Money_Source = Utils.getQueueId('B2C_The_Money_Source');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales'); // SFDC-1540
            Id Inside_Sales_Contractors = Utils.getQueueId('Inside_Sales_Contractors');
            //Id Hippo_Agency_Sales = Utils.getQueueId('Hippo_Agency_Sales');
            Id Duplicate_Leads_Q = Utils.getQueueId('Already_Purchased');

            //String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
            //String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
            //Id estPendingLeadsQueue = Utils.getQueueId(est_pending_queue_dev_name);
            //Id pstPendingLeadsQueue = Utils.getQueueId(pst_pending_queue_dev_name);

            Inside_Sales_Contractors = FeatureFlags.instance.ff_Use_Inside_Sales_Contractor_Queue ? Inside_Sales_Contractors : Non_workable_leads_Q;

            Set<Id> accountId = new Set<Id>();
            for (LeadItem theLead : objLeadItems.lst_LeadItems) {

                Lead my_lead = theLead.my_lead;

                system.debug('1. assignLeads, theLead.unique_identifier: ' + theLead.unique_identifier);
                system.debug('1. assignLeads, map_LeadUniqueId2IsCreatedByAgent: ' + map_LeadUniqueId2IsCreatedByAgent);
                Boolean isCreatedByAgent = map_LeadUniqueId2IsCreatedByAgent.containsKey(theLead.unique_identifier) ? map_LeadUniqueId2IsCreatedByAgent.get(theLead.unique_identifier) : isLeadCreatedByAgentOrKnownProcess(theLead);
                system.debug('1. assignLeads, isCreatedByAgent: ' + isCreatedByAgent);
                if ( isCreatedByAgent ) continue;

                System.debug('my_lead.RecordTypeId: ' + my_lead.RecordTypeId);
                if ( Excluded_RecordTypes_by_Id.contains(my_lead.RecordTypeId) /*|| my_lead.OwnerId == estPendingLeadsQueue || my_lead.OwnerId == pstPendingLeadsQueue*/ )
                    continue;

                if ( null != my_lead.Organization__c ) {
                    accountId.add(my_lead.Organization__c);
                }
            }

            // Since we are in a Before Insert/Update we do not have the relationship fields (Organization__c) data so need to get them
            this.accounts_in_context = new Map<Id, Account>([SELECT Id, Name, Workable_by_Hippo_picklist__c, B2B2C__c FROM Account WHERE Id IN :accountId]);
            this.hcr_accounts_in_context = new Map<Id, Account>([SELECT Id, Name, Workable_by_Hippo_picklist__c, B2B2C__c FROM Account WHERE Id IN : hcr_accounts_ids]);
            this.jv_accounts_in_context = new Map<Id, Account>([SELECT Id, Name, Workable_by_Hippo_picklist__c, B2B2C__c FROM Account WHERE Id IN : jv_accounts_ids]);

            //Map<String, Boolean> map_toggledOffLeadScores = Utils.getToggledOffLeadScores();
            System.debug('map_toggledOffLeadScores: ' + map_toggledOffLeadScores);

            for (LeadItem theLead : objLeadItems.lst_LeadItems) {

                Lead my_lead = theLead.my_lead;

                system.debug('2. assignLeads, theLead.unique_identifier: ' + theLead.unique_identifier);
                system.debug('2. assignLeads, map_LeadUniqueId2IsCreatedByAgent: ' + map_LeadUniqueId2IsCreatedByAgent);
                Boolean isCreatedByAgent = map_LeadUniqueId2IsCreatedByAgent.containsKey(theLead.unique_identifier) ? map_LeadUniqueId2IsCreatedByAgent.get(theLead.unique_identifier) : isLeadCreatedByAgentOrKnownProcess(theLead);
                system.debug('2. assignLeads, isCreatedByAgent: ' + isCreatedByAgent);
                if ( isCreatedByAgent ) continue;

                if ( my_lead.Status.equalsIgnoreCase('Closed') ) continue; // This was added for SFDC-1267 since 'Lead Quick Convert' flow updates the lead that "was converted" to 'Closed'

                // honor pre assignment of lead owner to HAS (SFDC-1079/1868) or to an agent (warm transfer, SFDC-1604)
                if ( ((Trigger.isInsert && !my_lead.Status.equalsIgnoreCase('Cancelled')) &&
                     (my_lead.OwnerId.equals(HAS_Internal_Referrals_Queue) ||
                     (String.isNotBlank(my_lead.Lead_Source__c) && my_lead.Lead_Source__c.equalsIgnoreCase('Internal Referral Warm Transfer')))) ||
                     (Trigger.isUpdate && (my_lead.OwnerId.equals(HAS_Internal_Referrals_Queue) ||
                     (String.isNotBlank(my_lead.Lead_Source__c) && my_lead.Lead_Source__c.containsIgnoreCase('Internal Referral')))) ) {

                    continue;
                }

                Lead oldLead = trigger.isUpdate ? (Lead)trigger.oldMap.get(my_lead.Id) : null;

                system.debug('my_lead.RecordTypeId: ' + my_lead.RecordTypeId);
                if ( Excluded_RecordTypes_by_Id.contains(my_lead.RecordTypeId) )
                    continue;

                system.debug('UserInfo.getName(): ' + UserInfo.getName());
                system.debug('my_lead.MobilePhone: ' + my_lead.MobilePhone);
                system.debug('my_lead.Phone: ' + my_lead.Phone);
                system.debug('my_lead.Email: ' + my_lead.Email);
                system.debug('my_lead.POD_Quote_ID__c: ' + my_lead.POD_Quote_ID__c);
                system.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
                system.debug('my_lead.OwnerId: ' + my_lead.OwnerId);
                system.debug('my_lead.Status: ' + my_lead.Status);
                system.debug('my_lead.Lead_Score__c: ' + my_lead.Lead_Score__c);
                system.debug('my_lead.Organization__c: ' + my_lead.Organization__c);
                system.debug('my_lead.UTM_Source__c: ' + my_lead.UTM_Source__c);
                system.debug('my_lead.State: ' + my_lead.State);
                system.debug('my_Lead.IsJVLead__c: ' + my_lead.IsJVLead__c);
                system.debug('my_Lead.IsConverted: ' + my_lead.IsConverted);

                Boolean previous_owner_is_queue = false;
                if (Trigger.isUpdate) {

                    Id previous_owner = (Id) Trigger.oldMap.get(my_lead.Id).get('OwnerId');
                    previous_owner_is_queue = previous_owner.equals(Non_workable_leads_Q) || previous_owner.equals(Outside_Sales_Queue)
                                              /*previous_owner.equals(Hippo_Agency_Sales) || previous_owner.equals(B2C_Partner_Sales)*/ || previous_owner.equals(B2C_Better_Cover) ||
                                              previous_owner.equals(B2C_The_Money_Source) /*|| previous_owner.equals(B2C_Direct_Sales)*/ || previous_owner.equals(Duplicate_Leads_Q) ||
                                              previous_owner.equals(HAS_Internal_Referrals_Queue) || previous_owner.equals(HAS_UW_Referrals_Queue) || previous_owner.equals(HAS_UW_Declinations_Queue) ||
                                              previous_owner.equals(B2C_Direct_1) || previous_owner.equals(B2C_Direct_2) ||
                                              previous_owner.equals(Workable_by_Hippo_1) || previous_owner.equals(Workable_by_Hippo_2) ||
                                              previous_owner.equals(B2C_Partner_Sales_1) || previous_owner.equals(B2C_Partner_Sales_2) ||
                                              previous_owner.equals(UW_Referrals_1) || previous_owner.equals(UW_Referrals_2);
                    previous_owner_is_queue = previous_owner_is_queue && (previous_owner != my_lead.OwnerId);
                }

                if ( FeatureFlags.instance.ff_Score_11 ) {

                        if ( ((String.isNotBlank(my_lead.utm_campaign__c) && my_lead.utm_campaign__c.equalsIgnoreCase('SmartFinancial')) && String.isNotBlank(my_lead.Lead_Score__c) && Integer.valueOf(my_lead.Lead_Score__c) >= 6) ||
                             ((String.isNotBlank(my_lead.Organization__c) && accounts_in_context != null && accounts_in_context.get(my_lead.Organization__c).Name.equalsIgnoreCase('everquote')) && String.isNotBlank(my_lead.Lead_Score__c) && Integer.valueOf(my_lead.Lead_Score__c) >= 6) ||
                             ((String.isNotBlank(my_lead.utm_source__c) && my_lead.utm_source__c.equalsIgnoreCase('blackbird')) && String.isNotBlank(my_lead.Lead_Score__c) && Integer.valueOf(my_lead.Lead_Score__c) >= 6)) {

                        my_lead.Lead_Score__c = '11';
                        system.debug('my_lead.Lead_Score__c: ' + my_lead.Lead_Score__c);
                    }
                }

                Boolean isFacebookDirect = String.isNotBlank(my_lead.Lead_Source__c) && my_lead.Lead_Source__c.equalsIgnoreCase('Facebook Direct');
                system.debug('isFacebookDirect: ' + isFacebookDirect);

                // check if lead is classified to partner sales (this flag is not related if it is workable or non-workable as it will be checked later)
                Boolean isPartnerSalesLead = isB2CPartnerSalesLead(my_lead, accounts_in_context);
                system.debug('isPartnerSalesLead: ' + isPartnerSalesLead);

                LeadTriggerHandler.JVLeadInfo jvLeadInfo = isJVLead(my_lead);
                system.debug('jvLeadInfo: ' + jvLeadInfo);

                Boolean isWorkableLead = isWorkableLead(my_lead, previous_owner_is_queue, accounts_in_context, Non_workable_leads_Q);
                system.debug('isWorkableLead: ' + isWorkableLead);

                RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('B2C_Sales');
                Boolean isB2CLead = my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId());
                system.debug('isB2CLead: ' + isB2CLead);

                LeadRoutingInfo lrInfo = isHASLead(my_Lead);
                system.debug('assignLeads, isHASLead: ' + lrInfo);

                Boolean isHCRLead = isHCRLead(my_lead); //String.isNotBlank(my_lead.UTM_Source__c) && my_lead.UTM_Source__c.equalsIgnoreCase('realtime');
                system.debug('assignLeads, isHCRLead: ' + isHCRLead);

                if ( isFacebookDirect ) {

                    system.debug('Calling SetLeadOwner to Facebook_Direct');
                    setLeadOwner(my_lead, Facebook_Direct, lrInfo);
                }
                else if ( isWorkableLead && checkSpecificLeadSource(my_lead, lrInfo) ) {

                    continue; // nothing to do. lead owner has been updated inside checkSpecificLeadSource method that was just returned
                }
                else if ( !isPartnerSalesLead && my_lead.Status.equalsIgnoreCase('New') &&
                          (Trigger.isInsert || (Trigger.isUpdate && (my_lead.OwnerId != UserInfo.getUserId() &&
                          !String.valueOf(my_lead.OwnerId).startsWith('005')))) /* Assigned by Omni or By User */ &&
                          ((String.isBlank(my_lead.Lead_Score__c)) ||
                           (String.isNotBlank(my_lead.Lead_Score__c) ? (Test.isRunningTest() || !FeatureFlags.instance.ff_Lead_Score_Toggling ? Integer.valueOf(my_lead.Lead_Score__c) <= 3 : map_toggledOffLeadScores.containsKey(my_lead.Lead_Score__c)) : false)) &&
                          !Inside_Sales_Contractors_States.contains(my_lead.State) && !jvLeadInfo.isJVLead && !isHCRLead && isB2CLead ) {

                    if (String.isNotBlank(my_lead.Lead_Score__c) && String.isBlank(my_lead.Organization__c)) {

                        system.debug('Calling SetLeadOwner to Outside_Sales_Queue, condition 1');
                        setLeadOwner(my_lead, Outside_Sales_Queue, lrInfo);

                    }
                    else {

                        system.debug('Calling SetLeadOwner to Non_workable_leads_Q, condition 2');
                        setLeadOwner(my_lead, Non_workable_leads_Q, lrInfo);
                    }
                }
                /*
                if ( my_lead.Status.equalsIgnoreCase('New') && (String.isBlank(my_lead.Lead_Score__c) || Integer.valueOf(my_lead.Lead_Score__c) <= 3) && !Inside_Sales_Contractors_States.contains(my_lead.State) ) {

                    setLeadOwner(my_lead, Non_workable_leads_Q);
                }
                 */
                else if ( Trigger.isInsert && my_lead.Status.equalsIgnoreCase('New') &&
                          (((String.isBlank(my_lead.MobilePhone) || my_lead.MobilePhone == 'MISSING') &&
                          (String.isBlank(my_lead.Phone) || my_lead.Phone == 'MISSING')) || String.isNotBlank(my_lead.POD_Quote_ID__c)) && !jvLeadInfo.isJVLead ) {

                    system.debug('Calling SetLeadOwner to Non_workable_leads_Q, condition 3');
                    setLeadOwner(my_lead, Non_workable_leads_Q, lrInfo);
                }
                else if ( !isWorkableByCatRiskClass(my_lead) && (my_lead.OwnerId != UserInfo.getUserId() && !String.valueOf(my_lead.OwnerId).startsWith('005') /* Assigned by Omni or By User */) && !jvLeadInfo.isJVLead ) {

                    system.debug('Calling SetLeadOwner to Non_workable_leads_Q, condition 4');
                    setLeadOwner(my_lead, Non_workable_leads_Q, lrInfo);
                }
                /*
                else if ( isWorkableLead && checkSpecificLeadSource(my_lead) ) {

                    continue; // nothing to do. lead owner has been updated inside checkSpecificLeadSource method that was just returned
                }
                 */
                else if ( isWorkableLead && isPartnerSalesLead ) {

                    Id leadQueue2Set = String.isBlank(my_Lead.Lead_Score__c) ? Non_workable_leads_Q : Integer.valueOf(my_Lead.Lead_Score__c) >= 5 ? B2C_Partner_Sales_1 : B2C_Partner_Sales_2;
                    //setLeadOwner(my_lead, B2C_Partner_Sales, lrInfo);
                    system.debug('Calling SetLeadOwner to Partner Sales / Non_workable_leads_Q');
                    setLeadOwner(my_lead, leadQueue2Set, lrInfo);
                    my_Lead.Lead_Source__c = String.isBlank(my_Lead.Lead_Source__c) && String.isNotBlank(my_lead.Lead_Score__c) ? 'Partner Referral' : my_Lead.Lead_Source__c;
                }
                else if ( isWorkableLead &&
                          isB2CBetterCoverLead(my_lead, accounts_in_context) ) {

                    setLeadOwner(my_lead, B2C_Better_Cover, lrInfo);
                }
                else if ( isWorkableLead &&
                          isB2CTheMoneySourceLead(my_lead, accounts_in_context) ) {

                    setLeadOwner(my_lead, B2C_The_Money_Source, lrInfo);
                }
                //else if ( setInsideSalesLead(my_lead, previous_owner_is_queue, accounts_in_context, Non_workable_leads_Q, B2C_Direct_Sales, Inside_Sales_Contractors, jvLeadInfo.isJVLead, lrInfo) ) {
                else if ( setInsideSalesLead(my_lead, previous_owner_is_queue, jvLeadInfo.isJVLead, isHCRLead, lrInfo) ) {

                    continue; // nothing to do. lead owner has been updated inside setInsideSalesLead method that was just returned
                }
                else if ( isWorkableLead &&
                          isSpecificOrganization(my_lead, accounts_in_context, lrInfo) ) {

                    continue; // nothing to do. lead owner has been updated inside isSpecificOrganization method that was just returned
                }
                else if ( my_lead.Status.equalsIgnoreCase('New') && !isWorkableLead && !jvLeadInfo.isJVLead &&
                          (Test.isRunningTest() || isCurrentUserAPI()) && (isCurrentUserAPI() && my_lead.OwnerId == UserInfo.getUserId()) ) {

                    system.debug('Calling SetLeadOwner to Non_workable_leads_Q, condition 5');
                    system.debug('isCurrentUserAPI(), condition 5: ' + isCurrentUserAPI());
                    system.debug('isWorkableLead, condition 5: ' + isWorkableLead);
                    system.debug('jvLeadInfo.isJVLead, condition 5: ' + jvLeadInfo.isJVLead);
                    system.debug('my_lead.OwnerId, condition 5: ' + my_lead.OwnerId);
                    system.debug('UserInfo.getUserId(), condition 5: ' + UserInfo.getUserId());
                    setLeadOwner(my_lead, Non_workable_leads_Q, lrInfo);
                }
                else if ( !isWorkableLead && jvLeadInfo.isJVLead ) { // SFDC-1462

                    system.debug('Calling SetLeadOwner to JV_Non_workable_leads_Q, condition 6');
                    Id  JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');
                    setLeadOwner(my_Lead, JV_Non_workable_leads_Q, lrInfo);
                    my_lead.RecordTypeId = jvLeadInfo.jvRecordTypeInfo.getRecordTypeId();
                    my_lead.IsJVLead__c = jvLeadInfo.isJVLead;
                }
                else if ( /*isWorkableLead &&*/ lrInfo.is_has ) { // SFDC-xxxx

                    system.debug('assignLeads, lrInfo: ' + lrInfo);
                    Boolean bLeadIsPendingDue2OutsideOfBusinessHours = isLeadPendingDue2OutsideOfBusinessHours(my_lead, Non_workable_leads_Q);
                    system.debug('assignLeads, bLeadIsPendingDue2OutsideOfBusinessHours: ' + bLeadIsPendingDue2OutsideOfBusinessHours);
                    setHASLead(my_lead, lrInfo, bLeadIsPendingDue2OutsideOfBusinessHours);
                }
                else {

                    system.debug('Lead has no classification'); //, Calling SetLeadOwner to Non_workable_leads_Q');
                    //setLeadOwner(my_lead, Non_workable_leads_Q, lrInfo);
                }
            }
        }
    }

    /******************************************************************
    * Method: reOpenLeads, private
    * Description: Previously workflow rule: 'Non Workable with Details'
    * Return: void
    *******************************************************************/
    private void reOpenLeads() {

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {

            Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');

            List<Lead> leads2Update = new List<Lead>();

            for (sObject theLead : trigger.new) {

                Lead my_lead = (Lead) theLead;

                system.debug('my_Lead.IsConverted: ' + my_lead.IsConverted);
                if ( my_lead.IsConverted ) continue;

                system.debug('my_lead.RecordTypeId: ' + my_lead.RecordTypeId);
                if ( Excluded_RecordTypes_by_Id.contains(my_lead.RecordTypeId) )
                    continue;

                system.debug('UserInfo.getName(): ' + UserInfo.getName());
                system.debug('my_lead.MobilePhone: ' + my_lead.MobilePhone);
                system.debug('my_lead.Phone: ' + my_lead.Phone);
                system.debug('my_lead.Email: ' + my_lead.Email);
                system.debug('my_lead.POD_Quote_ID__c: ' + my_lead.POD_Quote_ID__c);
                system.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
                system.debug('my_lead.OwnerId: ' + my_lead.OwnerId);
                system.debug('my_lead.CreatedDate: ' + my_lead.CreatedDate);

                Date leadCreation_date = my_lead.CreatedDate.date();
                system.debug('leadCreation_date: ' + leadCreation_date);
                Date weekStart_date = System.now().date().toStartOfWeek();
                system.debug('weekStart_date: ' + weekStart_date);
                Date weekEnd_date = weekStart_date.addDays(7);
                system.debug('weekEnd_date: ' + weekEnd_date);
                Boolean leadCreationInThisWeek = leadCreation_date >= weekStart_date && leadCreation_date <= weekEnd_date;
                system.debug('leadCreationInThisWeek: ' + leadCreationInThisWeek);

                // Previously workflow rule: 'Non Workable with Details'
                if ( my_lead.Status.equalsIgnoreCase('Closed') &&
                     my_lead.OwnerId == Non_workable_leads_Q &&
                     String.isNotBlank(my_lead.FirstName) &&
                     String.isNotBlank(my_lead.LastName) &&
                     String.isNotBlank(my_lead.Email) &&
                     leadCreationInThisWeek ) {

                    Lead my_updated_lead = new Lead(Id = my_lead.Id, Status = 'New');
                    leads2Update.add(my_updated_lead);
                }
            }

            LeadTriggerHandler.SKIP_RECURSION = true;
            if (leads2Update.size() > 0) update leads2Update;
            LeadTriggerHandler.SKIP_RECURSION = false;
        }
    }

    /******************************************************************
    * Method: handleWeb2Lead, private
    * Description: Handle business logic related to web 2 lead records (created by external forms)
    * Return: void
    *******************************************************************/
    private void handleWeb2Lead() {

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isAfter && Trigger.isInsert ) {

            Set<Id> b2cPartnerSalesLeads = new Set<Id>();
            Set<Id> agencySalesLeads = new Set<Id>();

            for (sObject theLead : trigger.new) {

                Lead my_lead = (Lead) theLead;
                system.debug('my_lead.RecordTypeId: ' + my_lead.RecordTypeId);

                if ( String.isNotBlank(my_lead.RecordTypeId) ) {

                    system.debug('UserInfo.getName(): ' + UserInfo.getName());
                    system.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
                    system.debug('my_lead.OwnerId: ' + my_lead.OwnerId);

                    String recordTypeDevName = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosById().get(my_lead.RecordTypeId).getDeveloperName();
                    if (recordTypeDevName?.equalsIgnoreCase('Web_Leads_Default')) {
                        b2cPartnerSalesLeads.add(my_lead.Id);
                    } else if (recordTypeDevName?.equalsIgnoreCase('Web_Leads_Producers')) {
                        agencySalesLeads.add(my_lead.Id);
                    }
                }
            }

            if( !system.isBatch() ) {

                reassignOwnerForWeb2Lead(b2cPartnerSalesLeads, agencySalesLeads);
            }
        }
    }

    @future (callout=false)
    public static void reassignOwnerForWeb2Lead(Set<Id> b2cPartnerSalesLeads, Set<Id> agencySalesLeads) {

        Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
        Id Agency_Sales = Utils.getQueueId('Agency_Sales');

        List<Lead> leads2Update = new List<Lead>();

        for (Id partnerSaleLeadId : b2cPartnerSalesLeads) {

            Lead my_updated_lead = new Lead(Id = partnerSaleLeadId, OwnerId = B2C_Partner_Sales);
            leads2Update.add(my_updated_lead);
        }

        List<Lead> lst_AgencySalesLead = [SELECT Id, State, OwnerId FROM Lead WHERE Id IN: agencySalesLeads];
        Map<String, Id> map_State2TerritoryManagerOwnerId = Utils.getTerritoryManagersByState();

        for (Lead agencySalesLead : lst_AgencySalesLead) {

            Lead my_updated_lead = new Lead(Id = agencySalesLead.Id);

            if ( map_State2TerritoryManagerOwnerId.containsKey(agencySalesLead.State.toUpperCase()) )
                my_updated_lead.OwnerId = map_State2TerritoryManagerOwnerId.get(agencySalesLead.State.toUpperCase());
            else
                my_updated_lead.OwnerId = Agency_Sales;

            leads2Update.add(my_updated_lead);
        }

        LeadTriggerHandler.SKIP_RECURSION = true;
        if (leads2Update.size() > 0) update leads2Update;
        LeadTriggerHandler.SKIP_RECURSION = false;
    }

    /******************************************************************
    * Method: isWorkableLead, private
    * Description: Check if Lead should be assigned to a workable queue
    * Return: Boolean
    *******************************************************************/
    private Boolean isWorkableLead(Lead my_Lead, Boolean previous_owner_is_queue, Map<Id, Account> accounts_in_context, Id Non_workable_leads_Q) {

        System.debug('isWorkableLead, qacp_Lead_is_Always_Workable: ' + QACockpit.instance.qacp_Lead_is_Always_Workable.enabled);

        if ( QACockpit.instance.qacp_Lead_is_Always_Workable.enabled && (my_lead.OwnerId != UserInfo.getUserId() || Trigger.isInsert) ) return true;

        Boolean res = false;

        System.debug('isWorkableLead, my_lead.OwnerId: ' +  my_lead.OwnerId);
        System.debug('isWorkableLead, my_lead.Owner.Name: ' +  my_lead.Owner.Name);
        System.debug('isWorkableLead, previous_owner_is_queue: ' + previous_owner_is_queue);
        System.debug('isWorkableLead, isCurrentUserAPI(): ' + isCurrentUserAPI());
        System.debug('isWorkableLead, my_lead.Status: ' + my_lead.Status);
        System.debug('isWorkableLead, my_lead.POD_Quote_ID__c: ' + my_lead.POD_Quote_ID__c);
        System.debug('isWorkableLead, my_lead.Phone: ' + my_lead.Phone);
        System.debug('isWorkableLead, my_lead.MobilePhone: ' + my_lead.MobilePhone);
        System.debug('isWorkableLead, my_lead.Non_Cat_Risk_Class__c: ' + my_lead.Non_Cat_Risk_Class__c);
        System.debug('isWorkableLead, my_lead.Cat_Risk_Class__c: ' + my_lead.Cat_Risk_Class__c);
        System.debug('isWorkableLead, my_lead.State: ' + my_lead.State);
        System.debug('isWorkableLead, previous_owner_is_queue: ' + previous_owner_is_queue);
        System.debug('isWorkableLead, isWorkableByCatRiskClass(my_Lead): ' + isWorkableByCatRiskClass(my_Lead));

        String account_id = my_lead?.Organization__c;
        System.debug('isWorkableLead, account_id: ' + account_id);
        String utm_source = String.isNotBlank(my_lead.UTM_Source__c) ? my_lead.UTM_Source__c : '';
        System.debug('isWorkableLead, my_lead.UTM_Source__c: ' + utm_source);
        Boolean isSMSReactivationUTMSource = utm_source.equalsIgnoreCase(LeadTriggerHandler.SMS_Reactivation_Dummy_Account_Name);
        System.debug('isWorkableLead, isSMSReactivationUTMSource: ' + isSMSReactivationUTMSource);

        //System.debug('isWorkableLead, Condition 1 (AND with (2 OR 3)): ' + (Trigger.isInsert || ( Trigger.isUpdate && ( my_lead.OwnerId != UserInfo.getUserId() || Test.isRunningTest() ) && ( !previous_owner_is_queue || isCurrentUserAPI() || Test.isRunningTest() ) )));
        //System.debug('isWorkableLead, Condition 2 (OR with 3): ' + ( ( my_lead.Status.equalsIgnoreCase('New') ) && ( (Trigger.isInsert && my_Lead.OwnerId == UserInfo.getUserId()) || Test.isRunningTest() || isCurrentUserAPI() || my_lead.OwnerId == Non_workable_leads_Q ) && String.isBlank(my_lead.POD_Quote_ID__c) && ( ( String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING' ) || ( String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING' ) ) && isWorkableByCatRiskClass(my_Lead) ));
        //System.debug('isWorkableLead, Condition 3 (OR with 2): ' + ( ( ( String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING' ) || ( String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING' ) ) && isWorkableByCatRiskClass(my_Lead) && isSMSReactivationUTMSource ));

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {
			
            if ( ( Trigger.isInsert || ( Trigger.isUpdate && ( my_lead.OwnerId != UserInfo.getUserId() || Test.isRunningTest() ) &&
                 ( !previous_owner_is_queue || isCurrentUserAPI() || Test.isRunningTest() ) ) ) &&
                 ( ( ( my_lead.Status.equalsIgnoreCase('New') /*|| (!my_lead.Status.equalsIgnoreCase('New') && isSMSReactivationUTMSource)*/ ) && ( (Trigger.isInsert && my_Lead.OwnerId == UserInfo.getUserId()) || Test.isRunningTest() || isCurrentUserAPI() || my_lead.OwnerId == Non_workable_leads_Q ) &&
                 String.isBlank(my_lead.POD_Quote_ID__c) &&
                 ( ( String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING' ) || ( String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING' ) ) &&
                 isWorkableByCatRiskClass(my_Lead) ) ||
                 ( ( ( String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING' ) || ( String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING' ) ) &&
                 isWorkableByCatRiskClass(my_Lead) && isSMSReactivationUTMSource ) ) 
                
               ) {

                res = true;
            }
        }

        System.debug('isWorkableLead, res: ' + res);

        return res;
    }

    /******************************************************************
    * Method: isWorkableByCatRiskClass, private
    * Description: Check if Lead should be assigned to a workable queue based on it's Non_Cat_Risk_Class__c and Cat_Risk_Class__c fields
    * Return: Boolean
    * Note: Cat Risk Class was a model implemented only for Texas. So if a State = TX and Cat Risk Class = Referral, then route the lead
    * to non-workable queue regardless of lead score. If it's any other state we ignore Cat Risk Class
     * -----------------------------------------------------------------------------------------------
     * SFDC-1443 (Added 03/09/22 - PennyMac referral leads should route to PennyMac as they can sell 3rd party services. Also set lead source to UW Referral
    *******************************************************************/
    private Boolean isWorkableByCatRiskClass(Lead my_lead) {

        Boolean res = false;

        try {

            if (null != my_lead) {

                if((my_lead.Non_Cat_Risk_Class__c == null && my_lead.Cat_Risk_Class__c == null) || (my_lead.Non_Cat_Risk_Class__c != '' && my_lead.Cat_Risk_Class__c != '')) {
                    return true;
                }

                res = (my_lead.Non_Cat_Risk_Class__c != 'referral' && (my_lead.Cat_Risk_Class__c != 'referral' || (String.isNotBlank(my_Lead.State) && !my_Lead.State.toLowerCase().equalsIgnoreCase('tx') && my_lead.Cat_Risk_Class__c == 'referral')));

                if ( !res ) { // SFDC-1443

                    res = my_lead.Non_Cat_Risk_Class__c == 'referral' && isJVLead(my_lead, Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PennyMac_Lead'), LeadTriggerHandler.Pennymac_Related_Token);
                    my_lead.Lead_Source__c = res ? 'UW Referral' : my_lead.Lead_Source__c;
                }
            }
        }
        catch(Exception ex) {

            System.debug(ex);
        }

        System.debug('isWorkableByCatRiskClass, res: ' + res);

        return res;
    }

    /******************************************************************
    * Method: setInsideSalesLead, private
    * Description: Check if Lead should be assigned to inside sales related queues (Direct Sales, Inside Sales Contractor) + special use case where it should but email is empty --> assign to non workable
    * Return: Boolean (indication if the owner of the lead had been changed)
    *******************************************************************/
    /*
    private Boolean setInsideSalesLead(Lead my_Lead, Boolean previous_owner_is_queue, Map<Id, Account> accounts_in_context, Id Non_workable_leads_Q, Id B2C_Direct_Sales, Id Inside_Sales_Contractors, Boolean isJVLead, LeadRoutingInfo lrInfo) {

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('B2C_Sales');

        if ( !my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId()) ) return false;

        LeadRoutingInfo leadRoutingInfo = isHASLead(my_Lead);
        if ( leadRoutingInfo.is_has ) return false;

        Boolean owner_updated = false;

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {

            Boolean bIsInsideSalesContractor = my_lead.Status.equalsIgnoreCase('New') && Inside_Sales_Contractors_States.contains(my_lead.State) && (String.isBlank(my_lead.Lead_Score__c) || Integer.valueOf(my_lead.Lead_Score__c) <= 3);
            system.debug('bIsInsideSalesContractor: ' + bIsInsideSalesContractor);

            if ( (Trigger.isInsert || (Trigger.isUpdate && my_lead.OwnerId != UserInfo.getUserId() &&
                 (!previous_owner_is_queue || isCurrentUserAPI() || Test.isRunningTest()))) &&
                 my_lead.Status.equalsIgnoreCase('New') && (Test.isRunningTest() || isCurrentUserAPI() || my_lead.OwnerId == Non_workable_leads_Q) &&
                 String.isBlank(my_lead.POD_Quote_ID__c) &&
                 ((String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING') || (String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING')) &&
                 isB2CDirectSalesLead(my_lead, accounts_in_context) &&
                 (my_lead.Non_Cat_Risk_Class__c != 'referral' && my_lead.Cat_Risk_Class__c != 'referral') && !isJVLead ) {

                // Modified based on SFDC-1540
                //Id leadQueue2Set = String.isBlank(my_lead.Email) ? Non_workable_leads_Q : bIsInsideSalesContractor ? Inside_Sales_Contractors : B2C_Direct_Sales;
                Id leadQueue2Set = String.isBlank(my_lead.Email) ? Non_workable_leads_Q : bIsInsideSalesContractor ? Inside_Sales_Contractors : String.isNotBlank(my_Lead.Lead_Score__c) && Integer.valueOf(my_Lead.Lead_Score__c) >= 5 ? B2C_Direct_1 : B2C_Direct_2;

                system.debug('leadQueue2Set, condition 1: ' + leadQueue2Set);
                setLeadOwner(my_lead, leadQueue2Set, lrInfo);
                //my_lead.OwnerId = String.isBlank(my_lead.Email) ? Non_workable_leads_Q : bIsInsideSalesContractor ? Inside_Sales_Contractors : B2C_Direct_Sales;
                owner_updated = true;
            }
            else if ( (Trigger.isInsert || (Trigger.isUpdate && my_lead.OwnerId != UserInfo.getUserId() &&
                      (!previous_owner_is_queue || isCurrentUserAPI() || Test.isRunningTest()))) &&
                      my_lead.Status.equalsIgnoreCase('New') && String.isBlank(my_lead.Organization__c) &&
                      (((String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING') || (String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING')) &&
                      String.isBlank(my_lead.POD_Quote_ID__c)) &&
                      (my_lead.Non_Cat_Risk_Class__c != 'referral' && my_lead.Cat_Risk_Class__c != 'referral') && !isJVLead ) {

                // Modified based on SFDC-1540
                //Id leadQueue2Set = bIsInsideSalesContractor ? Inside_Sales_Contractors : B2C_Direct_Sales;
                Id leadQueue2Set = bIsInsideSalesContractor ? Inside_Sales_Contractors : String.isNotBlank(my_Lead.Lead_Score__c) && Integer.valueOf(my_Lead.Lead_Score__c) >= 5 ? B2C_Direct_1 : B2C_Direct_2;

                system.debug('leadQueue2Set, condition 2: ' + leadQueue2Set);
                setLeadOwner(my_lead, leadQueue2Set, lrInfo);
                owner_updated = true;
            }
        }

        return owner_updated;
    }
     */

    /******************************************************************
    * Method: setInsideSalesLead, private
    * Description: Check if Lead should be assigned to inside sales related queues (Direct Sales, Inside Sales Contractor) + special use case where it should but email is empty --> assign to non workable
    * Return: Boolean (indication if the owner of the lead had been changed)
    *******************************************************************/
    private Boolean setInsideSalesLead(Lead my_Lead, Boolean previous_owner_is_queue, Boolean isJVLead, Boolean isHCRLead, LeadRoutingInfo lrInfo) {

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('B2C_Sales');

        if ( !my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId()) ) return false;

        LeadRoutingInfo leadRoutingInfo = isHASLead(my_Lead);
        if ( leadRoutingInfo.is_has ) return false;

        Boolean owner_updated = false;

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {

            if ( (Trigger.isInsert || (Trigger.isUpdate && my_lead.OwnerId != UserInfo.getUserId() &&
                 (!previous_owner_is_queue || isCurrentUserAPI() || Test.isRunningTest()))) &&
                 my_lead.Status.equalsIgnoreCase('New') && String.isBlank(my_lead.Organization__c) &&
                 (((String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING') || (String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING')) &&
                 String.isBlank(my_lead.POD_Quote_ID__c)) &&
                 (my_lead.Non_Cat_Risk_Class__c != 'referral' && my_lead.Cat_Risk_Class__c != 'referral') && !isJVLead && !isHCRLead ) {

                Id leadQueue2Set = String.isBlank(my_Lead.Lead_Score__c) ? Non_workable_leads_Q : Integer.valueOf(my_Lead.Lead_Score__c) >= 5 ? B2C_Direct_1 : B2C_Direct_2;
                system.debug('leadQueue2Set, condition 1540: ' + leadQueue2Set);
                setLeadOwner(my_lead, leadQueue2Set, lrInfo);
                my_Lead.Lead_Source__c = String.isBlank(my_Lead.Lead_Source__c) ? 'Hippo Direct Leads' : my_Lead.Lead_Source__c;
                owner_updated = true;
            }
        }

        return owner_updated;
    }

    /******************************************************************
    * Method: isB2CPartnerSalesLead, private
    * Description: Check if Lead organization is related to the partner sales queue
    * Return: Boolean
    *******************************************************************/
    private Boolean isB2CPartnerSalesLead(Lead my_Lead, Map<Id, Account> accounts_in_context) {

        Boolean res = false;

        String HomePointFinancialAccountName = 'Home Point Financial';

        Boolean leadScoreAvailable = String.isNotBlank(my_Lead.Lead_Score__c);

        String account_id = my_Lead?.Organization__c;
        Account acc = accounts_in_context.get(account_id);
        String account_name = String.isNotBlank(account_id) ? acc?.Name.toLowerCase() : null;

        system.debug('isB2CPartnerSalesLead account name: ' + account_name);

        if ( acc != null ) {

            system.debug('isB2CPartnerSalesLead account Workable_by_Hippo_picklist__c: ' + acc.Workable_by_Hippo_picklist__c);
            system.debug('isB2CPartnerSalesLead account B2B2C__c: ' + acc.B2B2C__c);
        }

        if (account_name == null) return false;

        //Map<String, Utils.LeadMapping> leadQueuesMap = Utils.getLeadQueuesMapping();

        Boolean isRealtimeLead = String.isNotBlank(my_lead.UTM_Source__c) && my_lead.UTM_Source__c.equalsIgnoreCase('realtime'); // SFDC-1694

        if ( acc != null && acc.Workable_by_Hippo_picklist__c == 'Yes' && acc.B2B2C__c == 'Yes' && !isRealtimeLead ) { // SFDC-1540, 1694

            res = true;
        }

        /*
        else if ( leadQueuesMap.containsKey(account_name) ) {

            if ( (leadQueuesMap.get(account_name).queue_dev_name.equalsIgnoreCase('B2C_Partner_Sales') && leadScoreAvailable) || (account_name.equalsIgnoreCase(HomePointFinancialAccountName) ) )
                res = true;
            else
                res = false;
        }
        */

        else {

            res = false;
        }

        system.debug('isB2CPartnerSalesLead res: ' + res);

        return res;
    }

    /******************************************************************
    * Method: isB2CBetterCoverLead, private
    * Description: Check if Lead organization is related to the better cover queue
    * Return: Boolean
    *******************************************************************/
    private Boolean isB2CBetterCoverLead(Lead my_Lead, Map<Id, Account> accounts_in_context) {

        Boolean res = false;

        String account_id = my_Lead?.Organization__c;
        String account_name = String.isNotBlank(account_id) ? accounts_in_context.get(account_id)?.Name.toLowerCase() : null;

        if (account_name == null) return false;

        Map<String, Utils.LeadMapping> leadQueuesMap = Utils.getLeadQueuesMapping();

        system.debug('isB2CBetterCoverLead: ' + leadQueuesMap.get(account_name));

        if ( leadQueuesMap.containsKey(account_name) ) {

            if ( leadQueuesMap.get(account_name).queue_dev_name.equalsIgnoreCase('B2C_Better_Cover') )
                res = true;
            else
                res = false;
        }
        else {

            res = false;
        }

        return res;
    }

    /******************************************************************
    * Method: isB2CTheMoneySourceLead, private
    * Description: Check if Lead organization is related to the money source queue
    * Return: Boolean
    *******************************************************************/
    private Boolean isB2CTheMoneySourceLead(Lead my_Lead, Map<Id, Account> accounts_in_context) {

        Boolean res = false;

        String account_id = my_Lead?.Organization__c;
        String account_name = String.isNotBlank(account_id) ? accounts_in_context.get(account_id)?.Name.toLowerCase() : null;

        if (account_name == null) return false;

        Map<String, Utils.LeadMapping> leadQueuesMap = Utils.getLeadQueuesMapping();

        system.debug('isB2CTheMoneySourceLead: ' + leadQueuesMap.get(account_name));

        if ( leadQueuesMap.containsKey(account_name) ) {

            if ( leadQueuesMap.get(account_name).queue_dev_name.equalsIgnoreCase('B2C_The_Money_Source') )
                res = true;
            else
                res = false;
        }
        else {

            res = false;
        }

        return res;
    }

    /******************************************************************
    * Method: isB2CDirectSalesLead, private
    * Description: Check if Lead organization is related to direct sales queue
    * Return: Boolean
    *******************************************************************/
    private Boolean isB2CDirectSalesLead(Lead my_Lead, Map<Id, Account> accounts_in_context) {

        Boolean res = false;

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('B2C_Sales');
        Boolean isB2CLead = my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId());

        String account_id = my_Lead?.Organization__c;
        String account_name = String.isNotBlank(account_id) ? accounts_in_context.get(account_id)?.Name.toLowerCase() : null;

        //if (account_name == null) return false;
        if (account_id == null && isB2CLead) return true; // Modified based on SFDC-1540

        Map<String, Utils.LeadMapping> leadQueuesMap = Utils.getLeadQueuesMapping();

        if ( account_name != null /* Modified based on SFDC-1540 */ && leadQueuesMap.containsKey(account_name) ) {

            if ( leadQueuesMap.get(account_name).queue_dev_name.equalsIgnoreCase('B2C_Direct_Sales') )
                res = true;
            else
                res = false;
        }
        else {

            res = false;
        }

        return res;
    }

    /******************************************************************
    * Method: isCurrentUserAPI, private
    * Description: Check if the current running user is API user
    * Return: Boolean
    *******************************************************************/
    private Boolean isCurrentUserAPI() {

        Utils.HippoUserInfo hippoUserInfo = Utils.getHippoUserInContext();

        // based on SFDC-1534 - leads that are created by an internal referrer using the cold or warm transfer option
        // should not route to the user as users who select a cold or warm transfer are support agents, not sales agents.
        // These support agents are identified by their profile which is 'Support'

        return UserInfo.getName().equalsIgnoreCase('Application User') ||
               UserInfo.getName().equalsIgnoreCase('Infra Bot') ||
               UserInfo.getName().equalsIgnoreCase('Facebook Integration User') ||
               (QACockpit.instance.qacp_Application_User_Mode.enabled && !Test.isRunningTest()) ||
               hippoUserInfo.profile_name.equalsIgnoreCase('Support');
    }

    /******************************************************************
    * Method: setLeadOwner, private
    * Description: Check if the lead should go to 'Sleep' due to out of office hours and set the owner accordingly
    * Return: Void
    *******************************************************************/
    private void setLeadOwner(Lead theLead, Id nonPendingQueueId, LeadRoutingInfo lrInfo) {

        System.debug('theLead: ' + theLead);
        System.debug('theLead.OwnerId: ' + theLead.OwnerId);
        System.debug('theLead.Status: ' + theLead.Status);
        System.debug('theLead.Pending_Queue_Id__c: ' + theLead.Pending_Queue_Id__c);
        System.debug('theLead.Owner.Type is User: ' + String.valueOf(theLead.OwnerId).startsWith('005'));
        System.debug('theLead.Owner.Type is Queue: ' + String.valueOf(theLead.OwnerId).startsWith('00G'));
        System.debug('nonPendingQueueId: ' + nonPendingQueueId);
        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        System.debug('Non_workable_leads_Q: ' + Non_workable_leads_Q);
        //System.debug('Hippo_Agency_Sales_Queue: ' + Hippo_Agency_Sales_Queue);

        Boolean bLeadIsPendingDue2OutsideOfBusinessHours = isLeadPendingDue2OutsideOfBusinessHours(theLead, nonPendingQueueId);

        // honor pre assignment of lead owner to HAS (SFDC-1079/1868), to an agent (warm transfer, SFDC-1604) or 'assign to self' (SFDC-1903)
        if ( ((Trigger.isInsert && !theLead.Status.equalsIgnoreCase('Cancelled')) &&
             (theLead.OwnerId.equals(HAS_Internal_Referrals_Queue) ||
             (String.isNotBlank(theLead.Lead_Source__c) && theLead.Lead_Source__c.equalsIgnoreCase('Internal Referral Warm Transfer')))) ||
             (Trigger.isUpdate && (theLead.OwnerId.equals(HAS_Internal_Referrals_Queue) ||
             (String.isNotBlank(theLead.Lead_Source__c) && theLead.Lead_Source__c.containsIgnoreCase('Internal Referral')))) ||
             (Trigger.isInsert && !theLead.Status.equalsIgnoreCase('Cancelled') && !isCurrentUserAPI() && theLead.OwnerId.equals(UserInfo.getUserId())) ) {

            return;
        }

        System.debug('SetLeadOwner, Excluded_RecordTypes_by_Id: ' + Excluded_RecordTypes_by_Id);
        System.debug('SetLeadOwner, theLead.RecordTypeId: ' + theLead.RecordTypeId);
        System.debug('SetLeadOwner, estPendingLeadsQueue: ' + estPendingLeadsQueue);
        System.debug('SetLeadOwner, pstPendingLeadsQueue: ' + pstPendingLeadsQueue);

        if ( !Excluded_RecordTypes_by_Id.contains(theLead.RecordTypeId) && (theLead.OwnerId?.equals(estPendingLeadsQueue) || theLead.OwnerId?.equals(pstPendingLeadsQueue)) && nonPendingQueueId != Lead_High_Urgency_Queue && nonPendingQueueId != Lead_Partner_Channel_High_Urgency_Queue ) {

            theLead.Pending_Queue_Id__c = nonPendingQueueId;
            //bLeadIsPendingDue2OutsideOfBusinessHours = true;
            System.debug('Set Lead Pending_Queue_Id__c');
        }
        else {

            // SFDC-714 (all leads that get to the two Qs (Pre-Bind UW Referrals Q, Lead Queue A) to remain there no matter what...)
            System.debug('Lead owner is lead source a OR prebined uw referrals queues: ' + String.valueOf(theLead.OwnerId.equals(Techsee_Queue) || theLead.OwnerId.equals(Lead_Prebind_UW_Referrals)));
            theLead.OwnerId = theLead.OwnerId.equals(Techsee_Queue) || theLead.OwnerId.equals(Lead_Prebind_UW_Referrals) || /*1492*/(Trigger.isUpdate && String.valueOf(theLead.OwnerId).startsWith('005')) ? theLead.OwnerId : /* If running user is not API and lead owner is standard user, let manager/agent to manually set owner transfer */ (Trigger.isUpdate && !Utils.isCurrentUserAPI() && !String.valueOf(theLead.OwnerId).startsWith('00G')) ? theLead.OwnerId : nonPendingQueueId;

            if ( theLead.OwnerId == nonPendingQueueId ) {

                System.debug('Lead OwnerId was set to: ' + theLead.OwnerId);
            }
            else {

                System.debug('Lead OwnerId remains unchanged: ' + theLead.OwnerId);
            }
        }

        System.debug('setLeadOwner, theLead.UTM_Source__c: ' + theLead.UTM_Source__c);
        theLead.Status = String.isNotBlank(theLead.UTM_Source__c) && theLead.UTM_Source__c.equalsIgnoreCase(LeadTriggerHandler.SMS_Reactivation_Dummy_Account_Name) ? 'New' : theLead.Status;
        theLead.Disqualified_Reason__c = String.isNotBlank(theLead.UTM_Source__c) && theLead.UTM_Source__c.equalsIgnoreCase(LeadTriggerHandler.SMS_Reactivation_Dummy_Account_Name) ? '' : theLead.Disqualified_Reason__c;
        System.debug('setLeadOwner, theLead.Status: ' + theLead.Status);
        System.debug('setLeadOwner, theLead.Pending_Queue_Id__c: ' + theLead.Pending_Queue_Id__c);

        Boolean isPendingNonWorkable = String.isBlank(theLead.Pending_Queue_Id__c) ? false : theLead.Pending_Queue_Id__c.equals(Non_workable_leads_Q);
        System.debug('setLeadOwner, isPendingNonWorkable: ' + isPendingNonWorkable);

        if ( ((lrInfo.is_has && ( String.isNotBlank(theLead.Lead_Score__c) && !map_toggledOffLeadScores.containsKey(theLead.Lead_Score__c) )) || // this use case is for Outside Sales Queue so need to keep it
             (lrInfo.is_has && String.isBlank(theLead.Lead_Score__c))) && // this use case is for Outside Sales Queue so need to keep it
             !theLead.Status.equalsIgnoreCase('Cancelled') ) { // ( theLead.OwnerId.equals(Non_workable_leads_Q) || isPendingNonWorkable) && !theLead.Status.equalsIgnoreCase('Cancelled') ) { // SFDC-1079

            setHASLead(theLead, lrInfo, bLeadIsPendingDue2OutsideOfBusinessHours);
        }
    }

    private Boolean isLeadPendingDue2OutsideOfBusinessHours(Lead theLead, Id nonPendingQueueId) {

        Boolean bLeadIsPendingDue2OutsideOfBusinessHours = false;

        if ( !Excluded_RecordTypes_by_Id.contains(theLead.RecordTypeId) && (theLead.OwnerId?.equals(estPendingLeadsQueue) || theLead.OwnerId?.equals(pstPendingLeadsQueue)) && nonPendingQueueId != Lead_High_Urgency_Queue && nonPendingQueueId != Lead_Partner_Channel_High_Urgency_Queue ) {

            bLeadIsPendingDue2OutsideOfBusinessHours = true;
        }

        System.debug('bLeadIsPendingDue2OutsideOfBusinessHours: ' + bLeadIsPendingDue2OutsideOfBusinessHours);

        return bLeadIsPendingDue2OutsideOfBusinessHours;
    }

    private void setHASLead(Lead theLead, LeadRoutingInfo lrInfo, Boolean bLeadIsPendingDue2OutsideOfBusinessHours) {

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;
        System.debug('setHASLead, ffUnderwritingDeclinationsLead2HASQueue: ' + ffUnderwritingDeclinationsLead2HASQueue);
        System.debug('setHASLead, bLeadIsPendingDue2OutsideOfBusinessHours: ' + bLeadIsPendingDue2OutsideOfBusinessHours);
        Boolean isHAS = (lrInfo.is_has && lrInfo.queue_dev_name.equalsIgnoreCase('Hippo_Agency_Sales') && ffUnderwritingDeclinationsLead2HASQueue) || (lrInfo.is_has && !lrInfo.queue_dev_name.equalsIgnoreCase('Hippo_Agency_Sales'));
        System.debug('setHASLead, isHAS: ' + isHAS);
        System.debug('setHASLead, isHAS queue_dev_name: ' + lrInfo.queue_dev_name);
        System.debug('setHASLead, isHAS queue_id: ' + lrInfo.queue_id);

        Boolean condition = (Trigger.isUpdate && (!Utils.isCurrentUserAPI() || !String.valueOf(theLead.OwnerId).startsWith('00G')));
        System.debug('setHASLead, condition: ' + condition);

        theLead.OwnerId = isHAS && !bLeadIsPendingDue2OutsideOfBusinessHours ? (Trigger.isUpdate && (isCurrentUserAPI() && !String.valueOf(theLead.OwnerId).startsWith('00G'))) ? theLead.OwnerId : lrInfo.queue_id : theLead.OwnerId;

        //////if ( /*1492*/(Trigger.isUpdate && (String.valueOf(theLead.OwnerId).startsWith('005') || false)) || Trigger.isInsert ) {
        //theLead.OwnerId = isHAS && !bLeadIsPendingDue2OutsideOfBusinessHours /*&& String.valueOf(theLead.OwnerId).startsWith('00G')*/ ?
                //(Trigger.isUpdate && (!Utils.isCurrentUserAPI() || !String.valueOf(theLead.OwnerId).startsWith('00G'))) ? theLead.OwnerId : lrInfo.queue_id : theLead.OwnerId;
        //////}

        System.debug('setHASLead, theLead.OwnerId: ' + theLead.OwnerId);
        System.debug('setHASLead, theLead.Pending_Queue_Id__c (Before override): ' + theLead.Pending_Queue_Id__c);
        theLead.Pending_Queue_Id__c = theLead.Pending_Queue_Id__c != null && isHAS && bLeadIsPendingDue2OutsideOfBusinessHours ? lrInfo.queue_id : (theLead.Pending_Queue_Id__c != null ? theLead.Pending_Queue_Id__c : (bLeadIsPendingDue2OutsideOfBusinessHours ? lrInfo.queue_id : theLead.Pending_Queue_Id__c));
        System.debug('setHASLead, theLead.Pending_Queue_Id__c (After override): ' + theLead.Pending_Queue_Id__c);
        theLead.Lead_Source__c = isHAS && String.isNotBlank(lrInfo.lead_source) /*&& String.valueOf(theLead.OwnerId).startsWith('00G')*/ ? lrInfo.lead_source : theLead.Lead_Source__c;
        System.debug('setHASLead, theLead.Lead_Source__c: ' + theLead.Lead_Source__c);
        theLead.Disqualified_Reason__c = lrInfo.disqualified_reason;
        System.debug('setHASLead, theLead.Disqualified_Reason__c: ' + theLead.Disqualified_Reason__c);
    }

    /******************************************************************
    * Method: checkSpecificLeadSource, private (SFDC-451)
    * Description: Check if the Lead is from Specific Organization + UTM_Source and if so, route to a specific queue as define in 'Lead Queue Mapping' custom metadata.
    * If the target queue is High_Urgency_Queue then it is required to cancel the routing to EST/PST queues that could have happened earlier
    * and leave the Pending_Queue_Id__c EMPTY and the OwnerId set to High_Urgency_Queue
    * Return: Boolean
    *******************************************************************/
    private Boolean checkSpecificLeadSource(Lead theLead, LeadRoutingInfo lrInfo) {

        System.debug('Inside checkSpecificLeadSource()');

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PennyMac_Lead');
        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('AmeriSave_Lead');

        String account_id = theLead?.Organization__c;
        String account_name = String.isNotBlank(account_id) ? accounts_in_context.get(account_id)?.Name.toLowerCase() : null;

        System.debug('checkSpecificLeadSource, account_name: ' + account_name);

        Map<String, Utils.LeadMapping> leadQueuesMap = Utils.getLeadQueuesMapping();

        LeadTriggerHandler.UTMSourceLeadInfo utmSourceLeadInfo = getUTMSourceLeadInfo(theLead);

        if ( utmSourceLeadInfo != null ) {

            setLeadOwner(theLead, getSpecificSourceLeadQueueId(utmSourceLeadInfo.queue_dev_name), lrInfo);
            System.debug('checkSpecificLeadSource, theLead.OwnerId: ' + theLead.OwnerId);

            if ( theLead.OwnerId == Facebook_Leads ) { // SFDC-1540

                theLead.Lead_Source__c = String.isBlank(theLead.Lead_Source__c) ? 'Facebook' : theLead.Lead_Source__c;
            }

            return String.isNotBlank(theLead.OwnerId) ? true : false;
        }
        else if ( isJVLead(theLead, pmRecordType, LeadTriggerHandler.Pennymac_Related_Token) ) {

            System.debug('checkSpecificLeadSource, isJVLead(pmRecordType): TRUE');

            /* Replaced by SFDC-1752
            Boolean ffPennyMacRoute2NonWorkableQueue = FeatureFlags.instance.ff_PennyMac_Leads_to_Non_Workable_Queue;
            Id queue_2_route = Utils.getQueueId(ffPennyMacRoute2NonWorkableQueue ? 'Non_workable_leads_Q' : 'PennyMac_Leads');
            setJVLead(theLead, pmRecordType, queue_2_route, lrInfo);
             */

            setPennyMacLeadOwner(theLead, lrInfo); // SFDC-1752

            System.debug('checkSpecificLeadSource, theLead.OwnerId: ' + theLead.OwnerId);

            return String.isNotBlank(theLead.OwnerId) ? true : false;
        }
        else if ( isJVLead(theLead, amsRecordType, LeadTriggerHandler.AmeriSave_Related_Token) ) {

            System.debug('checkSpecificLeadSource, isJVLead(amsRecordType): TRUE');

            /* Replaced by SFDC-1848
            Id queue_2_route = Utils.getQueueId('AmeriSave_Leads');
            setJVLead(theLead, amsRecordType, queue_2_route, lrInfo);
             */

            setAmerisaveLeadOwner(theLead, lrInfo); // SFDC-1848

            System.debug('checkSpecificLeadSource, theLead.OwnerId: ' + theLead.OwnerId);

            return String.isNotBlank(theLead.OwnerId) ? true : false;
        }
        else {

            return false;
        }
    }

    private Id getSpecificSourceLeadQueueId(String queue_dev_name) {

        System.debug('getSpecificSourceLeadQueueId, queue_dev_name: ' + queue_dev_name);

        switch on queue_dev_name {

            when 'Techsee_Queue' {

                return Techsee_Queue;
            }
            when 'SMS_Reactivation' {

                return SMS_Reactivation;
            }
            when 'Facebook_Leads' {

                return Facebook_Leads;
            }
            when 'High_Urgency_Queue' {

                return Lead_High_Urgency_Queue;
            }
            when 'Partner_Channel_High_Urgency_Queue' {

                return Lead_Partner_Channel_High_Urgency_Queue;
            }
            when else {

                return Utils.getQueueId(queue_dev_name);
            }
        }
    }

    /*
    Method: findDuplicates
    Description: Look for lead duplication based on logic described in SFDC-408, SFDC-561, SFDC-570
    The method is being executed only during AFTER INSERT event as the lead unique key is a formula field and formulas only get calculated after insert
    Return: None, just flag the duplicated leads as cancelled by duplication and assign to Duplicate Leads queue
    TBD: Look for duplicates on update ?!
    */
    private void findDuplicates() {

        if ( !FeatureFlags.instance.ff_Lead_De_Duplication_by_Code && !Test.isRunningTest() ) return;

        // check for lead duplications after lead insert only since formula fields are getting calculated after insert only
        // and we user Deduplication_Key__c formula to identify the lead uniqueness
        if ( Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {

            Map<Id, SObject> map_LeadId2ItsDup = LeadDeduplication.findDuplicates((Map<Id, Lead>)Trigger.newMap);

            System.debug('findDuplicates, map_LeadId2ItsDup: ' + map_LeadId2ItsDup);

            Map<Id, Lead> leads2Update = new Map<Id, Lead>();
            Map<Id, Lead> hcrLeads2Update = new Map<Id, Lead>(); // SFDC-1981
            Map<String, Duplicate_Lead_Record__c> map_DuplicateLeadRecords = new Map<String, Duplicate_Lead_Record__c>();

            Id 	Duplicate_Leads_Q = Utils.getQueueId('Already_Purchased');
            Id  Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
            Id  JV_Non_workable_leads_Q = Utils.getQueueId('Non_workable_JV_leads_Q');

            Map<Id, Set<String>> map_rule2_LeadId2OriginalOwnerId = new Map<Id, Set<String>>(); // rule 2 as required by SFDC-561
            Map<Id, String> map_rule2_LeadId2MessageBody = new Map<Id, String>(); // rule 2 as required by SFDC-561

            for (LeadItem theLead : objLeadItems.lst_LeadItems) {

                Lead my_Lead = theLead.my_lead;

                system.debug('findDuplicates,, theLead.unique_identifier: ' + theLead.unique_identifier);
                system.debug('findDuplicates,, map_LeadUniqueId2IsCreatedByAgent: ' + map_LeadUniqueId2IsCreatedByAgent);
                Boolean isCreatedByAgent = map_LeadUniqueId2IsCreatedByAgent.containsKey(theLead.unique_identifier) ? map_LeadUniqueId2IsCreatedByAgent.get(theLead.unique_identifier) : isLeadCreatedByAgentOrKnownProcess(theLead);
                system.debug('findDuplicates,, isCreatedByAgent: ' + isCreatedByAgent);
                if ( isCreatedByAgent ) continue;

                Boolean userManualOwnerTransfer = isManualOwnerTransferToUser(my_Lead);
                System.debug('findDuplicates, userManualOwnerTransfer: ' +  userManualOwnerTransfer);
                if ( userManualOwnerTransfer ) continue;

                if ( LeadTriggerHandler.TESTING_INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY || /* to Unit Test 'Transfer Person Account to HAS' Flow exception with INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY */
                     String.isBlank(my_Lead.Lead_Source__c) ||
                     !my_Lead.Lead_Source__c.containsIgnoreCase('Internal Referral') ) { // SFDC-1464 (Change De-Duplication Logic on SFDC-408/561)

                    if (map_LeadId2ItsDup.containsKey(my_Lead.Id)) {

                        SObject foundDup = map_LeadId2ItsDup.get(my_Lead.Id);
                        System.debug('findDuplicates, foundDup: ' + foundDup);
                        System.debug('findDuplicates, dup is for the currently created lead: ' + my_Lead);

                        Lead my_updated_lead = null;

                        // Rule 1 related (SFDC-408)
                        if (foundDup instanceof InsurancePolicy) {

                            my_updated_lead = new Lead(Id = my_lead.Id, Status = 'Cancelled', Disqualified_Reason__c = 'Duplicate', OwnerId = Duplicate_Leads_Q);
                        }
                        // Rule 2,3, 4 related (SFDC-561, SFDC-1469, SFDC-1463)
                        else if (foundDup instanceof Lead) {

                            Lead dupLead = (Lead)foundDup;

                            if ( !dupLead.IsJVLead__c && dupLead.Is_HCR_Lead__c == 'No' ) { // NOT SFDC-1469/1597

                                if (my_Lead.Is_HCR_Lead__c == 'Yes') { // SFDC-1981

                                    System.debug('Inside SFDC-1981, new lead: ' + my_Lead);
                                    System.debug('Inside SFDC-1981, dup lead: ' + dupLead);

                                    if (dupLead.Status == 'New' || dupLead.Status == 'Cancelled' || dupLead.Status == 'Closed') { // Cancel the POD (Existing/Older) lead

                                        System.debug('Inside SFDC-1981, updating HCR, cancelling POD');

                                        my_updated_lead = new Lead(Id = dupLead.Id, Status = 'Cancelled', Disqualified_Reason__c = 'Duplicate', OwnerId = Non_workable_leads_Q);//, Dup_Parent__c = my_Lead.Id);
                                        // Update the new created HCR lead with POD Lead Id from the old POD lead
                                        Lead hcrLead2Update = new Lead(Id = my_Lead.Id, POD_Lead_Id__c = dupLead.POD_Lead_Id__c, Lead_Source__c = dupLead.Lead_Source__c);
                                        if ( String.isNotBlank(dupLead.Declination_Reason__c) ) hcrLead2Update.Declination_Reason__c = dupLead.Declination_Reason__c;
                                        hcrLeads2Update.put(my_Lead.Id, hcrLead2Update);

                                        // create reference to the duplicate record
                                        Duplicate_Lead_Record__c duplicateLeadRecord = LeadDeduplication.createDuplicateLeadRecord(my_Lead, dupLead);
                                        if (null != duplicateLeadRecord) map_DuplicateLeadRecords.put(duplicateLeadRecord.Composite_Key__c, duplicateLeadRecord);
                                    }
                                    else { // POD lead is at work --> Update the POD lead and cancel the new HCR lead

                                        System.debug('Inside SFDC-1981, updating POD, cancelling HCR');

                                        hcrLeads2Update.put(my_Lead.Id, new Lead(Id = my_Lead.Id, Status = 'Cancelled', Disqualified_Reason__c = 'Duplicate', OwnerId = Non_workable_leads_Q));//, Dup_Parent__c = dupLead.Id));
                                        // Update the old POD Lead with Last_Page_Visited__c and Quote_Type_Selected__c (HCR Carrier Selected) from the newly created HCR lead that is also cancelled
                                        leads2Update.put(dupLead.Id, new Lead(Id = dupLead.Id, UTM_Source__c = my_Lead.UTM_Source__c, Declination_Reason__c = my_Lead.Declination_Reason__c, Last_Page_Visited__c = my_Lead.Last_Page_Visited__c, Quote_Type_Selection__c = my_Lead.Quote_Type_Selection__c, Quote_Type_Selected__c = my_Lead.Quote_Type_Selected__c));

                                        // create reference to the duplicate record
                                        Duplicate_Lead_Record__c duplicateLeadRecord = LeadDeduplication.createDuplicateLeadRecord(dupLead, my_Lead);
                                        if (null != duplicateLeadRecord) map_DuplicateLeadRecords.put(duplicateLeadRecord.Composite_Key__c, duplicateLeadRecord);
                                    }
                                }
                                else {

                                    my_updated_lead = new Lead(Id = my_lead.Id, Status = 'Cancelled', Disqualified_Reason__c = 'Duplicate', OwnerId = Non_workable_leads_Q);
                                    map_rule2_LeadId2OriginalOwnerId.put(dupLead.Id, new Set<String>{
                                            String.valueOf(dupLead.get('OwnerId'))
                                    });
                                    map_rule2_LeadId2MessageBody.put(dupLead.Id, Utils.getLeadDupNotificationBody(dupLead, my_Lead));
                                }
                            }
                            else { // SFDC-1469/1597

                                System.debug('findDuplicates, dupLead.OwnerId: ' +  dupLead.OwnerId);
                                System.debug('findDuplicates, dupLead.Owner.Name: ' +  dupLead.Owner.Name);
                                System.debug('findDuplicates, my_lead.OwnerId: ' +  my_lead.OwnerId);
                                System.debug('findDuplicates, my_lead.Owner.Name: ' +  my_lead.Owner.Name);

                                // Liron: COMEBACK - NEED TO SEPARATE BETWEEN 'APPLICATION USER' UPDATE AND INSERT ??!!
                                // IF IT IS AN UPDATE BY APPLICATION USER, THEN WE DON'T NEED TO CANCEL AN EXISTING WORKABLE LEAD ??!! (SEE COMMENTS IN SFDC-1492)
                                if ( dupLead.IsJVLead__c && /*1492*/!String.valueOf(my_lead.OwnerId).startsWith('005') ) {

                                    my_updated_lead = new Lead(Id = my_lead.Id, Status = 'Cancelled', Disqualified_Reason__c = 'Duplicate', OwnerId = JV_Non_workable_leads_Q);
                                }
                                else if ( dupLead.Is_HCR_Lead__c == 'Yes' && /*1492*/!String.valueOf(my_lead.OwnerId).startsWith('005') ) {

                                    my_updated_lead = new Lead(Id = my_lead.Id, Status = 'Cancelled', Disqualified_Reason__c = 'Duplicate', OwnerId = Non_workable_leads_Q);
                                }
                            }
                        }

                        if (null != my_updated_lead) leads2Update.put(my_updated_lead.Id, my_updated_lead);
                    }
                }
            }

            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;

            LeadTriggerHandler.SKIP_RECURSION = true;
            if (leads2Update.size() > 0) {

                //System.debug('User in context: ' + UserInfo.getUserName() + ', ' + UserInfo.getUserId());
                //List<UserRecordAccess> ura = [SELECT RecordId, HasAllAccess, HasDeleteAccess, HasEditAccess, HasTransferAccess, HasReadAccess, MaxAccessLevel FROM UserRecordAccess WHERE RecordId IN: leads2Update.keySet() AND UserId =: UserInfo.getUserId()];
                //System.debug('UserRecordAccess for user in context: ' + ura);
                System.debug('leads2Update.values(): ' + leads2Update.values());
                Database.SaveResult [] sr = Database.update(leads2Update.values(), dml);
                System.debug('leads2Update.values() SaveResult: ' + sr);
                //update leads2Update.values();
            }
            if (hcrLeads2Update.size() > 0) {

                System.debug('hcrLeads2Update.values(): ' + hcrLeads2Update.values());
                Database.SaveResult [] sr = Database.update(hcrLeads2Update.values(), dml);
                System.debug('hcrLeads2Update.values() SaveResult: ' + sr);
                //update hcrLeads2Update.values();
            }
            if ( map_DuplicateLeadRecords.size() > 0 ) {

                System.debug('Creating junction records for lead duplications: ' + map_DuplicateLeadRecords);
                upsert map_DuplicateLeadRecords.values() Composite_Key__c;
            }
            LeadTriggerHandler.SKIP_RECURSION = false;

            // get all the tasks created and associated with the dup leads and it's original lead (parent)
            Map<Id, Task> map_leadId2Task = new Map<Id, Task>();
            List<Task> lst_tasksCreated = [SELECT Id, WhoId, Original_Lead__c, Subject, Status, ActivityDate, Description FROM Task WHERE WhoId IN :Trigger.newMap.keySet() AND Original_Lead__c != ''];
            System.debug('findDuplicates, lst_tasksCreated: ' + lst_tasksCreated);
            for (Task tsk : lst_tasksCreated) {
                map_leadId2Task.put(tsk.WhoId, tsk);
            }
            System.debug('map_leadId2Task: ' + map_leadId2Task);

            // as required by SFDC-561 - Send a notification to the current b2c direct sales owner of the already exit (duplicated) lead
            System.debug('findDuplicates, map_rule2_LeadId2OriginalOwnerId: ' + map_rule2_LeadId2OriginalOwnerId);
            System.debug('findDuplicates, map_rule2_LeadId2MessageBody: ' + map_rule2_LeadId2MessageBody);
            for (Id leadId : map_rule2_LeadId2OriginalOwnerId.keySet()) {

                Utils.sendBellNotification(map_leadId2Task.get(leadId)?.Id, Label.LEAD_DDUP_RULE2_TITLE, map_rule2_LeadId2MessageBody.get(leadId), map_rule2_LeadId2OriginalOwnerId.get(leadId));
            }
        }
    }

    /******************************************************************
    * Method: isHASLead, private
    * Description: Check if Lead should be assigned to Hippo Agency Sales (HAS) queue
    * Return: Boolean
    *******************************************************************/
    private LeadRoutingInfo isHASLead(Lead my_Lead) {

        LeadRoutingInfo lrInfo = new LeadRoutingInfo();

        Boolean ffUnderwritingDeclinationsLead2HASQueue = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;
        System.debug('isHASLead, ffUnderwritingDeclinationsLead2HASQueue: ' + ffUnderwritingDeclinationsLead2HASQueue);

        System.debug('isHASLead, my_lead.OwnerId: ' +  my_lead.OwnerId);
        System.debug('isHASLead, my_lead.Owner.Name: ' +  my_lead.Owner.Name);
        System.debug('isHASLead, isCurrentUserAPI(): ' + isCurrentUserAPI());
        System.debug('isHASLead, my_lead.Status: ' + my_lead.Status);
        System.debug('isHASLead, my_lead.POD_Quote_ID__c: ' + my_lead.POD_Quote_ID__c);
        System.debug('isHASLead, my_lead.Phone: ' + my_lead.Phone);
        System.debug('isHASLead, my_lead.MobilePhone: ' + my_lead.MobilePhone);
        System.debug('isHASLead, my_lead.Non_Cat_Risk_Class__c: ' + my_lead.Non_Cat_Risk_Class__c);
        System.debug('isHASLead, my_lead.Cat_Risk_Class__c: ' + my_lead.Cat_Risk_Class__c);
        System.debug('isHASLead, my_lead.State: ' + my_lead.State);
        System.debug('isHASLead, my_lead.Lead_Score__c: ' + my_lead.Lead_Score__c);
        System.debug('isHASLead, my_lead.Disqualified_Reason__c: ' + my_lead.Disqualified_Reason__c);

        Account leadAccount = null; // CURRENTLY NOT IN USE AS LOOKS LIKE THE FORMULA ON THE LEAD FIELD IS CALCULATED ALTHOUGH IT IS A BEFORE INSERT EVENT !!!
        if ( String.isNotBlank(my_Lead.Account__c) ) {

            leadAccount = accounts_in_context.get(my_Lead.Account__c);
            System.debug('isHASLead, my_lead.Workable_by_Hippo_formula_text__c: ' + my_lead.Workable_by_Hippo_formula_text__c);
            System.debug('isHASLead, my_lead.Account__r.Workable_by_Hippo_picklist__c: ' + my_lead.Account__r.Workable_by_Hippo_picklist__c);
            System.debug('isHASLead, leadAccount: ' + leadAccount);
            //System.debug('isHASLead, leadAccount: ' + leadAccount.Workable_by_Hippo_picklist__c);
        }

        //System.debug('isHASLead, my_lead.Declination_Reason__c: ' + my_lead.Declination_Reason__c);
        //System.debug('isHASLead, my_lead.Partner_Message__c: ' + my_lead.Partner_Message__c);

        String account_id = my_lead?.Organization__c;
        System.debug('isHASLead, account_id: ' + account_id);

        String state = String.isNotBlank(my_Lead.State) ? my_Lead.State : '';
        System.debug('isHASLead, lead state: ' + state);
        Utils.StateInfo stateInfo = map_State2StateInfo.containsKey(state) ? map_State2StateInfo.get(state) : new Utils.StateInfo();
        System.debug('isHASLead, lead stateInfo: ' + stateInfo);

        System.debug('isHASLead, isWorkableByCatRiskClass(my_Lead): ' + isWorkableByCatRiskClass(my_Lead));

        Map<String, Boolean> uwDeclinationReasonsWithRouting = Utils.getUWDeclinationReasonsWithRoutingInfo();
        System.debug('isHASLead, uwDeclinationReasonsWithRouting: ' + uwDeclinationReasonsWithRouting);

        if ( (FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code || Test.isRunningTest()) && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {

            if ( ( Trigger.isInsert || ( Trigger.isUpdate && ( my_lead.OwnerId != UserInfo.getUserId() || Test.isRunningTest() ) &&
                 ( /*isCurrentUserAPI() || Test.isRunningTest()*/true ) ) ) &&
                 ( ( String.isBlank(my_Lead.Declination_Reason__c) && my_Lead.Disqualified_Reason__c != 'Duplicate' && my_lead.Status.equalsIgnoreCase('New') /*&& String.isBlank(my_Lead.Organization__c)*/ && ( /*isCurrentUserAPI() || Test.isRunningTest()*/true ) &&
                   ( String.isNotBlank(my_Lead.FinServ__ReferredByUser__c) ) ) )
               ) {

                lrInfo.is_has = true;
                lrInfo.queue_dev_name = 'HAS_Internal_Referrals';
                lrInfo.queue_id = HAS_Internal_Referrals_Queue;
                lrInfo.lead_source = 'Internal Referral Cold Transfer';
            }
            else if ( ( Trigger.isInsert || ( Trigger.isUpdate && ( my_lead.OwnerId != UserInfo.getUserId() || Test.isRunningTest() ) &&
                    ( /*isCurrentUserAPI() || Test.isRunningTest()*/true ) ) ) &&
                    ( ( String.isBlank(my_Lead.Declination_Reason__c) &&  my_Lead.Disqualified_Reason__c != 'Duplicate' && my_lead.Status.equalsIgnoreCase('New') /*&& String.isNotBlank(my_Lead.Organization__c)*/ && ( /*isCurrentUserAPI() || Test.isRunningTest()*/true ) &&
                      (( my_Lead.Workable_by_Hippo_formula_text__c == 'Yes' && my_lead.Non_Cat_Risk_Class__c == 'referral' && my_Lead.Non_Cat_Risk_Score__c < 1.50 /*&& stateInfo.has_uw_referral*/ ) || ( String.isBlank(my_Lead.Organization__c) && my_lead.Non_Cat_Risk_Class__c == 'referral' && my_Lead.Non_Cat_Risk_Score__c < 1.50 /*&& stateInfo.has_uw_referral*/ )) ) )
                ) {

                lrInfo.is_has = true;
                //lrInfo.queue_dev_name = 'HAS_UW_Referrals';
                //lrInfo.queue_id = HAS_UW_Referrals_Queue;
                lrInfo.lead_source = 'UW Referral';

                if ( String.isNotBlank(my_Lead.Lead_Score__c) && Integer.valueOf(my_Lead.Lead_Score__c) >= 5 ) {

                    lrInfo.queue_dev_name = 'HAS_UW_Referrals_1';
                    lrInfo.queue_id = UW_Referrals_1;
                }
                else {

                    lrInfo.queue_dev_name = 'HAS_UW_Referrals_2';
                    lrInfo.queue_id = UW_Referrals_2;
                }
            }
            else if ( ( Trigger.isInsert || ( Trigger.isUpdate && ( my_lead.OwnerId != UserInfo.getUserId() || Test.isRunningTest() ) &&
                    ( /*isCurrentUserAPI() || Test.isRunningTest()*/true ) ) ) &&
                    ( ( String.isNotBlank(my_Lead.Declination_Reason__c) && my_lead.Status.equalsIgnoreCase('New') &&
                      ( String.isBlank(my_Lead.Organization__c) || my_Lead.Workable_by_Hippo_formula_text__c == 'Yes' ) && ( /*isCurrentUserAPI() || Test.isRunningTest()*/true ) ) )
                    ) {

                System.debug('my_Lead.Declination_Reason__c: ' + my_Lead.Declination_Reason__c);
                Boolean bRoutableDeclinationReason = true; // this is a 'NO' list so if value not in list, it is assumed routable
                if ( uwDeclinationReasonsWithRouting.containsKey(my_Lead.Declination_Reason__c.toLowerCase()) )
                {
                    bRoutableDeclinationReason = uwDeclinationReasonsWithRouting.get(my_Lead.Declination_Reason__c.toLowerCase());
                }
                System.debug('bRoutableDeclinationReason: ' + bRoutableDeclinationReason);
                lrInfo.is_has = true;
                lrInfo.queue_dev_name = bRoutableDeclinationReason && ffUnderwritingDeclinationsLead2HASQueue ? 'HAS_UW_Declinations' : 'Non_workable_leads_Q';
                lrInfo.queue_id = bRoutableDeclinationReason && ffUnderwritingDeclinationsLead2HASQueue ? HAS_UW_Declinations_Queue : Utils.getQueueId('Non_workable_leads_Q');
                lrInfo.lead_source = 'UW Declinations';
                lrInfo.disqualified_reason = bRoutableDeclinationReason ? '' : 'Nonworkable Declination';
            }
            /*
            else if ( ( Trigger.isInsert || ( Trigger.isUpdate && ( my_lead.OwnerId != UserInfo.getUserId() || Test.isRunningTest() ) &&
                      ( true ) ) ) &&
                      ( ( String.isBlank(my_Lead.Declination_Reason__c) && my_Lead.Disqualified_Reason__c != 'Duplicate' && my_lead.Status.equalsIgnoreCase('New') && String.isBlank(my_Lead.Organization__c) && ( true ) &&
                        ( ( String.isNotBlank(my_lead.Phone) && my_lead.Phone != 'MISSING' ) || ( String.isNotBlank(my_lead.MobilePhone) && my_lead.MobilePhone != 'MISSING' ) ) &&
                        ( !isWorkableByCatRiskClass(my_Lead) || String.isBlank(my_Lead.Lead_Score__c) ) ) )
                ) {

                lrInfo.is_has = true;
                lrInfo.queue_dev_name = ffUnderwritingDeclinationsLead2HASQueue ? 'Hippo_Agency_Sales' : 'Non_workable_leads_Q'; //'Hippo_Agency_Sales';
                lrInfo.queue_id = ffUnderwritingDeclinationsLead2HASQueue ? Hippo_Agency_Sales_Queue : Utils.getQueueId('Non_workable_leads_Q'); //Hippo_Agency_Sales_Queue;
            }
            */
        }

        System.debug('isHASLead, res: ' + lrInfo);

        return lrInfo;
    }

    /******************************************************************
    * Method: isSpecificOrganization, private
    * Description: Check if Lead is related to any organization and set the owner per the configured queue
     * first, we check by a dedicated jv record type name. if it is, then we set to the target jv queue
     * else, we check for a match between the lead organization to leads queue mapping custom metadata
    * Return: Boolean
    *******************************************************************/
    private Boolean isSpecificOrganization(Lead my_Lead, Map<Id, Account> accounts_in_context, LeadRoutingInfo lrInfo) {

        Boolean res = false;

        RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('B2C_Sales');
        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PennyMac_Lead');
        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('AmeriSave_Lead');
        RecordTypeInfo rfRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Risk_Factor');
        RecordTypeInfo haRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Hippo_Analytics');

        String account_id = my_Lead?.Organization__c;
        if ( account_id == null ) account_id = my_Lead?.Account__c; // COMEBACK to Check with Alice: Which field are we using: Organization__c or Account__c
        Account accInContext = null;
        if ( String.isNotBlank(account_id) ) accInContext = accounts_in_context.get(account_id);
        String account_name = String.isNotBlank(account_id) ? accounts_in_context.get(account_id)?.Name.toLowerCase() : null;
        System.debug('isSpecificOrganization accInContext: ' + accInContext);
        System.debug('isSpecificOrganization account_name: ' + account_name);
        System.debug('isSpecificOrganization my_lead.Account__c: ' + my_lead.Account__c);
        System.debug('isSpecificOrganization my_Lead.Workable_by_Hippo_formula_text__c: ' + my_Lead.Workable_by_Hippo_formula_text__c);
        System.debug('isSpecificOrganization HippoAnalytics_Org_Id: ' + HippoAnalytics_Org_Id);

        Map<String, Utils.LeadMapping> leadQueuesMap = Utils.getLeadQueuesMapping();

        system.debug('isSpecificOrganization leadQueuesMap: ' + leadQueuesMap.get(account_name));

        if ( my_Lead.RecordTypeId.equals(pmRecordType.getRecordTypeId()) ) {

            /* Replaced by SFDC-1752
            Id PennyMac_Q = Utils.getQueueId('PennyMac_Leads');
            setLeadOwner(my_Lead, PennyMac_Q, lrInfo);
             */

            setPennyMacLeadOwner(my_Lead, lrInfo); // SFDC-1752

            System.debug('isSpecificOrganization matched to PennyMac JV, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        else if ( my_Lead.RecordTypeId.equals(amsRecordType.getRecordTypeId()) ) {

            Id AmeriSave_Q = Utils.getQueueId('AmeriSave_Leads');
            setLeadOwner(my_Lead, AmeriSave_Q, lrInfo);
            System.debug('isSpecificOrganization matched to AmeriSave JV, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        else if ( rfRecordType != null && my_Lead.RecordTypeId.equals(rfRecordType.getRecordTypeId()) ) {

            Id HCR_Q = Utils.getQueueId('Loan_Depot');
            setLeadOwner(my_Lead, HCR_Q, lrInfo);
            System.debug('isSpecificOrganization matched to Risk Factor HCR, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        else if ( haRecordType != null && my_Lead.RecordTypeId.equals(haRecordType.getRecordTypeId()) ) {

            Id HCR_Q = Utils.getQueueId('Loan_Depot');
            setLeadOwner(my_Lead, HCR_Q, lrInfo);
            System.debug('isSpecificOrganization matched to Hippo Analytics HCR, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        else if ( my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId()) && String.isNotBlank(my_lead.UTM_Source__c) &&
                  my_lead.UTM_Source__c.equalsIgnoreCase('realtime') &&
                  (accInContext != null && accInContext.B2B2C__c == 'No') &&
                  (my_Lead.Workable_by_Hippo_formula_text__c == 'Yes' || (accInContext != null && accInContext.Workable_by_Hippo_picklist__c == 'Yes')) &&
                  String.isNotBlank(my_Lead.Last_Page_Visited__c) && my_lead.Last_Page_Visited__c.equalsIgnoreCase('Clicked Link')) { // HCR Lead (SFDC-1540)

            Id HCR_Clicked_on_Link_Q = Utils.getQueueId('HCR_Clicked_on_Link');
            setLeadOwner(my_Lead, HCR_Clicked_on_Link_Q, lrInfo);
            my_Lead.Lead_Source__c = String.isBlank(my_Lead.Lead_Source__c) ? 'HCR Clicked on Link' : my_Lead.Lead_Source__c;
            System.debug('isSpecificOrganization matched to HCR Clicked on Link, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        /* SFDC-1821. Add New Lead Types to HAS Lead Routing Priority Rules */
        else if ( my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId()) && String.isNotBlank(my_lead.UTM_Source__c) &&
                my_lead.UTM_Source__c.equalsIgnoreCase('realtime') &&
                (accInContext != null && accInContext.B2B2C__c == 'Yes') &&
                (my_Lead.Workable_by_Hippo_formula_text__c == 'Yes' || (accInContext != null && accInContext.Workable_by_Hippo_picklist__c == 'Yes')) &&
                String.isNotBlank(my_Lead.Last_Page_Visited__c) && my_lead.Last_Page_Visited__c.equalsIgnoreCase('Clicked Link')) { // HCR Lead (SFDC-1540)

            Id Partner_HCR_Clicked_on_Link_Q = Utils.getQueueId('Partner_HCR_Clicked_on_Link');
            setLeadOwner(my_Lead, Partner_HCR_Clicked_on_Link_Q, lrInfo);
            my_Lead.Lead_Source__c = String.isBlank(my_Lead.Lead_Source__c) ? 'Partner HCR Clicked on Link' : my_Lead.Lead_Source__c;
            System.debug('isSpecificOrganization matched to Partner HCR Clicked on Link, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        else if ( my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId()) && String.isNotBlank(my_lead.UTM_Source__c) &&
                  my_lead.UTM_Source__c.equalsIgnoreCase('realtime') &&
                  (accInContext != null && accInContext.B2B2C__c == 'No') &&
                  (my_Lead.Workable_by_Hippo_formula_text__c == 'Yes' || (accInContext != null && accInContext.Workable_by_Hippo_picklist__c == 'Yes')) &&
                  String.isNotBlank(my_Lead.Last_Page_Visited__c) && my_lead.Last_Page_Visited__c.equalsIgnoreCase('Reached Prelim Quote')) { // HCR Lead (SFDC-1540)

            Id HCR_Reached_Prelim_Quote_Q = Utils.getQueueId('HCR_Reached_Prelim_Quote');
            setLeadOwner(my_Lead, HCR_Reached_Prelim_Quote_Q, lrInfo);
            my_Lead.Lead_Source__c = String.isBlank(my_Lead.Lead_Source__c) ? 'HCR Reached Prelim Quote' : my_Lead.Lead_Source__c;
            System.debug('isSpecificOrganization matched to HCR Reached Prelim Quote, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        /* SFDC-1821. Add New Lead Types to HAS Lead Routing Priority Rules */
        else if ( my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId()) && String.isNotBlank(my_lead.UTM_Source__c) &&
                my_lead.UTM_Source__c.equalsIgnoreCase('realtime') &&
                (accInContext != null && accInContext.B2B2C__c == 'Yes') &&
                (my_Lead.Workable_by_Hippo_formula_text__c == 'Yes' || (accInContext != null && accInContext.Workable_by_Hippo_picklist__c == 'Yes')) &&
                String.isNotBlank(my_Lead.Last_Page_Visited__c) && my_lead.Last_Page_Visited__c.equalsIgnoreCase('Reached Prelim Quote')) { // HCR Lead (SFDC-1540)

            Id Partner_HCR_Reached_Prelim_Quote_Q = Utils.getQueueId('Partner_HCR_Reached_Prelim_Quote');
            setLeadOwner(my_Lead, Partner_HCR_Reached_Prelim_Quote_Q, lrInfo);
            my_Lead.Lead_Source__c = String.isBlank(my_Lead.Lead_Source__c) ? 'Partner HCR Reached Prelim Quote' : my_Lead.Lead_Source__c;
            System.debug('isSpecificOrganization matched to Partner HCR Reached Prelim Quote, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
        else if ( my_Lead.RecordTypeId.equals(b2cRecordType.getRecordTypeId()) && my_Lead.Workable_by_Hippo_formula_text__c == 'Yes' ) { // HIPPO.COM Leads (SFDC-1540)

            if ( String.isNotBlank(my_Lead.Lead_Score__c) && Integer.valueOf(my_Lead.Lead_Score__c) >= 5 ) {

                setLeadOwner(my_Lead, Workable_by_Hippo_1, lrInfo);
                System.debug('isSpecificOrganization matched to Workable By Hippo 1 B2C Lead, theLead.OwnerId: ' + my_Lead.OwnerId);
                res = true;
            }
            else if ( String.isNotBlank(my_Lead.Lead_Score__c) ) {

                setLeadOwner(my_Lead, Workable_by_Hippo_2, lrInfo);
                System.debug('isSpecificOrganization matched to Workable By Hippo 2 B2C Lead, theLead.OwnerId: ' + my_Lead.OwnerId);
                res = true;
            }
            else {

                setLeadOwner(my_Lead, Non_workable_leads_Q, lrInfo);
                System.debug('isSpecificOrganization matched to Non_workable_leads_Q B2C Lead, theLead.OwnerId: ' + my_Lead.OwnerId);
                res = true;
            }
        }
        /*
        else if ( my_Lead.RecordTypeId.equals(ldRecordType.getRecordTypeId()) ) {

            Id LoanDepot_Q = Utils.getQueueId('Loan_Depot');
            setLeadOwner(my_Lead, LoanDepot_Q, lrInfo);
            System.debug('isSpecificOrganization matched to LoanDepot Partner, theLead.OwnerId: ' + my_Lead.OwnerId);
            res = true;
        }
         */
        else if ( account_name != null && leadQueuesMap.containsKey(account_name) ) {

            /*
            Check again is not partner sales lead as it may be that it was not identified as partner sales
            prior to this point, however it is still in the mapping table under partner sales and will be set to
            partner sales here although it doesn't meet all the criteria for partner sales that should also verify lead scoring
            */
            if ( !leadQueuesMap.get(account_name).queue_dev_name.equalsIgnoreCase('B2C_Partner_Sales') ) {

                setLeadOwner(my_Lead, getSpecificSourceLeadQueueId(leadQueuesMap.get(account_name).queue_dev_name), lrInfo);

                if ( String.isNotBlank(leadQueuesMap.get(account_name).recordtype_developername) ) {

                    String recordtype_id = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(leadQueuesMap.get(account_name).recordtype_developername).getRecordTypeId();
                    if (String.isNotBlank(recordtype_id)) my_Lead.RecordTypeId = recordtype_id;
                }
                
                System.debug('isSpecificOrganization matched by organization only (using leads queue mapping metadata), theLead.OwnerId: ' + my_Lead.OwnerId);
                res = true;
            }
        }
        else {

            res = false;
        }

        return res;
    }

    public class JVLeadInfo {

        public Boolean isJVLead;
        public RecordTypeInfo jvRecordTypeInfo;

        public JVLeadInfo() {

            this.isJVLead = false;
            this.jvRecordTypeInfo = null;
        }

        public JVLeadInfo(Boolean isJVLead) {

            this.isJVLead = isJVLead;
            this.jvRecordTypeInfo = null;
        }
    }

    private LeadTriggerHandler.JVLeadInfo isJVLead(Lead theLead) {

        LeadTriggerHandler.JVLeadInfo jvLeadInfo = new LeadTriggerHandler.JVLeadInfo();

        Boolean isPennyMac  = isJVLead(theLead, Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PennyMac_Lead'), LeadTriggerHandler.Pennymac_Related_Token);
        jvLeadInfo.isJVLead = isPennyMac;
        jvLeadInfo.jvRecordTypeInfo = isPennyMac ? Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PennyMac_Lead') : null;

        if ( !isPennyMac ) {

            Boolean isAmeriSave = isJVLead(theLead, Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('AmeriSave_Lead'), LeadTriggerHandler.AmeriSave_Related_Token);
            jvLeadInfo.isJVLead = isAmeriSave;
            jvLeadInfo.jvRecordTypeInfo = isAmeriSave ? Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('AmeriSave_Lead') : null;
        }

        jvLeadInfo.isJVLead = jvLeadInfo.isJVLead || theLead.IsJVLead__c;

        return jvLeadInfo;
    }

    private Boolean isJVLead(Lead theLead, RecordTypeInfo jvRecordTypeInfo, String jvToken) {

        Boolean res = false;

        String account_id = theLead?.Organization__c;
        String account_name = String.isNotBlank(account_id) ? accounts_in_context.get(account_id)?.Name.toLowerCase() : null;

        System.debug('isJVLead, account_name: ' + account_name);

        if ( (String.isNotBlank(account_name) && account_name.containsIgnoreCase(jvToken)) ||
             (String.isNotBlank(theLead.UTM_Source__c) &&
             theLead.UTM_Source__c.toLowerCase().contains(jvToken)) ) {

            theLead.RecordTypeId = jvRecordTypeInfo.getRecordTypeId(); // SFDC-1752
            res = true;
        }
        else if ( theLead.RecordTypeId.equals(jvRecordTypeInfo.getRecordTypeId()) ) {

            res = true;
        }

        return res;
    }

    private void setJVLead(Lead theLead, RecordTypeInfo jvRecordType, Id queue_2_route, LeadRoutingInfo lrInfo) {

        setLeadOwner(theLead, queue_2_route, lrInfo);
        theLead.RecordTypeId = jvRecordType.getRecordTypeId();
        theLead.IsJVLead__c = true;

        injectOrgtoJVLeads(theLead);

        System.debug('setJVLead, theLead.OwnerId: ' + theLead.OwnerId);
        System.debug('setJVLead, theLead.IsJVLead__c: ' + theLead.IsJVLead__c);
        System.debug('setJVLead, theLead.RecordTypeId: ' + theLead.RecordTypeId);
        System.debug('setJVLead, theLead.RecordType.DeveloperName: ' + jvRecordType.getDeveloperName());
    }

    private Boolean isManualOwnerTransferToUser(Lead theLead) {

        Boolean res = false;

        if (Trigger.isAfter && Trigger.isUpdate) {

            System.debug('isManualOwnerTransferToUser Trigger.isUpdate: ' + Trigger.isUpdate);

            Lead oldLead = (Lead) Trigger.oldMap.get(theLead.Id);

            if (/*theLead.OwnerId != oldLead.OwnerId &&*/
                String.valueOf(theLead.OwnerId).startsWith('005') &&
                !Utils.isCurrentUserAPI() &&
                !Utils.isRunningUser('Application User')) {

                res = true;
            }
        }
        /*
        else if (Trigger.isAfter && Trigger.isInsert) {

            System.debug('isManualOwnerTransferToUser Trigger.isInsert: ' + Trigger.isInsert);

            if (String.valueOf(theLead.OwnerId).startsWith('005') &&
                !Utils.isCurrentUserAPI() &&
                !Utils.isRunningUser('Application User')) {

                res = true;
            }
        }
        */

        return res;
    }

    public class UTMSourceLeadInfo {

        public UTMSourceLeadInfo() {

            this.organization = null;
            this.utm_source = null;
            this.queue_dev_name = queue_dev_name;
            this.recordtype_developername = null;
        }

        public UTMSourceLeadInfo(String organization, String utm_source, String queue_dev_name, String recordtype_developername) {

            this.organization = organization;
            this.utm_source = utm_source;
            this.queue_dev_name = queue_dev_name;
            this.recordtype_developername = recordtype_developername;
        }

        public String organization { get; set; }
        public String utm_source { get; set; }
        public String queue_dev_name { get; set; }
        public String recordtype_developername { get; set; }
    }

    private LeadTriggerHandler.UTMSourceLeadInfo getUTMSourceLeadInfo(Lead theLead) {

        LeadTriggerHandler.UTMSourceLeadInfo utmSourceLeadInfo = null;

        String account_id = theLead?.Organization__c;
        String account_name = String.isNotBlank(account_id) ? accounts_in_context.get(account_id)?.Name.toLowerCase() : null;

        System.debug('getUTMSourceLeadInfo, account_name: ' + account_name);
        System.debug('getUTMSourceLeadInfo, UTM_Source__c: ' + theLead.UTM_Source__c);

        Map<String, Utils.LeadMapping> leadQueuesMapByUTMSource = Utils.getLeadQueuesMappingByUTMSource();
        System.debug('getUTMSourceLeadInfo, leadQueuesMapByUTMSource count: ' + leadQueuesMapByUTMSource.size());

        if ( String.isNotBlank(theLead.UTM_Source__c) && leadQueuesMapByUTMSource.containsKey(theLead.UTM_Source__c.toLowerCase()) ) {

            String recordtype_developername = leadQueuesMapByUTMSource.get(theLead.UTM_Source__c.toLowerCase()).recordtype_developername;
            System.debug('getUTMSourceLeadInfo, recordtype_developername: ' + recordtype_developername);

            if ( String.isNotBlank(recordtype_developername) ) { // SFDC-1559 (Need to match the record type in context to the record type in leads queue mapping, if defined)

                RecordTypeInfo parRecordTypeInfo = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(recordtype_developername);
                if ( theLead.RecordTypeId == parRecordTypeInfo.getRecordTypeId() ) {

                    utmSourceLeadInfo = new LeadTriggerHandler.UTMSourceLeadInfo(account_name, theLead.UTM_Source__c, leadQueuesMapByUTMSource.get(theLead.UTM_Source__c.toLowerCase()).queue_dev_name, recordtype_developername);
                }

            }
            else {

                utmSourceLeadInfo = new LeadTriggerHandler.UTMSourceLeadInfo(account_name, theLead.UTM_Source__c, leadQueuesMapByUTMSource.get(theLead.UTM_Source__c.toLowerCase()).queue_dev_name, recordtype_developername);
            }
        }

        System.debug('getUTMSourceLeadInfo, utmSourceLeadInfo: ' + utmSourceLeadInfo);

        return utmSourceLeadInfo;
    }

    private void injectOrgtoJVLeads(Lead theLead) {

        if ( theLead.IsJVLead__c && theLead.Organization__c == null && FeatureFlags.instance.ff_Inject_Org_to_JV_Leads ) {

            RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PennyMac_Lead');
            RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('AmeriSave_Lead');

            System.debug('injectOrgtoJVLeads, ff_Inject_Org_to_JV_Leads: ' + FeatureFlags.instance.ff_Inject_Org_to_JV_Leads);

            if ( String.isNotBlank(Pennymac_Org_Id) && theLead.RecordTypeId.equals(pmRecordType.getRecordTypeId()) ) {

                theLead.Organization__c = Pennymac_Org_Id;
                theLead.Account__c = Pennymac_Org_Id;
                if ( !accounts_in_context.containsKey(Pennymac_Org_Id) ) accounts_in_context.put(Pennymac_Org_Id, jv_accounts_in_context.get(Pennymac_Org_Id));
            }
            else if ( String.isNotBlank(AmeriSave_Org_Id) && theLead.RecordTypeId.equals(amsRecordType.getRecordTypeId()) ) {

                theLead.Organization__c = AmeriSave_Org_Id;
                theLead.Account__c = AmeriSave_Org_Id;
                if ( !accounts_in_context.containsKey(AmeriSave_Org_Id) ) accounts_in_context.put(AmeriSave_Org_Id, jv_accounts_in_context.get(AmeriSave_Org_Id));
            }

            System.debug('injectOrgtoJVLeads, theLead.Organization__c: ' + theLead.Organization__c);
        }
    }

    private void injectOrgtoHCRLeads(Lead theLead) {

        if ( theLead.Is_HCR_Lead__c == 'Yes' && (FeatureFlags.instance.ff_Inject_Org_to_HCR_Leads || LeadTriggerTest.TESTING_FEATURE_FLAG_FORCE_INJECT_ORG_4_HCR) ) {

            System.debug('injectOrgtoHCRLeads, ff_Inject_Org_to_HCR_Leads: ' + FeatureFlags.instance.ff_Inject_Org_to_HCR_Leads);

            System.debug('injectOrgtoHCRLeads, theLead: ' + theLead);

            RecordTypeInfo b2cRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('B2C_Sales');
            Boolean isB2CLead = theLead.RecordTypeId.equals(b2cRecordType.getRecordTypeId());

            RecordTypeInfo rfRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Risk_Factor');
            Boolean isRiskFactorLead = rfRecordType != null ? theLead.RecordTypeId.equals(rfRecordType.getRecordTypeId()) : false;

            RecordTypeInfo haRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Hippo_Analytics');
            Boolean isHippoAnalyticsLead = haRecordType != null ? theLead.RecordTypeId.equals(haRecordType.getRecordTypeId()) : false;

            if ( isB2CLead && String.isBlank(theLead.Partner_UTM_Source__c) && String.isBlank(theLead.Organization__c) ) {

                if ( String.isNotBlank(LoanDepot_Org_Id) ) {

                    theLead.Organization__c = LoanDepot_Org_Id;
                    theLead.Account__c = LoanDepot_Org_Id;
                    if ( !accounts_in_context.containsKey(LoanDepot_Org_Id) ) accounts_in_context.put(LoanDepot_Org_Id, hcr_accounts_in_context.get(LoanDepot_Org_Id));
                }

            }
            else if ( isRiskFactorLead && String.isBlank(theLead.Organization__c) ) {

                if ( String.isNotBlank(FirstStreet_Org_Id) ) {

                    theLead.Organization__c = FirstStreet_Org_Id;
                    theLead.Account__c = FirstStreet_Org_Id;
                    if ( !accounts_in_context.containsKey(FirstStreet_Org_Id) ) accounts_in_context.put(FirstStreet_Org_Id, hcr_accounts_in_context.get(FirstStreet_Org_Id));
                }
            }
            else if ( isHippoAnalyticsLead && String.isBlank(theLead.Organization__c) ) {

                if ( String.isNotBlank(HippoAnalytics_Org_Id) ) {

                    theLead.Organization__c = HippoAnalytics_Org_Id;
                    theLead.Account__c = HippoAnalytics_Org_Id;
                    if (!accounts_in_context.containsKey(HippoAnalytics_Org_Id)) accounts_in_context.put(HippoAnalytics_Org_Id, hcr_accounts_in_context.get(HippoAnalytics_Org_Id));
                }
            }

            System.debug('injectOrgtoHCRLeads, theLead.Organization__c: ' + theLead.Organization__c);
        }
    }

    private Boolean isHCRLead(Lead theLead) {

        if (String.isNotBlank(theLead.UTM_Source__c) && theLead.UTM_Source__c.equalsIgnoreCase('realtime')) { // SFDC-1476, 1628, 1629

            theLead.Is_HCR_Lead__c = 'Yes';

            injectOrgtoHCRLeads(theLead);

            return true;
        }

        return false;
    }

    private Boolean isLeadCreatedByAgentOrKnownProcess(LeadItem theLead) {

        Boolean res = false;

        System.debug('isLeadCreatedByAgentOrKnownProcess, Trigger.isBefore: ' + Trigger.isBefore);
        System.debug('isLeadCreatedByAgentOrKnownProcess, Trigger.isInsert: ' + Trigger.isInsert);
        System.debug('isLeadCreatedByAgentOrKnownProcess, Trigger.isUpdate: ' + Trigger.isUpdate);

        System.debug('isLeadCreatedByAgentOrKnownProcess, theLead: ' + theLead);

        String lead_created_by_profile = theLead.created_by_user != null ? theLead.created_by_user.Profile.Name : null;
        System.debug('isLeadCreatedByAgentOrKnownProcess, theLead Created By Profile Name: ' + lead_created_by_profile);

        res = String.isNotBlank(lead_created_by_profile) ? !(lead_created_by_profile.containsIgnoreCase('API') || lead_created_by_profile.containsIgnoreCase('Application User')) : true;

        if ( QACockpit.instance.qacp_Application_User_Mode.enabled && !Test.isRunningTest() ) res = false;

        System.debug('isLeadCreatedByAgentOrKnownProcess, res (before Checking Known Processes): ' + res);

        // check if we are in a known/managed/custom process that sets a specific lead owner that we would like to keep
        Id HAS_Price_Increase_Renewals_Q = Utils.getQueueId('HAS_Price_Increase_Renewals');
        res = res || theLead.my_lead.OwnerId.equals(HAS_Price_Increase_Renewals_Q); // SFDC-1473

        System.debug('isLeadCreatedByAgentOrKnownProcess, res (after Checking Known Processes): ' + res);

        map_LeadUniqueId2IsCreatedByAgent.put(theLead.unique_identifier, res);

        System.debug('isLeadCreatedByAgentOrKnownProcess, map_LeadUniqueId2IsCreatedByAgent: ' + map_LeadUniqueId2IsCreatedByAgent);

        return res;
    }

    private void setPennyMacLeadOwner(Lead theLead, LeadRoutingInfo lrInfo) { // SFDC-1752

        System.debug('setPennyMacLeadOwner, theLead: ' + theLead);

        RecordTypeInfo pmRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PennyMac_Lead');
        Boolean isPennyMacRecordType = theLead.RecordTypeId.equals(pmRecordType.getRecordTypeId());
        System.debug('setPennyMacLeadOwner, isPennyMacRecordType: ' + isPennyMacRecordType);

        Boolean isRealtimeLead = String.isNotBlank(theLead.UTM_Source__c) && theLead.UTM_Source__c.equalsIgnoreCase('realtime');
        System.debug('setPennyMacLeadOwner, isRealtimeLead: ' + isRealtimeLead);

        Boolean isLeadScoreEqualOrGreater5 = String.isNotBlank(theLead.Lead_Score__c) && Integer.valueOf(theLead.Lead_Score__c) >= 5;
        System.debug('setPennyMacLeadOwner, isLeadScoreEqualOrGreater5: ' + isLeadScoreEqualOrGreater5);

        if ( isPennyMacRecordType && isRealtimeLead &&
             (String.isNotBlank(theLead.Partner_UTM_Source__c) && theLead.Partner_UTM_Source__c.equalsIgnoreCase('New Purchase')) &&
             (String.isNotBlank(theLead.Last_Page_Visited__c) && theLead.Last_Page_Visited__c.equalsIgnoreCase('Clicked Link')) ) {

            theLead.Lead_Source__c = 'PMIS HCR New Purchase Clicked on Link';
            setJVLead(theLead, pmRecordType, PennyMac_HCR_New_Purchase, lrInfo);
            System.debug('setPennyMacLeadOwner, set Owner to PennyMac_HCR_New_Purchase: ' + PennyMac_HCR_New_Purchase);
        }
        else if ( isPennyMacRecordType && isRealtimeLead && String.isBlank(theLead.Partner_UTM_Source__c) &&
                  (String.isNotBlank(theLead.Last_Page_Visited__c) && theLead.Last_Page_Visited__c.equalsIgnoreCase('Clicked Link')) ) {

            theLead.Lead_Source__c = 'PMIS HCR Clicked on Link';
            setJVLead(theLead, pmRecordType, PMIS_HCR_Clicked_on_Link, lrInfo);
            System.debug('setPennyMacLeadOwner, set Owner to PMIS_HCR_Clicked_on_Link: ' + PMIS_HCR_Clicked_on_Link);
        }
        else if ( isPennyMacRecordType && isRealtimeLead &&
                  (String.isNotBlank(theLead.Partner_UTM_Source__c) && theLead.Partner_UTM_Source__c.equalsIgnoreCase('New Purchase')) &&
                  (String.isNotBlank(theLead.Last_Page_Visited__c) && theLead.Last_Page_Visited__c.equalsIgnoreCase('Reached Prelim Quote')) ) {

            theLead.Lead_Source__c = 'PMIS HCR New Purchase Reached Prelim Quote';
            setJVLead(theLead, pmRecordType, PMIS_HCR_N_Purchase_Reached_Prelim_Quote, lrInfo);
            System.debug('setPennyMacLeadOwner, set Owner to PMIS_HCR_N_Purchase_Reached_Prelim_Quote: ' + PMIS_HCR_N_Purchase_Reached_Prelim_Quote);
        }
        else if ( isPennyMacRecordType && isLeadScoreEqualOrGreater5 ) {

            theLead.Lead_Source__c = 'PMIS Hippo Leads 1';
            setJVLead(theLead, pmRecordType, PMIS_Hippo_Leads_1, lrInfo);
            System.debug('setPennyMacLeadOwner, set Owner to PMIS_Hippo_Leads_1: ' + PMIS_Hippo_Leads_1);
        }
        else if ( isPennyMacRecordType && isRealtimeLead && String.isBlank(theLead.Partner_UTM_Source__c) &&
                  (String.isNotBlank(theLead.Last_Page_Visited__c) && theLead.Last_Page_Visited__c.equalsIgnoreCase('Reached Prelim Quote')) ) {

            theLead.Lead_Source__c = 'PMIS HCR Reached Prelim Quote';
            setJVLead(theLead, pmRecordType, PMIS_HCR_Reached_Prelim_Quote, lrInfo);
            System.debug('setPennyMacLeadOwner, set Owner to PMIS_HCR_Reached_Prelim_Quote: ' + PMIS_HCR_Reached_Prelim_Quote);
        }
        else if ( isPennyMacRecordType && !isLeadScoreEqualOrGreater5 ) {

            theLead.Lead_Source__c = 'PMIS Hippo Leads 2';
            setJVLead(theLead, pmRecordType, PMIS_Hippo_Leads_2, lrInfo);
            System.debug('setPennyMacLeadOwner, set Owner to PMIS_Hippo_Leads_2: ' + PMIS_Hippo_Leads_2);
        }
    }

    private void setAmerisaveLeadOwner(Lead theLead, LeadRoutingInfo lrInfo) { // SFDC-1848

        System.debug('setAmerisaveLeadOwner, theLead: ' + theLead);

        RecordTypeInfo amsRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('AmeriSave_Lead');
        Boolean isAmerisaveRecordType = theLead.RecordTypeId.equals(amsRecordType.getRecordTypeId());
        System.debug('setAmerisaveLeadOwner, isAmerisaveRecordType: ' + isAmerisaveRecordType);

        Boolean isRealtimeLead = String.isNotBlank(theLead.UTM_Source__c) && theLead.UTM_Source__c.equalsIgnoreCase('realtime');
        System.debug('setAmerisaveLeadOwner, isRealtimeLead: ' + isRealtimeLead);

        if ( isAmerisaveRecordType && isRealtimeLead && String.isBlank(theLead.Partner_UTM_Source__c) &&
             (String.isNotBlank(theLead.Last_Page_Visited__c) && theLead.Last_Page_Visited__c.equalsIgnoreCase('Clicked Link')) ) {

            theLead.Lead_Source__c = 'AIA HCR Clicked on Link';
            setJVLead(theLead, amsRecordType, AIA_HCR_Clicked_on_Link, lrInfo);
            System.debug('setAmerisaveLeadOwner, set Owner to AIA_HCR_Clicked_on_Link: ' + AIA_HCR_Clicked_on_Link);
        }
        else if ( isAmerisaveRecordType && isRealtimeLead &&
                  (String.isNotBlank(theLead.Last_Page_Visited__c) && theLead.Last_Page_Visited__c.equalsIgnoreCase('Reached Prelim Quote')) ) {

            theLead.Lead_Source__c = 'AIA HCR Reached Prelim Quote';
            setJVLead(theLead, amsRecordType, AIA_HCR_Reached_Prelim_Quote, lrInfo);
            System.debug('setAmerisaveLeadOwner, set Owner to AIA_HCR_Reached_Prelim_Quote: ' + AIA_HCR_Reached_Prelim_Quote);
        }
        else if ( isAmerisaveRecordType && String.isBlank(theLead.Partner_UTM_Source__c) && String.isBlank(theLead.Last_Page_Visited__c) ) {

            theLead.Lead_Source__c = 'AIA Leads';
            setJVLead(theLead, amsRecordType, AIA_Leads, lrInfo);
            System.debug('setAmerisaveLeadOwner, set Owner to AIA_Leads: ' + AIA_Leads);
        }
    }

    private void distributeUpdates2NonDuplicateLeads() {

        if ( Trigger.isAfter && Trigger.isUpdate ) {

            if ( LeadTriggerHandler.SKIP_DISTRIBUTED_UPDATE ) {

                return;
            }

            Map<Id, Lead> map_LeadsInContext = new Map<Id, Lead>([SELECT Id, Name, Status, Disqualified_Reason__c FROM Lead WHERE Status = 'Cancelled' AND Disqualified_Reason__c = 'Duplicate' AND  Id IN :Trigger.newMap.keySet()]);
            System.debug('distributeUpdates2NonDuplicateLeads, map_LeadsInContext: ' + map_LeadsInContext);

            List<Duplicate_Lead_Record__c> lst_DuplicateLeadRecords = [SELECT Id, ParentId__c, DuplicateId__c FROM Duplicate_Lead_Record__c WHERE DuplicateId__c IN :map_LeadsInContext.keySet() AND ParentId__r.Status != 'Cancelled'];
            System.debug('distributeUpdates2NonDuplicateLeads, lst_DuplicateLeadRecords: ' + lst_DuplicateLeadRecords);

            List<Lead> lst_Leads2Update = new List<Lead>();

            for (Duplicate_Lead_Record__c duplicateLeadRecord : lst_DuplicateLeadRecords) {

                Lead lead2Update = (Lead)Trigger.newMap.get(duplicateLeadRecord.DuplicateId__c); // get the cancelled-duplicated updated lead
                System.debug('distributeUpdates2NonDuplicateLeads, lead2Update: ' + lead2Update);
                Set<String> changedFields = Utils.GetChangedFields(Trigger.oldMap.get(lead2Update.Id), lead2Update);
                System.debug('distributeUpdates2NonDuplicateLeads, changedFields: ' + changedFields);
                Lead lead2UpdateClone = new Lead(Id = duplicateLeadRecord.ParentId__c); // modify the udpated lead id to the parent of the duplicate updated lead id such that the same update will be applied on the parent non-duplicate lead
                for (String field : changedFields) {

                    if ( Schema.SObjectType.Lead.fields.getMap().get(field).getDescribe().isUpdateable() ) {
                        lead2UpdateClone.put(field, lead2Update.get(field));
                    }
                }
                System.debug('distributeUpdates2NonDuplicateLeads, lead2UpdateClone: ' + lead2UpdateClone);
                lst_Leads2Update.add(lead2UpdateClone);
            }

            System.debug('distributeUpdates2NonDuplicateLeads, lst_Leads2Update: ' + lst_Leads2Update);

            if ( lst_Leads2Update.size() > 0 ) {

                LeadTriggerHandler.SKIP_DISTRIBUTED_UPDATE = true;
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.allowSave = true;
                dml.DuplicateRuleHeader.runAsCurrentUser = true;
                Database.SaveResult [] sr = Database.update(lst_Leads2Update, dml);
                System.debug('lst_Leads2Update SaveResult: ' + sr);
                LeadTriggerHandler.SKIP_DISTRIBUTED_UPDATE = false;
            }
        }
    }
}