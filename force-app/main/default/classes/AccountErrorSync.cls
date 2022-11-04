public class AccountErrorSync {
     @AuraEnabled
   public static String reSyncHandler(Id recordId){
        List<Account> accountIDList = new List<Account>();
        if(recordId!=null){
           accountIDList = [SELECT ID,Name FROM Account WHERE ID =: RecordID];
           return AccountSyncHelper.getAccount(accountIDList,null);
        }
        return null;
    }
}