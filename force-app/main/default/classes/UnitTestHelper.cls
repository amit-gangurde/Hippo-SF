public with sharing class UnitTestHelper {

    public static final Integer NUMBER_OF_UNIT_TEST_ACCOUNTS_FOR_ACCOUNTSYNC = 1;
    public static final Integer NUMBER_OF_UNIT_TEST_CONTACTS_FOR_ACCOUNTSYNC = 1;

    public static void initiateAccountSyncTestData() {

        Hippo_Last_Sync__c current_sync = Hippo_Last_Sync__c.getInstance(UserInfo.getProfileId());

        if ( String.isBlank(current_sync.Name) ) {

            Hippo_Last_Sync__c sync = new Hippo_Last_Sync__c();
            sync.Producer_Last_Updated_DateTime__c = DateTime.now();
            sync.LicenseLast_Update_DateTime__c = DateTime.now();
            sync.Account_Trigger_Active__c = true;
            sync.Contact_Trigger_Active__c = true;
            insert sync;
        }

        Account accOBJ = new Account();
        accOBJ.Name = 'Test';
        accOBJ.Sync_to_AgentSync__c = 'Yes';
        accOBJ.NPN__c = '12345';
        accOBJ.FEIN_number__c = '12345';
        insert accOBJ;

        AccountSync.isRecursive = false;

        Account accOBJUpd = new Account();
        accOBJUpd.Id = accOBJ.Id;
        update accOBJUpd;

        AccountSync.isRecursive = false;

        Contact con = new Contact();
        con.LastName = 'Test';
        con.AccountId = accOBJ.ID;
        con.Sync_to_AgentSync__c = 'Yes';
        con.PodRole__c = 'Customer Service';
        con.PodRoleAdmin__c = false;
        con.PodRoleMasterAgent__c = false;
        con.PodRolePrincipal__c = true;
        con.National_Producer_Number__c = '12345';
        insert con;
        AccountSync.isRecursive  = false;
        Contact conUpd = new Contact();
        conUpd.Id = con.Id;
        update conUpd;
    }

    /*
    Method: prepareDevEnvCustomSettings
    Description: Prepare custom settings data required for unit tests
    Return: nothing
    */
    public static Account prepareDevEnvCustomSettings() {

        X3rd_Party_Adjuster_Emails__c testX3rd_Party_Adjuster_Emails1 = new X3rd_Party_Adjuster_Emails__c();
        testX3rd_Party_Adjuster_Emails1.Name = 'Handdii';
        testX3rd_Party_Adjuster_Emails1.Email__c = 'dellett@myhippo.com';
        insert testX3rd_Party_Adjuster_Emails1;

        X3rd_Party_Adjuster_Emails__c testX3rd_Party_Adjuster_Emails2 = new X3rd_Party_Adjuster_Emails__c();
        testX3rd_Party_Adjuster_Emails2.Name = 'One Call Claims';
        testX3rd_Party_Adjuster_Emails2.Email__c = 'dellett@myhippo.com';
        insert testX3rd_Party_Adjuster_Emails2;

        X3rd_Party_Adjuster_Emails__c testX3rd_Party_Adjuster_Emails3 = new X3rd_Party_Adjuster_Emails__c();
        testX3rd_Party_Adjuster_Emails3.Name = 'Team One';
        testX3rd_Party_Adjuster_Emails3.Email__c = 'dellett@myhippo.com';
        insert testX3rd_Party_Adjuster_Emails3;

        X3rd_Party_Adjuster_Emails__c testX3rd_Party_Adjuster_Emails4 = new X3rd_Party_Adjuster_Emails__c();
        testX3rd_Party_Adjuster_Emails4.Name = 'Westhill';
        testX3rd_Party_Adjuster_Emails4.Email__c = 'dellett@myhippo.com';
        insert testX3rd_Party_Adjuster_Emails4;

        Hippo_Settings__c hsProperty = new Hippo_Settings__c();
        hsProperty.Name = 'Omni Lead Queue Developer Name';
        hsProperty.Value__c = 'B2C_Direct_Sales'; //Utils.isSandboxInstance() ? 'B2C_Direct_Sales' : 'B2C_Direct_Sales';
        insert hsProperty;

        Hippo_Settings__c hsProperty1 = new Hippo_Settings__c();
        hsProperty1.Name = 'Pending Leads EST Queue';
        hsProperty1.Value__c = 'EST_Pending_Leads';
        insert hsProperty1;

        Hippo_Settings__c hsProperty2 = new Hippo_Settings__c();
        hsProperty2.Name = 'Pending Leads PST Queue';
        hsProperty2.Value__c = 'PST_Pending_Leads';
        insert hsProperty2;

        Hippo_Settings__c hsProperty3 = new Hippo_Settings__c();
        hsProperty3.Name = 'Retention Cases Queue';
        hsProperty3.Value__c = 'Retention_B2C';
        insert hsProperty3;

        Hippo_Settings__c hsProperty4 = new Hippo_Settings__c();
        hsProperty4.Name = 'Pending Cases EST Queue';
        hsProperty4.Value__c = 'EST_Pending_Cases';
        insert hsProperty4;

        Hippo_Settings__c hsProperty5 = new Hippo_Settings__c();
        hsProperty5.Name = 'Pending Cases PST Queue';
        hsProperty5.Value__c = 'PST_Pending_Cases';
        insert hsProperty5;

        Hippo_Settings__c hsProperty6 = new Hippo_Settings__c();
        hsProperty6.Name = 'PSR_BATCH_SIZE';
        hsProperty6.Value__c = '50';
        insert hsProperty6;

        Hippo_Settings__c hsProperty7 = new Hippo_Settings__c();
        hsProperty7.Name = 'PSR_LAST_N_DAYS';
        hsProperty7.Value__c = '11';
        insert hsProperty7;

        Hippo_Settings__c hsProperty8 = new Hippo_Settings__c();
        hsProperty8.Name = 'NumOfCalloutRetries';
        hsProperty8.Value__c = '3';
        insert hsProperty8;

        Hippo_Settings__c hsProperty9 = new Hippo_Settings__c();
        hsProperty9.Name = 'AWS POD Webhook';
        hsProperty9.Value__c = 'https://m28l02p49i.execute-api.us-west-2.amazonaws.com';
        insert hsProperty9;

        Hippo_Settings__c hsProperty10 = new Hippo_Settings__c();
        hsProperty10.Name = 'Retention Cases Queue';
        hsProperty10.Value__c = 'Retention_B2C';
        insert hsProperty10;

        Hippo_Settings__c hsProperty11 = new Hippo_Settings__c();
        hsProperty11.Name = 'Excluded Lead Record Types';
        hsProperty11.Value__c = 'Web Leads - Producers;Web Leads - Default;Email Lead';
        insert hsProperty11;

        Hippo_Settings__c hsProperty12 = new Hippo_Settings__c();
        hsProperty12.Name = 'Inside Sales Contractors States';
        hsProperty12.Value__c = 'CA';
        insert hsProperty12;

        Hippo_Settings__c hsProperty13 = new Hippo_Settings__c();
        hsProperty13.Name = 'Producer Incentive Batch Size';
        hsProperty13.Value__c = '20'; // 5000
        insert hsProperty13;

        Hippo_Settings__c hsProperty14 = new Hippo_Settings__c();
        hsProperty14.Name = 'Email to Lead Organization';
        hsProperty14.Value__c = 'HomeGauge';
        insert hsProperty14;

        Hippo_Settings__c hsProperty15 = new Hippo_Settings__c();
        hsProperty15.Name = 'Timezone Routing Batch Size';
        hsProperty15.Value__c = '5000';
        insert hsProperty15;

        Hippo_Settings__c hsProperty16 = new Hippo_Settings__c();
        hsProperty16.Name = 'Leads Cockpit Permission Set API Name';
        hsProperty16.Value__c = 'Manager_Permissions';
        insert hsProperty16;

        Hippo_Settings__c hsProperty17 = new Hippo_Settings__c();
        hsProperty17.Name = 'JV Leads Seniority (days)';
        hsProperty17.Value__c = '30';
        insert hsProperty17;

        Hippo_Settings__c hsProperty18 = new Hippo_Settings__c();
        hsProperty18.Name = 'PennyMac Org';
        hsProperty18.Value__c = 'PennyMac Insurance Agency';
        insert hsProperty18;

        Hippo_Settings__c hsProperty19 = new Hippo_Settings__c();
        hsProperty19.Name = 'AmeriSave Org';
        hsProperty19.Value__c = 'AmeriSave Insurance Agency';
        insert hsProperty19;

        Hippo_Settings__c hsProperty20 = new Hippo_Settings__c();
        hsProperty20.Name = 'First Street Org';
        hsProperty20.Value__c = 'Risk Factor, LLC DBA First Street';
        insert hsProperty20;

        Hippo_Settings__c hsProperty21 = new Hippo_Settings__c();
        hsProperty21.Name = 'Loan Depot Org';
        hsProperty21.Value__c = 'Loan Depot';
        insert hsProperty21;

        Hippo_Settings__c hsProperty22 = new Hippo_Settings__c();
        hsProperty22.Name = 'Hippo Analytics Org';
        hsProperty22.Value__c = 'Hippo Analytics, Inc.';
        insert hsProperty22;

        initiateAccountSyncTestData();

        return prepareAccountWithContact(); // require for Utils.sendEmail() as it looks for a dummy contact
    }

    public static Account prepareAccount() {

        Account testAccount = new Account(Name = 'Test Account ' + Utils.getRandomString(5));
        testAccount.BillingStreet = 'BillingStreet';
        testAccount.BillingCity = 'BillingCity';
        testAccount.BillingCountry  = 'United States';
        testAccount.Website = 'None';
        testAccount.NPN__c = '12345';
        testAccount.FEIN_number__c = '1234';

        insert testAccount;

        return testAccount;
    }

    public static Account prepareAccount(String state) {

        Account testAccount = new Account(Name = 'Test Account ' + Utils.getRandomString(5));
        testAccount.BillingStreet = 'BillingStreet';
        testAccount.BillingCity = 'BillingCity';
        testAccount.BillingCountry  = 'United States';
        testAccount.BillingState  = state;
        testAccount.Website = 'None';

        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(testAccount, dml);
        //insert testAccount;

        return testAccount;
    }

    public static Carrier_Appointment__c prepareCarrierAppointment() {

        Carrier_Appointment__c testCarrierAppointment = new Carrier_Appointment__c(Name = 'Carrier Appointment Name');

        insert testCarrierAppointment;

        return testCarrierAppointment;
    }

    public static License__c prepareLicense() {

        Producer_Licensing__c pl = new Producer_Licensing__c(Name = 'Producer Licensing Name');
        insert pl;

        License__c testLicense = new License__c(Name = 'License Name');
        testLicense.Producer_Licensing__c = pl.Id;

        insert testLicense;

        return testLicense;
    }

    public static License__c prepareLicense(String stateCode) {

        Producer_Licensing__c pl = new Producer_Licensing__c(Name = 'Producer Licensing Name');
        insert pl;

        License__c testLicense = new License__c(Name = 'License Name');
        testLicense.Producer_Licensing__c = pl.Id;
        testLicense.State_Code__c = stateCode;

        insert testLicense;

        return testLicense;
    }

    public static Contact prepareContact(String recTypeName) {

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo(recTypeName, 'Contact');
        Contact testContact = new Contact(FirstName = 'Contact FirstName ' + Utils.getRandomString(5), LastName = 'Contact LastName ' + Utils.getRandomString(5), Email = Utils.getRandomString(5) + '@test.com', PodRole__c = 'Customer Service');
        testContact.RecordTypeId = rtInfo.getRecordTypeId();
        testContact.PodRole__c = 'Customer Service';
        testContact.PodRoleAdmin__c = false;
        testContact.PodRoleMasterAgent__c = false;
        testContact.PodRolePrincipal__c = true;
        testContact.National_Producer_Number__c = '12345';
        testContact.NPN__c = '';
        
        insert testContact;

        return testContact;
    }

    public static Contact prepareContact(String recTypeName, Account parentAccount) {

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo(recTypeName, 'Contact');
        Contact testContact = new Contact(FirstName = 'Contact FirstName ' + Utils.getRandomString(5), LastName = 'Contact LastName ' + Utils.getRandomString(5), Email = Utils.getRandomString(5) + '@test.com', PodRole__c = 'Customer Service');
        testContact.RecordTypeId = rtInfo.getRecordTypeId();
        testContact.AccountId = parentAccount.Id;
        testContact.PodRole__c = 'Customer Service';
        testContact.PodRoleAdmin__c = false;
        testContact.PodRoleMasterAgent__c = false;
        testContact.PodRolePrincipal__c = true;
        testContact.National_Producer_Number__c = '12345';
        testContact.NPN__c = '';

        insert testContact;

        return testContact;
    }

    public static Account prepareAccountWithContact() {

        Account testAccount = new Account(Name = 'Test Account With Contact ' + Utils.getRandomString(5));
        testAccount.BillingStreet = 'Account BillingStreet ' + Utils.getRandomString(5);
        testAccount.BillingCity = 'Account BillingCity ' + Utils.getRandomString(5);
        testAccount.BillingCountry  = 'United States';
        testAccount.Website = 'https://www.' + + Utils.getRandomString(5) + '.com';

        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(testAccount, dml);
        //insert testAccount;

        Contact testContact = new Contact(FirstName = 'Contact FirstName ' + Utils.getRandomString(5), LastName = 'Contact LastName ' + Utils.getRandomString(5), Email = Utils.getRandomString(5) + '@test.com', PodRole__c = 'Customer Service');
        testContact.AccountId = testAccount.Id;
        testContact.PodRole__c = 'Customer Service';
        testContact.PodRoleAdmin__c = false;
        testContact.PodRoleMasterAgent__c = false;
        testContact.PodRolePrincipal__c = true;
        testContact.National_Producer_Number__c = '12345';

        insert testContact;
        System.debug('Test Contact created: ' + testContact);

        return testAccount;
    }

    public static Account prepareAccountWithContact(String accountRecTypeName) {

        Account testAccount = new Account(Name = 'Test Account With Contact ' + Utils.getRandomString(5));
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo(accountRecTypeName, 'Account');
        testAccount.RecordTypeId = rtInfo.getRecordTypeId();
        testAccount.BillingStreet = 'Account BillingStreet ' + Utils.getRandomString(5);
        testAccount.BillingCity = 'Account BillingCity ' + Utils.getRandomString(5);
        testAccount.BillingCountry  = 'United States';
        testAccount.Website = 'https://www.' + + Utils.getRandomString(5) + '.com';

        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(testAccount, dml);
        //insert testAccount;

        Contact testContact = new Contact(FirstName = 'Contact FirstName ' + Utils.getRandomString(5), LastName = 'Contact LastName ' + Utils.getRandomString(5), Email = Utils.getRandomString(5) + '@test.com', PodRole__c = 'Customer Service');
        testContact.AccountId = testAccount.Id;
        testContact.PodRole__c = 'Customer Service';
        testContact.PodRoleAdmin__c = false;
        testContact.PodRoleMasterAgent__c = false;
        testContact.PodRolePrincipal__c = true;
        testContact.National_Producer_Number__c = '12345';

        insert testContact;
        System.debug('Test Contact created: ' + testContact);

        return testAccount;
    }

    public static Account prepareAccount(Boolean create, String accountName) {

        Account testAccount = new Account(Name = accountName);
        testAccount.BillingStreet = 'BillingStreet';
        testAccount.BillingCity = 'BillingCity';
        testAccount.BillingCountry  = 'United States';
        testAccount.Website = 'None';
        testAccount.NPN__c = '12345';
        testAccount.FEIN_number__c = '1234';

        if ( create ) insert testAccount;

        return testAccount;
    }

    public static Case prepareClaimCase(String peril, String carrier, String region) {

        Account acc = new Account();
        acc.LastName = 'Test Account ' + Utils.getRandomString(5);
        acc.RecordTypeId = '0126g000001JEVB';
        acc.PersonEmail = 'acc@Gmail.com';
        acc.Resource_Username__c = 'test';
        acc.Resource_Number__c = 'w453';
        acc.NPN__c = '1234';
        acc.Home_State__c = 'CA';
        acc.Configuration_Type__c = 'None';
        acc.Sync_to_AgentSync__c = 'No';
        acc.Corp_Structure__c = 'LLC';
        acc.Support_Service_Email__c = 'acc@Gmail.com';
        acc.FEIN_number__c = '1234';
        insert acc;

        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = 'test';
        insert ins;

        Case cs = new Case();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('Claim', 'Case');
        cs.RecordTypeId = rtInfo.getRecordTypeId();
        cs.Policy_Number__c = Utils.getRandomString(5);
        cs.Peril__c = peril;
        cs.Carrier__c = carrier;
        cs.Region__c = region;
        cs.Severity_of_Loss__c = 'Major';
        cs.Date_of_Loss__c = Date.valueOf(system.now().addDays(-1));
        cs.Claims_Agreement__c = 'Agree';
        cs.Insurance_Policy__c = ins.id;
        cs.AccountId = acc.id;

        insert cs;

        return cs;
    }

    public static Case prepareClaimCase(String peril, String carrier, String region, String severity_loss) {

        Account acc = new Account();
        acc.LastName = 'Test Account ' + Utils.getRandomString(5);
        acc.RecordTypeId = '0126g000001JEVB';
        acc.PersonEmail = 'acc@Gmail.com';
        acc.Resource_Username__c = 'test';
        acc.Resource_Number__c = 'w453';
        insert acc;

        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = 'test';
        ins.State__c = 'CA';
        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(ins, dml);
        //insert ins;

        Case cs = new Case();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('Claim', 'Case');
        cs.RecordTypeId = rtInfo.getRecordTypeId();
        cs.Policy_Number__c = Utils.getRandomString(5);
        cs.Peril__c = peril;
        cs.Carrier__c = carrier;
        cs.Region__c = region;
        cs.Severity_of_Loss__c = severity_loss;
        cs.Date_of_Loss__c = Date.valueOf(system.now().addDays(-1));
        cs.Claims_Agreement__c = 'Agree';
        cs.Insurance_Policy__c = ins.id;
        cs.AccountId = acc.id;

        insert cs;

        return cs;
    }

    public static Case prepareClaimCase(String peril, String carrier, String region, Account acc) {

        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = 'test';
        ins.State__c = 'CA';
        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(ins, dml);
        //insert ins;

        Case cs = new Case();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('Claim', 'Case');
        cs.RecordTypeId = rtInfo.getRecordTypeId();
        cs.Policy_Number__c = Utils.getRandomString(5);
        cs.Peril__c = peril;
        cs.Carrier__c = carrier;
        cs.Region__c = region;
        cs.Severity_of_Loss__c = 'Major';
        cs.Date_of_Loss__c = Date.valueOf(system.now().addDays(-1));
        cs.Claims_Agreement__c = 'Agree';
        cs.Insurance_Policy__c = ins.id;
        cs.AccountId = acc.id;
        cs.Claim_Vendor__c = acc.id;

        insert cs;

        return cs;
    }
    public static Case prepareCaseWithRecordType(String RecordTypeName) {    
        Case cs = new Case();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo(RecordTypeName, 'Case');
        cs.RecordTypeId = rtInfo.getRecordTypeId();  
        insert cs;
        return cs;
    }

    public static Case prepareB2CSupportCase(String subject) {

        Case cs = new Case();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Support', 'Case');
        cs.RecordTypeId = rtInfo.getRecordTypeId();
        cs.Subject = subject;

        insert cs;

        return cs;
    }

    public static List<AgentWork> createAgentWorks(List<sObject> work_items, User user) {

        ServiceChannel sc_Case = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'Cases' LIMIT 1];
        ServiceChannel sc_Lead = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'Leads' LIMIT 1];

        //PresenceUserConfig puc = [SELECT Id FROM PresenceUserConfig WHERE DeveloperName = 'Cases' LIMIT 1];
        //ServicePresenceStatus sps = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = 'Available_Case' LIMIT 1];

        List<AgentWork> agentWorks = new List<AgentWork>();

        for (sObject obj : work_items) {

            String objectName = Utils.findObjectNameFromRecordIdPrefix(obj.Id);

            if ( objectName.equalsIgnoreCase('Case') ) {

                agentWorks.add(new AgentWork(ServiceChannelId = sc_Case.Id, WorkItemId = obj.Id, UserId = user.Id));
            }
            else if ( objectName.equalsIgnoreCase('Lead') ) {

                agentWorks.add(new AgentWork(ServiceChannelId = sc_Lead.Id, WorkItemId = obj.Id, UserId = user.Id));
            }
        }

        system.debug('createAgentWorks return: ' + agentWorks);

        return agentWorks;
    }

    public static Lead prepareB2CLead(Boolean create, Boolean assign2OmniChannel) {

        Lead ld = new Lead();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Email = 'sfdc.test@yahoo.com';
        ld.Phone = '20212345678';
        ld.MobilePhone = '2021237845';
        ld.POD_Quote_ID__c = '';

        if ( assign2OmniChannel ) {
            String queue_dev_name = Utils.getHippoSettings('Omni Lead Queue Developer Name');
            ld.OwnerId = Utils.getQueueId(queue_dev_name);
        }

        if ( create ) insert ld;

        return ld;
    }

    public static Lead prepareB2CLead(Boolean create, String state) {

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = state;
        ld.Phone = '20212345678';
        ld.MobilePhone = '2021237845';
        ld.POD_Quote_ID__c = '';
        ld.Email = 'sfdc.test@yahoo.com';
        //User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];
        //ld.OwnerId = infra_bot.Id; //UserInfo.getUserId();
        ld.Status = 'New';

        if ( create ) insert ld;

        return ld;
    }

    public static Lead prepareNonWorkableB2CLead(Boolean create, String state) {

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = state;
        //ld.Phone = '20212345678';
        //ld.MobilePhone = '2021237845';
        ld.POD_Quote_ID__c = '';
        ld.Email = 'sfdc.test@yahoo.com';
        //User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];
        //ld.OwnerId = infra_bot.Id; //UserInfo.getUserId();
        ld.Status = 'New';

        if ( create ) insert ld;

        return ld;
    }

    public static Messaging.SingleEmailMessage getEmailMessage(Lead lead, Boolean setSaveAsActivity) {

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setTargetObjectId(lead.Id);
        mail.setPlainTextBody('email body');
        mail.subject = 'test email from Hippo sfdc';
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setReplyTo(lead.Email);
        mail.setSenderDisplayName('SFDC Unit Tet');
        mail.setSaveAsActivity(setSaveAsActivity);

        return mail;
    }

    public static Task getTask(Boolean create, Id OwnerId, Id WhoId, Id WhatId, String Subject) {

        Task tsk = new Task();

        tsk.OwnerId = OwnerId;
        tsk.WhoId = WhoId;
        tsk.WhatId = WhatId;
        tsk.Status = 'Open';
        tsk.Priority = 'Normal';
        tsk.Subject = Subject;
        DateTime due_date = System.now().addDays(3);
        tsk.ActivityDate = date.newInstance(due_date.year(), due_date.month(), due_date.day());

        if ( create ) insert tsk;

        return tsk;
    }

    public static Task getLeadTask(Boolean create, Id OwnerId, Id WhoId, Id WhatId, String Subject) {

        Task tsk = new Task();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('Lead Task', 'Task');

        tsk.OwnerId = OwnerId;
        tsk.WhoId = WhoId;
        tsk.WhatId = WhatId;
        tsk.Status = 'Open';
        tsk.Priority = 'Normal';
        tsk.Subject = Subject;
        tsk.RecordTypeId = rtInfo.getRecordTypeId();
        DateTime due_date = System.now().addDays(3);
        tsk.ActivityDate = date.newInstance(due_date.year(), due_date.month(), due_date.day());

        if ( create ) insert tsk;

        return tsk;
    }

    public static Case prepareRetentionCase(Boolean create, String state) {

        Case cs = new Case();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('Retention', 'Case');
        cs.RecordTypeId = rtInfo.getRecordTypeId();

        Account acc = UnitTestHelper.prepareAccount(state);
        cs.AccountId = acc.id;

        if ( create ) insert cs;

        return cs;
    }

    public static Lead prepareB2CLeadWithAccountName(Boolean create, String accountName) {

        Account acc = UnitTestHelper.prepareAccount(true, accountName);

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        //ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Organization__c = acc.Id;
        ld.Account__c = acc.Id;

        if ( create ) insert ld;

        return ld;
    }

    /*
    public static Lead prepareB2CLeadWithAccountName(Boolean create, String accountName) {

        Account acc = UnitTestHelper.prepareAccount(true, accountName);

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';
        ld.Organization__c = acc.Id;

        if ( create ) insert ld;

        return ld;
    }
     */

    /*
    public static BusinessHours getESTBusinessHoursInBusiness() {

        Datetime dt_now = system.now();

        BusinessHours newHours = new BusinessHours(
                SundayStartTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                SundayEndTime = Time.newInstance(dt_now.addHours(1).hour(), 0, 0, 0),
                MondayStartTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                MondayEndTime = Time.newInstance(dt_now.addHours(1).hour(), 0, 0, 0),
                TuesdayStartTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                TuesdayEndTime = Time.newInstance(dt_now.addHours(1).hour(), 0, 0, 0),
                WednesdayStartTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                WednesdayEndTime = Time.newInstance(dt_now.addHours(1).hour(), 0, 0, 0),
                ThursdayStartTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                ThursdayEndTime = Time.newInstance(dt_now.addHours(1).hour(), 0, 0, 0),
                FridayStartTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                FridayEndTime = Time.newInstance(dt_now.addHours(1).hour(), 0, 0, 0),
                SaturdayStartTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                SaturdayEndTime = Time.newInstance(dt_now.addHours(1).hour(), 0, 0, 0),
                TimeZoneSidKey = 'America/New_York',
                IsActive = true,
                IsDefault = false
        );

        return newHours;
    }

    public static BusinessHours getESTBusinessHourOutOfBusiness() {

        Datetime dt_now = system.now();

        BusinessHours newHours = new BusinessHours(
                SundayStartTime = Time.newInstance(dt_now.addHours(-2).hour(), 0, 0, 0),
                SundayEndTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                MondayStartTime = Time.newInstance(dt_now.addHours(-2).hour(), 0, 0, 0),
                MondayEndTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                TuesdayStartTime = Time.newInstance(dt_now.addHours(-2).hour(), 0, 0, 0),
                TuesdayEndTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                WednesdayStartTime = Time.newInstance(dt_now.addHours(-2).hour(), 0, 0, 0),
                WednesdayEndTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                ThursdayStartTime = Time.newInstance(dt_now.addHours(-2).hour(), 0, 0, 0),
                ThursdayEndTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                FridayStartTime = Time.newInstance(dt_now.addHours(-2).hour(), 0, 0, 0),
                FridayEndTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                SaturdayStartTime = Time.newInstance(dt_now.addHours(-2).hour(), 0, 0, 0),
                SaturdayEndTime = Time.newInstance(dt_now.addHours(-1).hour(), 0, 0, 0),
                TimeZoneSidKey = 'America/New_York',
                IsActive = true,
                IsDefault = false
        );

        return newHours;
    }
     */

    /*
    public static PendingServiceRouting createPendingServiceRouting(Lead leadWorkItem) {

        ServiceChannel sc_Lead = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'Leads' LIMIT 1];

        PendingServiceRouting psrObj = new PendingServiceRouting(
            CapacityWeight = 1,
            IsReadyForRouting = false,
            RoutingModel  = 'MostAvailable',
            RoutingPriority = 1,
            RoutingType = 'QueueBased',
            ServiceChannelId = sc_Lead.Id,
            WorkItemId = leadWorkItem.Id,
            PushTimeout = 0
        );

        insert psrObj;

        return psrObj;
    }
     */

    public static user createuser (){
        Profile prof = [select id from profile where name LIKE '%Admin%' LIMIT 1];
        User user = new User();
        user.firstName = 'test1';
        user.lastName = 'test2';
        user.profileId = prof.id;
        user.username = 'testuserinhippo@hippo.com';
        user.email = 'test@hippo.com';
        user.EmailEncodingKey='UTF-8';
        user.LanguageLocaleKey='en_US';
        user.LocaleSidKey='en_US';
        user.TimeZoneSidKey='America/New_York';
        user.Alias = 'uid';
        insert user;
        return user;
    }

    public static Integration__c creteintegrationdetails(){
        Integration__c setting = new Integration__c();
        setting.Name = 'CustomSettingName (User)';
        setting.Auth_URL__c='https://20012.claimatic.net/api_login/login_check?';
        setting.MultiClaim_Status_Update_URL__c='https://20012.claimatic.net/claim_api/claim/update_multi_claim_status?type=xml';
        setting.Multiclaim_URL__c='https://20012.claimatic.net/claim_api/claim/create/multi?type=xml';
        setting.Password__c='YpRM63f8a6Zmmrft';
        setting.Reassign_Claim_URL__c='https://20012.claimatic.net/claim_api/claim/assignments/reassignment_request?type=xml';
        setting.Unassign_Claim_URL__c='https://20012.claimatic.net/claim_api/claim/unassign_claim_parties?type=xml';
        setting.Username__c='hippo_api1';
        setting.SetupOwnerId =userinfo.getUserId();
        insert setting;
        return setting;
    }

    public static InsurancePolicy createInsurancePolicy(String accid){
        InsurancePolicy inspol = new InsurancePolicy();
        inspol.Name='test';
        inspol.NameInsuredId=  accid;
        inspol.PolicyType='Home';
        // avoid DDUP rules during unit tests
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(inspol, dml);
        //insert inspol;
        return inspol;
    }

    public static HttpResponse createFakeHttpResponse(Integer status_code) {

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"http_response":"dummy"}');
        res.setStatusCode(status_code);
        return res;
    }

    public static Lead prepareLeadByRecordTypeName(Boolean create, String recordTypeName) {

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo(recordTypeName, 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.State = 'CA';
        //ld.OwnerId = UserInfo.getUserId();
        ld.Status = 'New';

        if ( create ) insert ld;

        return ld;
    }

    public static User_Assignment__c prepareTerritoryManagerUserAssignment(String states) {

        User_Assignment__c ua = new User_Assignment__c();
        ua.User__c = UserInfo.getUserId();
        ua.Name = 'Producer Web Leads - ' + UserInfo.getUserName();
        ua.State__c = states;
        ua.Territory_Manager__c = true;

        insert ua;

        return ua;
    }

    public static Campaign prepareCampaign(String recordTypeName, Boolean isActive) {

        Campaign c = new Campaign();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo(recordTypeName, 'Campaign');
        c.RecordTypeId = rtInfo.getRecordTypeId();
        c.Name = 'Test Campaign';
        c.IsActive = isActive;
        c.Duration__c = 3;
        c.Campaign_Code__c = '1234';
        c.Reward_Amount__c = 1234;
        c.Description = 'Campaign description';
        c.Memo__c = 'Memo';
        c.Min_Leads_Generated__c = 10;
        c.Min_Policies_Bound__c = 10;

        insert c;

        return c;
    }

    public static Campaign prepareCampaign(String recordTypeName, String stateCode, Boolean isActive, Boolean restrictedToState) {

        Campaign c = new Campaign();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo(recordTypeName, 'Campaign');
        c.RecordTypeId = rtInfo.getRecordTypeId();
        c.Name = 'Test Campaign ' + Utils.getRandomString(5);
        c.IsActive = isActive;
        c.Duration__c = 3;
        c.Campaign_Code__c = '1234' + Utils.getRandomString(5);
        c.Reward_Amount__c = 1234;
        c.Description = 'Campaign description';
        c.Memo__c = 'Memo';
        c.Min_Leads_Generated__c = 10;
        c.Min_Policies_Bound__c = 10;
        c.Restricted_To_State__c = restrictedToState;
        c.State__c = stateCode;

        insert c;

        return c;
    }

    public static Claim prepareClaim(String peril, String carrier, String region) {

        Account acc = new Account();
        acc.LastName = 'Test Account ' + Utils.getRandomString(5);
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acc.PersonEmail = 'acc@Gmail.com';
        acc.Resource_Username__c = 'test';
        acc.Resource_Number__c = 'w453';
        insert acc;

        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = 'test' + Utils.getRandomString(5);

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(ins, dml);
        System.debug('InsurancePolicy sr: ' + sr);
        //insert ins;

        Claim clm = new Claim();
        clm.Name = Utils.getRandomString(5);
        /*
        clm.Peril__c = peril;
        clm.Carrier__c = carrier;
        clm.Region__c = region;
        clm.Severity_of_Loss__c = 'Major';
        clm.Date_of_Loss__c = Date.valueOf(system.now());
         */
        //clm.Insurance_Policy__c = ins.id;
        clm.PolicyNumberId = ins.id;
        clm.AccountId = acc.id;
        clm.Claim_Agreement__c = 'Agree';

        insert clm;

        return clm;
    }

    public static Claim prepareClaim(String peril, String carrier, String region, Boolean create) {

        Account acc = new Account();
        acc.LastName = 'Test Account ' + Utils.getRandomString(5);
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acc.PersonEmail = 'acc@Gmail.com';
        acc.Resource_Username__c = 'test';
        acc.Resource_Number__c = 'w453';
        insert acc;

        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = Utils.getRandomString(5); //'test';

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(ins, dml);
        System.debug('InsurancePolicy sr: ' + sr);
        //insert ins;

        Claim clm = new Claim();
        clm.Name = Utils.getRandomString(5);
        /*
        clm.Peril__c = peril;
        clm.Carrier__c = carrier;
        clm.Region__c = region;
        clm.Severity_of_Loss__c = 'Major';
        clm.Date_of_Loss__c = Date.valueOf(system.now());
         */
        //clm.Insurance_Policy__c = ins.id;
        clm.PolicyNumber = ins;
        clm.PolicyNumberId = ins.id;
        clm.AccountId = acc.id;
        clm.Claim_Agreement__c = 'Agree';

        if ( create ) insert clm;

        return clm;
    }

    public static Account prepareAccountFromLead(Lead my_Lead) {

        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acc.FirstName = my_Lead.FirstName;
        acc.LastName = my_Lead.LastName;
        acc.Phone = my_Lead.Phone;
        acc.PersonMobilePhone = my_Lead.MobilePhone;
        acc.PersonEmail = my_Lead.Email;
        acc.Home_State__c = 'CA';
        acc.Configuration_Type__c = 'None';
        acc.Sync_to_AgentSync__c = 'No';
        acc.Corp_Structure__c = 'LLC';
        acc.Support_Service_Email__c = 'acc@Gmail.com';
        acc.FEIN_number__c = '1234';
        
        insert acc;

        return acc;
    }

    public static InsurancePolicy prepareInsurancePolicyFromLead(Lead my_Lead, Account my_Account) {

        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = my_Account.id;
        ins.Name = 'Test InsurancePolicy ' + Utils.getRandomString(5);
        ins.Street__c = my_Lead.Street;
        ins.City__c = my_Lead.City;
        ins.State__c = my_Lead.State;
        ins.Zip__c = my_Lead.PostalCode;
        ins.Status = 'Active';

        insert ins;

        return ins;
    }

    public static Claim_Cat_Event__c prepareClaimCatEvent(String peril, String state, String zip, Date fromDate, Date toDate, Boolean create) {

        Claim_Cat_Event__c cce = new Claim_Cat_Event__c();

        cce.Perils__c = peril;
        cce.States__c = state;
        cce.Zip_Codes__c = zip;
        cce.From_Date__c = fromDate;
        cce.To_Date__c = toDate;
        cce.Status__c = 'Active';
        cce.Cat_Code__c = '11111111';

        if ( create ) insert cce;

        return cce;
    }

    public static Account preparePersonAccount() {

        Account acc = new Account();

        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acc.FirstName = Utils.getRandomString(5);
        acc.LastName = Utils.getRandomString(5);
        acc.Phone = '2027365957';
        acc.PersonMobilePhone = '';
        acc.PersonEmail = 'personaccount@gmail.com';
        acc.Configuration_Type__c = 'None';
        acc.Sync_to_AgentSync__c = 'No';
        acc.Corp_Structure__c = 'LLC';
        acc.Support_Service_Email__c = 'acc@gmail.com';
        acc.FEIN_number__c = '1234';
        acc.PersonMailingCountry = 'United States';
        acc.PersonMailingCity = 'Atlanta';
        acc.PersonMailingState = 'ga';
        acc.PersonMailingStreet = '5190 Amberland Sq';
        acc.PersonMailingPostalCode = '30349';

        insert acc;

        return acc;
    }

    public static InsurancePolicy prepareInsurancePolicyFromPersonAccount(Account my_Account) {

        InsurancePolicy ins = new InsurancePolicy();

        ins.NameInsuredId = my_Account.id;
        ins.Name = 'HGA-8431247-00';
        ins.Street__c = my_Account.PersonMailingStreet;
        ins.City__c = my_Account.PersonMailingCity;
        ins.State__c = my_Account.PersonMailingState;
        ins.Zip__c = my_Account.PersonMailingPostalCode;
        ins.Status = 'Active';

        insert ins;

        return ins;
    }

    public static Lead prepareLeadFromPersonAccount(Boolean create, Account my_Account, Id ownerId) {

        Lead ld = new Lead();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = my_Account.FirstName;
        ld.LastName = my_Account.LastName;
        ld.City = my_Account.PersonMailingCity;
        ld.Country = my_Account.PersonMailingCountry;
        ld.State = my_Account.PersonMailingState;
        ld.Street = my_Account.PersonMailingStreet;
        ld.Email = my_Account.PersonEmail;
        ld.FinServ__ReferredByUser__c = UserInfo.getUserId();
        ld.FinServ__RelatedAccount__c = my_Account.id;
        ld.Internal_Referring_Team__c  = null;
        ld.Lead_Source__c = 'Internal Referral';
        ld.MiddleName = my_Account.MiddleName;
        ld.New_Business__c = true;
        ld.OwnerId = ownerId;
        ld.Phone = my_Account.Phone;
        ld.Policy_Types__c = 'Auto';
        ld.PostalCode = my_Account.PersonMailingPostalCode;
        ld.Referral_Notes__c = 'some referral notes';
        ld.Status = 'New';

        if ( create ) insert ld;

        return ld;
    }

    public static user createuser (Id profileId){
        User user = new User();
        user.firstName = Utils.getRandomString(5);
        user.lastName = Utils.getRandomString(5);
        user.profileId = profileId;
        user.username = Utils.getRandomString(5) + '@hippo.com';
        user.email = 'test@hippo.com';
        user.EmailEncodingKey='UTF-8';
        user.LanguageLocaleKey='en_US';
        user.LocaleSidKey='en_US';
        user.TimeZoneSidKey='America/New_York';
        user.Alias = 'uid';
        user.Authorized_States__c = 'CA';
        insert user;
        return user;
    }

    public static Lead prepareFacebookDirectLead(Boolean create) {

        Lead ld = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2C Sales', 'Lead');
        ld.RecordTypeId = rtInfo.getRecordTypeId();
        ld.FirstName = Utils.getRandomString(5);
        ld.LastName = Utils.getRandomString(5);
        ld.Phone = '20212345678';
        ld.Email = 'sfdc.test@yahoo.com';
        ld.Property_Type__c = 'Home';
        ld.Home_Size__c = '1 - 1000';
        ld.Policy_Begin_Timeline__c = 'THIS_WEEK';
        ld.Lead_Source__c = 'Facebook Direct';

        if ( create ) insert ld;

        return ld;
    }

    public static Inspection__c createInspection(Boolean create, String lead_id) {

        Inspection__c inspection = new Inspection__c();

        inspection.Lead__c = lead_id;
        inspection.Inspection_Report_URL__c = 'https://api.hippo.com/gateway/files/link/eyJidWNrZXQiOiJoaXBwby1pbnNwZWN0aW9ucy1kb2N1bWVudHMtcHJvZCIsImtleSI6InRlY2hzZWUvaGlwcG8tZGVtby02MTJlYzA3N2M2YjhmMjA1NTUwMWQ3YmEtYTE4MzRlZjQtZWY1Mi00ODg1LWEwZDEtMTk3Y2NhZGQwNDNhLTIwMjFfMDlfMDFUMDBfMjhfNDMuNTM1Wi56aXAiLCJleHBpcmVzIjoiMTYzMTA2MDk2MiIsInNvdXJjZSI6InNhZmFyaS1zMyJ9';
        inspection.Inspection_Status__c = 'Close-Out';
        inspection.Inspection_Type__c = 'Virtual';
        inspection.Inspection_Provider__c = 'Mueller';

        if ( create ) {

            // avoid DDUP rules during unit tests
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.SaveResult sr = Database.insert(inspection, dml);
            System.debug('inspection sr: ' + sr);
        }

        return inspection;
    }
    
    public static Lead prepareB2BLeadWithAccount(Boolean create, Boolean createAccount) {
        Lead lead = new Lead();
        
        if(createAccount) {
            Account account = new Account();
            account.FirstName = 'prebind first name';
            account.LastName = 'prebind last name';
            account.BillingStreet = 'test street';
            account.BillingCity = 'test city';
            account.BillingState = 'test state';
            account.BillingCountry  = 'United States';
            account.PersonEmail = 'sfdc.prebind@gmail.com';
            account.Phone = '20212345678';
            account.Zipcode__c = 123456;
            insert account;
            
            lead.Account__c = account.Id;
        }
        
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2B Leads', 'Lead');
        lead.RecordTypeId = rtInfo.getRecordTypeId();
        lead.FirstName = 'prebind first name';
        lead.LastName = 'prebind last name';
        lead.Status = 'New';
        lead.Email = 'sfdc.prebind@gmail.com';
        lead.Phone = '20212345678';
        lead.Street = 'test street';
        lead.State = 'test state';
        lead.City = 'test city';
        lead.Country = 'United States';
        lead.Zip_Code__c = '123456';            
        
        if(create)
            insert lead;

        return lead;
    }

    public static Inspection__c prepareInspectionWithGivenLead(Boolean create, Id leadId, Id accountId, String inspectionName ) {
        Inspection__c inspection = new Inspection__c();
        inspection.Lead__c = leadId;
        inspection.Name = inspectionName ;
        inspection.Inspection_Provider__c = 'TechSee';
        if(accountId != null)
            inspection.Account__c = accountId;
        
        if ( create ) {
            // avoid DDUP rules during unit tests
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.SaveResult sr = Database.insert(inspection, dml);
            System.debug('inspection sr: ' + sr);
        }
        return inspection;
    }
    
    public static Lead prepareB2BLeadWithoutAccount(Boolean create) {
        Lead lead = new Lead();
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('B2B Leads', 'Lead');
        lead.RecordTypeId = rtInfo.getRecordTypeId();
        lead.FirstName = 'prebind first name1';
        lead.LastName = 'prebind last name1';
        lead.Status = 'New';
        lead.Email = 'sfdc123.prebind1234@gmail.com';
        lead.Phone = '2021234567';
        lead.Street = 'test street1';
        lead.State = 'test state1';
        lead.City = 'test city1';
        lead.Country = 'United States1';
        lead.Zip_Code__c = '123456';
        
        if(create)
            insert lead;

        return lead;
    }
    
    public static InsurancePolicy createInsurancePolicyWithAccount(Boolean Create ,String accid, String policyName){
        InsurancePolicy inspolicy = new InsurancePolicy();
        inspolicy.Name = policyName;
        inspolicy.NameInsuredId =  accid;
        inspolicy.PolicyType='Home';
        if(Create) {
            // avoid DDUP rules during unit tests
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            Database.SaveResult sr = Database.insert(inspolicy, dml);
        }
        
        return inspolicy;
    }
    
    

    /*
    public static GroupMember addUser2Group(User my_user, String groupDeveloperName) {

        GroupMember grpm = null;

        Group grp = [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName =: groupDeveloperName LIMIT 1];

        if ( null != grp ) {

            grpm = new GroupMember(GroupId = grp.Id, UserOrGroupId = my_user.Id);

            insert grpm;
        }

        return grpm;
    }
     */
}