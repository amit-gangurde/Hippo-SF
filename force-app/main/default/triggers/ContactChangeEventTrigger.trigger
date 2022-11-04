trigger ContactChangeEventTrigger on ContactChangeEvent (after insert) {

    List<ContactChangeEvent> changes = Trigger.new;

    system.debug('changes: ' + changes);

    // Get all contact id's so we can filter only for Business record type
    List<Id> all_supported_contact_ids = new List<Id>();

    for (ContactChangeEvent change : changes) {

        // Get some event header fields
        EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader) change.ChangeEventHeader;

        // Get all Record Ids for this change and add to the set
        all_supported_contact_ids.addAll(header.getRecordIds());
    }

    system.debug('all_supported_contact_ids: ' + all_supported_contact_ids);

    RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('ContactChangeEvent', 'Callout__c');

    List<Callout__c> callouts = new List<Callout__c>();

    // Get all contacts with Business record type
    Map<Id, Contact> all_supported_contacts = new Map<Id, Contact>([Select Id, PodID__c, CreatedDate From Contact Where Id IN: all_supported_contact_ids And RecordType.DeveloperName = 'IndustriesBusiness']);

    String aws_webhook = Utils.getHippoSettings('AWS Webhook - Contact');

    for (ContactChangeEvent change : changes) {

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

                        if (all_supported_contacts.containsKey(recId)) {

                            HippoChangeDataEvent hppChaneDataEvent = new HippoChangeDataEvent();
                            hppChaneDataEvent.id = recId;

                            if (String.isBlank(String.valueOf(all_supported_contacts.get(recId).PodID__c))) {

                                hppChaneDataEvent.eventType = 'Salesforce.Contact.CREATE';

                            } else {

                                hppChaneDataEvent.eventType = 'Salesforce.Contact.' + header.changeType;
                            }

                            hppChaneDataEvent.lastUpdateDate = String.valueOf(all_supported_contacts.get(recId).CreatedDate);  //String.valueOf(DateTime.newInstance(header.commitTimestamp));
                            Callout__c callout = new Callout__c(IsAsync__c = true, RecordTypeId = rtInfo.getRecordTypeId(), HttpMethod__c = 'POST', Endpoint__c = aws_webhook, Payload__c = HippoChangeDataEventsCallouts.serialize_Object(hppChaneDataEvent), Job_ID__c = '', Contact__c = recId, Status__c = 'Queued');
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