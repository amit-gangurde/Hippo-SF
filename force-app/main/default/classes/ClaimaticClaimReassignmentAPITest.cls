@IsTest(SeeAllData = false)
public class ClaimaticClaimReassignmentAPITest{

    static String expectedJson = '{' +
        '"claim_number":"${ClaimNumber}",' +
        '"assignments":[' +
            '{' +
                '"username":"",' +
                '"to_remove_resource_username":"",' +
                '"to_remove_resource_num":"${OldVendorId}",' +
                '"to_remove_resource_id":"${OldVendorId}",' +
                '"to_remove_resource_email":"",' +
                '"resource_num":"${NewVendorId}",' +
                '"resource_id":"${NewVendorId}",' +
                '"resource_email":"",' +
                '"is_primary":1,' +
                '"assignment_party_id":1' +
            '}' +
        ']' +
    '}';

    static String expectedJson2 = '{' +
        '"claim_number":"${ClaimNumber}",' +
        '"assignments":[' +
            '{' +
                '"username":"",' +
                '"to_remove_resource_username":"",' +
                '"to_remove_resource_num":"${OldAdjusterId}",' +
                '"to_remove_resource_id":"${OldAdjusterId}",' +
                '"to_remove_resource_email":"",' +
                '"resource_num":"${NewAdjusterId}",' +
                '"resource_id":"${NewAdjusterId}",' +
                '"resource_email":"",' +
                '"is_primary":1,' +
                '"assignment_party_id":1' +
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
        //Account account2 = ClaimaticAPITestUtility.setupAccount('testaccount2');

        InsurancePolicy policy = ClaimaticAPITestUtility.setupPolicy(account, 'testpolicy', false);
        //InsurancePolicy policy2 = ClaimaticAPITestUtility.setupPolicy(account2, 'testpolicy2', false);

        User u = ClaimaticAPITestUtility.createAdminAdjuster('standt13', 'standarduser23@testorg.com');
        ClaimaticAPITestUtility.createAdminAdjuster('standt14', 'standarduser24@testorg.com');

        Claim_Vendor__c v = ClaimaticAPITestUtility.createVendor('testVendor');
        ClaimaticAPITestUtility.createVendor('testVendor2');

        ClaimaticAPITestUtility.setupClaim('testclaim', account, u.Id, policy, v, true);

    }

    @IsTest
    public static void testBasicMethodCallWorks(){
        Test.startTest();
        Account account2 = ClaimaticAPITestUtility.setupAccount('testaccount2');
        InsurancePolicy policy2 = ClaimaticAPITestUtility.setupPolicy(account2, 'testpolicy2', false);

           User u = ClaimaticAPITestUtility.createAdminAdjuster('stdt134', 'standarduser234@testorg.com');
        Claim_Vendor__c v = ClaimaticAPITestUtility.createVendor('testVendor1');

        //Account account2

        ClaimaticAPITestUtility.setupClaim('testclaim2', account2, u.Id, policy2, v, true);
        List<Claim> claims = [SELECT Id,Claim_Vendor__c,Claim_Adjuster__c FROM Claim ];
        system.debug('@@claims 22'+claims );

        Map<Id, String> oldClaimsMap = new Map<Id, String>();
        for(Claim oldClaim : claims) {
            oldClaimsMap.put(oldClaim.Id, JSON.serialize(oldClaim));
        }

        User newAdjuster = [SELECT Id FROM User WHERE Alias = 'standt14' LIMIT 1];

        Claim_Vendor__c newVendor = [SELECT Id FROM Claim_Vendor__c WHERE Name = 'testVendor2'];
        Set<Id> claimIds = new Set<Id>();
        for(Claim claim : claims) {
            claimIds.add(claim.Id);
            claim.Claim_Adjuster__c = newAdjuster.Id;
            claim.Claim_Vendor__c = newVendor.Id;
        }
        //update claims;

        ClaimaticClaimReassignmentAPI.ReassignClaim(oldClaimsMap,claimIds,'Adjuster');
        ClaimaticClaimReassignmentAPI.ReassignClaim(oldClaimsMap,claimIds,'Vendor');
        Test.stopTest();
    }

    @IsTest
    public static void testJsonObjectStructureIsCorrect(){
        
        List<Claim> claims = [SELECT Id,Claim_Vendor__c,Claim_Adjuster__c FROM Claim ];
        system.debug('@@claims 11'+claims );
        Map<Id, String> oldClaimsMap = new Map<Id, String>();
        for(Claim oldClaim : claims) {
            oldClaimsMap.put(oldClaim.Id, JSON.serialize(oldClaim));
        }

        User oldAdjuster = [SELECT Id,Claimatic_Integration_ID__c FROM User WHERE Alias = 'standt13' LIMIT 1];
        User newAdjuster = [SELECT Id FROM User WHERE Alias = 'standt14' LIMIT 1];

        Claim_Vendor__c oldVendor = [SELECT Id,Claimatic_Integration_ID__c FROM Claim_Vendor__c WHERE Name = 'testVendor'];
        Claim_Vendor__c newVendor = [SELECT Id FROM Claim_Vendor__c WHERE Name = 'testVendor2'];
        Set<Id> claimIds = new Set<Id>();
        for(Claim claim : claims) {
            system.debug('@@claim '+claim );
            claimIds.add(claim.Id);
            claim.Claim_Adjuster__c = newAdjuster.Id;
            claim.Claim_Vendor__c = newVendor.Id;
        }
        Test.startTest();
            update claims;
        
        List<Claim> loadedClaims = ClaimaticClaimReassignmentAPI.loadClaimData(claimIds);
		System.debug('==loadedClaims=='+loadedClaims);
        List<Claim> loadedOldClaims = ClaimaticClaimReassignmentAPI.loadOldClaimData(oldClaimsMap, loadedClaims);
System.debug('==loadedOldClaims=='+loadedOldClaims);

        String json = ClaimaticClaimReassignmentAPI.generateJSON(loadedOldClaims[0],loadedClaims[0],'Vendor');
        String replacedExpectedJson = expectedJson.replace('${ClaimNumber}', loadedClaims[0].Id);
        replacedExpectedJson = replacedExpectedJson.replace('${OldVendorId}', oldVendor.Claimatic_Integration_ID__c);
        replacedExpectedJson = replacedExpectedJson.replace('${NewVendorId}', loadedClaims[0].Claim_Vendor__r.Claimatic_Integration_ID__c);
        System.assertEquals(replacedExpectedJson, json);

        String json2 = ClaimaticClaimReassignmentAPI.generateJSON(loadedOldClaims[0],loadedClaims[0],'Adjuster');
        String replacedExpectedJson2 = expectedJson2.replace('${ClaimNumber}', loadedClaims[0].Id);
        replacedExpectedJson2 = replacedExpectedJson2.replace('${OldAdjusterId}', oldAdjuster.Claimatic_Integration_ID__c);
        replacedExpectedJson2 = replacedExpectedJson2.replace('${NewAdjusterId}', loadedClaims[0].Claim_Adjuster__r.Claimatic_Integration_ID__c);
        System.assertEquals(replacedExpectedJson2, json2);
        Test.stopTest();

    }
}