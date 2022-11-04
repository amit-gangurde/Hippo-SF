/************************************************************************************************************************************
Author : Amit Gangurde
Description : This Test class used to cover scenario of CatEventClaimController Apex Class.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1            SFDC-2117        07/10/2022     Amit Gangurde     Initial Development
**************************************************************************************************************************************/
@isTest
public class CatEventClaimControllerTest {
    @testSetup 
    static void setup() {
        
        //prepare ClaimCatEvent data
        Claim_Cat_Event__c catEvent = UnitTestHelper.prepareClaimCatEvent('Lightning', 'IN', '12345', System.now().date().addDays(-2), System.now().date(), false);
        catEvent.status__C = 'Active';
        insert catEvent;      
        
    }
    
    static testmethod void test() {
        
        //prepare Claim data
        Claim testClaimData = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW',false);
        testClaimData.Peril__c='Lightning';
        testClaimData.Date_of_Loss__c = System.now().date().addDays(-1);
        testClaimData.State__c = 'IN';
        testClaimData.Claim_Cat_Event__c = null;
        insert testClaimData;
        
        List<Claim> claimList = [select Date_of_Loss__c,State__c,Peril__c,Claim_Cat_Event__c from Claim where Claim_Cat_Event__c = null];
        System.assertEquals(claimList.size(),0);
        
    }
}