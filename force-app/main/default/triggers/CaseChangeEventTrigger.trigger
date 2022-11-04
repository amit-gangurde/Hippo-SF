trigger CaseChangeEventTrigger on CaseChangeEvent (after insert) {

    List<CaseChangeEvent> changes = Trigger.new;

    system.debug('changes: ' + changes);

    // Get all case id's so we can filter only for Claim record type
    List<Id> all_supported_case_ids = new List<Id>();

    for (CaseChangeEvent change : changes) {

        // Get some event header fields
        EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader) change.ChangeEventHeader;

        // Get all Record Ids for this change and add to the set
        all_supported_case_ids.addAll(header.getRecordIds());
    }

    system.debug('all_supported_case_ids: ' + all_supported_case_ids);

    RecordTypeInfo rtInfo = Utils.getRecordTypeInfo('CaseChangeEvent', 'Callout__c');

    List<Callout__c> callouts = new List<Callout__c>();

    // Get all cases with Claim record type
    Map<Id, Case> all_supported_cases = new Map<Id, Case>([Select Id, POD_Claim_ID__c, CreatedDate From Case Where Id IN: all_supported_case_ids And RecordType.DeveloperName = 'Claim']);

    String aws_webhook = Utils.getHippoSettings('AWS Webhook - Case');

    for (CaseChangeEvent change : changes) {

        // Get some event header fields
        EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader)change.ChangeEventHeader;

        // Get all Record Ids for this change and add to the set
        List<String> recordIds = header.getRecordIds();
        system.debug('recordIds: ' + recordIds);

        switch on header.changeType {

            when 'CREATE', 'UPDATE' {

                Boolean updateFromPOD = false;

                //Create logic
                System.debug('header.changeType: ' + header.changeType);

                if (header.changetype == 'UPDATE') {

                    System.debug('List of all changed fields:');

                    for (String field : header.changedFields) {

                        if (null == change.get(field)) {

                            System.debug('Deleted field value (set to null): ' + field);

                        } else {

                            System.debug('Changed field value: ' + field + '. New Value: ' + change.get(field));
                        }

                        if ( field.equals('POD_Claim_ID__c') ) {

                            updateFromPOD = true;
                            break;
                        }
                    }
                }

                if ( !updateFromPOD ) {

                    for (String recId : recordIds) {

                        if (all_supported_cases.containsKey(recId)) {

                            HippoChangeDataEvent hppChaneDataEvent = new HippoChangeDataEvent();
                            hppChaneDataEvent.id = recId;

                            if (String.isBlank(String.valueOf(all_supported_cases.get(recId).POD_Claim_ID__c))) {

                                hppChaneDataEvent.eventType = 'Salesforce.Case.CREATE';

                            } else {

                                hppChaneDataEvent.eventType = 'Salesforce.Case.' + header.changeType;
                            }

                            hppChaneDataEvent.lastUpdateDate = String.valueOf(all_supported_cases.get(recId).CreatedDate);  //String.valueOf(DateTime.newInstance(header.commitTimestamp));
                            Callout__c callout = new Callout__c(IsAsync__c = true, RecordTypeId = rtInfo.getRecordTypeId(), HttpMethod__c = 'POST', Endpoint__c = aws_webhook, Payload__c = HippoChangeDataEventsCallouts.serialize_Object(hppChaneDataEvent), Job_ID__c = '', Case__c = recId, Status__c = 'Queued');
                            callouts.add(callout);
                        }
                    }
                }
            }
        }

        //EventBus.TriggerContext.currentContext().setResumeCheckpoint(change.replayId);
    }

    system.debug('callouts: ' + callouts);
    if ( callouts.size() > 0 ) insert callouts;
}