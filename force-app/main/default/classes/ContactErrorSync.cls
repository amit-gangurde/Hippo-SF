public class ContactErrorSync {
     @AuraEnabled
    public static String reSyncHandler(Id recordId){
         List<Contact> contactIDList = new List<Contact>();
        if(recordId!=null){
           contactIDList = [SELECT ID FROM Contact WHERE ID =: RecordID];
           return AccountSyncHelper.getContact(contactIDList,null);
        }
        return null;
    }
}