/**
 * Created by lironkeren on 26/06/2022.
 */

public with sharing class InspectionTriggerHandler extends TriggerHandler {

    public static final String test_hazards_json = '{\n' +
            '  "Hazards":[\n' +
            '    {\n' +
            '      "Category": "General Information",\n' +
            '      "Subcategory": "Vacant and uninhabitable",\n' +
            '      "HazardKey": "GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ",\n' +
            '      "HazardScore": 200' +
            '    },\n' +
            '    {\n' +
            '      "Category": "General Information",\n' +
            '      "Subcategory": "Vacant and uninhabitable",\n' +
            '      "HazardKey": "GENERAL_INFORMATION_INCORRECT_ADDRESS_PROVIDED_MAJ_2",\n' +
            '      "HazardScore": 300' +
            '    }\n' +
            '  ]\n' +
            '}';

    public static final String test_hazards_json_real_prod_sample_1 = '{\n' +
            '  "Hazards": [\n' +
            '    {\n' +
            '      "HazardKey": "TREE_TREE_OVERHANGING_DWELLING_MIN",\n' +
            '      "HazardScore": 25,\n' +
            '      "Category": "Tree",\n' +
            '      "Subcategory": "Tree overhanging dwelling"\n' +
            '    },\n' +
            '    {\n' +
            '      "HazardKey": "TREE_SHRUBS_OR_BUSHES_TOUCHING_DWELLING_MIN",\n' +
            '      "HazardScore": 25,\n' +
            '      "Category": "Tree",\n' +
            '      "Subcategory": "Shrubs/Bushes touching dwelling"\n' +
            '    }\n' +
            '  ]\n' +
            '}';

    /*
    Method: ctor
    Description: Trivial
    Return: nothing
    */
    public InspectionTriggerHandler() {

    }

    public override void afterInsert() {

        createChildHazards();
    }

    public override void afterUpdate() {

        createChildHazards();
    }

    private void createChildHazards() {

        System.debug('Start createChildHazards()');

        try {
            // Check the number of hazards on inspections so also UPDATE is supported (in case no hazards were created)
            Map<Id, AggregateResult> idToAggregateResultMap = new Map<id, AggregateResult>([SELECT Inspection__c Id, COUNT(Id) CountHazards FROM Hazard__c WHERE Inspection__c IN :Trigger.newMap.keySet() AND Inspection__c != NULL GROUP BY Inspection__c]);
            system.debug('idToAggregateResultMap: ' + idToAggregateResultMap);

            System.debug('createChildHazards(), idToAggregateResultMap: ' + idToAggregateResultMap);

            Map<Id, Inspection__c> map_Inspections2Process = new Map<Id, Inspection__c>();

            for (SObject obj : Trigger.new) {

                Inspection__c inspection = (Inspection__c) obj;

                if (!idToAggregateResultMap.containsKey(inspection.Id)) {

                    map_Inspections2Process.put(inspection.Id, inspection);
                }
            }

            System.debug('createChildHazards(), map_Inspections2Process: ' + map_Inspections2Process);

            List<Inspection__c> lst_InspectionsInConext = [SELECT Id, Hazards__c FROM Inspection__c WHERE Id IN :map_Inspections2Process.keySet()];

            System.debug('createChildHazards(), lst_InspectionsInConext: ' + lst_InspectionsInConext);

            if (lst_InspectionsInConext.size() > 0) createChildHazards(lst_InspectionsInConext);
        }
        catch (Exception ex) {

            System.debug('Exception from createChildHazards(): ' + ex);
        }

        System.debug('End createChildHazards()');
    }

    private void createChildHazards(List<Inspection__c> inspections) {

        System.debug('Inside createChildHazards()');

        List<Hazard__c> lst_Hazards = new List<Hazard__c>();

        for ( Inspection__c inspection : inspections ) {

            System.debug('Current Inspection: ' + inspection);

            if ( String.isNotBlank(inspection.Hazards__c) ) {

                try {

                    Map<String, Object> json_map = (Map<String, Object>) JSON.deserializeUntyped(inspection.Hazards__c);
                    System.debug('json_map: ' + json_map);
                    List<Object> json_hazards = (List<Object>)json_map.get('Hazards');
                    System.debug('json_hazards: ' + json_hazards);

                    for ( Object hazard : json_hazards ) {

                        Map<String, Object> hazard_map = (Map<String, Object>) hazard;

                        Hazard__c h = new Hazard__c();

                        h.Inspection__c = inspection.Id;
                        if (hazard_map.containsKey('Category')) h.Category__c = (String)hazard_map.get('Category');
                        if (hazard_map.containsKey('Subcategory')) h.Sub_Category__c = (String)hazard_map.get('Subcategory');
                        if (hazard_map.containsKey('HazardKey')) h.Hazard_Key__c = (String)hazard_map.get('HazardKey');
                        if (hazard_map.containsKey('HazardScore')) h.Score__c = (Integer)hazard_map.get('HazardScore');

                        lst_Hazards.add(h);
                    }

                }
                catch (Exception ex) {

                    System.debug('Exception from createChildHazards(List<Inspection__c> inspections): ' + ex);
                }
            }
        }

        if ( lst_Hazards.size() > 0 ) {

            insert lst_Hazards;
        }
    }
}