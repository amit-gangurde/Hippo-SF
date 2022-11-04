@IsTest(SeeAllData = false)
public class ClaimaticClaimAssignmentAPITest{

    static String expectedJson = '{' +
        '"claim_number":"${claimNumber}",' +
        '"assignments":[' +
            '{' +
                '"username":"",' +
                '"resource_num":"${userResourceId}",' +
                '"resource_email":"",' +
                '"is_primary":0,' +
                '"assignment_party_id":1' +
            '},{' +
                '"username":"",' +
                '"resource_num":"${vendorResourceId}",' +
                '"resource_email":"",' +
                '"is_primary":0,' +
                '"assignment_party_id":0' +
            '}' +
        ']' +
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

        User u = ClaimaticAPITestUtility.createAdjuster('standt13', 'standarduser23@testorg.com');

        Claim_Vendor__c v = ClaimaticAPITestUtility.createVendor('testVendor');

        ClaimaticAPITestUtility.setupClaim('testclaim', account, u.Id, policy, v, true);
    }
    
    public class AnimalLocatorMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"animal": {"id":1, "name":"Tiger"}}');
        response.setStatusCode(200);
        return response;
    }
    }

   
    public static testMethod void testBasicMethodCallWorks(){
        List<Claim> claims = [SELECT Id FROM Claim];
        List<Id> claimIds = new List<Id>();
        for (Claim c : claims) {
            claimIds.add(c.Id);
        }
        List<User> adjusters = [SELECT Id FROM User WHERE Alias = 'standt13'];
        List<Id> adjusterIds = new List<Id>();
        for (User u : adjusters) {
            adjusterIds.add(u.Id);
        }
        List<Claim_Vendor__c> vendors = [SELECT Id FROM Claim_Vendor__c WHERE Name = 'testVendor'];
        List<Id> vendorIds = new List<Id>();
        for (Claim_Vendor__c v : vendors) {
            vendorIds.add(v.Id);
        }
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMock());
        ClaimaticClaimAssignmentAPI.AssignClaim(claimIds, vendorIds, adjusterIds);
        Test.stopTest();
    }

    @IsTest
    public static void testJsonObjectStructureIsCorrect(){
        Claim claim = [SELECT Id FROM Claim];

        Claim loadedClaim = ClaimaticClaimAssignmentAPI.loadClaimData(claim.Id);

        User user = [SELECT Id FROM User WHERE Alias = 'standt13' LIMIT 1];

        User loadedUser = ClaimaticClaimAssignmentAPI.loadUserData(user.Id);

        Claim_Vendor__c vendor = [SELECT Id FROM Claim_Vendor__c WHERE Name = 'testVendor' LIMIT 1];

        Claim_Vendor__c loadedVendor = ClaimaticClaimAssignmentAPI.loadVendorData(vendor.Id);

        Test.startTest();
        String json = ClaimaticClaimAssignmentAPI.generateJSON(loadedClaim,loadedVendor,loadedUser);
        String replacedExpectedJson = expectedJson.replace('${userResourceId}', loadedUser.Claimatic_Integration_ID__c);
        replacedExpectedJson = replacedExpectedJson.replace('${vendorResourceId}', loadedVendor.Claimatic_Integration_ID__c);
        replacedExpectedJson = replacedExpectedJson.replace('${claimNumber}', loadedClaim.Id);
        System.assertEquals(replacedExpectedJson, json);
        Test.stopTest();
    }
}