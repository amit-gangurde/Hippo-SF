@IsTest
public class UnitTestHelperTest {

    @testsetup
    public static void prepareData() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        Account acc1 = UnitTestHelper.prepareDevEnvCustomSettings();
        Account acc2 = UnitTestHelper.prepareAccount();
        Account acc3 = UnitTestHelper.prepareAccount('CA');
        Carrier_Appointment__c ca = UnitTestHelper.prepareCarrierAppointment();
        License__c lic = UnitTestHelper.prepareLicense('ca');
        //Contact con1 = UnitTestHelper.prepareContact('Business');
        Account acc4 = UnitTestHelper.prepareAccountWithContact();
        Account acc5 = UnitTestHelper.prepareAccountWithContact('Business');
        Case cs1 = UnitTestHelper.prepareClaimCase('Fire', 'Topa', 'DFW');
        Case cs2 = UnitTestHelper.prepareClaimCase('Water damage from plumbing, heating, air condition overflow', 'Topa', 'DFW', 'Major');
        Case cs3 = UnitTestHelper.prepareB2CSupportCase('unit test with b2c support case');
        Lead ld1 = UnitTestHelper.prepareB2CLead(false, false);
    }

    @IsTest
    static void testAccountRelated() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        Test.startTest();

        Account acc1 = UnitTestHelper.prepareAccount(true, 'CPSI Test');
        UnitTestHelper.createInsurancePolicy(acc1.id);
        Contact con2 = UnitTestHelper.prepareContact('Business', acc1);

        Test.stopTest();
    }

    @IsTest
    static void testLeadRelated() {

        Test.startTest();

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        Lead ld1 = UnitTestHelper.prepareB2CLead(true, 'MD');
        UnitTestHelper.getEmailMessage(ld1,true);
        UnitTestHelper.getTask(true,Userinfo.getuserId(),ld1.id,null,'Subject');
        Lead ld2 = UnitTestHelper.prepareB2CLead(true, false);
        Lead ld3 = UnitTestHelper.prepareB2CLeadWithAccountName(false, 'HomeLight');
        Account acc = UnitTestHelper.prepareAccountFromLead(ld1);

        User infra_bot = [SELECT Id, Name FROM User WHERE Name = 'Infra Bot' LIMIT 1];

        System.runAs(infra_bot) {

            Lead ld4 = UnitTestHelper.prepareLeadByRecordTypeName(false, 'Web Leads - Producers');
            ld4.State = 'AL';
            insert ld4;
        }

        List<UserServicePresence> availableForLeadsStatusList = [Select Id, UserId from UserServicePresence where /*IsCurrentState = True And */ ServicePresenceStatus.DeveloperName = 'Available_for_Leads'];
        system.debug('availableForLeadsStatusList: ' + availableForLeadsStatusList);

        if (availableForLeadsStatusList.size() > 1) {

            User omni_user = new User(Id = availableForLeadsStatusList[0].UserId);
            system.debug('omni_user' + omni_user);
            // Set the lead owner to the randomly selected omni user
            // so we won't have owner based permission errors when trying to update the lead
            ld1.OwnerId = omni_user.Id;
            update ld1;

            System.runAs(omni_user) {

                List<AgentWork> agentWork = UnitTestHelper.createAgentWorks(new List<Lead>{ ld1 }, omni_user);
                system.debug('agentWok' + agentWork);
            }
        }

        Lead ld5 = UnitTestHelper.prepareNonWorkableB2CLead(true, 'GA');
        Lead ld6 = UnitTestHelper.prepareFacebookDirectLead(false);

        Test.stopTest();
    }

    @IsTest
    static void testMisselenious() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        Test.startTest();

        UnitTestHelper.createuser();
        Profile prof = [select id from profile where name LIKE '%Admin%' LIMIT 1];
        System.assertNotEquals(null, prof);
        UnitTestHelper.createuser(prof.Id);
        UnitTestHelper.creteintegrationdetails();
        UnitTestHelper.prepareLicense();
        UnitTestHelper.prepareContact('Business');
        UnitTestHelper.prepareRetentionCase(false, 'AL');
        UnitTestHelper.prepareTerritoryManagerUserAssignment('AL;AK;FL;GA;KY;MS;NC;SC;TN;VA;WV');
        UnitTestHelper.prepareCampaign('Producer Incentive Campaign', true);

        Account acc_MadSky = UnitTestHelper.prepareAccount(true, 'MadSky');
        Case cs_MadSky = UnitTestHelper.prepareClaimCase('Wind', 'Topa', 'DFW', acc_MadSky);

        System.assertNotEquals(null, cs_MadSky.Id);

        Claim claim1 = UnitTestHelper.prepareClaim('Wind', 'Topa', 'DFW');
        System.assertNotEquals(null, claim1.Id);
        Claim claim2 = UnitTestHelper.prepareClaim('Wind', 'Topa', 'DFW', false);

        Campaign c = UnitTestHelper.prepareCampaign('Producer Incentive Campaign', 'ca', true, false);
        System.assertNotEquals(null, c.Id);

        Lead ld1 = UnitTestHelper.prepareB2CLead(true, 'MD');
        Inspection__c inspection = UnitTestHelper.createInspection(true, ld1.Id);
        System.assertNotEquals(null, inspection.Id);

        Task tsk = UnitTestHelper.getLeadTask(false, ld1.OwnerId, ld1.Id, null, 'testUpdateParentLeads');

        InsurancePolicy ins1 = UnitTestHelper.prepareInsurancePolicyFromLead(ld1, acc_MadSky);
        system.assertNotEquals(null, ins1.Id);

        Claim_Cat_Event__c cce1 = UnitTestHelper.prepareClaimCatEvent('Lightning', 'MD', '12345', System.now().date().addDays(-2), System.now().date(), false);

        Account pa = UnitTestHelper.preparePersonAccount();
        System.assertNotEquals(null, pa.Id);
        InsurancePolicy ins2 = UnitTestHelper.prepareInsurancePolicyFromPersonAccount(pa);

        Id Hippo_Agency_Sales_Q = Utils.getQueueId('Hippo_Agency_Sales');
        Account pa_created = [Select Id, FirstName, MiddleName, LastName, Phone, PersonMailingCity, PersonMailingCountry, PersonMailingState, PersonMailingStreet, PersonMailingPostalCode, PersonEmail, OwnerId From Account WHERE Id =: pa.Id]?.get(0);
        System.assertNotEquals(null, pa_created);
        Lead ld2 = UnitTestHelper.prepareLeadFromPersonAccount(false, pa_created, Hippo_Agency_Sales_Q);

        Test.stopTest();
    }
}