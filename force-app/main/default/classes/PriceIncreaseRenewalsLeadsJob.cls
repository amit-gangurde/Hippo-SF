/***************************************************************************************************
* Class Name  : PriceIncreaseRenewalsLeadsJob
* Test Class  : PriceIncreaseRenewalsLeadsTest
* Author      : Dinesh Selvam
* Purpose     : The main purpose of the batch to fetch the price increase above 35% policies and 
*               create a renewal lead for that policy. 
* LastModifiedBy : Dinesh Selvam @ 06/08/2022
* *************************************************************************************************/
public class PriceIncreaseRenewalsLeadsJob implements Database.Batchable<sObject>,schedulable {
    public static Id HippoInsurancePolicyRecType = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByName().get('Hippo Insurance Policy').getRecordTypeId();
    public String renewalStatus = System.Label.Price_Increase_Renewals_Leads_renewal_Status;
    public decimal renewalIncreasedPercentage = Decimal.valueOf(System.Label.Price_Increase_Renewals_Leads_Percentage);
    public void execute(SchedulableContext sc){
        Database.executeBatch(new PriceIncreaseRenewalsLeadsJob(),100);
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Name,NameInsuredId,NameInsured.FirstName,NameInsured.LastName,Renewal_Policy_Premium__c,Current_Policy_Premium__c,Renewal_Review_Date__c,Renewal_Policy_Status__c,NameInsured.Name,Street__c,State__c,Zip__c,RenewalDate,YoY_Premium_Increase__c,Customer_Segment__c,Date_Renewal_Offer_Sent__c,Organization__c FROM InsurancePolicy WHERE Date_Renewal_Offer_Sent__c = LAST_N_DAYS:7 AND Status =\'Active\' AND (Renewal_Policy_Status__c =:renewalStatus OR Renewal_Policy_Status__c =\'Pending Active\') AND YoY_Premium_Increase_Percentage_Formula__c > :renewalIncreasedPercentage AND RecordTypeId =: HippoInsurancePolicyRecType';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<InsurancePolicy> insPolicyList) {
        PriceIncreaseRenewalsLeadsHandler.handleRenewalLeads(insPolicyList);
    }
    public void finish(Database.BatchableContext BC) {
        system.debug('**************BATCH COMPLETED************************');
    }
}