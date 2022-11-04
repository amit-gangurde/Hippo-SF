public with sharing class ContentDocumentLinkTriggerHandler extends TriggerHandler {
    public override void beforeDelete() {
        if (!FeatureManagement.checkPermission('AllowDeleteTasksAndDocs')) {
            for (SObject doc : Trigger.old) {
                doc.addError('You do not have permission to remove documents from a record');
            }
        }
    } 
}