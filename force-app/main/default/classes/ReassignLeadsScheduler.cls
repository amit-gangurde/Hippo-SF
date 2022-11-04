global class ReassignLeadsScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        ReassignLeads.reassignToQueue();
    }
}