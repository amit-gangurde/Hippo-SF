trigger IntegrationErrorLog on Integration_Error_Log__c (before insert) {
IntegrationErrorLogger.beforeInsert(trigger.new);
}