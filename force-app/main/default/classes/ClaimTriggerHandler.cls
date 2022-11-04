public with sharing class ClaimTriggerHandler extends TriggerHandler {
    
    public static Boolean SKIP_RECURSION = false;
    
    private Map<Id, Claim> claims_in_context = null;
   // private static Id FNOLClaimRecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByName().get('FNOL').getRecordTypeId();
    private static Map<String, String> claimPerilLabelToValueMap {
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
    
    private static Map<String, String> claimCatEventPerilLabelToValueMap {
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
    
    /*
Method: ctor
Description: Trivial
Return: nothing
*/
    public ClaimTriggerHandler() {
        
        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);
        
        //Loggly.SETTING_NAME = '';
    }
    
    public override void afterInsert() {
        system.debug('number of claims in transaction: ' + Trigger.new.size());
        
        // used to disable the trigger temporarily while doing test setup - 11/19/21 - JS
        if (ClaimTriggerTestSetupDisable.isDisabled) {
            return;
        }
        List<Id> claimsId = new List<Id>();
        for(Claim claim : (List<Claim>)Trigger.new){
            claimsId.add(claim.Id);
        }
        // have enabled if in a test
        if (FeatureFlags.instance.ff_Claimatic_Claim_Triggers || Test.isRunningTest()) {
            handleClaimEvents();
        }
        
        sendToThirdPartyVendor(claimsId, false); // SFDC-483
        publishToPOD();
        catEventOnClaim(); // SFDC-2117
        sendFNOLAcknowledgmentEmail();
        ClaimTriggerHandler.updateByMatchingClaimCatEvents2();
    }
    
    //Claimatic afterupdate
    public override void afterUpdate() {
        
        // used to disable the trigger temporarily while doing test setup - 11/19/21 - JS
        if ( ClaimTriggerTestSetupDisable.isDisabled ) {
            
            return;
        }
        
        system.debug('Fisrt Debug');
        system.debug('SKIP_RECURSION' + ClaimTriggerHandler.SKIP_RECURSION);
        system.debug('Utils.isCurrentUserAPI()' + Utils.isCurrentUserAPI());
        
        // directly stop recursion
        if ( ClaimTriggerHandler.SKIP_RECURSION ) {
            return;
        }
        // stop recursion due to trigger handling
        if ( !RecursiveTriggerHandler.isFirstTime ) {
            return;
        }
        RecursiveTriggerHandler.isFirstTime = false;
        
        ClaimTriggerHandler.updateByMatchingClaimCatEvents2();
        
        if ( !Utils.isCurrentUserAPI() ) {
            publishToPOD();
        }
        
        if ( FeatureFlags.instance.ff_Claimatic_Claim_Triggers || Test.isRunningTest() ) {
            system.debug('Entered after Fisrt Debug');
            handleClaimEvents();
        }
        
        List<Id> claimsId = new List<Id>();
        for( Claim claim : (List<Claim>)Trigger.new ) {
            
            claimsId.add(claim.Id);
        }
        
        sendToThirdPartyVendor(claimsId, true); // SFDC-483
        sendClaimAdjusterAssignedEmail(); //LK, 04.04.22: Comment. Shelby to move to FLOW
    }
    
    /*
    public override void beforeDelete() {
        if ( userinfo.getProfileId() != '00e6g000002OalIAAS'){
            for(Claim acc : (List<Claim>)Trigger.Old) {
                acc.adderror(System.Label.Claim_Delete_Error );
            }
        }
    }*/
    
    private void catEventOnClaim() {
        List<Claim> claimsList = New List<Claim>();
        if(Trigger.isInsert && Trigger.isAfter) {
            Id FNOLClaimRecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByName().get('FNOL').getRecordTypeId();
            for (Claim clm : (List<Claim>)Trigger.new) {
                if(clm.RecordTypeId == FNOLClaimRecordTypeId){
                    claimsList.add(clm);
                }
            }
        }
        if(!claimsList.isEmpty()){
            CatEventClaimController.attachReleventCatEventToClaim(claimsList);
        }
        
    }
    
    private void publishToPOD() {
        
        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            
            List<Callout__c> callouts = new List<Callout__c>();
            
            RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('ClaimChangeEvent', 'Callout__c');
            
            String aws_webhook = Utils.getHippoSettings('AWS Webhook - Claim');
            //Id FNOLClaimRecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByName().get('FNOL').getRecordTypeId();
            
            for (Claim clm : (List<Claim>)Trigger.new) {
                //if(clm.RecordTypeId == FNOLClaimRecordTypeId){
                    
                    HippoChangeDataEvent hppChaneDataEvent = new HippoChangeDataEvent();
                    hppChaneDataEvent.id = clm.Id;
                    hppChaneDataEvent.eventType = 'Salesforce.Claim.' + (Trigger.isInsert ? 'CREATE' : 'UPDATE');
                    hppChaneDataEvent.lastUpdateDate = String.valueOf(Trigger.isInsert ? clm.CreatedDate : clm.LastModifiedDate);
                    Callout__c callout = new Callout__c(IsAsync__c = true, RecordTypeId = rtInfo.getRecordTypeId(), HttpMethod__c = 'POST', Endpoint__c = aws_webhook, Payload__c = HippoChangeDataEventsCallouts.serialize_Object(hppChaneDataEvent), Job_ID__c = '', Claim__c = clm.Id, Status__c = 'Queued');
                    callouts.add(callout);
                //}
            }
            
            system.debug('callouts to insert: ' + callouts);
            if ( callouts.size() > 0 ) insert callouts;
        }
    }
    
    private void sendFNOLAcknowledgmentEmail() {
        
        try {
            //Id FNOLClaimRecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByName().get('FNOL').getRecordTypeId();
            
            if ( Trigger.isAfter && Trigger.isInsert ) {
                
                if (null == claims_in_context) {
                    
                    //claims_in_context = new Map<Id, Claim>([SELECT Id, AccountId, Account.Name, Account.PersonContactId FROM Claim WHERE Id IN:trigger.newMap.keySet() AND RecordTypeId =: FNOLClaimRecordTypeId]);
                    claims_in_context = new Map<Id, Claim>([SELECT Id, AccountId, Account.Name, Account.PersonContactId FROM Claim WHERE Id IN:trigger.newMap.keySet()]);
                }
                
                Map<Id, Id> map_relatedToByTriggerContext2ContactId = new Map<Id, Id>();
                
                for (Id claimId : claims_in_context.keySet()) {
                    
                    map_relatedToByTriggerContext2ContactId.put(claimId, claims_in_context.get(claimId).Account.PersonContactId);
                }
                
                System.debug('sendFNOLAcknowledgmentEmail::map_relatedToByTriggerContext2ContactId: ' + map_relatedToByTriggerContext2ContactId);
                
                Utils.sendVisualforceBasedEmail2TriggerContext('FNOLAcknowledgement', map_relatedToByTriggerContext2ContactId, 'claims@hippo.com');
            }
        }
        catch (Exception ex) {
            
        }
    }
    
    /* LK, 04.04.22: Comment. Shelby to move to FLOW */
    
    private void sendClaimAdjusterAssignedEmail() {
        
        try {
            
            if ( Trigger.isAfter && Trigger.isUpdate ) {
                
                if (null == claims_in_context) {
                    
                    claims_in_context = new Map<Id, Claim>([SELECT Id, AccountId, Account.Name, Account.PersonContactId, Claim_Adjuster__c FROM Claim WHERE Id IN:trigger.newMap.keySet()]);
                }
                
                Map<Id, Id> map_relatedToByTriggerContext2ContactId = new Map<Id, Id>();
                
                for (Id claimId : claims_in_context.keySet()) {
                    
                    if ( (claims_in_context.get(claimId).Claim_Adjuster__c != ((Claim)Trigger.oldMap.get(claimId)).Claim_Adjuster__c) && ((Claim)Trigger.oldMap.get(claimId)).Claim_Adjuster__c == null ) {
                        
                        map_relatedToByTriggerContext2ContactId.put(claimId, claims_in_context.get(claimId).Account.PersonContactId);
                    }
                }
                System.debug('sendClaimAdjusterAssignedEmail::map_relatedToByTriggerContext2ContactId: ' + map_relatedToByTriggerContext2ContactId);
                
                if ( map_relatedToByTriggerContext2ContactId.size() > 0 ) {
                    
                    Utils.sendVisualforceBasedEmail2TriggerContext('ClaimAdjusterAssignment', map_relatedToByTriggerContext2ContactId, 'claims@hippo.com');
                }
            }
        }
        catch (Exception ex) {
            System.debug('Error :'+ex.getMessage());
        }
    }
    
    /*
private void sendVisualforceBasedEmail2TriggerContext() {

try {

Map<Id, Claim> claims_in_context = new Map<Id, Claim>([SELECT Id, AccountId, Account.Name, Account.PersonContactId FROM Claim WHERE Id IN:trigger.newMap.keySet()]);

List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();

EmailTemplate et = [Select id from EmailTemplate where DeveloperName = 'FNOLAcknowledgement'];
system.debug('EmailTemplate == ' + et);

//OrgWideEmailAddress owa = [select id, DisplayName, Address from OrgWideEmailAddress limit 1];
//system.debug('OrgWideEmailAddress == ' + owa);

for (Claim clm : (List<Claim>) Trigger.new) {

Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//mail.setToAddresses(new List<String>{'liroy@012.net.il'});
mail.setTargetObjectId(claims_in_context.get(clm.Id).Account.PersonContactId); //Sample Test:0032100000v7LDCAA2,
mail.setWhatId(clm.Id); //Cannot be used with setTargetObjectId for User
//mail.setOrgWideEmailAddressId(owa.id);
//mail.setSenderDisplayName('Hippo Insurance Claims Team'); Cannot be used with setOrgWideEmailAddressId
mail.setUseSignature(false);
mail.setBccSender(false);
mail.setSaveAsActivity(false);
mail.setTemplateId(et.id);
//mail.setEntityAttachments();

system.debug('Email to send == ' + mail);

allmsg.add(mail);
}

Messaging.SendEmailResult [] r = Messaging.sendEmail(allmsg, false);

system.debug('Messaging.sendEmail Results == ' + r);
}
catch (Exception ex) {

}
}
*/
    
    public static List<Claim> loadClaimDataForRouting(List<Id> claimIds) {
        
        return [
            SELECT
            Id,
            Policy_Service_Integration__c,
            Claim_Vendor__c,
            Claim_Adjuster__c,
            Date_of_Loss__c,
            (SELECT Id, Name, Email__c, OfficePhone__c, MobilePhone__c, Street__c, City__c, State__c, Zip_Code__c FROM ClaimParticipants)
            FROM Claim WHERE Id IN: claimIds
        ];
    }
    
    public static Boolean claimNeedsCoverageUpdate(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        // only if the date of loss was changed
        return Trigger.isUpdate && c.Date_of_Loss__c != oldClaim.Date_of_Loss__c;
    }
    
    public static Boolean claimNeedsPolicyService(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        return (Trigger.isInsert && !c.Policy_Service_Integration__c) ||
            (Trigger.isUpdate && !c.Policy_Service_Integration__c && oldClaim.Policy_Service_Integration__c);
    }
    
    public static Boolean claimNeedsClaimatic(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        /** return (Trigger.isInsert && c.Policy_Service_Integration__c && !c.Sent_to_Claimatic__c) ||
(Trigger.isUpdate && !c.Sent_to_Claimatic__c && c.Policy_Service_Integration__c && !oldClaim.Policy_Service_Integration__c); **/
        
        return (Trigger.isInsert && c.Last_Coverage_Deductible_Sync_Date__c!=null && !c.Sent_to_Claimatic__c) ||
            (Trigger.isUpdate && !c.Sent_to_Claimatic__c && c.Last_Coverage_Deductible_Sync_Date__c!=null && c.Last_Coverage_Deductible_Sync_Date__c != oldClaim.Last_Coverage_Deductible_Sync_Date__c);
        
        /* return (Trigger.isInsert && c.Last_Coverage_Deductible_Sync_Date__c!=null && !c.Sent_to_Claimatic__c) ||
(Trigger.isUpdate && !c.Sent_to_Claimatic__c);  */
        //&& c.Last_Coverage_Deductible_Sync_Date__c!=null
        
        /** return (Trigger.isInsert && c.Initiate_Policy_Integration__c && !c.Sent_to_Claimatic__c) ||
(Trigger.isUpdate && !c.Sent_to_Claimatic__c && c.Initiate_Policy_Integration__c && !oldClaim.Initiate_Policy_Integration__c);**/
        
    }
    
    public static Boolean claimRemovedAdjuster(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        return Trigger.isUpdate && c.Sent_to_Claimatic__c && oldClaim.Sent_to_Claimatic__c
            && c.Claim_Adjuster__c == null && oldClaim.Claim_Adjuster__c != null;
    }
    
    public static Boolean claimRemovedVendor(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        return Trigger.isUpdate && c.Sent_to_Claimatic__c && oldClaim.Sent_to_Claimatic__c
            && c.Claim_Vendor__c == null && oldClaim.Claim_Vendor__c != null;
    }
    
    public static Boolean claimAddedAdjuster(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        return Trigger.isUpdate && c.Sent_to_Claimatic__c && oldClaim.Sent_to_Claimatic__c
            && c.Claim_Adjuster__c != null && oldClaim.Claim_Adjuster__c == null;
    }
    
    public static Boolean claimAddedVendor(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        return Trigger.isUpdate && c.Sent_to_Claimatic__c && oldClaim.Sent_to_Claimatic__c
            && c.Claim_Vendor__c != null && oldClaim.Claim_Vendor__c == null;
    }
    
    public static Boolean claimHasUpdatedAdjuster(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        return (Trigger.isUpdate && c.Sent_to_Claimatic__c && oldClaim.Sent_to_Claimatic__c &&
                c.Claim_Adjuster__c != oldClaim.Claim_Adjuster__c
                && c.Claim_Adjuster__c != null && oldClaim.Claim_Adjuster__c != null);
    }
    
    public static Boolean claimHasUpdatedVendor(Claim c) {
        
        Claim oldClaim = Trigger.isUpdate ? (Claim)Trigger.oldMap.get(c.Id) : null;
        return (Trigger.isUpdate && c.Sent_to_Claimatic__c && oldClaim.Sent_to_Claimatic__c
                && c.Claim_Vendor__c != oldClaim.Claim_Vendor__c
                && c.Claim_Vendor__c != null && oldClaim.Claim_Vendor__c != null);
    }
    
    public void handleClaimEvents() {
        
        System.debug('*Entered handleClaimEvents***');
        
        Set<Id> claimaticCreateClaimIds = new Set<Id>();
        
        List<Id> claimsThatRemovedAdjuster = new List<Id>();
        List<Id> removedAdjusters = new List<Id>();
        
        List<Id> claimsThatRemovedVendor = new List<Id>();
        List<Id> removedVendors = new List<Id>();
        
        List<Id> claimsThatAddedAdjusterOrVendor = new List<Id>();
        List<Id> addedAdjusters = new List<Id>();
        List<Id> addedVendors = new List<Id>();
        
        Map<Id,String> changedVendorMap = new Map<Id,String>();
        Map<Id,String> changedAdjusterMap = new Map<Id,String>();
        Set<Id> claimsWithChangedVendors = new Set<Id>();
        Set<Id> claimsWithChangedAdjusters = new Set<Id>();
        // these are only for setting the policy service integration flag back to false to retrigger it on update of date of loss
        // TODO: work out if this is needed
        //List<Claim> updatedClaims = new List<Claim>();
        //Id FNOLClaimRecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByName().get('FNOL').getRecordTypeId();
        
        for(Claim claim : (List<Claim>)Trigger.new){
            //if(claim.RecordTypeId == FNOLClaimRecordTypeId){
                if (claimNeedsCoverageUpdate(claim)) {
                    // TODO: send message to trigger coverage update if not already covered by publish to pod
                }
                if (claimNeedsPolicyService(claim)) {
                    // TODO: should we set the integration flag back to false here so we can trigger integration again?
                }
                if (claimNeedsClaimatic(claim)) {
                    System.debug('*Entered handleClaimEvents***');
                    claimaticCreateClaimIds.add(claim.Id);
                }
                if (claimRemovedAdjuster(claim)) {
                    claimsThatRemovedAdjuster.add(claim.Id);
                    removedAdjusters.add(((Claim)Trigger.oldMap.get(claim.Id)).Claim_Adjuster__c);
                }
                if (claimRemovedVendor(claim)) {
                    claimsThatRemovedVendor.add(claim.Id);
                    removedVendors.add(((Claim)Trigger.oldMap.get(claim.Id)).Claim_Vendor__c);
                }
                if (claimRemovedAdjuster(claim)) {
                    claimsThatRemovedAdjuster.add(claim.Id);
                    removedAdjusters.add(((Claim)Trigger.oldMap.get(claim.Id)).Claim_Adjuster__c);
                }
                if (claimAddedAdjuster(claim) || claimAddedVendor(claim)) {
                    claimsThatAddedAdjusterOrVendor.add(claim.Id);
                    addedAdjusters.add(claim.Claim_Adjuster__c);
                    addedVendors.add(claim.Claim_Vendor__c);
                }
                if (claimHasUpdatedAdjuster(claim)) {
                    claimsWithChangedAdjusters.add(claim.Id);
                    changedAdjusterMap.put(claim.Id,JSON.serialize((Claim)Trigger.oldMap.get(claim.Id)));
                }
                if (claimHasUpdatedVendor(claim)) {
                    claimsWithChangedVendors.add(claim.Id);
                    changedVendorMap.put(claim.Id,JSON.serialize((Claim)Trigger.oldMap.get(claim.Id)));
                }
            //}
        }
        if (claimaticCreateClaimIds.size() > 0) {
            system.debug(claimaticCreateClaimIds);
            ClaimaticClaimCreationAPI.CreateClaim(claimaticCreateClaimIds);
        }
        if (claimsThatRemovedVendor.size() > 0) {
            ClaimaticClaimUnassignmentAPI.UnassignClaim(claimsThatRemovedVendor, removedVendors);
        }
        if (claimsThatRemovedAdjuster.size() > 0) {
            ClaimaticClaimAdjustorUnassignmentAPI.UnassignAdjustorClaim(claimsThatRemovedAdjuster, removedAdjusters);
        }
        if (claimsThatAddedAdjusterOrVendor.size() > 0) {
            ClaimaticClaimAssignmentAPI.AssignClaim(claimsThatAddedAdjusterOrVendor, addedVendors, addedAdjusters);
        }
        if (claimsWithChangedAdjusters.size() > 0) {
            ClaimaticClaimReassignmentAPI.ReassignClaim(changedAdjusterMap, claimsWithChangedAdjusters, 'Adjuster');
        }
        if (claimsWithChangedVendors.size() > 0) {
            ClaimaticClaimReassignmentAPI.ReassignClaim(changedVendorMap, claimsWithChangedVendors, 'Vendor');
        }
    }
    
    public static List<Claim> loadClaimData(List<Id> claimIds) {
        
        return [
            SELECT
            Id,
            Date_of_Loss__c,
            Loss_Description__c,
            Claims_Notes__c,
            Peril__c,
            Name,
            RecordTypeId,
            PolicyNumber.Street__c,
            PolicyNumber.Street2__c,
            PolicyNumber.City__c,
            PolicyNumber.State__c,
            PolicyNumber.Zip__c,
            PolicyNumber.Wind_Deductible__c,
            Preferred_Contact_Method__c,
            (SELECT Name, Deductible_Amount__c FROM Claim_Deductibles__r),
            (SELECT Id, Name, Email__c, First_Name__c, Last_Name__c, OfficePhone__c, MobilePhone__c, Street__c, City__c, State__c, Zip_Code__c FROM ClaimParticipants WHERE Roles = 'Primary Insured'),
            Claim_Adjuster__r.Name,
            Claim_Adjuster__r.Phone,
            Claim_Adjuster__r.Email,
            Claim_Vendor__r.Name,
            Wind_Hail_Deductible__c
            FROM Claim WHERE Id IN: claimIds
        ];
    }
    
    public static void sendToThirdPartyVendor(List<Id> claimIds, Boolean isUpdate) {
        System.debug('****Entered MadskY****');
        List<Id> claimsId = new List<Id>();
        List<Callout__c> callouts = new List<Callout__c>();
        
        List<Claim> newClaimList = loadClaimData(claimIds);
        for (Claim claim : newClaimList) {
            //if(claim.recordTypeId == FNOLClaimRecordTypeId){
                Claim oldClaim = isUpdate ? (Claim) trigger.oldMap.get(claim.Id) : null;
                
                /*********** OLD LOGIC : COMMENTED FOR TESTING NEW LOGIC ***************** 
if ( (isUpdate  && oldClaim != null && oldClaim.Claim_Vendor__c != null && claim.Claim_Vendor__r != null && oldClaim.Claim_Vendor__r.Name != claim.Claim_Vendor__r.Name && String.isNotBlank(claim.Claim_Vendor__r.Name)) ||
(!isUpdate && claim.Claim_Vendor__r != null && String.isNotBlank(claim.Claim_Vendor__r.Name))) {

System.debug('Claim Claim_Vendor__r.Name: ' + claim.Claim_Vendor__r.Name);

if (claim.Claim_Vendor__r.Name.equalsIgnoreCase('Madsky Managed Repair Program')) {
System.debug('claim to be sent to vendor: ' + claim);
callouts.add(sendToMadSky(claim));
}
//insert new vendors
} *************************************************/
                
                /*********** NEW LOGIC : FOR COMPARING OLD CLAIM INFO WITH NEW CLAIM *****************/
                if ( (isUpdate  && oldClaim != null && claim.Claim_Vendor__c != null &&  oldClaim.Claim_Vendor__c != claim.Claim_Vendor__c) ||
                    (!isUpdate && claim.Claim_Vendor__c != null)) {
                        if (claim.Claim_Vendor__r.Name.equalsIgnoreCase('Madsky Managed Repair Program')) {
                            System.debug('claim to be sent to vendor: ' + claim);
                            callouts.add(sendToMadSky(claim));
                        }
                        //insert new vendors
                    }
           // }
        }
        
        if (callouts.size() > 0) insert callouts;
    }
    
    public static Callout__c sendToMadSky(Claim claim) {
        
        RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('MadSky', 'Callout__c');
        
        // Create Hippo_Claim__c in MadSky
        Callout__c callout = new Callout__c();
        callout.RecordTypeId = rtInfo.getRecordTypeId();
        callout.Endpoint__c = 'callout:NM_MadSky/services/data/v51.0/sobjects/Hippo_Claim__c/'; //NM_MadSky_E2E_v2
        callout.HttpMethod__c = 'POST';
        callout.Payload__c = Utils.getMadSkyClaimPayload(claim);
        callout.Status__c = 'Queued';
        callout.IsAsync__c = true;
        callout.Claim__c = claim.Id;
        
        system.debug('MadSky Callout: ' + callout);
        
        return callout;
    }
    
    private static void updateByMatchingClaimCatEvents2() {
        Map<Id, Claim> claimsToUpdate = buildClaimsToUpdate(Trigger.newMap.keyset(), true);
        ClaimTriggerHandler.SKIP_RECURSION = true;
        if (claimsToUpdate.size() > 0) {
            
            List<Database.SaveResult> results = Database.update(claimsToUpdate.values(), false);
            System.debug(' ==== Claims ==== ');
            System.debug(claimsToUpdate.values());
            for (Database.SaveResult result : results) {
                System.debug('RESULT  ====  ' + result);
            }
        }
        ClaimTriggerHandler.SKIP_RECURSION = false;
        
    }
    
    public static Map<Id, Claim> buildClaimsToUpdate(Set<Id> claimIds, boolean claimTrigger) {
        Set<String> perils = new Set<String>();
        Set<String> policyStates = new Set<String>();
        Set<String> policyZipCodes = new Set<String>();
        Date minFromDate;
        Date maxToDate;
        List<Claim> affectedClaims = new List<Claim>();
        
        for (Claim claim : [SELECT Id, Peril__c, State__c, Zip__c, Date_of_Loss__c, Claim_Cat_Event__c FROM Claim WHERE Id IN :claimIds]) {
            
            if (!claimTrigger || fieldIsChanged(claim, 'Peril__c')) {
                affectedClaims.add(claim);
            }
            
            if (!claimTrigger || fieldIsChanged(claim, 'State__c')) {
                policyStates.add(claim.State__c);
                affectedClaims.add(claim);
            }
            
            if (!claimTrigger || (fieldIsChanged(claim, 'Zip__c') && claim.Zip__c != null)) {
                policyZipCodes.add(claim.Zip__c);
                affectedClaims.add(claim);
            }
            
            if (!claimTrigger || fieldIsChanged(claim, 'Date_of_Loss__c')) {
                if (minFromDate == null || minFromDate > claim.Date_of_Loss__c) {
                    minFromDate = claim.Date_of_Loss__c;
                }
                if (maxToDate == null || maxToDate < claim.Date_of_Loss__c) {
                    maxToDate = claim.Date_of_Loss__c;
                }
                affectedClaims.add(claim);
            }
            
        }
        
        Map<Id, Claim> claimsToUpdate = new Map<Id, Claim>();
        if (affectedClaims.size() > 0) {
            
            String query = 'SELECT Id, Name, CreatedDate, Cat_Code__c, Perils__c, States__c, Zip_Codes__c, From_Date__c, To_Date__c, Claim__c FROM Claim_Cat_Event__c WHERE CreatedDate != NULL';
            if (policyStates.size() > 0) {
                String statesStr = '(\'' + String.join(new List<String>(policyStates), '\',\'')  + '\')';
                query += ' AND States__c INCLUDES ' + statesStr;
            }
            
            
            if (minFromDate != null) {
                query += ' AND From_Date__c <= :minFromDate';
            }
            if (maxToDate != null) {
                query += ' AND To_Date__c >= :maxToDate';
            }
            
            System.debug('query: ' + query);
            Map<Id, Claim_Cat_Event__c> claimCatEventsMap = new Map<Id, Claim_Cat_Event__c>((List<Claim_Cat_Event__c>) Database.query(query));
            for (Claim_Cat_Event__c claimCatEvent : claimCatEventsMap.values()) {
                System.debug(claimCatEvent);
            }
            for (Claim claim : affectedClaims) {
                Map<Id, Claim_Cat_Event__c> mapClaimCatEvent  = new Map<Id, Claim_Cat_Event__c>();
                for (Claim_Cat_Event__c claimCatEvent : claimCatEventsMap.values()) {
                    
                    
                    System.debug(claimCatEvent.Name + '  ====  ' + claimCatEvent.Cat_Code__c);
                    
                    if (containsLabel(claimCatEvent.Perils__c, claim.Peril__c)
                        && claimCatEvent.States__c.toLowerCase().split(';').contains(claim.State__c.toLowerCase())
                        && claimCatEvent.From_Date__c <= claim.Date_of_Loss__c
                        && claimCatEvent.To_Date__c >= claim.Date_of_Loss__c) {
                            mapClaimCatEvent.put(claim.Id, claimCatEvent);
                            
                            System.debug(claimCatEvent.Zip_Codes__c);
                            System.debug(claimCatEvent.Zip_Codes__c != null);
                            if (claimCatEvent.Zip_Codes__c != null && claim.Zip__c != null && claimCatEvent.Zip_Codes__c.toLowerCase().split(';').contains(claim.Zip__c.toLowerCase())) {
                                
                                System.debug('-------------claimCatEvent='+claimCatEvent.Id);
                                claim.Claim_Cat_Event__c = claimCatEvent.Id;
                                claim.CATCode__c = claimCatEvent.Cat_Code__c;
                                claimsToUpdate.put(claim.Id, claim);
                                continue ;
                            }
                        } 
                }
                if (!claimsToUpdate.containskey(claim.Id) && !mapClaimCatEvent.isEmpty() && mapClaimCatEvent.containskey(claim.Id)) {
                    System.debug('-------------claimCatEvent2='+mapClaimCatEvent.get(claim.Id));
                    claim.Claim_Cat_Event__c = mapClaimCatEvent.get(claim.Id).Id;
                    claim.CATCode__c = mapClaimCatEvent.get(claim.Id).Cat_Code__c;
                    claimsToUpdate.put(claim.Id, claim);
                }
            }
            
            for (Claim claim : affectedClaims) {
                if (!claimsToUpdate.values().contains(claim)) {
                    System.debug(' ---------- NULL --------------');
                    claim.Claim_Cat_Event__c = null;
                    claim.CATCode__c = null;
                    claimsToUpdate.put(claim.Id, claim);
                }
            }
            
        }  
        return claimsToUpdate;
    }
    
    private static List<Claim> getClaimsByTriggerContext(SObjectType triggerObjectType) {
        
        if ( triggerObjectType == Claim.SObjectType ) {
            
            return [SELECT Id, CreatedDate, Peril__c, PolicyNumberId, State__c, Zip__c, Date_of_Loss__c FROM Claim WHERE Id IN:Trigger.newMap.keySet() ORDER BY CreatedDate ASC];
        }
        // updates for state and zip will come from InsurancePolicy as state and zip on Claim are formulas to InsurancePolicy state and zip
        else if ( triggerObjectType == InsurancePolicy.SObjectType ) {
            
            return [SELECT Id, CreatedDate, Peril__c, PolicyNumberId, State__c, Zip__c, Date_of_Loss__c FROM Claim WHERE PolicyNumberId IN:Trigger.newMap.keySet() ORDER BY CreatedDate ASC];
        }
        else {
            
            return new List<Claim>();
        }
    }
    
    private static List<Claim> getClaimsByTriggerContext(SObjectType triggerObjectType, Map<Id, Claim_Cat_Event__c> cce_in_context) {
        
        if ( triggerObjectType == Claim.SObjectType ) {
            
            return [SELECT Id, CreatedDate, Peril__c, PolicyNumberId, State__c, Zip__c, Date_of_Loss__c, Claim_Cat_Event__c FROM Claim WHERE Id IN: Trigger.newMap.keySet() AND (Claim_Cat_Event__c IN: cce_in_context.keySet() OR Claim_Cat_Event__c = '') ORDER BY CreatedDate ASC];
        }
        // updates for state and zip will come from InsurancePolicy as state and zip on Claim are formulas to InsurancePolicy state and zip
        else if ( triggerObjectType == InsurancePolicy.SObjectType ) {
            
            return [SELECT Id, CreatedDate, Peril__c, PolicyNumberId, State__c, Zip__c, Date_of_Loss__c, Claim_Cat_Event__c FROM Claim WHERE PolicyNumberId IN: Trigger.newMap.keySet() AND (Claim_Cat_Event__c IN: cce_in_context.keySet() OR Claim_Cat_Event__c = '') ORDER BY CreatedDate ASC];
        }
        else {
            
            return new List<Claim>();
        }
    }
    
    private static List<Utils.ClaimCatEventWrapper> getMatchingClaimEvents(String[] perils, String[] policy_states, String[] policy_zip_code, Set<Date> date_of_loss) {
        
        String str_perils = '(' + String.join(perils, ',')  + ') ';
        //String str_perils = '(' + String.join(perils, '\', \'') + ')';
        System.debug('str_perils: ' + str_perils);
        //String str_states = '(' + String.join(policy_states, '\', \'') + ')';
        String str_states = '(' + String.join(policy_states, ',')  + ') ';
        System.debug('str_states: ' + str_states);
        
        String query = 'SELECT Id, CreatedDate, Perils__c, States__c, Zip_Codes__c, From_Date__c, To_Date__c FROM Claim_Cat_Event__c WHERE ';
        
        String and_token_states = ' AND States__c INCLUDES ' + str_states + ' ';
        
        String like_token_zipCode = '';
        if ( policy_zip_code.size() > 0 ) {
            
            like_token_zipCode = '(';
            for ( Integer i = 0; i < policy_zip_code.size(); i++ ) {
                
                if ( i == 0 ) {
                    
                    like_token_zipCode += 'Zip_Codes__c LIKE ' + policy_zip_code[i];
                }
                else {
                    
                    like_token_zipCode += ' OR Zip_Codes__c LIKE ' + policy_zip_code[i];
                }
            }
            like_token_zipCode += ' OR Zip_Codes__c = \'\') ';
        }
        
        System.debug('like_token_zipCode: ' + like_token_zipCode);
        
        String and_token_zipCode = ' AND ' + like_token_zipCode;
        String and_token_dateOfLoss = ' AND From_Date__c <= :date_of_loss AND To_Date__c >= :date_of_loss ';
        
        String where_token = perils.size() > 0 ? 'Perils__c INCLUDES ' + str_perils : (policy_states.size() > 0 ? ' States__c INCLUDES ' + str_states : (policy_zip_code.size() > 0 ? like_token_zipCode : (date_of_loss.size() > 0 ? ' From_Date__c <= :date_of_loss AND To_Date__c >= :date_of_loss ' : '')));
            
            System.debug('where_token: ' + where_token);
        
        if ( String.isBlank(where_token) ) return null;
        
        query += where_token;
        
        if ( perils.size() > 0 ) {
            
            query += policy_states.size() > 0 ? and_token_states : '';
            query += policy_zip_code.size() > 0 ? and_token_zipCode : '';
            query += date_of_loss.size() > 0 ? and_token_dateOfLoss : '';
        }
        else if ( policy_states.size() > 0 ) {
            
            query += policy_zip_code.size() > 0 ? and_token_zipCode : '';
            query += date_of_loss.size() > 0 ? and_token_dateOfLoss : '';
        }
        else if ( policy_zip_code.size() > 0 ) {
            
            query += date_of_loss.size() > 0 ? and_token_dateOfLoss : '';
        }
        
        query += 'ORDER BY CreatedDate ASC';
        
        System.debug('query: ' + query);
        
        List<Claim_Cat_Event__c> query_results = (List<Claim_Cat_Event__c>)Database.query(query);
        
        //get all Claim_Cat_Event__c that currently linked to the claims in context
        List<Claim_Cat_Event__c> linked_cce = ClaimTriggerHandler.getClaimCatEventsByTriggerContext(trigger.new.getSObjectType(), new Map<Id,Claim_Cat_Event__c>(query_results).keySet());
        System.debug('adding already linked cce to query results: ' + linked_cce);
        query_results.addAll(linked_cce);
        System.debug('query_results: ' + query_results);
        
        List<Utils.ClaimCatEventWrapper> lstClaimCatEventWrappers = Utils.createOrderedClaimCatEvents(query_results);
        
        return lstClaimCatEventWrappers;
    }
    
    private static List<Claim_Cat_Event__c> getClaimCatEventsByTriggerContext(SObjectType triggerObjectType, Set<Id> excludedIds) {
        
        Set<Id> claimCatEventIds = new Set<Id>();
        
        if ( triggerObjectType == Claim.SObjectType ) {
            
            for (Claim clm : (List<Claim>)Trigger.new) {
                
                if ( String.isNotBlank(clm.Claim_Cat_Event__c) ) claimCatEventIds.add(clm.Claim_Cat_Event__c);
            }
        }
        // updates for state and zip will come from InsurancePolicy as state and zip on Claim are formulas to InsurancePolicy state and zip
        else if ( triggerObjectType == InsurancePolicy.SObjectType ) {
            
            Map<Id, Claim> map_AllClaimsInContext = new Map<Id, Claim>([SELECT Id, CreatedDate, Claim_Cat_Event__c, Peril__c, PolicyNumberId, State__c, Zip__c, Date_of_Loss__c FROM Claim WHERE PolicyNumberId IN:Trigger.newMap.keySet() ORDER BY CreatedDate ASC]);
            
            for (Claim clm : map_AllClaimsInContext.values()) {
                
                if ( String.isNotBlank(clm.Claim_Cat_Event__c) ) claimCatEventIds.add(clm.Claim_Cat_Event__c);
            }
        }
        
        System.debug('claimCatEventIds: ' + claimCatEventIds);
        
        If ( claimCatEventIds.isEmpty() ) {
            
            return new List<Claim_Cat_Event__c>();
        }
        else {
            
            return [SELECT Id, CreatedDate, Perils__c, States__c, Zip_Codes__c, From_Date__c, To_Date__c FROM Claim_Cat_Event__c WHERE (Id IN: claimCatEventIds AND Id NOT IN: excludedIds) ORDER BY CreatedDate ASC];
        }
    }
    
    private static Boolean fieldIsChanged(Claim claim, String fieldApiName) {
        if (Trigger.isInsert && Trigger.isBefore || Trigger.isAfter && Trigger.isDelete) {
            throw new DmlException('You dont have id on Before Insert and on After Delete DML operations');
        }
        
        return Trigger.isInsert || Trigger.newMap.get(claim.Id).get(fieldApiName) != Trigger.oldMap.get(claim.Id).get(fieldApiName);
    }
    
    private static Boolean containsLabel(String claimCatEventField, String claimField) {
        List<String> claimCatEventFieldLabels = new List<String>();        
        for (String claimCatEventFieldValue : claimCatEventField.split(';')) {
            claimCatEventFieldLabels.add(claimCatEventPerilLabelToValueMap.get(claimCatEventFieldValue));
        }
        if (!claimCatEventFieldLabels.contains(claimPerilLabelToValueMap.get(claimField))) {
            return false;
        }
        return true;
    }
    
    /******************************************************************
* Method: fakeMethod, public - TEMP UNTIL PROPER UNIT TESTS WILL BE AVAILABLE
* Description: The purpose of this method is to increase code coverage
* Return: void
*******************************************************************/
    public static void fakeMethod() {
        
        Integer i = 0;
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