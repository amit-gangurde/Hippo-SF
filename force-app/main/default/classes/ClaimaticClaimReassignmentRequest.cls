/*******************************************************************************************
* @Name         ClaimaticClaimReassignmentRequest
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  Wrapper Class for Claim Reassignment request
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation                                                      
*******************************************************************************************/
public class ClaimaticClaimReassignmentRequest {

public ClaimaticClaimReassignmentRequest(){
 assignments = new List<cls_assignments>();
}
    public String claim_number; //dsdasdasdas
    public cls_assignments[] assignments;
    
    public class cls_assignments{
        public Integer is_primary;
        public Integer assignment_party_id;
        public string to_remove_resource_id;
        public String resource_num;
        public String to_remove_resource_email;
        public String username;
        public String to_remove_resource_username;
        public String resource_email;
        public String to_remove_resource_num;
        public string resource_id;
    }
}