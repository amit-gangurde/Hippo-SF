@isTest
public class ClaimaticAPIUtilityTest {
    @TestSetup static void initiateTestData(){
        String orgId = UserInfo.getOrganizationId();  
    String dateString =   
    String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
    Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
    String uniqueName = orgId + dateString + randomInt;  
        //Insert User
        User usr = new User();
        usr.ProfileID = [Select Id From Profile Where Name='System Administrator'].id;
        usr.EmailEncodingKey = 'ISO-8859-1';
        usr.LanguageLocaleKey = 'en_US';
        usr.TimeZoneSidKey = 'America/New_York';
        usr.LocaleSidKey = 'en_US';
        usr.FirstName = 'Vanii';
        usr.LastName = 'Moodyi';
      usr.Username = uniqueName + '@test' + orgId + '.org';
        //user.CommunityNickname = 'testUser123';
        usr.Alias = 't1';
        usr.Email = 'nor@email.com';
        usr.IsActive = true;
        insert usr;
        
        //Insert Account
        String recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Account acc= new Account(
            RecordTypeID=recordTypeId ,
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678' 
        );
        
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
        cl.Peril__c='wind';
        insert cl;
       
        Claim c = [SELECT ID,Carrier__c,PolicyNumber.Carrier__c FROM Claim LIMIT 1];
        ClaimaticAPIUtility.getCarrier(c);
        ClaimaticAPIUtility.getCoverage(c,'c',1);
        ClaimaticAPIUtility.createLogRecord(null,'Type','className','MethodName','objectName','RecordId','CustomMessage','Status');
        
       
    }
    @isTest static void claimAPITest(){
        Account acc = new Account();
        ClaimaticAPIUtility.wasFieldQueried(acc,'Name');
        ClaimaticAPIUtility.booleanToOneIncFlag(true);
        ClaimaticAPIUtility.getPolicyType('home');
        ClaimaticAPIUtility.createLogRecord( 'Integration', 'EndPoint', 'Request', 'Response', 'StatusCode', 'Type', 'Status');
        
         ClaimaticAuthenticationAPIResponse cAuth = new ClaimaticAuthenticationAPIResponse();
        cAuth.token = 'token';
         cAuth.token = 'email';
    }
}