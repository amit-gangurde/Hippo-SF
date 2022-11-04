/***************************************************************************************************
* Class Name  : PriceIncreaseRenewalsLeadsHandler
* Test Class  : PriceIncreaseRenewalsLeadsTest
* Author      : Dinesh Selvam
* Purpose     : The main purpose of the batch to fetch the price increase above 35% policies and 
*                create a renewal lead for that policy. 
* LastModifiedBy : Dinesh Selvam @ 06/08/2022
* *************************************************************************************************/
public class PriceIncreaseRenewalsLeadsHandler {
    /********** Constant Values *************************************/
    public static String QueueName = 'HAS Price Increase Renewals';
    public static String LeadSource = 'Price Increase Renewals';
    public static String LeadName = ' Renewal Lead';
    public static String className = 'PriceIncreaseRenewalsLeadsHandler';
    public static String methodName = 'handleRenewalLeads';
    /****************************************************************/
    
    public static void handleRenewalLeads(List<InsurancePolicy> insurancePolicyList){
        try{
            Id hasRenewalQueueId = [SELECT ID,Name FROM Group WHERE Type ='Queue' AND Name =: QueueName ]?.Id;
            List<Lead> renewalLeadInsertion = new List<Lead>();
            for(InsurancePolicy insPolicy: insurancePolicyList){
                Lead leadOBJ = new Lead();
                leadOBJ.OwnerId = hasRenewalQueueId;
                leadOBJ.Organization__c = insPolicy.Organization__c;
                leadOBJ.Lead_Source__c = LeadSource;
                leadOBJ.Insurance_Policy__c = insPolicy.Id;
                leadOBJ.Company = insPolicy.NameInsuredId!=null?insPolicy.NameInsured.Name:'';
                leadOBJ.LastName = insPolicy.NameInsuredId!=null?insPolicy.NameInsured.LastName:'N/A';
                leadOBJ.FirstName = insPolicy.NameInsuredId!=null?insPolicy.NameInsured.FirstName:'';
                leadOBJ.Street = insPolicy.Street__c;
                leadOBJ.State = insPolicy.State__c;
                leadOBJ.PostalCode = insPolicy.Zip__c;
                leadOBJ.Renewal_Offered_Premium__c = insPolicy.Renewal_Policy_Premium__c;
                leadOBJ.Premium__c = insPolicy.Current_Policy_Premium__c;
                leadOBJ.Renewal_offered_date__c = insPolicy.Date_Renewal_Offer_Sent__c;
                if(insPolicy.RenewalDate!=null){
                leadOBJ.Renewal_Date__c = date.newinstance(insPolicy.RenewalDate.year(), insPolicy.RenewalDate.month(), insPolicy.RenewalDate.day());
                }
                leadOBJ.Renewal_policy_status__c = insPolicy.Renewal_Policy_Status__c;
                leadOBJ.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales').getRecordTypeId();
                leadOBJ.YoY_Premium_Increase_Amount__c = insPolicy.YoY_Premium_Increase__c;
                leadOBJ.Customer_Segment_InsurancePolicy__c = insPolicy.Customer_Segment__c;
                leadOBJ.Price_Increase_Renewals_Lead_Upsert__c = insPolicy.id+':'+insPolicy.Date_Renewal_Offer_Sent__c;
                //B2C Sales recordType
                //Workable by hippo = yes
                renewalLeadInsertion.add(leadOBJ);
            }
           List<Database.UpsertResult> upsertResults =  Database.upsert(renewalLeadInsertion,Lead.Price_Increase_Renewals_Lead_Upsert__c,false);
            for(Database.UpsertResult res: upsertResults){
                if(res.isSuccess()){
                    ClaimaticAPIUtility.createLogRecord(null,'DML',className,methodName,'InsurancePolicy',res.Id,'Lead Created for the InsurancePolicy','Success'); 
                }else if(!res.isSuccess() && res.getErrors().size()>0){
                    ClaimaticAPIUtility.createLogRecord(null,'DML',className,methodName,'InsurancePolicy',res.Id,String.valueOf(res.getErrors()[0]),'Error'); 
                    
                }
            }
            System.debug('upsertResults: '+upsertResults);
            //insert renewalLeadInsertion;
        }catch(Exception e){
            ClaimaticAPIUtility.createLogRecord(e,'DML',className,methodName,'InsurancePolicy',null,'Error Occured','Error');   
        }
    }
}