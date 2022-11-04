@isTest
public class ClaimParticipantTriggerHandlerTest {
    @Testsetup static void initiateTestData(){
          PaymentAuth_Integration_System__c setting = new PaymentAuth_Integration_System__c();
        setting.Base_URL__c = 'https://servicesqa.insurpay.com:9441/hippo_app_dev/custom/service/v4_1_custom/rest.php';
        setting.Password__c = '3d160bf1743f184834468c0174e9d5dd';
        //setting.URL_Encoded_Body__c = 'Whatever';
        setting.User_Name__c = 'hpouser01';
        insert setting;
        //Insert User
        User usr = new User();
        usr.ProfileID = [Select Id From Profile Where Name='System Administrator'].id;
        usr.EmailEncodingKey = 'ISO-8859-1';
        usr.LanguageLocaleKey = 'en_US';
        usr.TimeZoneSidKey = 'America/New_York';
        usr.LocaleSidKey = 'en_US';
        usr.FirstName = 'Vanii';
        usr.LastName = 'Moodyi';
        usr.Username = 'tstuser.myhippo.889765@hippomail.com';
        //user.CommunityNickname = 'testUser123';
        usr.Alias = 't1';
        usr.Email = 'nor@email.com';
        usr.IsActive = true;
        insert usr;
        
        //Insert Account
        Account acc = new Account();
        acc.Name = 'test';
       // acc.PersonEmail = 'test@test.com';
        insert acc;
        
        //Insert Insurance Policy
        InsurancePolicy ip = new InsurancePolicy();
        ip.Name = 'IP Name test';
        ip.NameInsuredId =  acc.Id;
        //ip.policy
        insert ip;
        
        //Insert claim
        Claim cl = new Claim();
        cl.AccountId = acc.Id;
        cl.PolicyNumberId = ip.Id;
        cl.Claim_Adjuster__c = usr.Id;
        cl.Name = 'test claim';
        cl.ClaimType = 'Home';
        cl.Date_of_Loss__c = system.today() -10;
        cl.Claim_Agreement__c = 'Agree';
        insert cl;
        
        //Insert Contact
        Contact con = new Contact();
        con.Email = 'con@gmail.com';
        con.MobilePhone = '9940310711';
        con.FirstName = 'confn';
        con.LastName = 'conln';
        insert con;
        
        //Insert claim participant
        ClaimParticipant secCPart = new ClaimParticipant();
        secCPart.MobilePhone__c = '9876543212';
        secCPart.First_Name__c = 'cpartfn';
        secCPart.ParticipantContactId = con.Id;
        secCPart.Last_Name__c = 'cpartln';
        secCPart.OfficePhone__c = '8967452310';
        secCPart.Email__c = 'sec@gmail.com';
        secCPart.Roles = 'Witness';
        secCPart.ClaimId = cl.Id;
        insert secCPart;
        
            ClaimParticipant secCPartUpd = new ClaimParticipant();
        secCPartUpd.Id = secCPart.Id;
        secCPartUpd.Email__c= 'claim.test@email.com';
        update secCPartUpd;
        
           Claim_Payment__c cp = new Claim_Payment__c(
                Claim__c = cl.id,
                Status__c = 'Pending Approval'); 
              cp.Primary_Contact__c = secCPartUpd.id;
                insert cp;
        
          Claim_Payment__c cp1 = new Claim_Payment__c(
                Claim__c = cl.id,
                Status__c = 'Pending Approval'); 
              cp1.Primary_Contact__c = secCPartUpd.id;
                insert cp1;
    }
    @isTest static void claimParticipiantTest(){
          Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
          List<String> calloutLst = new List<String>();
          for(Claim_Payment__c con : [SELECT ID,Primary_Contact__c FROM Claim_Payment__c ]){
            ClaimParticipantTriggerHandler.updateProfile Request = new ClaimParticipantTriggerHandler.updateProfile();
            Request.PM_PaymentID 			= con.Id;
            Request.PCON_ContactId 			= null;// claimMap.containsKey(con.Id) && claimPartMap.containsKey(claimMap.get(con.Id))?claimPartMap.get(claimMap.get(con.Id)).Id:null;
            Request.PCON_EmailAddress 		= null;// claimMap.containsKey(con.Id) && claimPartMap.containsKey(claimMap.get(con.Id))?claimPartMap.get(claimMap.get(con.Id)).email__c:null;
             calloutLst.add(JSON.serialize(Request,true));
          }
          
        Database.executeBatch(new ClaimParticipantBatch(calloutLst), 1);
    }
}