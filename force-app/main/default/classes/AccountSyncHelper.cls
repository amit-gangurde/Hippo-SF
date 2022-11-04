/*****************************************************************************************************
* Name           : AccountSyncHelper
* Test Class     : AgentSyncTest
* Author         : Convene-Tech
* Purpose        : The main purpose of this class helps to sync the New/Updated Accounts to agent sync
* CreatedDate    : 2/16/2021
* LastModifiedBy : 5/09/2022
* ***************************************************************************************************/
public class AccountSyncHelper {
    public static String SUCCESS_MSG = 'Sync Initiated';
    public static String ERROR_MSG = 'Error: ';
    public static Map<String,String> externalFieldsMapping;
    public static Map<String,String> NPNmap;
    public static Id accountBusinessRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
    public static Id contactBusinessRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business').getRecordTypeId();
    static{
        
        NPNmap = new Map<String,String>();
        //********************** Getting Dummy NPN List *******************************//
        for(Dummy_NPN_List__mdt npn:[SELECT ID,NPN__c FROM Dummy_NPN_List__mdt]){
            NPNmap.put(npn.NPN__c,npn.NPN__c);
        }
        
        
    }
    
    public static String getAccount(List<Account> accountList,Map<Id,Account> accountOldMap){
        ConstantClass.CLASSNAME = 'AccountSyncHelper';
        ConstantClass.METHODNAME = 'getAccount';
        try{
            externalFieldsMapping = new Map<String,String>();
            //******* Custom meta data for dynamic field mapping for sync *******************************//
            for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: ConstantClass.ACCOUNT_OBJECT]){
                externalFieldsMapping.put(sync.Internal_Field_API__c, sync.External_Field_API__c);
            }
            //******* Dynamic endpoint to identify the Account creation and updation URL ***************//
            Data_Sync__mdt syncAccUPSERTAPI = [SELECT DeveloperName,End_Point__c,Method__c FROM Data_Sync__mdt WHERE DeveloperName =: ConstantClass.ACCOUNT_UPSERT_DATASYNC];
            
            Set<Id> accountIDSet = new Set<Id>();
            Map<Id,Account> accountMap = new Map<Id,Account>();
            Map<Id,String> accountExtIDMap = new Map<Id,String>();
            Map<Id,boolean> notValidNPNMap = new Map<Id,boolean>();
            
            //**************** Identify Dummy NPN with help of custom metadata *****************************//
            System.debug('externalFieldsMapping=='+externalFieldsMapping); 
            for(Account acc: accountList){
                if(acc.recordTypeId == accountBusinessRecTypeId && acc.Sync_to_AgentSync__c == ConstantClass.YES_VALUE && String.isNotblank(acc.NPN__c) && !NPNmap.containsKey(acc.NPN__c)){
                    for(String s:externalFieldsMapping.keySet()){
                        if((acc != null && acc.get(s) != null && accountOldMap!=null && accountOldMap.containsKey(acc.Id) && acc.get(s) != accountOldMap.get(acc.Id).get(s)) || (accountOldMap==null) ){
                            accountIDSet.add(acc.Id);
                        }
                    }
                }
            }
            System.debug('accountIDSet=='+accountIDSet);
            if(!accountIDSet.isEmpty()){
                List<Account> accOBJ = makeAccountQuery(accountIDSet);
                List<Schema.FieldSetMember> fieldSetMemberList = AccountSync.readFieldSet(ConstantClass.ACCOUNT_FIELDSET,ConstantClass.ACCOUNT_OBJECT);
                if(accOBJ!=null && !accOBJ.isEMpty()){
                    for(Account acc: accOBJ){
                        Id accIDkey = acc.Id;
                        accountExtIDMap.put(accIDkey,  acc.NPN__c);
                        acc.Id = null;
                        acc.Hippo_CRM_Identifier__c = accIDkey;
                        acc.NPN__c = null;
                        accountMap.put(accIDkey,acc);
                        
                    }
                }
                if(!accountMap.isEmpty()){
                    for(Id accIdKey: accountMap.keySet()){
                        // if(accountMap.containsKey(accIdKey)){
                        String accountExtID = accountExtIDMap.containsKey(accIdKey)?accountExtIDMap.get(accIdKey):'';
                        String sObj = JSON.serialize(accountMap.get(accIdKey),True);
                        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){ 
                            sObj = sObj.replace(',"'+ConstantClass.ACCOUNT_ID+'":'+ConstantClass.NULL_VALUE+'', ''); 
                            sObj = sObj.replace(',"'+ConstantClass.ACCOUNT_NPN+'":'+ConstantClass.NULL_VALUE+'', ''); 
                            //sObj = sObj.replace(',"'+ConstantClass.ACCOUNT_HIPPOCRMIDENTIFIER+'":'+ConstantClass.NULL_VALUE+'', ',"'+ConstantClass.ACCOUNT_HIPPOCRMIDENTIFIER+'":"'+accIdKey+'"');
                            if(externalFieldsMapping.containsKey(fieldSetMemberObj.getFieldPath())){
                                if(fieldSetMemberObj.getFieldPath() != ConstantClass.ACCOUNT_ID && fieldSetMemberObj.getFieldPath() !=ConstantClass.ACCOUNT_HIPPOCRMIDENTIFIER && fieldSetMemberObj.getFieldPath() !=ConstantClass.ACCOUNT_NPN ){
                                    sObj = sObj.replace('"'+fieldSetMemberObj.getFieldPath()+'"', '"'+externalFieldsMapping.get(fieldSetMemberObj.getFieldPath())+'"');
                                }
                            }
                        }
                        if(String.isNotBlank(accountExtID)){
                            accountSyncHelper( sObj,accIdKey,accountExtID,syncAccUPSERTAPI.Method__c,syncAccUPSERTAPI.End_Point__c+accountExtID,ConstantClass.ACCOUNT_OBJECT);
                        }
                        //}
                    } 
                }
                return SUCCESS_MSG;
            }
            return null;
        }catch(Exception ex){
            System.debug('Error:'+ex.getMessage());
            System.debug('Error Line:'+ex.getLineNumber());
            IntegrationErrorLogger.createErrorLog(ConstantClass.CLASSNAME, ConstantClass.METHODNAME, ex, ConstantClass.ERROR,null, ConstantClass.ERRORTYPE_DML,String.valueOf(ex.getMessage()),ConstantClass.ERROR,null);
            return ERROR_MSG +ex.getMessage();
        }
    }
    public static List<Account> makeAccountQuery(Set<Id> AccountId){
        if(!AccountId.isEmpty()){
            List<Schema.FieldSetMember> fieldSetMemberList = AccountSync.readFieldSet(ConstantClass.ACCOUNT_FIELDSET,ConstantClass.ACCOUNT_OBJECT);
            String Query = 'SELECT ';
            for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
                if(fieldSetMemberObj.getFieldPath() != ConstantClass.ACCOUNT_SYNCTOAGENTSYNC){
                    Query += fieldSetMemberObj.getFieldPath()+',';
                    system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()); //api name
                } 
            }
            Query = Query.removeEnd(',');
            Query += ' FROM Account WHERE ID IN: AccountId';
            return Database.query(Query);
        }
        return null;
    }
    public static String getContact(List<Contact> contactList,Map<Id,Contact> contactOldMap){
        ConstantClass.CLASSNAME = 'AccountSyncHelper';
        ConstantClass.METHODNAME = 'getContact';
        try{
            externalFieldsMapping = new Map<String,String>();
            //******* Custom meta data for dynamic field mapping for sync *******************************//
            for(Sync_Field_Mapping__mdt sync: [SELECT External_Field_API__c,Internal_Field_API__c FROM Sync_Field_Mapping__mdt WHERE Object__c =: ConstantClass.CONTACT_OBJECT]){
                externalFieldsMapping.put(sync.Internal_Field_API__c, sync.External_Field_API__c);
            }
            //******* Dynamic endpoint to identify the Contact creation and updation URL ***************//
            Data_Sync__mdt syncContactUPSERTAPI = [SELECT DeveloperName,End_Point__c,Method__c FROM Data_Sync__mdt WHERE DeveloperName =: ConstantClass.CONTACT_UPSERT_DATASYNC];
            
            List<Schema.FieldSetMember> fieldSetMemberList = AccountSync.readFieldSet(ConstantClass.CONTACT_FIELDSET,ConstantClass.CONTACT_OBJECT);
            Map<Id,Contact> conMap = new   Map<Id,Contact>();                 
            Map<Id,String> contactExtIDMap = new Map<Id,String>();
            Set<Id> contactIDSet = new Set<Id>();
            
            //*********************** Identify Dummy NPN Contatcs *************************************************//
            
            for(Contact con: contactList){
                if(con.recordTypeId == contactBusinessRecTypeId && con.Sync_to_AgentSync__c == ConstantClass.YES_VALUE && String.isNotblank(con.National_Producer_Number__c) && !NPNmap.containsKey(con.National_Producer_Number__c)){
                    for(String s:externalFieldsMapping.keySet()){
                        if((con !=null && contactOldMap != null && con.get(s)!=null && contactOldMap.containsKey(con.id) && con.get(s) != contactOldMap.get(con.Id).get(s)) || (contactOldMap == null) ){
                            contactIDSet.add(con.Id);
                        }
                    }
                }
            }
            System.debug('contactIDSet '+contactIDSet);
            if(!contactIDSet.isEmpty()){
                List<Contact> conOBJ = makeContactQuery(contactIDSet);
                if(conOBJ!=null && !conOBJ.isEmpty()){
                    for(Contact con: conOBJ){
                        Id conID = con.Id;
                        contactExtIDMap.put(conID,con.National_Producer_Number__c);
                        con.Id = null;
                        con.Hippo_CRM_Identifier__c = conID;
                        con.AccountId = con.External_AccountID__c;
                        con.National_Producer_Number__c = null;
                        conMap.put(conID,con);
                        
                    }
                    System.debug('conMap '+conMap);
                    for(Id conIdKey: conMap.keySet()){
                        //   if(conMap.containsKey(conIdKey)){
                        String contactExtID = contactExtIDMap.containsKey(conIdKey)?contactExtIDMap.get(conIdKey):''; 
                        String sObj = JSON.serialize(conMap.get(conIdKey),True);
                        sObj = sObj.replace(',"'+ConstantClass.CONTACT_ID+'":'+ConstantClass.NULL_VALUE+'', ''); 
                        sObj = sObj.replace(',"'+ConstantClass.CONTACT_NPN+'":'+ConstantClass.NULL_VALUE+'', ''); 
                        //sObj = sObj.replace(',"'+ConstantClass.CONTACT_HIPPOCRMIDENTIFIER+'":'+ConstantClass.NULL_VALUE+'', ',"'+ConstantClass.CONTACT_HIPPOCRMIDENTIFIER+'":"'+conIdKey+'"');
                        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){ 
                            if(fieldSetMemberObj.getFieldPath() != ConstantClass.CONTACT_ID && fieldSetMemberObj.getFieldPath() !=ConstantClass.CONTACT_HIPPOCRMIDENTIFIER && fieldSetMemberObj.getFieldPath() !=ConstantClass.CONTACT_NPN ){
                                sObj = sObj.replace('"'+fieldSetMemberObj.getFieldPath()+'"', '"'+externalFieldsMapping.get(fieldSetMemberObj.getFieldPath())+'"');
                            }
                        }
                        sObj = sObj.replace(',"'+ConstantClass.NULL_VALUE+'":"'+conMap.get(conIdKey).AccountId+'"', '');
                        if(String.isNotBlank(contactExtID)){
                            accountSyncHelper(sObj,conIdKey,contactExtID,syncContactUPSERTAPI.Method__c,syncContactUPSERTAPI.End_Point__c+contactExtID,ConstantClass.CONTACT_OBJECT);
                        }
                        // }
                    }
                }
                return SUCCESS_MSG;
            }
            return null;
        }catch(Exception ex){
            System.debug('EX: '+ex.getMessage());
            System.debug('EX: '+ex.getLineNumber());
            IntegrationErrorLogger.createErrorLog(ConstantClass.CLASSNAME, ConstantClass.METHODNAME, ex, ConstantClass.ERROR,null, ConstantClass.ERRORTYPE_DML,String.valueOf(ex.getMessage()),ConstantClass.ERROR,null);
            return ERROR_MSG +ex.getMessage();
        }
    }
    public static List<Contact> makeContactQuery(Set<Id> contactID){
        if(!contactID.isEmpty()){
            List<Schema.FieldSetMember> fieldSetMemberList = AccountSync.readFieldSet(ConstantClass.CONTACT_FIELDSET,ConstantClass.CONTACT_OBJECT);
            String Query = 'SELECT ';
            for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
                if(fieldSetMemberObj.getFieldPath() != ConstantClass.CONTACT_SYNCTOAGENTSYNC){
                    Query += fieldSetMemberObj.getFieldPath()+',';
                    system.debug('API Name ====>' + fieldSetMemberObj.getFieldPath()); //api name
                }
            }
            Query = Query.removeEnd(',');
            Query += ' FROM Contact WHERE ID IN: contactID';
            
            System.debug('Query==='+Query);
            return Database.query(Query);
        }
        return null;
    }
    @future(callout=true)
    public static void accountSyncHelper(String JSONData,Id objectID,String ExternalID,String method,String endPoint,String objectName){
        ConstantClass.CLASSNAME = 'AccountSyncHelper';
        ConstantClass.METHODNAME = 'accountSyncHelper';
        integer i = 0,result = 0;
        AccountSync.loggerWrapper accountUpdates = AccountSync.accountSyncHelper( JSONData, objectID, ExternalID, method, endPoint, objectName,DateTime.now(),DateTime.now());
        if(accountUpdates!=null && accountUpdates.sObjectList!=null){
            List<Database.UpsertResult> results = Database.upsert(accountUpdates.sObjectList, false);
            result = accountUpdates.sObjectList.size();
            for(Database.UpsertResult res: results){
                if(!res.isSuccess()){
                    i++;
                    IntegrationErrorLogger.createErrorLog(ConstantClass.CLASSNAME, ConstantClass.METHODNAME, null, ConstantClass.ERROR, res.Id, ConstantClass.ERRORTYPE_DML,String.valueOf(res.errors),ConstantClass.ERROR,String.valueOf(res));
                } 
            }
            if(!String.isBlank(accountUpdates.logID)){ 
                Integration_Log__c log = new Integration_Log__c();
                log.Id = accountUpdates.logID;
                log.Success_Records_Count__c =result-i;
                log.Failure_Records_Count__c = i;
                update log;
            }
        }
    }
}