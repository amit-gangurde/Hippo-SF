/************************************************************************************************************************************
Author : Amit Gangurde
Description : This class used to associate pertinent Cat events to claims based on specific criteria.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1            SFDC-2117        07/10/2022     Amit Gangurde     Initial Development
**************************************************************************************************************************************/

public class CatEventClaimController {
    public static void attachReleventCatEventToClaim(List<Claim> claimList){
        try {
            List<Claim> claimToBeUpdate = New List<Claim>();
            Set<String> setState = new Set<String>();
            for (Claim claimObj :claimList){
                if(claimObj.State__c != null) {
                    setState.add(claimObj.State__c);
                }
            }
            if(!claimList.isEmpty() && !setState.isEmpty()){
                List<Claim_Cat_Event__c> claimCatEventRecords = [ SELECT Id, From_Date__c , To_Date__c, Perils__c, States__c, Status__c 
                                                                  FROM Claim_Cat_Event__c 
                                                                  WHERE status__C='Active' 
                                                                        AND States__c IN:setState];
                for (Claim claimObj :claimList){
                    for (Claim_Cat_Event__c claimCatEvent : claimCatEventRecords){
                        Claim claims = new Claim();
                        if(claimObj.Date_of_Loss__c >= claimCatEvent.From_Date__c && claimObj.Date_of_Loss__c <= claimCatEvent.To_Date__c) {
                            if(claimObj.State__c == claimCatEvent.States__c) {
                                String claimPerilName = claimObj.Peril__c; 
                                String catPerilName = claimCatEvent.Perils__c;
                                if(claimCatEvent.Perils__c.containsIgnoreCase(claimObj.Peril__c)){    
                                    claims.Id = claimObj.Id;
                                    claims.Claim_Cat_Event__c = claimCatEvent.Id;
                                    claimToBeUpdate.add(claims); 
                                }                        
                            }
                        }
                    }
                }
            }
            if(!claimToBeUpdate.isEmpty()){
                update claimToBeUpdate;
            }
            
        }
        catch(exception ex) {
            smagicinteract__Error_Log__c exceptionLog = new smagicinteract__Error_Log__c();
            exceptionLog.smagicinteract__Class_Name__c = 'CatEventClaimController';
            insert exceptionLog;
        }       
        
    }
}