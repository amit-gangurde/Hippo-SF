trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    SYSTEM.debug('LeadTrigger BABAN');

    new LeadTriggerHandler().run();
}