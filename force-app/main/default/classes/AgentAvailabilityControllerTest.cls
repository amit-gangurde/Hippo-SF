/**
 * Created by lironkeren on 02/06/2022.
 */

@IsTest
public class AgentAvailabilityControllerTest {

    @testsetup
    public static void testSetup() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));
    }

    @IsTest
    static void testAgentOnlineOnAWS() {

        Profile adminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, adminProfile);

        User admin_user = UnitTestHelper.createuser(adminProfile.Id);
        System.assertNotEquals(null, admin_user);
        System.assertNotEquals(null, admin_user.Id);

        admin_user.Online_On_AWS__c = true;
        admin_user.On_a_Call__c = false;
        update admin_user;

        Id hasInternalReferralsQueueId = Utils.getQueueId('HAS_Internal_Referrals');
        GroupMember grpm = new GroupMember(UserOrGroupId = admin_user.Id, GroupId = hasInternalReferralsQueueId);
        insert grpm;

        test.startTest();

        System.runAs(admin_user) {

            Boolean isAnyAgentAvailable = AgentAvailabilityController.anyAgentAvailable_v2('HAS_Internal_Referrals');
            System.assertEquals(true, isAnyAgentAvailable);
        }

        test.stopTest();
    }

    @IsTest
    static void testAgentOfflineOnAWS() {

        Profile adminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, adminProfile);

        User admin_user = UnitTestHelper.createuser(adminProfile.Id);
        System.assertNotEquals(null, admin_user);
        System.assertNotEquals(null, admin_user.Id);

        admin_user.Online_On_AWS__c = false;
        admin_user.On_a_Call__c = false;
        update admin_user;

        Id hasInternalReferralsQueueId = Utils.getQueueId('HAS_Internal_Referrals');
        GroupMember grpm = new GroupMember(UserOrGroupId = admin_user.Id, GroupId = hasInternalReferralsQueueId);
        insert grpm;

        test.startTest();

        System.runAs(admin_user) {

            Boolean isAnyAgentAvailable = AgentAvailabilityController.anyAgentAvailable_v2('HAS_Internal_Referrals');
            System.assertEquals(false, isAnyAgentAvailable);
        }

        test.stopTest();
    }

    @IsTest
    static void testAgentOnACall() {

        Profile adminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, adminProfile);

        User admin_user = UnitTestHelper.createuser(adminProfile.Id);
        System.assertNotEquals(null, admin_user);
        System.assertNotEquals(null, admin_user.Id);

        admin_user.Online_On_AWS__c = true;
        admin_user.On_a_Call__c = true;
        update admin_user;

        Id hasInternalReferralsQueueId = Utils.getQueueId('HAS_Internal_Referrals');
        GroupMember grpm = new GroupMember(UserOrGroupId = admin_user.Id, GroupId = hasInternalReferralsQueueId);
        insert grpm;

        test.startTest();

        System.runAs(admin_user) {

            Boolean isAnyAgentAvailable = AgentAvailabilityController.anyAgentAvailable_v2('HAS_Internal_Referrals');
            System.assertEquals(false, isAnyAgentAvailable);
        }

        test.stopTest();
    }
}