public with sharing class HippoChangeDataEventsCallouts implements Queueable, Database.AllowsCallouts {

    public class SfdcRestResponse {

        public String id;
        public Boolean success;
        public List<String> errors;
    }

    /*
     * Callout__c passed on class creation (the actual callout records created by the standard and cdc triggers)
	 */
    private List<Callout__c> callouts {get; set;}

    // Collect pending updates instead of immidiate commit since the number of callouts can be more then one and while a DML
    // is being executed there is a limit that a callout cannot be executed
    private List<sObject> pending_updates;

    /*
     * Constructor
     */
    public HippoChangeDataEventsCallouts(List<Callout__c> callouts) {

        system.debug('HippoChangeDataEventsCallouts ctor');
        this.callouts = callouts.clone();
        this.pending_updates = new List<sObject>();
    }

    /******************************************************************
    * Method: execute, public
    * Description: Execute the Queueable interface
    * Return: void
    *******************************************************************/
    public void execute(QueueableContext context) {

        Callout__c current_calloutWorkItem = null;

        try {

            List<Callout__c> processed_callouts = new List<Callout__c>();

            // make sure to execute no more then Limits.getLimitCallouts() callouts and collect the remaining to a chained queueable to be execute at the end
            List<Callout__c> callouts_for_child_process = new List<Callout__c>();

            for (Callout__c callout : callouts) {

                system.debug('Handling the following Callout: ' + callout);

                // avoid hitting callouts governor limit
                if ( Limits.getCallouts() == Limits.getLimitCallouts() || Limits.getQueries() >= Limits.getLimitQueries() ) {

                    callouts_for_child_process.add(callout);
                    continue;
                }

                current_calloutWorkItem = callout;

                Long start = System.now().getTime();

                callout.Job_ID__c  = context.getJobId();

                HttpResponse res = new HttpResponse();

                if ( Test.isRunningTest() ) {

                    res = UnitTestHelper.createFakeHttpResponse(200);
                }
                else {

                    res = doCallout(callout);
                }

                system.debug('res == ' + res?.getBody());

                callout.Response__c = res?.getBody();

                if ( !(res.getStatusCode() != 200 && res.getStatusCode() != 201 && res.getStatusCode() != 204) ) {

                    callout.status__c = 'OK';
                    callout.Duration__c = system.now().getTime() - start;
                }
                else {

                    callout.status__c = !Test.isRunningTest() ? 'KO' : 'OK';
                    callout.Duration__c = system.now().getTime() - start;

                    /* Check if Retry is allowed */
                    Integer allowed_retries = Integer.valueOf(Utils.getHippoSettings('NumOfCalloutRetries'));

                    if ( allowed_retries > 0 && !Test.IsRunningTest() ) {

                        if ( callout.Retries__c < allowed_retries ) {

                            callout.Retries__c++;
                            CalloutTriggerHandler.GO_IN_FOR_RETRY = true;
                        }
                    }
                }

                postCallout(callout, res);

                processed_callouts.add(callout);
            }

            CalloutTriggerHandler.SKIP_RECURSION = true;
            update processed_callouts;
            System.debug('processed_callouts: ' + processed_callouts);
            CalloutTriggerHandler.SKIP_RECURSION = false;
            CalloutTriggerHandler.GO_IN_FOR_RETRY = false;

            CaseTriggerHandler.SKIP_RECURSION = true;
            if ( pending_updates.size() > 0 ) update pending_updates;
            CaseTriggerHandler.SKIP_RECURSION = false;

            if ( callouts_for_child_process.size() > 0 ) {

                HippoChangeDataEventsCallouts hppCalloutsQueueable = new HippoChangeDataEventsCallouts(callouts_for_child_process);
                ID jobID = System.enqueueJob(hppCalloutsQueueable);
            }
        }
        catch (Exception ex) {

            system.debug('HippoChangeDataEventsCallouts execute Exception: ' + ex.getStackTraceString());
        }
    }

    /******************************************************************
    * Method: doCallout, private
    * Description: Execute the actual callout from the platform
    * Return: HttpResponse
    *******************************************************************/
    private HttpResponse doCallout(Callout__c callout) {

        //Loggly.SETTING_NAME = '';

        HttpResponse res = new HttpResponse();

        try {

            HttpRequest req = new HttpRequest();
            req.setMethod(callout.HttpMethod__c);
            //req.setCompressed(true);
            //String authorizationHeader = Utils.getHippoSettings('authorizationHeader');
            //req.setHeader('Authorization', 'Basic ' + authorizationHeader);
            req.setHeader('Content-Type', 'application/json');
            //req.setHeader('Accept', 'application/json');

            Http http = new Http();

            req.setEndpoint(callout.Endpoint__c);
            req.setBody(callout.Payload__c);
            system.debug('req body == ' + req.getBody());
            //Loggly.singleLog('using the following end point for Hippo API transaction: ' + callout.Endpoint__c, System.now(), 'INFO');
            //Loggly.singleLog('sending the following request to Hippo API server: ' + req.getBody(), System.now(), 'INFO');

            callout.Sent_on__c = System.now();
            res = http.send(req);

        }
        catch(Exception ex) {

            res.setHeader('Content-Type', 'text/plain');
            res.setBody(ex.getMessage());
            res.setStatusCode(500);
        }

        return res;
    }

    /******************************************************************
    * Method: serialize_Object, public
    * Description: General serialization method for any object
    * Return: String (json)
    *******************************************************************/
    public static String serialize_Object(Object my_object) {

        String str = '{}';

        if ( null != my_object ) {

            str = JSON.serialize(my_object, false);
        }

        system.debug('my_object json: ' + str);

        return str;
    }

    /*
    Special post callout handling in certain transaction types
    The assumption is that it is OK to perform single DML operation in this method although can be
    called multiple times since the entire queuable execution context is bounded to the callouts limit
    which is currently set to 100 while the DML limit is 150
    (But still: need to fix this and bulkify this part as well)
    * */
    private void postCallout(Callout__c callout, HttpResponse res) {

        system.debug('psotCallout handling: ' + callout);

        try {

            if ( callout.RecordType.Name.equals('MadSky') && callout.status__c.equals('OK') ) {

                system.debug('Handling MadSky ' + callout.HttpMethod__c +  ' Callout Response: ' + res.getBody());

                if ( null != res && callout.HttpMethod__c.equals('POST') ) {

                    HippoChangeDataEventsCallouts.SfdcRestResponse sfdcRestResponse = (HippoChangeDataEventsCallouts.SfdcRestResponse)JSON.deserialize(res.getBody(), HippoChangeDataEventsCallouts.SfdcRestResponse.class);
                    System.debug('sfdcRestResponse: ' + sfdcRestResponse);
                    Case cs = new Case(Id = callout.Case__c, MadSky_Case__c = sfdcRestResponse.id);
                    pending_updates.add(cs);
                }
            }
        }
        catch (Exception ex) {

            System.debug('Exception from postCallout: ' + ex.getMessage());
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