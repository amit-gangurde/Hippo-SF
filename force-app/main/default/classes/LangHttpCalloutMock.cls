@isTest
global class LangHttpCalloutMock implements HttpCalloutMock {
    private String domain;
    private String token;
    private String project_id;
    private String text;
    private List<String> tagNames;
    private static final String endpoint = '/api/v1/documents';

    public LangHttpCalloutMock(String domain, String token, String project_id, String text, List<String> tagNames){
        this.domain = domain;
        this.token = token;
        this.project_id = project_id;
        this.text = text;
        this.tagNames = tagNames;
    }
    global HTTPResponse respond(HTTPRequest req) {
        String endpoint = 'https://' + this.domain + endpoint;
       // System.assertEquals(endpoint, req.getEndpoint());
       // System.assertEquals('POST', req.getMethod());
       // System.assertEquals('Bearer ' + this.token, req.getHeader('Authorization'));
        String expectedBody = '{"projectId":"'+this.project_id+'","text":"'+this.text+'"}';
       // System.assertEquals(expectedBody, req.getBody());
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String body = '{'+
            '"intents": [' +
                '{"name": "intent1", "features": [], "cluster": "cluster1"}'+
            '],'+
            '"tags": [';
        for (Integer i =0; i<this.tagNames.size(); i++) {
            body = body + '{"id": "tag'+i+'", "name": "' + this.tagNames.get(i) +'"}';
            if (i != this.tagNames.size()-1) {
                body = body +',';
            }
        }
        body = body + ']}';
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}