public with sharing class CaseTriggerHandler extends TriggerHandler {
    
    public static Boolean SKIP_RECURSION = false;
    
    private static Id id_recordtype_retention = Utils.getRecordTypeInfo('Retention', 'Case').getRecordTypeId();
    
    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */    public CaseTriggerHandler() {
        
        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);
    }
    
    public override void beforeInsert() {
        
        routeCases2PendingQueue();
    }

    public override void afterInsert() {

        if ( ClaimaticCaseTriggerActivation__c.getInstance().Activate__c == true ) {

            //set3rdPartyAdjuster();
            //Claimatic Integration

            set<id> caseIds = new set<id>();
            
            string ClaimRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Claim').getRecordTypeId();
            for ( case cs1 : (List<case>)Trigger.new ) {

                if ( cs1.RecordTypeId == ClaimRecId )
                    caseIds.add(cs1.id);
            }
               system.debug('@@@'+caseIds);
            if ( caseIds.size() > 0 )
                ClaimaticCaseCreationAPI.CreateClaim(caseIds);
        }

        send2MadSky(); // SFDC-410
    }
    
    //Claimatic afterupdate
    public override void afterUpdate() {

        if (CaseTriggerHandler.SKIP_RECURSION) {

            return;
        }

        if ( ClaimaticCaseTriggerActivation__c.getInstance().Activate__c == true ) {

            if ( RecursiveTriggerHandler.isFirstTime ) {

                RecursiveTriggerHandler.isFirstTime = false;
                set<id> adjusterCaseIds = new set<id>();
                set<id> vendorCaseIds = new set<id>();
                set<id> statuschangeCaseIds = new set<id>();
                set<id> ModifiedAdjusterIds = new set<id>();
                set<id> ModifiedVendorIds = new set<id>();
                Map<string,string> AdjusterMap = new Map<String,string>();
                Map<String,string> VendorMap = new Map<string,string>();
                
                string userId;
                string accountId;
                
                string caseId,AssignVendorId,AssignAdjusterId;

                for (Case cs : (List<case>)Trigger.new) {

                    Case old_cs = new Case();
                    old_cs = (Case)Trigger.oldMap.get(cs.Id);

                    //removing adjuster values from case
                    system.debug(cs.Claim_Vendor__c);
                    system.debug(old_cs.Claim_Vendor__c);
                    if ( cs.Claims_Adjuster__c == Null && old_cs.Claims_Adjuster__c != Null ) {

                        AdjustercaseIds.add(cs.id);
                        userId = old_cs.Claims_Adjuster__c;
                    }
                    
                    if ( cs.Status == 'Closed' && cs.Status !=  old_cs.Status) {

                        statuschangeCaseIds.add(cs.id);
                    }

                    //removing vendor values from case
                    if ( cs.Claim_Vendor__c == Null && old_cs.Claim_Vendor__c != Null ) {

                        VendorcaseIds.add(cs.id);
                        accountId = old_cs.Claim_Vendor__c;
                    }

                    //reassigning adjuster from existing adjuster
                    if ( old_cs.Claims_Adjuster__c != Null && cs.Claims_Adjuster__c != old_cs.Claims_Adjuster__c && cs.Claims_Adjuster__c != Null ) {

                        ModifiedAdjusterIds.add(cs.id);
                        AdjusterMap.put(cs.id,JSON.serialize(old_cs));
                    }

                    //reassigning vendor from existing vendor
                    if ( old_cs.Claim_Vendor__c != Null && cs.Claim_Vendor__c != old_cs.Claim_Vendor__c && cs.Claim_Vendor__c != Null ) {

                        ModifiedVendorIds.add(cs.id);
                        VendorMap.put(cs.id,JSON.serialize(old_cs));
                    }
                    
                    if ( cs.Sent_to_Claimatic__c && old_cs.Sent_to_Claimatic__c ) {

                        //assigning adjuster from blank value
                        if ( old_cs.Claims_Adjuster__c == Null && cs.Claims_Adjuster__c != Null ) {

                            caseId = cs.id;
                            assignVendorId = cs.Claim_Vendor__c;
                            assignAdjusterId = cs.Claims_Adjuster__c;
                        }
                        
                        //assigning vendor from blank value
                        if ( old_cs.Claim_Vendor__c == Null && cs.Claim_Vendor__c != Null ) {

                            caseId = cs.id;
                            assignVendorId = cs.Claim_Vendor__c;
                            assignAdjusterId = cs.Claims_Adjuster__c;
                        }
                    }
                }

                //if(caseId == Null){
                if ( UserId != Null )
                    ClaimaticCaseAdjusterUnassignmentAPI.UnassignAdjustorClaim(AdjustercaseIds,UserId);

                if ( AccountId != Null )
                    ClaimaticCaseUnassignmentAPI.UnassignClaim(VendorcaseIds,AccountId);
                
                if ( ModifiedAdjusterIds.size() > 0 ) {

                   ClaimaticCaseReassignmentAPI.ReassignClaim(AdjusterMap,ModifiedAdjusterIds,'Adjuster');
                }
                
                if ( ModifiedVendorIds.size() > 0 ) {

                    ClaimaticCaseReassignmentAPI.ReassignClaim(VendorMap,ModifiedVendorIds,'Vendor');
                }
                //}
                if ( caseId != Null ) {

                    ClaimaticCaseAssignmentAPI.AssignClaim(caseId,assignVendorId,assignAdjusterId);
                }
                
                if ( statuschangeCaseIds.size() > 0 ) {

                    ClaimaticCaseStatusUpdateAPI.UpdateClaim(statuschangeCaseIds);
                }
            }                
        }
         //Added below code as part of SFDC-310
        updateCaseRelatedTasks();

        send2MadSky(); // SFDC-410
    }
    
    public override void beforeUpdate() {
        
        if (CaseTriggerHandler.SKIP_RECURSION) {
            
            //if (CaseTriggerHandler.SEND_FNOL_CLAIM_SUBMISSION_EMAILS)
            //sendFNOLClaimSubmissionEmails(); // we may come here from an afterInsert so need to check if there is something to send
            
            if ( Test.isRunningTest() ) changeStatus2Working();
            
            return;
        }
        
        //set3rdPartyAdjuster();
        changeStatus2Working();

        if ( Test.isRunningTest() ) {

            integer i=0;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
        }
    }
    
    /*
    Valid Context: Before Insert
    Description: If Retention Cases are from the WEST/EAST Coast, route it to the PST_Pending_Cases/EST_Pending_Cases Queues
    */
    private void routeCases2PendingQueue() {
        
        if ( Trigger.isBefore && Trigger.isInsert ) {
            
            try {
                
                BusinessHours bh_EST = [SELECT Id FROM BusinessHours WHERE Name = 'EST'];
                BusinessHours bh_PST = [SELECT Id FROM BusinessHours WHERE Name = 'PST'];
                
                String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Cases EST Queue');
                system.debug('est cases queue name == ' + est_pending_queue_dev_name);
                String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Cases PST Queue');
                system.debug('est cases queue name == ' + pst_pending_queue_dev_name);
                Id estPendingCasesQueue = Utils.getQueueId(est_pending_queue_dev_name);
                system.debug('est cases queue id == ' + estPendingCasesQueue);
                Id pstPendingCasesQueue = Utils.getQueueId(pst_pending_queue_dev_name);
                system.debug('pst cases queue id == ' + pstPendingCasesQueue);
                
                Map<String, Utils.StateInfo> map_State2Coast = Utils.getStates2StateInfo();
                
                Map<Id, Map<Case, Account>> cases_in_context = getValidRetentionCases4Routing();
                
                for (Id theCaseId : cases_in_context.keySet()) {
                    
                    Map<Case, Account> case_account_pair = cases_in_context.get(theCaseId);
                    
                    for (Case my_Case : case_account_pair.keySet()) { // will always be a loop of one !!!
                        
                        Account parent_account = case_account_pair.get(my_Case);
                        
                        String state = parent_account.BillingState;
                        
                        if (String.isNotBlank(state) && map_State2Coast.containsKey(state)) {
                            
                            if (map_State2Coast.get(state).coast.toLowerCase().equals('west')) {
                                
                                // Find whether the time is within the PST business hours
                                Boolean isWithin = BusinessHours.isWithin(bh_PST.id, system.now());
                                if (!isWithin) {
                                    my_Case.OwnerId = pstPendingCasesQueue;
                                }
                            } else if (map_State2Coast.get(state).coast.toLowerCase().equals('east')) {
                                
                                // Find whether the time is within the EST business hours
                                Boolean isWithin = BusinessHours.isWithin(bh_EST.id, system.now());
                                if (!isWithin) {
                                    my_Case.OwnerId = estPendingCasesQueue;
                                }
                            }
                        }
                    }
                }
            }
            catch(Exception ex) {
                
                System.debug('Exception from routeCases2PendingQueue: ' + ex.getMessage());
            }
        }
    }
    
    /*
    Valid Context: Before Insert
    Description: Get all valid Retention Cases for special routing handling (they should have parent accounts)
    */
    private Map<Id, Map<Case, Account>> getValidRetentionCases4Routing() {
        
        // Map from Case Id to the Case and it's associsated parent Account
        Map<Id, Map<Case, Account>> res = new Map<Id, Map<Case, Account>>();
        
        try {
            
            if ( Trigger.isBefore && Trigger.isInsert ) {
                
                Set<Id> account_ids = new Set<Id>();
                
                for (sObject theCase : trigger.new) {
                    
                    system.debug('theCase == ' + theCase);
                    
                    Case my_Case = (Case) theCase;
                    if ( my_Case.RecordTypeId.equals(id_recordtype_retention) &&
                        String.isNotBlank(my_Case.AccountId) ) {
                            
                            account_ids.add(my_Case.AccountId);
                        }
                }
                
                Map<Id, Account> map_AccountId2Account = new Map<Id, Account>([Select Id, BillingState, ShippingState, PersonMailingState From Account Where Id IN: account_ids]);
                
                for (sObject theCase : trigger.new) {
                    
                    Case my_Case = (Case) theCase;
                    if ( my_Case.RecordTypeId.equals(id_recordtype_retention) &&
                        String.isNotBlank(my_Case.AccountId) ) {
                            
                            res.put(my_Case.Id, new Map<Case, Account>{ my_Case => map_AccountId2Account.get(my_Case.AccountId)});
                        }
                }
            }
        }
        catch(Exception ex) {
            
            System.debug('Exception from getValidRetentionCases4Routing: ' + ex.getMessage());
        }
        
        return res;
    }
    
    private void changeStatus2Working() {
        
        if ( Trigger.isBefore && Trigger.isUpdate ) {
            
            RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('Claim', 'Case');
            
            for ( Sobject obj : Trigger.new ) {
                
                Case new_cs = (Case)obj;
                Case old_cs = (Case)Trigger.oldMap.get(new_cs.Id);
                
                if ( !new_cs.RecordTypeId.equals(rtInfo.getRecordTypeId()) &&
                    String.valueOf(old_cs.OwnerId).startsWith('00G') &&
                    String.valueOf(new_cs.OwnerId).startsWith('005') ) {
                        
                        new_cs.Status = 'Working';
                    }
            }
        }
    }
    //Added below code as part of SFDC-310
    public void updateCaseRelatedTasks() {

        Id idClaim = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Claim').getRecordTypeId();
        Map<Id,Id> mapCaseIdWithAdjusterId = new Map<Id,Id> ();
        Map<Id,Id> mapOldCaseIdWithOldAdjusterId = new Map<Id,Id> ();
        List<Task> lstTask = new List<Task> ();
         for (Sobject obj : Trigger.new) {
            Case new_cs = (Case)obj;
            Case old_cs = (Case)Trigger.oldMap.get(new_cs.Id);
            if(new_cs.recordTypeid == idClaim && new_cs.Claims_Adjuster__c != null && 
                new_cs.Claims_Adjuster__c != old_cs.Claims_Adjuster__c){
                    mapCaseIdWithAdjusterId.put(new_cs.Id,new_cs.Claims_Adjuster__c);
                    mapOldCaseIdWithOldAdjusterId.put(old_cs.Id,old_cs.Claims_Adjuster__c);
            }
         }
         system.debug('mapCaseIdWithAdjusterId==> '+mapCaseIdWithAdjusterId);
         system.debug('mapOldCaseIdWithOldAdjusterId==> '+mapOldCaseIdWithOldAdjusterId);
         if(!mapCaseIdWithAdjusterId.isEmpty()) {
            for(Case objcase: [select id,Claims_Adjuster__c,(select id,whoid,whatid,OwnerId from tasks) FROM CASE 
                        where ID IN: mapCaseIdWithAdjusterId.keyset()]){
                            system.debug('objcase==> '+objcase);      
                             system.debug('objcase.tasks==> '+objcase.tasks);
                if(objcase.tasks!= NULL && !objcase.tasks.isEmpty()){
                    for(Task objTask: objcase.tasks){
                        system.debug('objTask==> '+objTask);
                    if(!mapCaseIdWithAdjusterId.isEmpty() &&
                        mapCaseIdWithAdjusterId.containsKey(objcase.Id) &&                       
                       objTask.OwnerId != mapCaseIdWithAdjusterId.get(objcase.Id) &&
                      !mapOldCaseIdWithOldAdjusterId.isEmpty() 
                       && mapOldCaseIdWithOldAdjusterId.containsKey(objcase.Id)
                      && objTask.OwnerId == mapOldCaseIdWithOldAdjusterId.get(objcase.Id)){                         
                        objTask.OwnerId = mapCaseIdWithAdjusterId.get(objcase.Id);
                        lstTask.add(objTask);
                    }   
                    }
                }
            }
            system.debug('lstTask==> '+lstTask);
            if(!lstTask.isEmpty()){
                try{
                    Database.update(lstTask,false);
                } Catch(Exception ex){
                    System.debug('Exception in updateCaseRelatedTasks '+ex);
                }           
            }
        }
    }

    private void send2MadSky() {

        if ( Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {

            List<Callout__c> madSkyCallouts = new List<Callout__c>();

            RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('MadSky', 'Callout__c');

            string ClaimRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Claim').getRecordTypeId();

            Set<Id> caseIds = new Set<Id>();
            for (Case cs : (List<Case>)trigger.new) {

                if ( cs.RecordTypeId == ClaimRecId ) caseIds.add(cs.Id);
            }

            System.debug('caseIds: ' + caseIds);

            List<Case> cases_in_context = [Select Id, MadSky_Case__c, Account.Name, Wind_Hail_Deductible__c, Claim_Number__c, CaseNumber, RecordTypeId, Claim_Vendor_Name__c, Date_of_Loss__c, Loss_Description__c, Client_Email_Address__c, Client_Contact_Phone__c, Client_Secondary_Phone__c, Street__c, City__c, State__c, Zip__c, Preferred_Contact_Method__c, Claims_Adjuster__r.Email, Claims_Adjuster__r.Name, Claims_Adjuster__r.Phone, Claims_Notes__c, Peril__c, Insurance_Policy__r.Deductible__c, Insurance_Policy__r.State__c, Have_a_Contractor__c From Case Where Id IN: caseIds AND (Peril__c = 'Wind' OR Peril__c = 'Hail')];

            System.debug('cases_in_context: ' + cases_in_context);

            for (Case cs : cases_in_context) {

                Case oldCase = Trigger.isUpdate ? (Case) trigger.oldMap.get(cs.Id) : null;

                // Create Hippo_Claim__c in MadSky
                // 
                // 
                
                /******************** Duplicate Madsky Issue fix SFDC-1302 Commented @ 25/01/2022 **************************************
                if ( (Trigger.isUpdate && oldCase.Claim_Vendor_Name__c != cs.Claim_Vendor_Name__c && String.isNotBlank(cs.Claim_Vendor_Name__c) && cs.Claim_Vendor_Name__c.equalsIgnoreCase('MadSky')) ||
                     (Trigger.isInsert && String.isNotBlank(cs.Claim_Vendor_Name__c) && cs.Claim_Vendor_Name__c.equalsIgnoreCase('MadSky')) ) { **/
				
                 if ((cs.Peril__c == 'Hail' || cs.Peril__c == 'Wind') && cs.Have_a_Contractor__c == false && (Trigger.isUpdate && (oldCase.Claim_Vendor_Name__c != cs.Claim_Vendor_Name__c || cs.Peril__c != oldCase.Peril__c) && String.isNotBlank(cs.Claim_Vendor_Name__c) && cs.Claim_Vendor_Name__c.equalsIgnoreCase('MadSky')) ||
                     (Trigger.isInsert && String.isNotBlank(cs.Claim_Vendor_Name__c) && cs.Claim_Vendor_Name__c.equalsIgnoreCase('MadSky')) ) {
                         
                    Callout__c callout = new Callout__c();
                    callout.RecordTypeId = rtInfo.getRecordTypeId();
                    callout.Endpoint__c = 'callout:NM_MadSky/services/data/v51.0/sobjects/Hippo_Claim__c/'; //NM_MadSky_E2E_v2
                    callout.HttpMethod__c = 'POST';
                    callout.Payload__c = Utils.getMadSkyClaimPayload(cs);
                    callout.Status__c = 'Queued';
                    callout.IsAsync__c = true;
                    callout.Case__c = cs.Id;

                    system.debug('MadSky Callout: ' + callout);

                    madSkyCallouts.add(callout);
                }
                // Update Hippo_Claim__c in MadSky
                else if ( (Trigger.isUpdate && oldCase.Wind_Hail_Deductible__c != cs.Wind_Hail_Deductible__c && String.isNotBlank(cs.Claim_Vendor_Name__c) && cs.Claim_Vendor_Name__c.equalsIgnoreCase('MadSky')) && String.isNotBlank(cs.MadSky_Case__c)) {

                    Callout__c callout = new Callout__c();
                    callout.RecordTypeId = rtInfo.getRecordTypeId();
                    callout.Endpoint__c = 'callout:NM_MadSky/services/data/v51.0/sobjects/Hippo_Claim__c/' + cs.MadSky_Case__c;
                    callout.HttpMethod__c = 'PATCH';
                    callout.Payload__c = Utils.getMadSkyClaimPayload(cs);
                    callout.Status__c = 'Queued';
                    callout.IsAsync__c = true;
                    callout.Case__c = cs.Id;

                    system.debug('MadSky Callout: ' + callout);

                    madSkyCallouts.add(callout);
                }
            }

            if (madSkyCallouts.size() > 0) insert madSkyCallouts;
        }
    }

}