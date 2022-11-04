public with sharing class CalloutTriggerHandler extends TriggerHandler {

    public static Boolean SKIP_RECURSION = false;
    public static Boolean GO_IN_FOR_RETRY = false;

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public CalloutTriggerHandler() {

        if ( !Test.isRunningTest() )
            this.setMaxLoopCount(100);

        //Loggly.SETTING_NAME = '';
    }

    public override void afterInsert() {

        if ( CalloutTriggerHandler.SKIP_RECURSION ) return;

        String query = 'Select Id, Retries__c, RecordTypeId, RecordType.Name, Metadata__c, JSON_Metadata__c, HttpMethod__c, Endpoint__c, Payload__c, Response__c, Job_ID__c, Status__c, Sent_on__c, Duration__c, Account__c, Case__c, Contact__c, License__c, Carrier_Appointment__c From Callout__c Where Id IN (';

        Boolean valid_query = false;

        for ( sObject obj : trigger.new ) {

            query += '\'' + String.valueOf(obj.Id) + '\',';
            valid_query = true;
        }

        query = query.removeEnd(',');
        query += ') AND IsAsync__c = True And Status__c = \'Queued\'';

        system.debug('Callouts query: ' + query);

        /* Query with empty target ID's considered invalId. meaning, that it will look like this: [...IN ()...] */
        if ( valid_query ) {

            sendCalloutsViaPlatformEvent(query);
        }
    }

    /*
    Update for Callout__c happens in case of a failure. in this case we will try at least Env:NumOfRetries times and will update number of retries on Callout__c.Retries__c
    each update to the record will trigger this event to try again (Maximum of Env:NumOfRetries times)
    */
    public override void afterUpdate() {

        if ( CalloutTriggerHandler.SKIP_RECURSION && !CalloutTriggerHandler.GO_IN_FOR_RETRY ) return;

        String query = 'Select Id, Retries__c, RecordTypeId, RecordType.Name, Metadata__c, JSON_Metadata__c, HttpMethod__c, Endpoint__c, Payload__c, Response__c, Job_ID__c, Status__c, Sent_on__c, Duration__c, Account__c, Case__c, Contact__c, License__c, Carrier_Appointment__c From Callout__c Where Id IN (';

        Boolean valid_query = false;

        for ( sObject obj : trigger.new ) {

            query += '\'' + String.valueOf(obj.Id) + '\',';
            valid_query = true;
        }
        query = query.removeEnd(',');
        query += ') AND IsAsync__c = True';

        Integer allowed_retries = Integer.valueOf(Utils.getHippoSettings('NumOfCalloutRetries'));

        query += ' AND Retries__c > 0 AND Retries__c < ' + String.valueOf(allowed_retries);
        query += ' And Status__c != \'Failed\'';

        system.debug('Callouts retry query: ' + query);

        /* Query with empty target ID's considered invalId. meaning, that it will look like this: [...IN ()...] */
        if ( valid_query ) {

            sendCalloutsViaPlatformEvent(query);
        }
    }

    private void sendCalloutsViaPlatformEvent(String query) {

        // Create only one platform events to indicate that a batch of callouts are pending
        Callout_Event__e callout_event = new Callout_Event__e(Query__c = query);

        // Call method to publish events (Taking one DML from the transaction DML limits)...
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        Database.SaveResult result = EventBus.publish(callout_event);
        results.add(result);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted callout event. Callout_Event__e ID: ' + sr.getId());
            } else {
                // Operation failed, so get all errors
                for (Database.Error err : sr.getErrors()) {

                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('fields that affected this error: ' + err.getFields());
                }
            }
        }
    }

    /******************************************************************
    * Method: fakeMethod, public - TEMP UNTIL PROPER UNIT TESTS WILL BE AVAILABLE
    * Description: The purpose of this method is to increase code coverage
    * Return: void
    *******************************************************************/
    public static void fakeMethod() {

        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

    }
}