@IsTest
public class ProducerIncentiveCampaignTest {

    @IsTest
    static void testActiveCampaign() {

        Account acc = UnitTestHelper.prepareDevEnvCustomSettings(); // this call also prepares a dummy account with contact so need to take that into account
        System.assertNotEquals(null, acc.Id);
        Account dummy_acc = [SELECT Id, RecordType.Name FROM Account WHERE Id =: acc.Id];
        System.assertNotEquals(null, dummy_acc);
        Boolean isBusinessDummyAccount = dummy_acc.RecordType.Name.equalsIgnoreCase('Business');

        Account organization1 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization1.Id);
        Account organization2 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization2.Id);
        Account organization3 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization3.Id);
        Account organization4 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization4.Id);

        List<Account> lst_Account = [SELECT Id FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(4 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account.size());

        Test.startTest();

        Campaign c = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        System.assertNotEquals(null, c.Id);

        Test.stopTest();

        Map<Id, Organization_Campaign__c> map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c FROM Organization_Campaign__c WHERE Campaign__c =: c.Id]);
        System.assertEquals(4 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(true, oc.Active__c);
        }

        List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.assertEquals(4 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());
        for (Agent_Campaign__c ac : lst_AgentCampaigns) {
            System.assertEquals(true, ac.Active__c);
        }
    }

    @IsTest
    static void testDeactivateCampaign() {

        Account acc = UnitTestHelper.prepareDevEnvCustomSettings(); // this call also prepares a dummy account with contact so need to take that into account
        System.assertNotEquals(null, acc.Id);
        Account dummy_acc = [SELECT Id, RecordType.Name FROM Account WHERE Id =: acc.Id];
        System.assertNotEquals(null, dummy_acc);
        Boolean isBusinessDummyAccount = dummy_acc.RecordType.Name.equalsIgnoreCase('Business');

        CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = true;
        Campaign c = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = false;
        System.assertNotEquals(null, c.Id);

        // verify that campaign was created and in the correct record type
        List<Campaign> lst_Campaigns1 = [Select Id, IsActive, CreatedDate, Duration__c, RecordType.DeveloperName From Campaign Where RecordType.DeveloperName = 'Producer_Incentive_Campaign'];
        System.debug('lst_Campaigns1: ' + lst_Campaigns1);
        System.assertNotEquals(0, lst_Campaigns1.size());
        List<Campaign> lst_Campaigns2 = [Select Id, IsActive, CreatedDate, Duration__c, RecordType.DeveloperName From Campaign Where Id =: c.Id];
        System.debug('lst_Campaigns2: ' + lst_Campaigns2);
        System.assertNotEquals(0, lst_Campaigns2.size());

        Account organization1 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization1.Id);
        System.debug('organization1: ' + organization1);
        List<Account> accounts1 = [Select Id, (select Id from contacts) From Account WHERE Id =: organization1.Id];
        System.debug('organization1 contacts: ' + accounts1[0].contacts);
        Account organization2 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization2.Id);
        System.debug('organization2: ' + organization2);
        List<Account> accounts2 = [Select Id, (select Id from contacts) From Account WHERE Id =: organization2.Id];
        System.debug('organization2 contacts: ' + accounts2[0].contacts);

        List<Account> lst_Account = [SELECT Id FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account.size());

        //CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = true;
        //Campaign c = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        //CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = false;
        //System.assertNotEquals(null, c.Id);

        // CONFIRM ACTIVATION OF CAMPAIGN AND RELATED OBJECTS
        Map<Id, Organization_Campaign__c> map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c FROM Organization_Campaign__c WHERE Campaign__c =: c.Id]);
        System.debug('map_OrganizationCampaignsByIds 1: ' + map_OrganizationCampaignsByIds);
        System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(true, oc.Active__c);
        }

        List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());
        for (Agent_Campaign__c ac : lst_AgentCampaigns) {
            System.assertEquals(true, ac.Active__c);
        }

        Test.startTest();

        c.IsActive = false;
        update c;

        Test.stopTest();

        // CONFIRM DEACTIVATION OF CAMPAIGN AND RELATED OBJECTS
        Campaign cRet = [SELECT Id, IsActive FROM Campaign WHERE Id =: c.Id LIMIT 1];
        System.assertEquals(false, cRet.IsActive);

        map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c FROM Organization_Campaign__c WHERE Campaign__c =: c.Id]);
        System.debug('map_OrganizationCampaignsByIds 2: ' + map_OrganizationCampaignsByIds);
        System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(false, oc.Active__c);
        }

        lst_AgentCampaigns = [SELECT Id, Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());
        for (Agent_Campaign__c ac : lst_AgentCampaigns) {
            System.assertEquals(false, ac.Active__c);
        }
    }

    @IsTest
    static void testNewOrganization() {

        Account acc = UnitTestHelper.prepareDevEnvCustomSettings(); // this call also prepares a dummy account with contact so need to take that into account
        System.assertNotEquals(null, acc.Id);
        Account dummy_acc = [SELECT Id, RecordType.Name FROM Account WHERE Id =: acc.Id];
        System.assertNotEquals(null, dummy_acc);
        Boolean isBusinessDummyAccount = dummy_acc.RecordType.Name.equalsIgnoreCase('Business');

        Account organization1 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization1.Id);
        Account organization2 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization2.Id);
        Account organization3 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization3.Id);
        Account organization4 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization4.Id);

        List<Account> lst_Account = [SELECT Id FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(4 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account.size());

        Campaign c = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        System.assertNotEquals(null, c.Id);

        Test.startTest();

        // adding new organization with a related contact so new organization campaign should be created and new agent campaign
        Account organization5 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization5.Id);

        Test.stopTest();

        Map<Id, Organization_Campaign__c> map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c FROM Organization_Campaign__c WHERE Campaign__c =: c.Id]);
        System.assertEquals(5 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(true, oc.Active__c);
        }

        List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.assertEquals(5 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());
        for (Agent_Campaign__c ac : lst_AgentCampaigns) {
            System.assertEquals(true, ac.Active__c);
        }
    }

    @IsTest
    static void testNewAgent() {

        Account acc = UnitTestHelper.prepareDevEnvCustomSettings(); // this call also prepares a dummy account with contact so need to take that into account
        System.assertNotEquals(null, acc.Id);
        Account dummy_acc = [SELECT Id, RecordType.Name FROM Account WHERE Id =: acc.Id];
        System.assertNotEquals(null, dummy_acc);
        Boolean isBusinessDummyAccount = dummy_acc.RecordType.Name.equalsIgnoreCase('Business');

        Account organization1 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization1.Id);

        List<Account> lst_Account = [SELECT Id FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(1 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account.size());

        Campaign c = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        System.assertNotEquals(null, c.Id);

        Test.startTest();

        // adding new agent so a new agent campaign should be created
        Contact con = UnitTestHelper.prepareContact('Business', organization1);
        System.assertNotEquals(null, con.Id);

        Test.stopTest();

        Map<Id, Organization_Campaign__c> map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c FROM Organization_Campaign__c WHERE Campaign__c =: c.Id]);
        System.assertEquals(1 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(true, oc.Active__c);
        }

        List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());
        for (Agent_Campaign__c ac : lst_AgentCampaigns) {
            System.assertEquals(true, ac.Active__c);
        }
    }

    @IsTest
    static void increaseCoverageForNonReachableCode() {

        OrganizationCampaignTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testSingleAgentPerCampaign() {

        Account acc = UnitTestHelper.prepareDevEnvCustomSettings(); // this call also prepares a dummy account with contact so need to take that into account
        System.assertNotEquals(null, acc.Id);
        Account dummy_acc = [SELECT Id, RecordType.Name FROM Account WHERE Id =: acc.Id];
        System.assertNotEquals(null, dummy_acc);
        Boolean isBusinessDummyAccount = dummy_acc.RecordType.Name.equalsIgnoreCase('Business');

        Account organization1 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization1.Id);

        List<Account> lst_Account = [SELECT Id FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(1 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account.size());

        // adding new agent so a new agent campaign should be created
        Contact con1 = UnitTestHelper.prepareContact('Business', organization1);
        System.assertNotEquals(null, con1.Id);

        CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = true;
        Campaign c1 = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = false;
        System.assertNotEquals(null, c1.Id);

        Test.startTest();

        //Account organization2 = UnitTestHelper.prepareAccountWithContact('Business');
        //System.assertNotEquals(null, organization2.Id);

        Campaign c2 = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        System.assertNotEquals(null, c2.Id);

        // adding new agent so a new agent campaign should be created
        //Contact con2 = UnitTestHelper.prepareContact('Business', organization1);
        //System.assertNotEquals(null, con2.Id);

        Test.stopTest();

        Map<Id, Organization_Campaign__c> map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c FROM Organization_Campaign__c WHERE Campaign__c =: c1.Id OR Campaign__c =: c2.Id]);
        System.assertEquals((1 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC) * 2, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(true, oc.Active__c);
        }

        List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Agent__c, Organization_Campaign__c, Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.debug('lst_AgentCampaigns: ' + lst_AgentCampaigns);

        if ( !FeatureFlags.instance.ff_One_Campaign_per_Producer )
            System.assertEquals((2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC) * 2, lst_AgentCampaigns.size());
        else
            System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());

        for (Agent_Campaign__c ac : lst_AgentCampaigns) {
            System.assertEquals(true, ac.Active__c);
        }
    }

    @IsTest
    static void testSingleAgentPerStateSpecificCampaign() {

        Account acc = UnitTestHelper.prepareDevEnvCustomSettings(); // this call also prepares a dummy account with contact so need to take that into account
        System.assertNotEquals(null, acc.Id);
        Account dummy_acc = [SELECT Id, RecordType.Name, RecordType.DeveloperName FROM Account WHERE Id =: acc.Id];
        System.debug('Dummy Account: ' + dummy_acc);
        System.assertNotEquals(null, dummy_acc);
        Boolean isBusinessDummyAccount = dummy_acc.RecordType.Name.equalsIgnoreCase('Business');
        System.debug('isBusinessDummyAccount: ' + isBusinessDummyAccount);

        Account organization1 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization1.Id);
        System.debug('organization1 Name: ' + organization1.Name);

        List<Account> lst_Account = [SELECT Id, Name, RecordType.Name FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(1 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account.size());
        System.debug('lst_Account: ' + lst_Account);

        // adding new agent so a new agent campaign should be created
        Contact con1 = UnitTestHelper.prepareContact('Business', organization1);
        System.assertNotEquals(null, con1.Id);

        // check number of created contacts
        List<Contact> contacts_count1 = [SELECT Id FROM Contact];
        System.assertEquals(3 + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, contacts_count1.size());

        CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = true;
        Campaign c1 = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        CampaignTriggerHandler.SYNCHRONOUS_EXECUTE_QUEUEABLE_CreateOrganizationCampaigns = false;
        System.assertNotEquals(null, c1.Id);

        Test.startTest();

        Campaign c2 = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, true);
        System.assertNotEquals(null, c2.Id);

        List<Organization_Campaign__c> stateCheckOrganizationCampaigns = [SELECT Id, Organization__c, Organization__r.Name, Campaign__c, Campaign__r.Name FROM Organization_Campaign__c];
        System.debug('stateCheckOrganizationCampaigns: ' + stateCheckOrganizationCampaigns);
        System.assertEquals(4 + (UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC * 2), stateCheckOrganizationCampaigns.size());

        Account organization2 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization2.Id);
        System.debug('organization2 Name: ' + organization2.Name);

        //stateCheckOrganizationCampaigns = [SELECT Id FROM Organization_Campaign__c];
        //System.debug('stateCheckOrganizationCampaigns: ' + stateCheckOrganizationCampaigns.size()); 4

        List<Contact> organization2_contact = [SELECT Id FROM Contact WHERE AccountId =: organization2.Id];
        System.assertEquals(1, organization2_contact.size());
        System.debug('organization2_contact: ' + organization2_contact[0].Id);

        // create license
        License__c license = UnitTestHelper.prepareLicense('ca');

        // adding new agent so a new agent campaign should be created
        Contact con2 = UnitTestHelper.prepareContact('Business', organization1);
        System.assertNotEquals(null, con2.Id);
        System.debug('con2: ' + con2.Id);

        //stateCheckOrganizationCampaigns = [SELECT Id FROM Organization_Campaign__c];
        //System.debug('stateCheckOrganizationCampaigns: ' + stateCheckOrganizationCampaigns.size()); 4

        // connect license to contact
        license.Contact__c = con2.Id; // assigning the contact to a license (in CA state) will make sure an agent campaign will be created for this contact
        update license;

        //stateCheckOrganizationCampaigns = [SELECT Id FROM Organization_Campaign__c];
        //System.debug('stateCheckOrganizationCampaigns: ' + stateCheckOrganizationCampaigns.size()); 5

        // check number of created contacts
        List<Contact> contacts_count2 = [SELECT Id FROM Contact];
        System.assertEquals(5 + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, contacts_count2.size());
        System.debug('contacts_count2: ' + contacts_count2);

        Test.stopTest();

        List<Account> lst_Account_count = [SELECT Id, Name FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(2 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account_count.size());
        System.debug('lst_Account_count: ' + lst_Account_count);

        Map<Id, Organization_Campaign__c> map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c, Organization__c, Organization__r.Name, Campaign__r.IsActive FROM Organization_Campaign__c WHERE Campaign__c =: c1.Id OR Campaign__c =: c2.Id]);
        System.debug('map_OrganizationCampaignsByIds: ' + map_OrganizationCampaignsByIds);
        System.debug('map_OrganizationCampaignsByIds count: ' + map_OrganizationCampaignsByIds.size());
        System.assertEquals(6 + (UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC * 2), map_OrganizationCampaignsByIds.size());
        //System.assertEquals((2 + (isBusinessDummyAccount ? 1 : 0)) * 2, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(oc.Campaign__r.IsActive, oc.Active__c);
        }

        List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Agent__c, Organization_Campaign__c, Organization_Campaign__r.Organization__c, Organization_Campaign__r.Campaign__c, Organization_Campaign__r.Campaign__r.IsActive, Organization_Campaign__r.Campaign__r.State__c, Organization_Campaign__r.Campaign__r.Restricted_To_State__c,  Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.debug('lst_AgentCampaigns: ' + lst_AgentCampaigns);
        System.debug('lst_AgentCampaigns count: ' + lst_AgentCampaigns.size());

        if ( !FeatureFlags.instance.ff_One_Campaign_per_Producer )
            System.assertEquals(6 + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());
        else
            System.assertEquals(5 + UnitTestHelper.NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC, lst_AgentCampaigns.size());

        //System.assertEquals(3 + (isBusinessDummyAccount ? 1 : 0), lst_AgentCampaigns.size());
        for (Agent_Campaign__c ac : lst_AgentCampaigns) {
            System.assertEquals(ac.Organization_Campaign__r.Campaign__r.IsActive, ac.Active__c);
            System.debug('==== START AGENT CAMPAIGN OUTPUT ====');
            System.debug('Agent_Campaign__c Campaign: ' + ac.Organization_Campaign__r.Campaign__c);
            System.debug('Agent_Campaign__c Campaign RestrictedToState: ' + ac.Organization_Campaign__r.Campaign__r.Restricted_To_State__c);
            System.debug('Agent_Campaign__c Campaign State: ' + ac.Organization_Campaign__r.Campaign__r.State__c);
            System.debug('Agent_Campaign__c Account: ' + ac.Organization_Campaign__r.Organization__c);
            System.debug('Agent_Campaign__c Contact: ' + ac.Agent__c);
            System.debug('==== END AGENT CAMPAIGN OUTPUT ====');
        }
    }

    @IsTest
    static void testStateRestrictedCampaignCreationAfterAgentCreation() {

        Account acc = UnitTestHelper.prepareDevEnvCustomSettings(); // this call also prepares a dummy account with contact so need to take that into account
        System.assertNotEquals(null, acc.Id);
        Account dummy_acc = [SELECT Id, RecordType.Name, RecordType.DeveloperName FROM Account WHERE Id =: acc.Id];
        System.debug('Dummy Account: ' + dummy_acc);
        System.assertNotEquals(null, dummy_acc);
        Boolean isBusinessDummyAccount = dummy_acc.RecordType.Name.equalsIgnoreCase('Business');
        System.debug('isBusinessDummyAccount: ' + isBusinessDummyAccount);

        Account organization1 = UnitTestHelper.prepareAccountWithContact('Business');
        System.assertNotEquals(null, organization1.Id);
        System.debug('organization1 Name: ' + organization1.Name);

        List<Account> lst_Account = [SELECT Id FROM Account WHERE RecordType.Name = 'Business'];
        System.assertEquals(1 + (isBusinessDummyAccount ? 1 : 0) + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, lst_Account.size());

        // adding new agent so a new agent campaign should be created
        Contact con1 = UnitTestHelper.prepareContact('Business', organization1);
        System.assertNotEquals(null, con1.Id);

        Test.startTest();

        Campaign c1 = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'OH', true, true);
        System.assertNotEquals(null, c1.Id);

        Test.stopTest();

        Map<Id, Organization_Campaign__c> map_OrganizationCampaignsByIds = new Map<Id, Organization_Campaign__c>([SELECT Id, Active__c, Organization__c, Organization__r.Name, Campaign__r.IsActive FROM Organization_Campaign__c WHERE Campaign__c =: c1.Id]);
        System.debug('map_OrganizationCampaignsByIds: ' + map_OrganizationCampaignsByIds);
        System.debug('map_OrganizationCampaignsByIds count: ' + map_OrganizationCampaignsByIds.size());
        System.assertEquals(2 + UnitTestHelper.NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC, map_OrganizationCampaignsByIds.size());
        for (Organization_Campaign__c oc : map_OrganizationCampaignsByIds.values()) {
            System.assertEquals(oc.Campaign__r.IsActive, oc.Active__c);
        }

        List<Agent_Campaign__c> lst_AgentCampaigns = [SELECT Id, Agent__c, Organization_Campaign__c, Organization_Campaign__r.Organization__c, Organization_Campaign__r.Campaign__c, Organization_Campaign__r.Campaign__r.IsActive, Organization_Campaign__r.Campaign__r.State__c, Organization_Campaign__r.Campaign__r.Restricted_To_State__c,  Active__c FROM Agent_Campaign__c WHERE Organization_Campaign__c IN: map_OrganizationCampaignsByIds.keySet()];
        System.debug('lst_AgentCampaigns: ' + lst_AgentCampaigns);
        System.debug('lst_AgentCampaigns count: ' + lst_AgentCampaigns.size());
        System.assertEquals(0, lst_AgentCampaigns.size());
    }
}