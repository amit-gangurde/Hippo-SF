@isTest
public class PriceIncreaseRenewalsLeadsTest {
    @TestSetup static void initiateTestData(){
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'Last';
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
        ins.Name = 'PriceRenewalInsTest';
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
        ins.Date_Renewal_Offer_Sent__c = System.today()-1;
        ins.Status = 'Active';
        ins.Renewal_Policy_Status__c = 'pending active';
        ins.Renewal_Policy_Premium__c = 1550;
        ins.Current_Policy_Premium__c = 100;
        ins.YoY_Premium_Increase_Percentage__c = 40;
        ins.RecordTypeId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByName().get('Hippo Insurance Policy').getRecordTypeId();
        insert ins;
    }
    @isTest static void testBatch(){
        
        Test.startTest();
        String jobID = System.schedule('PrinceRenewalLeadJob', '0 0 22 * * ? *' , new PriceIncreaseRenewalsLeadsJob());
        Test.stopTest();
    }
}