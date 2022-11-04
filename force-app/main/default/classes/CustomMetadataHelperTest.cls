@IsTest
private class CustomMetadataHelperTest {

    @IsTest
    static void testBehavior() {

        List<Lead_Score__mdt> leadScoreMetadata = [SELECT MasterLabel, DeveloperName, Checked__c, Additional_Text__c FROM Lead_Score__mdt WHERE MasterLabel = '1'];
        System.assertEquals(1, leadScoreMetadata.size());
        leadScoreMetadata[0].Checked__c = true;
        leadScoreMetadata[0].Additional_Text__c = '+';
        String jobId = CustomMetadataHelper.upsertMetadata(leadScoreMetadata);

        CustomMetadataHelper.toggleLeadScore('1', true);

        // Instantiate the callback.
        Metadata.DeployCallback callback = new CustomMetadataHelper.CustomMetadataCallback();
        // Create test result and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.numberComponentErrors = 1;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        // Invoke the callback's handleResult method.
        callback.handleResult(result, context);
    }
}