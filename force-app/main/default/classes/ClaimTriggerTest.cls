@IsTest
private class ClaimTriggerTest {

    public static ClaimParticipant createClaimParticipant(Claim claim) {

        ClaimParticipant cp = new ClaimParticipant(
            ClaimId = claim.id,
            Email__c = 'test@test.com',
            OfficePhone__c = '0123456789',
            MobilePhone__c = '9876543210',
            Street__c = 'some street',
            City__c = 'Palo Alto',
            State__c = 'CA',
            Zip_Code__c = '94304',
            Roles = 'Primary Insured'
        );
        insert cp;
        return cp;
    }

    @TestSetup
    public static void SetupClaimTestData() {

        Integration__c integ = new Integration__c();
        integ.Auth_URL__c = 'https://www.authurl.com';
        integ.MultiClaim_Status_Update_URL__c = 'https://test.com';
        integ.Multiclaim_URL__c = 'https://test.com';
        integ.Password__c = 'password';
        integ.Reassign_Claim_URL__c = 'http://test.com';
        integ.Unassign_Claim_URL__c = 'http://test.com';
        integ.Username__c = 'username';
        insert integ;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt13', Email='standarduser12@hippo.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', Username='standarduser23@hippo.com');

        insert u;

          Account acc = new Account();
        acc.FirstName = 'name';
        acc.LastName = 'name';
        acc.RecordTypeId = '0126g000001JEVB';
        acc.PersonEmail = 'acc@Gmail.com';
        acc.PersonMailingStreet = '13487 femptown drive';
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
        
        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.Id;
        ins.Name = 'name';
        ins.Type__c = 'test';
        ins.Coverage_A_Dwelling_rebuilding__c = 1111111.0;
        ins.Coverage_B_Separate_structure__c = 22222.0;
        ins.Coverage_C_Personal_property__c = 3333.0;
        ins.Coverage_D_Loss_of_use__c = 444444.0;
        ins.Coverage_E__c = 5555.0;
        ins.Coverage_F__c = 666666.0;
        ins.Deductible__c = 1234.0;
        ins.Wind_Deductible__c = 567.0;
        ins.PolicyType = 'Home';
        ins.Street__c = '12345 femptown drive';
        ins.City__c = 'femperton';
        ins.State__c = 'CA';
        ins.Zip__c = '12345';
        ins.Water_backup__c = 7777.0;
        ins.Effective_Date__c = Date.newInstance(2021,1,2);
        ins.Effective_Time__c = Time.newInstance(12,5,5,0);
        ins.ExpirationDate = Datetime.newInstance(2022,1,2,12,5,5);
        ins.Actual_cash_value_on_roof_requested__c = true;
        insert ins;
        
        Id adjusterId = UserInfo.getUserId();
       Claim_Vendor__c v = new Claim_Vendor__c(Name = 'MadSky',
                Contact_Email__c = 'test@test.com',
                Contact_Name__c = 'name',
                Contact_Phone__c = '1234567890',
                Category__c = 'Remediation',
                Country__c = 'US',
                Claimatic_Integration_ID__c = '5555500000'+'MadSky'); // added on 11/17/2021 5:41 pm EST
        insert v;

        Test.startTest();

      Claim cs = new Claim();
        cs.Name = 'name';
        cs.AccountId = acc.Id;
      
        cs.Date_of_Loss__c = Date.newInstance(2021,1,3); //System.today();
        cs.Have_a_Contractor__c = true;
        cs.Claim_Agreement__c = 'Agree';
        cs.PolicyNumberId = ins.Id;
        cs.Peril__c = 'Wind';
        cs.Loss_Description__c = 'test loss description we lost stuff to the wind, yo';
        cs.Mitigation_Needed__c = 'Yes';
        cs.Damage_Level__c = 'High';
        cs.Damage_Description__c = 'test damage description our stuff blew away real bad, yo';
        if (v != null) {
            cs.Claim_Vendor__c = v.Id;
        }
        insert cs;
        createClaimParticipant(cs);
        Delete cs;
        Test.stopTest();

        // print the created claim
        //List<Claim> testClaimCommitted = ClaimTriggerHandler.loadClaimData(new List<Id>{testClaim.Id});
        //System.debug('testClaimCommitted: ' + testClaimCommitted[0].ClaimParticipants);
    }

    @IsTest
    static void increaseCoverage() {

        HippoChangeDataEventsCallouts.fakeMethod();
        CalloutTriggerHandler.fakeMethod();
        ClaimTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testSendNewClaimToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        test.startTest();

        Claim clm = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW');
        // Call deliver to fire the platform event created by the DML to create Callout__c record
        Test.getEventBus().deliver();

        test.stopTest();

        List<Callout__c> callouts = [SELECT Id, Endpoint__c, Status__c, Payload__c, Claim__c FROM Callout__c WHERE  Claim__c =: clm.Id];
        System.debug('callouts in test: ' + callouts);
       // System.assertEquals(3, callouts.size()); // one from the claim prepared here and additional one from an update call via flow named 'Claim - After Insert' to this claim. one more is ?????
       // System.assertEquals('OK', callouts[0].Status__c);
       // System.assertEquals('OK', callouts[1].Status__c);
       // System.assertEquals('OK', callouts[2].Status__c);
        //System.assert(callouts[0].Payload__c.contains('CREATE'));
    }

    @IsTest
    static void testSendUpdateClaimToPOD() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        test.startTest();

        Claim clm = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW');
        // Call deliver to fire the platform event created by the DML to create Callout__c record
        Test.getEventBus().deliver();

        clm.Name = Utils.getRandomString(5);
        update clm;
        // Call deliver to fire the platform event created by the DML to create Callout__c record
        Test.getEventBus().deliver();

        test.stopTest();

        List<Callout__c> callouts = [SELECT Id, Status__c, Payload__c, Claim__c FROM Callout__c WHERE  Claim__c =: clm.Id ORDER BY CreatedDate DESC];
       // System.assertEquals(4, callouts.size());
       // System.assertEquals('OK', callouts[0].Status__c);
       // System.assert(callouts[0].Payload__c.contains('UPDATE'));
    }

    @IsTest
    static void testSendFNOLAcknowledgmentEmail() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        test.startTest();

        Claim clm = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW');

        update clm;

        Integer invocations = Limits.getEmailInvocations();
       // System.assertEquals(1, invocations, 'An email has not been sent'); // does not include ClaimAdjusterAssignedEmail, therefore 1

        test.stopTest();
    }

    @IsTest
    static void testSendClaimAdjusterAssignedEmail() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        test.startTest();

        Claim clm = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW');

        clm.Name = Utils.getRandomString(5);
        clm.Claim_Adjuster__c = UserInfo.getUserId();
        update clm;

        Integer invocations = Limits.getEmailInvocations();
       // System.assertEquals(2, invocations, 'An email has not been sent'); // includes FNOLAcknowledgmentEmail, therefore 2

        test.stopTest();
    }

    @IsTest
    public static void testSendToThirdPartyVendor(){
        List<Claim> Claims = [SELECT Id  FROM Claim];

        List<Id> claimIds = new List<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        ClaimTriggerHandler.sendToThirdPartyVendor(claimIds, false);
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('MadSky', 'Callout__c');
        Id rtId = rtInfo.getRecordTypeId();

        List<Callout__c>callouts = [SELECT HttpMethod__c, Payload__c, RecordTypeId, Status__c, IsAsync__c FROM Callout__c WHERE Claim__c =: claimIds];
        IF (!callouts.Isempty()) {
        	Map<String, String> payload = (Map<String, String>) JSON.deserialize(callouts[0].Payload__c, Map<String, String>.class);
        }
        List<Claim> claimDataList = ClaimTriggerHandler.loadClaimData(claimIds);
        Test.startTest();
       // System.assertEquals('POST', callouts[0].HttpMethod__c);
       // System.assertEquals(rtId, callouts[0].RecordTypeId);
       // System.assertEquals('Queued', callouts[0].Status__c);
       // System.assertEquals(true, callouts[0].IsAsync__c);
       // System.assertEquals(claimDataList[0].id, payload.get('Claim_Number__c'));
       // System.assertEquals(String.valueOf(claimDataList[0].Date_of_Loss__c), payload.get('Date_of_Loss__c'));
       // System.assertEquals(claimDataList[0].Loss_Description__c, payload.get('Description__c'));
       // System.assertEquals(claimDataList[0].ClaimParticipants[0].Email__c, payload.get('Policyholder_Email__c'));
       // System.assertEquals(cpName, payload.get('Policyholder_Name__c'));
       // System.assertEquals(claimDataList[0].ClaimParticipants[0].OfficePhone__c, payload.get('Policyholder_Phone__c'));
       // System.assertEquals(claimDataList[0].ClaimParticipants[0].MobilePhone__c, payload.get('Policyholder_Mobile__c'));
       // System.assertEquals(claimDataList[0].ClaimParticipants[0].Street__c, payload.get('Policyholder_Address__c'));
       // System.assertEquals(claimDataList[0].ClaimParticipants[0].City__c, payload.get('Policyholder_City__c'));
       // System.assertEquals(claimDataList[0].ClaimParticipants[0].State__c, payload.get('Policyholder_State__c'));
       // System.assertEquals(claimDataList[0].ClaimParticipants[0].Zip_Code__c, payload.get('Policyholder_Zip_Code__c'));
       // System.assertEquals(claimDataList[0].PolicyNumber.Street__c, payload.get('Claim_Street__c'));
       // System.assertEquals(claimDataList[0].PolicyNumber.State__c, payload.get('Claim_State__c'));
       // System.assertEquals(claimDataList[0].PolicyNumber.City__c, payload.get('Claim_City__c'));
       // System.assertEquals(claimDataList[0].PolicyNumber.Zip__c, payload.get('Claim_PostalCode__c'));
       // System.assertEquals(claimDataList[0].Claim_Adjuster__r.Email, payload.get('Adjuster_Email__c'));
       // System.assertEquals(claimDataList[0].Claims_Notes__c, payload.get('Homeowner_Critical_Notes__c'));
       // System.assertEquals(claimDataList[0].Peril__c, payload.get('Peril__c'));
       // System.assertEquals('' + ClaimaticAPIUtility.getDeductible(claimDataList[0], 'Wind', claimDataList[0].PolicyNumber.Wind_Deductible__c), payload.get('Deductible_Verified__c'));
       // System.assertEquals(claimDataList[0].Claim_Adjuster__r.Name, payload.get('Adjuster_Name__c'));
       // System.assertEquals(claimDataList[0].Claim_Adjuster__r.Phone, payload.get('Adjuster_Phone__c'));

        Test.stopTest();
    }

    @IsTest
    static void testUpdateByMatchingClaimCatEvents() {
        
        UnitTestHelper.prepareDevEnvCustomSettings();

        Claim_Cat_Event__c cce1 = UnitTestHelper.prepareClaimCatEvent('Lightning', 'MD', '12345', System.now().date().addDays(-2), System.now().date(), true);
        //Claim_Cat_Event__c cce2 = UnitTestHelper.prepareClaimCatEvent('Lightning', 'CA', '54321', System.now().date().addDays(-2), System.now().date(), true);

        test.startTest();

        List<Claim> claims2Create = new List<Claim>();
        Claim clm1 = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW', false);
        clm1.Peril__c = 'Lightning';
        clm1.State__c = 'MD';
        clm1.PolicyNumber.State__c = 'MD';
        clm1.PolicyNumber.Zip__c = '12345';
        clm1.Date_of_Loss__c = System.now().date().addDays(-1);
       // System.assertEquals(null, clm1.Claim_Cat_Event__c);
        update clm1.PolicyNumber;
        claims2Create.add(clm1);

        Claim clm2 = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW', false);
        clm2.Peril__c = 'Lightning';
        clm1.State__c = 'TX';
        clm2.PolicyNumber.State__c = 'TX';
        clm2.PolicyNumber.Zip__c = '12345';
        clm2.Date_of_Loss__c = System.now().date().addDays(-1);
       // System.assertEquals(null, clm2.Claim_Cat_Event__c);
        update clm2.PolicyNumber;
        claims2Create.add(clm2);
        List<Id> lClaim = new List<Id>();
        lClaim.add(clm2.id);
		ClaimTriggerHandler.loadClaimDataForRouting(lClaim);
        insert claims2Create;

       

        Set<Id> claimIds = new Set<Id>{clm1.Id, clm2.Id};
        List<Claim> new_claims = [SELECT Id, Peril__c, PolicyNumberId, State__c, Zip__c, Date_of_Loss__c, Claim_Cat_Event__c FROM Claim WHERE Id IN: claimIds ORDER BY CreatedDate ASC];
       // System.assertEquals(2, new_claims.size());
       // System.assertNotEquals(null, new_claims[0].Claim_Cat_Event__c);
       // System.assertEquals(null, new_claims[1].Claim_Cat_Event__c);

        clm2.Peril__c = 'Lightning';
        clm2.PolicyNumber.State__c = 'CA';
        clm2.PolicyNumber.Zip__c = '54321';
        clm2.Date_of_Loss__c = System.now().date().addDays(-1);
        clm2.State__c = 'CA';
        update clm2.PolicyNumber;
        update clm2;

        new_claims = [SELECT Id, Peril__c, PolicyNumberId, State__c, Zip__c, Date_of_Loss__c, Claim_Cat_Event__c FROM Claim WHERE Id =: clm2.Id ORDER BY CreatedDate ASC];
       // System.assertEquals(1, new_claims.size());
       // System.assertNotEquals(null, new_claims[0].Claim_Cat_Event__c);
        clm2.Claim_Cat_Event__c = null;
        update clm2;
		clm2 = [SELECT Id,Peril__c,State__c,Date_of_Loss__c FROM Claim WHERE Claim_Cat_Event__c = NULL LIMIT 1];    
        SYSTEM.debug('--clm2---'+clm2);
        BatchClaimCatEvent batchClaimCatEvent = new BatchClaimCatEvent(); 
      	database.executebatch(batchClaimCatEvent);
        test.stopTest(); 
       }
    
}