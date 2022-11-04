trigger CarrierAppointmentChangeEvent on Carrier_Appointment__ChangeEvent (after insert) {

    List<Carrier_Appointment__ChangeEvent> changes = Trigger.new;

    system.debug('changes: ' + changes);

    // Get all carrier appointment id's
    List<Id> all_supported_carrierapp_ids = new List<Id>();

    for (Carrier_Appointment__ChangeEvent change : changes) {

        // Get some event header fields
        EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader) change.ChangeEventHeader;

        // Get all Record Ids for this change and add to the set
        all_supported_carrierapp_ids.addAll(header.getRecordIds());
    }

    system.debug('all_supported_carrierapp_ids: ' + all_supported_carrierapp_ids);

    RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('CarrierAppointmentChangeEvent', 'Callout__c');

    List<Callout__c> callouts = new List<Callout__c>();

    // Get all carrier appointment
    Map<Id, Carrier_Appointment__c> all_supported_carrierapp = new Map<Id, Carrier_Appointment__c>([Select Id, PodID__c, CreatedDate From Carrier_Appointment__c Where Id IN: all_supported_carrierapp_ids]);

    String aws_webhook = Utils.getHippoSettings('AWS Webhook - Carrier Appointment');

    for (Carrier_Appointment__ChangeEvent change : changes) {

        // Get some event header fields
        EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader)change.ChangeEventHeader;

        // Get all Record Ids for this change and add to the set
        List<String> recordIds = header.getRecordIds();
        system.debug('recordIds: ' + recordIds);

        switch on header.changeType {

            when 'CREATE', 'UPDATE' {

                Boolean updateFromPOD = false;

                //Create/Update logic
                System.debug('header.changeType: ' + header.changeType);

                if (header.changetype == 'UPDATE') {

                    System.debug('List of all changed fields:');

                    for (String field : header.changedFields) {

                        if (null == change.get(field)) {

                            System.debug('Deleted field value (set to null): ' + field);

                        } else {

                            System.debug('Changed field value: ' + field + '. New Value: ' + change.get(field));
                        }

                        if ( field.equals('PodID__c') ) {

                            updateFromPOD = true;
                            break;
                        }
                    }
                }

                if ( !updateFromPOD ) {

                    for (String recId : recordIds) {

                        if (all_supported_carrierapp.containsKey(recId)) {

                            HippoChangeDataEvent hppChaneDataEvent = new HippoChangeDataEvent();
                            hppChaneDataEvent.id = recId;

                            if (String.isBlank(String.valueOf(all_supported_carrierapp.get(recId).PodID__c))) {

                                hppChaneDataEvent.eventType = 'Salesforce.Carrier_Appointment__c.CREATE';

                            } else {

                                hppChaneDataEvent.eventType = 'Salesforce.Carrier_Appointment__c.' + header.changeType;
                            }

                            hppChaneDataEvent.lastUpdateDate = String.valueOf(all_supported_carrierapp.get(recId).CreatedDate);  //String.valueOf(DateTime.newInstance(header.commitTimestamp));
                            Callout__c callout = new Callout__c(IsAsync__c = true, RecordTypeId = rtInfo.getRecordTypeId(), HttpMethod__c = 'POST', Endpoint__c = aws_webhook, Payload__c = HippoChangeDataEventsCallouts.serialize_Object(hppChaneDataEvent), Job_ID__c = '', Carrier_Appointment__c = recId, Status__c = 'Queued');
                            callouts.add(callout);
                        }
                    }
                }
            }
        /*
        when 'DELETE' {
            //Delete logic
            System.debug('DELETE');
        }
        when 'UNDELETE' {
            //Undelete logic
            System.debug('UNDELETE');
        }
         */
        }

        //EventBus.TriggerContext.currentContext().setResumeCheckpoint(change.replayId);
    }

    system.debug('callouts: ' + callouts);
    if ( callouts.size() > 0 ) insert callouts;
}