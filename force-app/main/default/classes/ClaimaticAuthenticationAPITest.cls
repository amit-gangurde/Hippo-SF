@isTest(seeAllData = false)
Public class ClaimaticAuthenticationAPITest{
    public static testmethod void ClaimaticAuthenticationAPI(){
        Integration__c integ = new Integration__c();
        integ.Auth_URL__c = 'https://www.authurl.com';
        integ.MultiClaim_Status_Update_URL__c = 'https://test.com';
        integ.Multiclaim_URL__c = 'https://test.com';
        integ.Password__c = 'password';
        integ.Reassign_Claim_URL__c = 'http://test.com';
        integ.Unassign_Claim_URL__c = 'http://test.com';
        integ.Username__c = 'username';
        insert integ;
        Test.startTest();
            ClaimaticAuthenticationAPI.AuthenticationService();  
            ClaimaticAuthenticationAPIResponse ctrl = new ClaimaticAuthenticationAPIResponse();          
            ctrl.token = 'token';
            ctrl.email = 'mail';
        Test.stopTest();
    }
}