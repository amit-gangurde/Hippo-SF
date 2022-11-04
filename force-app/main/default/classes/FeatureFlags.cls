public with sharing class FeatureFlags {

    public static FeatureFlags instance = new FeatureFlags();

    @AuraEnabled public Boolean ff_Prefer_Lead_Code_Execution_over_No_Code { get; set; }
    @AuraEnabled public Boolean ff_reSort_PSR { get; set; }
    @AuraEnabled public Boolean ff_Use_Inside_Sales_Contractor_Queue { get; set; }
    @AuraEnabled public Boolean ff_Score_11 { get; set; }
    @AuraEnabled public Boolean ff_Timezone_Routing { get; set; }
    @AuraEnabled public Boolean ff_Lead_De_Duplication_by_Code { get; set; }
    @AuraEnabled public Boolean ff_One_Campaign_per_Producer { get; set; }
    @AuraEnabled public Boolean ff_Fix_Old_Leads_Popping_Into_OmniChannel { get; set; }
    @AuraEnabled public Boolean ff_Claimatic_Claim_Triggers { get; set; }
    @AuraEnabled public Boolean ff_Timezone_bug { get; set; }
    @AuraEnabled public Boolean ff_Lead_Score_Toggling { get; set; }
    @AuraEnabled public Boolean ff_PennyMac_Leads_to_Non_Workable_Queue { get; set; }
    @AuraEnabled public Boolean ff_Underwriting_Declinations_Lead_to_HAS_Q { get; set; }
    @AuraEnabled public Boolean ff_DDup_Check_By_Existing_Policy { get; set; }
    @AuraEnabled public Boolean ff_DDup_B2C_Sales_Leads { get; set; }
    @AuraEnabled public Boolean ff_Inject_Org_to_JV_Leads { get; set; }
    @AuraEnabled public Boolean ff_Inject_Org_to_HCR_Leads { get; set; }

    public FeatureFlags() {

        ff_Prefer_Lead_Code_Execution_over_No_Code = FeatureFlags.isFeatureFlagEnabled('Prefer_Lead_Code_Execution_over_No_Code');
        ff_reSort_PSR = FeatureFlags.isFeatureFlagEnabled('reSort_PSR');
        ff_Use_Inside_Sales_Contractor_Queue = FeatureFlags.isFeatureFlagEnabled('Use_Inside_Sales_Contractor_Queue');
        ff_Score_11 = FeatureFlags.isFeatureFlagEnabled('Score_11');
        ff_Timezone_Routing = FeatureFlags.isFeatureFlagEnabled('Timezone_Routing');
        ff_Lead_De_Duplication_by_Code = FeatureFlags.isFeatureFlagEnabled('Lead_De_Duplication_by_Code');
        ff_One_Campaign_per_Producer = FeatureFlags.isFeatureFlagEnabled('One_Campaign_per_Producer');
        ff_Fix_Old_Leads_Popping_Into_OmniChannel = FeatureFlags.isFeatureFlagEnabled('Fix_Old_Leads_Popping_Into_OmniChannel');
        ff_Claimatic_Claim_Triggers = FeatureFlags.isFeatureFlagEnabled('Claimatic_Claim_Triggers');
        ff_Timezone_bug = FeatureFlags.isFeatureFlagEnabled('Timezone_bug');
        ff_Lead_Score_Toggling = FeatureFlags.isFeatureFlagEnabled('Lead_Score_Toggling');
        ff_PennyMac_Leads_to_Non_Workable_Queue = FeatureFlags.isFeatureFlagEnabled('PennyMac_Leads_to_Non_Workable_Queue');
        ff_Underwriting_Declinations_Lead_to_HAS_Q = FeatureFlags.isFeatureFlagEnabled('Underwriting_Declinations_Lead_to_HAS_Q');
        ff_DDup_Check_By_Existing_Policy = FeatureFlags.isFeatureFlagEnabled('DDup_Check_By_Existing_Policy');
        ff_DDup_B2C_Sales_Leads = FeatureFlags.isFeatureFlagEnabled('DDup_B2C_Sales_Leads');
        ff_Inject_Org_to_JV_Leads = FeatureFlags.isFeatureFlagEnabled('Inject_Org_to_JV_Leads');
        ff_Inject_Org_to_HCR_Leads = FeatureFlags.isFeatureFlagEnabled('Inject_Org_to_HCR_Leads');
    }

    public static Boolean isFeatureFlagEnabled(String feature_flag_name) {

        Boolean enabled = false;

        Features_Flags__mdt[] feature_flags = [SELECT MasterLabel, QualifiedApiName, Enabled__c FROM Features_Flags__mdt Where QualifiedApiName =: feature_flag_name];

        if ( feature_flags.size() == 1 ) {

            enabled = feature_flags[0].Enabled__c;

        }

        return enabled;
    }
}