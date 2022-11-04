public with sharing class ReorderOminChannelLeadsScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {

        ID jobID_1 = System.enqueueJob(new ReorderOminChannelLeadsQueue(new List<Id>()));
        System.debug('Kick off ReorderOminChannelLeadsQueue, jobId is: ' + jobID_1);

        if ( FeatureFlags.instance.ff_Timezone_Routing || Test.isRunningTest() ) {

            Id jobID_2 = System.enqueueJob(new RoutePendingLeadsToOmniChannel());
            System.debug('Kick off RoutePendingLeadsToOmniChannel, jobId is: ' + jobID_2);
        }
    }
}