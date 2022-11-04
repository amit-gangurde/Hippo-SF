@IsTest(SeeAllData = false)
public class ClaimaticClaimCreationAPITest{

    static String expectedXmlClaim = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Request>' +
                '<Claims>' +
                    '<Claim DateReceived="${dateRec}" DateOfLoss="${dateRec}" ClaimNumber="${CLAIMNUMBER}">' +
                        '<Policy PolicyNumber="test1" PolicyType="HO" PolicyStart="2021-01-02" PolicyEnd="2022-01-02"/>' +
                        '<Insureds>' +
                            '<Insured>' +
                                '<Contact First_Name="test1" Last_Name="test1" Phone="1234567890" Cell="0987654321" Alt="5432109876" Email="acc@gmail.com"/>' +
                                '<Address Street="13487 femptown drive" City="femperton" State="CA" County="" Zip="12345" Country="US" />' +
                            '</Insured>' +
                        '</Insureds>' +
                        '<Coverages>' +
                            '<Coverage Name="Coverage A Dwelling rebuilding" Coverage_Amount="2222222.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage B Separate structure" Coverage_Amount="33333.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage C Personal property" Coverage_Amount="4444.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage D Loss of use" Coverage_Amount="55555.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage E" Coverage_Amount="666666.00" Reserve_Amount="500.00" />' +
                            '<Coverage Name="Coverage F" Coverage_Amount="666666.00" Reserve_Amount="500.00" />' +
                        '</Coverages>' +
                        '<Deductibles>' +
                            '<Deductible Name="Deductible" Deductible_Amount="2345.00"/>' +
                            '<Deductible Name="Wind Deductible" Deductible_Amount="567.00"/>' +
                        '</Deductibles>' +
                        '<Addresses>' +
                            '<Address LossType="Yes" Type="Home" Street="12345 femptown drive" City="femperton" State="CA" County="" Zip="12345" Country="US"/>' +
                        '</Addresses>' +
                        '<Loss_Specs>' +
                            '<COL Code="" Desc="" />' +
                            '<TOL Code="wind" Desc="wind" />' +
                            '<Loss_Description ><![CDATA[test loss description we lost stuff to the wind, yo]]></Loss_Description>' +
                            '<Special_Notes><![CDATA[test damage description our stuff blew away real bad, yo]]></Special_Notes>' +
                        '</Loss_Specs>' +
                        '<Custom_Attributes>' +
                            '<Attribute Name="custom_attribute_30" desc="Mitigation_Needed" value="Yes" />' +
                            '<Attribute Name="custom_attribute_29" desc="SF_ID" value="${CLAIMNUMBER}" />' +
                            '<Attribute Name="custom_attribute_26" desc="coverage_limit" value="7777.00" />' +
                            '<Attribute Name="custom_attribute_25" desc="contractor" value="" />' +
                            '<Attribute Name="custom_attribute_24" desc="ACV" value="No"/>' +
                            '<Attribute Name="custom_attribute_23" desc="SEV" value="High" /> ' +
                        '</Custom_Attributes>' +
                    '</Claim>' +
                '</Claims>' +
            '</Request>';

    static String expectedXmlClaim2 = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Request>' +
                '<Claims>' +
                    '<Claim DateReceived="${dateRec}" DateOfLoss="${dateRec}" ClaimNumber="${CLAIMNUMBER}">' +
                        '<Policy PolicyNumber="test2" PolicyType="HO" PolicyStart="2021-01-02" PolicyEnd="2022-01-02"/>' +
                        '<Insureds>' +
                            '<Insured>' +
                                '<Contact First_Name="test2" Last_Name="test2" Phone="1234567890" Cell="0987654321" Alt="5432109876" Email="acc@gmail.com"/>' +
                                '<Address Street="13487 femptown drive" City="femperton" State="CA" County="" Zip="12345" Country="US" />' +
                            '</Insured>' +
                        '</Insureds>' +
                        '<Coverages>' +
                            '<Coverage Name="Coverage A Dwelling rebuilding" Coverage_Amount="2222222.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage B Separate structure" Coverage_Amount="33333.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage C Personal property" Coverage_Amount="4444.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage D Loss of use" Coverage_Amount="55555.00" Reserve_Amount="" />' +
                            '<Coverage Name="Coverage E" Coverage_Amount="666666.00" Reserve_Amount="500.00" />' +
                            '<Coverage Name="Coverage F" Coverage_Amount="7777.00" Reserve_Amount="500.00" />' +
                        '</Coverages>' +
                        '<Deductibles>' +
                            '<Deductible Name="Deductible" Deductible_Amount="2345.00"/>' +
                            '<Deductible Name="Wind Deductible" Deductible_Amount="345.00"/>' +
                        '</Deductibles>' +
                        '<Addresses>' +
                            '<Address LossType="Yes" Type="Home" Street="12345 femptown drive" City="femperton" State="CA" County="" Zip="12345" Country="US"/>' +
                        '</Addresses>' +
                        '<Loss_Specs>' +
                            '<COL Code="" Desc="" />' +
                            '<TOL Code="wind" Desc="wind" />' +
                            '<Loss_Description ><![CDATA[test loss description we lost stuff to the wind, yo]]></Loss_Description>' +
                            '<Special_Notes><![CDATA[test damage description our stuff blew away real bad, yo]]></Special_Notes>' +
                        '</Loss_Specs>' +
                        '<Custom_Attributes>' +
                            '<Attribute Name="custom_attribute_30" desc="Mitigation_Needed" value="Yes" />' +
                            '<Attribute Name="custom_attribute_29" desc="SF_ID" value="${CLAIMNUMBER}" />' +
                            '<Attribute Name="custom_attribute_26" desc="coverage_limit" value="7777.00" />' +
                            '<Attribute Name="custom_attribute_25" desc="contractor" value="" />' +
                            '<Attribute Name="custom_attribute_24" desc="ACV" value="Yes"/>' +
                            '<Attribute Name="custom_attribute_23" desc="SEV" value="High" /> ' +
                        '</Custom_Attributes>' +
                    '</Claim>' +
                '</Claims>' +
            '</Request>';

    @TestSetup
    public static void SetupClaimaticTestData() {
        Integration__c integ = new Integration__c();
        integ.Auth_URL__c = 'https://www.authurl.com';
        integ.MultiClaim_Status_Update_URL__c = 'https://test.com';
        integ.Multiclaim_URL__c = 'https://test.com';
        integ.Password__c = 'password';
        integ.Reassign_Claim_URL__c = 'http://test.com';
        integ.Unassign_Claim_URL__c = 'http://test.com';
        integ.Username__c = 'username';
        insert integ;

        Account[] accounts = ClaimaticAPITestUtility.setupAccounts();
        InsurancePolicy[] policies = ClaimaticAPITestUtility.setupPolicies(accounts[0], accounts[1]);
        ClaimaticAPITestUtility.setupClaims(accounts[0], accounts[1], policies[0], policies[1]);

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt13', Email='standarduser12@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', Username='standarduser23@testorg.com');

        insert u;

        Account acc1 = new Account();
        acc1.LastName = 'test';
        acc1.RecordTypeId = '0126g000001JEVB';
        acc1.PersonEmail = 'acc1@Gmail.com';
        acc1.Resource_Username__c = 'test1';
        acc1.Resource_Number__c = 'w4531';
        insert acc1;
    }

    @IsTest
    public static void testCoverageFallback(){
        List<Claim> Claims = [SELECT Id FROM Claim];

        Set<Id> claimIds = new Set<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }
        // blormp
        List<Claim> loadedClaims = ClaimaticClaimCreationAPI.loadData(claimIds);

        Test.startTest();
        Decimal coverageFFallback = ClaimaticAPIUtility.getCoverage(loadedClaims.get(0), 'Coverage F', loadedClaims.get(0).PolicyNumber.Coverage_F__c);
        System.assertEquals(666666.0, coverageFFallback);
        Decimal coverageFNoFallback = ClaimaticAPIUtility.getCoverage(loadedClaims.get(1), 'Coverage F', loadedClaims.get(1).PolicyNumber.Coverage_F__c);
        System.assertEquals(7777.0, coverageFNoFallback);
        Test.stopTest();
    }

    @IsTest
    public static void testDeductibleFallback(){
        List<Claim> Claims = [SELECT Id FROM Claim];

        Set<Id> claimIds = new Set<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        List<Claim> loadedClaims = ClaimaticClaimCreationAPI.loadData(claimIds);

        Test.startTest();
        Decimal windDeductibleFallback = ClaimaticAPIUtility.getDeductible(loadedClaims.get(0), 'Wind', loadedClaims.get(0).PolicyNumber.Wind_Deductible__c);
        System.assertEquals(567.0, windDeductibleFallback);
        Decimal windDeductibleNoFallback = ClaimaticAPIUtility.getDeductible(loadedClaims.get(1), 'Wind', loadedClaims.get(1).PolicyNumber.Wind_Deductible__c);
        System.assertEquals(345.0, windDeductibleNoFallback);
        Test.stopTest();
    }

    @IsTest
    public static void testXMLGenerationWithFallback(){
        List<Claim> Claims = [SELECT Id FROM Claim WHERE Name = 'testclaim'];

        Set<Id> claimIds = new Set<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        List<Claim> loadedClaim = ClaimaticClaimCreationAPI.loadData(claimIds);

        String expectedXml = expectedXmlClaim.replace('${CLAIMNUMBER}', loadedClaim.get(0).Id);
        expectedXml = expectedXml.replace('${dateRec}', Datetime.newInstance(System.today().year(),System.today().month(),System.today().day()).format('YYYY-MM-dd'));

        Test.startTest();
        String generatedXml = ClaimaticClaimCreationAPI.generateXML(loadedClaim.get(0));
        System.assertEquals(expectedXml, generatedXml);
        Test.stopTest();
    }

    @IsTest
    public static void testXMLGenerationWithAllDataInClaim(){

        List<Claim> Claims = [SELECT Id FROM Claim WHERE Name = 'testclaim2'];

        Set<Id> claimIds = new Set<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        List<Claim> loadedClaim = ClaimaticClaimCreationAPI.loadData(claimIds);

        String expectedXml = expectedXmlClaim2.replace('${CLAIMNUMBER}', loadedClaim.get(0).Id);
        expectedXml = expectedXml.replace('${dateRec}', Datetime.newInstance(System.today().year(),System.today().month(),System.today().day()).format('YYYY-MM-dd'));
        System.debug(expectedXml);

        System.debug(ClaimaticClaimCreationAPI.generateXML(loadedClaim.get(0)));

        Test.startTest();
        String generatedXml = ClaimaticClaimCreationAPI.generateXML(loadedClaim.get(0));
        System.assertEquals(expectedXml, generatedXml);
        Test.stopTest();
    }

    @IsTest
    public static void testClaimaticClaimCreationAPIExecution(){

        List<Claim> Claims = [SELECT Id FROM Claim];

        Set<Id> claimIds = new Set<Id>();
        for (Claim c : Claims) {
            claimIds.add(c.Id);
        }

        Test.startTest();
        ClaimaticClaimCreationAPI.CreateClaim(claimIds);
        Test.stopTest();
    }
}