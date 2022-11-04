@isTest(seeAllData = false)
Public class ClaimaticClmAdjustorUnassignmentAPITest{

    static String expectedJson = '{' +
            '"unassignments":[' +
                '{' +
                    '"username":"",' +
                    '"resource_num":"${userResourceId}",' +
                    '"resource_email":"",' +
                    '"is_primary":null,' +
                    '"assignment_party_id":1' +
                '}' +
            '],' +
            '"claim_number":"${claimNumber}"' +
        '}';

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
        List<Claim> Claims = [SELECT Id FROM Claim LIMIT 1];

        List<Id> claimIds = new List<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        User adjuster = [SELECT Id FROM User WHERE Alias = 'standt13' LIMIT 1];
        List<Id> adjusterIds = new List<Id>();
        adjusterIds.add(adjuster.Id);
        Test.startTest();
        ClaimaticClaimAdjustorUnassignmentAPI.UnassignAdjustorClaim(claimIds,adjusterIds);

        Test.stopTest();
    }

    @IsTest
    public static void testJsonObjectStructureIsCorrect(){
        List<Claim> Claims = [SELECT Id FROM Claim LIMIT 1];
        List<Id> claimIds = new List<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }
        List<Claim> loadedClaims = ClaimaticClaimAdjustorUnassignmentAPI.loadClaimData(claimIds);
        User user = [SELECT Id FROM User WHERE Alias = 'standt13' LIMIT 1];

        User loadedUser = ClaimaticClaimAdjustorUnassignmentAPI.loadUserData(user.Id);

        Test.startTest();
        String json = ClaimaticClaimAdjustorUnassignmentAPI.generateJSON(loadedClaims.get(0),loadedUser);
        String replacedExpectedJson = expectedJson.replace('${userResourceId}', loadedUser.Claimatic_Integration_ID__c);
        replacedExpectedJson = replacedExpectedJson.replace('${claimNumber}', loadedClaims.get(0).Id);
        System.assertEquals(replacedExpectedJson, json);
        Test.stopTest();
    }
}