/*******************************************************************************************
* @Name         ClaimaticClaimUnassignmentAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class has a call out service to unassign vendor added to a claim
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/
public class ClaimaticClaimUnassignmentAPI {

    public static Claim_Vendor__c loadVendorData(Id id) {
        return [SELECT Id,Claimatic_Integration_ID__c,Contact_Email__c FROM Claim_Vendor__c WHERE Id = :id];
    }

    public static List<Claim> loadClaimData(List<Id> claimIds) {
        return [SELECT Id,Claim_Vendor__c FROM Claim WHERE Id IN: claimIds];
    }

    @Future(Callout=true)
    public static void UnassignClaim(List<Id> claimIds,List<Id> vendorIds){
        if (claimIds.size() != vendorIds.size()) {
            throw new IllegalArgumentException('calling unassignment api with mismatched counts of claims and vendors');
        }
        String token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Log__c> logs = new List<Log__c>();
        Claim faultRec;
        Integer statusCode;
        String responseBody;
        try{
            Integration__c integ = Integration__c.getOrgDefaults();
            List<Claim> newClaimList = loadClaimData(claimIds);
            for (Integer i = 0; i < newClaimList.size(); i++) {
                Id vendorId = vendorIds.get(i);
                Claim c = newClaimList.get(i);
                faultRec = c;
              //** Modified @ 12/1/2021 By Convene ***  if (c.Claim_Vendor__c.equals(vendorId)) {
                    Claim_Vendor__c vendor = loadVendorData(vendorId);
                    Http h = new Http();
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(integ.Unassign_Claim_URL__c);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/xml');
                    req.setHeader('Authorization', 'Bearer ' + token);
                    String body = generateJSON(c, vendor);
                    req.setBody(body);
                    System.debug(body);
                    HttpResponse res = new HttpResponse();
                    if (!Test.isRunningTest()) {
                        res = h.send(req);
                        responseBody = res.getBody();
                        statusCode = res.getStatusCode();
                    } else {
                        statusCode = 200;
                        StaticResource SR = new StaticResource();
                        SR = [SELECT Body FROM StaticResource WHERE Name = 'ClaimaticAuth'];
                        responseBody = SR.Body.toString();
                    }
                    if (statusCode == 200) {
                        //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                        logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment API', integ.Unassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Success'));
                    } else {
                        //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                        logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Unassignment API', integ.Unassign_Claim_URL__c, req.getBody(), responseBody, String.valueOf(statusCode), 'Integration', 'Error'));
                    }
               //** Modified @ 12/1/2021 By Convene*** }
            }
        }catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimUnassignmentAPI','UnassignClaim','Case',faultRec.Id,'N/A','Error'));
        }
        insert logs;
    }


    public static String generateJSON(Claim c,Claim_Vendor__c vendor){
        ClaimaticClaimUnassignmentRequest request = new ClaimaticClaimUnassignmentRequest();
        request.claim_number = c.Id;
        ClaimaticClaimUnassignmentRequest.cls_assignments assignment = new ClaimaticClaimUnassignmentRequest.cls_assignments();
        assignment.resource_email = vendor.Contact_Email__c;
        assignment.username = '';
        assignment.resource_num = vendor.Claimatic_Integration_ID__c;
        assignment.assignment_party_id = 0;
        assignment.is_primary = 0;
        request.unassignments.add(assignment);
        String RequestString = JSON.serialize(request);
        return RequestString;
    }
}