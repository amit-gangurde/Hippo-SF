trigger CalloutEventTrigger on Callout_Event__e (after insert) {

    Set<String> queries = new Set<String>();

    for (Callout_Event__e event : Trigger.New) {

        System.debug('Query: ' + event.Query__c);

        if ( String.isNotBlank(event.Query__c) )
            queries.add(event.Query__c);
    }

    for ( String query : queries ) { // COMEBACK!!! SOQL IN A LOOP

        List<Callout__c> platform_event_callouts = Database.query(query);

        if ( platform_event_callouts.size() > 0 ) {

            system.debug('preparing to handle ' + platform_event_callouts.size() + ' Platform Event Callout__c records:' + platform_event_callouts);
            HippoChangeDataEventsCallouts hppCalloutsQueueable = new HippoChangeDataEventsCallouts(platform_event_callouts);
            ID jobID = System.enqueueJob(hppCalloutsQueueable);
        }
    }
}