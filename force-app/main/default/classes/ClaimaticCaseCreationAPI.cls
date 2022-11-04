/**
 * Created by jonathanschwartz on 7/29/21.
 */

/*******************************************************************************************
* @Name         ClaimaticClaimCreationAPI
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  This class contains Create new claim service in the claimatic system
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation
*******************************************************************************************/

Public class ClaimaticCaseCreationAPI{
    @future(callout=true)
    public static void CreateClaim(set<id> caseIds){
        string token = ClaimaticAuthenticationAPI.AuthenticationService();
        List<Log__c> logs = new List<Log__c>();
        Case csRec = new Case();
        List<case> updateCaseList = new List<Case>();
        List<Case> newCaseList = new List<Case>();
        try{
            newCaseList = [select id,Are_repairs_required__c,CreatedDate,Date_of_Loss__c,POD_Claim_ID__c,CaseNumber
                    ,Insurance_Policy__r.Name,Insurance_Policy__r.Type__c,
                    Insurance_Policy__r.NameInsured.FirstName,Insurance_Policy__r.NameInsured.LastName,
                    Insurance_Policy__r.NameInsured.PersonMailingStreet,
                    Insurance_Policy__r.NameInsured.PersonMailingCity,
                    Insurance_Policy__r.NameInsured.PersonMailingState,
                    Insurance_Policy__r.NameInsured.PersonMailingPostalCode,
                    Insurance_Policy__r.NameInsured.PersonMailingCountry,
                    Insurance_Policy__r.NameInsured.Phone,
                    Insurance_Policy__r.NameInsured.PersonMobilePhone,
                    Insurance_Policy__r.NameInsured.PersonOtherPhone,
                    Insurance_Policy__r.NameInsured.PersonEmail,
                    Insurance_Policy__r.Coverage_A_Dwelling_rebuilding__c,
                    Insurance_Policy__r.Coverage_B_Separate_structure__c,
                    Insurance_Policy__r.Coverage_C_Personal_property__c,
                    Insurance_Policy__r.Coverage_D_Loss_of_use__c,
                    Insurance_Policy__r.Coverage_E__c,
                    Insurance_Policy__r.Coverage_F__c,
                    Insurance_Policy__r.Deductible__c,Insurance_Policy__r.Wind_Deductible__c,
                    Insurance_Policy__r.PolicyType,Insurance_Policy__r.Street__c,
                    Insurance_Policy__r.City__c,Insurance_Policy__r.State__c,
                    Insurance_Policy__r.Zip__c,Peril__c,Loss_Description__c,Mitigation_Needed__c,
                    Preferred_Contact_Method__c,Insurance_Policy__r.Water_backup__c,
                    Have_a_Contractor__c,Insurance_Policy__r.Actual_cash_value_on_roof_requested__c,
                    Damage_Level__c,status,CATCode__c,Damage_Description__c from Case where id IN: caseIds];
            for(case c : newCaseList){
                Integration__c integ = Integration__c.getOrgDefaults();
                HTTP h = new HTTP();
                HTTPRequest req = new HTTPRequest();
                req.setEndpoint(integ.Multiclaim_URL__c);
                req.setMethod('POST');
                req.setHeader('Content-Type','application/xml');
                req.setHeader('Authorization','Bearer '+token);
                req.setBody(generateXML(c));
                system.debug(generateXML(c));
                HTTPResponse res =new HttpResponse();
                res = h.send(req);
                system.debug(res.getBody());
                if(res.getStatusCode() == 200){
                    if(res.getBody().contains('<status_code>')){
                        string successCode = res.getBody().subStringBetween('<status_code>','</status_code>');
                        if(successCode != Null && successCode == '1'){
                            //c.sent_to_Claimatic__c = true;
                            updateCaseList.add(c);
                        }
                    }
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Creation API',integ.Multiclaim_URL__c,req.getBody(),res.getBody(),string.valueOf(res.getStatusCode()),'Integration','Success'));
                }else{
                    //IntegrationLog(Integration,EndPoint,Request,Response,StatusCode,Type,Status)
                    Logs.add(ClaimaticAPIUtility.createLogRecord('Claimatic Claim Creation API',integ.Multiclaim_URL__c,req.getBody(),res.getBody(),string.valueOf(res.getStatusCode()),'Integration','Error'));
                }
            }
            if(!updateCaseList.isEmpty())
                csRec = updateCaseList[0];
            //update updateCaseList;

        }Catch(Exception e){
            //ExceptionLog(Exception,type,className,MethodName,objectName,recId,CustomMessage,status)
            Logs.add(ClaimaticAPIUtility.createLogRecord(e,'Exception','ClaimaticClaimCreationAPI','CreateClaim','Case',csRec.id,'N/A','Error'));
        }
        insert logs;
    }


    public static string generateXML(Case c){
        string xmlString = '<?xml version="1.0" encoding="UTF-8"?><Request><Claims>';
        xmlString = xmlString + '<Claim DateReceived="'+c.CreatedDate.format('YYYY-MM-dd')+'" DateOfLoss="'+DateTime.newInstance(c.Date_of_Loss__c.year(),c.Date_of_Loss__c.month(),c.Date_of_Loss__c.day()).format('YYYY-MM-dd') +'" ClaimNumber="'+c.id+'" CATCode="'+c.CATCode__c+'">';
        xmlString = xmlString + '<Policy PolicyNumber="'+c.Insurance_Policy__r.Name+'" PolicyType="'+ClaimaticAPIUtility.getPolicyType(c.Insurance_Policy__r.PolicyType)+'"/>';
        xmlString = xmlString + '<Insureds><Insured>';
        xmlString = xmlString + '<Contact First_Name="'+c.Insurance_Policy__r.NameInsured.FirstName+'" Last_Name="'+c.Insurance_Policy__r.NameInsured.LastName+'" Phone="'+c.Insurance_Policy__r.NameInsured.Phone+'" Cell="'+c.Insurance_Policy__r.NameInsured.PersonMobilePhone+'" Alt="'+c.Insurance_Policy__r.NameInsured.PersonOtherPhone+'" Email="'+c.Insurance_Policy__r.NameInsured.PersonEmail+'"/>';
        xmlString = xmlString + '<Address Street="'+c.Insurance_Policy__r.NameInsured.PersonMailingStreet+'" City="'+c.Insurance_Policy__r.NameInsured.PersonMailingCity+'" State="'+c.Insurance_Policy__r.NameInsured.PersonMailingState+'" County="" Zip="'+c.Insurance_Policy__r.NameInsured.PersonMailingPostalCode+'" Country="'+c.Insurance_Policy__r.NameInsured.PersonMailingCountry+'" />';
        xmlString = xmlString + '</Insured></Insureds>';
        xmlString = xmlString + '<Coverages>';
        xmlString = xmlString + '<Coverage Name="Coverage A Dwelling rebuilding" Coverage_Amount="'+c.Insurance_Policy__r.Coverage_A_Dwelling_rebuilding__c+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage B Separate structure" Coverage_Amount="'+c.Insurance_Policy__r.Coverage_B_Separate_structure__c+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage C Personal property" Coverage_Amount="'+c.Insurance_Policy__r.Coverage_C_Personal_property__c+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage D Loss of use" Coverage_Amount="'+c.Insurance_Policy__r.Coverage_D_Loss_of_use__c+'" Reserve_Amount="" />';
        xmlString = xmlString + '<Coverage Name="Coverage E" Coverage_Amount="'+c.Insurance_Policy__r.Coverage_E__c+'" Reserve_Amount="500.00" />';
        xmlString = xmlString + '<Coverage Name="Coverage F" Coverage_Amount="'+c.Insurance_Policy__r.Coverage_F__c+'" Reserve_Amount="500.00" />';
        xmlString = xmlString + '</Coverages>';
        xmlString = xmlString + '<Deductibles>';
        xmlString = xmlString + '<Deductible Name="Deductible" Deductible_Amount="'+c.Insurance_Policy__r.Deductible__c+'"/>';
        xmlString = xmlString + '<Deductible Name="Wind Deductible" Deductible_Amount="'+c.Insurance_Policy__r.Wind_Deductible__c+'"/>';
        xmlString = xmlString + '</Deductibles>';
        xmlString = xmlString + '<Addresses>';
        xmlString = xmlString + '<Address LossType="Yes" Type="'+c.Insurance_Policy__r.PolicyType+'" Street="'+c.Insurance_Policy__r.Street__c+'" City="'+c.Insurance_Policy__r.City__c+'" State="'+c.Insurance_Policy__r.State__c+'" County="" Zip="'+c.Insurance_Policy__r.Zip__c+'" Country="US"/>';
        xmlString = xmlString + '</Addresses>';
        xmlString = xmlString + '<Loss_Specs>';
        xmlString = xmlString + '<COL Code="" Desc="" />';
        xmlString = xmlString + '<TOL Code="'+c.Peril__c+'" Desc="'+c.Peril__c+'" />';
        xmlString = xmlString + '<Loss_Description ><![CDATA['+c.Loss_Description__c+']]></Loss_Description>';
        xmlString = xmlString + '<Special_Notes><![CDATA['+c.Damage_Description__c+']]></Special_Notes>';
        xmlString = xmlString + '</Loss_Specs>';
        xmlString = xmlString + '<Custom_Attributes>';
        xmlString = xmlString + '<Attribute Name="custom_attribute_30" desc="Mitigation_Needed" value="'+c.Mitigation_Needed__c+'" />';
        xmlString = xmlString + '<Attribute Name="custom_attribute_29" desc="SF_ID" value="'+c.id+'" />';
        xmlString = xmlString + '<Attribute Name="custom_attribute_28" desc="Contact Notes" value="'+c.Preferred_Contact_Method__c+'" />';
        xmlString = xmlString + '<Attribute Name="custom_attribute_27" desc="Preferred_Contact_Method" value="'+c.Preferred_Contact_Method__c+'" />';
        xmlString = xmlString + '<Attribute Name="custom_attribute_26" desc="coverage_limit" value="'+c.Insurance_Policy__r.Water_backup__c+'" />';
        if (c.Have_a_Contractor__c==true) {
            xmlString = xmlString + '<Attribute Name="custom_attribute_25" desc="contractor" value="Yes" />';
        } 
        else if (c.Have_a_Contractor__c==false) {
            xmlString = xmlString + '<Attribute Name="custom_attribute_25" desc="contractor" value="No" />';
        }
        if(c.Insurance_Policy__r.Actual_cash_value_on_roof_requested__c)
            xmlString = xmlString + '<Attribute Name="custom_attribute_24" desc="ACV" value="Yes"/>';
        else
                xmlString = xmlString + '<Attribute Name="custom_attribute_24" desc="ACV" value="No"/>';

        xmlString = xmlString + '<Attribute Name="custom_attribute_23" desc="SEV" value="'+c.Damage_Level__c+'" />';
        xmlString = xmlString + ' </Custom_Attributes></Claim></Claims></Request>';
        return xmlString;
    }
}