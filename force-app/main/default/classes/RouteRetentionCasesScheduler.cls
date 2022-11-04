public with sharing class RouteRetentionCasesScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {

        RouteRetentionCases.route();
    }
}