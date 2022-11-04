@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {

    private final String body;
    private final String status;
    private final Integer status_code;

    global MockHttpResponseGenerator() {

        this.body = '';
        this.status = '';
        this.status_code = 200;
    }

    global MockHttpResponseGenerator(String body, String http_method) {

        this.body = body;
        this.status = '';
        this.status_code = 200;
    }

    global MockHttpResponseGenerator(String body, String status, Integer status_code) {

        this.body = body;
        this.status = status;
        this.status_code = status_code;
    }

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {

        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('http://api.salesforce.com/foo/bar', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());
PaymentLoginResponseWrapper pay = new PaymentLoginResponseWrapper();
        pay.Id = '12345';
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(pay));
        res.setStatus(status);
        res.setStatusCode(status_code);
        return res;
    }
}