@isTest
public class CallUnassignAllUsersCtrlTest {
    public static testMethod void testSingleSplitController()
    {
        //Insert User
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        /*UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
insert r;*/
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason.liveston@scnsoft.com',
                            Username = 'jason.liveston@scnsoft.com',
                            ProfileId = profileId.id,
                            //UserRoleId = r.Id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'                            
                           );
        insert usr;
        
        //Insert Account
        Account acc = new Account();
        acc.LastName = 'test';
        acc.RecordTypeId = '0126g000001JEVB';
        acc.PersonEmail = 'acc@Gmail.com';
        acc.Resource_Username__c = 'test';
        acc.Resource_Number__c = 'w453';
        insert acc;
        
        //Insert case
        string ClaimRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Claim').getRecordTypeId();
        Case cs = new Case();
        cs.AccountId = acc.id;
        //cs.Claim_Vendor__c = acc.id;
        cs.POD_Claim_ID__c = '12434';
        cs.POD_Diary_ID__c = '3344';
        //cs.Claims_Adjuster__c = userinfo.getUserId();
        cs.Date_of_Loss__c = system.today();
        cs.CATCode__c = '1234';        
        cs.Have_a_Contractor__c = true;        
        cs.RecordTypeId = ClaimRecId;
        cs.status = 'New';
        cs.Claims_Adjuster__c = userinfo.getUserId();
        cs.Sent_to_Claimatic__c = true;
        insert cs;
        
        Test.startTest();        
        
        Apexpages.StandardController sc = new Apexpages.StandardController(cs);
        CallUnassignAllUsersCtrl ctrl = new CallUnassignAllUsersCtrl(sc);             
        ctrl.callUnassignAdjustor();        
        ctrl.callUnassignAll();     
        ctrl.callUnassignAllUserNoResponse();
        ctrl.callUnassignVendor();         
        
        Test.stopTest();
    }
}