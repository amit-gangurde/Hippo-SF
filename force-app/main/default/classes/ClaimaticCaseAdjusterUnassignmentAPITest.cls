/**
 * Created by jonathanschwartz on 7/29/21.
 */

@isTest(seeAllData = false)
Public class ClaimaticCaseAdjusterUnassignmentAPITest {
    public static testmethod void ClaimaticCaseAdjustorUnassignmentAPI(){
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

        Case cs = new Case();
        cs.AccountId = acc.id;
        cs.Claim_Vendor__c = acc.id;
        cs.POD_Claim_ID__c = '12434';
        cs.POD_Diary_ID__c = '3344';
        insert cs;

        set<id> caseIds = new set<id>();
        caseIds.add(cs.id);

        Test.startTest();
        ClaimaticCaseAdjusterUnassignmentAPI.UnassignAdjustorClaim(caseIds,userinfo.getuserId());

        Test.stopTest();
    }
}