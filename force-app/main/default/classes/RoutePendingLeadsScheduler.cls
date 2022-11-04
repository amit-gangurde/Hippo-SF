public with sharing class RoutePendingLeadsScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {

        //RoutePendingLeadsToOmniChannel.route();
        Id jobId = System.enqueueJob(new RoutePendingLeadsToOmniChannel());
        System.debug('Kick off RoutePendingLeadsToOmniChannel, jobId is: ' + jobId);
    }
}