@isTest
public class InsurencePolicyMatchingJobTest {
    @TestSetup static void initiateTestData(){
        Account acc = new Account();
        acc.Name = 'TestAccount';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'ConLast';
        con.AccountId = acc.Id;
        insert con;
        
         Contact con1 = new Contact();
        con1.LastName = 'ConLast';
        con1.AccountId = acc.Id;
        insert con1;
        
         Contact con2 = new Contact();
        con2.LastName = 'ConLast';
        con2.AccountId = acc.Id;
        insert con2;
        
        Producer_Licensing__c prodL = new Producer_Licensing__c();
        prodL.Name = 'ProdL';
        insert prodL;
        
           Carrier_Appointment__c testCarrierAppointment = new Carrier_Appointment__c(Name = 'Carrier Appointment Name',contact__c = con.id,State_Code__c ='ca');

        insert testCarrierAppointment;
        
        Carrier_Appointment__c testCarrierAppointment1 = new Carrier_Appointment__c(Name = 'Carrier Appointment Name',contact__c = con1.id,State_Code__c ='ca');

        insert testCarrierAppointment1;
        
         Carrier_Appointment__c testCarrierAppointment2 = new Carrier_Appointment__c(Name = 'Carrier Appointment Name',contact__c = con2.id,State_Code__c ='ca');

        insert testCarrierAppointment2;
        
        License__c testLicense = new License__c();
        testLicense.Name = 'License Name';
        testLicense.Active__c = 'Yes';
        testLicense.Contact__c = con.id;
        testLicense.Producer_Licensing__c = prodL.Id;
        testLicense.State_Code__c='ca';
        insert testLicense;
        
        License__c testLicense1 = new License__c();
        testLicense1.Name = 'License Name1';
        testLicense1.Active__c = 'Yes';
        testLicense1.Contact__c = con.id;
        testLicense1.Producer_Licensing__c = prodL.Id;
        insert testLicense1;
        
        License__c testLicense2 = new License__c();
        testLicense2.Name = 'License Name1';
        testLicense2.Active__c = 'Yes';
        testLicense2.Contact__c = con1.id;
        testLicense2.Producer_Licensing__c = prodL.Id;
       // testLicense2.State_Code__c= 'CA';
        insert testLicense2;
        
        Producer prod = new Producer();
        prod.Name = 'Prod';
        prod.AccountId = acc.Id;
        prod.ContactId = con.id;
        insert prod;
        
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
        ins.Producer__c = con.id;
        ins.State__c = 'CA';
        ins.Zip__c = '12345';
        ins.Water_backup__c = 7777.0;
        ins.Effective_Date__c = Date.newInstance(2021,1,2);
        ins.Effective_Time__c = Time.newInstance(12,5,5,0);
        ins.ExpirationDate = Datetime.newInstance(2022,1,2,12,5,5);
        ins.Actual_cash_value_on_roof_requested__c = false;
        ins.ProducerId = prod.Id;
        insert ins;
        
         InsurancePolicy ins1 = new InsurancePolicy();
        ins1.NameInsuredId = acc.Id;
        ins1.Name = 'name';
        ins1.Type__c = 'test';
        ins1.Coverage_A_Dwelling_rebuilding__c = 1111111.0;
        ins1.Coverage_B_Separate_structure__c = 22222.0;
        ins1.Coverage_C_Personal_property__c = 3333.0;
        ins1.Coverage_D_Loss_of_use__c = 444444.0;
        ins1.Coverage_E__c = 5555.0;
        ins1.Coverage_F__c = 666666.0;
        ins1.Deductible__c = 1234.0;
        ins1.Wind_Deductible__c = 567.0;
        ins1.PolicyType = 'Home';
        ins1.Street__c = '12345 femptown drive';
        ins1.City__c = 'femperton';
        ins1.Producer__c = con1.id;
        ins1.State__c = 'CA';
        ins1.Zip__c = '12345';
        ins1.Water_backup__c = 7777.0;
        ins1.Effective_Date__c = Date.newInstance(2021,1,2);
        ins1.Effective_Time__c = Time.newInstance(12,5,5,0);
        ins1.ExpirationDate = Datetime.newInstance(2022,1,2,12,5,5);
        ins1.Actual_cash_value_on_roof_requested__c = false;
        ins1.ProducerId = prod.Id;
        //insert ins1;
        
         InsurancePolicy ins2 = new InsurancePolicy();
        ins2.NameInsuredId = acc.Id;
        ins2.Name = 'name';
        ins2.Type__c = 'test';
        ins2.Coverage_A_Dwelling_rebuilding__c = 1111111.0;
        ins2.Coverage_B_Separate_structure__c = 22222.0;
        ins2.Coverage_C_Personal_property__c = 3333.0;
        ins2.Coverage_D_Loss_of_use__c = 444444.0;
        ins2.Coverage_E__c = 5555.0;
        ins2.Coverage_F__c = 666666.0;
        ins2.Deductible__c = 1234.0;
        ins2.Wind_Deductible__c = 567.0;
        ins2.PolicyType = 'Home';
        ins2.Street__c = '12345 femptown drive';
        ins2.City__c = 'femperton';
        ins2.Producer__c = con2.id;
        ins2.State__c = 'CA';
        ins2.Zip__c = '12345';
        ins2.Water_backup__c = 7777.0;
        ins2.Effective_Date__c = Date.newInstance(2021,1,2);
        ins2.Effective_Time__c = Time.newInstance(12,5,5,0);
        ins2.ExpirationDate = Datetime.newInstance(2022,1,2,12,5,5);
        ins2.Actual_cash_value_on_roof_requested__c = false;
        ins2.ProducerId = prod.Id;
        //insert ins2;
        
        Insurance_Policy_License__c insP = new Insurance_Policy_License__c();
        insert insP;
        
    }
    @isTest static void insurePolicyBatchTest(){
     Test.startTest(); 
       Database.executeBatch(new InsurencePolicyMatchingJob(),50); 
         Database.executeBatch(new InsurancePolicyJunctionDltBatch(),50); 
    Test.stopTest();
    }
    @isTest static void insurePolicyScheduleTest(){
        Test.startTest();
        System.schedule('InsurencePolicyMatchingJob 1', '0 0 * * * ?', new InsurencePolicyMatchingJob());
        Test.stopTest();
  }
}