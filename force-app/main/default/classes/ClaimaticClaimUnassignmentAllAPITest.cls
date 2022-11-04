@IsTest(seeAllData = false)
public class ClaimaticClaimUnassignmentAllAPITest{

    static String expectedJson = '{"claim_number": "${ClaimNumber}"}';

    @TestSetup
    public static void SetupClaimaticTestData() {
        Integration__c integ = new Integration__c();
        integ.Auth_URL__c = 'https://www.authurl.com';
        integ.MultiClaim_Status_Update_URL__c = 'https://test.com';
        integ.Multiclaim_URL__c = 'https://test.com';
        integ.Password__c = 'password';
        integ.Reassign_Claim_URL__c = 'http://test.com';
        integ.Unassign_Claim_URL__c = 'http://test.com';
        integ.Username__c = 'username';
        insert integ;

        Account account = ClaimaticAPITestUtility.setupAccount('testaccount');

        InsurancePolicy policy = ClaimaticAPITestUtility.setupPolicy(account, 'testpolicy', false);

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt13', Email='standarduser12@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', Username='standarduser23@testorg.com');

        insert u;

        ClaimaticAPITestUtility.setupClaim('testclaim', account, u.Id, policy, null, true);
    }

    @IsTest
    public static void testBasicMethodCallWorks(){
        List<Claim> Claims = [SELECT Id FROM Claim];

        Set<Id> claimIds = new Set<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        Test.startTest();
        ClaimaticClaimUnassignmentAllAPI.UnassignAllClaim(claimIds);

        Test.stopTest();
    }

    @IsTest
    public static void testJsonObjectStructureIsCorrect(){
        List<Claim> Claims = [SELECT Id FROM Claim];

        Test.startTest();
        String json = ClaimaticClaimUnassignmentAllAPI.generateJSON(Claims.get(0).Id);
        String replacedExpectedJson = expectedJson.replace('${ClaimNumber}', Claims.get(0).Id);
        System.assertEquals(replacedExpectedJson, json);
        Test.stopTest();
    }
}