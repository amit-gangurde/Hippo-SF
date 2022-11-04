public without sharing class CreateNewCase {
    public static Id Id { get; set; }
    public static Inspection__c inspection { get; set; }
      //constructor to get the inspection record
    public CreateNewCase(ApexPages.StandardController controller) {
        if(controller.getRecord() != null) {
            inspection = [SELECT Id, Case__c FROM Inspection__c WHERE Id = :controller.getRecord().Id];
        }
        Id = inspection.Id;
    }
    
    //Method that creates case if case field is empty on inspection.
    public static PageReference CreateCase() {
        if(inspection.Id != null && inspection.Case__c == null) {
            set<Id> inspectionIds = new set<Id>();
            inspectionIds.add(inspection.Id);
            if(!inspectionIds.isEmpty()) {
                BatchForPreBindCaseCreationHelper.createCaseAssociatedToInspectionAndUpdate(inspectionIds);
            }
        }
       //Returns to the inspection page
       PageReference pageRef = new PageReference('/'+Id);
       pageRef.setRedirect(true);
       return pageRef; 
    }
}