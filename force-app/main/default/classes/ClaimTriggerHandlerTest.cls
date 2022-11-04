@isTest
public class ClaimTriggerHandlerTest {
    
    @testSetup
    public static void testSetup(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        //User user = [Select Id, Name FROM User WHERE Id = :userInfo.getUserId()];
		User u = new User(Alias = 'TestAls', Email='standarduser13@hippo.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', Username='Testuser13@hippo.com');
        insert u;
        
        Account acc = new Account();
        acc.FirstName= 'Test Account';
        acc.LastName='Account';
        acc.RecordTypeId='0126g000001JEVB';
        acc.PersonEmail='Testacc@gmail.com';
        acc.PersonMailingStreet='13487 femptown drive';
        acc.PersonMailingCity = 'femperton';
        acc.PersonMailingState = 'CA';
        acc.PersonMailingPostalCode = '12345';
        acc.PersonMailingCountry = 'US';
        acc.Resource_Username__c = 'test1';
        acc.Resource_Number__c = 'w453';
        acc.Phone = '1234567890';
        acc.PersonMobilePhone = '0987654321';
        acc.PersonOtherPhone = '5432109876';
        insert acc;
        Claim_Cat_Event__c cce1 = UnitTestHelper.prepareClaimCatEvent('Lightning', 'TN', '642001', System.now().date().addDays(-2), System.now().date(), true);
        Claim_Vendor__c vendor = new Claim_Vendor__c();
        vendor.Name = 'Test Vendor';
        vendor.Contact_Email__c = 'vendor@gmail.com';
        vendor.Category__c = 'Remediation';
        vendor.Country__c = 'US';
        vendor.Contact_Phone__c ='1234567890';
        vendor.Claimatic_Integration_ID__c='5555500000Test';
        insert vendor;
        
        InsurancePolicy policy = new InsurancePolicy();
        policy.Status = 'Active';
        policy.Effective_Date__c = Date.newInstance(2021,8,1);
        policy.ExpirationDate = Date.newInstance(2022, 7, 30);
        policy.Name = 'Test Policy';
        policy.NameInsuredId = acc.Id;
        policy.State__c = 'TN';
        policy.Zip__c = '642001';
        Insert policy;
        
        Claim claimObj = new Claim();
        claimObj.Name ='Test Claim123';
        claimObj.Policy_Service_Integration__c = true;
        claimObj.Claim_Vendor__c = vendor.Id;
        claimObj.Claim_Adjuster__c = u.Id;
        claimObj.Date_of_Loss__c = Date.newInstance(2021,11,1);
        claimObj.Claim_Agreement__c = 'Agree';
        claimObj.AccountId = acc.Id;
        claimObj.PolicyNumber = policy;
        claimObj.PolicyNumberId = policy.Id;
        claimObj.Have_a_Contractor__c = true;
        claimObj.Peril__c = 'Wind';
        claimObj.Loss_Description__c ='test loss description';
        claimObj.Mitigation_Needed__c ='Yes';
        claimObj.Damage_Level__c = 'High';
        claimObj.Damage_Description__c ='test damage description';
        claimObj.Are_repairs_required__c ='No';
        claimObj.Temporary_Housing_Required__c='Find my own';
        claimObj.Zip__c = '642001';
        //claimObj.Claim_Number__c ='1234';
        Insert claimObj;
             
        ClaimParticipant claimP = new ClaimParticipant();
        claimP.ClaimId = claimObj.Id;
        claimP.First_Name__c = 'Test';
        claimP.Last_Name__c ='Participant';
        claimP.Email__c= 'test@gmail.com';
        claimP.MobilePhone__c= '123456789';
        claimP.Zip_Code__c = '423124';
        claimP.Roles='Primary Insured';
        Insert claimP;
        
        Claim_Deductible__c deductible = new Claim_Deductible__c();
          deductible.Claim__c =claimObj.Id;
        deductible.Name = 'Test deductible';
        deductible.Deductible_Amount__c = 10.00;
        insert deductible;
         
        
    }
	@isTest
	 public static void loadClaimDataForRoutingTest(){
        Claim claim = [Select Id, Name,Policy_Service_Integration__c,Claim_Vendor__c,Claim_Adjuster__c,Date_of_Loss__c
                          from Claim Limit 1];
        List<Id> claimIds = new List<Id>();
        claimIds.add(claim.Id);
        
        List<Claim> result = ClaimTriggerHandler.loadClaimDataForRouting(claimIds);
        system.assertEquals(claim.Id, result[0].Id);
        
     }
    
    /*@isTest
    public static void claimNeedsCoverageUpdateTest(){
        Claim c = [Select Id, Name from Claim Limit 1];
        Boolean result = ClaimTriggerHandler.claimNeedsCoverageUpdate(c);
        system.debug('claimNeedsCoverageUpdate? =='+result);
    }*/
    
    @isTest
    public static void loadClaimDataTest(){
        Claim c = [Select Id, Name from Claim Limit 2];
        List<Id> claimIds = new List<Id>();
        claimIds.add(c.Id);
        ClaimTriggerHandler.loadClaimData(claimIds);
    }

    @isTest
    public static void sendToThirdPartyVendorTest(){
        Claim c = [Select Id, Name from Claim Limit 2];
        List<Id> claimIds = new List<Id>();
        claimIds.add(c.Id);
        
        ClaimTriggerHandler.sendToThirdPartyVendor(claimIds, false);
    }
    
    @isTest
    public static void sendToMadSkyTest(){
        Claim c = [Select Id, Name,Loss_Description__c,PolicyNumberId,Claim_Vendor__c,Date_of_Loss__c,PolicyNumber.Street__c,PolicyNumber.State__c,PolicyNumber.City__c,PolicyNumber.Zip__c,
                  Claim_Adjuster__c,Claim_Adjuster__r.Email,Claims_Notes__c,Peril__c,Wind_Hail_Deductible__c,Claim_Adjuster__r.Name,Claim_Adjuster__r.Phone from Claim Limit 1];
        Callout__c result = ClaimTriggerHandler.sendToMadSky(c);
    }
}