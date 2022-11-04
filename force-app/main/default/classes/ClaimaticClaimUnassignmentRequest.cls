/*******************************************************************************************
* @Name         ClaimaticClaimUnassignmentRequest
* @Author       Convene-tech
* @Date         11/19/2020
* @Group        Claimatic Service
* @Description  Wrapper class to store all the unassignment request for claimatic system
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      11/19/2020          Initial Creation                                                      
*******************************************************************************************/
Public class ClaimaticClaimUnassignmentRequest{
    public ClaimaticClaimUnassignmentRequest(){
        unassignments = new List<cls_assignments>();
    }
    public String claim_number; //dsdasdasdas
    public cls_assignments[] unassignments;
    Public class cls_assignments {
        public String resource_email;   //mtcronin@hotmail.com
        public String username; //MTC-tester
        public String resource_num; //123
        public Integer assignment_party_id; //2
        public Integer is_primary;  //1
    }
}