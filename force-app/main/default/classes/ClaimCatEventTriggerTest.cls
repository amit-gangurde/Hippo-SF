@IsTest
public class ClaimCatEventTriggerTest {

    @testsetup
    public static void SetupData() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Claim clm1 = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW');
        Set<Id> claimIds = new Set<Id>{ clm1.Id };

        List<Claim> new_claims = [SELECT Id, Peril__c, State__c, Zip__c, Date_of_Loss__c FROM Claim WHERE Id IN: claimIds];
        System.assertEquals(1, new_claims.size());

        new_claims[0].Peril__c = 'Lightning';
        new_claims[0].State__c = 'MD';
        new_claims[0].Zip__c = '12345';
        new_claims[0].Date_of_Loss__c = System.now().date().addDays(-1);
        update new_claims;
    }

    @IsTest
    static void testClaimsMatching() {

        Test.startTest();
        List<Claim_Cat_Event__c> lstCCE = new List<Claim_Cat_Event__c>();
        Claim_Cat_Event__c cce1 = UnitTestHelper.prepareClaimCatEvent('Lightning', 'MD', '12345', System.now().date().addDays(-2), System.now().date(), false);
        lstCCE.add(cce1);
        insert lstCCE;

        Test.stopTest();

      	System.assertEquals(1, [SELECT Id, Claim_Cat_Event__c FROM Claim WHERE Claim_Cat_Event__c =: cce1.Id].size());
    }
}