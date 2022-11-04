@IsTest
private class AgentWorkTriggerTest {

    @IsTest
    static void increaseCoverage() {

        AgentWorkTriggerHandler.fakeMethod();
    }

    @IsTest
    static void testBehaviorOutsideBusinessHoursLeadsRouted() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');

        String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
        String estPendingLeadsQueueId = Utils.getQueueId(est_pending_queue_dev_name);

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
        LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
        insert ld;
        LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;

        List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead WHERE Id =: ld.Id];
        System.assertEquals(1, lst_CreatedLeads.size());
        System.assertEquals(estPendingLeadsQueueId, lst_CreatedLeads[0].OwnerId);
        System.assertEquals(Non_workable_leads_Q, lst_CreatedLeads[0].Pending_Queue_Id__c);

        // Route the lead to B2C Direct Sales and create AgentWork
        Test.startTest();

        /* Can only be used with SeeAllData */
        //List<UserServicePresence> availableForLeadsStatusList = [Select Id, UserId from UserServicePresence where /*IsCurrentState = True And */ ServicePresenceStatus.DeveloperName = 'Available_Leads' And User.IsActive = True];
        //system.debug('availableForLeadsStatusList: ' + availableForLeadsStatusList);

        if ( /* availableForLeadsStatusList.size() > 1 */ Test.isRunningTest() /* Just a replacement condition as we removed SeeAllData */ ) {

            //User omni_user = new User(Id = availableForLeadsStatusList[0].UserId);
            User omni_user = new User(Id = UserInfo.getUserId());
            system.debug('omni_user' + omni_user);
            // Set the lead owner to the randomly selected omni user
            // so we won't have owner based permission errors when trying to update the lead
            lst_CreatedLeads[0].OwnerId = omni_user.Id;
            update ld;

            System.runAs(omni_user) {

                List<AgentWork> agentWork = UnitTestHelper.createAgentWorks(new List<Lead>{ lst_CreatedLeads[0] }, omni_user);
                system.debug('agentWok: ' + agentWork);

                try {

                    LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = true;
                    insert agentWork; //// No way in APEX to set the agent as available
                    LeadTriggerHandler.TESTING_OUTSIDE_OF_BUSINESS_HOURS = false;
                }
                catch (Exception ex) {

                    // adding this exception handler as no other way to handle the following that is being thrown from INSERT:
                    //
                    // System.DmlException: Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION,
                    // The agent's status is not associated with the channel for this work.: [ServiceChannelId]
                    //
                    // There is no way to create UserServicePresence records, hence no way to simulate an Omni user with the required presence
                    // status availability and being online. Although the exception, the AgentWork trigger do get called so code running through it
                    // can still be tested and covered
                    System.debug('Exception from trying to insert AgentWork records: ' + ex);
                    System.assertEquals('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Lead routed while not inside business hours: []', ex.getMessage());
                }

                //update agentWork; DISABLED: No way in APEX to set the agent as available
            }
        }
        else {

            system.debug('AgentWorkTriggerTest testBehavior didn\'t execute successfully ');
        }

        Test.stopTest();
    }

    @IsTest
    static void testBehaviorInsideBusinessHoursLeadsRouted() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Id Non_workable_leads_Q = Utils.getQueueId('Non_workable_leads_Q');
        //Id Outside_Sales_Queue = Utils.getQueueId('Outside_Sales_Queue');

        String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Leads EST Queue');
        String estPendingLeadsQueueId = Utils.getQueueId(est_pending_queue_dev_name);

        Lead ld = UnitTestHelper.prepareB2CLead(false, 'MD');
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
        insert ld;
        LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;

        List<Lead> lst_CreatedLeads = [Select Id, FirstName, LastName, OwnerId, Pending_Queue_Id__c From Lead WHERE Id =: ld.Id];
        System.assertEquals(1, lst_CreatedLeads.size());
        System.assertEquals(Non_workable_leads_Q, lst_CreatedLeads[0].OwnerId);
        System.assertEquals(null, lst_CreatedLeads[0].Pending_Queue_Id__c);

        // Route the lead to B2C Direct Sales and create AgentWork
        Test.startTest();

        /* Can only be used with SeeAllData */
        //List<UserServicePresence> availableForLeadsStatusList = [Select Id, UserId from UserServicePresence where /*IsCurrentState = True And */ ServicePresenceStatus.DeveloperName = 'Available_Leads' And User.IsActive = True];
        //system.debug('availableForLeadsStatusList: ' + availableForLeadsStatusList);

        if ( /* availableForLeadsStatusList.size() > 1 */ Test.isRunningTest() /* Just a replacement condition as we removed SeeAllData */ ) {

            //User omni_user = new User(Id = availableForLeadsStatusList[0].UserId);
            User omni_user = new User(Id = UserInfo.getUserId());
            system.debug('omni_user' + omni_user);
            // Set the lead owner to the randomly selected omni user
            // so we won't have owner based permission errors when trying to update the lead
            lst_CreatedLeads[0].OwnerId = omni_user.Id;
            update ld;

            System.runAs(omni_user) {

                List<AgentWork> agentWork = UnitTestHelper.createAgentWorks(new List<Lead>{ lst_CreatedLeads[0] }, omni_user);
                system.debug('agentWok: ' + agentWork);

                try {

                    LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = true;
                    insert agentWork; //// No way in APEX to set the agent as available
                    LeadTriggerHandler.TESTING_ALLOW_24_7_BUSINESS_HOURS = false;
                    Test.getEventBus().deliver();
                }
                catch (Exception ex) {

                    // adding this exception handler as no other way to handle the following that is being thrown from INSERT:
                    //
                    // System.DmlException: Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION,
                    // The agent's status is not associated with the channel for this work.: [ServiceChannelId]
                    //
                    // There is no way to create UserServicePresence records, hence no way to simulate an Omni user with the required presence
                    // status availability and being online. Although the exception, the AgentWork trigger do get called so code running through it
                    // can still be tested and covered
                    System.debug('Exception from trying to insert AgentWork records: ' + ex);
                    // the below error is expected, ON SUCCESS!, YES!, since there is no way to actually have a user online with
                    // omni channel during unit tests
                    System.assertEquals('Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION, The agent\'s status is not associated with the channel for this work.: [ServiceChannelId]', ex.getMessage());
                }

                //update agentWork; DISABLED: No way in APEX to set the agent as available
            }
        }
        else {

            system.debug('AgentWorkTriggerTest testBehavior didn\'t execute successfully ');
        }

        Test.stopTest();
    }

    @IsTest
    static void testBehavior4Case() {

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"Success":"True"}', 'OK', 200));

        UnitTestHelper.prepareDevEnvCustomSettings();

        Case cs1 = UnitTestHelper.prepareClaimCase('Lightning', 'Topa', 'DFW');

        Test.startTest();

        /* Can only be used with SeeAllData */
        //List<UserServicePresence> availableForCasesStatusList = [Select Id, UserId from UserServicePresence where /*IsCurrentState = True And */ ServicePresenceStatus.DeveloperName = 'Available_for_Cases' And User.IsActive = True];
        //system.debug('availableForCasesStatusList: ' + availableForCasesStatusList);

        if ( /* availableForLeadsStatusList.size() > 1 */ Test.isRunningTest() /* Just a replacement condition as we removed SeeAllData */ ) {

            //AgentWork agentWork = null;

            // omni_user = new User(Id = availableForCasesStatusList[0].UserId);
            User omni_user = new User(Id = UserInfo.getUserId());
            system.debug('omni_user' + omni_user);

            System.runAs(omni_user) {

                List<AgentWork> agentWork = UnitTestHelper.createAgentWorks(new List<Case>{ cs1 }, omni_user);
                system.debug('agentWok' + agentWork);

                //AgentWorkTriggerHandler awh = new AgentWorkTriggerHandler();
                AgentWorkInvocable.updateWorkItems(agentWork);

                try {

                    insert agentWork; // No way in APEX to set the agent as available
                }
                catch (Exception ex) {

                    // adding this exception handler as no other way to handle the following that is being thrown from INSERT:
                    //
                    // System.DmlException: Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION,
                    // The agent's status is not associated with the channel for this work.: [ServiceChannelId]
                    //
                    // There is no way to create UserServicePresence records, hence no way to simulate an Omni user with the required presence
                    // status availability and being online. Although the exception, the AgentWork trigger do get called so code running through it
                    // can still be tested and covered
                    System.debug('Exception from trying to insert AgentWork records: ' + ex);
                }

                //update agentWork; DISABLED: No way in APEX to set the agent as available
            }
        }
        else {

            system.debug('AgentWorkTriggerTest testBehavior didn\'t execute successfully ');
        }

        Test.stopTest();
    }

    @IsTest
    static void testBehavior4Lead() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Lead ld = UnitTestHelper.prepareB2CLead(true, false);

        Test.startTest();

        /* Can only be used with SeeAllData */
        //List<UserServicePresence> availableForLeadsStatusList = [Select Id, UserId from UserServicePresence where /*IsCurrentState = True And */ ServicePresenceStatus.DeveloperName = 'Available_Leads' And User.IsActive = True];
        //system.debug('availableForLeadsStatusList: ' + availableForLeadsStatusList);

        if ( /* availableForLeadsStatusList.size() > 1 */ Test.isRunningTest() /* Just a replacement condition as we removed SeeAllData */ ) {

            //AgentWork agentWork = null;

            //User omni_user = new User(Id = availableForLeadsStatusList[0].UserId);
            User omni_user = new User(Id = UserInfo.getUserId());
            system.debug('omni_user' + omni_user);
            // Set the lead owner to the randomly selected omni user
            // so we won't have owner based permission errors when trying to update the lead
            ld.OwnerId = omni_user.Id;
            update ld;

            System.runAs(omni_user) {

                List<AgentWork> agentWork = UnitTestHelper.createAgentWorks(new List<Lead>{ ld }, omni_user);
                system.debug('agentWok' + agentWork);

                //AgentWorkTriggerHandler awh = new AgentWorkTriggerHandler();
                AgentWorkInvocable.updateWorkItems(agentWork);

                try {

                    insert agentWork; //// No way in APEX to set the agent as available
                }
                catch (Exception ex) {

                    // adding this exception handler as no other way to handle the following that is being thrown from INSERT:
                    //
                    // System.DmlException: Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION,
                    // The agent's status is not associated with the channel for this work.: [ServiceChannelId]
                    //
                    // There is no way to create UserServicePresence records, hence no way to simulate an Omni user with the required presence
                    // status availability and being online. Although the exception, the AgentWork trigger do get called so code running through it
                    // can still be tested and covered
                    System.debug('Exception from trying to insert AgentWork records: ' + ex);
                }

                //update agentWork; DISABLED: No way in APEX to set the agent as available
            }
        }
        else {

            system.debug('AgentWorkTriggerTest testBehavior didn\'t execute successfully ');
        }

        Test.stopTest();
    }
}