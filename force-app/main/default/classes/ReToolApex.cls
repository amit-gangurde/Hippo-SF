/************************************************************************************************************************************
Author : Amit Gangurde
Description : This class used in the LWC component for the ReTool Application .
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         			           22/09/2022     Amit Gangurde     Initial Development
**************************************************************************************************************************************/

public class ReToolApex {
    
    @AuraEnabled(cacheable=true)
    public static string PodLeadIds (id RecId){
        
        Id recordId;
        String recToolExternalPolicyId = null; 
        String recToolURL = null; 
        List<Case> recordData = [SELECT Id,RecordType.Name from CASE WHERE Id=:RecId];
        String recordTypeName = recordData[0].RecordType.Name;
        List <ReTool_Setting__mdt> retool_Setting = [SELECT RecordTypeName__c,URL__c FROM ReTool_Setting__mdt where RecordTypeName__c =: recordTypeName ];
        for(ReTool_Setting__mdt obj : retool_Setting){
            if(obj.URL__c != null){
                recToolURL = obj.URL__c;                
            }
        }
        if(recordTypeName == 'UW-Prebind'){
            List<Case> results = [SELECT Lead_and_Referral__r.POD_Lead_Id__c from CASE WHERE Id=:RecId]; 
            if(!results.isEmpty()) {
                recToolExternalPolicyId = results[0].Lead_and_Referral__r.POD_Lead_Id__c; 
                recToolURL = recToolURL.replace('=', '='+recToolExternalPolicyId);
                recToolURL = recToolURL+'&_environment=production';                
                return recToolURL;  
            }
            
        }
        else if ((recordTypeName == 'UW-New Business') || (recordTypeName == 'UW-Renewal')) {
            List<InsurancePolicy> result = [SELECT POD_Policy_Uuid__c from InsurancePolicy WHERE case__C =:RecId];
            if(!result.isEmpty()) {               
                recToolExternalPolicyId = result[0].POD_Policy_Uuid__c;   
                recToolURL = recToolURL.replace('?', '?'+recToolExternalPolicyId); 
                recToolURL = recToolURL+'_environment=dev&_releaseVersion=latest';  
                return recToolURL;  
            } 
        }  
        return null;  
    } 
}