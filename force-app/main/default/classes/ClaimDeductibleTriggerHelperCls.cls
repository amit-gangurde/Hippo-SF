public class ClaimDeductibleTriggerHelperCls {

    public static void updateSeletedBasedonName(List<Claim_Deductible__c> lstClaimDeductible) {

        Set<Id> setClaimId = new Set<Id> ();
        Map<Id, String> mapClaimWithPeril = new Map<Id, String>();
        for (Claim_Deductible__c objClaimDedut : lstClaimDeductible) {
            if (objClaimDedut.Claim__c != Null) {
                setClaimId.add(objClaimDedut.Claim__c);
            }
        }

        List<Claim_Deductible__c> lstClaimDedSelected = new List<Claim_Deductible__c>();

        if (!setClaimId.isEmpty()) {

            for (Claim objClaim : [
                    Select Id,Peril__c, (Select Id,Name From Claim_Deductibles__r)
                    From Claim
                    Where Peril__c != Null AND Id IN:setClaimId
            ]) {
                if (objClaim.Claim_Deductibles__r != Null && objClaim.Claim_Deductibles__r.size() > 0) {
                    String IdWind_or_Hail = '';
                    String IdHurricane = '';
                    String IdService_Line = '';
                    String IdEquipment_Breakdown = '';
                    String IdAll_Perils_Deductible = '';
                    for (Claim_Deductible__c objClaimDed : objClaim.Claim_Deductibles__r) {
                        if (objClaimDed.Name != Null && objClaimDed.Name == 'Wind or Hail Deductible'
                                && (objClaim.Peril__c == 'wind' || objClaim.Peril__c == 'hail')) {
                            IdWind_or_Hail = objClaimDed.Id;
                        } else if (objClaimDed.Name != Null && objClaimDed.Name == 'Hurricane Deductible'
                                && objClaim.Peril__c == 'hurricane') {
                            IdHurricane = objClaimDed.Id;
                        } else if (objClaimDed.Name != Null && objClaimDed.Name == 'Service Line Deductible'
                                && objClaim.Peril__c == 'service_line') {
                            IdService_Line = objClaimDed.Id;
                        } else if (objClaimDed.Name != Null && objClaimDed.Name == 'Equipment Breakdown Deductible'
                                && objClaim.Peril__c == 'equipment_breakdown') {
                            IdEquipment_Breakdown = objClaimDed.Id;
                        } else if (objClaimDed.Name != Null && objClaimDed.Name == 'All Perils Deductible') {
                            IdAll_Perils_Deductible = objClaimDed.Id;
                        }
                    }
                    if (IdWind_or_Hail != Null && IdWind_or_Hail != '') {
                        lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdWind_or_Hail, selected__c = true));
                        if (IdHurricane != null && IdHurricane != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdHurricane, selected__c = false));
                        }
                        if (IdService_Line != null && IdService_Line != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdService_Line, selected__c = false));
                        }
                        if (IdEquipment_Breakdown != null && IdEquipment_Breakdown != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdEquipment_Breakdown, selected__c = false));
                        }
                        if (IdAll_Perils_Deductible != null && IdAll_Perils_Deductible != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdAll_Perils_Deductible, selected__c = false));
                        }
                    } else if (IdHurricane != null && IdHurricane != '') {
                        lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdHurricane, selected__c = true));
                        if (IdService_Line != null && IdService_Line != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdService_Line, selected__c = false));
                        }
                        if (IdEquipment_Breakdown != null && IdEquipment_Breakdown != '') {  // *** Added Empty Check
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdEquipment_Breakdown, selected__c = false));
                        }
                        if (IdAll_Perils_Deductible != null && IdAll_Perils_Deductible != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdAll_Perils_Deductible, selected__c = false));
                        }
                    } else if (IdService_Line != null && IdService_Line != '') {
                        lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdService_Line, selected__c = true));
                        if (IdEquipment_Breakdown != null && IdEquipment_Breakdown != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdEquipment_Breakdown, selected__c = false));
                        }
                        if (IdAll_Perils_Deductible != null && IdAll_Perils_Deductible != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdAll_Perils_Deductible, selected__c = false));
                        }
                    } else if (IdEquipment_Breakdown != null && IdEquipment_Breakdown != '') {
                        lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdEquipment_Breakdown, selected__c = true));
                        if (IdAll_Perils_Deductible != null && IdAll_Perils_Deductible != '') {
                            lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdAll_Perils_Deductible, selected__c = false));
                        }
                    } else if (IdAll_Perils_Deductible != null && IdAll_Perils_Deductible != '') {
                        lstClaimDedSelected.add(new Claim_Deductible__c(Id = IdAll_Perils_Deductible, selected__c = true));
                    }

                }

            }
            if (!lstClaimDedSelected.isEmpty()) {
                Database.update(lstClaimDedSelected, false);
            }
        }
    }

    public static void verifyIfUpdateAllowed(List<Claim_Deductible__c> lstClaimDeductible) {

        if ( Trigger.isExecuting ) {

            List<Claim_Payment_Item__c> lstClaimPaymentItems = [SELECT Id, Name, Deductible__c, Claim_Payment__c FROM Claim_Payment_Item__c WHERE Deductible__c IN:Trigger.newMap.keySet()];
            System.debug('lstClaimPaymentItems: ' + lstClaimPaymentItems);

            Map<Id, Claim_Deductible__c> map_ClaimPaymentId2ClaimDeductible = new Map<Id, Claim_Deductible__c>();
            for (Claim_Payment_Item__c cpi : lstClaimPaymentItems) {
                map_ClaimPaymentId2ClaimDeductible.put(cpi.Claim_Payment__c, (Claim_Deductible__c)Trigger.newMap.get(cpi.Deductible__c));
            }

            List<Claim_Payment__c> lstClaimPayments = [SELECT Id, Name, Transaction_Status__c FROM Claim_Payment__c WHERE Id IN: map_ClaimPaymentId2ClaimDeductible.keySet()];

            for (Claim_Payment__c cp : lstClaimPayments) {

                system.debug('cp == ' + cp);

                Claim_Deductible__c newCD = map_ClaimPaymentId2ClaimDeductible.get(cp.Id);
                system.debug('newCD == ' + newCD);
                Claim_Deductible__c oldCD = (Claim_Deductible__c)Trigger.oldMap.get(newCD.Id);
                system.debug('oldCD == ' + oldCD);

                if ( newCD.Deductible_Override_Amount__c != oldCD.Deductible_Override_Amount__c ) {

                    system.debug('cp.Transaction_Status__c == ' + cp.Transaction_Status__c);

                    if ( String.isNotBlank(cp.Transaction_Status__c) && !cp.Transaction_Status__c.equalsIgnoreCase('Stopped')) {

                        map_ClaimPaymentId2ClaimDeductible.get(cp.Id).addError(Label.Error_Cannot_Override_Claim_Deductible_Amount);
                    }
                }
            }
        }
    }

    /*
    Method: launchClaimPaymentItemFlows
    Description: Update on Claim_Deductible__c results with formula field updates on Claim_Payment_Item__c. However, these
    formula field updates do not launch the flows related to Claim_Payment_Item__c, therefore we execute an EMPTY update to trigger
    these flows and let Total_Payment__c get recalculated
    Return: nothing
    NOTES: This approach is with high potential to result with flow_element_error|this error occurred when the flow tried to update records: too many soql queries: 101
    */
    public static void launchClaimPaymentItemFlows(List<Claim_Deductible__c> lstClaimDeductible) {

        if ( Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate ) {

            try {

                // filter only on relevant use cases that resulted with Deductible_Amount__c and Deductible_Override_Amount__c
                //      updates and not any other non relevant fields on Claim_Deductible__c
                Set<Id> deductiblesIds = new Set<Id>();
                for ( Claim_Deductible__c cd : lstClaimDeductible ) {

                    Boolean alreadyUsed = cd.Already_Used__c;
                    Boolean oldAlreadyUsed = ((Claim_Deductible__c)Trigger.oldMap.get(cd.Id)).Already_Used__c;
                    if (alreadyUsed && alreadyUsed != oldAlreadyUsed) {

                        continue; // No need to update CPI for this scenario as this is a result of 'Claim Payment Item After Update' flow which updates Already_Used__c
                    }
                    else {

                        deductiblesIds.add(cd.Id);
                    }
                }

                System.debug('deductiblesIds: ' + deductiblesIds);

                if ( deductiblesIds.size() > 0 ) {

                    List<Claim_Payment_Item__c> lstClaimPaymentItems = [SELECT Id FROM Claim_Payment_Item__c WHERE Deductible__c IN: deductiblesIds];
                    System.debug('Claim_Payment_Item__c to executes flows upon : ' + lstClaimPaymentItems);

                    if ( lstClaimPaymentItems.size() > 0 ) {
                        
                        update lstClaimPaymentItems;
                    }
                }
            }
            catch (Exception ex) {

                System.debug('launchClaimPaymentItemFlows(): ' + ex);
            }
        }
    }
}