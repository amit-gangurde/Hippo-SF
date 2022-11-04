public class SalesTerminateController {
@AuraEnabled
public static String checkAlreadyTerminated(Id recordId){
    if(recordId != null){
        Contact conOBJ = [SELECT ID,Sync_to_AgentSync__c,Blocked__c,Hidden__c,Producer_Status__c FROM Contact WHERE ID =: recordId LIMIT 1];
        if(conOBJ.Sync_to_AgentSync__c == 'Yes' || conOBJ.Blocked__c == false || conOBJ.Hidden__c == false || conOBJ.Producer_Status__c != 'Terminated'){
            return 'false';
        }
        return 'true';
    }
    return 'true';
}
@AuraEnabled
public static void terminateTheAgent(Id recordId){
    try{
    if(recordId != null){
        Contact con = new Contact();
        con.Id = recordId;
        con.Blocked__c = true;
        con.Hidden__c = true;
        con.PodRoleAdmin__c = false;
        con.PodRoleMasterAgent__c = false;
        con.PodRolePrincipal__c = false;
        con.Producer_Status__c = 'Terminated';
        con.Sync_to_AgentSync__c = 'No';
        update con;
    } 
    }catch(Exception ex){
        throw new AuraHandledException(ex.getMessage());
    } 
}
}