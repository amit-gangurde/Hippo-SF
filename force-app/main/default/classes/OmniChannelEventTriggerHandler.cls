/*
This is an handler for platform event Omni_Channel_Event__e
It is not a standard trigger so no need to inherit the TriggerHandler.
If extending TriggerHandler will be required in the future, the class should get modified
as for now it will juts contain static methods to handle the related business logic
 */
public with sharing class OmniChannelEventTriggerHandler {

    public static void handleAgentWorkCreation(String serializedAgentWork) {

        try {

            if ( String.isNotBlank(serializedAgentWork) ) {

                // Deserialize the list of AgentWork from the JSON string.
                List<AgentWork> deserializedAgentWork = (List<AgentWork>)JSON.deserialize(serializedAgentWork, List<AgentWork>.class);
                System.debug('deserializedAgentWork size: ' + deserializedAgentWork.size());
                if ( deserializedAgentWork.size() > 0 ) {

                    AgentWorkTriggerHandler.SKIP_RECURSION = true;
                    insert deserializedAgentWork;
                    AgentWorkTriggerHandler.SKIP_RECURSION = false;
                }
            }
        } catch (Exception ex) {

            System.debug('Exception from OmniChannelEventTriggerHandler::handleAgentWorkCreation execution: ' + ex.getMessage());
        }

    }
}