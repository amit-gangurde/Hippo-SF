trigger ContentDocumentLinkTrigger on ContentDocumentLink (before delete) {
	new ContentDocumentLinkTriggerHandler().run();
}