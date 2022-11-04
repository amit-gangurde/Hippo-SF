public class ClaimParticipantTriggerHandler {
    public static  PaymentAuth_Integration_System__c payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults(); 
    public static void handleClaimParticipant(List<ClaimParticipant> ClaimParticipantLst,Map<Id,ClaimParticipant> oldMap){
        List<ClaimParticipant> conList = new List<ClaimParticipant>();
        for(ClaimParticipant claim: ClaimParticipantLst){
            if(oldMap!=null && ((String.isNotBlank(claim.Email__c) && claim.Email__c!= oldMap.get(claim.Id).Email__c) || (String.isNotBlank(claim.MobilePhone__c) && claim.MobilePhone__c!= oldMap.get(claim.Id).MobilePhone__c) )){
                conList.add(claim);
            }
        }
        if(!conList.isEmpty())
            makeJSON(conList);
    }
    
    public static void makeJSON(List<ClaimParticipant> conList){
        List<String> calloutLst = new List<String>();
        set<Id> claimAmountIdSet = new Set<Id>();
        Map<Id,Id> claimMap = new Map<Id,Id>();
        Map<Id,ClaimParticipant> claimPartMap = new Map<Id,ClaimParticipant>();
        for(ClaimParticipant claim: conList){
            claimAmountIdSet.add(claim.Id);
            claimPartMap.put(claim.Id,claim);
        }
        for(Claim_Payment__c claimPmt: [SELECT ID,Primary_Contact__c FROM Claim_Payment__c WHERE Primary_Contact__c IN: claimAmountIdSet]){
            claimMap.put(claimPmt.Id,claimPmt.Primary_Contact__c);
        } 
        
        for(Claim_Payment__c con : [SELECT ID,Primary_Contact__c FROM Claim_Payment__c WHERE Primary_Contact__c IN: claimAmountIdSet]){
            updateProfile Request 			= new updateProfile();
            Request.PM_PaymentID 			= con.Id;
            Request.PCON_ContactId 			= claimMap.containsKey(con.Id) && claimPartMap.containsKey(claimMap.get(con.Id))?claimPartMap.get(claimMap.get(con.Id)).Id:null;
            Request.PCON_EmailAddress 		= claimMap.containsKey(con.Id) && claimPartMap.containsKey(claimMap.get(con.Id))?claimPartMap.get(claimMap.get(con.Id)).email__c:null;
            if(claimMap.containsKey(con.Id) && claimPartMap.containsKey(claimMap.get(con.Id)) && claimPartMap.get(claimMap.get(con.Id)).MobilePhone__c != null){
                Request.PCON_MobilePhone 	= claimPartMap.get(claimMap.get(con.Id)).MobilePhone__c;
            }
            calloutLst.add(JSON.serialize(Request,true));
           // calloutHelper(JSON.serialize(Request,true));
        }
        
        Database.executeBatch(new ClaimParticipantBatch(calloutLst), 40);
    }
  //  @future(callout=true)
    public static void calloutHelper(String Request){
        
        String JSONRes = '{"session":"'+PaymentAuth.getSessionID()+'","str_json":"'+ JSON.serialize(Request)+'"}';
        JSONRes = JSONRes.replace('""', '"');
        System.debug(JSONRes);
        
        
        String logWrap = '';
        String urlEncodedBody = Constants.method+'='+Constants.method_UpdateProfile+'&';
        urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
        urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
        urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSONRes, 'UTF-8'); 
        
        System.debug('urlEncodedBody=='+urlEncodedBody);
        
        HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
        
        System.debug('response=='+response.getBody());
    }
    public class updateProfile{        
        Public String PM_PaymentID;                
        Public String PCON_ContactId;
        Public String PCON_EmailAddress;
        Public String PCON_MobilePhone;
    }
}