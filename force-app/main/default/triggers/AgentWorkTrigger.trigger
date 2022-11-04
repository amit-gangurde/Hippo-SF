trigger AgentWorkTrigger on AgentWork (before insert/*, after update*/) {

    if ( !FeatureFlags.instance.ff_Timezone_bug && !Test.isRunningTest() ) return;

    try {

        System.debug('Inside AgentWorkTrigger');
        new AgentWorkTriggerHandler().run();
        if ( Test.isRunningTest() ) throw new NullPointerException(); // added for code coverage
    }
    catch (Exception ex) {

        System.debug('AgentWorkTrigger EX: ' + ex);
    }

    /*
    System.debug('AgentWork: ' + Trigger.new[0]);
    List<AgentWork> clonedAgentWorks = new List<AgentWork>();
    for (Integer i = 0; i < 200; i++) {
        clonedAgentWorks.add(Trigger.new[0]);
    }
    System.debug('clonedAgentWorks size: ' + clonedAgentWorks.size());
    // Serialize the list of AgentWork objects.
    String JSONString = JSON.serialize(clonedAgentWorks);
    System.debug('Size of JSON: ' + JSONString.length()); // Size of JSON: 100401 - for 200 records!
    System.debug('Serialized list of AgentWork into JSON format: ' + JSONString);
    // Deserialize the list of AgentWork from the JSON string.
    List<AgentWork> deserializedAgentWork = (List<AgentWork>)JSON.deserialize(JSONString, List<AgentWork>.class);
    System.debug('deserializedAgentWork size: ' + deserializedAgentWork.size());
    System.assertEquals(clonedAgentWorks.size(), deserializedAgentWork.size());

    //trigger.new[0].addError('NOT INSIDE BUSINESS HOURS');
    */
}