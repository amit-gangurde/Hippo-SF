@isTest
public class PaymentFeedbackTest {
    static testMethod void testDoGet() {
        String myJSON = '{"PM_CR_PaymentID":"PMM01302018009","PM_IP_PaymentID":"2390c4a5-7bad-7d66-7502-5b7f9b63456","PM_Amount":"256.36","PM_Funded":true,"PM_Status":"Success","PM_PaidDate":"2020-01-20","PM_ClearedDate":"2020-07-30","PM_EscheatDate":"2020-07-30","PM_CheckNumber":1478529,"PM_MailTrackingNumber":"TRACK12345","PM_MethodID":"2390c4a5-7bad-7d66-7502-865f9b6344f2","PM_New_Method":"Direct_Deposit","PM_Orig_Method":"Check","PM_Selection":"value","PM_Method_Last4Digit":9874,"PM_ReIssue":"N","PM_ErrorCode":"45","PM_ErrorMessage":"error message"}';

        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/upsertaccount';
        request.httpMethod = 'POST';
		request.requestBody = Blob.valueof(myJSON);

        RestContext.request = request;
		String payOBJ = PaymentFeedback.getPayment();

        List<Transaction__c> transactions = [SELECT Id, Claim_Payment__c FROM Transaction__c WHERE CR_Payment_ID__c = 'PMM01302018009'];
        PaymentFeedback.getWebHookInfo(transactions.get(0).Claim_Payment__c);
    }

}