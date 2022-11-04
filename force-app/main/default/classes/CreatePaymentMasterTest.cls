@isTest
public class CreatePaymentMasterTest {
    @testsetup
    public static void testDateCreation(){
        
        //Insert User
        User usr = new User();
        usr.ProfileID = [Select Id From Profile Where Name='System Administrator'].id;
        usr.EmailEncodingKey = 'ISO-8859-1';
        usr.LanguageLocaleKey = 'en_US';
        usr.TimeZoneSidKey = 'America/New_York';
        usr.LocaleSidKey = 'en_US';
        usr.FirstName = 'Vanii';
        usr.LastName = 'Moodyi';
        usr.Username = 'tstuser.hippo.orgtest678889.new112@gmail.com';
        //user.CommunityNickname = 'testUser123';
        usr.Alias = 't1';
        usr.Email = 'nor@hippo.com';
        usr.IsActive = true;
        insert usr;
        
        //Insert Account
        Account acc = new Account();
        acc.FirstName = 'test';
        acc.LastName = 'test';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        acc.PersonMailingCity = 'test';
        acc.PersonMailingStreet='test@yahoo.com';
        
        acc.PersonMailingPostalCode='12345';
        
        acc.PersonMailingCity='SFO';
        
        acc.PersonEmail='test@yahoo.com';
        
        acc.PersonHomePhone='1234567';
        
        acc.PersonMobilePhone='12345678'; 
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
        cr.Status__c = 'Approved';
        cr.Claim__c = cl.Id;
        cr.RecordTypeId = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
        insert cr;
        System.debug('------cr='+cr);
        
        
        
        Id CPRecTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Claimant_Digital').getRecordTypeId();
        //Insert claim payment
        Claim_Payment__c cp = new Claim_Payment__c();
        cp.Claim__c = cl.Id;
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
        
        Claim_Payment_Item__c cpi = new Claim_Payment_Item__c();
        cpi.Claim__c = cl.id;
        cpi.Payment_Amount__c = 0;
        cpi.Claim_Payment__c = cp.Id;
        cpi.Claim_Reserve__c = cr.Id;
        cpi.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
        insert cpi;
        //cp.Claim__r.Name =
        //cp.Claim__r.ClaimType  =
        
        //Insert claim payment
        Claim_Payment__c cp1 = new Claim_Payment__c();
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
        cpi1.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
        cpi1.Payment_Amount__c = 0;
        cpi1.Claim_Payment__c = cp1.Id;
        cpi1.Claim_Reserve__c = cr.Id;
        insert cpi1;
        
        Claim_Payment__c cp2 = new Claim_Payment__c();
        cp2.Payment_Amount_in_words__c =  'thousand';
        cp2.Payment_Method_Inc__c = 'Claimant Check';
        cp2.Request_Reason__c = 'reason';
        cp2.Expedite__c = true;
        cp2.Certified__c = true;
        cp2.Claim__c = cl.Id;
        cp2.Secondary_Contact__c = secCPart.Id;
        //cp2.Fourth_Contact__c = fourthCPart.Id;
        //cp2.Third_Contact__c = thirdCPart.Id;
        cp2.Print_Locally__c = false;
        cp2.Primary_Contact__c = primaryCPart.Id;
        cp2.Secondary_Contact__c =  secCPart.Id;
        insert cp2;
        Claim_Payment_Item__c cpi2 = new Claim_Payment_Item__c();
        cpi2.Claim__c = cl.id;
        cpi2.Payment_Amount__c = 0;
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
        cpi3.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
        cpi3.Claim_Reserve__c = cr.Id;
        insert cpi3;
        
        Claim_Payment__c cp4 = new Claim_Payment__c();
        cp4.Payment_Amount_in_words__c =  'thousand';
        cp4.RecordTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Vendor_Digital_with_Approval').getRecordTypeId();
        cp4.Payment_Method_Inc__c = 'Vendor Digital with Approval';
        cp4.Request_Reason__c = 'reason';
        cp4.Expedite__c = false;
        cp4.Certified__c = true;
        cp4.Claim__c = cl.Id;
        cp4.Secondary_Contact__c = secCPart.Id;
        cp4.Fourth_Contact__c = fourthCPart.Id;
        cp4.Third_Contact__c = thirdCPart.Id;
        cp4.Print_Locally__c = false;
        cp4.Primary_Contact__c = primaryCPart.Id;
        cp4.Secondary_Contact__c =  secCPart.Id;
        insert cp4;
        Claim_Payment_Item__c cpi4 = new Claim_Payment_Item__c();
        cpi4.Claim__c = cl.id;
        cpi4.Payment_Amount__c = 0;
        cpi4.Claim_Payment__c = cp4.Id;
        cpi4.Claim_Reserve__c = cr.Id;
        cpi4.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
        insert cpi4;
        
        Claim_Payment__c cp5 = new Claim_Payment__c();
        cp5.Payment_Amount_in_words__c =  'thousand';
        cp5.RecordTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Vendor_Check').getRecordTypeId();
        cp5.Payment_Method_Inc__c = 'Vendor Check';
        cp5.Request_Reason__c = 'reason';
        cp5.Expedite__c = false;
        cp5.Certified__c = true;
        cp5.Claim__c = cl.Id;
        cp5.Secondary_Contact__c = secCPart.Id;
        cp5.Fourth_Contact__c = fourthCPart.Id;
        cp5.Third_Contact__c = thirdCPart.Id;
        cp5.Print_Locally__c = false;
        cp5.Primary_Contact__c = primaryCPart.Id;
        cp5.Secondary_Contact__c =  secCPart.Id;
        insert cp5;
        Claim_Payment_Item__c cpi5 = new Claim_Payment_Item__c();
        cpi5.Claim__c = cl.id;
        cpi5.Payment_Amount__c = 0;
        cpi5.Claim_Payment__c = cp5.Id;
        cpi5.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
        cpi5.Claim_Reserve__c = cr.Id;
        insert cpi5;
        
        //Insert claim payment
        Claim_Payment__c cp6 = new Claim_Payment__c();
        cp6.Payment_Amount_in_words__c =  'thousand';
        cp6.Payment_Method_Inc__c = 'Claimant Check';
        cp6.Request_Reason__c = 'reason';
        cp6.Expedite__c = true;
        cp6.Certified__c = true;
        cp6.Claim__c = cl.Id;
        cp6.Secondary_Contact__c = secCPart.Id;
        cp6.Fourth_Contact__c = fourthCPart.Id;
        cp6.Third_Contact__c = thirdCPart.Id;
        cp6.Print_Locally__c = true;
        cp6.Primary_Contact__c = primaryCPart.Id;
        cp6.Secondary_Contact__c =  secCPart.Id;
        insert cp6;
        
        Claim_Payment_Item__c cpi6 = new Claim_Payment_Item__c();
        cpi6.Claim__c = cl.id;
        cpi6.Payment_Amount__c = 0;
        cpi6.Claim_Payment__c = cp6.Id;
        cpi6.Claim_Reserve__c = cr.Id;
        cpi6.recordTypeId = Schema.SObjectType.Claim_Payment_Item__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
        insert cpi6;
        
        PaymentAuth_Integration_System__c setting = new PaymentAuth_Integration_System__c();
        setting.Base_URL__c = 'https://servicesqa.insurpay.com:9441/hippo_app_dev/custom/service/v4_1_custom/rest.php';
        setting.Password__c = '3d160bf1743f184834468c0174e9d5dd';
        //setting.URL_Encoded_Body__c = 'Whatever';
        setting.User_Name__c = 'hpouser01';
        insert setting;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        PaymentAuth.endSession();
        CreatePaymentMaster.createPayment(cp2.Id);
        Test.stopTest();
    }
    public static testMethod void paymentMasterVendorDigitalTest(){
        Id recTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Vendor_Digital').getRecordTypeId();
        Claim_Payment__c cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                               Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                               Request_Reason__c from Claim_Payment__c where RecordTypeId =: recTypeId];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CreatePaymentMaster.createPayment(cp.Id);
        Test.stopTest();
    }
    public static testMethod void paymentMasterVendorDigitalApprovalTest(){
        Id recTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Vendor_Digital_with_Approval').getRecordTypeId();
        Claim_Payment__c cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                               Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                               Request_Reason__c from Claim_Payment__c where RecordTypeId =: recTypeId];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CreatePaymentMaster.createPayment(cp.Id);
        Test.stopTest();
    }
    public static testMethod void paymentMasterVendorCheckTest(){
        Id recTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Vendor_Check').getRecordTypeId();
        Claim_Payment__c cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                               Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                               Request_Reason__c from Claim_Payment__c where RecordTypeId =: recTypeId];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CreatePaymentMaster.createPayment(cp.Id);
        Test.stopTest();
    }
    public static testMethod void paymentMasterClaimantDigitalTest(){
        Id recTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Claimant_Digital').getRecordTypeId();
        Claim_Payment__c cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                               Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                               Request_Reason__c from Claim_Payment__c where RecordTypeId =: recTypeId];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CreatePaymentMaster.createPayment(cp.Id);
        Test.stopTest();
    }
    public static testMethod void paymentMasterClaimantCheckTest(){
        Id recTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Claimant_Check').getRecordTypeId();
        Claim_Payment__c cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                               Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                               Request_Reason__c from Claim_Payment__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CreatePaymentMaster.createPayment(cp.Id);
        Test.stopTest();
    }
    public static testMethod void paymentMasterClaimantCheckprTest(){
        Id recTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Claimant_Check').getRecordTypeId();
        Claim_Payment__c cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                               Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                               Request_Reason__c from Claim_Payment__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CreatePaymentMaster.createPayment(cp.Id);
        Test.stopTest();
    }
    public static testMethod void paymentMasterClaimantCheckprtrueTest(){
        Id recTypeId = Schema.SObjectType.Claim_Payment__c.getRecordTypeInfosByDeveloperName().get('Claimant_Check').getRecordTypeId();
        Claim_Payment__c cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                               Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                               Request_Reason__c from Claim_Payment__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        CreatePaymentMaster.createPayment(cp.Id);
        CreatePaymentMaster.humanizeErrorMessages('PM_Amount valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('PMA_Street valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('PMA_City valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('PMA_Zipcode valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('PMA_State valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('PMA_Country valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('BUS_Name valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('BUS_Type valid','Method');
        CreatePaymentMaster.humanizeErrorMessages('BUS_SubType valid','Method');
        Test.stopTest();
    }
    @isTest static void paymentTriggerTest(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<Claim_Payment__c> cp = [select Id, Payment_Amount_in_words__c, RecordTypeId,Payment_Method_Inc__c,Total_Payment__c,Expedite__c,
                                     Certified__c, Claim__c, Fourth_Contact__c ,Third_Contact__c ,Print_Locally__c ,Primary_Contact__c ,Secondary_Contact__c,
                                     Request_Reason__c from Claim_Payment__c];
        
        Claim_Reserve__c cr = new Claim_Reserve__c();
        cr.Id = [SELECT ID FROM Claim_Reserve__c LIMIT 1].ID;
        cr.Status__c = 'Approved';
        update cr;
        
        Test.startTest();
        
        CreatePaymentMaster.handleFromTrigger(cp);
        Test.stopTest();
    }
    @isTest static void PaymentLoginResponseWrapperTest(){
        Test.startTest();
        PaymentLoginResponseWrapper pay = new PaymentLoginResponseWrapper();
        pay.module_name='test';
        
        
        PaymentLoginResponseWrapper.user_number_seperator userOBJ = new PaymentLoginResponseWrapper.user_number_seperator();
        userOBJ.name = 'name';
        userOBJ.value= 'value';
        PaymentLoginResponseWrapper.user_name user_nameOBJ = new PaymentLoginResponseWrapper.user_name();
        user_nameOBJ.name = 'name';
        user_nameOBJ.value= 'value';
        PaymentLoginResponseWrapper.user_language user_languageOBJ = new PaymentLoginResponseWrapper.user_language();
        user_languageOBJ.name = 'name';
        user_languageOBJ.value= 'value';
        PaymentLoginResponseWrapper.user_is_admin user_is_adminOBJ = new PaymentLoginResponseWrapper.user_is_admin();
        user_is_adminOBJ.name = 'name';
        user_is_adminOBJ.value=true;
        PaymentLoginResponseWrapper.user_id user_idOBJ = new PaymentLoginResponseWrapper.user_id();
        user_idOBJ.name = 'name';
        user_idOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.user_default_timeformat user_default_timeformatOBJ = new PaymentLoginResponseWrapper.user_default_timeformat();
        user_default_timeformatOBJ.name = 'name';
        user_default_timeformatOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.user_default_team_id user_default_team_idOBJ = new PaymentLoginResponseWrapper.user_default_team_id();
        user_default_team_idOBJ.name = 'name';
        user_default_team_idOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.user_default_dateformat user_default_dateformatOBJ = new PaymentLoginResponseWrapper.user_default_dateformat();
        user_default_dateformatOBJ.name = 'name';
        user_default_dateformatOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.user_decimal_seperator user_decimal_seperatorOBJ = new PaymentLoginResponseWrapper.user_decimal_seperator();
        user_decimal_seperatorOBJ.name = 'name';
        user_decimal_seperatorOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.user_currency_name user_currency_nameOBJ = new PaymentLoginResponseWrapper.user_currency_name();
        user_currency_nameOBJ.name = 'name';
        user_currency_nameOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.user_currency_id user_currency_idOBJ = new PaymentLoginResponseWrapper.user_currency_id();
        user_currency_idOBJ.name = 'name';
        user_currency_idOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.mobile_max_subpanel_entries mobile_max_subpanel_entriesOBJ = new PaymentLoginResponseWrapper.mobile_max_subpanel_entries();
        mobile_max_subpanel_entriesOBJ.name = 'name';
        mobile_max_subpanel_entriesOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.mobile_max_list_entries mobile_max_list_entriesOBJ = new PaymentLoginResponseWrapper.mobile_max_list_entries();
        mobile_max_list_entriesOBJ.name = 'name';
        mobile_max_list_entriesOBJ.value= 'value';
        
        PaymentLoginResponseWrapper.name_value_list nList = new PaymentLoginResponseWrapper.name_value_list();
        //  nList.user_number_seperator=user_number_seperatorOBJ;
        nList.user_default_timeformat=user_default_timeformatOBJ;
        nList.user_decimal_seperator=user_decimal_seperatorOBJ;
        nList.user_default_dateformat=user_default_dateformatOBJ;
        nList.user_default_team_id=user_default_team_idOBJ;
        nList.mobile_max_list_entries = mobile_max_list_entriesOBJ;
        nList.user_is_admin=user_is_adminOBJ;
        nList.user_currency_id=user_currency_idOBJ;
        nList.user_language= user_languageOBJ;
        nList.mobile_max_subpanel_entries = mobile_max_subpanel_entriesOBJ;
        nList.user_name = user_nameOBJ;
        nList.user_currency_name = user_currency_nameOBJ;
        nList.user_id = user_idOBJ;
        Test.stopTest();
    }
}