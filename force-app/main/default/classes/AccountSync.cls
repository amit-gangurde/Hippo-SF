public class AccountSync {
    public static boolean isRecursive = false;
    public static Map<String,Sync_Field_Mapping__mdt> externalFieldsMapping = new Map<String,Sync_Field_Mapping__mdt>();
    public static String DATETIME_DATABASE_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
    public static Hippo_Last_Sync__c sync = Hippo_Last_Sync__c.getOrgDefaults(); 
    public static string nextURL = '';
    public static string IntegID = '';
    //@future(Callout=true)
    public static loggerWrapper accountSyncHelper(String JSONData,Id objectID,String ExternalID,String method,String endPoint,String objectName,DateTime startDate,DateTime endDate){
        Id logID = null;
        try{ 
            System.debug('endPoint==='+endPoint);
            List<sObject> sObjectList = new List<sObject>();
            AccountSync.isRecursive = true;
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            request.setMethod(method);
            request.setTimeout(100000);
            request.setEndpoint(endPoint);
            SYstem.debug('JSONData==='+JSONData);
            if(!String.isBlank(JSONData)){
                request.setBody(JSONData);
            }
            request.setHeader('Content-Type', 'application/json');
            SYstem.debug('endPoint==='+endPoint);
            response = http.send(request);
            System.debug('response>>>>>>>>>>>>'+response.getBody());
            loggerWrapper logWrap = new loggerWrapper();
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                Id loggerId = IntegrationLogger.createIntegrationLog(objectName+' Sync-'+DateTime.now(),'AccountSync','accountSyncHelper', method,endPoint,JSONData,response.getBody(),'Success',objectName,objectID,ExternalID,startDate,endDate);
                IntegrationErrorLogger.createErrorLog('AccountSync', 'accountSyncHelper', null, 'Success',loggerId, 'Integration',String.valueOf(sObjectList),'Success',null);
                logWrap.logID = loggerId; 
                logID = loggerId; 
                IntegID = loggerId;
                responseReturnWrapper resWrap  = responseHandler(response,objectName,objectID);
                logWrap.sObjectList = resWrap.sObjectList;
                logWrap.nextRecordsUrl = resWrap.nextRecordsUrl;
            }else if(response.getStatusCode() >=300 && response.getStatusCode() <= 307 && response.getStatusCode() != 306) {
                String loc = response.getHeader('Location'); // get location of the redirect
                system.debug('loc===='+loc);
                Id loggerId =  IntegrationLogger.createIntegrationLog(objectName+' Sync-'+DateTime.now(),'AccountSync','accountSyncHelper', method,endPoint,JSONData,'URL Relocated: '+loc,'Failure',objectName,objectID,ExternalID,startDate,endDate);
                IntegrationErrorLogger.createErrorLog('AccountSync', 'accountSyncHelper', null, 'Error',logID, 'Integration','URL Relocated: '+loc,'Error',null);
                IntegID = loggerId;
            }else{
                Id loggerId =  IntegrationLogger.createIntegrationLog(objectName+' Sync-'+DateTime.now(),'AccountSync','accountSyncHelper', method,endPoint,JSONData,response.getBody(),'Failure',objectName,objectID,ExternalID,startDate,endDate);
                logWrap.logID = loggerId; 
                logWrap.sObjectList = sObjectList;
                logID = loggerId;
                IntegID = loggerId;
                IntegrationErrorLogger.createErrorLog('AccountSync', 'accountSyncHelper', null, 'Error',logID, 'Integration',response.getBody(),'Error',null);
                
            }
            return logWrap;
        }catch(Exception ex){
            System.debug('ex:::'+ex.getMessage());
            System.debug('exLine:::'+ex.getLineNumber());
            IntegrationErrorLogger.createErrorLog('AccountSync', 'accountSyncHelper', ex, 'Error',logID, 'DML',String.valueOf(ex.getMessage()),'Error',null);
            return null;
        }
        
    }
    public static responseReturnWrapper responseHandler(HttpResponse response,String objectName,String objectID){
        responseReturnWrapper resWrap = new responseReturnWrapper();
        List<sObject> listSobjectsRecords = new List<sObject>();
        
        if(objectName == 'Account' || objectName == 'Contact'){
            System.debug('response>>>>>>>>>>>>'+response.getBody());
            responseWrapper res = (responseWrapper) JSON.deserialize(response.getBody(), responseWrapper.class);
            Schema.SObjectType t = Schema.getGlobalDescribe().get(objectName);
            SObject sObjectAccount = t.newSObject(objectID);
            sObjectAccount.put('Hippo_CRM_Identifier__c', res.Id);
            // Update sObjectAccount;
            listSobjectsRecords.add(sObjectAccount);
            
        }else if(objectName == 'License__c' || objectName == 'Carrier_Appointment__c' || objectName == 'Producer_Licensing__c' || objectName == 'Line_of_Authority__c'){
            String responseBody = response.getBody();
            if(Test.isRunningTest() && objectName == 'Producer_Licensing__c'){
                responseBody = '{"totalSize":54,"done":true,"records":[{"attributes":{"type":"agentsync__Producer_Licensing__c","url":"/services/data/v49.0/sobjects/agentsync__Producer_Licensing__c/a0P55000001vL0kEAE"},"Id":"a0P55000001vL0kEAE","Name":"test"},{"attributes":{"type":"agentsync__Producer_Licensing__c","url":"/services/data/v49.0/sobjects/agentsync__Producer_Licensing__c/a0P55000001vciQEAQ"},"Id":"a0P55000001vciQEAQ","Name":"final commit"},{"attributes":{"type":"agentsync__Producer_Licensing__c","url":"/services/data/v49.0/sobjects/agentsync__Producer_Licensing__c/a0P55000001vclcEAA"},"Id":"a0P55000001vclcEAA","Name":"final two test"}]}';
            }else if(Test.isRunningTest() && objectName == 'License__c'){
                responseBody = '{"totalSize":71,"done":true,"records":[{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fo54EAA"},"Name":"Convence1","agentsync__Account__c":null,"agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__STATE__c":null,"agentsync__Unique_ID__c":null,"agentsync__User__c":null,"Id":"a0H55000005fo54EAA","agentsync__Producer_Licensing__c":"a0P55000001vciQEAQ"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fo5GEAQ"},"Name":"ConvAccount","agentsync__Account__c":"0015500001FOlxsAAD","agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__STATE__c":null,"agentsync__Unique_ID__c":null,"agentsync__User__c":null,"Id":"a0H55000005fo5GEAQ","agentsync__Producer_Licensing__c":"a0P55000001vciQEAQ"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fe8REAQ"},"Name":"123","agentsync__Account__c":null,"agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__STATE__c":null,"agentsync__Unique_ID__c":null,"agentsync__User__c":null,"Id":"a0H55000005fe8REAQ","agentsync__Producer_Licensing__c":"a0P55000001vL0kEAE"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fbF5EAI"},"Name":"test account syncedit","agentsync__Account__c":"0015500001FActmAAD","agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__STATE__c":null,"agentsync__Unique_ID__c":null,"agentsync__User__c":null,"Id":"a0H55000005fbF5EAI","agentsync__Producer_Licensing__c":"a0P55000001vclcEAA"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fVRrEAM"},"Name":"test lic","agentsync__Account__c":null,"agentsync__ACTIVE__c":null,"agentsync__Branch_ID__c":null,"agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":null,"agentsync__LICENSE_CLASS_CODE__c":null,"agentsync__DATE_EXPIRE_LICENSE__c":null,"agentsync__DATE_ISSUE_LICENSE_ORIG__c":null,"agentsync__LICENSE_NUM__c":null,"agentsync__DATE_UPDATED__c":null,"agentsync__NPN__c":null,"agentsync__RESIDENCY_STATUS__c":null,"agentsync__STATE__c":null,"agentsync__Unique_ID__c":null,"agentsync__User__c":null,"Id":"a0H55000005fVRrEAM","agentsync__Producer_Licensing__c":"a0P55000001vclcEAA"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fzr3EAA"},"Name":"NJ: 1638976","agentsync__Account__c":"0015500001FOlxsAAD","agentsync__ACTIVE__c":"Yes","agentsync__Branch_ID__c":"53994443","agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":"Insurance Producer","agentsync__LICENSE_CLASS_CODE__c":"3","agentsync__DATE_EXPIRE_LICENSE__c":"2021-05-31","agentsync__DATE_ISSUE_LICENSE_ORIG__c":"2017-04-24","agentsync__LICENSE_NUM__c":"1638976","agentsync__DATE_UPDATED__c":"2020-05-07","agentsync__NPN__c":"17991161","agentsync__RESIDENCY_STATUS__c":"NR","agentsync__STATE__c":"NJ","agentsync__Unique_ID__c":"179911611638976NJ3LIC","agentsync__User__c":null,"Id":"a0H55000005fzr3EAA","agentsync__Producer_Licensing__c":"a0P55000001vkLHEAY"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fzr4EAA"},"Name":"NM: 3000277553","agentsync__Account__c":"0015500001FOlxsAAD","agentsync__ACTIVE__c":"Yes","agentsync__Branch_ID__c":"58950242","agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":"Insurance Producer","agentsync__LICENSE_CLASS_CODE__c":"3","agentsync__DATE_EXPIRE_LICENSE__c":"2021-02-28","agentsync__DATE_ISSUE_LICENSE_ORIG__c":"2018-04-10","agentsync__LICENSE_NUM__c":"3000277553","agentsync__DATE_UPDATED__c":"2020-10-21","agentsync__NPN__c":"17991161","agentsync__RESIDENCY_STATUS__c":"NR","agentsync__STATE__c":"NM","agentsync__Unique_ID__c":"179911613000277553NM3LIC","agentsync__User__c":null,"Id":"a0H55000005fzr4EAA","agentsync__Producer_Licensing__c":"a0P55000001vkLIEAY"},{"attributes":{"type":"agentsync__License__c","url":"/services/data/v49.0/sobjects/agentsync__License__c/a0H55000005fzr5EAA"},"Name":"NV: 3237655","agentsync__Account__c":"0015500001FOlxsAAD","agentsync__ACTIVE__c":"Yes","agentsync__Branch_ID__c":"49120855","agentsync__Contact__c":null,"agentsync__LICENSE_CLASS__c":"NON RES PRODUCER/PRODUCER FIRM","agentsync__LICENSE_CLASS_CODE__c":"1012","agentsync__DATE_EXPIRE_LICENSE__c":"2023-05-01","agentsync__DATE_ISSUE_LICENSE_ORIG__c":"2017-04-24","agentsync__LICENSE_NUM__c":"3237655","agentsync__DATE_UPDATED__c":"2020-10-09","agentsync__NPN__c":"17991161","agentsync__RESIDENCY_STATUS__c":"NR","agentsync__STATE__c":"NV","agentsync__Unique_ID__c":"179911613237655NV1012LIC","agentsync__User__c":null,"Id":"a0H55000005fzr5EAA","agentsync__Producer_Licensing__c":"a0P55000001vkLJEAY"}]}';    
            }else if(Test.isRunningTest() && objectName == 'Carrier_Appointment__c'){
                responseBody = '{"totalSize":582,"done":true,"records":[{"attributes":{"type":"agentsync__Carrier_Appointment__c","url":"/services/data/v49.0/sobjects/agentsync__Carrier_Appointment__c/a045500000AviFaAAJ"},"Name":"CA-2654421","agentsync__Account__c":"0015500001FOlxsAAD","agentsync__Agency_Name__c":"ConvenceAg","agentsync__FEIN_State_Co_ID__c":"12345","agentsync__Branch_ID__c":null,"agentsync__COCODE__c":"123456","agentsync__COMPANY_NAME__c":"COnvAccount","agentsync__Contact__c":null,"agentsync__Appointment_Effective_Date__c":"2021-01-20","agentsync__Producer_Licensing__c":"a0P55000001vciQEAQ","agentsync__FEIN__c":"12345","agentsync__COUNTY_CODE__c":null,"agentsync__LINE_OF_AUTHORITY__c":"1234","agentsync__LOA_CODE__c":null,"agentsync__NPN__c":null,"agentsync__APPONT_RENEWAL_DATE__c":"2021-01-20","agentsync__Source__c":"PDB","agentsync__State_Code__c":"AK","agentsync__Status__c":"Active","agentsync__STATUS_REASON_DATE__c":"2021-01-20","agentsync__Termination_Effective_Date__c":"2021-01-20","agentsync__TERMINATION_REASON__c":"Termination","agentsync__Unique_ID__c":null,"agentsync__User__c":null,"Id":"a045500000AviFaAAJ"},{"attributes":{"type":"agentsync__Carrier_Appointment__c","url":"/services/data/v49.0/sobjects/agentsync__Carrier_Appointment__c/a045500000AviFaAAJ"},"Name":"CA-2654421","agentsync__Account__c":"0015500001FOlxsAAD","agentsync__Agency_Name__c":"ConvenceAg","agentsync__FEIN_State_Co_ID__c":"12345","agentsync__Branch_ID__c":null,"agentsync__COCODE__c":"123456","agentsync__COMPANY_NAME__c":"COnvAccount","agentsync__Contact__c":null,"agentsync__Appointment_Effective_Date__c":"2021-01-20","agentsync__Producer_Licensing__c":"a0P55000001vciQEAQ","agentsync__FEIN__c":"12345","agentsync__COUNTY_CODE__c":null,"agentsync__LINE_OF_AUTHORITY__c":"1234","agentsync__LOA_CODE__c":null,"agentsync__NPN__c":null,"agentsync__APPONT_RENEWAL_DATE__c":"2021-01-20","agentsync__Source__c":"PDB","agentsync__State_Code__c":"AK","agentsync__Status__c":"Active","agentsync__STATUS_REASON_DATE__c":"2021-01-20","agentsync__Termination_Effective_Date__c":"2021-01-20","agentsync__TERMINATION_REASON__c":"Termination","agentsync__Unique_ID__c":null,"agentsync__User__c":null,"Id":"a045500000AviFaAAJ"}]}';
            }else if(Test.isRunningTest() && objectName == 'Line_of_Authority__c'){
                responseBody = '{"totalSize":110,"done":true,"records":[{"attributes":{"type":"agentsync__Line_of_Authority__c","url":"/services/data/v49.0/sobjects/agentsync__Line_of_Authority__c/a0I55000003GswoEAC"},"agentsync__AgentSync_Audit_Log__c":null,"agentsync__AUTHORITY_ISSUE_DATE__c":"2021-01-20","agentsync__Categories__c":"health;life","agentsync__CE_COMPLIANCE__c":"TEST","agentsync__CE_CREDITS_NEEDED__c":12.0,"agentsync__CE_RENEWAL_DATE__c":"2021-01-20","agentsync__License__c":"a0H55000005fo54EAA","agentsync__License_Number__c":null,"agentsync__LOA__c":"ConvenceLOA","agentsync__LOA_CODE__c":"1234","agentsync__NPN__c":null,"agentsync__STATUS__c":"Active","agentsync__STATUS_REASON__c":"ST123","agentsync__STATUS_REASON_DATE__c":"2021-01-20","agentsync__Unique_ID__c":null,"Name":"LOA-338064","Id":"a0I55000003GswoEAC"},{"attributes":{"type":"agentsync__Line_of_Authority__c","url":"/services/data/v49.0/sobjects/agentsync__Line_of_Authority__c/a0I55000003GaxMEAS"},"agentsync__AgentSync_Audit_Log__c":null,"agentsync__AUTHORITY_ISSUE_DATE__c":"2021-01-18","agentsync__Categories__c":"health","agentsync__CE_COMPLIANCE__c":"Compliance","agentsync__CE_CREDITS_NEEDED__c":1234.0,"agentsync__CE_RENEWAL_DATE__c":"2021-01-18","agentsync__License__c":"a0H55000005fe8REAQ","agentsync__License_Number__c":null,"agentsync__LOA__c":"LOA test123","agentsync__LOA_CODE__c":"LA123456","agentsync__NPN__c":null,"agentsync__STATUS__c":"Active","agentsync__STATUS_REASON__c":"abc","agentsync__STATUS_REASON_DATE__c":"2021-01-18","agentsync__Unique_ID__c":null,"Name":"LOA-338063","Id":"a0I55000003GaxMEAS"}]}';
            }
            Map<String, Object> results =  (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            Integer totalSize = (Integer)results.get('totalSize'); //nextRecordsUrl
            resWrap.totalSize = totalSize;
            resWrap.nextRecordsUrl = (String)results.get('nextRecordsUrl');
            nextURL = (String)results.get('nextRecordsUrl');
            List<Object> responseList = (List<Object>)results.get('records');
            if(objectName == 'License__c'){
                sync.Last_Sync_License_Records_C__c = totalSize;
                listSobjectsRecords = upsertLicenseInfo(responseList,totalSize);  
            }else if(objectName == 'Carrier_Appointment__c'){
                sync.Last_Sync_Carrier_APPT_Records_Count__c = totalSize;
                listSobjectsRecords =  upsertCarrerAppointmentInfo(responseList,totalSize);
            }else if(objectName == 'Producer_Licensing__c'){
                sync.Last_Sync_Producer_Records_Count__c = totalSize;
                listSobjectsRecords = upsertProducerInfo(responseList,totalSize);
            }else if(objectName == 'Line_of_Authority__c'){
                sync.Last_Sync_LOA_Records_Count__c = totalSize;
                listSobjectsRecords = upsertLicenseAuthorityInfo(responseList,totalSize);
            }
            update sync;
        }
        resWrap.sObjectList = listSobjectsRecords;
        return resWrap;
    }
    public static loggerWrapper getLicenseInfo(DateTime startDate,DateTime endDate,String nextUrl){
        Set<String> loaCodes = new Set<String>();
        Line_Of_Authority_Filter__mdt loaFilter = [SELECT Active_LOA_Categories__c FROM Line_Of_Authority_Filter__mdt LIMIT 1];
        List<String> loaFilters = loaFilter.Active_LOA_Categories__c.split(',');
        
        System.debug('loaCodes==='+loaCodes);
        //Active_LOA_Categories__c
        System.debug('enteredUrl==='+nextUrl);
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'License']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        }
        Data_Sync__mdt syncContactCreateAPI = [SELECT DeveloperName,End_Point__c,Method__c FROM Data_Sync__mdt WHERE DeveloperName =: 'LicenseSync'];
        List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('License_Sync','License__c');
        String Query = 'SELECT+';
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
            if(externalFieldsMapping.containsKey(fieldSetMemberObj.getFieldPath())){
                Query += externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c+',+';
                system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()+',+'); //api name
            }
        }
        Query = Query.removeEnd(',+');
        Query += '+';
        // startDate = startDate.addHours(-24);
        startDate = startDate.addHours(7);
        endDate = endDate.addHours(7);
        
        String encodedStartDate = 'LastModifiedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String encodedLastDate = 'LastModifiedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        // String encodedStartDate = 'CreatedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        //  String encodedLastDate = 'CreatedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        String dateTimeNow = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String expirationDate = 'agentsync__DATE_EXPIRE_LICENSE__c >='+dateTimeNow;
        System.debug('loaCodes=='+loaCodes);
        
        String loaCodesString = '(';
        for(String sync:loaFilters){
            loaCodesString+='\''+sync+'\',';
        }
        loaCodesString = loaCodesString.removeEnd(',');
        loaCodesString += ')';
        System.debug('loaCodesString=='+loaCodesString);
        //Query += 'FROM+agentsync__License__c+WHERE+agentsync__Contact__c=\'0034v000031fUrTAAU\'';
        /*** ORG ****/ Query += 'FROM+agentsync__License__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('Active_LOA_Categories__c includes '+loaCodesString,'UTF-8')+'+AND+agentsync__ACTIVE__c=\'Yes\''+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        // Query += 'FROM+agentsync__License__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('Active_LOA_Categories__c includes '+loaCodesString,'UTF-8')+'+AND+agentsync__ACTIVE__c=\'Yes\'';//+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        //  Query += 'FROM+agentsync__License__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('Active_LOA_Categories__c includes '+loaCodesString,'UTF-8');//+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        
        // Query += 'FROM+agentsync__License__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('Active_LOA_Categories__c includes '+loaCodesString,'UTF-8')+'+AND+agentsync__ACTIVE__c=\'Yes\''+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        Query = Query.trim();
        System.debug('syncContactCreateAPI.End_Point__c+= Query=='+syncContactCreateAPI.End_Point__c+Query);
        loggerWrapper sObjectList;
        System.debug('enterednextUrl==='+nextUrl);
        if(String.isBlank(nextUrl) || nextUrl == null){
            sObjectList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,syncContactCreateAPI.End_Point__c+Query,'License__c',startDate,endDate);
        }else{
            sObjectList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,'callout:Hippo_AgentSync'+nextUrl,'License__c',startDate,endDate);
        }
        return sObjectList;
    }
    public static loggerWrapper getLineAuthorityInfo(DateTime startDate,DateTime endDate,String nextUrl){
        Set<String> loaCodes = new Set<String>();
        Line_Of_Authority_Filter__mdt loaFilter = [SELECT License_Codes__c FROM Line_Of_Authority_Filter__mdt LIMIT 1];
        List<String> loaFilters = loaFilter.License_Codes__c.split(',');
        
        System.debug('loaCodes==='+loaCodes);
        System.debug('enterednextUrl==='+nextUrl);
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'Line Of Authorities']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        }
        Data_Sync__mdt syncContactCreateAPI = [SELECT DeveloperName,End_Point__c,Method__c FROM Data_Sync__mdt WHERE DeveloperName =: 'LicenseSync'];
        List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('LineOfAuthority_Sync','Line_of_Authority__c');
        String Query = 'SELECT+';
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
            if(externalFieldsMapping.containsKey(fieldSetMemberObj.getFieldPath())){
                Query += externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c+',+';
                system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()+',+'); //api name
            }
        }
        Query = Query.removeEnd(',+');
        Query += '+';
        startDate = startDate.addHours(7);
        //startDate = startDate.addHours(-24);
        endDate = endDate.addHours(7);
        String encodedStartDate = 'LastModifiedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String encodedLastDate = 'LastModifiedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        //  
        // String encodedStartDate = 'CreatedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        //  String encodedLastDate = 'CreatedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        System.debug('loaCodes=='+loaCodes);
        
        String loaCodesString = '(';
        for(String sync:loaFilters){
            loaCodesString+='\''+sync+'\',';
        }
        loaCodesString = loaCodesString.removeEnd(',');
        loaCodesString += ')';
        System.debug('loaCodesString=='+loaCodesString);
        /** ORD **/ Query += 'FROM+agentsync__Line_of_Authority__c+WHERE+agentsync__STATUS__c=\'Active\'+AND+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('agentsync__LOA_CODE__c IN '+loaCodesString,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');//Line_of_Authority_Code__c+IN+{\'10052\',\'10352\'}'; //+EncodingUtil.Urlencode(String.valueOf(loaCodes),'UTF-8');//
        //++ Query += 'FROM+agentsync__Line_of_Authority__c+WHERE+agentsync__STATUS__c=\'Active\'+AND+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('agentsync__LOA_CODE__c IN '+loaCodesString,'UTF-8');
        Query = Query.trim();
        System.debug('Line_of_Authority__c.End_Point__c+= Query=='+syncContactCreateAPI.End_Point__c+Query);
        System.debug('enterednextUrl==='+nextUrl);
        loggerWrapper recordList;
        if(String.isBlank(nextUrl) || nextUrl == null){
            recordList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,syncContactCreateAPI.End_Point__c+Query,'Line_of_Authority__c',startDate,endDate); 
        }else{
            recordList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,'callout:Hippo_AgentSync'+nextUrl,'Line_of_Authority__c',startDate,endDate); 
        }
        return recordList;
    }
    public static  loggerWrapper getProducerInfo(DateTime startDate,DateTime endDate,String nextUrl){
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'Producer']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        }
        Data_Sync__mdt syncContactCreateAPI = [SELECT DeveloperName,End_Point__c,Method__c FROM Data_Sync__mdt WHERE DeveloperName =: 'LicenseSync'];
        List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('Producer_Sync','Producer_Licensing__c');
        String Query = 'SELECT+';
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
            if(externalFieldsMapping.containsKey(fieldSetMemberObj.getFieldPath())){
                Query += externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c+',+';
                system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()+',+'); //api name
            }
        }
        startDate = startDate.addHours(7);
        // startDate = startDate.addHours(-24);
        endDate = endDate.addHours(7);
        String encodedStartDate = 'LastModifiedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String encodedLastDate = 'LastModifiedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        // String encodedStartDate = 'CreatedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        // String encodedLastDate = 'CreatedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        Query = Query.contains('Id')?Query:Query+'Id';
        Query = Query.removeEnd(',+');
        Query += '+';
        //+++  Query += 'FROM+agentsync__Producer_Licensing__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8');//+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');//+'+AND+LastModifiedDate>='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        Query += 'FROM+agentsync__Producer_Licensing__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        Query = Query.trim();
        
        System.debug('Producer_Licensing__c.End_Point__c+= Query=='+syncContactCreateAPI.End_Point__c+Query);
        loggerWrapper recordList;
        System.debug('nextUrl--Inside==='+nextUrl);
        if(String.isBlank(nextUrl) || nextUrl == null){
            recordList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,syncContactCreateAPI.End_Point__c+Query,'Producer_Licensing__c',startDate,endDate);
        }else{
            recordList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,'callout:Hippo_AgentSync'+nextUrl,'Producer_Licensing__c',startDate,endDate);
        }
        return recordList;
    }
    public static loggerWrapper getCarrierAppointmentInfo(DateTime startDate,DateTime endDate,String nextUrl){
        Set<String> loaCodes = new Set<String>();
        Line_Of_Authority_Filter__mdt loaFilter = [SELECT License_Codes__c,CA_CoCode_Filter__c,Active_LOA_CA_Categories__c FROM Line_Of_Authority_Filter__mdt LIMIT 1];
        List<String> loaFilters = loaFilter.License_Codes__c.split(',');
        List<String> cocodeFilters = loaFilter.CA_CoCode_Filter__c.split(',');
        List<String> activeLOACateg = loaFilter.Active_LOA_CA_Categories__c.split(',');
        System.debug('loaCodes==='+loaCodes);
        System.debug('enterednextUrl==='+nextUrl);
        
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'Carrier Appointment']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        }
        Data_Sync__mdt syncContactCreateAPI = [SELECT DeveloperName,End_Point__c,Method__c FROM Data_Sync__mdt WHERE DeveloperName =: 'LicenseSync'];
        List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('Carrier_Appointment','Carrier_Appointment__c');
        String Query = 'SELECT+';
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
            if(externalFieldsMapping.containsKey(fieldSetMemberObj.getFieldPath())){
                Query += externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c+',+';
                system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()+',+'); //api name
            } 
        }
        // startDate = startDate.addHours(6);
        startDate = startDate.addHours(7);
        endDate = endDate.addHours(7);
        String encodedStartDate = 'LastModifiedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String encodedLastDate = 'LastModifiedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        // String encodedStartDate = 'CreatedDate>='+startDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        //  String encodedLastDate = 'CreatedDate<='+endDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        System.debug('loaCodes=='+loaCodes);
        
        String loaCodesString = '(';
        for(String sync:loaFilters){
            loaCodesString+='\''+sync+'\',';
        }
        loaCodesString = loaCodesString.removeEnd(',');
        loaCodesString += ')';
        System.debug('loaCodesString=='+loaCodesString);
        
        
        String coCodesString = '(';
        for(String sync:cocodeFilters){
            coCodesString+='\''+sync+'\',';
        }
        coCodesString = coCodesString.removeEnd(',');
        coCodesString += ')';
        System.debug('coCodesString=='+coCodesString);
        
        /**
String ActiveLOAString = '(';
for(String sync:activeLOACateg){
ActiveLOAString+='\''+sync+'\',';
}
ActiveLOAString = ActiveLOAString.removeEnd(',');
ActiveLOAString += ')';
System.debug('ActiveLOAString=='+ActiveLOAString);
**/
        
        String encodedLike = '(';
        Set<String> ActiveLOAString = new Set<String>();
        for(String sync:activeLOACateg){
            encodedLike+= EncodingUtil.Urlencode('Active_Line_of_Authority_Category__c LIKE \'%'+sync+'%\'','UTF-8')+'+OR+';
            //ActiveLOAString.add('\'%'+sync+'%\'');
        }
        encodedLike = encodedLike.removeEnd('+OR+');
        encodedLike+= ')';
        
        System.debug('=encodedLike=='+encodedLike);
        
        
        Query = Query.contains('Id')?Query:Query+'Id';  //
        Query = Query.removeEnd(',+');
        Query += '+'; //a043C000003uhvfQAA
        //Query += 'FROM+agentsync__Carrier_Appointment__c+WHER+AND(+'+EncodingUtil.Urlencode('agentsync__LOA_CODE__c IN '+loaCodesString,'UTF-8')+'+OR+'+EncodingUtil.Urlencode('Active_Line_of_Authority_Category__c IN '+loaCodesString,'UTF-8')+'+)AND+'+EncodingUtil.Urlencode('agentsync__COCODE__c IN '+coCodesString,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
       /** ORG **/ Query += 'FROM+agentsync__Carrier_Appointment__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND(+'+EncodingUtil.Urlencode('agentsync__LOA_CODE__c IN '+loaCodesString,'UTF-8')+'+OR+'+encodedLike+'+)AND+'+EncodingUtil.Urlencode('agentsync__COCODE__c IN '+coCodesString,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        //++ Query += 'FROM+agentsync__Carrier_Appointment__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('agentsync__LOA_CODE__c IN '+loaCodesString,'UTF-8')+'+AND+'+EncodingUtil.Urlencode('agentsync__COCODE__c IN '+coCodesString,'UTF-8');//+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        
        //Query += 'FROM+agentsync__Carrier_Appointment__c+WHERE+'+EncodingUtil.Urlencode(encodedStartDate,'UTF-8')+'+AND+agentsync__LOA_CODE__c=null+AND+'+encodedLike+'+AND+'+EncodingUtil.Urlencode('agentsync__COCODE__c IN '+coCodesString,'UTF-8')+'+AND+'+EncodingUtil.Urlencode(encodedLastDate,'UTF-8');
        Query = Query.trim();
        System.debug('Carrier_Appointment__c.End_Point__c+= Query=='+syncContactCreateAPI.End_Point__c+Query);  //
        System.debug('enterednextUrl==='+nextUrl);
        
        System.debug('==QUERY===='+Query);
        loggerWrapper recordList; 
        if(String.isBlank(nextUrl) || nextUrl == null){
            recordList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,syncContactCreateAPI.End_Point__c+Query,'Carrier_Appointment__c',startDate,endDate);
        }else{
            recordList = accountSyncHelper( null,null,null,syncContactCreateAPI.Method__c,'callout:Hippo_AgentSync'+nextUrl,'Carrier_Appointment__c',startDate,endDate);
            
        }
        return recordList;
    }
    public static List<sObject> upsertLicenseInfo(List<Object> responsesObjList,Integer totalSize){
        System.debug('responseList>>>OBJ>>'+responsesObjList);
        Map<Id,Id> accountMap = new  Map<Id,Id>();
        Map<Id,Id> contactMap = new  Map<Id,Id>();
        Map<Id,Id> licenseMap = new  Map<Id,Id>();
        
        Set<Id> accountID = new Set<Id>();
        Set<Id> contactID = new Set<Id>();
        Set<Id> licenseIDset = new Set<Id>();
        
        List<License__c> licenseList = new  List<License__c>(); 
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'License']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        }  
        System.debug('externalFieldsMapping>>>OBJ>>'+externalFieldsMapping);
        for(Object objVar: responsesObjList){
            Map<String, Object> responseAttributes = (Map<String, Object>)objVar;
            if(responseAttributes.get(externalFieldsMapping.get('Account__c').External_Field_API__c)!=null){
                accountID.add((Id)responseAttributes.get(externalFieldsMapping.get('Account__c').External_Field_API__c));
            }
            if(responseAttributes.get(externalFieldsMapping.get('Contact__c').External_Field_API__c)!=null){
                contactID.add((Id)responseAttributes.get(externalFieldsMapping.get('Contact__c').External_Field_API__c)); 
            }
            if(responseAttributes.get(externalFieldsMapping.get('Producer_Licensing__c').External_Field_API__c)!=null){
                licenseIDset.add((Id)responseAttributes.get(externalFieldsMapping.get('Producer_Licensing__c').External_Field_API__c));  
            }
        }
        System.debug('licenseIDset>>>OBJ>>'+licenseIDset); 
        for(Account acc:[SELECT ID,Hippo_CRM_Identifier__c FROM Account WHERE Hippo_CRM_Identifier__c IN: accountID]){
            accountMap.put(acc.Hippo_CRM_Identifier__c,acc.Id);
        }
        for(Contact con:[SELECT ID,Hippo_CRM_Identifier__c FROM Contact WHERE Hippo_CRM_Identifier__c IN: contactID]){
            contactMap.put(con.Hippo_CRM_Identifier__c,con.Id);
        }
        for(Producer_Licensing__c license:[SELECT ID,Hippo_CRM_Identifier__c FROM Producer_Licensing__c WHERE Hippo_CRM_Identifier__c IN: licenseIDset]){
            licenseMap.put(license.Hippo_CRM_Identifier__c,license.Id);
        }
        System.debug('licenseMap>>>OBJ>>'+licenseMap);
        List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('License_Sync','License__c');
        String objName = 'License__c';
        licenseList.addAll((List<License__c>)iterateResult(responsesObjList,totalSize,objName,fieldSetMemberList));
        for(License__c license: licenseList){
            System.debug('lic==='+ licenseMap.get(license.Producer_Licensing__c));
            license.Producer_Licensing__c = licenseMap.containsKey(license.Producer_Licensing__c)? licenseMap.get(license.Producer_Licensing__c):null;
            license.Account__c = accountMap.containsKey(license.Account__c)? accountMap.get(license.Account__c):null; 
            license.Contact__c =   contactMap.containsKey(license.Contact__c)? contactMap.get(license.Contact__c):null; 
        }
        System.debug('licenseListMpa===='+licenseMap);
        System.debug('licenseList===='+licenseList);
        return licenseList;
    }
    public static List<sObject> upsertProducerInfo(List<Object> responsesObjList,Integer totalSize){
        System.debug('responsesObjList==='+responsesObjList);
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'Producer']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        }  
        List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('Producer_Sync','Producer_Licensing__c');
        
        String objName = 'Producer_Licensing__c';
        List<Producer_Licensing__c> producerList = new  List<Producer_Licensing__c>();
        producerList.addAll((List<Producer_Licensing__c>)iterateResult(responsesObjList,totalSize,objName,fieldSetMemberList));
        System.debug('producerList===='+producerList);
        return producerList;
    }
    public static List<sObject> upsertLicenseAuthorityInfo(List<Object> responsesObjList,Integer totalSize){
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'Line Of Authorities']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        } 
        List<Line_of_Authority__c> LineList = new  List<Line_of_Authority__c>();
        Set<Id> licenseIDset = new Set<Id>();
        Map<String,String> licenseIDMap = new Map<String,String>();
        if(totalSize>0){
            for(Object objVar: responsesObjList){
                Map<String, Object> responseAttributes = (Map<String, Object>)objVar;
                if(!String.isBlank((String)responseAttributes.get(externalFieldsMapping.get('License__c').External_Field_API__c))!=null){
                    licenseIDset.add((Id)responseAttributes.get(externalFieldsMapping.get('License__c').External_Field_API__c));
                }
            }
            for(License__c license:[SELECT ID,Hippo_CRM_Identifier__c FROM License__c WHERE Hippo_CRM_Identifier__c IN: licenseIDset]){
                licenseIDMap.put(license.Hippo_CRM_Identifier__c,license.Id);
            }
            List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('LineOfAuthority_Sync','Line_of_Authority__c');
            String objName = 'Line_of_Authority__c';
            List<Line_of_Authority__c> licenseList = new  List<Line_of_Authority__c>();
            licenseList.addAll((List<Line_of_Authority__c>)iterateResult(responsesObjList,totalSize,objName,fieldSetMemberList));
            for(Line_of_Authority__c line: licenseList){
                line.License__c = licenseIDMap.containsKey(line.License__c)?licenseIDMap.get(line.License__c):null;  
            }
            return licenseList;
            //upsert LineList Hippo_CRM_Identifier__c;
        }
        return null;
    }
    public static List<sObject> upsertCarrerAppointmentInfo(List<Object> responsesObjList,Integer totalSize){
        for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c,Data_Type__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: 'Carrier Appointment']){
            externalFieldsMapping.put(sync.Internal_Field_API__c, sync);
        } 
        System.debug('responseList>>>OBJ>>'+responsesObjList);
        List<Carrier_Appointment__c> carrerList = new  List<Carrier_Appointment__c>();
        Map<Id,Id> accountMap = new  Map<Id,Id>();
        Map<Id,Id> contactMap = new  Map<Id,Id>();
        Map<Id,Id> licenseMap = new  Map<Id,Id>();
        if(totalSize>0){
            Set<Id> accountID = new Set<Id>();
            Set<Id> contactID = new Set<Id>();
            Set<Id> licenseID = new Set<Id>();
            for(Object carrer: responsesObjList){
                Map<String, Object> responseAttributes = (Map<String, Object>)carrer;
                System.debug('ExtMap Cont Key==='+externalFieldsMapping.get('Account__c').External_Field_API__c);
                if(!String.isBlank((String)responseAttributes.get(externalFieldsMapping.get('Account__c').External_Field_API__c))){
                    accountID.add((Id)responseAttributes.get(externalFieldsMapping.get('Account__c').External_Field_API__c));
                }
                System.debug('accountID'+accountID);
                if(!String.isBlank((String)responseAttributes.get(externalFieldsMapping.get('Contact__c').External_Field_API__c))){
                    contactID.add((Id)responseAttributes.get(externalFieldsMapping.get('Contact__c').External_Field_API__c));
                }
                System.debug('ExtMap Cont Key==='+externalFieldsMapping.containsKey('Producer_Licensing__c'));
                System.debug('responseAttributes Cont Key==='+responseAttributes.containsKey(externalFieldsMapping.get('Producer_Licensing__c').External_Field_API__c));
                if(externalFieldsMapping.containsKey('Producer_Licensing__c') && responseAttributes.containsKey(externalFieldsMapping.get('Producer_Licensing__c').External_Field_API__c) && !String.isBlank((String)responseAttributes.get(externalFieldsMapping.get('Producer_Licensing__c').External_Field_API__c))){
                    licenseID.add((Id)responseAttributes.get(externalFieldsMapping.get('Producer_Licensing__c').External_Field_API__c));
                }
            } System.debug('licenseID==='+licenseID);
            for(Account acc:[SELECT ID,Hippo_CRM_Identifier__c FROM Account WHERE Hippo_CRM_Identifier__c IN: accountID]){
                accountMap.put(acc.Hippo_CRM_Identifier__c,acc.Id);
            }
            for(Contact con:[SELECT ID,Hippo_CRM_Identifier__c FROM Contact WHERE Hippo_CRM_Identifier__c IN: contactID]){
                contactMap.put(con.Hippo_CRM_Identifier__c,con.Id);
            }
            for(Producer_Licensing__c license:[SELECT ID,Hippo_CRM_Identifier__c FROM Producer_Licensing__c WHERE Hippo_CRM_Identifier__c IN: licenseID]){
                licenseMap.put(license.Hippo_CRM_Identifier__c,license.Id);
            }
            System.debug('accountMap==='+accountMap);
            
            List<Schema.FieldSetMember> fieldSetMemberList = readFieldSet('Carrier_Appointment','Carrier_Appointment__c');
            
            
            String objName = 'Carrier_Appointment__c';
            List<Carrier_Appointment__c> carrierList = new  List<Carrier_Appointment__c>();
            carrierList.addAll((List<Carrier_Appointment__c>)iterateResult(responsesObjList,totalSize,objName,fieldSetMemberList));
            for(Carrier_Appointment__c carrier: carrierList){
                System.debug('bfr==='+carrier.Account__c);
                carrier.Account__c = accountMap.containsKey(carrier.Account__c)?accountMap.get(carrier.Account__c):null;
                System.debug('aftr==='+carrier.Account__c);
                carrier.Contact__c = contactMap.containsKey(carrier.Contact__c)?contactMap.get(carrier.Contact__c):null;
                carrier.Producer_Licensing__c = licenseMap.containsKey(carrier.Producer_Licensing__c)?licenseMap.get(carrier.Producer_Licensing__c):null;
            } 
            System.debug('carrierList==='+carrierList);
            return carrierList;
            // upsert  carrerList Hippo_CRM_Identifier__c;
            
        }
        return null;
    }
    public static  List<sObject> iterateResult(List<Object> responsesObjList,Integer totalSize,String objName,List<Schema.FieldSetMember> fieldSetMemberList){
        List<sObject> objectResultList = new List<sObject>();
        if(totalSize>0){
            for(Object objVar: responsesObjList){
                Map<String, Object> responseAttributes = (Map<String, Object>)objVar;
                sObject sObj = Schema.getGlobalDescribe().get(objName).newSObject();
                for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
                    System.debug('fieldSetMemberObj.getFieldPath()===>'+fieldSetMemberObj.getFieldPath());
                    // System.debug('DataType===>'+ responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).Data_Type__c));
                    //  System.debug('ExternalMap===>'+ responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c));
                    if(externalFieldsMapping.containsKey(fieldSetMemberObj.getFieldPath())&& externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c != 'LastModifiedById' && externalFieldsMapping.containsKey(fieldSetMemberObj.getFieldPath()) && responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c)!= null){
                        if(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).Data_Type__c == 'Date'){
                            System.debug('responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c)'+responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c));
                            if(responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c)!=null){
                                sObj.put(fieldSetMemberObj.getFieldPath(),Date.valueOf((String)responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c)));
                            }
                        }else if(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).Data_Type__c != 'Date'){
                            sObj.put(fieldSetMemberObj.getFieldPath(),responseAttributes.get(externalFieldsMapping.get(fieldSetMemberObj.getFieldPath()).External_Field_API__c));
                            
                        }
                    }
                }
                System.debug('sObjsObj===>'+ sObj);
                objectResultList.add(sObj);
            } 
        }
        return objectResultList;
    }
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields(); 
    } 
    public class responseWrapper{
        public String id;
    }
    public class loggerWrapper{
        public Id logID;
        public String nextRecordsUrl;
        public List<sObject> sObjectList = new List<sObject>();
    }
    public class responseObjWrapper{
        public Integer totalSize;
        public String nextRecordsUrl;
        public  List<sObject> records = new List<sObject>();
    }
    public class responseReturnWrapper{
        public Integer totalSize;
        public String nextRecordsUrl;
        public List<sObject> sObjectList = new List<sObject>();
    }
}