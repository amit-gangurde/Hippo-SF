@IsTest(SeeAllData = false)
public class ClaimaticClaimUnassignmentAPITest{

    static String expectedJson = '{' +
        '"unassignments":[' +
            '{' +
                '"username":"",' +
                '"resource_num":"${VendorId}",' +
                '"resource_email":"${VendorEmail}",' +
                '"is_primary":0,' +
                '"assignment_party_id":0' +
            '}' +
        '],' +
        '"claim_number":"${ClaimNumber}"' +
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

        Claim_Vendor__c v = ClaimaticAPITestUtility.createVendor('testVendor');

        ClaimaticAPITestUtility.setupClaim('testclaim', account, u.Id, policy, v, true);
    }

    @IsTest
    public static void testBasicMethodCallWorks(){
        List<Claim> Claims = [SELECT Id FROM Claim];

        List<Id> claimIds = new List<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        Claim_Vendor__c vendor = [SELECT Id FROM Claim_Vendor__c WHERE Name = 'testVendor' LIMIT 1];
        List<Id> vendorIds = new List<Id>();
        vendorIds.add(vendor.Id);
        Test.startTest();
        ClaimaticClaimUnassignmentAPI.UnassignClaim(claimIds,vendorIds);

        Test.stopTest();
    }

    @IsTest
    public static void testJsonObjectStructureIsCorrect(){
        List<Claim> Claims = [SELECT Id FROM Claim];
        List<Id> claimIds = new List<Id>();
        
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        List<Claim> loadedClaims = ClaimaticClaimUnassignmentAPI.loadClaimData(claimIds);
        Claim_Vendor__c vendor = [SELECT Id FROM Claim_Vendor__c WHERE Name = 'testVendor' LIMIT 1];

        Claim_Vendor__c loadedVendor = ClaimaticClaimUnassignmentAPI.loadVendorData(vendor.Id);

        Test.startTest();
        String json = ClaimaticClaimUnassignmentAPI.generateJSON(loadedClaims.get(0),loadedVendor);
        String replacedExpectedJson = expectedJson.replace('${VendorId}', loadedVendor.Claimatic_Integration_ID__c);
        replacedExpectedJson = replacedExpectedJson.replace('${VendorEmail}', loadedVendor.Contact_Email__c);
        replacedExpectedJson = replacedExpectedJson.replace('${ClaimNumber}', loadedClaims.get(0).Id);
        System.assertEquals(replacedExpectedJson, json);
        Test.stopTest();
    }
}