public class LangClient {
    private String domain;
    private String token;
    private String project_id;
    private static final String endpoint = '/api/v1/documents';

    public LangClient(String domain, String token, String project_id){
        this.domain = domain;
        this.token = token;
        this.project_id = project_id;
    }

    public List<String> analyze(String text) {
        system.debug('Lang.ai analyze for text '+ text);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://' + this.domain + endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        Map<String,String> body = new Map<String,String> {
            'text'=> text,
            'projectId'=> this.project_id
        };
        String JSONbody = JSON.serialize(body);
        req.setBody(JSONbody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        List<String> tagNames = new List<String>();
        if (res.getStatusCode() == 200) {
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            if ( m != null && m.get('tags') != null ) {
                for (Object tag : (List<Object>) m.get('tags')) {
                    Map<String, Object> tagMap = (Map<String, Object>) tag;
                    String tagName = (String) tagMap.get('name');
                    tagNames.add(tagName);
                }
            }
        } else {
            system.debug('Lang.ai request failed with code ' + res.getStatusCode());
        }
        system.debug('Tags: '+ tagNames);
        return tagNames;
    }
}