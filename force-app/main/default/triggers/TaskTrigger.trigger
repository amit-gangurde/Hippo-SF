trigger TaskTrigger on Task (after insert, after update, before delete) {

    new TaskTriggerHandler().run();
}