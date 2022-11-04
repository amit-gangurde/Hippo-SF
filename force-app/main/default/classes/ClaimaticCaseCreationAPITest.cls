/**
 * Created by jonathanschwartz on 7/29/21.
 */

@isTest(seeAllData = false)
Public class ClaimaticCaseCreationAPITest{
    public static testmethod void ClaimaticClaimCreationAPI(){
          // Set mock callout class 

        String domain = 'test_domain.lang.ai';
        String token = 'test_token';
        String project_id = 'test_project_id';
        String text = 'the text we will test with';
        List<String> tagNames = new List<String>{'Tag 1', 'Tag 2'};
        Test.setMock(HttpCalloutMock.class, new LangHttpCalloutMock(domain, token, project_id, text, tagNames));
        
        LangClient client = new LangClient(domain ,token, project_id);
        List<String> tags = client.analyze(text);
        
        Integration__c integ = new Integration__c();
        integ.Auth_URL__c = 'https://www.authurl.com';
        integ.MultiClaim_Status_Update_URL__c = 'https://test.com';
        integ.Multiclaim_URL__c = 'https://test.com';
        integ.Password__c = 'password';
        integ.Reassign_Claim_URL__c = 'http://test.com';
        integ.Unassign_Claim_URL__c = 'http://test.com';
        integ.Username__c = 'username';
        insert integ;

        Account acc = new Account();
        acc.LastName = 'test';
        acc.RecordTypeId = '0126g000001JEVB';
        acc.PersonEmail = 'acc@Gmail.com';
        acc.Resource_Username__c = 'test';
        acc.Resource_Number__c = 'w453';
        insert acc;

        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.id;
        ins.Name = 'test';
        insert ins;
        string ClaimRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Claim').getRecordTypeId();
        Case cs = new Case();
        cs.AccountId = acc.id;
        cs.Claim_Vendor__c = acc.id;
        cs.POD_Claim_ID__c = '12434';
        cs.POD_Diary_ID__c = '3344';
        cs.Claims_Adjuster__c = userinfo.getUserId();
        cs.Claims_Agreement__c = 'Agree'; // added in 11/17/2021 6:11 pm
        cs.Date_of_Loss__c = system.today();
        cs.CATCode__c = '1234';
        cs.Insurance_Policy__c = ins.id;
        cs.Have_a_Contractor__c = true;
        cs.RecordTypeId = ClaimRecId;

        set<id> caseIds = new set<id>();
        caseIds.add(cs.id);

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt13', Email='standarduser12@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser23@testorg.com');

        insert u;

        Account acc1 = new Account();
        acc1.LastName = 'test';
        acc1.RecordTypeId = '0126g000001JEVB';
        acc1.PersonEmail = 'acc1@Gmail.com';
        acc1.Resource_Username__c = 'test1';
        acc1.Resource_Number__c = 'w4531';
        insert acc1;


        Test.startTest();
        insert cs;
        Test.stopTest();
    }
}