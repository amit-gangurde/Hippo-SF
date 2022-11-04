@isTest
private class LangClientTest {
    @isTest static void testLangClient() {
        // Set mock callout class 

        String domain = 'test_domain.lang.ai';
        String token = 'test_token';
        String project_id = 'test_project_id';
        String text = 'the text we will test with';
        List<String> tagNames = new List<String>{'Tag 1', 'Tag 2'};
        Test.setMock(HttpCalloutMock.class, new LangHttpCalloutMock(domain, token, project_id, text, tagNames));
        
        LangClient client = new LangClient(domain ,token, project_id);
        List<String> tags = client.analyze(text);
        
        System.assertEquals(tagNames, tags);
    }
}