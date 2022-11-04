public with sharing class AgentAvailabilityController {

    @AuraEnabled(cacheable=true)
    public static Boolean anyAgentAvailable_v2(String queueDevName) {

        Boolean res = false;

        System.debug('User Info -> ' + UserInfo.getName());

        Map<String, Set<Id>> map_Group2ActiveUsers = Utils.groupDeveloperNameAndTypeToActiveUserIds;

        System.debug('map_Group2ActiveUsers -> ' + map_Group2ActiveUsers);

        //map_Group2ActiveUsers.containsKey('HAS_Internal_Referrals-Queue')

        String queue_in_context = queueDevName + '-Queue';
        System.debug('queue_in_context -> ' + queue_in_context);

        if ( map_Group2ActiveUsers.containsKey(queue_in_context) ) {

            Set<Id> agentIds = new Set<Id>();

            agentIds.addAll(map_Group2ActiveUsers.get(queue_in_context));

            System.debug('agentIds -> ' + agentIds);

            if ( agentIds.size() > 0 ) {

                List<User> available_agents = [SELECT Id, Name, Online_On_AWS__c, On_a_Call__c FROM User WHERE Online_On_AWS__c = TRUE AND On_a_Call__c = FALSE AND Id IN :agentIds];

                System.debug('available_agents -> ' + available_agents);

                if ( available_agents.size() > 0 ) res = true;
            }
        }

        System.debug('res -> ' + res);

        return res;
    }

    /*
    @AuraEnabled(cacheable=true)
    public static Boolean anyAgentAvailable_v1(String queueDevName) {

        Boolean res = false;

        System.debug('User Info -> ' + UserInfo.getName());

        Map<String, Set<Id>> map_Group2ActiveUsers = Utils.groupDeveloperNameAndTypeToActiveUserIds;

        System.debug('map_Group2ActiveUsers -> ' + map_Group2ActiveUsers);

        //map_Group2ActiveUsers.containsKey('HAS_Internal_Referrals-Queue')

        String queue_in_context = queueDevName + + '-Queue';
        System.debug('queue_in_context -> ' + queue_in_context);

        if ( map_Group2ActiveUsers.containsKey(queue_in_context) ) {

            Set<Id> agentIds = new Set<Id>();

            agentIds.addAll(map_Group2ActiveUsers.get('HAS_Internal_Referrals-Queue'));

            System.debug('agentIds -> ' + agentIds);

            if ( agentIds.size() > 0 ) {

                Map<String, String> map_NonBusyLeadsPresenceStatus = Utils.getNonBusyLeadsPresenceStatus();

                System.debug('map_NonBusyLeadsPresenceStatus -> ' + map_NonBusyLeadsPresenceStatus);

                // Get current UserServicePresence records of all agents in context
                //  If an agent has an active UserServicePresence record, it means that he is online and either available for work or currently in full capacity
                List<UserServicePresence> userServicePresences = [SELECT Id, UserId, ConfiguredCapacity FROM UserServicePresence WHERE IsCurrentState = true AND ServicePresenceStatus.MasterLabel IN :map_NonBusyLeadsPresenceStatus.keySet() AND UserId IN :agentIds];

                System.debug('UserServicePresence -> ' + userServicePresences);

                // Build a map between an agent to it's allowed capacity
                Map<Id, Integer> map_UserId2ConfiguredCapacity = new Map<Id, Integer>();
                for ( UserServicePresence userServicePresence : userServicePresences) {

                    map_UserId2ConfiguredCapacity.put(userServicePresence.UserId, userServicePresence.ConfiguredCapacity);
                }

                ServiceChannel sc = [SELECT Id, DeveloperName, MasterLabel, RelatedEntity FROM ServiceChannel WHERE RelatedEntity = 'Lead' LIMIT 1];

                System.debug('ServiceChannel -> ' + sc);

                if ( null != sc ) {

                    // Get all current Opened agent work records, leads related only, for all agents in context
                    //  If the total of open agent work records, per agent, is less then it's configured capacity - which we have since we queried UserServicePresence before
                    //  then it means that the agent is available for additional work
                    List<AggregateResult> aggregateResults = [SELECT CreatedById, Count(Id) Consumed_Capacity FROM AgentWork WHERE ServiceChannelId =: sc.Id AND (Status = 'Opened' OR Status = 'Assigned') AND CreatedById IN :agentIds GROUP BY CreatedById];

                    System.debug('Consumed Capacity -> ' + aggregateResults);

                    if ( aggregateResults.size() > 0 ) {

                        for (AggregateResult agr : aggregateResults) {

                            Id agentId = (Id) agr.get('CreatedById');
                            System.debug('agentId -> ' + aggregateResults);
                            Integer agentConsumedCapacity = (Integer) agr.get('Consumed_Capacity');
                            System.debug('agentConsumedCapacity -> ' + agentConsumedCapacity);
                            if ( map_UserId2ConfiguredCapacity.containsKey(agentId) ) {

                                Integer agentConfiguredCapacity = map_UserId2ConfiguredCapacity.get(agentId);
                                System.debug('agentConfiguredCapacity -> ' + agentConfiguredCapacity);
                                if (agentConfiguredCapacity > agentConsumedCapacity) {

                                    res = true;
                                    break; // ANY available agent is ok to be reported
                                }
                            }
                        }
                    }
                    else {

                        if ( map_UserId2ConfiguredCapacity.size() > 0 ) {

                            res = true; // It means that there are available agent(s) online with full capacity availability
                        }
                    }

                    //System.debug(aggregateResults[0].get('Consumed_Capacity'));
                }
            }
        }

        System.debug('res -> ' + res);

        return res;
    }
    */
}