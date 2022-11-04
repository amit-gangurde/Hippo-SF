public class PaymentAuth {
    public static PaymentAuth_Integration_System__c payAuthSetting;
    public PaymentAuth(){
        payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults();
    }
    public static String getSessionID(){
        payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults();
        user_authClass log = new user_authClass();
        log.user_name = payAuthSetting.User_Name__c;
        log.password = payAuthSetting.Password__c;
        log.version = '1';

        loginReqWrapper logWrap = new loginReqWrapper();
        logWrap.user_auth = log;

        System.debug(JSON.serialize(logWrap));

        String urlEncodedBody = Constants.method+'='+Constants.method_Login+'&';
        urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
        urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
        urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSON.serialize(logWrap), 'UTF-8');
        system.debug('passes'+payAuthSetting.Base_URL__c);
        HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
        System.debug('response=='+response.getBody());
        if(response.getStatusCode() == 200){
            PaymentLoginResponseWrapper payLoginWrap = (PaymentLoginResponseWrapper) JSON.deserialize(response.getBody(),PaymentLoginResponseWrapper.class);
            String session_id = payLoginWrap.id;
            System.debug(session_id);
            return session_id;
        }
        return null;
    }

    public static String endSessionBase(String sessionId) {
        logoutReqWrapper logOut = new logoutReqWrapper();
        logOut.session = sessionId;
        String urlEncodedBody = Constants.method+'='+Constants.method_Logout+'&';
        urlEncodedBody+= Constants.input_type+'='+Constants.input_type_JSON+'&';
        urlEncodedBody+= Constants.response_type+'='+Constants.input_type_response_type+'&';
        urlEncodedBody+= Constants.rest_data+'='+EncodingUtil.urlEncode(JSON.serialize(logOut), 'UTF-8');

        HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
       // System.debug('response=='+response.getBody());
        return null;
    }
    public static String endSession(){
        return endSessionBase(PaymentAuth.getSessionID());
    }
    public class logoutReqWrapper{
        public String session;
    }
    public class loginReqWrapper{
        public user_authClass user_auth;
    }
    public class user_authClass{
        public String user_name;
        public String password;
        public String version;
    }
}