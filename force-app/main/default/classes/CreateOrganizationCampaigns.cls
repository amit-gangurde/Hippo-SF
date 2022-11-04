public with sharing class CreateOrganizationCampaigns implements Queueable {

    /*
    Description for the purpose of List<CreateOrganizationCampaigns>

    This transaction only gets active campaigns and can do the following two actions:

    1. Create new organization campaigns to newly created campaigns using chained queueable
    2. Update existing organization campaigns if they are already active for a specific campaign. is is updating them just by setting their Active value to true

    However, internally in organization campaign trigger, a recalculate of start/end date for agent campaign may be required based on campaign duration that might get updated as well.
    Therefore, if an UPDATE DML is initiated for existing organization campaign, it will enqueue an AgentCampaignStateManagement to work on related agent campaigns, so it won't be possible
    to keep handling additional chained CreateOrganizationCampaigns so they will be kept here in this array and will be chained to AgentCampaignStateManagement (See OrganizationCampaignTriggerHandler)
     */
    public static List<CreateOrganizationCampaigns> PENDING_QUEUEABLE_CreateOrganizationCampaigns = new List<CreateOrganizationCampaigns>();

    private Map<Id, Campaign> map_CampaignsByIds; // map of Campaigns in context
    private List<Campaign> lst_Campaigns; // list of Campaigns in context (We need the list in addition to the map to preserve the order of the query results set)
    private Map<Id, Boolean> map_ChangedDurationCampaignIds; // map of Campaigns in context with changed in duration
    private Map<Id, Account> map_NewAccountIds; // map of Accounts in context (if we came here from Account trigger)
    private List<Account> lst_Organizations; // list of Accounts in context (We need the list in addition to the map to preserve the order of the query results set)
    private Integer batch_size;
    private Id last_Processed_Organization_Index; // the Id of the last processed Account (required for the split of queueable to child queueables)
    private Id last_Processed_Campaign_Index; // the Id of the last processed Campaign (required for the split of queueable to child queueables)
    private Map<String, Organization_Campaign__c> map_ExistingOrgCampaignsByExternalId; // map of already existing Organization Campaigns so we won't recreate them
    private Boolean bSourceIsAccountTrigger; // indication if the transaction started from the Account trigger
    private Boolean bSourceIsContactTrigger; // indication if the transaction started from the Contact trigger
    private Map<Id, Campaign> map_Restricted2StateCampaigns; // map of state restricted Campaigns in context (only used when a Contact is created, SFDC-509)
    private Map<Id, Campaign> map_NonRestricted2StateCampaigns; // map of non-restricted state Campaigns in context (only used when a Contact is created, SFDC-509)
    private Map<Id, Campaign> map_ContactId2Campaign; // map between Contact id to a matching Campaign (only used when a Contact is created, SFDC-509)
    private map<Id, List<Agent_Campaign__c>> map_ContactId2AgentCampaigns; // map between Contact id to Agent Campaigns (With SFDC-509 there should be one agent campaign per Contact but system state prior to SFDC-509 could have multiple)
    private Map<Id, Map<String, License__c>> map_LicensesByContactId;

    /*
    this ctor is used when the process is initiated from Campaign trigger
     */
    public CreateOrganizationCampaigns(Map<Id, Campaign> map_CampaignsByIds, Map<Id, Boolean> map_ChangedDurationCampaignIds) {

        System.debug('ctor 1');
        batch_size = Utils.getHippoSettings('Producer Incentive Batch Size') != null ? Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size')) : 200;
        System.debug('batch_size: ' + batch_size);

        this.map_CampaignsByIds = map_CampaignsByIds;
        this.map_ChangedDurationCampaignIds = map_ChangedDurationCampaignIds;

        initialize();

        /* Replaced by the call to initialize() above

        this.lst_Campaigns = map_CampaignsByIds.values();
        this.map_NewAccountIds = null;
        this.lst_Organizations = Database.query('Select Id, Name, (select Id, Name from contacts) From Account Where RecordType.DeveloperName = \'IndustriesBusiness\' Order By Id ASC LIMIT ' + batch_size);
        */

        this.last_Processed_Organization_Index = null;
        this.last_Processed_Campaign_Index = null;
        this.bSourceIsAccountTrigger = false;
        this.bSourceIsContactTrigger = false;
        this.map_Restricted2StateCampaigns = null;
        this.map_NonRestricted2StateCampaigns = null;
        fetchExistingOrgCampaigns();
    }

    /*
    this ctor is used internally for chaining
     */
    public CreateOrganizationCampaigns(Map<Id, Campaign> map_CampaignsByIds, Id last_Processed_Organization_Index, Map<Id, Boolean> map_ChangedDurationCampaignIds) {

        System.debug('ctor 2');
        this.map_CampaignsByIds = map_CampaignsByIds;
        this.lst_Campaigns = map_CampaignsByIds.values();
        this.map_ChangedDurationCampaignIds = map_ChangedDurationCampaignIds;
        batch_size = Utils.getHippoSettings('Producer Incentive Batch Size') != null ? Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size')) : 200;
        System.debug('batch_size: ' + batch_size);
        this.last_Processed_Organization_Index = last_Processed_Organization_Index;
        this.last_Processed_Campaign_Index = null;
        this.map_NewAccountIds = null;
        this.lst_Organizations = Database.query('Select Id, Name, (select Id, Name from contacts) From Account Where RecordType.DeveloperName = \'IndustriesBusiness\' AND Id >: this.last_Processed_Organization_Index Order By Id ASC LIMIT ' + batch_size);
        this.bSourceIsAccountTrigger = false;
        this.bSourceIsContactTrigger = false;
        this.map_Restricted2StateCampaigns = null;
        this.map_NonRestricted2StateCampaigns = null;
        fetchExistingOrgCampaigns();
    }

    /*
    this ctor is used when the process is initiated from Account trigger
     */
    public CreateOrganizationCampaigns(Map<Id, Account> map_NewAccountIds, Id last_Processed_Campaign_Index, Boolean bSourceIsAccountTrigger, Boolean bSourceIsContactTrigger) {

        System.debug('ctor 3');
        batch_size = Utils.getHippoSettings('Producer Incentive Batch Size') != null ? Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size')) : 200;
        System.debug('batch_size: ' + batch_size);
        this.last_Processed_Campaign_Index = last_Processed_Campaign_Index;
        System.debug('last_Processed_Campaign_Index: ' + last_Processed_Campaign_Index);
        String query = 'Select Id, IsActive, CreatedDate, Duration__c From Campaign Where RecordType.DeveloperName = \'Producer_Incentive_Campaign\' ' + (String.isNotBlank(this.last_Processed_Campaign_Index) ? 'AND Id >: this.last_Processed_Campaign_Index' : '') + ' Order By Id ASC LIMIT ' + batch_size;
        this.lst_Campaigns = Database.query(query);
        System.debug('lst_Campaigns: ' + lst_Campaigns);
        this.map_CampaignsByIds = new Map<Id, Campaign>(this.lst_Campaigns);
        this.map_ChangedDurationCampaignIds = null;
        this.map_NewAccountIds = map_NewAccountIds;
        this.lst_Organizations = map_NewAccountIds.values();
        this.last_Processed_Organization_Index = null;
        this.bSourceIsAccountTrigger = bSourceIsAccountTrigger;
        this.bSourceIsContactTrigger = bSourceIsContactTrigger;
        this.map_Restricted2StateCampaigns = null;
        this.map_NonRestricted2StateCampaigns = null;
        fetchExistingOrgCampaigns();
    }

    /*
    this ctor is used when the process is initiated from Contact and License__c triggers
     */
    public CreateOrganizationCampaigns(Map<Id, Campaign> map_Restricted2StateCampaigns, Map<Id, Campaign> map_NonRestricted2StateCampaigns, Map<Id, Account> map_NewAccountIds, Map<Id, Map<String, License__c>> map_LicensesByContactId) {

        System.debug('ctor 4');
        batch_size = Utils.getHippoSettings('Producer Incentive Batch Size') != null ? Integer.valueOf(Utils.getHippoSettings('Producer Incentive Batch Size')) : 200;
        System.debug('batch_size: ' + batch_size);
        this.last_Processed_Campaign_Index = null;
        System.debug('last_Processed_Campaign_Index: ' + last_Processed_Campaign_Index);
        this.map_Restricted2StateCampaigns = map_Restricted2StateCampaigns;
        System.debug('map_Restricted2StateCampaigns: ' + map_Restricted2StateCampaigns);
        this.map_NonRestricted2StateCampaigns = map_NonRestricted2StateCampaigns;
        System.debug('map_NonRestricted2StateCampaigns: ' + map_NonRestricted2StateCampaigns);
        this.map_CampaignsByIds = matchContact2Campaign(map_LicensesByContactId);
        this.lst_Campaigns = map_CampaignsByIds?.values();
        this.map_ChangedDurationCampaignIds = null;
        this.map_NewAccountIds = map_NewAccountIds;
        this.lst_Organizations = map_NewAccountIds.values();
        this.bSourceIsAccountTrigger = false;
        this.bSourceIsContactTrigger = true;
        fetchExistingOrgCampaigns();
    }

    /*
    SFDC-509 / 584
     */
    private void initialize() {

        system.debug('Inside initialize...');
        /*
        We come here from ctor 1, meaning from Campaign Trigger, therefore we take all campaigns in context and split to restricted vs non restricted
         */
        if ( null != this.map_CampaignsByIds && this.map_CampaignsByIds.size() > 0 ) {

            this.map_Restricted2StateCampaigns = CampaignTriggerHandler.getOrderedRestricted2StateCampaigns(this.map_CampaignsByIds.keySet());
            System.debug('initialize map_Restricted2StateCampaigns: ' + this.map_Restricted2StateCampaigns);
            this.map_NonRestricted2StateCampaigns = CampaignTriggerHandler.getOrderedNonRestricted2StateCampaign(this.map_CampaignsByIds.keySet());
            System.debug('initialize map_NonRestricted2StateCampaigns: ' + this.map_NonRestricted2StateCampaigns);

            this.map_NewAccountIds = null;
            this.lst_Organizations = Database.query('Select Id, Name, (select Id, Name from contacts) From Account Where RecordType.DeveloperName = \'IndustriesBusiness\' Order By Id ASC LIMIT ' + batch_size);
            System.debug('initialize lst_Organizations: ' + this.lst_Organizations);

            Set<Id> contactsInContext = getContactsInContext();
            //Map<Id, Map<String, License__c>> map_LicensesByContactId = ContactTriggerHandler.getContactsLicensesByState(contactsInContext);
            this.map_LicensesByContactId = ContactTriggerHandler.getContactsLicensesByState(contactsInContext);
            System.debug('initialize map_LicensesByContactId: ' + this.map_LicensesByContactId);
            Map<Id, Campaign> results = matchContact2Campaign(this.map_LicensesByContactId);
            if ( results.size() > 0 ) {
                this.map_CampaignsByIds = results;
                System.debug('re-initialize map_CampaignsByIds: ' + this.map_CampaignsByIds);
            }
            else {
                // there are no matched campaigns as the context was a restricted campaign without any matching contact/license
                // so, just continue with the original input campaigns to create their matching OC records
            }
            this.lst_Campaigns = map_CampaignsByIds?.values();
            System.debug('initialize lst_Campaigns: ' + this.lst_Campaigns);
        }
    }

    /*
    SFDC-509
     */
    private Map<Id, Campaign> matchContact2Campaign(Map<Id, Map<String, License__c>> map_LicensesByContactId) {

        Map<Id, Campaign> results = new Map<Id, Campaign>(); // return list of Campaigns in context (SFDC-509)

        map_ContactId2Campaign = new Map<Id, Campaign>();

        try {

            // go over all contacts in context
            for ( Id contactId : map_LicensesByContactId.keySet() ) {

                System.debug('CreateOrganizationCampaigns: map_LicensesByContactId::ContactId ' + contactId);

                if ( map_ContactId2Campaign.containsKey(contactId) ) continue; // allow only one Campaign per Contact (SFDC-509)

                System.debug('CreateOrganizationCampaigns: matchContact2Campaign::map_Restricted2StateCampaigns ' + map_Restricted2StateCampaigns);

                // 1. go over state restricted campaigns as first priority to match a Contact (by its licenses)
                for ( Id cId : map_Restricted2StateCampaigns.keySet() ) {

                    System.debug('map_ContactId2Campaign Current State: ' + map_ContactId2Campaign);

                    String campaign_state = map_Restricted2StateCampaigns.get(cId).State__c;

                    System.debug('campaign_state: ' + campaign_state);

                    Map<String, License__c> map_State2License =  map_LicensesByContactId.get(contactId);

                    System.debug('map_State2License for Contact Id ' + contactId + ', ' + map_State2License);

                    for ( String state_license : map_State2License.keySet() ) {

                        if (  String.isNotBlank(campaign_state) ) {

                            if ( state_license.equalsIgnoreCase(campaign_state) ) {

                                map_ContactId2Campaign.put(contactId, map_Restricted2StateCampaigns.get(cId));
                                results.put(map_Restricted2StateCampaigns.get(cId).Id, map_Restricted2StateCampaigns.get(cId));
                                break;
                            }
                        }
                    }
                }

                // 2. if the Contact hasn't been matched to any state restricted Campaign, pair with a non restricted state Campaign
                Campaign default_campaign = getContactDefaultCampaign(contactId);
                if (null != default_campaign) results.put(default_campaign.Id, default_campaign);
            }

            System.debug('map_ContactId2Campaign: ' + map_ContactId2Campaign);
        }
        catch (Exception ex) {

            System.debug('Exception from populateFinalCampaigns execution: ' + ex.getMessage() + ex.getStackTraceString());
        }

        System.debug('results: ' + results);

        return results;
    }

    private Campaign getContactDefaultCampaign(Id contactId) {

        // 2. if the Contact hasn't been matched to any state restricted Campaign, pair with a non restricted state Campaign
        if ( !map_ContactId2Campaign.containsKey(contactId) ) {

            // there could be only one Campaign as we sort by reward amount and created date DESC with LIMIT 1 (See ContactTriggerHandler)
            if ( map_NonRestricted2StateCampaigns.size() == 1 ) {

                map_ContactId2Campaign.put(contactId, map_NonRestricted2StateCampaigns.values()[0]);
                return map_NonRestricted2StateCampaigns.values()[0];
            }
            else { // there are no non-restricted campaigns COMEBACK!!!!

                System.debug('there are no non-restricted campaigns COMEBACK!!!!');
            }
        }

        return null;
    }

    private void fetchExistingOrgCampaigns() {

        try {

            map_ExistingOrgCampaignsByExternalId = new Map<String, Organization_Campaign__c>();

            Map<Id, Organization_Campaign__c> map_ExistingOrgCampaigns = new Map<Id, Organization_Campaign__c>();

            map_ExistingOrgCampaigns = new Map<Id, Organization_Campaign__c>([Select Id, MyExtID__c, Active__c, Campaign__c, Campaign__r.Duration__c, Campaign__r.CreatedDate, Organization__c From Organization_Campaign__c Where Campaign__c IN: this.map_CampaignsByIds.keySet()]);

            for (Organization_Campaign__c oc : map_ExistingOrgCampaigns.values()) {

                map_ExistingOrgCampaignsByExternalId.put(oc.MyExtID__c, oc);
            }

            System.debug('map_ExistingOrgCampaignsByExternalId: ' + map_ExistingOrgCampaignsByExternalId);

            // collect existing agent campaigns for contacts in context (per SFDC-509 there could be only one Agent_Campaign__c per Contact)
            map_ContactId2AgentCampaigns = new Map<Id, List<Agent_Campaign__c>>();

            Set<Id> contactsInContext = getContactsInContext();

            System.debug('contactsInContext: ' + contactsInContext);

            List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Active__c, Agent__c FROM Agent_Campaign__c WHERE Active__c = TRUE AND Agent__c IN: contactsInContext];

            System.debug('lst_AgentCampaigns (Existing): ' + lst_AgentCampaigns);

            if ( lst_AgentCampaigns.size() > 0 ) {

                for (Agent_Campaign__c ac : lst_AgentCampaigns) {

                    if ( !map_ContactId2AgentCampaigns.containsKey(ac.Agent__c) ) {

                        map_ContactId2AgentCampaigns.put(ac.Agent__c, new List<Agent_Campaign__c>{ac});
                    }
                    else {

                        map_ContactId2AgentCampaigns.get(ac.Agent__c).add(ac);
                    }
                }
            }

            System.debug('map_ContactId2AgentCampaigns: ' + map_ContactId2AgentCampaigns);

        }
        catch (Exception ex) {

            System.debug('Exception from fetchExistingOrgCampaigns execution: ' + ex.getMessage() + ex.getStackTraceString());
        }
    }

    private Set<Id> getContactsInContext() {

        Set<Id> contactsInContext = new Set<Id>();

        if ( null != lst_Organizations && lst_Organizations.size() > 0 ) {

            for (Account acc : lst_Organizations) {

                for (Contact con : acc.contacts) {

                    contactsInContext.add(con.Id);
                }
            }
        }

        return contactsInContext;
    }

    public void execute(QueueableContext context) {

        try {

            System.debug('execute, map_CampaignsByIds: ' + map_CampaignsByIds);

            if ( map_CampaignsByIds.isEmpty() ) return;

            // Salesforce treats each sObject switch in a List as a new type (even if same types are used) and allows up to 10 switches!
            // So, we collect all parents (same type) to one list and all childs (same type, but other) to a different list. Then we combine them to one list and insert to the database
            List<SObject> lst_ParentObjects = new List<SObject>(); // list of parent objects to create (Organization Campaigns)
            List<SObject> lst_ChildObjects = new List<SObject>();  // list of child objects to create (Agent Campaigns)

            List<Agent_Campaign__c> lst_AgentCampaigns = new List<Agent_Campaign__c>();  // list of Agent Campaign objects to create when coming from Contact trigger

            List<Organization_Campaign__c> lst_oOrganizationCampaigns2Reactivate = new List<Organization_Campaign__c>();

            System.debug('lst_Organizations count: ' + lst_Organizations.size());
            System.debug('lst_Organizations: ' + lst_Organizations);

            for (Account acc : lst_Organizations) {

                for (Id cId : map_CampaignsByIds.keySet()) {

                    //Blob aes = Crypto.generateAesKey(128);
                    //String hex = EncodingUtil.convertToHex(aes);
                    //System.debug('uuid is ' + hex);

                    String composite_key = String.valueOf(acc.Id) + String.valueOf(cId);
                    System.debug('Organization in context: ' + acc.Name);
                    System.debug('Organization contacts count: ' + acc.contacts.size());
                    System.debug('Organization contacts: ' + acc.contacts);

                    System.debug('composite_key is ' + composite_key);

                    if (!map_ExistingOrgCampaignsByExternalId.containsKey(composite_key)) {

                        system.debug('Creating new Organization Campaign and related Agent Campaigns');

                        Organization_Campaign__c ocReference = new Organization_Campaign__c(MyExtID__c = composite_key);

                        Organization_Campaign__c ocParent = new Organization_Campaign__c();
                        ocParent.Active__c = map_CampaignsByIds.get(cId).IsActive;
                        ocParent.Campaign__c = cId;
                        ocParent.Organization__c = acc.Id;
                        ocParent.MyExtID__c = composite_key;

                        lst_ParentObjects.add(ocParent); // insert the parent

                        for (Contact con : acc.contacts) {

                            // SFDC-509: Check if Contact already have an active Campaign
                            if ( (isContactAllowed4Campaign(con, map_CampaignsByIds.get(cId)) && !map_ContactId2AgentCampaigns.containsKey(con.Id)) || !FeatureFlags.instance.ff_One_Campaign_per_Producer ) {

                                System.debug('Preparing Agent Campaigns...');
                                System.debug('Contact in context: ' + con);
                                System.debug('Contact organzation: ' + acc.Name);

                                Agent_Campaign__c ac = prepareAgentCampaign(cId, ocReference, con);

                                /*
                                Agent_Campaign__c ac = new Agent_Campaign__c();
                                ac.Organization_Campaign__r = ocReference;
                                ac.Agent__c = con.Id;
                                ac.Active__c = true;
                                ac.Start_Date__c = map_CampaignsByIds.get(cId).CreatedDate.date(); //.addDays(1).date();
                                ac.End_Date__c = String.isNotBlank(String.valueOf(map_CampaignsByIds.get(cId).Duration__c)) ? ac.Start_Date__c.addDays(Integer.valueOf(map_CampaignsByIds.get(cId).Duration__c)) : ac.End_Date__c;
                                */

                                // insert child so both will get created together (based on the external id of the parent)
                                lst_ChildObjects.add(ac);
                            }
                        }
                    }
                    else if ( bSourceIsContactTrigger ) {

                        system.debug('Creating new Agent Campaigns (coming from Contact Trigger)');

                        Organization_Campaign__c ocReference = map_ExistingOrgCampaignsByExternalId.get(composite_key);

                        for (Contact con : acc.contacts) {

                            if ( !map_ContactId2AgentCampaigns.containsKey(con.Id) ) {

                                Agent_Campaign__c ac = prepareAgentCampaign(cId, ocReference, con);
                                lst_AgentCampaigns.add(ac);
                            }
                        }

                    }
                    else {

                        Organization_Campaign__c oc = map_ExistingOrgCampaignsByExternalId.get(composite_key);
                        if ( !oc.Active__c ) { // the assumption is that only active campaigns gets to this transaction so if the organization campaign is already active, there is nothing more to do
                            oc.Active__c = true;
                            lst_oOrganizationCampaigns2Reactivate.add(oc);
                        }
                        else if ( this.map_ChangedDurationCampaignIds.containsKey(cId) ) { // add the organization campaigns to the list to "Reactivate" so it's related agent campaigns will get recalculated
                            lst_oOrganizationCampaigns2Reactivate.add(oc);
                        }
                    }
                }
            }

            if (lst_ParentObjects.size() > 0) { // create new Organization Campaigns with Agent Campaigns OR just new Agent Campaigns (for newly added Contacts)

                // The following line as been comment out as we are getting: System.TypeException: Cannot have more than 10 chunks in a single operation. Please rearrange the data to reduce chunking.
                //lst_ParentObjects.addAll(lst_ChildObjects); // combine parents and children to one DML

                // Create the parent/child records
                Database.SaveResult[] results1 = Database.insert(lst_ParentObjects);
                System.debug('--> Created ' + lst_ParentObjects.size() + ' new Organization Campaign records');
                Utils.debugSaveResults(results1);
                Database.SaveResult[] results2 = Database.insert(lst_ChildObjects);
                System.debug('--> Created ' + lst_ChildObjects.size() + ' new Agent Campaigns records');
                Utils.debugSaveResults(results2);
            }

            if (lst_AgentCampaigns.size() > 0) { // create new Agent Campaigns records (for newly added Contacts)

                // Create the parent/child records
                Database.SaveResult[] results = Database.insert(lst_AgentCampaigns);
                System.debug('--> Created ' + lst_AgentCampaigns.size() + ' new Agent Campaigns records');
                Utils.debugSaveResults(results);
            }

            if (lst_oOrganizationCampaigns2Reactivate.size() > 0) { // reactivate existing organization campaigns

                System.debug('lst_oOrganizationCampaigns2Reactivate: ' + lst_oOrganizationCampaigns2Reactivate);

                //Database.SaveResult[] results = Database.update(lst_oOrganizationCampaigns2Reactivate);

                if ( (!bSourceIsAccountTrigger && lst_Organizations.size() > 0 && lst_Organizations.size() == batch_size) ||   // there might be more accounts if we came from campaign trigger context
                     (bSourceIsAccountTrigger && map_CampaignsByIds.size() > 0 && map_CampaignsByIds.size() == batch_size) ) { // there might be more campaigns if we came from account trigger context

                    CreateOrganizationCampaigns coc = getNextQueueable();
                    // the AfterUpdate trigger on Organization_Campaign__c may kick off a queueable (AgentCampaignStateManagement). so the next CreateOrganizationCampaigns is parked and will continue
                    // once all AgentCampaignStateManagement queueable are completed (See code in AgentCampaignStateManagement)
                    if ( !Test.isRunningTest() ) {

                        CreateOrganizationCampaigns.PENDING_QUEUEABLE_CreateOrganizationCampaigns.add(coc);
                    }
                    else {

                        System.debug('Reexecute CreateOrganizationCampaigns');
                        coc.execute(null);
                    }
                }

                // Update existing records
                Database.SaveResult[] results = Database.update(lst_oOrganizationCampaigns2Reactivate);
                System.debug('--> Reactivated existing Organization Campaign records');
                Utils.debugSaveResults(results);
            }
            else {

                System.debug('bSourceIsAccountTrigger: ' + bSourceIsAccountTrigger);
                System.debug('bSourceIsContactTrigger: ' + bSourceIsContactTrigger);

                if ( ((!bSourceIsAccountTrigger && !bSourceIsContactTrigger) && lst_Organizations.size() > 0 && lst_Organizations.size() == batch_size) ||   // there might be more accounts if we came from campaign trigger context
                     ((bSourceIsAccountTrigger || bSourceIsContactTrigger) && map_CampaignsByIds.size() > 0 && map_CampaignsByIds.size() == batch_size) ) { // there might be more campaigns if we came from account trigger context

                    CreateOrganizationCampaigns coc = getNextQueueable();
                    if ( !Test.isRunningTest() ) {

                        Id jobId = System.enqueueJob(coc);
                        System.debug('CreateOrganizationCampaigns jobId: ' + jobId);
                    }
                    else {

                        System.debug('Reexecute CreateOrganizationCampaigns');
                        coc.execute(null);
                    }
                }
            }
        }
        catch(Exception ex) {

            System.debug('Exception from CreateOrganizationCampaigns execution: ' + ex.getMessage() + ex.getStackTraceString());
        }
    }

    private CreateOrganizationCampaigns getNextQueueable() {

        if ( !bSourceIsAccountTrigger && !bSourceIsContactTrigger ) {

            return new CreateOrganizationCampaigns(map_CampaignsByIds, lst_Organizations[batch_size - 1].Id, this.map_ChangedDurationCampaignIds);
        }
        else {

            return new CreateOrganizationCampaigns(map_NewAccountIds, lst_Campaigns[batch_size - 1].Id, this.bSourceIsAccountTrigger, this.bSourceIsContactTrigger);
        }
    }

    private Agent_Campaign__c prepareAgentCampaign(Id cId, Organization_Campaign__c oc, Contact con) {

        Agent_Campaign__c ac = new Agent_Campaign__c();

        if ( String.isBlank(oc.Id) ) {// creating new organization campaign with new agent campaign
            ac.Organization_Campaign__r = oc;
            ac.Active__c = map_CampaignsByIds.get(cId).IsActive; // the organization campaign is also created based on this value so there is a match
        }
        else { // create new agent campaign for an existing organization campaign (coming from Contact trigger)
            ac.Organization_Campaign__c = oc.Id;
            ac.Active__c = oc.Active__c;
        }

        ac.Agent__c = con.Id;
        ac.Start_Date__c = System.now().date(); //map_CampaignsByIds.get(cId).CreatedDate.date(); //.addDays(1).date();
        ac.End_Date__c = String.isNotBlank(String.valueOf(map_CampaignsByIds.get(cId).Duration__c)) ? ac.Start_Date__c.addDays(Integer.valueOf(map_CampaignsByIds.get(cId).Duration__c)) : ac.End_Date__c;

        system.debug('ac: ' + ac);

        if ( ac.Active__c ) {

            if ( !map_ContactId2AgentCampaigns.containsKey(ac.Agent__c) ) {

                map_ContactId2AgentCampaigns.put(ac.Agent__c, new List<Agent_Campaign__c>{ac});
            }
            else {

                map_ContactId2AgentCampaigns.get(ac.Agent__c).add(ac);
            }
        }

        return ac;
    }

    private Boolean isContactAllowed4Campaign(Contact con, Campaign cmp) {

        Boolean allow = true;

        if ( cmp.Restricted_To_State__c ) {

            if (null != map_LicensesByContactId && map_LicensesByContactId.containsKey(con.Id)) {

                String campaign_state = cmp.State__c;

                Map<String, License__c> map_StateCode2License = map_LicensesByContactId.get(con.Id);

                if ( !map_StateCode2License.containsKey(campaign_state) ) allow = false;
            }
        }

        return allow;
    }
}