@isTest
global class AgentSyncMockTest implements HttpCalloutMock {
    public String body;
    global AgentSyncMockTest(String body){
        this.body = body;
    }
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        response.setStatusCode(200);
        return response; 
    }
}