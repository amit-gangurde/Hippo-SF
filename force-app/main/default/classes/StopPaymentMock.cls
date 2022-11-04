@isTest
global class StopPaymentMock implements HttpCalloutMock {
    public String status = 'Success';
    global StopPaymentMock(String status){
        this.status = status;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
      
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"PM_PaymentID" : "PM1234ETS", "PM_AmountUnloaded" : "123","PM_Status" : "Error","Status" : "Error","Error Code" : "41","Error Message" : "Success"}');
        if(status == 'Error'){
            res.setStatusCode(400);
        }else{
            res.setStatusCode(200);
        }
        return res;
    }
}