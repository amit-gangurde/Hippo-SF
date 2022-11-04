/**
 * Created by jonathanschwartz on 7/19/21.
 */

public with sharing class ClaimaticAPITestUtility {

    public static InsurancePolicy setupPolicy(Account acc, String name, Boolean cashValueRoof) {
        InsurancePolicy ins = new InsurancePolicy();
        ins.NameInsuredId = acc.Id;
        ins.Name = name;
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
        ins.Actual_cash_value_on_roof_requested__c = cashValueRoof;
        insert ins;
        return ins;
    }

    public static InsurancePolicy[] setupPolicies(Account acc, Account acc2) {
        InsurancePolicy ins = setupPolicy(acc, 'test1', false);
        InsurancePolicy ins2 = setupPolicy(acc2, 'test2', true); // changed 'acc' to 'acc2' 11/17/2021 4:08pm CST

        return new InsurancePolicy[]{ins, ins2};
    }

    public static List<InsurancePolicy> setupPolicies(Account[] accs) {
        List<InsurancePolicy> output = new List<InsurancePolicy>();
        for (Integer i = 0; i < accs.size(); i++) {
            output.add(setupPolicy(accs[i], 'test' + (i+1), false));
        }
        return output;
    }

    public static List<InsurancePolicy> setupPolicies(Account[] accs, String[] names) {
        List<InsurancePolicy> output = new List<InsurancePolicy>();
        for (Integer i = 0; i < accs.size(); i++) {
            output.add(setupPolicy(accs[i], names[i], false));
        }
        return output;
    }

    public static Account setupAccount(String name) {
        Account acc = new Account();
        acc.FirstName = name;
        acc.LastName = name;
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
        return acc;
    }

    public static Account[] setupAccounts() {
        ClaimTriggerTestSetupDisable.isDisabled = true; // disable triggers for insert so we can setup data - 11/19/21 - JS
        Account acc = setupAccount('test1');
        Account acc2 = setupAccount('test2');
        ClaimTriggerTestSetupDisable.isDisabled = false;
        return new Account[]{acc, acc2};
    }

    public static void setupCoverageAndDeductible(Claim c, Boolean includeAll) {
        ClaimCoverage covA = new ClaimCoverage();
        covA.Name = 'Coverage A / Dwelling Rebuilding';
        covA.Coverage_Amount__c = 2222222.0;
        covA.ClaimId = c.Id;
        covA.InternalReserveMode = 'CoverageReserve';
        insert covA;
        ClaimCoverage covB = new ClaimCoverage();
        covB.Name = 'Coverage B / Separate Structure';
        covB.Coverage_Amount__c = 33333.0;
        covB.ClaimId = c.Id;
        covB.InternalReserveMode = 'CoverageReserve';
        insert covB;
        ClaimCoverage covC = new ClaimCoverage();
        covC.Name = 'Coverage C / Personal Property';
        covC.Coverage_Amount__c = 4444.0;
        covC.ClaimId = c.Id;
        covC.InternalReserveMode = 'CoverageReserve';
        insert covC;
        ClaimCoverage covD = new ClaimCoverage();
        covD.Name = 'Coverage D / Loss of Use';
        covD.Coverage_Amount__c = 55555.0;
        covD.ClaimId = c.Id;
        covD.InternalReserveMode = 'CoverageReserve';
        insert covD;
        ClaimCoverage covE = new ClaimCoverage();
        covE.Name = 'Coverage E';
        covE.Coverage_Amount__c = 666666.0;
        covE.ClaimId = c.Id;
        covE.InternalReserveMode = 'CoverageReserve';
        insert covE;
        if (includeAll) {
            ClaimCoverage covF = new ClaimCoverage();
            covF.Name = 'Coverage F';
            covF.Coverage_Amount__c = 7777.0;
            covF.ClaimId = c.Id;
            covF.InternalReserveMode = 'CoverageReserve';
            insert covF;
        }

        Claim_Deductible__c generalDeductible = new Claim_Deductible__c();
        generalDeductible.Name = 'General Deductible';
        generalDeductible.Deductible_Amount__c = 2345.0;
        generalDeductible.Claim__c = c.Id;
        insert generalDeductible;

        if (includeAll) {
            Claim_Deductible__c windDeductible = new Claim_Deductible__c();
            windDeductible.Name = 'Wind Deductible';
            windDeductible.Deductible_Amount__c = 345.0;
            windDeductible.Claim__c = c.Id;
            insert windDeductible;
        }
    }

    public static Claim setupClaim(String name, Account acc, Id adjuster, InsurancePolicy policy, Claim_Vendor__c vendor, Boolean includeAllCoverages) {
        Claim cs = new Claim();
        cs.Name = name;
        cs.AccountId = acc.Id;
        if (adjuster != null) {
            cs.Claim_Adjuster__c = adjuster;
        }
        cs.Date_of_Loss__c = System.today();
        cs.Have_a_Contractor__c = true;
        cs.Claim_Agreement__c = 'Agree';
        cs.PolicyNumberId = policy.Id;
        cs.Peril__c = 'Wind';
        cs.Loss_Description__c = 'test loss description we lost stuff to the wind, yo';
        cs.Mitigation_Needed__c = 'Yes';
        cs.Damage_Level__c = 'High';
        cs.Damage_Description__c = 'test damage description our stuff blew away real bad, yo';
        if (vendor != null) {
            cs.Claim_Vendor__c = vendor.Id;
        }
        insert cs;
        List<Claim> claims = [SELECT Id,Claim_Vendor__c,Claim_Adjuster__c FROM Claim];


        setupCoverageAndDeductible(cs, includeAllCoverages);
        return cs;
    }

    public static void setupClaims(Account acc, Account acc2, InsurancePolicy insNoRoof, InsurancePolicy insRoof) {
        ClaimTriggerTestSetupDisable.isDisabled = true; // disable triggers for insert so we can setup data - 11/19/21 - JS
        setupClaim('testclaim', acc, UserInfo.getUserId(), insNoRoof, null, false);
        setupClaim('testclaim2', acc2, UserInfo.getUserId(), insRoof, null, true); // changed 'acc' to 'acc2' 11/17/2021 3:50pm CST
        ClaimTriggerTestSetupDisable.isDisabled = false;
    }

    @Future
    private static void addAdjusterPermissionSet(String userAlias) {
        List<User> users = [SELECT Id FROM User WHERE Alias = :userAlias];
        System.debug(users);
        List<PermissionSet> ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Adjuster'];
        System.debug(ps);
        insert new PermissionSetAssignment(AssigneeId = users[0].Id, PermissionSetId = ps[0].Id);
    }

    @Future
    private static void addRole(String alias) {
        List<User> users = [SELECT Id FROM User WHERE Alias = :alias];
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Name = 'Adjuster'];
        users[0].UserRoleId = roles[0].Id;
        update users;
    }

    public static User createAdjuster(String alias, String username) {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = alias, Email='standarduser12@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', Username=username);

        insert u;
        return u;
    }

    public static User createAdminAdjuster(String alias, String username) {
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE '%Admin%' LIMIT 1];
        User u = new User(Alias = alias, Email='standarduser12@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', Username=username);

        insert u;
        return u;
    }

    public static Claim_Vendor__c createVendor(String name) {
        Claim_Vendor__c v = new Claim_Vendor__c(Name = name,
                Contact_Email__c = 'test@test.com',
                Contact_Name__c = name,
                Contact_Phone__c = '1234567890',
                Category__c = 'Remediation',
                Country__c = 'US',
                Claimatic_Integration_ID__c = '5555500000'+name); // added on 11/17/2021 5:41 pm EST
        insert v;
        return v;
    }

}