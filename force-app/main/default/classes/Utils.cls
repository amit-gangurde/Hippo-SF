public without sharing class Utils {
    
    public class HippoUserInfo {
        
        @AuraEnabled public String user_id;
        @AuraEnabled public String profile_name;
        
        public HippoUserInfo() {
            
            this.user_id = UserInfo.getUserId();
            this.profile_name = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        }
    }
    
    private static Map<String, Schema.SObjectType> GlobalDescribeMap = null;
    private static Map<String, Map<String, Schema.RecordTypeInfo>> RecordTypeInfoMap = null;
    private static Map<String, StateInfo> States2StateInfo = null;
    private static Map<String, Utils.LeadMapping> LeadQueuesMap = null;
    private static Map<String, Utils.LeadMapping> LeadQueuesMapByUTMSource = null;
    private static Map<Integer, Boolean> ToggledOffLeadScores = null;
    private static Map<String, Boolean> UWDeclinationReasonsWithRouting = null;
    
    private static EmailServicesAddress esa = null;
    private static OrgWideEmailAddress owa = null;
    private static EmailTemplate et_FNOL_Claim_Submission = null;
    
    private static Map<String, Id> map_State2TerritoryManagerOwnerId = null;
    
    private static BusinessHours bh_EST = null;
    private static BusinessHours bh_PST = null;
    
    private static HippoUserInfo hippoUserInfo = null;
    
    public class ClaimWrapper implements Comparable {
        
        public Claim clm { get; set; }
        
        public ClaimWrapper(Claim clm) {
            
            this.clm = clm;
        }
        
        public Integer compareTo(Object compareTo) {
            
            // Cast argument to ClaimWrapper
            ClaimWrapper compareToClaim = (ClaimWrapper)compareTo;
            
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            
            if (clm.CreatedDate > compareToClaim.clm.CreatedDate) {
                
                // Set return value to a positive value.
                returnValue = 1;
                
            } else if (clm.CreatedDate < compareToClaim.clm.CreatedDate) {
                
                // Set return value to a negative value.
                returnValue = -1;
            }
            
            return returnValue;
        }
    }
    
    /*
    Method: createOrderedClaims
    Description: Get list of ordered claims (via ClaimWrapper)
    Return: List<Utils.ClaimWrapper>
    */
    public static List<Utils.ClaimWrapper> createOrderedClaims(List<Claim> lstClaims) {
        
        List<Utils.ClaimWrapper> lstClaimWrappers = new List<Utils.ClaimWrapper>();
        
        if ( lstClaims != null ) {
            
            for (Claim clm : lstClaims) {
                
                lstClaimWrappers.add(new ClaimWrapper(clm));
            }
            
            lstClaimWrappers.sort();
        }
        
        return lstClaimWrappers;
    }
    
    public class ClaimCatEventWrapper implements Comparable {
        
        public Claim_Cat_Event__c cce { get; set; }
        
        public ClaimCatEventWrapper(Claim_Cat_Event__c cce) {
            
            this.cce = cce;
        }
        
        public Integer compareTo(Object compareTo) {
            
            // Cast argument to ClaimCatEventWrapper
            ClaimCatEventWrapper compareToClaimCatEvent = (ClaimCatEventWrapper)compareTo;
            
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            
            if (cce.CreatedDate > compareToClaimCatEvent.cce.CreatedDate) {
                
                // Set return value to a positive value.
                returnValue = 1;
                
            } else if (cce.CreatedDate < compareToClaimCatEvent.cce.CreatedDate) {
                
                // Set return value to a negative value.
                returnValue = -1;
            }
            
            return returnValue;
        }
    }
    
    /*
    Method: createOrderedClaimCatEvents
    Description: Get list of ordered claim cat events (via ClaimCatEventWrapper)
    Return: List<Utils.ClaimCatEventWrapper>
    */
    public static List<Utils.ClaimCatEventWrapper> createOrderedClaimCatEvents(List<Claim_Cat_Event__c> lstClaimCatEvents) {
        
        List<Utils.ClaimCatEventWrapper> lstClaimCatEventWrappers = new List<Utils.ClaimCatEventWrapper>();
        
        if ( lstClaimCatEvents != null ) {
            
            for (Claim_Cat_Event__c cce : lstClaimCatEvents) {
                
                lstClaimCatEventWrappers.add(new ClaimCatEventWrapper(cce));
            }
            
            lstClaimCatEventWrappers.sort();
        }
        
        return lstClaimCatEventWrappers;
    }
    
    
    /*
    Method: valueOfClaimCatEventWrappers
    Description: Get list of ordered claim cat events (via Claim_Cat_Event__c)
    Return: List<Claim_Cat_Event__c>
    */
    public static List<Claim_Cat_Event__c> valueOfClaimCatEventWrappers(List<Utils.ClaimCatEventWrapper> lstClaimCatEventWrappers) {
        
        List<Claim_Cat_Event__c> lstClaimCatEvents = new List<Claim_Cat_Event__c>();
        
        if ( lstClaimCatEventWrappers != null ) {
            
            for (Utils.ClaimCatEventWrapper cCatEventWrapper : lstClaimCatEventWrappers) {
                
                lstClaimCatEvents.add(cCatEventWrapper.cce);
            }
        }
        
        return lstClaimCatEvents;
    }
    
    /*
    Method: getFieldNamesForSObjectName
    Description: Get list of fields for sObject passed by Name
    Return: List<String>
    */
    public static List<String> getFieldNamesForSObjectName(String sObjectName) {
        
        if (null == GlobalDescribeMap)
            GlobalDescribeMap = Schema.getGlobalDescribe();
        
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(sObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        if (null != DescribeSObjectResultObj)
            return getFieldNamesForSObject(DescribeSObjectResultObj);
        
        return new List<String>();
    }
    
    /*
    Method: getFieldNamesForSObject
    Description: Get list of fields for sObject passed by DescribeSObjectResult
    Return: List<String>
    */
    private static List<String> getFieldNamesForSObject(DescribeSObjectResult sObjectResult) {
        
        List<String> fields = new List<String>();
        
        for (Schema.SobjectField field : sObjectResult.fields.getMap().values()) {
            
            DescribeFieldResult fieldResult = field.getDescribe();
            if (!fieldResult.isDeprecatedAndHidden()
                && fieldResult.getType() != Schema.DisplayType.base64) {
                    fields.add(fieldResult.getName());
                }
        }
        
        return fields;
    }
    
    /*
    Method: getChildRelationsForSObject
    Description: Get map of relationships for sObject passed by Name
    Return: Map<String, DescribeSObjectResult>
    */
    private static Map<String, DescribeSObjectResult> getChildRelationsForSObject(String sObjectName) {
        
        if (null == GlobalDescribeMap)
            GlobalDescribeMap = Schema.getGlobalDescribe();
        
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(sObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        Map<String, DescribeSObjectResult> children = new Map<String, DescribeSObjectResult>();
        
        for (ChildRelationship child : DescribeSObjectResultObj.childRelationships) {
            
            if (!child.isDeprecatedAndHidden()
                && child.getRelationshipName() != null
                && child.getRelationshipName() != 'ChildAccounts'
                && child.getRelationshipName() != sObjectName) {
                    children.put(child.getRelationshipName(), child.getChildSObject().getDescribe());
                }
        }
        return children;
    }
    
    /*
    Method: buildJoinStringsForSObject
    Description: Get join strings for sObject with it's fields and relationships for dynamic SOQL
    Return: List<String>
    */
    public static List<String> buildJoinStringsForSObject(String sObjectName) {
        
        Map<String, DescribeSObjectResult> childFields = getChildRelationsForSObject('Account');
        List<String> joinStrings = new List<String>();
        
        for (String relationName : childFields.keySet()) {
            String fields = String.join(getFieldNamesForSObject(childFields.get(relationName)), ', ');
            String joinString = '(SELECT ' + fields + ' FROM ' + relationName + ')';
            joinStrings.add(joinString);
        }
        
        return joinStrings;
    }
    
    /*
    Method: readFieldSet
    Description: Get list of field set member by field set name and sObject name
    Return: List<Schema.FieldSetMember>
    */
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName) {
        
        if (null == GlobalDescribeMap)
            GlobalDescribeMap = Schema.getGlobalDescribe();
        
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        
        return fieldSetObj.getFields();
    }
    
    public static Boolean getBooleanFieldValue(String ObjectName, Id recId, String FieldName) {
        
        Boolean result = false;
        List<String> fields = new List<String>{
            FieldName
                };
                    if (null != recId) {
                        String soql = 'select ' + String.join(fields, ', ') + ' from ' + ObjectName + ' where Id = :recId';
                        SObject sob = Database.query(soql);
                        result = (Boolean) sob.get(FieldName);
                    }
        system.debug('getBooleanFieldValue result == ' + result);
        return result;
    }
    
    /*
    Method: getRecordTypeInfo
    Description: Get record type info by reocrd type id and sObject name
    Return: RecordTypeInfo
    */
    public static RecordTypeInfo getRecordTypeInfo(Id recordTypeId, String ObjectName) {
        
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SobjectType = :ObjectName AND Id = :recordTypeId];
        
        if (null == GlobalDescribeMap)
            GlobalDescribeMap = Schema.getGlobalDescribe();
        
        if (rt != null && GlobalDescribeMap != null && !GlobalDescribeMap.isEmpty()) {
            
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
            Schema.DescribeSObjectResult d = SObjectTypeObj.getDescribe();
            Map<Id, Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();
            Schema.RecordTypeInfo rtById = rtMapById.get(rt.id);
            Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtByName = rtMapByName.get(rt.name);
            
            return rtByName;
        }
        
        return null;
    }
    
    /*
    Method: getRecordTypesByName
    Description: Get map of record type info by Id based on the sObject name
    Return: Map<Id, Schema.RecordTypeInfo>
    */
    public static Map<Id, Schema.RecordTypeInfo> getRecordTypes(String ObjectName) {
        
        Map<Id, Schema.RecordTypeInfo> rtMapById = null;
        
        RecordType[] rt = [SELECT Id, Name, Description, DeveloperName, IsActive FROM RecordType WHERE SobjectType = :ObjectName And IsActive = TRUE];
        
        if (null == GlobalDescribeMap)
            GlobalDescribeMap = Schema.getGlobalDescribe();
        
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult d = SObjectTypeObj.getDescribe();
        rtMapById = d.getRecordTypeInfosById();
        
        return rtMapById;
    }
    
    /*
    Method: getRecordTypeInfo
    Description: Get record type info by reocrd type name and sObject name
    Return: RecordTypeInfo
    */
    public static RecordTypeInfo getRecordTypeInfo(String recordTypeName, String ObjectName) {
        
        if (RecordTypeInfoMap == null) {
            
            RecordTypeInfoMap = new Map<String, Map<String, Schema.RecordTypeInfo>>();
        }
        
        if (RecordTypeInfoMap.containsKey(ObjectName)) {
            
            Map<String, Schema.RecordTypeInfo> rtInfoMap = RecordTypeInfoMap.get(ObjectName);
            
            if (rtInfoMap.containsKey(recordTypeName)) {
                
                return rtInfoMap.get(recordTypeName);
            } else {
                
                RecordTypeInfo rtInfo = getRecordTypeInfoHelper(recordTypeName, ObjectName);
                rtInfoMap.put(recordTypeName, rtInfo);
                return rtInfo;
            }
        } else {
            
            RecordTypeInfo rtInfo = getRecordTypeInfoHelper(recordTypeName, ObjectName);
            Map<String, Schema.RecordTypeInfo> rtInfoMap = new Map<String, Schema.RecordTypeInfo>();
            rtInfoMap.put(recordTypeName, rtInfo);
            RecordTypeInfoMap.put(ObjectName, rtInfoMap);
            return rtInfo;
        }
    }
    
    /*
    Method: getRecordTypeInfoHelper
    Description: Get record type info by reocrd type name and sObject name
    Return: RecordTypeInfo
    */
    private static RecordTypeInfo getRecordTypeInfoHelper(String recordTypeName, String ObjectName) {
        
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE SobjectType = :ObjectName AND Name = :recordTypeName];
        
        if (null == GlobalDescribeMap)
            GlobalDescribeMap = Schema.getGlobalDescribe();
        
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult d = SObjectTypeObj.getDescribe();
        Map<Id, Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();
        Schema.RecordTypeInfo rtById = rtMapById.get(rt.id);
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtByName = rtMapByName.get(rt.name);
        
        return rtByName;
    }
    
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix) {
        
        String objectName = '';
        
        try {
            
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0, 3);
            
            //Get schema information
            if (null == GlobalDescribeMap)
                GlobalDescribeMap = Schema.getGlobalDescribe();
            
            Map<String, Schema.SObjectType> gd = GlobalDescribeMap;
            
            //Loop through all the sObject types returned by Schema
            for (Schema.SObjectType stype : gd.values()) {
                
                //if (!sObj.contains('__')) to exclude managed package objects
                
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                System.debug('Prefix is ' + prefix);
                
                //Check if the prefix matches with requested prefix
                if (prefix != null && prefix.equals(myIdPrefix)) {
                    
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
            
        } catch (Exception e) {
            
            System.debug(e);
        }
        
        return objectName;
    }
    
    public static String getRandomString(Integer len) {
        
        Integer length = len;
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        String pwd = key.substring(0, length);
        return pwd;
    }
    
    /*
    public static void sendEmail(Set<Id> listOfCases, List<String> toAddresses) {

    List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
    List<EmailMessage> allEmailMsg  = new List<EmailMessage>();

    Map<Id, Case> map_CaseId2Case = new Map<Id, Case>([Select Id, Policy_Number__c, Severity_of_Loss__c, Effective_Date__c, Contact.Name, Client_Contact_Phone__c, Client_Email_Address__c, Property_Address__c, Date_of_Loss__c, Peril__c, Home_Habitable__c, Addl_Living_Exp_Req__c, Adjuster__c From Case Where Id IN: listOfCases]);

    if ( null == et_FNOL_Claim_Submission ) {

    et_FNOL_Claim_Submission = [Select Id, Subject, HtmlValue, Body from EmailTemplate where Name = '[Name of 3rd party] FNOL Claim Submission'];
    }

    Contact con = [Select id from Contact limit 1]; // dummy contact just to make whatId to work with templateId

    if ( null == esa ) {

    esa = [SELECT EmailDomainName, IsActive, LocalPart FROM EmailServicesAddress limit 1];
    }

    if ( null == owa ) {

    owa = [select id, DisplayName, Address from OrgWideEmailAddress limit 1];
    }

    for ( Id case_id : listOfCases ) {

    system.debug('Case id == ' + case_id);

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setTemplateId(et_FNOL_Claim_Submission.id);
    mail.setWhatId(case_id); //Cannot be used with setTargetObjectId for User
    mail.setReplyTo(esa.LocalPart + '@' + esa.EmailDomainName);
    mail.setToAddresses(toAddresses);
    mail.setSenderDisplayName('The Hippo Claim Adjuster Team'); // will not work with setOrgWideEmailAddressId
    mail.setTargetObjectId(con.Id);
    mail.setTreatTargetObjectAsRecipient(false); // make sure email will not be sent to user
    //mail.setOrgWideEmailAddressId(owa.id); // will not work with setSenderDisplayName
    mail.setUseSignature(false);
    mail.setBccSender(false);
    mail.setSaveAsActivity(false);

    system.debug('Messaging.SingleEmailMessage to send == ' + mail);
    allmsg.add(mail);

    EmailMessage emailMsg = buildEmailMessage(map_CaseId2Case.get(case_id), et_FNOL_Claim_Submission, mail.getReplyTo(), toAddresses);
    system.debug('EmailMessage to save == ' + emailMsg);
    if (null != emailMsg) allEmailMsg.add(emailMsg);
    }

    if(!Test.isRunningTest())
    Messaging.SendEmailResult [] r = Messaging.sendEmail(allmsg, false);

    if (allEmailMsg.size() > 0) insert allEmailMsg;

    }
    */
    
    /*
    private static EmailMessage buildEmailMessage(Case my_Case, EmailTemplate et, String fromAddress, List<String> toAddresses) {

    EmailMessage emailMsg = new EmailMessage();

    system.debug('Case: ' + my_Case);

    emailMsg.FromAddress = fromAddress;
    emailMsg.ToAddress = toAddresses[0];

    String subject = et.subject;
    subject = subject.replace('{!Case.Policy_Number__c}', my_Case.Policy_Number__c != null ? my_Case.Policy_Number__c : '');
    subject = subject.replace('{!Case.Peril__c}', my_Case.Peril__c != null ? my_Case.Peril__c : '');
    subject = subject.replace('{!Case.Severity_of_Loss__c}', my_Case.Severity_of_Loss__c != null ? my_Case.Severity_of_Loss__c : '');
    emailMsg.Subject = subject;

    String textBody = et.body;
    textBody = textBody.replace('{!Case.Policy_Number__c}', my_Case.Policy_Number__c != null ? my_Case.Policy_Number__c : '');
    textBody = textBody.replace('{!Case.Effective_Date__c}', my_Case.Effective_Date__c != null ? String.valueOf(my_Case.Effective_Date__c) : '');
    textBody = textBody.replace('{!Case.Contact}', my_Case.Contact.Name != null ? my_Case.Contact.Name : '');
    textBody = textBody.replace('{!Case.Client_Contact_Phone__c}', my_Case.Client_Contact_Phone__c != null ? my_Case.Client_Contact_Phone__c : '');
    textBody = textBody.replace('{!Case.Client_Email_Address__c}', my_Case.Client_Email_Address__c != null ? my_Case.Client_Email_Address__c : '');
    textBody = textBody.replace('{!Case.Property_Address__c}', my_Case.Property_Address__c != null ? my_Case.Property_Address__c : '');
    textBody = textBody.replace('{!Case.Date_of_Loss__c}', my_Case.Date_of_Loss__c != null ? String.valueOf(my_Case.Date_of_Loss__c) : '');
    textBody = textBody.replace('{!Case.Peril__c}', my_Case.Peril__c != null ? my_Case.Peril__c : '');
    textBody = textBody.replace('{!Case.Severity_of_Loss__c}', my_Case.Severity_of_Loss__c != null ? my_Case.Severity_of_Loss__c : '');
    textBody = textBody.replace('{!Case.Home_Habitable__c}', String.valueOf(my_Case.Home_Habitable__c));
    textBody = textBody.replace('{!Case.Addl_Living_Exp_Req__c}', String.valueOf(my_Case.Addl_Living_Exp_Req__c));
    if ( String.isNotBlank(my_Case.Adjuster__c) ) textBody = textBody.replace('{!Case.Adjuster__c}', my_Case.Adjuster__c);
    emailMsg.TextBody = textBody;

    //emailMsg.HtmlBody = et.HtmlBody;

    emailMsg.ParentId = my_Case.Id;
    emailMsg.MessageDate = system.now();
    emailMsg.Status = '3'; // 'Sent

    return emailMsg;
    }
    */
    
    public static Map<String, Group> queues {
        
        get {
            
            if (queues == null) {
                
                queues = new Map<String, Group>();
                List<Group> groups = [Select Id, Name, DeveloperName, Type From Group Where Type = 'Queue'];
                for (Group g : groups) {
                    queues.put(g.DeveloperName, g);
                }
                
            }
            
            return queues;
        }
        private set;
    }
    
    public static Id getQueueId(String queue_dev_name) {
        
        Id queue_id = queues?.get(queue_dev_name)?.Id;
        
        return queue_id;
        
        /*
        List<Group> groups = [Select Id, Name, DeveloperName From Group Where DeveloperName = :queue_dev_name Limit 1];

        if (groups.size() > 0) return groups[0].Id;

        return null;
        */
    }
    
    public class LeadScoreItem {
        
        @AuraEnabled public Integer score;
        
        public LeadScoreItem(Integer score) {
            this.score = score;
        }
    }
    
    /*
    Method: getToggledOffLeadScores
    Description: Get lead scores that were toggled off by admin(s)
    Return: Map<String, Boolean> (Lead score --> TRUE) --- value is always TRUE, meaning, if lead is in the map then TRUE that it is toggled off
    */
    public static Map<String, Boolean> getToggledOffLeadScores() {
        
        Map<String, Boolean> map_toggledOffLeadScores = new Map<String, Boolean>();
        
        Lead_Score__mdt[] leadScores = [SELECT MasterLabel, QualifiedApiName, Checked__c, Additional_Text__c FROM Lead_Score__mdt ORDER BY MasterLabel ASC];
        
        for (Lead_Score__mdt leadScore : leadScores) {
            
            if ( !leadScore.Checked__c ) {
                
                map_toggledOffLeadScores.put(leadScore.MasterLabel, true);
            }
        }
        
        return map_toggledOffLeadScores;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Lead_Score__mdt> getLeadScores() {
        
        Lead_Score__mdt[] leadScores = [SELECT MasterLabel, QualifiedApiName, Checked__c, Additional_Text__c FROM Lead_Score__mdt ORDER BY MasterLabel ASC];
        
        Map<Integer, Lead_Score__mdt> map_sortedLeadScoresByIntegers = new Map<Integer, Lead_Score__mdt>();
        for (Lead_Score__mdt leadScore : leadScores) {
            map_sortedLeadScoresByIntegers.put(Integer.valueOf(leadScore.MasterLabel), leadScore);
        }
        
        List<Lead_Score__mdt> sortedLeadScores = new List<Lead_Score__mdt>();
        Integer i = 1; // minimum lead score
        while (map_sortedLeadScoresByIntegers.containsKey(i)) {
            sortedLeadScores.add(map_sortedLeadScoresByIntegers.get(i++));
        }
        
        System.debug('sortedLeadScores :' + sortedLeadScores);
        
        /*
        List<LeadScoreItem> res = new List<LeadScoreItem>();

        String max_lead_score = Utils.getHippoSettings('MAX_LEAD_SCORE');

        // for (Integer i = Integer.valueOf(max_lead_score); i >= 1; i--) {
        for (Integer i = 1; i <= Integer.valueOf(max_lead_score); i++) {
        res.add(new LeadScoreItem(i));
        }

        System.debug('LeadScoreItems :' + res);

        return res;
        */
        
        return sortedLeadScores;
    }
    
    public static String getHippoSettings(String key) {
        
        Hippo_Settings__c hsProperty = Hippo_Settings__c.getValues(key);
        
        if (null != hsProperty) {
            
            return hsProperty.Value__c;
        }
        
        return null;
    }
    
    public static Boolean isSandboxInstance() {
        
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
    
    public class StateInfo {
        
        public String coast;
        public Boolean has_uw_referral;
        
        public StateInfo() {
            
            this.coast = '';
            this.has_uw_referral = false;
        }
        
        public StateInfo(String coast, Boolean has_uw_referral) {
            
            this.coast = coast;
            this.has_uw_referral = has_uw_referral;
        }
    }
    
    public static Map<String, StateInfo> getStates2StateInfo() {
        
        if (null == States2StateInfo) {
            
            States2StateInfo = new Map<String, StateInfo>();
            Zip_Codes__mdt[] zipCodes = [SELECT MasterLabel, QualifiedApiName, State__c, Coast__c, HAS_UW_Referral__c FROM Zip_Codes__mdt];
            for (Zip_Codes__mdt zipCode : zipCodes) {
                
                States2StateInfo.put(zipCode.State__c, new StateInfo(zipCode.Coast__c, zipCode.HAS_UW_Referral__c));
            }
        }
        
        return States2StateInfo;
    }
    
    public class LeadMapping {
        
        public LeadMapping(String queue_dev_name, String utm_source, Boolean lead_score_required, String recordtype_developername) {
            
            this.queue_dev_name = queue_dev_name;
            this.utm_source = utm_source;
            this.lead_score_required = lead_score_required;
            this.recordtype_developername = recordtype_developername;
            this.organization = '';
        }
        
        public LeadMapping(String queue_dev_name, String utm_source, Boolean lead_score_required, String recordtype_developername, String organization) {
            
            this.queue_dev_name = queue_dev_name;
            this.utm_source = utm_source;
            this.lead_score_required = lead_score_required;
            this.recordtype_developername = recordtype_developername;
            this.organization = organization;
        }
        
        public String queue_dev_name { get; set; }
        public String utm_source { get; set; }
        public Boolean lead_score_required { get; set; }
        public String recordtype_developername { get; set; }
        public String organization { get; set; }
    }
    
    public static Map<String, Utils.LeadMapping> getLeadQueuesMapping() {
        
        if (null == LeadQueuesMap) {
            
            LeadQueuesMap = new Map<String, Utils.LeadMapping>();
            LeadQueuesMapByUTMSource = new Map<String, Utils.LeadMapping>();
            
            Lead_Queue_Mapping__mdt[] leadQueues = [SELECT MasterLabel, Queue_Dev_Name__c, UTM_Source__c, Lead_Score_Required__c, Longer_Label__c, RecordType_DeveloperName__c FROM Lead_Queue_Mapping__mdt];
            for (Lead_Queue_Mapping__mdt leadQueue : leadQueues) {
                
                if ( String.isNotBlank(leadQueue.Longer_Label__c) ) {
                    
                    LeadQueuesMap.put(leadQueue.Longer_Label__c.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c));
                    
                    if ( String.isNotBlank(leadQueue.UTM_Source__c) ) {
                        
                        LeadQueuesMapByUTMSource.put(leadQueue.UTM_Source__c.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c, leadQueue.Longer_Label__c.toLowerCase()));
                    }
                }
                else {
                    
                    LeadQueuesMap.put(leadQueue.MasterLabel.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c));
                    
                    if ( String.isNotBlank(leadQueue.UTM_Source__c) ) {
                        
                        LeadQueuesMapByUTMSource.put(leadQueue.UTM_Source__c.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c, leadQueue.MasterLabel.toLowerCase()));
                    }
                }
            }
            
            if (Test.isRunningTest()) { // Take care for custom metadata for SFDC-451 tests
                
                LeadQueuesMap.put('sfdc-451-paid', new Utils.LeadMapping('High_Urgency_Queue', 'TEST UTM SOURCE', false, ''));
            }
        }
        
        return LeadQueuesMap;
    }
    
    public static Map<String, Utils.LeadMapping> getLeadQueuesMappingByUTMSource() {
        
        if (null == LeadQueuesMapByUTMSource) {
            
            LeadQueuesMap = new Map<String, Utils.LeadMapping>();
            LeadQueuesMapByUTMSource = new Map<String, Utils.LeadMapping>();
            
            Lead_Queue_Mapping__mdt[] leadQueues = [SELECT MasterLabel, Queue_Dev_Name__c, UTM_Source__c, Lead_Score_Required__c, Longer_Label__c, RecordType_DeveloperName__c FROM Lead_Queue_Mapping__mdt];
            for (Lead_Queue_Mapping__mdt leadQueue : leadQueues) {
                
                if ( String.isNotBlank(leadQueue.Longer_Label__c) ) {
                    
                    LeadQueuesMap.put(leadQueue.Longer_Label__c.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c));
                    
                    if ( String.isNotBlank(leadQueue.UTM_Source__c) ) {
                        
                        LeadQueuesMapByUTMSource.put(leadQueue.UTM_Source__c.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c, leadQueue.Longer_Label__c.toLowerCase()));
                    }
                }
                else {
                    
                    LeadQueuesMap.put(leadQueue.MasterLabel.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c));
                    
                    if ( String.isNotBlank(leadQueue.UTM_Source__c) ) {
                        
                        LeadQueuesMapByUTMSource.put(leadQueue.UTM_Source__c.toLowerCase(), new Utils.LeadMapping(leadQueue.Queue_Dev_Name__c, leadQueue.UTM_Source__c, leadQueue.Lead_Score_Required__c, leadQueue.RecordType_DeveloperName__c, leadQueue.MasterLabel.toLowerCase()));
                    }
                }
            }
            
            if (Test.isRunningTest()) { // Take care for custom metadata for SFDC-451 tests
                
                LeadQueuesMap.put('sfdc-451-paid', new Utils.LeadMapping('High_Urgency_Queue', 'TEST UTM SOURCE', false, ''));
            }
        }
        
        return LeadQueuesMapByUTMSource;
    }
    
    public static void debugSaveResults(Database.SaveResult[] results) {
        
        for (Integer i = 0; i < results.size(); i++) {
            
            if (results[i].isSuccess()) {
                
                System.debug('Successfully created ID: ' + results[i].getId());
                
            } else {
                
                System.debug('Error: could not create sobject ' + 'for array element ' + i + '.');
                
                System.debug('   The error reported was: ' + results[i].getErrors()[0].getMessage() + '\n');
            }
        }
    }
    
    public static String getMadSkyClaimPayload(Case claim) {
        
        Map<String, String> create_payload = new Map<String, String>();
        
        create_payload.put('Claim_Number__c', claim.CaseNumber); //claim.Id
        //create_payload.put('Hippo_Claim_Object_ID__c', claim.xxx);
        if(claim.Date_of_Loss__c!=null){
            create_payload.put('Date_of_Loss__c', String.valueOf(claim.Date_of_Loss__c));
        }
        create_payload.put('Description__c', claim.Loss_Description__c);
        create_payload.put('Policyholder_Email__c', claim.Client_Email_Address__c);
        if(claim.AccountId !=null){
            create_payload.put('Policyholder_Name__c', claim.Account.Name); //Client_Name__c
        }
        create_payload.put('Policyholder_Phone__c', claim.Client_Contact_Phone__c);
        create_payload.put('Policyholder_Mobile__c', claim.Client_Secondary_Phone__c);
        create_payload.put('Policyholder_Address__c', claim.Street__c);
        create_payload.put('Policyholder_City__c', claim.City__c);
        create_payload.put('Policyholder_Country__c', 'United States');
        if(claim.Insurance_Policy__c!=null){
            create_payload.put('Policyholder_State__c', claim.Insurance_Policy__r.State__c);
            create_payload.put('Claim_State__c', claim.Insurance_Policy__r.State__c);
        }
        create_payload.put('Policyholder_Zip_Code__c', claim.Zip__c);
        create_payload.put('Preferred_Contact__c', claim.Preferred_Contact_Method__c);
        create_payload.put('Claim_Street__c', claim.Street__c);
        create_payload.put('Claim_City__c', claim.City__c);
        create_payload.put('Claim_PostalCode__c', claim.Zip__c);
        
        create_payload.put('Homeowner_Critical_Notes__c', claim.Claims_Notes__c);
        create_payload.put('Peril__c', claim.Peril__c);
        //create_payload.put('Policy_Inception_Date__c', claim.xxx);\
        if(claim.Wind_Hail_Deductible__c!=null){
            create_payload.put('Deductible_Verified__c', String.valueOf(claim.Wind_Hail_Deductible__c)); //Insurance_Policy__r.Deductible__c
        }
        //create_payload.put('CAT_Code__c', claim.xxx);
        //create_payload.put('Referral_Type__c', claim.xxx);
        if(claim.Claims_Adjuster__c!=null){
            create_payload.put('Adjuster_Name__c', claim.Claims_Adjuster__r.Name);
            create_payload.put('Adjuster_Email__c', claim.Claims_Adjuster__r.Email);
        }
        //create_payload.put('Adjuster_Phone__c', claim.Claims_Adjuster__r.Phone);
        
        return JSON.serialize(create_payload);
    }
    
    public static Map<String, Id> getTerritoryManagersByState() {
        
        if (null == map_State2TerritoryManagerOwnerId)
            map_State2TerritoryManagerOwnerId = new Map<String, Id>(); else
                return map_State2TerritoryManagerOwnerId;
        
        try {
            
            List<User_Assignment__c> lst_UserAssignments = [SELECT Id, Name, User__c, State__c, Territory_Manager__c FROM User_Assignment__c Where Territory_Manager__c = TRUE];
            
            for (User_Assignment__c ua : lst_UserAssignments) {
                
                if (String.isNotBlank(ua.State__c) && ua.Territory_Manager__c) {
                    
                    List<String> states = new List<String>();
                    states = ua.State__c.split(';');
                    
                    for (String state : states) {
                        
                        if (!map_State2TerritoryManagerOwnerId.containsKey(state.toUpperCase())) {
                            
                            map_State2TerritoryManagerOwnerId.put(state.toUpperCase(), ua.User__c);
                        }
                    }
                }
            }
        } catch (Exception e) {
            
            System.debug(e);
        }
        
        return map_State2TerritoryManagerOwnerId;
    }
    
    public static Boolean isWithinEST(Datetime dt) {
        
        System.debug('isWithinEST, dt: ' + dt);
        
        if (null == bh_EST) bh_EST = [SELECT Id FROM BusinessHours WHERE Name = 'EST'];
        
        System.debug('isWithinEST, bh_EST: ' + bh_EST);
        
        System.debug('isWithinEST, BusinessHours.isWithin(bh_EST.id, dt): ' + BusinessHours.isWithin(bh_EST.id, dt));
        
        if (null != bh_EST) return BusinessHours.isWithin(bh_EST.id, dt);
        
        return false;
    }
    
    public static Boolean isWithinPST(Datetime dt) {
        
        System.debug('isWithinPST, dt: ' + dt);
        
        if (null == bh_PST) bh_PST = [SELECT Id FROM BusinessHours WHERE Name = 'PST'];
        
        System.debug('isWithinPST, bh_PST: ' + bh_PST);
        
        System.debug('isWithinPST, BusinessHours.isWithin(bh_PST.id, dt): ' + BusinessHours.isWithin(bh_PST.id, dt));
        
        if (null != bh_PST) return BusinessHours.isWithin(bh_PST.id, dt);
        
        return false;
    }
    
    public static List<UserServicePresence > getAvailableOmniChannelAgents() {
        
        return [SELECT Id, Name, CreatedDate, LastModifiedDate, UserId, StatusStartDate, ConfiguredCapacity, StatusEndDate, IsAway, IsCurrentState, AverageCapacity FROM UserServicePresence WHERE IsCurrentState = True AND LastModifiedDate = TODAY];
    }
    
    public static void sendVisualforceBasedEmail2TriggerContext(String visualforce_et_name, Map<Id, Id> map_relatedToByTriggerContext2ContactId, String owaFromAddressDisplayName) {
        
        if ( !Trigger.isExecuting ) return;
        
        try {
            
            Map<Id, Claim> claims_in_context = new Map<Id, Claim>([SELECT Id, Claim_Adjuster__c, Claim_Adjuster__r.Name, AccountId, Account.Name, Account.PersonContactId FROM Claim WHERE Id IN:trigger.newMap.keySet()]);
            
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            
            EmailTemplate et = [SELECT Id, Name, DeveloperName from EmailTemplate where DeveloperName =: visualforce_et_name];
            system.debug('EmailTemplate == ' + et);
            
            List<OrgWideEmailAddress> owa = [SELECT Id, DisplayName, Address from OrgWideEmailAddress Where DisplayName =: owaFromAddressDisplayName limit 1];
            System.debug('OrgWideEmailAddress == ' + owa);
            
            for (Id relatedToId : map_relatedToByTriggerContext2ContactId.keySet()) {
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                //mail.setToAddresses(new List<String>{'liroy@012.net.il'});
                mail.setTargetObjectId(map_relatedToByTriggerContext2ContactId.get(relatedToId)); //Sample Test:0032100000v7LDCAA2,
                mail.setWhatId(relatedToId); //Cannot be used with setTargetObjectId for User
                if ( owa.size() == 1 ) {
                    
                    if ( visualforce_et_name.equalsIgnoreCase('ClaimAdjusterAssignment') ) {
                        
                        mail.setSenderDisplayName(claims_in_context.get(relatedToId).Claim_Adjuster__r.Name);
                        mail.setReplyTo(owa[0].Address);
                    }
                    else {
                        
                        mail.setOrgWideEmailAddressId(owa[0].id);
                    }
                }
                //mail.setSenderDisplayName('Hippo Insurance Claims Team'); Cannot be used with setOrgWideEmailAddressId
                mail.setUseSignature(false);
                mail.setBccSender(false);
                mail.setSaveAsActivity(false);
                mail.setTemplateId(et.id);
                mail.setSaveAsActivity(true);
                //mail.setEntityAttachments();
                
                system.debug('Email to send == ' + mail);
                
                allmsg.add(mail);
            }
            
            if ( allmsg.size() > 0 ) {
                
                Messaging.SendEmailResult [] r = Messaging.sendEmail(allmsg, false);
                
                system.debug('Messaging.sendEmail Results for Visualforce Email Template: ' + visualforce_et_name + ', --> ' + r);
            }
        }
        catch (Exception ex) {
            
            System.debug(ex);
        }
    }
    
    public static String getMadSkyClaimPayload(Claim claim) {
        
        Map<String, String> create_payload = new Map<String, String>();
        // TODO: check for ClaimParticipants
        create_payload.put('Claim_Number__c', claim.Name); //claim.Id
        create_payload.put('Date_of_Loss__c', String.valueOf(claim.Date_of_Loss__c));
        create_payload.put('Description__c', claim.Loss_Description__c);
        if ( claim.ClaimParticipants.size() > 0 ) {
            System.debug('adding ClaimParticipants to payload: ' + claim.ClaimParticipants);
            create_payload.put('Policyholder_Email__c', claim.ClaimParticipants[0].Email__c);
            create_payload.put('Policyholder_Name__c', claim.ClaimParticipants[0].First_Name__c + ' ' + claim.ClaimParticipants[0].Last_Name__c); //Client_Name__c
            create_payload.put('Policyholder_Phone__c', claim.ClaimParticipants[0].OfficePhone__c);
            create_payload.put('Policyholder_Mobile__c', claim.ClaimParticipants[0].MobilePhone__c);
            create_payload.put('Policyholder_Address__c', claim.ClaimParticipants[0].Street__c);
            create_payload.put('Policyholder_City__c', claim.ClaimParticipants[0].City__c);
            create_payload.put('Policyholder_State__c', claim.ClaimParticipants[0].State__c);
            create_payload.put('Policyholder_Zip_Code__c', claim.ClaimParticipants[0].Zip_Code__c);
        }
        create_payload.put('Policyholder_Country__c', 'United States');
        // TODO: Missing preferred contact method
        // create_payload.put('Preferred_Contact__c', claim.ClaimParticipants.Preferred_Contact_Method__c);
        if(claim.PolicyNumber!=null){ //**** Added NULL check for Validation "Claim Policy Number != NULL" ***//
            create_payload.put('Claim_Street__c', claim.PolicyNumber.Street__c);
            create_payload.put('Claim_State__c', claim.PolicyNumber.State__c);
            create_payload.put('Claim_City__c', claim.PolicyNumber.City__c);
            create_payload.put('Claim_PostalCode__c', claim.PolicyNumber.Zip__c);
        }
        
        create_payload.put('Homeowner_Critical_Notes__c', claim.Claims_Notes__c);
        create_payload.put('Peril__c', claim.Peril__c);
        create_payload.put('Deductible_Verified__c', String.valueOf(claim.Wind_Hail_Deductible__c));
        if(claim.Claim_Adjuster__c != null){ //**** Added NULL check for Validation "Claim Adjuster != NULL" ***//
            create_payload.put('Adjuster_Email__c', claim.Claim_Adjuster__r.Email);
            create_payload.put('Adjuster_Name__c', claim.Claim_Adjuster__r.Name);
            create_payload.put('Adjuster_Phone__c', claim.Claim_Adjuster__r.Phone);
        }
        return JSON.serialize(create_payload);
    }
    
    private static Map<String, String> StatesMap = new Map<String, String>{
        // list pulled from https://about.usps.com/who-we-are/postal-history/state-abbreviations.htm
        'ALABAMA' => 'AL',
            'AL.' => 'AL',
            'ALA.' => 'AL',
            'ALA' => 'AL',
            'ALASKA' => 'AK',
            'ALSK' => 'AK',
            'ARIZONA' => 'AZ',
            'ARIZ.' => 'AZ',
            'ARIZ' => 'AZ',
            'ARKANSAS' => 'AR',
            'AR. T.' => 'AR',
            'ARK.' => 'AR',
            'ARK' => 'AR',
            'CALIFORNIA' => 'CA',
            'CAL.' => 'CA',
            'CALIF.' => 'CA',
            'CALIF' => 'CA',
            'COLORADO' => 'CO',
            'COLO.' => 'CO',
            'COL' => 'CO',
            'CONNECTICUT' => 'CT',
            'CT.' => 'CT',
            'CONN.' => 'CT',
            'CONN' => 'CT',
            'COL' => 'CT',
            'DELAWARE' => 'DE',
            'DE.' => 'DE',
            'DEL.' => 'DE',
            'DEL' => 'DE',
            'DISTRICT OF COLUMBIA' => 'DC',
            'D. C.' => 'DC',
            'FLORIDA' => 'FL',
            'FL. T.' => 'FL',
            'FLA.' => 'FL',
            'FLA' => 'FL',
            'GEORGIA' => 'GA',
            'GA.' => 'GA',
            'HAWAII' => 'HI',
            'HAW' => 'HI',
            'IDAHO' => 'ID',
            'IDA' => 'ID',
            'ILLINOIS' => 'IL',
            'IL.' => 'IL',
            'ILL.' => 'IL',
            'ILL' => 'IL',
            'INDIANA' => 'IN',
            'IA.' => 'IN',
            'IND.' => 'IN',
            'IND' => 'IN',
            'IOWA' => 'IA',
            'KANSAS' => 'KS',
            'KANS.' => 'KS',
            'KANS' => 'KS',
            'KENTUCKY' => 'KY',
            'KY.' => 'KY',
            'LOUISIANA' => 'LA',
            'LA.' => 'LA',
            'MAINE' => 'ME',
            'ME.' => 'ME',
            'MARYLAND' => 'MD',
            'MD.' => 'MD',
            'MASSACHUSETTS' => 'MA',
            'MS.' => 'MA',
            'MASS.' => 'MA',
            'MASS' => 'MA',
            'MICHIGAN' => 'MI',
            'MIC. T.' => 'MI',
            'MICH.' => 'MI',
            'MICH' => 'MI',
            'MINNESOTA' => 'MN',
            'MINN.' => 'MN',
            'MINN' => 'MN',
            'MISSISSIPPI' => 'MS',
            'MI.' => 'MS',
            'MISS.' => 'MS',
            'MISS' => 'MS',
            'MISSOURI' => 'MO',
            'MO.' => 'MO',
            'MONTANA' => 'MT',
            'MONT.' => 'MT',
            'MONT' => 'MT',
            'NEBRASKA' => 'NE',
            'NEBR.' => 'NE',
            'NEB' => 'NE',
            'NB' => 'NE',
            'NEVADA' => 'NV',
            'NEV.' => 'NV',
            'NEV' => 'NV',
            'NEW HAMPSHIRE' => 'NH',
            'N. H.' => 'NH',
            'NEW JERSEY' => 'NJ',
            'N. J.' => 'NJ',
            'NEW MEXICO' => 'NM',
            'N. MEX.' => 'NM',
            'NEW YORK' => 'NY',
            'N. Y.' => 'NY',
            'NORTH CAROLINA' => 'NC',
            'N. C.' => 'NC',
            'NORTH DAKOTA' => 'ND',
            'N. DAK.' => 'ND',
            'OHIO' => 'OH',
            'O.' => 'OH',
            'OKLAHOMA' => 'OK',
            'OKLA.' => 'OK',
            'OKLA' => 'OK',
            'OREGON' => 'OR',
            'OREG.' => 'OR',
            'ORE' => 'OR',
            'PENNSYLVANIA' => 'PA',
            'PA.' => 'PA',
            'PUERTO RICO' => 'PR',
            'P. R.' => 'PR',
            'RHODE ISLAND' => 'RI',
            'R. I.' => 'RI',
            'SOUTH CAROLINA' => 'SC',
            'S. C.' => 'SC',
            'SOUTH DAKOTA' => 'SD',
            'S. DAK.' => 'SD',
            'TENNESSEE' => 'TN',
            'TE.' => 'TN',
            'TENN.' => 'TN',
            'TENN' => 'TN',
            'TEXAS' => 'TX',
            'TEX.' => 'TX',
            'TEX' => 'TX',
            'UTAH' => 'UT',
            'VERMONT' => 'VT',
            'VT.' => 'VT',
            'VIRGINIA' => 'VA',
            'VA.' => 'VA',
            'WASHINGTON' => 'WA',
            'WASH.' => 'WA',
            'WEST VIRGINIA' => 'WV',
            'W. VA.' => 'WV',
            'W VA' => 'WV',
            'WISCONSIN' => 'WI',
            'WIS.' => 'WI',
            'WIS' => 'WI',
            'WYOMING' => 'WY',
            'WYO.' => 'WY',
            'WYO' => 'WY'
            };
                
                public static String mapStateValue(String value) {
                    if (value == null) {
                        return value;
                    }
                    value = value.toUpperCase();
                    if (value.length() > 2 || value == 'NB' || value == 'O.') {
                        return StatesMap.get(value.toUpperCase());
                    }
                    return value;
                }
    
    //private static Map<Id, UserRole> userRoleMap = new Map<Id, UserRole>([SELECT FIELDS(STANDARD) FROM UserRole]);
    private static Map<Id, UserRole> userRoleMap = new Map<Id, UserRole>([SELECT Id, Name, ParentRoleId, RollupDescription, OpportunityAccessForAccountOwner, CaseAccessForAccountOwner, ContactAccessForAccountOwner, ForecastUserId, MayForecastManagerShare, LastModifiedDate, LastModifiedById, Systemmodstamp, DeveloperName, PortalAccountId, PortalType, PortalAccountOwnerId FROM UserRole]);
    public static Map<Id, List<UserRole>> hierarchy {
        
        get {
            
            hierarchy = new Map<Id, List<UserRole>>();
            for (UserRole role : userRoleMap.values()) {
                
                if (!hierarchy.containsKey(role.ParentRoleId)) {
                    
                    hierarchy.put(role.ParentRoleId, new List<UserRole>());
                }
                
                hierarchy.get(role.ParentRoleId).add(role);
            }
            return hierarchy;
        }
        private set;
    }
    
    public static List<UserRole> getChildren(Id userRoleId) {
        
        return hierarchy.containsKey(userRoleId) ? hierarchy.get(userRoleId) : new List<UserRole>();
    }
    
    public static Set<Id> getSubHierarchy(Id userRoleId) {
        
        Set<Id> roleIds = new Set<Id> { userRoleId };
            for (UserRole childRole : getChildren(userRoleId)) {
                
                roleIds.addAll(getSubHierarchy(childRole.Id));
            }
        
        return roleIds;
    }
    
    public static Set<Id> getParentRoles(Id userRoleId) {
        
        Set<Id> roleIds = new Set<Id>();
        UserRole currentRole = userRoleMap.get(userRoleId);
        while (currentRole.ParentRoleId != null) {
            
            roleIds.add(currentRole.ParentRoleId);
            currentRole = userRoleMap.get(currentRole.ParentRoleId);
        }
        
        return roleIds;
    }
    
    private static Map<Id,Set<Id>> getRoleIdToUsers(Map<Id,User> userMap) {
        
        Map<Id, Set<Id>> roleIdToUsers = new Map<Id,Set<Id>>();
        for (User u : userMap.values()) {
            
            if (u.UserRoleId != null ){
                
                if (!roleIdToUsers.containsKey(u.UserRoleId)) {
                    
                    roleIdToUsers.put(u.UserRoleId, new Set<Id>());
                }
                
                roleIdToUsers.get(u.UserRoleId).add(u.Id);
            }
        }
        
        return roleIdToUsers;
    }
    
    @TestVisible
    public static Map<String, Set<Id>> groupDeveloperNameAndTypeToActiveUserIds {
        
        get {
            
            if (groupDeveloperNameAndTypeToActiveUserIds == null) {
                
                groupDeveloperNameAndTypeToActiveUserIds = new  Map<String, Set<Id>>();
                
                //query for all relevant data
                Map<Id,Group> groupMap = new Map<Id,Group>([SELECT Id, DeveloperName, DoesIncludeBosses, Type, RelatedId, (SELECT UserOrGroupId FROM GroupMembers) FROM Group]);
                Map<Id,User> userMap = new Map<Id,User>([SELECT Id, IsActive, /*IsPortalEnabled,*/ UserRoleId FROM User WHERE IsActive = true]);
                Map<Id,Set<Id>> roleIdToUsers = getRoleIdToUsers(userMap);
                //calculate group users for each individual group
                for (Group g : groupMap.values()) {
                    
                    groupDeveloperNameAndTypeToActiveUserIds.put(g.DeveloperName + '-' + g.Type, getGroupUsers(g, groupMap, userMap, roleIdToUsers));
                }
                //add users above in the hierarchy (Currently disabled)
                /*
                for (Group g : groupMap.values()) {

                if (g.DoesIncludeBosses == true) {

                Set<Id> rolesForUsersInThisGroup = new Set<Id>();
                for (id userId : groupDeveloperNameAndTypeToActiveUserIds.get(g.DeveloperName + '-' + g.Type)) {

                User u = userMap.get(userId);
                if (u.UserRoleId != null) {

                rolesForUsersInThisGroup.add(u.UserRoleId);
                }
                }

                Set<Id> allParentRoles = new Set<Id>();
                for (Id roleId : rolesForUsersInThisGroup) {

                allParentRoles.addAll(getParentRoles(roleId));
                }

                for (Id parentRoleId : allParentRoles) {

                Set<Id> userIds = roleIdToUsers.get(parentRoleId);
                if (null != userIds)
                groupDeveloperNameAndTypeToActiveUserIds.get(g.DeveloperName + '-' + g.Type).addAll(userIds);
                }
                }
                }
                */
            }
            
            return groupDeveloperNameAndTypeToActiveUserIds;
        }
        private set;
    }
    
    
    private static Set<Id> getGroupUsers(Group g, Map<Id,Group> groupMap, Map<Id,User> userMap, Map<Id,Set<Id>> roleIdToUsers) {
        
        Set<Id> usersForThisGroup = new Set<Id>();
        switch on g.Type {
            
            when 'Organization' {
                
                for (User u : userMap.values()) {
                    
                    //if (!u.IsPortalEnabled) {
                    usersForThisGroup.add(u.id);
                    //}
                }
            }
            when 'Regular' {
                
                for (GroupMember gm : g.GroupMembers) {
                    
                    String sobjectType = gm.UserOrGroupId.getSObjectType().getDescribe().getName();
                    if (sobjectType == 'User') {
                        
                        if (userMap.containsKey(gm.UserOrGroupId)) {
                            
                            usersForThisGroup.add(gm.UserOrGroupId);
                        }
                    } else {
                        
                        //recurse down the group tree
                        usersForThisGroup.addAll(getGroupUsers(groupmap.get(gm.UserOrGroupId), groupMap, userMap, roleIdToUsers));
                    }
                }
            }
            when 'Queue' {
                
                for (GroupMember gm : g.GroupMembers) {
                    
                    String sobjectType = gm.UserOrGroupId.getSObjectType().getDescribe().getName();
                    if (sobjectType == 'User') {
                        
                        if (userMap.containsKey(gm.UserOrGroupId)) {
                            
                            usersForThisGroup.add(gm.UserOrGroupId);
                        }
                    } else {
                        
                        //recurse down the group tree
                        usersForThisGroup.addAll(getGroupUsers(groupmap.get(gm.UserOrGroupId), groupMap, userMap, roleIdToUsers));
                    }
                }
            }
            when 'AllCustomerPortal' {
                
                for (User u : userMap.values()) {
                    
                    //if (u.IsPortalEnabled) {
                    usersForThisGroup.add(u.id);
                    //}
                }
            }
            when 'Role' {
                
                if (roleIdToUsers.containsKey(g.RelatedId)) {
                    
                    usersForThisGroup.addAll(roleIdToUsers.get(g.RelatedId));
                }
            }
            when 'RoleAndSubordinates' {
                
                Set<Id> subordinateRoles = getSubHierarchy(g.RelatedId);
                for (Id roleId : subordinateRoles) {
                    
                    if (roleIdToUsers.keySet().contains(roleId)) {
                        
                        Set<Id> userIds = roleIdToUsers.get(g.RelatedId);
                        if (null != userIds)
                            usersForThisGroup.addAll(userIds);
                    }
                }
            }
            when 'RoleAndSubordinatesInternal' {
                
                Set<Id> subordinateRoles = getSubHierarchy(g.RelatedId);
                for (Id roleId : subordinateRoles) {
                    
                    if (roleIdToUsers.keySet().contains(roleId)) {
                        
                        for (Id userId : (roleIdToUsers.get(g.RelatedId))) {
                            
                            //if (!userMap.get(userId).IsPortalEnabled) {
                            usersForThisGroup.add(userId);
                            //}
                        }
                    }
                }
            }
        }
        
        return usersForThisGroup;
    }
    
    public static void sendBellNotification(Id targetId, String title, String body, Set<String> recipientsIds) {
        
        try {
            
            // Get the Id for our custom notification type
            CustomNotificationType notificationType = [SELECT Id, DeveloperName
                                                       FROM CustomNotificationType
                                                       WHERE DeveloperName='Bell_Notification'];
            
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            
            // Set the contents for the notification
            notification.setTitle(title);
            notification.setBody(body);
            
            // Set the notification type and target
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(targetId);
            
            System.debug('Sending the following custom notification: ' + notification);
            
            notification.send(recipientsIds);
        }
        catch (Exception ex) {
            
            System.debug('Exception from sendBellNotification execution: ' + ex.getMessage());
        }
    }
    
    /*
    Method: getLeadRenewedInterestTask
    Description: Get a task as required by lead deduplication rule 2 as described in SFDC-561
    Return: String
    */
    public static Task getLeadRenewedInterestTask(Lead new_lead, Lead original_lead, String description) {
        
        Task tsk = new Task();
        
        string tskRecId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('B2C Sales Task').getRecordTypeId();
        
        tsk.RecordTypeId = tskRecId;
        tsk.Subject = 'Renewed Interest';
        tsk.WhoId = new_lead.Id;
        tsk.Description = description;
        tsk.ActivityDate = new_lead.CreatedDate.date();
        tsk.Original_Lead__c = original_lead.Id;
        tsk.Status = 'Not Started';
        tsk.OwnerId = original_lead.OwnerId;
        
        return tsk;
    }
    
    /*
    Method: getLeadDupNotificationBody
    Description: Get the notification body for lead deduplication rule 2 as described in SFDC-561
    Return: String
    */
    public static String getLeadDupNotificationBody(Lead new_lead, Lead original_lead) {
        
        List<String> notification_body_dynamic_values = new List<String>{new_lead.Name, original_lead.Organization__r.Name};
            
            String body = String.format(Label.LEAD_DDUP_RULE2_BODY, notification_body_dynamic_values);
        
        return body;
    }
    
    public class LeadState {
        
        private DateTime validity;
        @AuraEnabled public Lead my_lead;
        @AuraEnabled public Boolean bIsWithinBusinessHours;
        @AuraEnabled public Id pendingQueueId; // either PST or EST
        
        public LeadState(Lead my_lead) {
            
            this.validity = System.now();
            this.my_lead = my_lead;
            this.bIsWithinBusinessHours = true;
            this.pendingQueueId = null;
        }
        
        public LeadState(Lead my_lead, Boolean isWithinBusinesHours, Id pendingQueueId) {
            
            this.validity = System.now();
            this.my_lead = my_lead;
            this.bIsWithinBusinessHours = isWithinBusinesHours;
            this.pendingQueueId = pendingQueueId;
        }
    }
    
    public static LeadState isLeadWithinBusinessHours(Lead my_lead) {
        
        LeadState leadState = new LeadState(my_lead);
        
        try {
            
            String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
            String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads PST Queue');
            Id estPendingLeadsQueue = Utils.getQueueId(est_pending_queue_dev_name);
            Id pstPendingLeadsQueue = Utils.getQueueId(pst_pending_queue_dev_name);
            
            Map<String, StateInfo> map_State2Coast = Utils.getStates2StateInfo();
            
            System.debug('map_State2Coast: ' + map_State2Coast);
            
            String state = my_lead.State?.toUpperCase();
            System.debug('state: ' + state);
            
            if (String.isNotBlank(state) && map_State2Coast.containsKey(state)) {
                
                if (map_State2Coast.get(state).coast.toLowerCase().equals('west')) {
                    
                    // Find whether the time is within the PST business hours
                    System.debug('isWithin PST Condition 1: ' + Utils.isWithinPST(system.now()));
                    System.debug('isWithin PST Condition 2: ' + QACockpit.instance.qacp_Force_Inside_Business_Hours_for_PST.enabled);
                    System.debug('isWithin PST Condition 3: ' + LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS);
                    Boolean isWithin = Utils.isWithinPST(system.now()) || QACockpit.instance.qacp_Force_Inside_Business_Hours_for_PST.enabled || LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS;
                    if (!isWithin || LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS || QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_PST.enabled) {
                        leadState.pendingQueueId = pstPendingLeadsQueue;
                        leadState.bIsWithinBusinessHours = false;
                    }
                } else if (map_State2Coast.get(state).coast.toLowerCase().equals('east')) {
                    
                    // Find whether the time is within the EST business hours
                    System.debug('isWithin EST Condition 1: ' + Utils.isWithinEST(system.now()));
                    System.debug('isWithin EST Condition 2: ' + QACockpit.instance.qacp_Force_Inside_Business_Hours_for_EST.enabled);
                    System.debug('isWithin EST Condition 3: ' + LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS);
                    Boolean isWithin = Utils.isWithinEST(system.now()) || QACockpit.instance.qacp_Force_Inside_Business_Hours_for_EST.enabled || LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS;
                    if (!isWithin || LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS || QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_EST.enabled) {
                        leadState.pendingQueueId = estPendingLeadsQueue;
                        leadState.bIsWithinBusinessHours = false;
                    }
                }
            }
            
        } catch (Exception ex) {
            
            System.debug('Exception from isLeadWithinBusinessHours execution: ' + ex.getMessage());
        }
        
        System.debug('leadState: ' + leadState);
        
        return leadState;
    }
    
    public static Boolean isCurrentUserAPI() {
        
        return /*UserInfo.getName().equalsIgnoreCase('Application User') ||*/ UserInfo.getName().equalsIgnoreCase('Infra Bot');
    }
    
    public static Boolean isRunningUser(String userName) {
        
        return UserInfo.getName().equalsIgnoreCase(userName);
    }
    
    public static Map<String, Boolean> getUWDeclinationReasonsWithRoutingInfo() {
        
        if (null == UWDeclinationReasonsWithRouting) {
            
            UWDeclinationReasonsWithRouting = new Map<String, Boolean>();
            Declination_Reason__mdt[] declinationReasons = [SELECT MasterLabel, QualifiedApiName, Declination_Reason__c, Route_To_HAS_UW_Declinations__c FROM Declination_Reason__mdt];
            for (Declination_Reason__mdt declinationReason : declinationReasons) {

                if ( String.isBlank(declinationReason.Declination_Reason__c) ) // if the declination reason is longer than 40 characters, it is saved in this field
                    UWDeclinationReasonsWithRouting.put(declinationReason.MasterLabel, declinationReason.Route_To_HAS_UW_Declinations__c);
                else
                    UWDeclinationReasonsWithRouting.put(declinationReason.Declination_Reason__c, declinationReason.Route_To_HAS_UW_Declinations__c);
            }
        }
        
        return UWDeclinationReasonsWithRouting;
    }
    
    public static Utils.HippoUserInfo getHippoUserInContext() {
        
        if ( hippoUserInfo == null || (hippoUserInfo != null && hippoUserInfo.user_id != UserInfo.getUserId()) ) {
            
            hippoUserInfo = new Utils.HippoUserInfo();
        }
        
        System.debug('hippoUserInfo: ' + hippoUserInfo);
        
        return hippoUserInfo;
    }
    
    public static Set<String> getLeadNonJVRecordTypes() {
        
        Set<String> nonJVRecordTypes = new Set<String>{'B2C_Sales', 'Web_Leads_Default', 'Web_Leads_Producers'};
            
            return nonJVRecordTypes;
    }

    /*
    Method: GetChangedFields
    Description: checks whether the updated record values are different from the previous
    Return: Set<String>
    */
    public static Set<String> GetChangedFields(SObject oldRecord, SObject newRecord) {

        Set<String> fields = new Set<String>();
        Set<String> systemFields = new Set<String>{'CreatedDate','LastModifiedById','LastModifiedDate','SystemModstamp', 'FinServ__ConversionDateTime__c'};

        for (String key : newRecord.getPopulatedFieldsAsMap().keySet()) {

            if (systemFields.contains(key)) continue;

            if (oldRecord.get(key) != newRecord.get(key)) {
                fields.add(key);
            }
        }

        return fields;
    }
}