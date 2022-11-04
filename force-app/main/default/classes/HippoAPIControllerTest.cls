@isTest
public class HippoAPIControllerTest {
    @TestSetup
    static void setup() {

        UnitTestHelper.prepareDevEnvCustomSettings();
        
        Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
        ld.middleName = Utils.getRandomString(5);
        ld.Date_of_Birth__c = System.today();
        ld.industry = 'Education/Library';
        ld.Occupation__c = 'Professor';
        ld.Education__c = 'Bachelors';
        ld.Line_of_Business__c = 'HO3';
        ld.Preferred_Deductibles__c = 1000;
        ld.Effective_Date__c = System.today();

        insert ld;
        
        User user = UnitTestHelper.createuser();
        user.Authorized_States__c = 'CA;FL;MO;OH;TX';
        
        update user;
    }
    
    @IsTest
    static void createQuoteAPITestSuccess() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('success":true', 'Created', 201));

        Lead lead = UnitTestHelper.prepareB2CLead(true, 'MD');

        Profile sysAdminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, sysAdminProfile);

        User sysAdmin_user = UnitTestHelper.createuser(sysAdminProfile.Id);

        Test.startTest();
        HippoAPIController.createQuoteAPI(lead.Id, sysAdmin_user.Id);
        Test.stopTest();
    }

    @IsTest
    static void createQuoteAPITestFail() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('success":false', 'Not Found', 404));

        Lead lead = UnitTestHelper.prepareB2CLead(true, 'MD');

        Profile sysAdminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, sysAdminProfile);

        User sysAdmin_user = UnitTestHelper.createuser(sysAdminProfile.Id);

        Test.startTest();
        try {
            HippoAPIController.createQuoteAPI(lead.Id, sysAdmin_user.Id);
        } catch (AuraHandledException e) {
            System.debug(e.getMessage());
            System.debug(e.getTypeName());
        }
        Test.stopTest();
        
    }

    @IsTest
    static void retrieveQuoteAPISuccess() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('success":true', 'OK', 200));

        Lead lead = UnitTestHelper.prepareB2CLead(true, 'MD');

        Profile sysAdminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, sysAdminProfile);

        User sysAdmin_user = UnitTestHelper.createuser(sysAdminProfile.Id);

        Account acc = UnitTestHelper.prepareAccountFromLead(lead);

        String quoteId = Utils.getRandomString(10);

        Test.startTest();
        HippoAPIController.retrieveQuoteAPI(quoteId, lead.RecordTypeId, sysAdmin_user.Id, acc.Id);
        Test.stopTest();
        
    }

    @IsTest
    static void retrieveQuoteAPIFail() {
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('success":false', 'Not Found', 404));

        Lead lead = UnitTestHelper.prepareB2CLead(true, 'MD');

        Profile sysAdminProfile = [select id from profile where name = 'System Administrator' LIMIT 1];

        System.assertNotEquals(null, sysAdminProfile);

        User sysAdmin_user = UnitTestHelper.createuser(sysAdminProfile.Id);

        Account acc = UnitTestHelper.prepareAccountFromLead(lead);

        String quoteId = Utils.getRandomString(10);

        Test.startTest();
        try {
            HippoAPIController.retrieveQuoteAPI(quoteId, lead.RecordTypeId, sysAdmin_user.Id, acc.Id);
        } catch (AuraHandledException e) {
            System.debug(e.getMessage());
            System.debug(e.getTypeName());
        }
        Test.stopTest();
    }
}