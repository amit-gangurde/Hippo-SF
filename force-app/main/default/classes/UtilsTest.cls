@isTest
public class UtilsTest {

    static Account acc = null;

    private static void prepareData() {

        UnitTestHelper.prepareDevEnvCustomSettings();
        acc = UnitTestHelper.prepareAccount();
    }

    @isTest static void test_Utils() {

        prepareData();

        test.startTest();

        Utils.getFieldNamesForSObjectName('Account');
        Utils.buildJoinStringsForSObject('Account');
        Utils.readFieldSet('FSC_Banker_Profile_Fin_Acct_Summary', 'Account');
        RecordTypeInfo caseRecordTypeInfo = Utils.getRecordTypeInfo('Claim', 'Case');
        caseRecordTypeInfo = Utils.getRecordTypeInfo('Claim', 'Case');
        Map<Id, Schema.RecordTypeInfo> recordTypes = Utils.getRecordTypes('Case');
        Utils.getRecordTypeInfo(caseRecordTypeInfo.getRecordTypeId(), Case.getSObjectType().getDescribe().getName());
        Utils.getBooleanFieldValue('Account', acc.Id, 'PersonDoNotCall');

        //Case cs = UnitTestHelper.prepareClaimCase('Lightning', 'Topa', 'DFW');
        //X3rd_Party_Adjuster_Emails__c x3rdPartyAdjusterEmail_cs = X3rd_Party_Adjuster_Emails__c.getInstance('Westhill');
        //Utils.sendEmail(new Set<Id>{cs.Id}, new List<String>{x3rdPartyAdjusterEmail_cs.Email__c});

        Case cs = UnitTestHelper.prepareB2CSupportCase('Support Ticket');
        String objectName = Utils.findObjectNameFromRecordIdPrefix(cs.Id);
        Id queue_id = Utils.getQueueId('Fire');

        String value = Utils.getHippoSettings('Omni Lead Queue Developer Name');
        System.assertNotEquals(null, value);

        Map<String, Utils.StateInfo> states2CoastMap = Utils.getStates2StateInfo();
        //System.assert(states2CoastMap.size() > 0); // EMPTY IN PRODUCTION ?!
        Map<String, Utils.LeadMapping> leadQueuesMap = Utils.getLeadQueuesMapping();
        System.assert(leadQueuesMap.size() > 0);
        Map<String, Utils.LeadMapping> leadQueuesMapByUTMSource = Utils.getLeadQueuesMappingByUTMSource();
        System.assert(leadQueuesMapByUTMSource.size() > 0);

        User_Assignment__c ua = UnitTestHelper.prepareTerritoryManagerUserAssignment('AL;AK;FL;GA;KY;MS;NC;SC;TN;VA;WV');
        Map<String, Id> map_State2TerritoryManagerOwnerId = Utils.getTerritoryManagersByState();
        System.assert(map_State2TerritoryManagerOwnerId.keySet().size() > 0);

        Boolean res1 = Utils.isWithinEST(System.now());
        Boolean res2 = Utils.isWithinPST(System.now());

        Boolean isSandbox = Utils.isSandboxInstance();
        List<Lead_Score__mdt> lead_scores = Utils.getLeadScores();
        Map<String, Boolean> toggledOffLeadScores = Utils.getToggledOffLeadScores();
        List<UserServicePresence > usp = Utils.getAvailableOmniChannelAgents();
        Boolean isAPIUser = Utils.isCurrentUserAPI();

        Claim clm = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW');
        String payload2 = Utils.getMadSkyClaimPayload(clm);

        Map<String, Set<Id>> map_Group2ActiveUsers = Utils.groupDeveloperNameAndTypeToActiveUserIds;

        Lead ld = UnitTestHelper.prepareB2CLead(true, 'MD');
        System.assertNotEquals(null, ld.Id);
        List<Lead> lstLeads = [SELECT Id, Name, Organization__c, Organization__r.Name, CreatedDate, OwnerId FROM Lead WHERE Id =: ld.Id];
        System.assertNotEquals(0, lstLeads.size());
        Task tsk = Utils.getLeadRenewedInterestTask(lstLeads[0], lstLeads[0], 'description');
        String notificationBody = Utils.getLeadDupNotificationBody(lstLeads[0], lstLeads[0]);

        Utils.LeadState leadState = Utils.isLeadWithinBusinessHours(lstLeads[0]);

        Utils.HippoUserInfo hippoUserInfo = Utils.getHippoUserInContext();

        Set<String> nonJVRecordTypes = Utils.getLeadNonJVRecordTypes();

        test.stopTest();
    }

    @IsTest
    public static void test_Send2MadSkyUtils() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Account acc = UnitTestHelper.prepareAccount(true, 'MadSky');
        System.assertNotEquals(null, acc.Id);

        test.startTest();

        Case cs1 = UnitTestHelper.prepareClaimCase('Wind', 'Topa', 'DFW', acc);
        System.assertNotEquals(null, cs1.Id);

        Case cs2 = UnitTestHelper.prepareClaimCase('Hail', 'Topa', 'DFW', acc);
        System.assertNotEquals(null, cs2.Id);

        Test.getEventBus().deliver();

        test.stopTest();

        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('MadSky', 'Callout__c');

        List<Callout__c> call1 = [SELECT Id, RecordTypeId, Status__c FROM Callout__c WHERE Case__c =: cs1.Id AND RecordTypeId =: rtInfo.getRecordTypeId()];
        System.assertEquals(1, call1.size());
        System.assertEquals('OK', call1[0].Status__c);

        List<Callout__c> call2 = [SELECT Id, RecordTypeId, Status__c FROM Callout__c WHERE Case__c =: cs2.Id AND RecordTypeId =: rtInfo.getRecordTypeId()];
        System.assertEquals(1, call2.size());
        System.assertEquals('OK', call2[0].Status__c);
    }
}