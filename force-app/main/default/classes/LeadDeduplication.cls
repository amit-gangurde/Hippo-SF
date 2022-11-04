/*
03/12/22 - Modified class definition from 'with sharing' to 'without sharing' as part of LeadTriggerTest.testTransferPersonAccountToHasFlow, and anyway it is better to ddup logic
 */
public without sharing class LeadDeduplication {

    /*
    Method: findDuplicates (SFDC-408, 561, 570(2Do))
    Description: Look for lead duplication based on logic described in SFDC-408 and it's related Confluence product spec: https://docs.google.com/document/d/1Ocj1h612UwpXZZKHI9rvO390KPBijOBVBI9qRpLNV54/edit#
    Return: Map<Id, SObject> - The map is between a Lead Id and an SObject (polymorphic approach) that has been identified as a duplicated for this lead (hence, lead should be cancelled as duplicate)
    */
    public static Map<Id, SObject> findDuplicates(Map<Id, Lead> in_Leads) {

        Map<Id, SObject> map_LeadId2ItsDup = new Map<Id, SObject>();

        Map<String, Duplicate_Lead_Record__c> map_DuplicateLeadRecords = new Map<String, Duplicate_Lead_Record__c>();

        try {

            /*
            List<Lead> leads_in_context = [
                    SELECT  Id, FirstName, LastName, Name, Phone, MobilePhone, Email, OwnerId, CreatedDate, Lead_Source__c, Line_of_Business__c, IsJVLead__c,
                            Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, Lead_Score__c,
                            Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c
                    FROM Lead
                    WHERE Id IN:in_Leads.keySet()
            ];
             */

            /*
                * Changes for SFDC-1463: Added: Street, City, State, PostalCode, Policy_Type__c, Policy_Types__c
                * Changes for SFDC-1597: Added Is_HCR_Lead__c
            */
            List<Lead> leads_in_context = [
                    SELECT  Id, FirstName, LastName, Name, Phone, MobilePhone, Email, Street, City, State, PostalCode, OwnerId, CreatedDate, Lead_Source__c, Line_of_Business__c, IsJVLead__c,
                            Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, Lead_Score__c,
                            Non_Cat_Risk_Class__c, Non_Cat_Risk_Score__c, POD_Quote_ID__c, POD_Lead_Id__c, Organization__c, POD_Quote_Link__c, POD_Lead_Link__c,
                            Policy_Type__c, Policy_Types__c, Is_HCR_Lead__c, Last_Page_Visited__c, Quote_Type_Selection__c, Quote_Type_Selected__c, Declination_Reason__c
                    FROM Lead
                    WHERE Id IN:in_Leads.keySet()
            ];

            System.debug('findDuplicates, in_Leads: ' + in_Leads);
            System.debug('findDuplicates, in_Leads size: ' + in_Leads.size());
            System.debug('findDuplicates, leads_in_context: ' + leads_in_context);

            Set<String> lead_name_ddup_keys = new Set<String>();
            Set<String> lead_phone_ddup_keys = new Set<String>();
            Set<String> lead_mobile_ddup_keys = new Set<String>();
            Set<String> lead_email_ddup_keys = new Set<String>();

            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
            Set<String> lead_name_keys = new Set<String>();
            Set<String> lead_phone_keys = new Set<String>();
            Set<String> lead_mobile_keys = new Set<String>();
            Set<String> lead_email_keys = new Set<String>();
            Set<String> lead_street_keys = new Set<String>();
            Set<String> lead_city_keys = new Set<String>();
            Set<String> lead_state_keys = new Set<String>();
            Set<String> lead_zip_keys = new Set<String>();
            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */

            Set<String> jv_hcr_lead_name_ddup_keys = new Set<String>();
            Set<String> jv_hcr_lead_phone_ddup_keys = new Set<String>();
            Set<String> jv_hcr_lead_mobile_ddup_keys = new Set<String>();
            Set<String> jv_hcr_lead_email_ddup_keys = new Set<String>();

            for (Lead my_Lead : leads_in_context) {

                Boolean bAddedValidLead2Check = false;

                if ( LeadTriggerHandler.TESTING_INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY || /* to Unit Test 'Transfer Person Account to HAS' Flow exception with INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY */
                     String.isBlank(my_Lead.Lead_Source__c) ||
                     !my_Lead.Lead_Source__c.containsIgnoreCase('Internal Referral') ) {

                    if (String.isNotBlank(my_Lead.Name) && String.isNotBlank(my_Lead.Name_Deduplication_Key__c)) {

                        if (!my_Lead.IsJVLead__c /*&& my_Lead.Is_HCR_Lead__c == 'No'*/) {

                            lead_name_ddup_keys.add(my_Lead.Name_Deduplication_Key__c) ;
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            lead_name_keys.add(my_Lead.Name);
                            bAddedValidLead2Check = true;
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            jv_hcr_lead_name_ddup_keys.add(my_Lead.Name_Deduplication_Key__c); // SFDC-1981 as we are still ddup HCR leads with other HCR leads
                        }
                        else
                            jv_hcr_lead_name_ddup_keys.add(my_Lead.Name_Deduplication_Key__c);
                    }
                    if (String.isNotBlank(my_Lead.Phone) && String.isNotBlank(my_Lead.Phone_Deduplication_Key__c)) {

                        if (!my_Lead.IsJVLead__c /*&& my_Lead.Is_HCR_Lead__c == 'No'*/) {

                            lead_phone_ddup_keys.add(my_Lead.Phone_Deduplication_Key__c);
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            lead_phone_keys.add(my_Lead.Phone);
                            bAddedValidLead2Check = true;
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            jv_hcr_lead_phone_ddup_keys.add(my_Lead.Phone_Deduplication_Key__c); // SFDC-1981 as we are still ddup HCR leads with other HCR leads
                        }
                        else
                            jv_hcr_lead_phone_ddup_keys.add(my_Lead.Phone_Deduplication_Key__c);
                    }
                    if (String.isNotBlank(my_Lead.MobilePhone) && String.isNotBlank(my_Lead.Mobile_Deduplication_Key__c)) {

                        if (!my_Lead.IsJVLead__c /*&& my_Lead.Is_HCR_Lead__c == 'No'*/) {

                            lead_mobile_ddup_keys.add(my_Lead.Mobile_Deduplication_Key__c);
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            lead_mobile_keys.add(my_Lead.MobilePhone);
                            bAddedValidLead2Check = true;
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            jv_hcr_lead_mobile_ddup_keys.add(my_Lead.Mobile_Deduplication_Key__c); // SFDC-1981 as we are still ddup HCR leads with other HCR leads
                        }
                        else
                            jv_hcr_lead_mobile_ddup_keys.add(my_Lead.Mobile_Deduplication_Key__c);
                    }
                    if (String.isNotBlank(my_Lead.Email) && String.isNotBlank(my_Lead.Email_Deduplication_Key__c)) {

                        if (!my_Lead.IsJVLead__c /*&& my_Lead.Is_HCR_Lead__c == 'No'*/) {

                            lead_email_ddup_keys.add(my_Lead.Email_Deduplication_Key__c);
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            lead_email_keys.add(my_Lead.Email);
                            bAddedValidLead2Check = true;
                            /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                            jv_hcr_lead_email_ddup_keys.add(my_Lead.Email_Deduplication_Key__c); // SFDC-1981 as we are still ddup HCR leads with other HCR leads
                        }
                        else
                            jv_hcr_lead_email_ddup_keys.add(my_Lead.Email_Deduplication_Key__c);
                    }

                    /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                    if ( bAddedValidLead2Check ) {

                        lead_street_keys.add(my_Lead.Street);
                        lead_city_keys.add(my_Lead.City);
                        lead_state_keys.add(my_Lead.State);
                        lead_zip_keys.add(my_Lead.PostalCode);
                    }
                    /* Changes for SFDC-1463: Compare against direct lead values for Name, Phone, Mobile, Email AND Address */
                }
            }

            System.debug('lead_name_ddup_keys: ' + lead_name_ddup_keys);
            System.debug('lead_phone_ddup_keys: ' + lead_phone_ddup_keys);
            System.debug('lead_mobile_ddup_keys: ' + lead_mobile_ddup_keys);
            System.debug('lead_email_ddup_keys: ' + lead_email_ddup_keys);

            System.debug('jv_hcr_lead_name_ddup_keys: ' + jv_hcr_lead_name_ddup_keys);
            System.debug('jv_hcr_lead_phone_ddup_keys: ' + jv_hcr_lead_phone_ddup_keys);
            System.debug('jv_hcr_lead_mobile_ddup_keys: ' + jv_hcr_lead_mobile_ddup_keys);
            System.debug('jv_hcr_lead_email_ddup_keys: ' + jv_hcr_lead_email_ddup_keys);

            // Rule 1 data (SFDC-408)
            //List<InsurancePolicy> insurancePolicies = getInsurancePoliciesByLeadsSimilarity(lead_name_ddup_keys, lead_phone_ddup_keys, lead_mobile_ddup_keys, lead_email_ddup_keys);
            List<InsurancePolicy> insurancePolicies = getInsurancePoliciesByLeadsSimilarity_v2(lead_name_keys, lead_phone_keys, lead_mobile_keys, lead_email_keys, lead_street_keys, lead_city_keys, lead_state_keys, lead_zip_keys);

            // Rule 2 data (SFDC-561)
            Map<Id, Lead> map_Leads2Update = new Map<Id, Lead>();
            List<Task> lst_Tasks2Create = new List<Task>();
            Id B2C_Partner_Sales = Utils.getQueueId('B2C_Partner_Sales');
            //Id B2C_Direct_Sales = Utils.getQueueId('B2C_Direct_Sales');
            Id B2C_Direct_1 = Utils.getQueueId('B2C_Direct_1');
            Id B2C_Direct_2 = Utils.getQueueId('B2C_Direct_2');
            Id B2C_Partner_Sales_1 = Utils.getQueueId('B2C_Partner_Sales_1');
            Id B2C_Partner_Sales_2 = Utils.getQueueId('B2C_Partner_Sales_2');
            List<Lead> b2cDirectSalesAssignedLeads = getAssignedDirectSalesLeadsByLeadsSimilarity(lead_name_ddup_keys, lead_phone_ddup_keys, lead_mobile_ddup_keys, lead_email_ddup_keys);
            List<Lead> b2cPartnerSalesAssignedLeads = getAssignedPartnerSalesLeadsByLeadsSimilarity(lead_name_ddup_keys, lead_phone_ddup_keys, lead_mobile_ddup_keys, lead_email_ddup_keys);

            // Rule 3 data (SFDC-1469)
            //String JV_Leads_Seniority_InDays = Utils.getHippoSettings('JV Leads Seniority (days)');
            List<Lead> jv_hcr_LeadsDuplications = getJvHcrLeadsDuplicates_v2(jv_hcr_lead_name_ddup_keys, jv_hcr_lead_phone_ddup_keys, jv_hcr_lead_mobile_ddup_keys, jv_hcr_lead_email_ddup_keys);

            // Rule 4 data (SFDC-1463)
            List<Lead> nonJvLeadsDuplications = getAllNonJVLeads_v3(lead_name_keys, lead_phone_keys, lead_mobile_keys, lead_email_keys, lead_street_keys, lead_city_keys, lead_state_keys, lead_zip_keys);

            for (Lead my_Lead : leads_in_context) {

                Boolean skip_and_continue = false;

                if ( LeadTriggerHandler.TESTING_INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY || /* to Unit Test 'Transfer Person Account to HAS' Flow exception with INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY */
                     String.isBlank(my_Lead.Lead_Source__c) ||
                     !my_Lead.Lead_Source__c.containsIgnoreCase('Internal Referral') ) {

                    // Try to match against rule 1
                    for (InsurancePolicy insurancePolicy : insurancePolicies) {

                        if ( (my_Lead.Name_Deduplication_Key__c != null && my_Lead.Name_Deduplication_Key__c.equalsIgnoreCase(insurancePolicy.Lead_Name_Deduplication_Key__c))||
                             (String.isNotBlank(my_Lead.Phone) && my_Lead.Phone_Deduplication_Key__c != null && my_Lead.Phone_Deduplication_Key__c.equalsIgnoreCase(insurancePolicy.Lead_Phone_Deduplication_Key__c)) ||
                             (String.isNotBlank(my_Lead.MobilePhone) && my_Lead.Mobile_Deduplication_Key__c != null && my_Lead.Mobile_Deduplication_Key__c.equalsIgnoreCase(insurancePolicy.Lead_Mobile_Deduplication_Key__c)) ||
                             (String.isNotBlank(my_Lead.Email) && my_Lead.Email_Deduplication_Key__c != null && my_Lead.Email_Deduplication_Key__c.equalsIgnoreCase(insurancePolicy.Lead_Email_Deduplication_Key__c)) ) {

                            map_LeadId2ItsDup.put(my_Lead.Id, insurancePolicy);
                            skip_and_continue = true;
                            break;
                        }
                    }
                    // ========= End of business logic for rule 1 ===========================

                    if ( skip_and_continue ) continue;

                    // Try to match against rule 2
                    // 1st use case: If a lead is created and assigned to the “B2C Partner Sales Q”,
                    //                  before assigning the lead to an owner, check whether a lead for the same customer at the same property address
                    //                  has already been assigned to a B2C Direct Sales agent
                    if (String.isNotBlank(my_Lead.OwnerId) && (my_Lead.OwnerId.equals(B2C_Partner_Sales_1) || my_Lead.OwnerId.equals(B2C_Partner_Sales_2))) {

                        System.debug('DDUP RULE 2, LEAD IN PARTNER QUEUE: ' + my_Lead);
                        System.debug('DDUP RULE 2, b2cDirectSalesAssignedLeads: ' + b2cDirectSalesAssignedLeads);

                        for (Lead b2cDirectSalesAssignedLead : b2cDirectSalesAssignedLeads) {

                            if ( (my_Lead.Name_Deduplication_Key__c != null && my_Lead.Name_Deduplication_Key__c.equalsIgnoreCase(b2cDirectSalesAssignedLead.Name_Deduplication_Key__c)) ||
                                 (String.isNotBlank(my_Lead.Phone) && my_Lead.Phone_Deduplication_Key__c != null && my_Lead.Phone_Deduplication_Key__c.equalsIgnoreCase(b2cDirectSalesAssignedLead.Phone_Deduplication_Key__c)) ||
                                 (String.isNotBlank(my_Lead.MobilePhone) && my_Lead.Mobile_Deduplication_Key__c != null && my_Lead.Mobile_Deduplication_Key__c.equalsIgnoreCase(b2cDirectSalesAssignedLead.Mobile_Deduplication_Key__c)) ||
                                 (String.isNotBlank(my_Lead.Email) && my_Lead.Email_Deduplication_Key__c != null && my_Lead.Email_Deduplication_Key__c.equalsIgnoreCase(b2cDirectSalesAssignedLead.Email_Deduplication_Key__c)) ) {

                                map_LeadId2ItsDup.put(my_Lead.Id, b2cDirectSalesAssignedLead);
                                //map_Leads2Update.put(my_Lead.Id, new Lead(Id = my_Lead.Id, Dup_Parent__c = b2cDirectSalesAssignedLead.Id));
                                Duplicate_Lead_Record__c duplicateLeadRecord = createDuplicateLeadRecord(b2cDirectSalesAssignedLead, my_Lead);
                                if ( null != duplicateLeadRecord ) map_DuplicateLeadRecords.put(duplicateLeadRecord.Composite_Key__c, duplicateLeadRecord);
                                lst_Tasks2Create.add(Utils.getLeadRenewedInterestTask(my_Lead, b2cDirectSalesAssignedLead, 'Renewed Customer Interest'));
                                System.debug('DDUP RULE 2, LEAD IN PARTNER QUEUE: map_Leads2Update: ' + map_Leads2Update);
                                skip_and_continue = true;
                                break;
                            }
                        }
                    }

                    if ( skip_and_continue ) continue;

                    // 2nd use case: If a lead is created and assigned to the “B2C Direct Sales”,
                    //                  before assigning the lead to an owner, check whether a lead for the same customer at the same property address
                    //                  has already been assigned to a B2C Partner Sales Q agent
                    if (String.isNotBlank(my_Lead.OwnerId) && (my_Lead.OwnerId.equals(B2C_Direct_1) || my_Lead.OwnerId.equals(B2C_Direct_2))) {

                        System.debug('DDUP RULE 2, LEAD IN INSIDE SALES QUEUES: ' + my_Lead);
                        System.debug('DDUP RULE 2, b2cPartnerSalesAssignedLeads: ' + b2cPartnerSalesAssignedLeads);

                        for (Lead b2cPartnerSalesAssignedLead : b2cPartnerSalesAssignedLeads) {

                            if ( (my_Lead.Name_Deduplication_Key__c != null && my_Lead.Name_Deduplication_Key__c.equalsIgnoreCase(b2cPartnerSalesAssignedLead.Name_Deduplication_Key__c)) ||
                                 (String.isNotBlank(my_Lead.Phone) && my_Lead.Phone_Deduplication_Key__c != null && my_Lead.Phone_Deduplication_Key__c.equalsIgnoreCase(b2cPartnerSalesAssignedLead.Phone_Deduplication_Key__c)) ||
                                 (String.isNotBlank(my_Lead.MobilePhone) && my_Lead.Mobile_Deduplication_Key__c != null && my_Lead.Mobile_Deduplication_Key__c.equalsIgnoreCase(b2cPartnerSalesAssignedLead.Mobile_Deduplication_Key__c)) ||
                                 (String.isNotBlank(my_Lead.Email) && my_Lead.Email_Deduplication_Key__c != null && my_Lead.Email_Deduplication_Key__c.equalsIgnoreCase(b2cPartnerSalesAssignedLead.Email_Deduplication_Key__c)) ) {

                                map_LeadId2ItsDup.put(my_Lead.Id, b2cPartnerSalesAssignedLead);
                                //map_Leads2Update.put(my_Lead.Id, new Lead(Id = my_Lead.Id, Dup_Parent__c = b2cPartnerSalesAssignedLead.Id));
                                Duplicate_Lead_Record__c duplicateLeadRecord = createDuplicateLeadRecord(b2cPartnerSalesAssignedLead, my_Lead);
                                if ( null != duplicateLeadRecord ) map_DuplicateLeadRecords.put(duplicateLeadRecord.Composite_Key__c, duplicateLeadRecord);
                                lst_Tasks2Create.add(Utils.getLeadRenewedInterestTask(my_Lead, b2cPartnerSalesAssignedLead, ''));
                                System.debug('DDUP RULE 2, LEAD IN INSIDE SALES QUEUE: map_Leads2Update: ' + map_Leads2Update);
                                skip_and_continue = true;
                                break;
                            }
                        }
                    }
                }
                // ========= End of business logic for rule 2 ===========================

                if ( skip_and_continue ) continue;

                // Try to match against rule 3
                for (Lead jv_hcr_Lead : jv_hcr_LeadsDuplications) {

                    if ( my_Lead.Id != jv_hcr_Lead.Id &&
                         ((my_Lead.Line_of_Business__c == jv_hcr_Lead.Line_of_Business__c) ||
                           (
                            (String.isBlank(my_Lead.Line_of_Business__c) || my_Lead.Line_of_Business__c == 'HO3' || my_Lead.Line_of_Business__c == 'HO6') &&
                            (String.isBlank(jv_hcr_Lead.Line_of_Business__c)  || jv_hcr_Lead.Line_of_Business__c == 'HO3'  || jv_hcr_Lead.Line_of_Business__c == 'HO6')
                           )
                         ) &&
                         ( (my_Lead.Name_Deduplication_Key__c != null && my_Lead.Name_Deduplication_Key__c.equalsIgnoreCase(jv_hcr_Lead.Name_Deduplication_Key__c)) ||
                           (String.isNotBlank(my_Lead.Phone) && my_Lead.Phone_Deduplication_Key__c != null && my_Lead.Phone_Deduplication_Key__c.equalsIgnoreCase(jv_hcr_Lead.Phone_Deduplication_Key__c)) ||
                           (String.isNotBlank(my_Lead.MobilePhone) && my_Lead.Mobile_Deduplication_Key__c != null && my_Lead.Mobile_Deduplication_Key__c.equalsIgnoreCase(jv_hcr_Lead.Mobile_Deduplication_Key__c)) ||
                           (String.isNotBlank(my_Lead.Email) && my_Lead.Email_Deduplication_Key__c != null && my_Lead.Email_Deduplication_Key__c.equalsIgnoreCase(jv_hcr_Lead.Email_Deduplication_Key__c)) ) ) {

                        System.debug('JV/HCR Lead  (Existing Lead): ' + jv_hcr_Lead);
                        System.debug('my_Lead (New/Updated Lead): ' + my_Lead);

                        map_LeadId2ItsDup.put(my_Lead.Id, jv_hcr_Lead);
                        //map_Leads2Update.put(my_Lead.Id, new Lead(Id = my_Lead.Id, Dup_Parent__c = jv_hcr_Lead.Id));
                        Duplicate_Lead_Record__c duplicateLeadRecord = createDuplicateLeadRecord(jv_hcr_Lead, my_Lead);
                        if ( null != duplicateLeadRecord ) map_DuplicateLeadRecords.put(duplicateLeadRecord.Composite_Key__c, duplicateLeadRecord);
                        map_Leads2Update.put(jv_hcr_Lead.Id, mergeLeads(my_Lead, jv_hcr_Lead.Id));
                        skip_and_continue = true;
                        break;

                        /* Refactor for SFDC-1469 (Query for LAST_N_DAYS leads only so no need to calculate days between here)

                        System.debug('jvLead.CreatedDate  (Existing Lead): ' + jvLead.CreatedDate);
                        System.debug('my_Lead.CreatedDate (New Lead): ' + my_Lead.CreatedDate);
                        Integer daysBetween = jvLead.CreatedDate.date().daysBetween(my_Lead.CreatedDate.date());
                        System.debug('daysBetween: ' + daysBetween);

                        if ( daysBetween < Integer.valueOf(JV_Leads_Seniority_InDays) ) {

                            map_LeadId2ItsDup.put(my_Lead.Id, jvLead);
                            lst_Leads2Update.add(mergeJVLeads(my_Lead, jvLead.Id));
                            break;
                        }
                         */
                    }
                }
                // ========= End of business logic for rule 3 ===========================

                if ( skip_and_continue ) continue;

                // Try to match against rule 4
                for (Lead nonJvLead : nonJvLeadsDuplications) {

                    if ( my_Lead.Id == nonJvLead.Id ) continue;

                    System.debug('Comparing created lead: ' + my_Lead);
                    System.debug('To nonJvHCR lead : ' + nonJvLead);

                    String my_Lead_PolicyTypesOrLOB = my_Lead.Policy_Types__c;
                    String nonJvLead_PolicyTypesOrLOBIsHO = nonJvLead.Policy_Types__c;

                    // OR between my_Lead.Policy_Types__c AND my_Lead.Line_of_Business__c
                    if ( !(String.isBlank(my_Lead.Line_of_Business__c) || (String.isNotBlank(my_Lead.Line_of_Business__c) && (my_Lead.Line_of_Business__c.containsIgnoreCase('HO3') || my_Lead.Line_of_Business__c.containsIgnoreCase('HO6')))) ) {

                        if ( !(String.isBlank(my_Lead_PolicyTypesOrLOB) || (String.isNotBlank(my_Lead_PolicyTypesOrLOB) && (my_Lead_PolicyTypesOrLOB.containsIgnoreCase('HO3') || my_Lead_PolicyTypesOrLOB.containsIgnoreCase('HO6')))) ) {

                            my_Lead_PolicyTypesOrLOB += my_Lead.Line_of_Business__c; // in case Policy_Types__c AND LOB has different, non-HO related, values then concat them to avoid duplication flagging
                        }
                        else {

                            my_Lead_PolicyTypesOrLOB = my_Lead.Line_of_Business__c; // LK: What if Line_of_Business__c != Policy_Types__c and not HO --> See above IF condition for that use case
                        }
                    }

                    System.debug('my_Lead_PolicyTypesOrLOB: ' + my_Lead_PolicyTypesOrLOB);

                    // OR between nonJvLead.Policy_Types__c AND nonJvLead.Line_of_Business__c
                    if ( !(String.isBlank(nonJvLead.Line_of_Business__c) || (String.isNotBlank(nonJvLead.Line_of_Business__c) && (nonJvLead.Line_of_Business__c.containsIgnoreCase('HO3') || nonJvLead.Line_of_Business__c.containsIgnoreCase('HO6')))) ) {

                        if ( !(String.isBlank(nonJvLead_PolicyTypesOrLOBIsHO) || (String.isNotBlank(nonJvLead_PolicyTypesOrLOBIsHO) && (nonJvLead_PolicyTypesOrLOBIsHO.containsIgnoreCase('HO3') || nonJvLead_PolicyTypesOrLOBIsHO.containsIgnoreCase('HO6')))) ) {

                            nonJvLead_PolicyTypesOrLOBIsHO += nonJvLead.Line_of_Business__c; // in case Policy_Types__c AND LOB has different, non-HO related, values then concat them to avoid duplication flagging
                        }
                        else {

                            nonJvLead_PolicyTypesOrLOBIsHO = nonJvLead.Line_of_Business__c; // LK: What if Line_of_Business__c != Policy_Types__c and not HO --> See above IF condition for that use case
                        }
                    }

                    System.debug('nonJvLead_PolicyTypesOrLOBIsHO: ' + nonJvLead_PolicyTypesOrLOBIsHO);

                    if ( my_Lead.Id != nonJvLead.Id &&
                         (((my_Lead_PolicyTypesOrLOB == nonJvLead_PolicyTypesOrLOBIsHO) ||
                           (
                            ((String.isBlank(my_Lead_PolicyTypesOrLOB) || my_Lead_PolicyTypesOrLOB == 'HO3' || my_Lead_PolicyTypesOrLOB == 'HO6') &&
                            (String.isBlank(nonJvLead_PolicyTypesOrLOBIsHO)  || nonJvLead_PolicyTypesOrLOBIsHO == 'HO3'  || nonJvLead_PolicyTypesOrLOBIsHO == 'HO6'))
                           )
                         ))
                         &&
                         ( (my_Lead.Name_Deduplication_Key__c != null && my_Lead.Name_Deduplication_Key__c.equalsIgnoreCase(nonJvLead.Name_Deduplication_Key__c)) ||
                           (String.isNotBlank(my_Lead.Phone) && my_Lead.Phone_Deduplication_Key__c != null && my_Lead.Phone_Deduplication_Key__c.equalsIgnoreCase(nonJvLead.Phone_Deduplication_Key__c)) ||
                           (String.isNotBlank(my_Lead.MobilePhone) && my_Lead.Mobile_Deduplication_Key__c != null && my_Lead.Mobile_Deduplication_Key__c.equalsIgnoreCase(nonJvLead.Mobile_Deduplication_Key__c)) ||
                           (String.isNotBlank(my_Lead.Email) && my_Lead.Email_Deduplication_Key__c != null && my_Lead.Email_Deduplication_Key__c.equalsIgnoreCase(nonJvLead.Email_Deduplication_Key__c)) ) ) {

                        System.debug('Non-JV Lead  (Existing Lead): ' + nonJvLead);
                        System.debug('my_Lead (New/Updated Lead): ' + my_Lead);

                        map_LeadId2ItsDup.put(my_Lead.Id, nonJvLead);
                        //map_Leads2Update.put(my_Lead.Id, new Lead(Id = my_Lead.Id, Dup_Parent__c = nonJvLead.Id));
                        if ( my_Lead.Is_HCR_Lead__c == 'No' ) { // HCR Leads merge happens in the trigger level in findDuplicates so only there we can know how is the parent and who is the dup
                            Duplicate_Lead_Record__c duplicateLeadRecord = createDuplicateLeadRecord(nonJvLead, my_Lead);
                            if (null != duplicateLeadRecord) map_DuplicateLeadRecords.put(duplicateLeadRecord.Composite_Key__c, duplicateLeadRecord);
                        }
                        break;
                    }
                }
                // ========= End of business logic for rule 4 ===========================
            }

            // Rule 2 related CRUD's (keep references from dup leads to their original parent and create tasks for agents)
            if ( map_Leads2Update.size() > 0 ) {

                System.debug('Keeping references from duplicate leads to their parents: ' + map_Leads2Update);
                LeadTriggerHandler.SKIP_RECURSION = true;
                Database.DMLOptions dml = new Database.DMLOptions();
                // Didn't work. SR results still contain 'Duplicate!' alert and record not updated. Had to modify 'Lead Anti-Dupe' duplication rule to 'Allow' on Edit and 'Alert' on Edit
                // NEED TO OPEN A SUPPORT TICKET (WHEN PREMIER SUPPORT WILL BE AVAILABLE!!!)
                dml.DuplicateRuleHeader.allowSave = true;
                dml.DuplicateRuleHeader.runAsCurrentUser = true;
                List<Database.SaveResult> sr = Database.update(map_Leads2Update.values(), dml);
                System.debug('sr: ' + sr);
                //update map_Leads2Update.values();
                LeadTriggerHandler.SKIP_RECURSION = false;
            }

            if ( map_DuplicateLeadRecords.size() > 0 ) {

                System.debug('Creating junction records for lead duplications: ' + map_DuplicateLeadRecords);
                upsert map_DuplicateLeadRecords.values() Composite_Key__c;
            }

            if ( lst_Tasks2Create.size() > 0 ) {

                System.debug('Creating tasks for duplicate leads management: ' + lst_Tasks2Create);
                insert lst_Tasks2Create;
            }
            // ===========================================================================

        } catch (Exception ex) {

            System.debug('Exception from findDuplicates execution: ' + ex.getMessage());
            System.debug('Exception from findDuplicates, stack trace: ' + ex.getStackTraceString());
            System.debug('Exception from findDuplicates, line number: ' + ex.getLineNumber());
            System.debug('Exception from findDuplicates, inaccessible fields: ' + ex.getInaccessibleFields());
            System.debug('Exception from findDuplicates, cause: ' + ex.getCause());
        }

        System.debug('map_LeadId2ItsDup: ' + map_LeadId2ItsDup);

        return map_LeadId2ItsDup;
    }

    /*
    Method: getInsurancePoliciesByLeadsSimilarity (SFDC-408)
    Description: Get InsurancePolicy record set by similarity to other leads by specific context of name, phone, mobile or email
    Return: List<InsurancePolicy> - Trivial
    */
    private static List<InsurancePolicy> getInsurancePoliciesByLeadsSimilarity(Set<String> lead_name_ddup_keys, Set<String> lead_phone_ddup_keys, Set<String> lead_mobile_ddup_keys, Set<String> lead_email_ddup_keys) {

        List<InsurancePolicy> insurancePolicies = new List<InsurancePolicy>();

        if ( FeatureFlags.instance.ff_DDup_Check_By_Existing_Policy ) {

            insurancePolicies = [
                    SELECT Id, Status, Lead_Name_Deduplication_Key__c, Lead_Phone_Deduplication_Key__c, Lead_Mobile_Deduplication_Key__c, Lead_Email_Deduplication_Key__c
                    FROM InsurancePolicy
                    WHERE Status IN ('Active', 'Pending Active')
                    AND (Lead_Name_Deduplication_Key__c IN:lead_name_ddup_keys
                    OR Lead_Phone_Deduplication_Key__c IN:lead_phone_ddup_keys
                    OR Lead_Mobile_Deduplication_Key__c IN:lead_mobile_ddup_keys
                    OR Lead_Email_Deduplication_Key__c IN:lead_email_ddup_keys)
            ];
        }

        System.debug('insurancePolicies: ' + insurancePolicies);

        return insurancePolicies;
    }

    /*
    Method: getInsurancePoliciesByLeadsSimilarity_v2 (SFDC-408), added V2 (To fix non-selective query exception)
    Description: Get InsurancePolicy record set by similarity to other leads by specific context of name, phone, mobile or email
    Return: List<InsurancePolicy> - Trivial
    */
    private static List<InsurancePolicy> getInsurancePoliciesByLeadsSimilarity_v2(Set<String> lead_name_keys, Set<String> lead_phone_keys, Set<String> lead_mobile_keys, Set<String> lead_email_keys, Set<String> lead_street_keys, Set<String> lead_city_keys, Set<String> lead_state_keys, Set<String> lead_zip_keys) {

        List<InsurancePolicy> insurancePolicies = new List<InsurancePolicy>();

        if ( FeatureFlags.instance.ff_DDup_Check_By_Existing_Policy ) {

            /*
            insurancePolicies = [
                    SELECT Id, Status, Lead_Name_Deduplication_Key__c, Lead_Phone_Deduplication_Key__c, Lead_Mobile_Deduplication_Key__c, Lead_Email_Deduplication_Key__c, NameInsured.Name, NameInsured.Phone, NameInsured.PersonMobilePhone, NameInsured.PersonEmail
                    FROM InsurancePolicy
                    WHERE Status IN ('Active', 'Pending Active')
                    AND ( (NameInsured.Name IN:lead_name_keys AND Street__c IN:lead_street_keys AND City__c IN:lead_city_keys AND State__c IN:lead_state_keys AND Zip__c IN:lead_zip_keys)
                    OR (NameInsured.Phone IN:lead_phone_keys AND Street__c IN:lead_street_keys AND City__c IN:lead_city_keys AND State__c IN:lead_state_keys AND Zip__c IN:lead_zip_keys)
                    OR (NameInsured.PersonMobilePhone IN:lead_mobile_keys AND Street__c IN:lead_street_keys AND City__c IN:lead_city_keys AND State__c IN:lead_state_keys AND Zip__c IN:lead_zip_keys)
                    OR (NameInsured.PersonEmail IN:lead_email_keys AND Street__c IN:lead_street_keys AND City__c IN:lead_city_keys AND State__c IN:lead_state_keys AND Zip__c IN:lead_zip_keys) )
            ];
             */

            insurancePolicies = [
                    SELECT Id, Status, Lead_Name_Deduplication_Key__c, Lead_Phone_Deduplication_Key__c, Lead_Mobile_Deduplication_Key__c, Lead_Email_Deduplication_Key__c, NameInsured.Name, NameInsured.Phone, NameInsured.PersonMobilePhone, NameInsured.PersonEmail
                    FROM InsurancePolicy
                    WHERE Status IN ('Active', 'Pending Active')
                    AND ( (NameInsured.Name IN:lead_name_keys OR NameInsured.Phone IN:lead_phone_keys OR NameInsured.PersonMobilePhone IN:lead_mobile_keys OR NameInsured.PersonEmail IN:lead_email_keys)
                           AND (Street__c IN:lead_street_keys AND City__c IN:lead_city_keys AND State__c IN:lead_state_keys AND Zip__c IN:lead_zip_keys) )
            ];
        }

        System.debug('insurancePolicies: ' + insurancePolicies);

        return insurancePolicies;
    }

    /*
    Method: getDirectSalesQueueAgents (SFDC-561)
    Description: Get a set of user ids which are members of B2C Direct Sales Q
    Return: Set<Id> - Trivial
    */
    private static Set<Id> getDirectSalesQueueAgents() {

        Set<Id> b2cDirectSalesAssignedUsers = new Set<Id>();

        try {

            Map<String, Set<Id>> map_Group2ActiveUsers = Utils.groupDeveloperNameAndTypeToActiveUserIds;
            //System.debug('map_Group2ActiveUsers: ' + map_Group2ActiveUsers);

            //Set<Id> directSalesQueueUserIds = map_Group2ActiveUsers.get('B2C Direct Sales Q-Queue');
            //Set<Id> directSalesQueueUserIds = map_Group2ActiveUsers.get('B2C_Direct_Sales-Queue');
            //System.debug('directSalesQueueUserIds: ' + directSalesQueueUserIds);

            Set<Id> directSales1QueueUserIds = map_Group2ActiveUsers.get('B2C_Direct_1-Queue');
            System.debug('directSales1QueueUserIds: ' + directSales1QueueUserIds);
            Set<Id> directSales2QueueUserIds = map_Group2ActiveUsers.get('B2C_Direct_2-Queue');
            System.debug('directSales2QueueUserIds: ' + directSales2QueueUserIds);

            if (null != directSales1QueueUserIds) {

                b2cDirectSalesAssignedUsers.addAll(directSales1QueueUserIds);
            }
            if (null != directSales2QueueUserIds) {

                b2cDirectSalesAssignedUsers.addAll(directSales2QueueUserIds);
            }

            if ( Test.isRunningTest() ) b2cDirectSalesAssignedUsers.add(UserInfo.getUserId());

            System.debug('b2cDirectSalesAssignedUsers: ' + b2cDirectSalesAssignedUsers);

        } catch (Exception ex) {

            System.debug('Exception from getDirectSalesQueueAgents execution: ' + ex.getMessage());
        }

        return b2cDirectSalesAssignedUsers;
    }

    /*
    Method: getPartnerSalesQueueAgents (SFDC-561)
    Description: Get a set of user ids which are members of B2C Partner Sales Q
    Return: Set<Id> - Trivial
    */
    private static Set<Id> getPartnerSalesQueueAgents() {

        Set<Id> b2cPartnerSalesAssignedUsers = new Set<Id>();

        try {

            Map<String, Set<Id>> map_Group2ActiveUsers = Utils.groupDeveloperNameAndTypeToActiveUserIds;

            //Set<Id> partnerSalesQueueUserIds = map_Group2ActiveUsers.get('B2C Partner Sales-Queue');
            Set<Id> partnerSalesQueueUserIds = map_Group2ActiveUsers.get('B2C_Partner_Sales-Queue');

            Set<Id> partnerSales1QueueUserIds = map_Group2ActiveUsers.get('B2C_Partner_Sales_1-Queue');
            System.debug('partnerSales1QueueUserIds: ' + partnerSales1QueueUserIds);
            Set<Id> partnerSales2QueueUserIds = map_Group2ActiveUsers.get('B2C_Partner_Sales_2-Queue');
            System.debug('partnerSales2QueueUserIds: ' + partnerSales2QueueUserIds);

            if (null != partnerSalesQueueUserIds) {

                b2cPartnerSalesAssignedUsers.addAll(partnerSalesQueueUserIds);
            }
            if (null != partnerSales1QueueUserIds) {

                b2cPartnerSalesAssignedUsers.addAll(partnerSales1QueueUserIds);
            }
            if (null != partnerSales2QueueUserIds) {

                b2cPartnerSalesAssignedUsers.addAll(partnerSales2QueueUserIds);
            }

            if ( Test.isRunningTest() ) b2cPartnerSalesAssignedUsers.add(UserInfo.getUserId());

            System.debug('b2cPartnerSalesAssignedUsers: ' + b2cPartnerSalesAssignedUsers);

        } catch (Exception ex) {

            System.debug('Exception from getPartnerSalesQueueAgents execution: ' + ex.getMessage());
        }

        return b2cPartnerSalesAssignedUsers;
    }

    /*
    Method: getAssignedDirectSalesLeadsByLeadsSimilarity (SFDC-561)
    Description: Get list of leads assigned to members of B2C Direct Sales Q and have similarity to other leads by specific context of name, phone, mobile or email
    Return: Set<Id> - Trivial
    */
    private static List<Lead> getAssignedDirectSalesLeadsByLeadsSimilarity(Set<String> lead_name_ddup_keys, Set<String> lead_phone_ddup_keys, Set<String> lead_mobile_ddup_keys, Set<String> lead_email_ddup_keys) {

        Set<Id> b2cDirectSalesAssignedUsers = getDirectSalesQueueAgents();
        System.debug('b2cDirectSalesAssignedUsers === ' + b2cDirectSalesAssignedUsers);
        Set<String> nonJVRecordTypes = Utils.getLeadNonJVRecordTypes();
        System.debug('nonJVRecordTypes === ' + nonJVRecordTypes);

        List<Lead> b2cDirectSalesAssignedLeads = [SELECT Id, OwnerId, Name, MobilePhone, Phone, Email, Street, City, State, PostalCode, Status, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, IsJVLead__c, Is_HCR_Lead__c, Lead_Source__c, Declination_Reason__c
                                                  FROM Lead
                                                  //WHERE RecordType.DeveloperName IN: nonJVRecordTypes AND OwnerId IN: (Test.isRunningTest() ? new Set<Id>{UserInfo.getUserId()} : b2cDirectSalesAssignedUsers)
                                                  WHERE RecordType.DeveloperName IN: nonJVRecordTypes AND OwnerId IN: b2cDirectSalesAssignedUsers
                                                  AND Status = 'Working'
                                                  AND (Name_Deduplication_Key__c IN: lead_name_ddup_keys
                                                  OR Phone_Deduplication_Key__c IN: lead_phone_ddup_keys
                                                  OR Mobile_Deduplication_Key__c IN: lead_mobile_ddup_keys
                                                  OR Email_Deduplication_Key__c IN: lead_email_ddup_keys)];

        if ( b2cDirectSalesAssignedLeads.size() == 0 && Test.isRunningTest() ) {

            b2cDirectSalesAssignedLeads = [SELECT Id, OwnerId, Name, MobilePhone, Phone, Email, Street, City, State, PostalCode, Status, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, IsJVLead__c, Is_HCR_Lead__c, Lead_Source__c, Declination_Reason__c
                                           FROM Lead
                                           WHERE RecordType.DeveloperName IN: nonJVRecordTypes
                                           AND Status = 'Working'
                                           AND (Name_Deduplication_Key__c IN: lead_name_ddup_keys
                                           OR Phone_Deduplication_Key__c IN: lead_phone_ddup_keys
                                           OR Mobile_Deduplication_Key__c IN: lead_mobile_ddup_keys
                                           OR Email_Deduplication_Key__c IN: lead_email_ddup_keys)];
        }

        System.debug('b2cDirectSalesAssignedLeads === ' + b2cDirectSalesAssignedLeads);



        return b2cDirectSalesAssignedLeads;
    }

    /*
    Method: getAssignedPartnerSalesLeadsByLeadsSimilarity (SFDC-561)
    Description: Get list of leads assigned to members of B2C Partner Sales Q and have similarity to other leads by specific context of name, phone, mobile or email
    Return: Set<Id> - Trivial
    */
    private static List<Lead> getAssignedPartnerSalesLeadsByLeadsSimilarity(Set<String> lead_name_ddup_keys, Set<String> lead_phone_ddup_keys, Set<String> lead_mobile_ddup_keys, Set<String> lead_email_ddup_keys) {

        Set<Id> b2cPartnerSalesAssignedUsers = getPartnerSalesQueueAgents();
        System.debug('b2cPartnerSalesAssignedUsers === ' + b2cPartnerSalesAssignedUsers);
        Set<String> nonJVRecordTypes = Utils.getLeadNonJVRecordTypes();
        System.debug('nonJVRecordTypes === ' + nonJVRecordTypes);

        List<Lead> b2cPartnerSalesAssignedLeads = [SELECT Id, OwnerId, Name, MobilePhone, Phone, Email, Street, City, State, PostalCode, Status, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, IsJVLead__c, Is_HCR_Lead__c, Lead_Source__c, Declination_Reason__c
                                                   FROM Lead
                                                   //WHERE RecordType.DeveloperName IN: nonJVRecordTypes AND OwnerId IN: (Test.isRunningTest() ? new Set<Id>{UserInfo.getUserId()} : b2cPartnerSalesAssignedUsers)
                                                   WHERE RecordType.DeveloperName IN: nonJVRecordTypes AND OwnerId IN: b2cPartnerSalesAssignedUsers
                                                   AND Status = 'Working'
                                                   AND (Name_Deduplication_Key__c IN: lead_name_ddup_keys
                                                   OR Phone_Deduplication_Key__c IN: lead_phone_ddup_keys
                                                   OR Mobile_Deduplication_Key__c IN: lead_mobile_ddup_keys
                                                   OR Email_Deduplication_Key__c IN: lead_email_ddup_keys)];

        if ( b2cPartnerSalesAssignedLeads.size() == 0 && Test.isRunningTest() ) {

            b2cPartnerSalesAssignedLeads = [SELECT Id, OwnerId, Name, MobilePhone, Phone, Email, Street, City, State, PostalCode, Status, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, IsJVLead__c, Is_HCR_Lead__c, Lead_Source__c, Declination_Reason__c
                                            FROM Lead
                                            WHERE RecordType.DeveloperName IN: nonJVRecordTypes
                                            AND Status = 'Working'
                                            AND (Name_Deduplication_Key__c IN: lead_name_ddup_keys
                                            OR Phone_Deduplication_Key__c IN: lead_phone_ddup_keys
                                            OR Mobile_Deduplication_Key__c IN: lead_mobile_ddup_keys
                                            OR Email_Deduplication_Key__c IN: lead_email_ddup_keys)];
        }

        System.debug('b2cPartnerSalesAssignedLeads === ' + b2cPartnerSalesAssignedLeads);

        return b2cPartnerSalesAssignedLeads;
    }

    /*
    Method: getJvHcrLeadsDuplicates (SFDC-1469)
    Description: Get JV/HCR Leads record set by similarity to other leads by specific context of name, phone, mobile or email AND line of business
    Return: List<Lead> - Trivial
    Change Log: Modified for SFDC-1597: Added Is_HCR_Lead__c to support HCR leads which could come as B2C Sales record type. moved to dynamic query to use LAST_N_DAYS
    */
    /*
    private static List<Lead> getJvHcrLeadsDuplicates(Set<String> jv_hcr_lead_name_ddup_keys, Set<String> jv_hcr_lead_phone_ddup_keys, Set<String> jv_hcr_lead_mobile_ddup_keys, Set<String> jv_hcr_lead_email_ddup_keys) {

        List<Lead> jv_hcr_Leads = new List<Lead>();

        String JV_Leads_Seniority_InDays = Utils.getHippoSettings('JV Leads Seniority (days)');

        if (jv_hcr_lead_name_ddup_keys.size() == 0) jv_hcr_lead_name_ddup_keys.add('');
        if (jv_hcr_lead_phone_ddup_keys.size() == 0) jv_hcr_lead_phone_ddup_keys.add('');
        if (jv_hcr_lead_mobile_ddup_keys.size() == 0) jv_hcr_lead_mobile_ddup_keys.add('');
        if (jv_hcr_lead_email_ddup_keys.size() == 0) jv_hcr_lead_email_ddup_keys.add('');

        String query = 'SELECT Id, FirstName, LastName, Name, Phone, MobilePhone, Email, OwnerId, Owner.Name, Status, IsJVLead__c, Is_HCR_Lead__c, Line_of_Business__c, UTM_Source__c, POD_Lead_Id__c, Lead_Source__c, Declination_Reason__c, ' +
                        'CreatedDate, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, Last_Page_Visited__c, Quote_Type_Selection__c, Quote_Type_Selected__c FROM Lead WHERE ' +
                        'Status IN (\'New\', \'Working\', \'Bound\', \'Quoted\') ' +
                        'AND (IsJVLead__c = TRUE OR Is_HCR_Lead__c = \'Yes\') AND CreatedDate = LAST_N_DAYS:' + JV_Leads_Seniority_InDays + ' ' +
                        'AND (Name_Deduplication_Key__c IN: jv_hcr_lead_name_ddup_keys ' +
                        'OR Phone_Deduplication_Key__c IN: jv_hcr_lead_phone_ddup_keys ' +
                        'OR Mobile_Deduplication_Key__c IN: jv_hcr_lead_mobile_ddup_keys ' +
                        'OR Email_Deduplication_Key__c IN: jv_hcr_lead_email_ddup_keys)';


        System.debug('getJvHcrLeadsDuplicates, query: ' + query);

        try {

            jv_hcr_Leads = Database.query(query);

        }
        catch (Exception ex) {

            System.debug('getJvHcrLeadsDuplicates Exception === ');
            System.debug(ex);
        }

        System.debug('jv_hcr_Leads: ' + jv_hcr_Leads);

        return jv_hcr_Leads;
    }
     */

    /*
    Method: getJvHcrLeadsDuplicates_v2 (SFDC-1469)
    Description: Get JV/HCR Leads record set by similarity to other leads by specific context of name, phone, mobile or email AND line of business
    Return: List<Lead> - Trivial
    Change Log: Modified for SFDC-1597: Added Is_HCR_Lead__c to support HCR leads which could come as B2C Sales record type. moved to dynamic query to use LAST_N_DAYS
    */
    private static List<Lead> getJvHcrLeadsDuplicates_v2(Set<String> jv_hcr_lead_name_ddup_keys, Set<String> jv_hcr_lead_phone_ddup_keys, Set<String> jv_hcr_lead_mobile_ddup_keys, Set<String> jv_hcr_lead_email_ddup_keys) {

        List<Lead> jv_hcr_Leads = new List<Lead>();

        String JV_Leads_Seniority_InDays = Utils.getHippoSettings('JV Leads Seniority (days)');

        String query = 'SELECT Id, FirstName, LastName, Name, Phone, MobilePhone, Email, OwnerId, Owner.Name, Status, IsJVLead__c, Is_HCR_Lead__c, Line_of_Business__c, UTM_Source__c, POD_Lead_Id__c, Lead_Source__c, Declination_Reason__c, ' +
                'CreatedDate, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, Last_Page_Visited__c, Quote_Type_Selection__c, Quote_Type_Selected__c FROM Lead WHERE ' +
                'Status IN (\'New\', \'Working\', \'Bound\', \'Quoted\') ' +
                'AND (IsJVLead__c = TRUE OR Is_HCR_Lead__c = \'Yes\') AND CreatedDate = LAST_N_DAYS:' + JV_Leads_Seniority_InDays + ' ' +
                'AND (';

        Boolean has_valid_filters = false;

        if ( jv_hcr_lead_name_ddup_keys.size() > 0 ) {

            query += 'Name_Deduplication_Key__c IN:jv_hcr_lead_name_ddup_keys';
            has_valid_filters = true;
        }

        if ( jv_hcr_lead_phone_ddup_keys.size() > 0 ) {

            if ( has_valid_filters ) {
                query += ' OR Phone_Deduplication_Key__c IN:jv_hcr_lead_phone_ddup_keys';
            }
            else {
                query += 'Phone_Deduplication_Key__c IN:jv_hcr_lead_phone_ddup_keys';
                has_valid_filters = true;
            }
        }

        if ( jv_hcr_lead_mobile_ddup_keys.size() > 0 ) {

            if ( has_valid_filters ) {
                query += ' OR Mobile_Deduplication_Key__c IN:jv_hcr_lead_mobile_ddup_keys';
            }
            else {
                query += 'Mobile_Deduplication_Key__c IN:jv_hcr_lead_mobile_ddup_keys';
                has_valid_filters = true;
            }
        }

        if ( jv_hcr_lead_email_ddup_keys.size() > 0 ) {

            if ( has_valid_filters ) {
                query += ' OR Email_Deduplication_Key__c IN:jv_hcr_lead_email_ddup_keys';
            }
            else {
                query += 'Email_Deduplication_Key__c IN:jv_hcr_lead_email_ddup_keys';
                has_valid_filters = true;
            }
        }

        //'Name_Deduplication_Key__c IN: jv_hcr_lead_name_ddup_keys ' +
        //'OR Phone_Deduplication_Key__c IN: jv_hcr_lead_phone_ddup_keys ' +
        //'OR Mobile_Deduplication_Key__c IN: jv_hcr_lead_mobile_ddup_keys ' +
        //'OR Email_Deduplication_Key__c IN: jv_hcr_lead_email_ddup_keys' +

        query += ')';

        System.debug('getJvHcrLeadsDuplicates_v2, query: ' + query);

        try {

            if ( has_valid_filters ) { // indication that there are valid filter conditions in the query

                jv_hcr_Leads = Database.query(query);
            }

        }
        catch (Exception ex) {

            System.debug('getJvHcrLeadsDuplicates_v2 Exception === ');
            System.debug(ex);
        }

        /*
        List<Lead> jvLeads = [SELECT Id, FirstName, LastName, Name, Phone, MobilePhone, Email, OwnerId, Owner.Name, Status, IsJVLead__c, Line_of_Business__c, UTM_Source__c,
                                     CreatedDate, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c
                              FROM Lead
                              WHERE Status IN ('New', 'Working', 'Bound')
                              AND (IsJVLead__c = TRUE OR Is_HCR_Lead__c = 'Yes') AND CreatedDate = LAST_N_DAYS:30
                              AND (Name_Deduplication_Key__c IN: jv_lead_name_ddup_keys
                              OR Phone_Deduplication_Key__c IN: jv_lead_phone_ddup_keys
                              OR Mobile_Deduplication_Key__c IN: jv_lead_mobile_ddup_keys
                              OR Email_Deduplication_Key__c IN: jv_lead_email_ddup_keys)
                             ];
         */

        System.debug('jv_hcr_Leads: ' + jv_hcr_Leads);

        return jv_hcr_Leads;
    }

    private static Lead mergeLeads(Lead source_lead, Id target_lead_id) {

        Lead target_lead = new Lead(Id = target_lead_id);

        target_lead.Lead_Score__c = source_lead.Lead_Score__c;
        target_lead.Non_Cat_Risk_Class__c = source_lead.Non_Cat_Risk_Class__c;
        target_lead.Non_Cat_Risk_Score__c = source_lead.Non_Cat_Risk_Score__c;
        target_lead.POD_Quote_ID__c = source_lead.POD_Quote_ID__c;
        target_lead.POD_Lead_Id__c = source_lead.POD_Lead_Id__c;
        target_lead.Organization__c = source_lead.Organization__c;
        target_lead.Lead_Source__c = source_lead.Lead_Source__c;
        if ( String.isNotBlank(source_lead.Declination_Reason__c) ) target_lead.Declination_Reason__c = source_lead.Declination_Reason__c;

        //target_lead.POD_Quote_Link__c = source_lead.POD_Quote_Link__c; // formula
        //target_lead.POD_Lead_Link__c = source_lead.POD_Lead_Link__c; // formula

        System.debug('mergeJVLeads, source_lead: ' + source_lead);
        System.debug('mergeJVLeads, target_lead: ' + target_lead);

        return target_lead;
    }

    /*
    Method: getAllNonJVLeads_v1 (SFDC-1463)
    Description: Get list of all non jv leads and have similarity to other leads by specific context of name, phone, mobile or email AND policy type
    Return: List<Lead> - Trivial
    */
    /*
    private static List<Lead> getAllNonJVLeads_v1(Set<String> lead_name_ddup_keys, Set<String> lead_phone_ddup_keys, Set<String> lead_mobile_ddup_keys, Set<String> lead_email_ddup_keys) {

        List<Lead> nonJvHcrLeads = new List<Lead>();

        if ( FeatureFlags.instance.ff_DDup_B2C_Sales_Leads ) {

            String JV_Leads_Seniority_InDays = Utils.getHippoSettings('JV Leads Seniority (days)');

            Set<String> nonJVRecordTypes = Utils.getLeadNonJVRecordTypes();
            System.debug('nonJVRecordTypes === ' + nonJVRecordTypes);

            if (lead_name_ddup_keys.size() == 0) lead_name_ddup_keys.add('');
            if (lead_phone_ddup_keys.size() == 0) lead_phone_ddup_keys.add('');
            if (lead_mobile_ddup_keys.size() == 0) lead_mobile_ddup_keys.add('');
            if (lead_email_ddup_keys.size() == 0) lead_email_ddup_keys.add('');

            String query = 'SELECT Id, FirstName, LastName, Name, Phone, MobilePhone, Email, PostalCode, OwnerId, Owner.Name, Status, IsJVLead__c, Line_of_Business__c, UTM_Source__c, Is_HCR_Lead__c, ' +
                    'CreatedDate, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, Policy_Types__c, Lead_Source__c FROM Lead WHERE ' +
                    'Status IN (\'New\', \'Working\', \'Converted\', \'Cancelled\', \'Closed\', \'Bound\') ' +
                    'AND IsJVLead__c = FALSE AND Is_HCR_Lead__c = \'No\' AND RecordType.DeveloperName IN: nonJVRecordTypes AND CreatedDate = LAST_N_DAYS:' + JV_Leads_Seniority_InDays + ' ' +
                    'AND (Name_Deduplication_Key__c IN: lead_name_ddup_keys ' +
                    'OR Phone_Deduplication_Key__c IN: lead_phone_ddup_keys ' +
                    'OR Mobile_Deduplication_Key__c IN: lead_mobile_ddup_keys ' +
                    'OR Email_Deduplication_Key__c IN: lead_email_ddup_keys)';

            System.debug('getAllNonJVLeads_v1, query: ' + query);

            try {

                nonJvHcrLeads = Database.query(query);

            }
            catch (Exception ex) {

                System.debug('getAllNonJVLeads_v1 Exception === ');
                System.debug(ex);
            }
        }

        System.debug('nonJvHcrLeads: ' + nonJvHcrLeads);

        return nonJvHcrLeads;
    }
     */

    /*
    Method: getAllNonJVLeads_v2 (SFDC-1463)
    Description: Get list of all non jv leads and have similarity to other leads by specific context of name, phone, mobile or email AND policy type
    Return: List<Lead> - Trivial
    */
    /*
    private static List<Lead> getAllNonJVLeads_v2(Set<String> lead_name_keys, Set<String> lead_phone_keys, Set<String> lead_mobile_keys, Set<String> lead_email_keys, Set<String> lead_street_keys, Set<String> lead_city_keys, Set<String> lead_state_keys, Set<String> lead_zip_keys) {

        List<Lead> nonJvHcrLeads = new List<Lead>();

        if ( FeatureFlags.instance.ff_DDup_B2C_Sales_Leads ) {

            String JV_Leads_Seniority_InDays = Utils.getHippoSettings('JV Leads Seniority (days)');
            System.debug('getAllNonJVLeads_v2::JV_Leads_Seniority_InDays === ' + JV_Leads_Seniority_InDays);

            Set<String> nonJVRecordTypes = Utils.getLeadNonJVRecordTypes();
            System.debug('nonJVRecordTypes === ' + nonJVRecordTypes);

            System.debug('lead_name_keys === ' + lead_name_keys);
            System.debug('lead_phone_keys === ' + lead_phone_keys);
            System.debug('lead_mobile_keys === ' + lead_mobile_keys);
            System.debug('lead_email_keys === ' + lead_email_keys);
            System.debug('lead_street_keys === ' + lead_street_keys);
            System.debug('lead_city_keys === ' + lead_city_keys);
            System.debug('lead_state_keys === ' + lead_state_keys);
            System.debug('lead_zip_keys === ' + lead_zip_keys);

            if (lead_name_keys.size() == 0) lead_name_keys.add('');
            if (lead_phone_keys.size() == 0) lead_phone_keys.add('');
            if (lead_mobile_keys.size() == 0) lead_mobile_keys.add('');
            if (lead_email_keys.size() == 0) lead_email_keys.add('');
            if (lead_street_keys.size() == 0) lead_street_keys.add('');
            if (lead_city_keys.size() == 0) lead_city_keys.add('');
            if (lead_state_keys.size() == 0) lead_state_keys.add('');
            if (lead_zip_keys.size() == 0) lead_zip_keys.add('');

            String query = 'SELECT Id, FirstName, LastName, Name, Phone, MobilePhone, Email, PostalCode, OwnerId, Owner.Name, Status, IsJVLead__c, Line_of_Business__c, UTM_Source__c, Is_HCR_Lead__c, POD_Lead_Id__c, Lead_Source__c, Declination_Reason__c, ' +
                    'CreatedDate, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, Policy_Types__c, Last_Page_Visited__c, Quote_Type_Selection__c, Quote_Type_Selected__c FROM Lead WHERE ' +
                    'Status IN (\'New\', \'Working\', \'Converted\', \'Cancelled\', \'Closed\', \'Bound\', \'Quoted\') ' +
                    'AND IsJVLead__c = FALSE AND Is_HCR_Lead__c = \'No\' AND RecordType.DeveloperName IN: nonJVRecordTypes AND CreatedDate = LAST_N_DAYS:' + JV_Leads_Seniority_InDays + ' ' +
                    'AND ( (Name IN:lead_name_keys OR Phone IN:lead_phone_keys OR MobilePhone IN:lead_mobile_keys OR Email IN:lead_email_keys) ' +
                    'AND   (Street IN:lead_street_keys AND City IN:lead_city_keys AND State IN:lead_state_keys AND PostalCode IN:lead_zip_keys) )';

            System.debug('getAllNonJVLeads_v2, query: ' + query);

            try {

                nonJvHcrLeads = Database.query(query);

            }
            catch (Exception ex) {

                System.debug('getAllNonJVLeads_v2 Exception === ');
                System.debug(ex);
            }
        }

        System.debug('nonJvHcrLeads: ' + nonJvHcrLeads);

        return nonJvHcrLeads;
    }
     */

    /*
    Method: getAllNonJVLeads_v3 (SFDC-1463)
    Description: Get list of all non jv leads and have similarity to other leads by specific context of name, phone, mobile or email AND policy type
    Return: List<Lead> - Trivial
    */
    private static List<Lead> getAllNonJVLeads_v3(Set<String> lead_name_keys, Set<String> lead_phone_keys, Set<String> lead_mobile_keys, Set<String> lead_email_keys, Set<String> lead_street_keys, Set<String> lead_city_keys, Set<String> lead_state_keys, Set<String> lead_zip_keys) {

        List<Lead> nonJvHcrLeads = new List<Lead>();

        if ( FeatureFlags.instance.ff_DDup_B2C_Sales_Leads ) {

            String JV_Leads_Seniority_InDays = Utils.getHippoSettings('JV Leads Seniority (days)');
            System.debug('getAllNonJVLeads_v3::JV_Leads_Seniority_InDays === ' + JV_Leads_Seniority_InDays);

            Set<String> nonJVRecordTypes = Utils.getLeadNonJVRecordTypes();
            System.debug('nonJVRecordTypes === ' + nonJVRecordTypes);

            System.debug('lead_name_keys === ' + lead_name_keys);
            System.debug('lead_phone_keys === ' + lead_phone_keys);
            System.debug('lead_mobile_keys === ' + lead_mobile_keys);
            System.debug('lead_email_keys === ' + lead_email_keys);
            System.debug('lead_street_keys === ' + lead_street_keys);
            System.debug('lead_city_keys === ' + lead_city_keys);
            System.debug('lead_state_keys === ' + lead_state_keys);
            System.debug('lead_zip_keys === ' + lead_zip_keys);

            String query = 'SELECT Id, FirstName, LastName, Name, Phone, MobilePhone, Email, PostalCode, OwnerId, Owner.Name, Status, IsJVLead__c, Line_of_Business__c, UTM_Source__c, Is_HCR_Lead__c, POD_Lead_Id__c, Lead_Source__c, Declination_Reason__c, ' +
                    'CreatedDate, Name_Deduplication_Key__c, Phone_Deduplication_Key__c, Mobile_Deduplication_Key__c, Email_Deduplication_Key__c, Policy_Types__c, Last_Page_Visited__c, Quote_Type_Selection__c, Quote_Type_Selected__c FROM Lead WHERE ' +
                    'Status IN (\'New\', \'Working\', \'Converted\', \'Cancelled\', \'Closed\', \'Bound\', \'Quoted\') AND Disqualified_Reason__c != \'Duplicate\' ' +
                    'AND IsJVLead__c = FALSE AND Is_HCR_Lead__c = \'No\' AND RecordType.DeveloperName IN: nonJVRecordTypes AND CreatedDate = LAST_N_DAYS:' + JV_Leads_Seniority_InDays + ' ' +
                    'AND ( (';

            Boolean has_valid_filters = false;

            if ( lead_name_keys.size() > 0 ) {

                query += 'Name IN:lead_name_keys';
                has_valid_filters = true;
            }

            if ( lead_phone_keys.size() > 0 ) {

                if ( has_valid_filters ) {
                    query += ' OR Phone IN:lead_phone_keys';
                }
                else {
                    query += 'Phone IN:lead_phone_keys';
                    has_valid_filters = true;
                }
            }

            if ( lead_mobile_keys.size() > 0 ) {

                if ( has_valid_filters ) {
                    query += ' OR MobilePhone IN:lead_mobile_keys';
                }
                else {
                    query += 'MobilePhone IN:lead_mobile_keys';
                    has_valid_filters = true;
                }
            }

            if ( lead_email_keys.size() > 0 ) {

                if ( has_valid_filters ) {
                    query += ' OR Email IN:lead_email_keys';
                }
                else {
                    query += 'Email IN:lead_email_keys';
                    has_valid_filters = true;
                }
            }

            //'Name IN:lead_name_keys OR Phone IN:lead_phone_keys OR MobilePhone IN:lead_mobile_keys OR Email IN:lead_email_keys' +

            query += ') AND (';

            Boolean has_valid_address_filters = false;

            if ( lead_street_keys.size() > 0 ) {

                query += 'Street IN:lead_street_keys';
                has_valid_address_filters = true;
            }

            if ( lead_city_keys.size() > 0 ) {

                if ( has_valid_address_filters ) {
                    query += ' AND City IN:lead_city_keys';
                }
                else {
                    query += 'City IN:lead_city_keys';
                    has_valid_address_filters = true;
                }
            }

            if ( lead_state_keys.size() > 0 ) {

                if ( has_valid_address_filters ) {
                    query += ' AND State IN:lead_state_keys';
                }
                else {
                    query += 'State IN:lead_state_keys';
                    has_valid_address_filters = true;
                }
            }

            if ( lead_zip_keys.size() > 0 ) {

                if ( has_valid_address_filters ) {
                    query += ' AND PostalCode IN:lead_zip_keys';
                }
                else {
                    query += 'PostalCode IN:lead_zip_keys';
                    has_valid_address_filters = true;
                }
            }

            //'Street IN:lead_street_keys AND City IN:lead_city_keys AND State IN:lead_state_keys AND PostalCode IN:lead_zip_keys';

            query += ') )';

            //query += ') AND (Street IN:lead_street_keys AND City IN:lead_city_keys AND State IN:lead_state_keys AND PostalCode IN:lead_zip_keys) )';

            System.debug('getAllNonJVLeads_v3, query: ' + query);

            try {

                if ( has_valid_filters && has_valid_address_filters ) { // indication that there are valid filter conditions in the query

                    nonJvHcrLeads = Database.query(query);
                }

            }
            catch (Exception ex) {

                System.debug('getAllNonJVLeads_v3 Exception === ');
                System.debug(ex);
            }
        }

        System.debug('nonJvHcrLeads: ' + nonJvHcrLeads);

        return nonJvHcrLeads;
    }

    public static Duplicate_Lead_Record__c createDuplicateLeadRecord(Lead parent, Lead duplicate) {

        if ( parent != null && duplicate != null ) {

            Duplicate_Lead_Record__c duplicateLeadRecord = new Duplicate_Lead_Record__c(ParentId__c = parent.Id, DuplicateId__c = duplicate.Id, Composite_Key__c = String.valueOf(parent.Id) + String.valueOf(duplicate.Id));
            return duplicateLeadRecord;
        }

        return null;
    }
}