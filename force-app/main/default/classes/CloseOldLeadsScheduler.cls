public with sharing class CloseOldLeadsScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {

        CloseOldLeads b = new CloseOldLeads();
        ID jobID = database.executeBatch(b);
    }
}