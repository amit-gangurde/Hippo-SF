/*******************************************************************************************
* @Name         ClaimaticRESTService
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class contains REST service for updating Adjustor and Vendor
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/
@RestResource(UrlMapping='/UpdateClaim')
global class ClaimaticRESTService{

    global class Resource {
        public String idVal;
        public String userName;
        public String type;
        public String position;
        public String claimNumber;
    }

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        DOM.Document doc=new DOM.Document();
        String response;
        Boolean isVendorMatched,isAdjusterMatched;
        List<Log__c> Logs =new List<Log__c>();
        try{
            String cn;
            List<Resource> resources = new List<Resource>();
            System.debug(req.requestBody.toString());
            doc.load(req.requestBody.toString());
            DOM.XmlNode rootNode=doc.getRootElement();
            parseXML(rootNode,resources,cn);
            Set<String> claimNumber = new Set<String>();
            Map<String,String> AccountMap = new Map<String,String>();
            Map<String,String> vendorMap = new Map<String,String>();
            Map<String,String> userMap = new Map<String,String>();

            Map<String,String> AccountClaimMap = new Map<String,String>();
            Map<String,String> vendorClaimMap = new Map<String,String>();
            Map<String,String> userClaimMap = new Map<String,String>();

            Boolean VendorExists = false;
            Boolean AdjustorExists = false;
            for(Resource reso : resources){
                claimNumber.add(reso.claimNumber);
                if (reso.type == 'Vendor Partners') { // need to match with vendor or account
                    vendorClaimMap.put(reso.claimNumber, reso.idVal);
                    AccountClaimMap.put(reso.claimNumber,reso.idVal);
                }
                if(reso.type == 'Desk Adjuster') { // Need to match with users
                    userClaimMap.put(reso.claimNumber, reso.idVal);
                }
            }

            for(Claim_Vendor__c vendor : [SELECT Id,Claimatic_Integration_ID__c FROM Claim_Vendor__c WHERE Claimatic_Integration_ID__c IN: vendorClaimMap.values()]){
                vendorMap.put(vendor.Claimatic_Integration_ID__c,vendor.Id);
            }

            for(Account account : [SELECT Id,Claimatic_Integration_ID__c FROM Account WHERE Claimatic_Integration_ID__c IN: AccountClaimMap.values()]){
                AccountMap.put(account.Claimatic_Integration_ID__c,account.Id);
            }

            for(User u : [SELECT Id,Claimatic_Integration_ID__c FROM User WHERE Claimatic_Integration_ID__c IN: userClaimMap.values()]){
                userMap.put(u.Claimatic_Integration_ID__c,u.Id);
            }
            System.debug(userClaimMap);
            System.debug(vendorClaimMap);
            System.debug(AccountClaimMap);
            System.debug(userMap);
            System.debug(vendorMap);
            System.debug(AccountMap);
            List<Claim> updatedClaimList = new List<Claim>();
            List<Case> updatedCaseList = new List<Case>();
            for(Claim claim : [SELECT Id,Claim_Vendor__c,Claim_Adjuster__c FROM Claim WHERE Id IN: claimNumber]){
                System.debug(claim.Id);
                String claimId = String.valueOf(claim.Id);
                System.debug(vendorClaimMap.get(claimId));
                if(vendorMap.keySet().size() > 0){
                    if(vendorMap.containsKey(vendorClaimMap.get(claimId))){
                        VendorExists = true;
                        claim.Claim_Vendor__c = vendorMap.get(vendorClaimMap.get(claimId));
                        Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Claim',claimId,'Vendor Found Successfully','success'));
                    }else{
                        //Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Vendor Details Not found-'+AccountClaimMap.get(caseId),'failure'));
                        Logs.add(ClaimaticAPIUtility.createLogRecord('ClaimaticRESTService','',req.requestBody.toString(),response,'400','Integration','Error'));
                    }
                }else{
                    Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Claim',claimId,'Vendor Details Not Found-'+vendorClaimMap.get(claimId),'success'));
                }

                if(userMap.keySet().size() > 0){
                    if(userMap.containsKey(userClaimMap.get(claimId))){
                        AdjustorExists = true;
                        claim.Claim_Adjuster__c = userMap.get(userClaimMap.get(claimId));
                        Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Claim',claimId,'Adjuster Found Successfully','success'));
                    }else{
                        //Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Adjuster Details Not Found-'+UserClaimMap.get(caseId),'success'));
                        //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                        Logs.add(ClaimaticAPIUtility.createLogRecord('ClaimaticRESTService','',req.requestBody.toString(),response,'400','Integration','Error'));
                    }
                }else{
                    Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Claim',claimId,'Adjuster Details Not Found-'+userClaimMap.get(claimId),'success'));
                }
                updatedClaimList.add(claim);
            }
            for(Case cs : [SELECT Id,Claim_Vendor__c,Claims_Adjuster__c FROM Case WHERE Id IN: claimNumber]){
                System.debug(cs.Id);
                String caseId = String.valueOf(cs.Id);
                System.debug(AccountClaimMap.get(caseId));
                if(AccountMap.keySet().size() > 0){
                    if(AccountMap.containsKey(AccountClaimMap.get(caseId))){
                        VendorExists = true;
                        cs.Claim_Vendor__c = AccountMap.get(AccountClaimMap.get(caseId));
                        Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Vendor Found Successfully','success'));
                    }else{
                        //Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Vendor Details Not found-'+AccountClaimMap.get(caseId),'failure'));
                        Logs.add(ClaimaticAPIUtility.createLogRecord('ClaimaticRESTService','',req.requestBody.toString(),response,'400','Integration','Error'));
                    }
                }else{
                    Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Vendor Details Not Found-'+UserClaimMap.get(caseId),'success'));
                }

                if(userMap.keySet().size() > 0){
                    if(userMap.containsKey(userClaimMap.get(caseId))){
                        AdjustorExists = true;
                        cs.Claims_Adjuster__c = userMap.get(userClaimMap.get(caseId));
                        Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Adjuster Found Successfully','success'));
                    }else{
                        //Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Adjuster Details Not Found-'+UserClaimMap.get(caseId),'success'));
                        //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                        Logs.add(ClaimaticAPIUtility.createLogRecord('ClaimaticRESTService','',req.requestBody.toString(),response,'400','Integration','Error'));
                    }
                }else{
                    Logs.add(ClaimaticAPIUtility.createLogRecord(null,'Integration','ClaimaticRESTService','doPost','Case',CaseId,'Adjuster Details Not Found-'+UserClaimMap.get(caseId),'success'));
                }
                updatedCaseList.add(cs);
            }
            if(updatedClaimList.size() > 0 || updatedCaseList.size() > 0){
                response = '<?xml version="1.0" encoding="UTF-8"?><results><status_code>1</status_code><Message>Vendor and Adjustor Found</Message></results>';
                if (VendorExists && !AdjustorExists) {
                    response = '<?xml version="1.0" encoding="UTF-8"?><results><status_code>1</status_code><Message>Vendor Found and Adjustor Not Found</Message></results>';
                }
                else if (!VendorExists && AdjustorExists) {
                    response = '<?xml version="1.0" encoding="UTF-8"?><results><status_code>1</status_code><Message>Adjustor Found and Vendor Not Found</Message></results>';
                }
                else if (!VendorExists && !AdjustorExists) {
                    response = '<?xml version="1.0" encoding="UTF-8"?><results><status_code>0</status_code><Message>Adjustor and Vendor Not Found</Message></results>';
                }
                for (Claim c : updatedClaimList) {
                    c.Sent_to_Claimatic__c = true;
                }
                for (Case c : updatedCaseList) {
                    c.Sent_to_Claimatic__c = true;
                }
                update updatedClaimList;
                update updatedCaseList;
                res.responseBody = Blob.valueOf(response);
                res.statusCode = 200;
            }else{
                response = '<?xml version="1.0" encoding="UTF-8"?><results><status_code>0</status_code><Message>Case id Not found in salesforce</Message></results>';
                //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                Logs.add(ClaimaticAPIUtility.createLogRecord('ClaimaticRESTService','',req.requestBody.toString(),response ,'400','Integration','Error'));
            }
        }catch(Exception e){
            response = '<?xml version="1.0" encoding="UTF-8"?><results><status_code>0</status_code><message>'+e.getMessage()+'</message></results>';
            res.responseBody = Blob.valueOf(response);
            res.statusCode = 200;
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticRESTService','doPost','Claim','','','Error'));
        }
        insert Logs;
    }
/**************************************************************************************
* @Description  This method is used to parse the xml to get the vendor and adjustor
* @Param        DOM.XMLNode, Resources and claimNumber (String)
* @Return       Null
* @Example
* parseXML(rootNode,resources,cn);
**************************************************************************************/
    private static void parseXML(DOM.XmlNode node,List<Resource> resources,String cnum) {
        if (node.getNodeType() == DOM.XmlNodeType.ELEMENT) {
            if(node.getName()=='CLAIM'){
                if (cnum == null || cnum == '') {
                    cnum = node.getAttribute('claimNumber', null);
                }
            }
            if(node.getName()=='RESOURCE'){
                Resource res = new Resource();
                res.idVal = node.getAttribute('id',null);
                res.userName = node.getAttribute('username',null);
                res.type = node.getAttribute('type',null);
                res.position = node.getAttribute('position',null);
                res.claimNumber = cnum;
                resources.add(res);
            }
        }
        for (Dom.XmlNode child: node.getChildElements()) {
            parseXML(child,resources,cnum);
        }
    }
}