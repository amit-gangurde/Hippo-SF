/************************************************************************************************************************************
Author : Amit Gangurde
Description : Helper class for the PriorityQueue batch.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1             SFDC-2192        17/10/2022      Amit Gangurde      Initial Development
**************************************************************************************************************************************/
public class PriorityQueueBatchHelper {
    
    public static List<Case> listToBeProcess = New List<Case>();
    
    public static void processCases(List<Case> listOfCases){
        
        List<Case> newBusinessCaseLst =new list<Case>();
        List<Case> renewalCaseLst = new list<Case>();
        
        Set<String> queueName = new Set<String>();
        List <queue_Setting__mdt> queue_Setting = [SELECT Queue_Name__c FROM queue_Setting__mdt where FIFO_Priority__c != true ];
        for(queue_Setting__mdt obj : queue_Setting){
            queueName.add(obj.Queue_Name__c);
        }
        
        String renewalQueueId;
        String newbusinessqueueId; 
        List<Group> lstGroup = [SELECT Id, Name FROM Group where Type='Queue' and name in : queueName];
        for(Group obj : lstGroup){
            if(obj.name == 'New Business'){
                newbusinessqueueId =obj.Id;
            }
            else if(obj.name == 'Renewal'){
                renewalQueueId = obj.Id;
            }
        }
        
        for(Case obj : listOfCases){
            String recordTyeName = obj.recordtype.name;
            if(recordTyeName == 'UW-New Business'){
                obj.OwnerId = newbusinessqueueId;
                newBusinessCaseLst.add(obj);
            }
            else if(recordTyeName == 'UW-Renewal'){
                obj.OwnerId = renewalQueueId;
                renewalCaseLst.add(obj);
            }
            
        }
        if(!newBusinessCaseLst.isEmpty()) {
            processCasesByLAD(newBusinessCaseLst);
        }
        if(!renewalCaseLst.isEmpty()) {
            processCasesByLAD(renewalCaseLst);
        }
        
    }
    public static void processCasesByLAD(List<Case> casesList){
        
        List<Case> firstPrioList = New List<Case>();
        List<Case> secondPrioList = New List<Case>();
        List<Case> thirdPrioList = New List<Case>();
        List<Case> fourthPrioList = New List<Case>();
        
        if(!casesList.isEmpty()) {
            
            for (Case caseRec : casesList){
                
                if(caseRec.Last_Action_Date__c == Date.today()){
                    firstPrioList.add(caseRec);
                }
                else if(caseRec.Last_Action_Date__c < Date.today()){
                    secondPrioList.add(caseRec);
                }
                else if(caseRec.Last_Action_Date__c == Date.today().addDays(1)){
                    thirdPrioList.add(caseRec);
                }
                else if(caseRec.Last_Action_Date__c == Date.today().addDays(2)){
                    fourthPrioList.add(caseRec);
                }
                
            }
        }
        
        processCaseByProbability(firstPrioList, secondPrioList, thirdPrioList, fourthPrioList);
        
    }
    public static void processCaseByProbability(List<Case> lstCaseFirst, List<Case> lstCaseSecond, List<Case> lstCaseThird, List<Case> lstCaseFourth) {
        
        if(!lstCaseFirst.isEmpty()) {
            probabilityCaseDistribution(lstCaseFirst);
        }
        if(!lstCaseSecond.isEmpty()) {
            probabilityCaseDistribution(lstCaseSecond);
        }
        if(!lstCaseThird.isEmpty()) {
            probabilityCaseDistribution(lstCaseThird);
        }
        if(!lstCaseFourth.isEmpty()) {
            probabilityCaseDistribution(lstCaseFourth);
        }
        if(!listToBeProcess.isEmpty()) {
            update listToBeProcess;
            listToBeProcess.clear();
        }
    }
    
    
    public static void probabilityCaseDistribution(List<Case> lstCase) {
        
        if(!lstCase.isEmpty()) {
            
            List<Case> firstPrioProbabilityLst = New List<Case>();
            List<Case> secondPrioProbabilityLst = New List<Case>();
            List<Case> thirdPrioProbabilityLst = New List<Case>();
            List<Case> fourthPrioProbabilityList = New List<Case>();
            
            for(Case caseRec : lstCase){
                
                Decimal probabilityScore = caseRec.Priority_Score__c;
                
                if( probabilityScore >= 0.78 && probabilityScore <= 1.00){
                    firstPrioProbabilityLst.add(caseRec);
                }
                else if( probabilityScore >= 0.54 && probabilityScore <= 0.77){
                    secondPrioProbabilityLst.add(caseRec);
                }
                else if( probabilityScore >= 0.31 && probabilityScore <= 0.53){
                    thirdPrioProbabilityLst.add(caseRec);
                }
                else if( probabilityScore >= 0.07 && probabilityScore <= 0.30){
                    fourthPrioProbabilityList.add(caseRec);
                }
                
            }
            if(!firstPrioProbabilityLst.isEmpty()) {
                processCaseByInspection(firstPrioProbabilityLst);
            }
            if(!secondPrioProbabilityLst.isEmpty()) {
                processCaseByInspection(secondPrioProbabilityLst);
            }
            if(!thirdPrioProbabilityLst.isEmpty()) {
                processCaseByInspection(thirdPrioProbabilityLst);
            }
            if(!fourthPrioProbabilityList.isEmpty()) {
                processCaseByInspection(fourthPrioProbabilityList);
            }
        }
    }
    
    
    public static void processCaseByInspection(List<Case> lstInspection){
        
        if(!lstInspection.isEmpty()) {
            
            List<Case> firstPrioInspectionLst = New List<Case>();
            List<Case> secondPrioInspectionLst = New List<Case>();
            List<Case> thirdPrioInspectionLst = New List<Case>();
            List<Case> fourthPrioInspectionList = New List<Case>();
            
            for(Case caseRec : lstInspection){
                
                Integer inspectionScore = Integer.valueOf(caseRec.Inspection_Score__c);
                
                if( inspectionScore >= 1875 && inspectionScore <= 2500){
                    firstPrioInspectionLst.add(caseRec);
                }
                else if( inspectionScore >= 1250 && inspectionScore <= 1874){
                    secondPrioInspectionLst.add(caseRec);
                }
                else if( inspectionScore >= 624 && inspectionScore <= 1249){
                    thirdPrioInspectionLst.add(caseRec);
                }
                else if( inspectionScore >= 0 && inspectionScore <= 623){
                    fourthPrioInspectionList.add(caseRec);
                }
            }
            
            if(!firstPrioInspectionLst.isEmpty())
                listToBeProcess.addAll(firstPrioInspectionLst);
            if(!secondPrioInspectionLst.isEmpty())
                listToBeProcess.addAll(secondPrioInspectionLst);
            if(!thirdPrioInspectionLst.isEmpty())
                listToBeProcess.addAll(thirdPrioInspectionLst);
            if(!fourthPrioInspectionList.isEmpty())
                listToBeProcess.addAll(fourthPrioInspectionList);
           
        }
        
    }
}