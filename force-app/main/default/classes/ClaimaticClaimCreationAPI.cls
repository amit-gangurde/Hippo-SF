/*******************************************************************************************
* @Name         ClaimaticClaimCreationAPI
* @Author       jonathanschwartz
* @Date         07/15/2021
* @Group        Claimatic Service
* @Description  This class contains Create new claim service in the claimatic system
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*  1.1            jonathanschwartz  07/15/2021          update to use claim object
*******************************************************************************************/

public class ClaimaticClaimCreationAPI{

    public static List<Claim> loadData(Set<Id> claimIds) {
        return [SELECT Id,
                CreatedDate, (SELECT Name, Coverage_Amount__c FROM ClaimCoverages),
        (SELECT Name, Deductible_Amount__c FROM Claim_Deductibles__r),
                Date_of_Loss__c,
                Name,
                PolicyNumber.Name,
                PolicyNumber.Type__c,
                PolicyNumber.NameInsured.FirstName,
                PolicyNumber.NameInsured.LastName,
                PolicyNumber.NameInsured.PersonMailingStreet,
                PolicyNumber.NameInsured.PersonMailingCity,
                PolicyNumber.NameInsured.PersonMailingState,
                PolicyNumber.NameInsured.PersonMailingPostalCode,
                PolicyNumber.NameInsured.PersonMailingCountry,
                PolicyNumber.NameInsured.Phone,
                PolicyNumber.NameInsured.PersonMobilePhone,
                PolicyNumber.NameInsured.PersonOtherPhone,
                PolicyNumber.NameInsured.PersonEmail,
                PolicyNumber.Coverage_A_Dwelling_rebuilding__c,
                PolicyNumber.Coverage_B_Separate_structure__c,
                PolicyNumber.Coverage_C_Personal_property__c,
                PolicyNumber.Coverage_D_Loss_of_use__c,
                PolicyNumber.Coverage_E__c,
                PolicyNumber.Coverage_F__c,
                PolicyNumber.Deductible__c,
                PolicyNumber.Wind_Deductible__c,
                PolicyNumber.PolicyType,
                PolicyNumber.Street__c,
                PolicyNumber.City__c,
                PolicyNumber.State__c,
                PolicyNumber.Zip__c,
                Peril__c,
                Loss_Description__c,
                Mitigation_Needed__c,
                PolicyNumber.Water_backup__c,
                PolicyNumber.Effective_Date__c,
                PolicyNumber.Effective_Time__c,
                PolicyNumber.ExpirationDate,
                Have_a_Contractor__c,
                PolicyNumber.Actual_cash_value_on_roof_requested__c,
                Damage_Level__c,Status,
                Damage_Description__c,Are_repairs_required__c
        FROM Claim WHERE Id IN: claimIds];
    }

    @Future(Callout=true)
    public static void CreateClaim(Set<Id> claimIds){
        String token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Log__c> logs = new List<Log__c>();
        Claim clmRec = new Claim();
        List<Claim> updateClaimList = new List<Claim>();
        List<Claim> newClaimList = new List<Claim>();
        try{
            newClaimList = loadData(claimIds);
            System.debug(LoggingLevel.DEBUG, 'number of entries to create is ' + newClaimList.size());
            System.debug(LoggingLevel.DEBUG, 'claim ids ' + claimIds);
            for(Claim c : newClaimList){
                List<Id> ids = new List<Id>();
                ids.add(c.Id);
                Integration__c integ = Integration__c.getOrgDefaults();
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(integ.Multiclaim_URL__c);
                req.setMethod('POST');
                req.setHeader('Content-Type','application/xml');
                req.setHeader('Authorization','Bearer '+token);
                String body = generateXML(c);
                req.setBody(body);
                System.debug(body);
                HttpResponse res =new HttpResponse();
                res = h.send(req);
                System.debug('==Response Body=='+res.getBody());
                if(res.getStatusCode() == 200){
                    if(res.getBody().contains('<status_code>')){
                        String successCode = res.getBody().substringBetween('<status_code>','</status_code>');
                        if(successCode != null && successCode == '1'){
                            // we do this in the rest callback now, so don't set it here
                            //c.Sent_to_Claimatic__c = true;
                            updateClaimList.add(c);
                        }
                    }
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Creation API',integ.Multiclaim_URL__c,req.getBody(),res.getBody(),String.valueOf(res.getStatusCode()),'Integration','Success'));
                }else{
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Creation API',integ.Multiclaim_URL__c,req.getBody(),res.getBody(),String.valueOf(res.getStatusCode()),'Integration','Error'));
                }
            }
            if(!updateClaimList.isEmpty()) {
                clmRec = updateClaimList[0];
                //update updateClaimList;
            }

        }catch(Exception e){
            System.debug('Exception ex:::'+e);
             System.debug('Exception ex:::'+e.getLineNumber());
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimCreationAPI','CreateClaim','Claim',clmRec.Id,'N/A','Error'));
        }
        insert logs;
    }

    public static String generateXML(Claim c){
        Decimal coverageA = ClaimaticAPIUtility.getCoverage(c, 'Coverage A', c.PolicyNumber.Coverage_A_Dwelling_rebuilding__c);
        Decimal coverageB = ClaimaticAPIUtility.getCoverage(c, 'Coverage B', c.PolicyNumber.Coverage_B_Separate_structure__c);
        Decimal coverageC = ClaimaticAPIUtility.getCoverage(c, 'Coverage C', c.PolicyNumber.Coverage_C_Personal_property__c);
        Decimal coverageD = ClaimaticAPIUtility.getCoverage(c, 'Coverage D', c.PolicyNumber.Coverage_D_Loss_of_use__c);
        Decimal coverageE = ClaimaticAPIUtility.getCoverage(c, 'Coverage E', c.PolicyNumber.Coverage_E__c);
        Decimal coverageF = ClaimaticAPIUtility.getCoverage(c, 'Coverage F', c.PolicyNumber.Coverage_F__c);

        Decimal generalDeductible = ClaimaticAPIUtility.getDeductible(c, 'General', c.PolicyNumber.Deductible__c);
        Decimal windDeductible = ClaimaticAPIUtility.getDeductible(c, 'Wind', c.PolicyNumber.Wind_Deductible__c);
        
        //************* Added Null Checks for Date avoiding nullpointer exception @ SFDC-859 *****************************************************//
        String dateOfLoss = c.Date_of_Loss__c!=null ? Datetime.newInstance(c.Date_of_Loss__c.year(),c.Date_of_Loss__c.month(),c.Date_of_Loss__c.day()).format('YYYY-MM-dd'):null; 
        String policyExpirationDate = c.PolicyNumber.ExpirationDate!=null ? c.PolicyNumber.ExpirationDate.format('YYYY-MM-dd'):null;
        String policyEffectiveDate = c.PolicyNumber.Effective_Date__c!=null? Datetime.newInstance(c.PolicyNumber.Effective_Date__c, c.PolicyNumber.Effective_Time__c).format('YYYY-MM-dd'):null;
       //****************** Modified code refered in the xml request generation ******************************************************************//
        
        String xmlString = '<?xml version="1.0" encoding="UTF-8"?><Request><Claims>';
        xmlString = xmlString + '<Claim DateReceived="'+c.CreatedDate.format('YYYY-MM-dd')+
                '" DateOfLoss="'+dateOfLoss+
                '" ClaimNumber="'+c.Id+'">';
        xmlString = xmlString + '<Policy PolicyNumber="'+c.PolicyNumber.Name+'" PolicyType="'+ClaimaticAPIUtility.getPolicyType(c.PolicyNumber.PolicyType)+
                '" PolicyStart="'+ policyEffectiveDate +
                '" PolicyEnd="'+policyExpirationDate+ '"/>';
        xmlString = xmlString + '<Insureds><Insured>';
        xmlString = xmlString + '<Contact First_Name="'+c.PolicyNumber.NameInsured.FirstName+
                '" Last_Name="'+c.PolicyNumber.NameInsured.LastName+
                '" Phone="'+c.PolicyNumber.NameInsured.Phone+
                '" Cell="'+c.PolicyNumber.NameInsured.PersonMobilePhone+
                '" Alt="'+c.PolicyNumber.NameInsured.PersonOtherPhone+
                '" Email="'+c.PolicyNumber.NameInsured.PersonEmail+'"/>';
        xmlString = xmlString + '<Address Street="'+c.PolicyNumber.NameInsured.PersonMailingStreet+
                '" City="'+c.PolicyNumber.NameInsured.PersonMailingCity+
                '" State="'+c.PolicyNumber.NameInsured.PersonMailingState+
                '" County="" Zip="'+c.PolicyNumber.NameInsured.PersonMailingPostalCode+
                '" Country="'+c.PolicyNumber.NameInsured.PersonMailingCountry+'" />';
        xmlString = xmlString + '</Insured></Insureds>';
        xmlString = xmlString + '<Coverages>';
        xmlString = xmlString + '<Coverage Name="Coverage A Dwelling rebuilding" Coverage_Amount="'+coverageA+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage B Separate structure" Coverage_Amount="'+coverageB+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage C Personal property" Coverage_Amount="'+coverageC+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage D Loss of use" Coverage_Amount="'+coverageD+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage E" Coverage_Amount="'+coverageE+'" Reserve_Amount="500.00" />';
        xmlString = xmlString + '<Coverage Name="Coverage F" Coverage_Amount="'+coverageF+'" Reserve_Amount="500.00" />';
        xmlString = xmlString + '</Coverages>';
        xmlString = xmlString + '<Deductibles>';
        xmlString = xmlString + '<Deductible Name="Deductible" Deductible_Amount="'+generalDeductible+'"/>';
        xmlString = xmlString + '<Deductible Name="Wind Deductible" Deductible_Amount="'+windDeductible+'"/>';
        xmlString = xmlString + '</Deductibles>';
        xmlString = xmlString + '<Addresses>';
        xmlString = xmlString + '<Address LossType="Yes" Type="'+c.PolicyNumber.PolicyType+
                '" Street="'+c.PolicyNumber.Street__c+
                '" City="'+c.PolicyNumber.City__c+
                '" State="'+c.PolicyNumber.State__c+
                '" County="" Zip="'+c.PolicyNumber.Zip__c+'" Country="US"/>';
        xmlString = xmlString + '</Addresses>';
        xmlString = xmlString + '<Loss_Specs>';
        xmlString = xmlString + '<COL Code="" Desc="" />';
        xmlString = xmlString + '<TOL Code="'+c.Peril__c+'" Desc="'+c.Peril__c+'" />';
        xmlString = xmlString + '<Loss_Description ><![CDATA['+c.Loss_Description__c+']]></Loss_Description>';
        xmlString = xmlString + '<Special_Notes><![CDATA['+c.Damage_Description__c+']]></Special_Notes>';
        xmlString = xmlString + '</Loss_Specs>';
        xmlString = xmlString + '<Custom_Attributes>';
        xmlString = xmlString + '<Attribute Name="custom_attribute_30" desc="Mitigation_Needed" value="'+c.Mitigation_Needed__c+'" />';
        xmlString = xmlString + '<Attribute Name="custom_attribute_29" desc="SF_ID" value="'+c.Id+'" />';
        xmlString = xmlString + '<Attribute Name="custom_attribute_26" desc="coverage_limit" value="'+c.PolicyNumber.Water_backup__c+'" />';
        if (c.Have_a_Contractor__c==true) {
            xmlString = xmlString + '<Attribute Name="custom_attribute_25" desc="contractor" value="Yes" />';
        } 
        else if (c.Have_a_Contractor__c==false) {
            xmlString = xmlString + '<Attribute Name="custom_attribute_25" desc="contractor" value="No" />';
        }
        if (c.PolicyNumber.Actual_cash_value_on_roof_requested__c) {
            xmlString = xmlString + '<Attribute Name="custom_attribute_24" desc="ACV" value="Yes"/>';
        } else {
            xmlString = xmlString + '<Attribute Name="custom_attribute_24" desc="ACV" value="No"/>';
        }
        xmlString = xmlString + '<Attribute Name="custom_attribute_23" desc="SEV" value="'+c.Damage_Level__c+'" />';
        xmlString = xmlString + ' </Custom_Attributes></Claim></Claims></Request>';
        return xmlString;
    }
}