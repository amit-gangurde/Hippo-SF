@isTest
public class StoppaymentTest {
    @TestSetup static void initiateTestData(){
        //Insert User
        User usr = new User();
        usr.ProfileID = [Select Id From Profile Where Name='System Administrator'].id;
        usr.EmailEncodingKey = 'ISO-8859-1';
        usr.LanguageLocaleKey = 'en_US';
        usr.TimeZoneSidKey = 'America/New_York';
        usr.LocaleSidKey = 'en_US';
        usr.FirstName = 'Vanii';
        usr.LastName = 'Moodyi';
               usr.Username = 'tstuser.hippo12.orgtest8889.new12@gmail.com';

        //user.CommunityNickname = 'testUser123';
        usr.Alias = 't1';
        usr.Email = 'nor@email.com';
        usr.IsActive = true;
        insert usr;

        //Insert Account
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;

        //Insert Insurance Policy
        InsurancePolicy ip = new InsurancePolicy();
        ip.Name = 'IP Name test';
        ip.NameInsuredId =  acc.Id;
        //ip.policy
        insert ip;

        //Insert claim
        Claim cl = new Claim();
        cl.Claim_Adjuster__c = usr.Id;
        cl.Name = 'test claim';
        cl.ClaimType = 'Home';
        cl.AccountId = acc.Id;
        cl.PolicyNumberId = ip.Id;
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

        ClaimParticipant fourthCPart = new ClaimParticipant();
        fourthCPart.MobilePhone__c = '8796543212';
        fourthCPart.First_Name__c = 'fourthCPartfn';
        fourthCPart.Last_Name__c = 'fourthCPartln';
        fourthCPart.Roles = 'Witness';
        fourthCPart.ClaimId = cl.Id;
        insert fourthCPart;

        ClaimParticipant thirdCPart = new ClaimParticipant();
        thirdCPart.MobilePhone__c = '8796543212';
        thirdCPart.First_Name__c = 'fourthCPartfn';
        thirdCPart.Last_Name__c = 'fourthCPartln';
        thirdCPart.Roles = 'Witness';
        thirdCPart.ClaimId = cl.Id;
        insert thirdCPart;

        Contact cont = new Contact();
        cont.Email = 'cont@gmail.com';
        cont.MobilePhone = '6789092345';
        cont.FirstName = 'contfn';
        cont.LastName = 'contln';
        insert cont;

        ClaimParticipant primaryCPart = new ClaimParticipant();
        primaryCPart.Roles = 'Witness';
        primaryCPart.ClaimId = cl.Id;
        primaryCPart.MobilePhone__c = '8796543987';
        primaryCPart.First_Name__c = 'priCPartfn';
        primaryCPart.Last_Name__c = 'priCPartln';
        primaryCPart.ParticipantContactId = cont.Id;
        primaryCPart.OfficePhone__c = '5432198760';
        primaryCPart.Email__c = 'primary@gmail.com';
        primaryCPart.Mail_To__c = 'test user';
        primaryCPart.Country__c =  'priCountry';
        primaryCPart.City__c = 'pricity';
        primaryCPart.State__c = 'pristate';
        primaryCPart.Zip_Code__c = '123456';
        primaryCPart.Street__c = 'street';
        insert primaryCPart;

        ClaimCoverage cc = new ClaimCoverage();
        cc.Name = 'ccName';
        cc.InternalReserveMode = 'CoverageReserve';
        cc.ClaimId = cl.Id;
        insert cc;

        Claim_Reserve__c cr = new Claim_Reserve__c();
        cr.Claim_Coverage__c = cc.Id;
        cr.RecordTypeId = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
  		cr.Status__c = 'Approved';
        cr.Claim__c = cl.id;
        insert cr;

        Id CPRecTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Claimant_Digital').getRecordTypeId();
        //Insert claim payment
        Claim_Payment__c cp = new Claim_Payment__c();
        cp.Payment_Amount_in_words__c =  'thousand';
        cp.RecordTypeId = CPRecTypeId;
        cp.Payment_Method_Inc__c = 'Claimant Digital';
        cp.Request_Reason__c = 'reason';
        cp.Expedite__c = false;
        cp.Certified__c = true;
        cp.Claim__c = cl.Id;
        cp.Secondary_Contact__c = secCPart.Id;
        cp.Fourth_Contact__c = fourthCPart.Id;
        cp.Third_Contact__c = thirdCPart.Id;
        cp.Print_Locally__c = false;
        cp.Primary_Contact__c = primaryCPart.Id;
        cp.Secondary_Contact__c =  secCPart.Id;
        insert cp;
        //cp.Claim__r.Name =
        //cp.Claim__r.ClaimType  =
        Claim_Payment_Item__c cpi = new Claim_Payment_Item__c();
         cpi.Claim__c = cl.id;
        cpi.Payment_Amount__c = 0;
        cpi.Claim_Payment__c = cp.Id;
        cpi.Claim_Reserve__c = cr.Id;
                cpi.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();

        insert cpi;
        //Insert claim payment
        Claim_Payment__c cp1 = new Claim_Payment__c();
         cp1.Claim__c = cl.id;
        cp1.Payment_Amount_in_words__c =  'thousand';
        cp1.Payment_Method_Inc__c = 'Claimant Check';
        cp1.Request_Reason__c = 'reason';
        cp1.Expedite__c = true;
        cp1.Certified__c = true;
        cp1.Claim__c = cl.Id;
        cp1.Secondary_Contact__c = secCPart.Id;
        cp1.Fourth_Contact__c = fourthCPart.Id;
        cp1.Third_Contact__c = thirdCPart.Id;
        cp1.Print_Locally__c = false;
        cp1.Primary_Contact__c = primaryCPart.Id;
        cp1.Secondary_Contact__c =  secCPart.Id;
        insert cp1;
        Claim_Payment_Item__c cpi1 = new Claim_Payment_Item__c();
        cpi1.Claim__c = cl.id;
        cpi1.Payment_Amount__c = 0;
        cpi1.Claim_Payment__c = cp1.Id;
        cpi1.Claim_Reserve__c = cr.Id;
                cpi1.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();

        insert cpi1;
        Claim_Payment__c cp2 = new Claim_Payment__c();
        cp2.Payment_Amount_in_words__c =  'thousand';
        cp2.Payment_Method_Inc__c = 'Claimant Check';
        cp2.Request_Reason__c = 'reason';
        cp2.Expedite__c = true;
        cp2.Certified__c = true;
        cp2.Claim__c = cl.Id;
        cp2.Secondary_Contact__c = secCPart.Id;
        cp2.Fourth_Contact__c = fourthCPart.Id;
        cp2.Third_Contact__c = thirdCPart.Id;
        cp2.Print_Locally__c = false;
        cp2.Primary_Contact__c = primaryCPart.Id;
        cp2.Secondary_Contact__c =  secCPart.Id;
        insert cp2;
        Claim_Payment_Item__c cpi2 = new Claim_Payment_Item__c();
          cpi2.Claim__c = cl.id;
        cpi2.Payment_Amount__c =0;
        cpi2.Claim_Payment__c = cp2.Id;
        cpi2.Claim_Reserve__c = cr.Id;
                cpi2.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();

        insert cpi2;

        //Insert claim payment
        Claim_Payment__c cp3 = new Claim_Payment__c();
        cp3.Payment_Amount_in_words__c =  'thousand';
        cp3.RecordTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Vendor_Digital').getRecordTypeId();
        cp3.Payment_Method_Inc__c = 'Vendor Digital';
        cp3.Request_Reason__c = 'reason';
        cp3.Expedite__c = false;
        cp3.Certified__c = true;
        cp3.Claim__c = cl.Id;
        cp3.Secondary_Contact__c = secCPart.Id;
        cp3.Fourth_Contact__c = fourthCPart.Id;
        cp3.Third_Contact__c = thirdCPart.Id;
        cp3.Print_Locally__c = false;
        cp3.Primary_Contact__c = primaryCPart.Id;
        cp3.Secondary_Contact__c =  secCPart.Id;
        insert cp3;
        Claim_Payment_Item__c cpi3 = new Claim_Payment_Item__c();
          cpi3.Claim__c = cl.id;
        cpi3.Payment_Amount__c = 0;
        cpi3.Claim_Payment__c = cp3.Id;
        cpi3.Claim_Reserve__c = cr.Id;
                cpi3.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();

        insert cpi3;
        PaymentAuth_Integration_System__c setting = new PaymentAuth_Integration_System__c();
        setting.Base_URL__c = 'https://servicesqa.insurpay.com:9441/hippo_app_dev/custom/service/v4_1_custom/rest.php';
        setting.Password__c = '3d160bf1743f184834468c0174e9d5dd';
        //setting.URL_Encoded_Body__c = 'Whatever';
        setting.User_Name__c = 'hpouser01';
        insert setting;
    }
    @isTest static void callStopPayment(){
        Id claimID = [SELECT ID FROM Claim_Payment__c LIMIT 1].ID;
        Test.startTest();
        PaymentFeedback.getWebHookInfo(claimID);
        Test.setMock(HttpCalloutMock.class, new StopPaymentMock('Success'));
         Stoppayment.Accessstoppayment(claimID);
        Test.stopTest();
    }
    @isTest static void callStopPaymentError(){
        Id claimID = [SELECT ID FROM Claim_Payment__c LIMIT 1].ID;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StopPaymentMock('Error'));
         Stoppayment.Accessstoppayment(claimID);
        Test.stopTest();
    }
}