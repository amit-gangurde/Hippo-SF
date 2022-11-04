trigger LangCaseTrigger on Case (after insert) {

    TriggerSetting__c setting = TriggerSetting__c.getInstance('LangCaseTrigger');
    if(setting == null ) {
        List<ID> caseIDs = new List<ID>();
        for (Case c : Trigger.New) {
            caseIDs.add(c.ID);
        }
        system.debug('CaseIDs: ' + caseIDs);
        HippoLangCaseConsumer.process(caseIDs);
    }
    else if(setting.Is_Active__c){
        List<ID> caseIDs = new List<ID>();
        for (Case c : Trigger.New) {
            caseIDs.add(c.ID);
        }
        system.debug('CaseIDs: ' + caseIDs);
        HippoLangCaseConsumer.process(caseIDs);
    }
}