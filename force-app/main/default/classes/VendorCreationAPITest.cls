@isTest
public class VendorCreationAPITest {
    @TestSetup static void initiateTestData(){
          PaymentAuth_Integration_System__c setting = new PaymentAuth_Integration_System__c();
        setting.Base_URL__c = 'https://servicesqa.insurpay.com:9441/hippo_app_dev/custom/service/v4_1_custom/rest.php';
        setting.Password__c = '3d160bf1743f184834468c0174e9d5dd';
        //setting.URL_Encoded_Body__c = 'Whatever';
        setting.User_Name__c = 'hpouser01';
        insert setting;
           Claim_Vendor__c v = new Claim_Vendor__c(Name = 'name',
                Contact_Email__c = 'test@test.com',
                Contact_Name__c = 'name',
                Contact_Phone__c = '1234567890',
                Category__c = 'Remediation',
                Country__c = 'US',
                Claimatic_Integration_ID__c = '5555500000'+'name'); // added on 11/17/2021 5:41 pm EST
        insert v;
    }
    @isTest static void testVendor(){
        Test.startTest();
         Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Claim_Vendor__c claim = [SELECT ID FROM Claim_Vendor__c LIMIT 1];
        VendorCreationAPI.createVendor(claim.id);
         List<Claim_Vendor__c> claim1 = [SELECT ID,Name,Business_type__c,Business_Sub_Type__c,Status__c,Category__c,Country__c,City__c,Contact_Email__c,Contact_Name__c,Contact_Phone__c,State__c,Street__c,Street_2__c,Website__c,Zip_Code__c,Business_TIN__c,Business_TIN_type__c FROM Claim_Vendor__c];
            
        VendorCreationAPI.handleFromTrigger(claim1);
        Test.stopTest();
    }
}