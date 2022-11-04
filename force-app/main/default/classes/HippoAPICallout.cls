public with sharing class HippoAPICallout {
    public static HttpResponse makePOSTCallout(APIIntegrationSetting__mdt apiSetting, String bodyRequest) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiSetting.Endpoint__c);
        request.setMethod(apiSetting.Method__c);
        request.setHeader('Content-Type', apiSetting.ContentType__c);
        request.setBody(bodyRequest);
        HttpResponse response = http.send(request);
        return response;
    }

    public static HttpResponse makeGETCallout(APIIntegrationSetting__mdt apiSetting, String url) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiSetting.Endpoint__c + url);
        request.setMethod(apiSetting.Method__c);
        request.setHeader('Content-Type', apiSetting.ContentType__c);
        HttpResponse response = http.send(request);
        return response;
    }
}