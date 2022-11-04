/**
 * Created by lironkeren on 29/05/2022.
 */
@IsTest
public class CTIFlowActionsTest {

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

        test.startTest();

        System.runAs(admin_user) {

            CTIFlowActions.setAgentOnlineOnAWS();
        }

        test.stopTest();

        admin_user = [SELECT Id, Online_On_AWS__c FROM User WHERE Id =: admin_user.Id LIMIT 1];
        System.assertEquals(true, admin_user.Online_On_AWS__c);
    }

    @IsTest
    static void testAgentOfflineOnAWS() {

        Profile adminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, adminProfile);

        User admin_user = UnitTestHelper.createuser(adminProfile.Id);
        System.assertNotEquals(null, admin_user);
        System.assertNotEquals(null, admin_user.Id);

        admin_user.Online_On_AWS__c = true;
        update admin_user;

        test.startTest();

        System.runAs(admin_user) {

            CTIFlowActions.setAgentOfflineOnAWS();
        }

        test.stopTest();

        admin_user = [SELECT Id, Online_On_AWS__c FROM User WHERE Id =: admin_user.Id LIMIT 1];
        System.assertEquals(false, admin_user.Online_On_AWS__c);
    }

    @IsTest
    static void testAgentOnACall() {

        Profile adminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, adminProfile);

        User admin_user = UnitTestHelper.createuser(adminProfile.Id);
        System.assertNotEquals(null, admin_user);
        System.assertNotEquals(null, admin_user.Id);

        test.startTest();

        System.runAs(admin_user) {

            CTIFlowActions.setAgentOnVoiceCall();
        }

        test.stopTest();

        admin_user = [SELECT Id, On_a_Call__c FROM User WHERE Id =: admin_user.Id LIMIT 1];
        System.assertEquals(true, admin_user.On_a_Call__c);
    }

    @IsTest
    static void testAgentNotOnACall() {

        Profile adminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, adminProfile);

        User admin_user = UnitTestHelper.createuser(adminProfile.Id);
        System.assertNotEquals(null, admin_user);
        System.assertNotEquals(null, admin_user.Id);

        admin_user.On_a_Call__c = true;
        update admin_user;

        test.startTest();

        System.runAs(admin_user) {

            CTIFlowActions.setAgentNotOnVoiceCall();
        }

        test.stopTest();

        admin_user = [SELECT Id, On_a_Call__c FROM User WHERE Id =: admin_user.Id LIMIT 1];
        System.assertEquals(false, admin_user.On_a_Call__c);
    }
}