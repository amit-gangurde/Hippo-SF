public with sharing class HippoAPIController {
    @AuraEnabled
    public static Map<String, Object> createQuoteAPI(String leadId, String userId) {
        Map<String, Object> result;
        Lead leadRecord = [
                        SELECT Id, Organization__c, Street, City, Country, State, PostalCode, FirstName, MiddleName, LastName, Date_of_Birth__c, Phone, Email, Industry, Occupation__c, Education__c, Line_of_Business__c, Preferred_Deductibles__c, Effective_Date__c, RecordTypeId, QuoteId__c
                        FROM Lead 
                        WHERE Id =: leadId
                        LIMIT 1
                        ];
        User userRecord = [
                        SELECT Id, Email, Authorized_States__c 
                        FROM User 
                        WHERE Id =: userId
                        LIMIT 1
                        ];

        List<APIIntegrationSetting__mdt> apiIntSettingList = [SELECT Endpoint__c, Method__c, ContentType__c FROM APIIntegrationSetting__mdt WHERE DeveloperName =:'CreateQuote' LIMIT 1];

        if (apiIntSettingList!=null && !apiIntSettingList.isEmpty()) {
            String leadBody = createJSONBody(leadRecord, userRecord);
            HttpResponse response = HippoAPICallout.makePOSTCallout(apiIntSettingList[0], leadBody);
            if(response.getStatusCode() != 201 && response.getStatusCode() != 401) {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody());
                result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                //System.debug('result: ' + result);
                String message = (String) result.get('message');
                List<Object> details = (List<Object>) result.get('details');
                //System.debug('message => ' + message);
                //System.debug('details => ' + details);
                throw new AuraHandledException('Status Code: ' + response.getStatusCode() + ' ' + response.getStatus() + ', Message: ' + message + ', Details: ' + details);
            } else if (response.getStatusCode() != 201) {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody());
                throw new AuraHandledException('Status Code: ' + response.getStatusCode() + ' ' + response.getStatus());
            }
            
            else {
                //System.debug('Status Code: ' + response.getStatusCode() + ', Status:  ' + response.getStatus() + ', Body: ' + response.getBody()) ;
                result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                //System.debug(result);
                String quoteId = (String) result.get('quoteId');
                //System.debug(quoteId);
                updateCurrentLead(leadRecord, quoteId);
            }
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> retrieveQuoteAPI(String quoteId, String recordTypeId, String userId, String organizationId) {
        Map<String, Object> result;
        User userRecord = [
                        SELECT Id, Authorized_States__c 
                        FROM User 
                        WHERE Id =: userId
                        LIMIT 1
                        ];
        if (String.isBlank(userRecord.Authorized_States__c)) {
            throw new AuraHandledException('Missing "Authorized States" on User');
        }
        List<APIIntegrationSetting__mdt> apiIntSettingList = [SELECT Endpoint__c, Method__c, ContentType__c FROM APIIntegrationSetting__mdt WHERE DeveloperName =:'RetrieveQuoteURL' LIMIT 1];
        if (apiIntSettingList.size() > 0) {
            String authStates = userRecord.Authorized_States__c.replace(';', ',');
            //System.debug('authStates => ' + authStates);
            String url = '?quoteId=' + quoteId + '&market=' + authStates + '&leadRecordTypeId=' + recordTypeId + '&accountOrganizationId=' + organizationId;
            //System.debug('url => ' + url);
            HttpResponse response = HippoAPICallout.makeGETCallout(apiIntSettingList[0], url);
            // Parse the JSON response
            if(response.getStatusCode() != 200 && response.getStatusCode() != 401) {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody());
                result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                //System.debug('result: ' + result);
                String message = (String) result.get('message');
                List<Object> details = (List<Object>) result.get('details');
                //System.debug('message => ' + message);
                //System.debug('details => ' + details);
                throw new AuraHandledException('Status Code: ' + response.getStatusCode() + ' ' + response.getStatus() + ', Message: ' + message + ', Details: ' + details);
                //throw new AuraHandledException('Status Code: ' + response.getStatusCode() + ' ' + response.getStatus());
            } else if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody());
                throw new AuraHandledException('Status Code: ' + response.getStatusCode() + ' ' + response.getStatus());
            } else {
                //System.debug('Status Code: ' + response.getStatusCode() + ', Status:  ' + response.getStatus() + ', Body: ' + response.getBody()) ;
                result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            }   
        }
        return result;
    }

    public static void updateCurrentLead(Lead leadToUpdate, String quoteId) {
        leadToUpdate.QuoteId__c = quoteId;
        update leadToUpdate;
    }

    public static String createJSONBody(Lead leadRecord, User userRecord) {
        Map<String, Object> personInfo = new Map<String, Object>();
        personInfo.put('firstName', leadRecord.firstName);
        personInfo.put('lastName', leadRecord.LastName);
        personInfo.put('phone', leadRecord.Phone);
        personInfo.put('email', leadRecord.Email);

        if (String.isNotBlank(leadRecord.MiddleName)) {
            personInfo.put('middleName', leadRecord.MiddleName);
        }
        if (leadRecord.Date_of_Birth__c != null) {
            personInfo.put('dateOfBirth', leadRecord.Date_of_Birth__c);
        }
        if (String.isNotBlank(leadRecord.Industry)) {
            personInfo.put('industry', leadRecord.Industry);
        }
        if (String.isNotBlank(leadRecord.Occupation__c)) {
            personInfo.put('occupation', leadRecord.Occupation__c);
        }
        if (String.isNotBlank(leadRecord.Education__c)) {
            personInfo.put('education', leadRecord.Education__c);
        }

        Map<String, Object> address = new Map<String, Object>();
        address.put('street', leadRecord.Street);
        address.put('city', leadRecord.City);
        address.put('state', leadRecord.State);
        address.put('zip', leadRecord.PostalCode);

        Map<String, Object> bodyReq = new Map<String, Object>();
        bodyReq.put('personalInformation', personInfo);
        bodyReq.put('address', address);
        bodyReq.put('leadId', leadRecord.Id);
        bodyReq.put('leadRecordTypeId', leadRecord.RecordTypeId);
        bodyReq.put('accountOrganizationId', leadRecord.Organization__c);
        bodyReq.put('agentEmail', userRecord.Email);
        bodyReq.put('market', userRecord.Authorized_States__c);

        if (String.isNotBlank(leadRecord.Line_of_Business__c)) {
            bodyReq.put('coverageType', leadRecord.Line_of_Business__c);
        }
        if (leadRecord.Preferred_Deductibles__c != null) {
            bodyReq.put('preferredDeductibles', leadRecord.Preferred_Deductibles__c);
        }
        if (leadRecord.Effective_Date__c != null) {
            bodyReq.put('effectiveDate', leadRecord.Effective_Date__c);
        }

        String JSONBody = JSON.serializePretty(bodyReq);
        return JSONBody;
    }
}