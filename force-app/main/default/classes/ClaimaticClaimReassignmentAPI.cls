/*******************************************************************************************
* @Name         ClaimaticClaimReassignmentAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class contains REST service for Reassigning vendors in claim
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/

public class ClaimaticClaimReassignmentAPI {

    public static List<Claim> loadClaimData(Set<Id> claimIds) {
        return [SELECT Id,Claim_Vendor__r.Claimatic_Integration_ID__c,
                Claim_Adjuster__r.Claimatic_Integration_ID__c
                FROM Claim WHERE Id IN: claimIds];
    }

    public static List<Claim> loadOldClaimData(Map<Id, String> oldClaimMap, List<Claim> newClaimList) {
        List<Claim> oldClaims = new List<Claim>();
        for(Claim newClaim : newClaimList) {
            oldClaims.add((Claim) System.JSON.deserialize(oldClaimMap.get(newClaimList[0].Id), Claim.class));
        }
        return oldClaims;
    }

    @Future(Callout=true)
    public static void ReassignClaim(Map<Id,String> oldClaimMap,Set<Id> claimIds,String type){
        Claim csRec = new Claim();
        List<Log__c> logs = new List<Log__c>();
        Integer statusCode;
        String responseBody;
        try{
            List<Claim> newClaimList = loadClaimData(claimIds);
            List<Claim> oldClaimList = loadOldClaimData(oldClaimMap, newClaimList);
            for(Integer i = 0; i < newClaimList.size(); i++) {
                Claim newClaim = newClaimList[i];
                Claim oldClaim = oldClaimList[i];
                Integration__c integ = Integration__c.getOrgDefaults();
                Http h = new Http();
                String token = ClaimaticAuthenticationAPI.AuthenticationService();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(integ.Reassign_Claim_URL__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/xml');
                req.setHeader('Authorization', 'Bearer ' + token);
                String body = generateJSON(oldClaim, newClaim, type);
                req.setBody(body);
                System.debug('ReassignClaim body:' + body);
                HttpResponse res = new HttpResponse();
                if (!Test.isRunningTest()) {
                    res = h.send(req);
                    statusCode = res.getStatusCode();
                    System.debug('ReassignClaim statusCode:' + statusCode);
                    responseBody = res.getBody();
                    System.debug('ReassignClaim responseBody:' + responseBody);
                } else {
                    statusCode = 200;
                    StaticResource SR = new StaticResource();
                    SR = [SELECT Body FROM StaticResource WHERE Name = 'ClaimaticAuth'];
                    responseBody = SR.Body.toString();
                }
                if (statusCode == 200) {
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Reassignment API', integ.Reassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Success'));
                } else {
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Reassignment API', integ.Reassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Error'));
                }
                csRec = newClaim;
            }
        }catch(Exception e){
             //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
             logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimReassignmentAPI','ReassignClaim','Case',csRec.Id,'N/A','Error'));
             insert logs;
        }
    }

    public static Claim_Vendor__c loadOldVendor(Id id) {
        return [SELECT Claimatic_Integration_ID__c FROM Claim_Vendor__c WHERE Id = :id];
    }

    public static User loadOldAdjuster(Id id) {
        return [SELECT Email,Username,Claimatic_Integration_ID__c FROM User WHERE Id= :id];
    }

    public static String generateJSON(Claim oldClaim,Claim newClaim,String type){
        Claim_Vendor__c vendor = new Claim_Vendor__c();
        if (type == 'Vendor') {
            vendor = loadOldVendor(oldClaim.Claim_Vendor__c);
        }
        User u = new User();
        if (type == 'Adjuster') {
            u = loadOldAdjuster(oldClaim.Claim_Adjuster__c);
        }

        ClaimaticClaimReassignmentRequest request = new ClaimaticClaimReassignmentRequest();
        request.claim_number = newClaim.Id;
        ClaimaticClaimReassignmentRequest.cls_assignments assignment = new ClaimaticClaimReassignmentRequest.cls_assignments();
        if(type == 'Vendor'){
            //assignment.resource_email = newCaseList[0].Claim_Vendor__r.PersonEmail;
            assignment.resource_email = '';
            //assignment.username = newCaseList[0].Claim_Vendor__r.Resource_Username__c;
            assignment.username = '';
            assignment.resource_num = newClaim.Claim_Vendor__r.Claimatic_Integration_ID__c;
            assignment.resource_id = newClaim.Claim_Vendor__r.Claimatic_Integration_ID__c;
            assignment.assignment_party_id = 1;
            assignment.is_primary = 1;
            //assignment.to_remove_resource_email=acc.PersonEmail;
            //assignment.to_remove_resource_username=acc.Resource_Username__c;
            assignment.to_remove_resource_email='';
            assignment.to_remove_resource_username='';
            assignment.to_remove_resource_num = vendor.Claimatic_Integration_ID__c;
            assignment.to_remove_resource_id = vendor.Claimatic_Integration_ID__c;
            request.assignments.add(assignment);
        }else{
            //assignment.resource_email = newCaseList[0].Claim_Vendor__r.PersonEmail;
            assignment.resource_email = '';
            //assignment.username = newCaseList[0].Claim_Vendor__r.Resource_Username__c;
            assignment.username = '';
            assignment.resource_num = newClaim.Claim_Adjuster__r.Claimatic_Integration_ID__c;
            assignment.resource_id = newClaim.Claim_Adjuster__r.Claimatic_Integration_ID__c;
            assignment.assignment_party_id = 1;
            assignment.is_primary = 1;
            //assignment.to_remove_resource_email=acc.PersonEmail;
            //assignment.to_remove_resource_username=acc.Resource_Username__c;
            assignment.to_remove_resource_email='';
            assignment.to_remove_resource_username='';
            assignment.to_remove_resource_num = u.Claimatic_Integration_ID__c;
            assignment.to_remove_resource_id = u.Claimatic_Integration_ID__c;
            request.assignments.add(assignment);
        }
        String RequestString = JSON.serialize(request);
        return RequestString;
    }
}