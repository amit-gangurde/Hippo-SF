public class VendorCreationAPI {
    public static PaymentAuth_Integration_System__c payAuthSetting;
    @AuraEnabled
    public static String createVendor(Id recordId){
         try{
            Claim_Vendor__c claim = [SELECT ID,Name,Business_type__c,Business_Sub_Type__c,Status__c,Category__c,Country__c,City__c,Contact_Email__c,Contact_Name__c,Contact_Phone__c,State__c,Street__c,Street_2__c,Website__c,Zip_Code__c,Business_TIN__c,Business_TIN_type__c FROM Claim_Vendor__c WHERE ID=: recordId];
            payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults();  
            
            requestWrapper req = new requestWrapper();
            
            req.BUS_BusinessId = claim.Id;
            req.BUS_Type = claim.Business_type__c;
            req.BUS_SubType = claim.Business_Sub_Type__c;
            req.BUS_Name = claim.Name;
            req.BUS_DBAName = '';
            req.BUS_EmailAddress = claim.Contact_Email__c;
            req.BUS_OfficePhone = claim.Contact_Phone__c;
            req.BUS_Fax = '';
             if(claim.Street__c!=null && claim.Street_2__c !=null){
               req.BUS_Street = claim.Street__c+' '+claim.Street_2__c;   
             }else if(claim.Street__c!=null){
                 req.BUS_Street = claim.Street__c; 
             }else if(claim.Street_2__c !=null){
                  req.BUS_Street = claim.Street_2__c;
             }
           
            req.BUS_City = claim.City__c;
            req.BUS_State = claim.State__c;
            req.BUS_Zipcode = claim.Zip_Code__c;
            req.BUS_Country = claim.Country__c;
            req.BUS_Status = claim.Status__c;
            req.BUS_Reportable1099 = '';
            req.BUS_ReportingType1099 = '';
            
            //************ Added two more mapping @ SFDC-856 *******************//
               req.BUS_TIN  = claim.Business_TIN__c;
            req.BUS_TINType  = claim.Business_TIN_type__c;
            
            String JSONRes = '{"session":"'+PaymentAuth.getSessionID()+'","str_json":"'+JSON.serialize(JSON.serialize(req,true))+'"}';
            JSONRes = JSONRes.replace('""', '"');
            System.debug(JSONRes);
            
            String logWrap = '';
            String urlEncodedBody = Constants.method+'='+Constants.method_CreateVendor+'&';
            urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
            urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
            urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSONRes, 'UTF-8'); 
            System.debug('urlEncodedBody=='+urlEncodedBody);
            
            HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
            String responseBody = response.getBody();
             System.debug('==responseBody==='+responseBody);
            if(responseBody.contains('Error')){
                responseBody = responseBody.replace('Error Message', 'Error_Message'); 
            }
            responseWrapper resWrap = (responseWrapper) JSON.deserialize(responseBody, responseWrapper.class);
            Claim_Vendor__c claimUpd = new Claim_Vendor__c();
            claimUpd.Id = recordId;
            if(resWrap.Status == 'Error'){
                claimUpd.Status_Message__c = resWrap.Error_Message; 
                claimUpd.Status__c = 'Error';
                update claimUpd;
                return 'Error: '+resWrap.Error_Message; 
            }
            claimUpd.Status_Message__c ='Success'; 
            claimUpd.Status__c = 'Success';
            update claimUpd;
        }catch(Exception ex){
            return 'Error: '+ex.getMessage();
        }
        return 'Success';
    }
    public static void handleFromTrigger(List<Claim_Vendor__c> claimVendorList){
        for(Claim_Vendor__c claim: claimVendorList){
          calloutFromTrigger(claim.id);
        }
    }
    @future(callout=true)
    public static void calloutFromTrigger(id claimId){
          createVendor(claimId);
    }
    public class requestWrapper{
        public String BUS_BusinessId;
        public String BUS_Type;
        public String BUS_SubType;
        public String BUS_Name;
        public String BUS_TIN;
        public String BUS_TINType;
        public String BUS_DBAName;
        public String BUS_EmailAddress;
        public String BUS_OfficePhone;
        public String BUS_Fax;
        public String BUS_Street;
        public String BUS_City;
        public String BUS_State;
        public String BUS_Zipcode;
        public String BUS_Country;
        public String BUS_Status;
        public String BUS_Reportable1099;
        public String BUS_ReportingType1099;
    }
    public class responseWrapper{
        public String BUS_BusinessId;
        public String Status;
        public String Error_Code;
        public String Error_Message;
    }
}