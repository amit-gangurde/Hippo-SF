/************************************************************************************************************************************
Author : Amit Gangurde
Description : This class used in the LWC component for the related cases on case record page based on the AccountID.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         			               14/09/2022     Amit Gangurde     Initial Development
**************************************************************************************************************************************/

public class AccRelatedCases {
    
    @AuraEnabled(cacheable=true)
    public static List<Case> fetchCases (id RecId){
        Id accId = null;
        String recordTypeName = null;
        List<Case> lstCase = [SELECT AccountId,recordType.Name FROM Case WHERE Id=:RecId];
        accId = lstCase[0].accountId;
        recordTypeName = lstCase[0].recordType.Name;       
        if(accId != null){   
            //Fetching similar recordType Id Cases
            string query = 'SELECT Id,CaseNumber,Status,RecordType.Name,CreatedDate FROM Case WHERE AccountId =:accId and RecordType.Name =:recordTypeName';                  
            return Database.query( query );
        }
        return null;
        
        
    }  
}