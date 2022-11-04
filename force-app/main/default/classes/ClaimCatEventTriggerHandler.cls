public without sharing class ClaimCatEventTriggerHandler extends TriggerHandler {

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    
    private Map<String, String> claimCatEventPerilLabelToValueMap {
        get {
            if (claimCatEventPerilLabelToValueMap == null) {
                claimCatEventPerilLabelToValueMap = new Map<String, String>();
                for (Schema.PicklistEntry pickListVal : Claim_Cat_Event__c.Perils__c.getDescribe().getPicklistValues()){
                    claimCatEventPerilLabelToValueMap.put(pickListVal.getValue(), pickListVal.getLabel());
                }   
            }
            return claimCatEventPerilLabelToValueMap;
        }
        set;
    }
    
    private Map<String, String> claimPerilLabelToValueMap {
        get {
            if (claimPerilLabelToValueMap == null) {
                claimPerilLabelToValueMap = new Map<String, String>();
                for (Schema.PicklistEntry pickListVal : Claim.Peril__c.getDescribe().getPicklistValues()){
                    claimPerilLabelToValueMap.put(pickListVal.getValue(), pickListVal.getLabel());
                }   
            }
            return claimPerilLabelToValueMap;
        }
        set;
    }
    
    public ClaimCatEventTriggerHandler() {

        if (!Test.isRunningTest())
            this.setMaxLoopCount(100);

       
    }

    public override void afterInsert() {
        updateMatchingClaims();
        
    }

    public override void afterUpdate() {
        updateMatchingClaims();
        
    }
    
    
    private void updateMatchingClaims() {
        
        Map<Id, Claim> claimsToUpdate = new Map<Id, Claim>();
        
        Set<String> perils = new Set<String>();
        Set<String> policyStates = new Set<String>();
        Set<String> policyZipCodes = new Set<String>();
        Date minFromDate;
        Date maxToDate;
        
        List<Claim_Cat_Event__c> affectedClaimCatEvents = new List<Claim_Cat_Event__c>();
        Set<Id> setCatIds = new Set<Id>();
        for (Claim_Cat_Event__c claimCatEvent : (List<Claim_Cat_Event__c>) Trigger.new) {
            
            if (fieldIsChanged(claimCatEvent, 'Perils__c')) {
                setCatIds.add(claimCatEvent.Id);
                affectedClaimCatEvents.add(claimCatEvent);
            }
            
            if (fieldIsChanged(claimCatEvent, 'States__c')) {
                policyStates.addAll(claimCatEvent.States__c.split(';'));
                setCatIds.add(claimCatEvent.Id);
                affectedClaimCatEvents.add(claimCatEvent);
            }
            
            if (fieldIsChanged(claimCatEvent, 'Zip_Codes__c') && claimCatEvent.Zip_Codes__c != null) {
                policyZipCodes.addAll(claimCatEvent.Zip_Codes__c.split(';'));
                setCatIds.add(claimCatEvent.Id);
                affectedClaimCatEvents.add(claimCatEvent);
            }
            
            if (fieldIsChanged(claimCatEvent, 'From_Date__c')) {
                if (minFromDate == null || minFromDate > claimCatEvent.From_Date__c) {
                    minFromDate = claimCatEvent.From_Date__c;
                }
                setCatIds.add(claimCatEvent.Id);
                affectedClaimCatEvents.add(claimCatEvent);
            }
            
            if (fieldIsChanged(claimCatEvent, 'To_Date__c')) {
                if (maxToDate == null || maxToDate < claimCatEvent.To_Date__c) {
                    maxToDate = claimCatEvent.To_Date__c;
                }
                setCatIds.add(claimCatEvent.Id);
                affectedClaimCatEvents.add(claimCatEvent);
            }
            
        }
        if (!affectedClaimCatEvents.isEmpty()) {
            
            String query = 'SELECT Id, CATCode__c , Name, CreatedDate, Peril__c, State__c, Zip__c, Date_of_Loss__c, Claim_Cat_Event__c FROM Claim WHERE CreatedDate != NULL';
            /*
            if (perils.size() > 0) {
                query += ' AND Peril__c IN :perils';
                System.debug(perils);
            }
			*/
            if (policyStates.size() > 0) {
                query += ' AND State__c IN :policyStates';
            }
            /*
            if (policyZipCodes.size() > 0) {
                query += ' AND Zip__c IN :policyZipCodes';
            }
			*/
            
            if (minFromDate != null) {
                query += ' AND Date_of_Loss__c >= :minFromDate';
            }
            if (maxToDate != null) {
                query += ' AND Date_of_Loss__c <= :maxToDate';
            }
            
            System.debug('query: ' + query);
            Map<Id, Claim> claimsMap = new Map<Id, Claim>((List<Claim>) Database.query(query));
            if (!setCatIds.isEmpty()) {
                for (Claim claims : [SELECT Id, CATCode__c , Name, CreatedDate, Peril__c, State__c, Zip__c, Date_of_Loss__c, Claim_Cat_Event__c 
                                     FROM Claim
                                     WHERE Claim_Cat_Event__c IN: setCatIds]) {
                                         
                                         if (!claimsMap.containskey(claims.ID)) {
                                             claimsMap.put(claims.Id, claims);
                                         }
                    
                }
            }
            //affectedClaimCatEvents = [SELECT ID,Perils__c,From_Date__c,To_Date__c,Cat_Code__c,Zip_Codes__c, States__c  FROM Claim_Cat_Event__c];
            System.debug('-------claimsMap.size()='+claimsMap.size());
            Map<Id, Claim_Cat_Event__c> claimCatEventsToUpdateMap = new Map<Id, Claim_Cat_Event__c>();
            Set<Id> claimIds = new Set<Id>();
			for (Claim claim : claimsMap.values()) {
               Map<Id, Claim_Cat_Event__c> mapClaimCatEvent  = new Map<Id, Claim_Cat_Event__c>();
               
               for (Claim_Cat_Event__c claimCatEvent : affectedClaimCatEvents) {
                   if (claimCatEvent.Id == claim.Claim_Cat_Event__c) {
                       claimIds.add(claim.Id);
                   }
                    if (containsLabel(claimCatEvent.Perils__c, claim.Peril__c)
                        && (claim.State__c != null && claimCatEvent.States__c.toLowerCase().split(';').contains(claim.State__c.toLowerCase()))
                        && (claim.Date_of_Loss__c != null && 
                            (claimCatEvent.From_Date__c <= claim.Date_of_Loss__c && claimCatEvent.To_Date__c >= claim.Date_of_Loss__c))) {
                            mapClaimCatEvent.put(claim.Id, claimCatEvent);
                            System.debug('-------------claim2='+claim);
                            if (claimCatEvent.Zip_Codes__c != null) {
                                if (claimCatEvent.Zip_Codes__c.toLowerCase().split(';').contains(claim.Zip__c)) {
                                    claim claimUpdate = new Claim(Id = claim.Id, Claim_Cat_Event__c = claimCatEvent.Id, CATCode__c = claimCatEvent.Cat_Code__c);
                                    System.debug('-------------claim='+claim);
                                    claimsToUpdate.put(claim.Id, claimUpdate);
                                    claimIds.remove(claim.Id);
                                    continue ;
                                }
                                
                            }     
                         }
                }
                if (!claimsToUpdate.containskey(claim.Id) && !mapClaimCatEvent.isEmpty() && mapClaimCatEvent.containskey(claim.Id)) {
                        
                    System.debug('-------------claimCatEvent2='+mapClaimCatEvent.get(claim.Id));
                    claim claimUpdate = new Claim(Id = claim.Id, Claim_Cat_Event__c = mapClaimCatEvent.get(claim.Id).Id, CATCode__c = mapClaimCatEvent.get(claim.Id).Cat_Code__c);
                    System.debug('-------------claimsToUpdate inside 167='+claim);
                    claimsToUpdate.put(claim.Id, claimUpdate);
                    claimIds.remove(claim.Id);
            	}
            }
            ClaimTriggerHandler.SKIP_RECURSION = true;
            System.debug('-------------claimsToUpdate='+claimsToUpdate.size());
            if (!claimsToUpdate.isEmpty()) {
                if (!claimIds.isEmpty()) {
                   for (Id claimId : claimIds) {
                       claim claimUpdate = new Claim(Id = claimId, Claim_Cat_Event__c = null, CATCode__c = '');
               		   claimsToUpdate.put(claimId, claimUpdate);
                   }
                	Map<Id, Claim> claimsWithUpdatedEvents = ClaimTriggerHandler.buildClaimsToUpdate(claimIds, false);
                    if (!claimsWithUpdatedEvents.isEmpty()) {
                        for (Id claimId : claimsWithUpdatedEvents.Keyset()) {
                            if(claimsToUpdate.containskey(claimId)) {
                                claimsToUpdate.put(claimId, claimsWithUpdatedEvents.get(claimId));
                            }
                        }
                    }
            	}
                
                System.debug('-------------claimsToUpdate='+claimsToUpdate.size());
                for (Claim claim : claimsToUpdate.values()) {
                    System.debug('-------------claim=='+claim);
                }
                List<Database.SaveResult> results = Database.update(claimsToUpdate.values(), false);
                System.debug(' ==== Claims ==== ');
                for (Database.SaveResult result : results) {
                    System.debug('Successfully inserted account. Account ID: ' + result.getId());
                    System.debug('RESULT  ====  ' + result);
                }
            }
            ClaimTriggerHandler.SKIP_RECURSION = false;
        }
    }
    
    private Boolean fieldIsChanged(Claim_Cat_Event__c claimCatEvent, String fieldApiName) {
        if (Trigger.isInsert && Trigger.isBefore || Trigger.isAfter && Trigger.isDelete) {
            throw new DmlException('You dont have id on Before Insert and on After Delete DML operations');
        }

        return Trigger.isInsert || Trigger.newMap.get(claimCatEvent.Id).get(fieldApiName) != Trigger.oldMap.get(claimCatEvent.Id).get(fieldApiName);
    }
    
    private Boolean containsLabel(String claimCatEventField, String claimField) {
        List<String> claimCatEventFieldLabels = new List<String>();        
        for (String claimCatEventFieldValue : claimCatEventField.split(';')) {
            claimCatEventFieldLabels.add(claimCatEventPerilLabelToValueMap.get(claimCatEventFieldValue));
        }
        if (!claimCatEventFieldLabels.contains(claimPerilLabelToValueMap.get(claimField))) {
            return false;
        }
        return true;
    }
  }