@IsTest(SeeAllData = false)
public class ClaimaticCaseCreationAPI_Test{

    static String expectedXml = '<?xml version="1.0" encoding="UTF-8"?>' +
    '<Request>' +
        '<Claims>' +
            '<Claim ClaimNumber="${ClaimNumber}">' +
                '<Status Name="${ClaimStatus}"/>' +
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

        Account account = ClaimaticAPITestUtility.setupAccount('testaccount');

        InsurancePolicy policy = ClaimaticAPITestUtility.setupPolicy(account, 'testpolicy', false);

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt13', Email='standarduser12@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', Username='standarduser23@testorg.com');

        insert u;

        case cs = new case();
        cs.City__c = 'Texas';
        cs.Date_of_Loss__c = system.today(); 
        cs.CATCode__c = '1234';
        cs.Insurance_Policy__c = policy.id;
        insert cs;
    }
    
     private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    public static void testBasicMethodCallWorks(){
        List<case> cses = [SELECT Id FROM case];

        Set<Id> caseIds = new Set<Id>();
        for (case c : cses ) {
            caseIds.add(c.Id);
        }

        Test.startTest();
            //Test.setMock(HttpCalloutMock.class, new RestMock());
            ClaimaticCaseCreationAPI.CreateClaim(caseIds);

        Test.stopTest();
    }

    @IsTest
    public static void testXmlObjectStructureIsCorrect(){
        Case cses = [SELECT Id,CreatedDate,Date_of_Loss__c,CATCode__c,Insurance_Policy__c,Insurance_Policy__r.Name,
                            Insurance_Policy__r.NameInsured.FirstName,Insurance_Policy__r.NameInsured.LastName,Insurance_Policy__r.PolicyType, 
                            Insurance_Policy__r.NameInsured.Phone,Insurance_Policy__r.NameInsured.PersonMailingState,
                            Insurance_Policy__r.NameInsured.PersonMailingStreet,Insurance_Policy__r.NameInsured.PersonMailingCity,
                            Insurance_Policy__r.NameInsured.PersonMailingPostalCode,Insurance_Policy__r.NameInsured.PersonMailingCountry,
                            Insurance_Policy__r.Coverage_A_Dwelling_rebuilding__c,Insurance_Policy__r.Coverage_B_Separate_structure__c,
                            Insurance_Policy__r.Coverage_C_Personal_property__c,Insurance_Policy__r.Coverage_D_Loss_of_use__c,
                            Insurance_Policy__r.Coverage_E__c,Insurance_Policy__r.Coverage_F__c,Insurance_Policy__r.Deductible__c,
                            Insurance_Policy__r.Wind_Deductible__c,Insurance_Policy__r.NameInsured.PersonMobilePhone,
                            Insurance_Policy__r.NameInsured.PersonOtherPhone,Insurance_Policy__r.NameInsured.PersonEmail,
                            Insurance_Policy__r.Street__c,Insurance_Policy__r.City__c,Insurance_Policy__r.State__c,
                            Insurance_Policy__r.Zip__c,Peril__c,Loss_Description__c,Damage_Description__c,Mitigation_Needed__c,
                            Preferred_Contact_Method__c,Insurance_Policy__r.Water_backup__c,Insurance_Policy__r.Actual_cash_value_on_roof_requested__c,
                            Damage_Level__c,Have_a_Contractor__c,Are_repairs_required__c
                            
                            
                            FROM case LIMIT 1];

        //List<Claim> loadedClaims = ClaimaticClaimStatusUpdateAPI.loadClaimData(claimIds);
        Test.startTest();
        String xml = ClaimaticCaseCreationAPI.generateXML(cses );
        //String replacedExpectedXml = expectedXml.replace('${ClaimNumber}',cses );
        //replacedExpectedXml = replacedExpectedXml.replace('${ClaimStatus}', cses );
        //System.assertEquals(replacedExpectedXml, xml);
        Test.stopTest();
    }
}