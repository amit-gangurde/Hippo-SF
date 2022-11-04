@IsTest
public class ClaimaticRESTServiceTest{

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

        ClaimaticAPITestUtility.createAdminAdjuster('standt13', 'standarduser23@testorg.com');

        ClaimaticAPITestUtility.createVendor('testVendor');

        ClaimaticAPITestUtility.setupClaim('testclaim', account, null, policy, null, true);
        
        case cs = new case();
        cs.City__c = 'Texas';
        cs.Date_of_Loss__c = system.today(); 
        cs.CATCode__c = '1234';
        cs.Insurance_Policy__c = policy.id;
        insert cs;
    }

    @IsTest
    static void ClaimaticRESTService() {
        Test.startTest();

        Claim c1 = [SELECT Id,Name,Claim_Vendor__c,Claim_Adjuster__c FROM Claim LIMIT 1];
        Claim_Vendor__c v = [SELECT Id,Claimatic_Integration_ID__c FROM Claim_Vendor__c WHERE Name = 'testVendor' LIMIT 1];
        User u = [SELECT Id,Claimatic_Integration_ID__c FROM User u WHERE Alias = 'standt13' LIMIT 1];
        String requestxml ='<CLAIMATIC><ADM><CLAIMS><CLAIM claimNumber="'+c1.Id+'" ><RESOURCES><RESOURCE id="'+v.Claimatic_Integration_ID__c+'" username="pcouch" type="Vendor Partners" position="Internal" ></RESOURCE></RESOURCES></CLAIM></CLAIMS></ADM></CLAIMATIC>';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/UpdateClaim/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        req.requestBody= Blob.valueOf(requestxml);
        RestContext.response= res;
        ClaimaticRESTService.doPost();

        String requestxml1 ='<CLAIMATIC><ADM><CLAIMS><CLAIM claimNumber="'+c1.Id+'" ><RESOURCES><RESOURCE id="'+u.Claimatic_Integration_ID__c+'" username="pcouch" type="Desk Adjuster" position="Internal" ></RESOURCE></RESOURCES></CLAIM></CLAIMS></ADM></CLAIMATIC>';
        RestRequest req1 = new RestRequest();
        RestResponse res1 = new RestResponse();
        req1.requestURI = '/services/apexrest/UpdateClaim/';
        req1.httpMethod = 'POST';
        RestContext.request = req1;
        req1.requestBody= Blob.valueOf(requestxml1);
        RestContext.response= res1;
        ClaimaticRESTService.doPost();
        Test.stopTest();
    }
    
    @IsTest
    static void ClaimaticRESTService1() {
        Test.startTest();

        
        Claim c1 = [SELECT Id,Name,Claim_Vendor__c,Claim_Adjuster__c FROM Claim LIMIT 1];
        Claim_Vendor__c v = [SELECT Id,Claimatic_Integration_ID__c FROM Claim_Vendor__c WHERE Name = 'testVendor' LIMIT 1];
        User u = [SELECT Id,Claimatic_Integration_ID__c FROM User u WHERE Alias = 'standt13' LIMIT 1];
        String requestxml ='<CLAIMATIC><ADM><CLAIMS><CLAIM claimNumber="'+c1.Id+'" ><RESOURCES><RESOURCE id="'+v.Claimatic_Integration_ID__c+'" username="pcouch" type="Vendor Partners" position="Internal" ></RESOURCE></RESOURCES></CLAIM></CLAIMS></ADM></CLAIMATIC>';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/UpdateClaim/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        req.requestBody= Blob.valueOf(requestxml);
        RestContext.response= res;
        ClaimaticRESTService.doPost();

        Case cs = [SELECT Id FROM Case LIMIT 1];
        String requestxml1 ='<CLAIMATIC><ADM><CLAIMS><CLAIM claimNumber="'+cs.Id+'" ><RESOURCES><RESOURCE id="'+u.Claimatic_Integration_ID__c+'" username="pcouch" type="Desk Adjuster" position="Internal" ></RESOURCE></RESOURCES></CLAIM></CLAIMS></ADM></CLAIMATIC>';
        RestRequest req1 = new RestRequest();
        RestResponse res1 = new RestResponse();
        req1.requestURI = '/services/apexrest/UpdateClaim/';
        req1.httpMethod = 'POST';
        RestContext.request = req1;
        req1.requestBody= Blob.valueOf(requestxml1);
        RestContext.response= res1;
        ClaimaticRESTService.doPost();
        Test.stopTest();
        
    }
}