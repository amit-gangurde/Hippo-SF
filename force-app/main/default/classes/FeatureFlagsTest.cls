@isTest
public class FeatureFlagsTest {

    @isTest static void test_FeatureFlags() {

        Boolean res1 = FeatureFlags.instance.ff_Prefer_Lead_Code_Execution_over_No_Code;
        Boolean res2 = FeatureFlags.instance.ff_reSort_PSR;
        Boolean res3 = FeatureFlags.instance.ff_Use_Inside_Sales_Contractor_Queue;
        Boolean res4 = FeatureFlags.instance.ff_Score_11;
        Boolean res5 = FeatureFlags.instance.ff_Timezone_Routing;
        Boolean res6 = FeatureFlags.instance.ff_Lead_De_Duplication_by_Code;
        Boolean res7 = FeatureFlags.instance.ff_One_Campaign_per_Producer;
        Boolean res8 = FeatureFlags.instance.ff_Fix_Old_Leads_Popping_Into_OmniChannel;
        Boolean res9 = FeatureFlags.instance.ff_Claimatic_Claim_Triggers;
        Boolean res10 = FeatureFlags.instance.ff_Timezone_bug;
        Boolean res11 = FeatureFlags.instance.ff_Lead_Score_Toggling;
        Boolean res12 = FeatureFlags.instance.ff_PennyMac_Leads_to_Non_Workable_Queue;
        Boolean res13 = FeatureFlags.instance.ff_Underwriting_Declinations_Lead_to_HAS_Q;
        Boolean res14 = FeatureFlags.instance.ff_DDup_Check_By_Existing_Policy;
        Boolean res15 = FeatureFlags.instance.ff_DDup_B2C_Sales_Leads;
        Boolean res16 = FeatureFlags.instance.ff_Inject_Org_to_JV_Leads;
        Boolean res17 = FeatureFlags.instance.ff_Inject_Org_to_HCR_Leads;
    }
}