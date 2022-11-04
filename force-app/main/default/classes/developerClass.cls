public class developerClass {
    public static string underwrtingRecId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Underwriting').getRecordTypeId();
    public static void dev() {
        List<Case> lstCase = new List<Case>();
        system.debug('lstCase =====' + lstCase);
        for (Integer i = 0; i < 1; i++) {
            Case testCase = new Case(Status='New');
            testCase.RecordTypeId =  Schema.sObjectType.Case.getRecordTypeInfosByName().get('B2B Support').getRecordTypeId();
            testCase.OwnerId = '00G7c000003laPDEAY';
            lstCase.add(testCase);
        }
        system.debug('lstCase =====' + lstCase[0]);
        insert lstCase;
        system.debug('lstCase == ' + lstCase[0]);
    }
    
    Public static List<Task> buildTasksRelatedToCases(List<Case> lstCase, string recId) {
        List<Task_Subjects__mdt> taskSubjects = [SELECT Id, Task_Subjects__c FROM Task_Subjects__mdt WHERE DeveloperName='UnderwritingTasksSubjects' LIMIT 1];
        List<String> subjects = new List<String>();
        
        if(taskSubjects != null && taskSubjects.size() > 0 && taskSubjects[0].Task_Subjects__c != '') {
            subjects = taskSubjects[0].Task_Subjects__c.split(',');
        }
        
        List<Task> lstTask = new List<Task>();
        if(!subjects.isEmpty()) {
            for(Case caseObj : lstCase) {
                for(integer index = 0; index < subjects.size() ; index++) {
                    Task task = new Task();
                    task.OwnerId = caseObj.OwnerId;
                    task.Priority = 'Normal';
                    task.Status = 'Open';
                    task.Subject = subjects[index];
                    task.RecordTypeId = recId;
                    lstTask.add(task);
                }
            }
        }
        return lstTask;
    }
}