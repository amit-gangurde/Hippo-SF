trigger OpTrigger on Op__c (before insert, before update, after insert, after update) {
	 new OpTriggerHandler().run();
}