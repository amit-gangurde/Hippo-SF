public class CalloutHelper {
    public static HttpResponse callCalloutHelper(String urlEncodedBody,String EndPoint,String Method){
        try{
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        system.debug('@@body'+urlEncodedBody);
        system.debug('@@EndPoint'+EndPoint);
        system.debug('@@Method'+Method);
        request.setHeader('Content-Type', Constants.Content_type);
        request.setBody(urlEncodedBody);
        request.setEndpoint(EndPoint);
        request.setMethod(Method);

        response = http.send(request);
        system.debug('Helper Response=='+response);
        system.debug('Helper Response Body=='+response.getBody());
        return response;
        }catch(Exception ex){
            System.debug('ex:::'+ex.getLineNumber());
              System.debug('ex:::'+ex.getMessage());
            return null;
        }
    }

    public static String buildMethodCall(String method, String JSONRes) {
        String urlEncodedBody = Constants.method+'='+method+'&';
        urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
        urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
        urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSONRes, 'UTF-8');
        return urlEncodedBody;
    }
}