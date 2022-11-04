public without sharing class ClaimReserveTriggerHandler extends TriggerHandler{
    
    private final static String CLAIM_TASK_RESERVE_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Claim_Task_Reserve').getRecordTypeId();
    private final static String CLAIM_RESERVE_LOSS_RT_ID = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
    private final static String CLAIM_RESERVE_EXPENSE_RT_ID = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Expense').getRecordTypeId();
    
    //private Map<Id, List<Claim_Reserve__c>> claimIdToRelatedClaimReservesMap = new Map<Id, List<Claim_Reserve__c>>();
 	private Map<Id, Map<String, List<Claim_Reserve__c>>> claimIdToSeparatedByTypeReserves = new Map<Id, Map<String, List<Claim_Reserve__c>>>();

    public override void afterInsert() {
        startApprovalProcess((List<Claim_Reserve__c>) Trigger.new);
    }
    
    public override void afterUpdate() {
        
        
        List<Claim_Reserve__c> claimReserveToApprovalProcesses = new List<Claim_Reserve__c>();
        for (Claim_Reserve__c claimReserve : (List<Claim_Reserve__c>) Trigger.new) {
            if (fieldIsChanged(claimReserve, 'Reserve_Amount__c') && fieldIsChanged(claimReserve, 'Re_enter_Reserve_Amount__c')) {
                claimReserveToApprovalProcesses.add(claimReserve);
            }
        }
        
        if (claimReserveToApprovalProcesses.size() > 0) {
            startApprovalProcess(claimReserveToApprovalProcesses);
        }
    }
    
    private void startApprovalProcess(List<Claim_Reserve__c> claimReserves) {
        
        User currentUser = [SELECT Id, Name, Reserve_Authority_Amount__c, ManagerId FROM User WHERE Id = :UserInfo.getUserId()];
                
        Set<Id> claimIdsRelatedToAffectedReserves = new Set<Id>();
        for (Claim_Reserve__c claimReserve : claimReserves) {
            if (claimReserve.Claim__c != null) {
                claimIdsRelatedToAffectedReserves.add(claimReserve.Claim__c);
            }
        }
        Map<Id, Claim> claimMap = new Map<Id, Claim>([SELECT Id, Name FROM Claim WHERE Id IN :claimIdsRelatedToAffectedReserves]);
        
        
        List<Claim_Reserve__c> allRelatedClaimReservesWithNew = [SELECT Id, RecordTypeId, Claim__c, Reserve_Amount__c, Name, Status__c,Claim_Coverage__c,Claim_Coverage__r.Name 
                                                                 FROM Claim_Reserve__c 
                                                                 WHERE Claim__c IN :claimMap.keySet()
                                                                 AND Status__c != 'Cancelled'];
        for (Claim_Reserve__c claimReserve : allRelatedClaimReservesWithNew) {
            if (claimIdToSeparatedByTypeReserves.containsKey(claimReserve.Claim__c)) {
                Map<String, List<Claim_Reserve__c>> typeToClaimReserves = claimIdToSeparatedByTypeReserves.get(claimReserve.Claim__c);
                if (claimReserve.RecordTypeId == CLAIM_RESERVE_LOSS_RT_ID) { typeToClaimReserves.get('Loss').add(claimReserve);
                } else if (claimReserve.RecordTypeId == CLAIM_RESERVE_EXPENSE_RT_ID) { typeToClaimReserves.get('Expense').add(claimReserve);
                }
            } else {
                Map<String, List<Claim_Reserve__c>> typeToClaimReserves = new Map<String, List<Claim_Reserve__c>>{
                    claimReserve.RecordTypeId == CLAIM_RESERVE_LOSS_RT_ID ? 'Loss' : 'Expense' => new List<Claim_Reserve__c>{claimReserve},
                    claimReserve.RecordTypeId == CLAIM_RESERVE_EXPENSE_RT_ID ? 'Loss' : 'Expense' => new List<Claim_Reserve__c>()
                };
                claimIdToSeparatedByTypeReserves.put(claimReserve.Claim__c, typeToClaimReserves);                
            }
        }
        
        Map<Id, Map<String, Double>> claimIdToSumOfRelatedReservesAmountMap = new Map<Id, Map<String, Double>>();
        for (Id claimId : claimIdToSeparatedByTypeReserves.keySet()) {
            
            Double sumOfLossAmount;
            if (claimIdToSeparatedByTypeReserves.get(claimId).get('Loss').size() > 0) {
                sumOfLossAmount = AcceptOrRejectClaimApprovalsController.getSumOfRelatedReservesAmount(claimIdToSeparatedByTypeReserves.get(claimId).get('Loss'));
                //sumOfLossAmount = AcceptOrRejectClaimApprovalsInvocable.getSumOfRelatedReservesAmount(claimIdToSeparatedByTypeReserves.get(claimId).get('Loss'));
            }
            Double sumOfExpenseAmount;
            if (claimIdToSeparatedByTypeReserves.get(claimId).get('Expense').size() > 0) {
                 sumOfExpenseAmount = AcceptOrRejectClaimApprovalsController.getSumOfRelatedReservesAmount(claimIdToSeparatedByTypeReserves.get(claimId).get('Expense'));
               // sumOfExpenseAmount = AcceptOrRejectClaimApprovalsInvocable.getSumOfRelatedReservesAmount(claimIdToSeparatedByTypeReserves.get(claimId).get('Expense'));
            }
            
            Map<String, Double> sumOfAmountByType = new Map<String, Double>{
                'Loss' => sumOfLossAmount,
                'Expense' => sumOfExpenseAmount
            };
            
            claimIdToSumOfRelatedReservesAmountMap.put(claimId, sumOfAmountByType);
            
        }
        
        Map<String, Set<Claim>> claimsToCreateOrGetTaskByType = new Map<String, Set<Claim>>();
        List<Claim_Reserve__c> claimReservesToUpdate = new List<Claim_Reserve__c>();
        
        
        //new
        for (Claim_Reserve__c claimReserve : (List<Claim_Reserve__c>) Trigger.new) {

            //String claimId = claimReserve.Claim__c;
            //String claimReserveType = claimReserve.RecordTypeId == CLAIM_RESERVE_LOSS_RT_ID ? 'Loss' : 'Expense';
            
            //for (Claim_Reserve__c cr : claimIdToSeparatedByTypeReserves.get(claimId).get(claimReserveType)) {
            Claim_Reserve__c cr = new Claim_Reserve__c(Id = claimReserve.Id, Claim__c = claimReserve.Claim__c, RecordTypeId = claimReserve.RecordTypeId);
                if (claimReserve.RecordTypeId == CLAIM_RESERVE_LOSS_RT_ID) {
                    
                    if (claimIdToSumOfRelatedReservesAmountMap.get(claimReserve.Claim__c).get('Loss') < currentUser.Reserve_Authority_Amount__c) {
                        cr.Status__c = 'Approved';
                    } else {
                        cr.Status__c = 'Pending Approval';
                        
                        if (claimsToCreateOrGetTaskByType.containsKey('Loss')) { claimsToCreateOrGetTaskByType.get('Loss').add(claimMap.get(claimReserve.Claim__c));
                        } else { claimsToCreateOrGetTaskByType.put('Loss', new Set<Claim>{ claimMap.get(claimReserve.Claim__c) }); }
                    }
                    
                } else if (claimReserve.RecordTypeId == CLAIM_RESERVE_EXPENSE_RT_ID) {
                    
                    if (claimIdToSumOfRelatedReservesAmountMap.get(claimReserve.Claim__c).get('Expense') < currentUser.Reserve_Authority_Amount__c) {
                        cr.Status__c = 'Approved';
                    } else {
                        cr.Status__c = 'Pending Approval';
                        
                        if (claimsToCreateOrGetTaskByType.containsKey('Expense')) {
                            claimsToCreateOrGetTaskByType.get('Expense').add(claimMap.get(claimReserve.Claim__c));
                        } else {
                            claimsToCreateOrGetTaskByType.put('Expense', new Set<Claim>{ claimMap.get(claimReserve.Claim__c) });
                        }
                    }
                    
                }
                
                claimReservesToUpdate.add(cr);
                
            //}

        }
        
        update claimReservesToUpdate;
        for (Claim_Reserve__c claimReserve : claimReservesToUpdate) {
            if (claimIdToSeparatedByTypeReserves.containsKey(claimReserve.Claim__c)) {
                    Map<String, List<Claim_Reserve__c>> typeToClaimReserves = claimIdToSeparatedByTypeReserves.get(claimReserve.Claim__c);
                    if (claimReserve.RecordTypeId == CLAIM_RESERVE_LOSS_RT_ID) { 
                        for (Claim_Reserve__c claimReserveFromList : typeToClaimReserves.get('Loss')) {
                            if (claimReserveFromList.Id == claimReserve.Id) {
                                claimReserveFromList.Status__c = claimReserve.Status__c;
                             }
                        }
                    } else if (claimReserve.RecordTypeId == CLAIM_RESERVE_EXPENSE_RT_ID) { 
                        for (Claim_Reserve__c claimReserveFromList : typeToClaimReserves.get('Expense')) {
                            if (claimReserveFromList.Id == claimReserve.Id) {
                                claimReserveFromList.Status__c = claimReserve.Status__c;
                            }
                        }
                    }
                }
        }
        
  
        
        
        Map<Id, Claim> claimIdToClaimMap = new Map<Id, Claim>();
        for (String approvalType : claimsToCreateOrGetTaskByType.keySet()) {
            for (Claim claim : claimsToCreateOrGetTaskByType.get(approvalType)) {
                claimIdToClaimMap.put(claim.Id, claim);
            }
        }
        
        List<Task> tasksToUpsert = new List<Task>();
        List<Task> tasksForLossType = [SELECT Id, Description, WhatId FROM Task WHERE WhatId IN :claimIdToClaimMap.keySet() AND RecordTypeId = :CLAIM_TASK_RESERVE_RT_ID AND Approval_Type__c = 'Loss'];
        List<Task> tasksForExpenseType = [SELECT Id, Description, WhatId FROM Task WHERE WhatId IN :claimIdToClaimMap.keySet() AND RecordTypeId = :CLAIM_TASK_RESERVE_RT_ID AND Approval_Type__c = 'Expense'];
        
        for (String approvalType : claimsToCreateOrGetTaskByType.keySet()) {
            for (Claim claim : claimsToCreateOrGetTaskByType.get(approvalType)) {
                if (approvalType == 'Loss') {
                    tasksToUpsert.add(createOrGetTask(currentUser, claim, claimIdToSeparatedByTypeReserves.get(claim.Id).get(approvalType), approvalType, tasksForLossType));
                } else if (approvalType == 'Expense') {
                    tasksToUpsert.add(createOrGetTask(currentUser, claim, claimIdToSeparatedByTypeReserves.get(claim.Id).get(approvalType), approvalType, tasksForExpenseType));
                }
            }
        }
        
        
        for (Task t : tasksToUpsert) {
            System.debug(t);
        }
        Claims_Custom__c aConfig = new Claims_Custom__c(SetupOwnerId=currentUser.Id, Skip_Validation__c=True);
        insert aConfig;
        upsert tasksToUpsert;
        delete aConfig;
    }

    private Task createOrGetTask(User currentUser, Claim claim, List<Claim_Reserve__c> claimReserves, String approvalType, List<Task> tasks){
        Task returnedTask;
        
		Map<Id, List<Task>> claimIdToTasksMap = new Map<Id, List<Task>>();
        for (Task task : tasks) {
            if (claimIdToTasksMap.containsKey(task.WhatId)) {
                claimIdToTasksMap.get(task.WhatId).add(task);
            } else {
                claimIdToTasksMap.put(task.WhatId, new List<Task>{ task });
            }
        }
        
        if (claimIdToTasksMap.containsKey(claim.Id)) {
            System.debug('if');
            for (Task task : claimIdToTasksMap.get(claim.Id)) {
                task.OwnerId = currentUser.ManagerId == null ? currentUser.Id : currentUser.ManagerId;
                task.Status = 'In Progress';
                task.Description = '';
                for (Claim_Reserve__c claimReserve : claimReserves) {
                    task.Description += 'Claim Reserve - ' + claimReserve.Name  + ' - Claim Coverage - '+claimReserve.Claim_Coverage__r.Name+' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimReserve.Id + '] (Status - ' + claimReserve.Status__c + '; Amount - ' + claimReserve.Reserve_Amount__c + ');\n';
                }
                task.Description = task.Description.abbreviate(31900);
                returnedTask = task;
            }
        } else {
            System.debug('else');
            Task newTask = new Task();
            newTask.RecordTypeId = CLAIM_TASK_RESERVE_RT_ID;
            newTask.Subject = approvalType + ' Reserves Approval Task (Claim - ' + claim.Name + ')';
            newTask.WhatId = claim.Id;
          /*  newTask.OwnerId = currentUser.ManagerId != null ? currentUser.ManagerId : 
            	(AcceptOrRejectClaimApprovalsInvocable.claimReserveGlobalManager != null ? AcceptOrRejectClaimApprovalsInvocable.claimReserveGlobalManager.Id : currentUser.Id); */
            
            newTask.OwnerId = currentUser.ManagerId != null ? currentUser.ManagerId : 
            	(AcceptOrRejectClaimApprovalsController.claimReserveGlobalManager != null ? AcceptOrRejectClaimApprovalsController.claimReserveGlobalManager.Id : currentUser.Id);
            newTask.Status = 'Open';
            newTask.Priority = 'Normal';
            newTask.Disposition__c = 'Claims';
            newTask.Description = '';
            newTask.ActivityDate = System.today();
            newTask.Approval_Type__c = approvalType;
            for (Claim_Reserve__c claimReserve : claimReserves) {
                newTask.Description += 'Claim Reserve - ' + claimReserve.Name + ' - Claim Coverage - '+claimReserve.Claim_Coverage__r.Name+' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimReserve.Id 
                    + '] (Status - ' + claimReserve.Status__c + '; Amount - ' + claimReserve.Reserve_Amount__c + ');\n';
            }
            newTask.Description = newTask.Description.abbreviate(31900);
            returnedTask = newTask;
        }
  
        return returnedTask;
    }
    
    private Boolean fieldIsChanged(Claim_Reserve__c claimReserve, String fieldApiName) {
        if (Trigger.isInsert && Trigger.isBefore || Trigger.isAfter && Trigger.isDelete) {
            throw new DmlException('You dont have id on Before Insert and on After Delete DML operations');
        }
        return Trigger.newMap.get(claimReserve.Id).get(fieldApiName) != Trigger.oldMap.get(claimReserve.Id).get(fieldApiName);
    }

}