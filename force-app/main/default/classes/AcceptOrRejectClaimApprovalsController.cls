/*****************************************************************************************************
* Name           : AcceptOrRejectClaimApprovalsController
* Test Class     : 
* Author         : Convene-Tech
* Purpose        : The main purpose of this class helps to update Claim Payment / Reserve Status based on the task owner approval / rejection.
* CreatedDate    : 07/20/2022
* LastModifiedBy : 07/29/2022
* ***************************************************************************************************/
public without sharing class AcceptOrRejectClaimApprovalsController{ 
    
    private final static String CLAIM_TASK_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Claim_Task').getRecordTypeId();
    private final static String CLAIM_TASK_RESERVE_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Claim_Task_Reserve').getRecordTypeId();
    private final static String CLAIM_TASK_PAYMENT_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Claim_Task_Payment').getRecordTypeId();
    private final static String CLAIM_RESERVE_LOSS_RT_ID = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
    private final static String CLAIM_RESERVE_EXPENSE_RT_ID = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Expense').getRecordTypeId();
    
    
    
    private static Claim_Approvals_Setting__c claimApprovalsSetting = Claim_Approvals_Setting__c.getInstance();
    public static User claimReserveGlobalManager {
        get {
            if (claimReserveGlobalManager == null) {
                List<User> users = [SELECT Id, ManagerId, Payment_Authority_Amount__c, Reserve_Authority_Amount__c 
                                    FROM User 
                                    WHERE Email = :claimApprovalsSetting.Claim_Reserve_Global_Manager__c];
                if (users.size() > 0) {
                    claimReserveGlobalManager = users.get(0);
                }
            }
            return claimReserveGlobalManager;
        }
        set;
    }
    public static User claimPaymentGlobalManager {
        get {
            if (claimPaymentGlobalManager == null) {
                List<User> users = [SELECT Id, ManagerId, Payment_Authority_Amount__c, Reserve_Authority_Amount__c 
                                    FROM User 
                                    WHERE Email = :claimApprovalsSetting.Claim_Payment_Global_Manager__c];
                if (users.size() > 0) {
                    claimPaymentGlobalManager = users.get(0);
                }
            }
            return claimPaymentGlobalManager;
        }
        set;
    }
    @AuraEnabled
    public static List<claimReserveAuraWrapper> getClaimCRs(Id taskId){
        List<claimReserveAuraWrapper> claimCRList = new List<claimReserveAuraWrapper>();
        
        Task requiredTask = [SELECT Id, RecordTypeId, WhatId, Status, OwnerId, Approval_Type__c, CreatedById,Description,Subject FROM Task WHERE Id = :taskId];
        Claim requiredClaim = [SELECT Id, Name FROM Claim WHERE Id = :requiredTask.WhatId];
        String claimReserveRecordTypeId;
        if (requiredTask.Approval_Type__c == 'Loss' || (String.isNotblank(requiredTask.Subject) && requiredTask.Subject.containsIgnoreCase('Loss'))) {
            claimReserveRecordTypeId = CLAIM_RESERVE_LOSS_RT_ID;
        } else if (requiredTask.Approval_Type__c == 'Expense' || (String.isNotblank(requiredTask.Subject) && requiredTask.Subject.containsIgnoreCase('Expense'))) {
            claimReserveRecordTypeId = CLAIM_RESERVE_EXPENSE_RT_ID;
        }
        if(requiredTask.recordTypeId == CLAIM_TASK_RESERVE_RT_ID){
            for(Claim_Reserve__c cr:[SELECT ID,Name,Status__c,Claim_Coverage__c,Claim_Coverage__r.Name,Reserve_Amount__c FROM Claim_Reserve__c WHERE Claim__c =: requiredClaim.Id AND Status__c = 'Pending Approval' AND RecordTypeId =: claimReserveRecordTypeId]){
                claimReserveAuraWrapper crWrap = new claimReserveAuraWrapper();
                crWrap.crObj = cr;
                claimCRList.add(crWrap);
            }
        }else if(requiredTask.recordTypeId == CLAIM_TASK_PAYMENT_RT_ID){
            for(Claim_Payment__c cr:[SELECT ID,Name,Status__c FROM Claim_Payment__c WHERE Claim__c =: requiredClaim.Id AND Status__c = 'Pending Approval']){
                claimReserveAuraWrapper crWrap = new claimReserveAuraWrapper();
                crWrap.cpayObj = cr;
                claimCRList.add(crWrap);
            }
        }
        System.debug('claimCRList::'+claimCRList);
        return claimCRList;
    }
    @AuraEnabled
    public static void updateApproval(List<AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper> claimReserveLst,Id taskId){
        try{
            List<FeedItem> feedItems = new List<FeedItem>();
            List<Sobject> claimReservesOrPaymentsToUpdate = new List<Sobject>();
            Boolean isAccept;
            String comments;
            System.debug('claimReserveLst::'+claimReserveLst);
            List<Claim_Reserve__c> claimUpdate = new List<Claim_Reserve__c>();
            Map<Id,AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper> crApprovalMap = new Map<Id,AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper>();
            Map<Id,AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper> cpayApprovalMap = new Map<Id,AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper>();
            
            for(AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper acp: claimReserveLst){
                if(acp.crObj!=null){
                    crApprovalMap.put(acp.crObj.id,acp);
                }
                if(acp.cpayObj!=null){
                    cpayApprovalMap.put(acp.cpayObj.id,acp);
                }
            }
            Task requiredTask = [SELECT Id, RecordTypeId, WhatId, Status, OwnerId, Approval_Type__c, CreatedById,Description,Subject FROM Task WHERE Id = :taskId];
            User taskOwner = [SELECT Id, ManagerId, Payment_Authority_Amount__c, Reserve_Authority_Amount__c FROM User WHERE Id = :requiredTask.OwnerId];
            Claim requiredClaim = [SELECT Id, Name,Claim_Adjuster__c FROM Claim WHERE Id = :requiredTask.WhatId];
            Boolean isClaimReserve = false;
            String claimReserveRecordTypeId;
            if (requiredTask.RecordTypeId == CLAIM_TASK_RESERVE_RT_ID && requiredTask.WhatId.getSObjectType().getDescribe().getName() == 'Claim') {
                // for Claim Reserves
                isClaimReserve = true;
                
                if (requiredTask.Approval_Type__c == 'Loss' || (String.isNotblank(requiredTask.Subject) && requiredTask.Subject.containsIgnoreCase('Loss'))) {
                    claimReserveRecordTypeId = CLAIM_RESERVE_LOSS_RT_ID;
                } else if (requiredTask.Approval_Type__c == 'Expense' || (String.isNotblank(requiredTask.Subject) && requiredTask.Subject.containsIgnoreCase('Expense'))) {
                    claimReserveRecordTypeId = CLAIM_RESERVE_EXPENSE_RT_ID;
                }
                
                List<Claim_Reserve__c> claimReserves = [SELECT Id, Name, Status__c, Notes__c, Reserve_Amount__c, Claim__c, Claim_Coverage__r.Name 
                                                        FROM Claim_Reserve__c 
                                                        WHERE Claim__c = :requiredTask.WhatId 
                                                        AND RecordTypeId = :claimReserveRecordTypeId
                                                        AND Status__c != 'Cancelled'];
                Double sumOfRelatedReservesAmount = getSumOfRelatedReservesAmount(claimReserves);
                requiredTask.Description = '';
                for (Claim_Reserve__c claimReserve : claimReserves) {
                    isAccept = false;
                    comments = '';
                    if(crApprovalMap.containsKey(claimReserve.Id)){
                        isAccept = crApprovalMap.get(claimReserve.Id).approvalStatus == 'Approved'?true:false; 
                        comments = crApprovalMap.get(claimReserve.Id).approvalComments; 
                    }
                    claimReserve.Notes__c = claimReserve.Notes__c == null ? createNotes(isAccept, comments) : claimReserve.Notes__c + '\n' + createNotes(isAccept, comments);
                    if (isAccept) {
                        if (taskOwner.Reserve_Authority_Amount__c >= sumOfRelatedReservesAmount) {
                            claimReserve.Status__c = 'Approved';
                            requiredTask.Status = 'Completed';
                            //******* Newly Added ********//
                            requiredTask.Description += 'Claim Reserve - ' + claimReserve.Name  + ' - Claim Coverage - '+claimReserve.Claim_Coverage__r.Name+' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimReserve.Id + '] (Status - ' + claimReserve.Status__c + '; Amount - ' + claimReserve.Reserve_Amount__c + ');\n';
                            
                        } else {
                            
                            //******* Newly Added ********//
                            requiredTask.Description += 'Claim Reserve - ' + claimReserve.Name  + ' - Claim Coverage - '+claimReserve.Claim_Coverage__r.Name+' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimReserve.Id + '] (Status - ' + claimReserve.Status__c + '; Amount - ' + claimReserve.Reserve_Amount__c + ');\n';
                            
                            requiredTask.OwnerId = taskOwner.ManagerId != null ? taskOwner.ManagerId : (claimReserveGlobalManager != null ? claimReserveGlobalManager.Id : taskOwner.Id);
                                }
                    } else if(claimReserve.Status__c != 'Approved'){
                        claimReserve.Status__c = 'Draft';
                        requiredTask.Status = 'Completed';
                        //******* Newly Added ********//
                        requiredTask.Description += 'Claim Reserve - ' + claimReserve.Name  + ' - Claim Coverage - '+claimReserve.Claim_Coverage__r.Name+' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimReserve.Id + '] (Status - ' + claimReserve.Status__c + '; Amount - ' + claimReserve.Reserve_Amount__c + ');\n';
                        
                    }else{
                        //******* Newly Added ********//
                        requiredTask.Description += 'Claim Reserve - ' + claimReserve.Name  + ' - Claim Coverage - '+claimReserve.Claim_Coverage__r.Name+' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimReserve.Id + '] (Status - ' + claimReserve.Status__c + '; Amount - ' + claimReserve.Reserve_Amount__c + ');\n';
                        
                    }
                    
                    feedItems.add(createFeedItemForReserve(isAccept, claimReserve, comments));
                    claimReservesOrPaymentsToUpdate.add(claimReserve);
                }
                
                if (requiredTask.Status == 'Completed') {
                    insert createFinalTask('Reserves', isAccept, requiredClaim, requiredTask, (String) claimReservesOrPaymentsToUpdate.get(0).get('Notes__c'));
                }
                
                
            }else if (requiredTask.RecordTypeId == CLAIM_TASK_PAYMENT_RT_ID && requiredTask.WhatId.getSObjectType().getDescribe().getName() == 'Claim') {
                // for Claim Payments
                
                List<Claim_Payment__c> claimPayments = [SELECT Id, Name, Status__c, Notes__c, Total_Payment__c, Claim__c 
                                                        FROM Claim_Payment__c 
                                                        WHERE Claim__c = :requiredTask.WhatId
                                                        AND Status__c != 'Cancelled'];
                Double sumOfRelatedPaymentsAmount = getSumOfRelatedPaymentsAmount(claimPayments);
                requiredTask.Description = '';
                for (Claim_Payment__c claimPayment : claimPayments) {
                    isAccept = false;
                    comments = '';
                    if(cpayApprovalMap.containsKey(claimPayment.Id)){
                        isAccept = cpayApprovalMap.get(claimPayment.Id).approvalStatus == 'Approved'?true:false; 
                        comments = cpayApprovalMap.get(claimPayment.Id).approvalComments; 
                    }
                    System.debug('CPAY isAccept: '+isAccept);
                    claimPayment.Notes__c = claimPayment.Notes__c == null ? createNotes(isAccept, comments) : claimPayment.Notes__c + '\n' + createNotes(isAccept, comments);
                    if (isAccept) {
                        if (taskOwner.Payment_Authority_Amount__c >= sumOfRelatedPaymentsAmount) {
                            claimPayment.Status__c = 'Approved';
                            requiredTask.Status = 'Completed';
                            requiredTask.Description += 'Claim Payment - ' + claimPayment.Name + ' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimPayment.Id 
                                + '] (Status - ' + claimPayment.Status__c + '; Amount - ' + claimPayment.Total_Payment__c + ');\n';
                        } else {
                            requiredTask.OwnerId = taskOwner.ManagerId != null ? taskOwner.ManagerId : (claimPaymentGlobalManager != null ? claimPaymentGlobalManager.Id : taskOwner.Id);
                                requiredTask.Description += 'Claim Payment - ' + claimPayment.Name + ' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimPayment.Id 
                                + '] (Status - ' + claimPayment.Status__c + '; Amount - ' + claimPayment.Total_Payment__c + ');\n';   
                        }
                    } else if(claimPayment.Status__c != 'Approved'){
                        claimPayment.Status__c = 'Draft';
                        requiredTask.Status = 'Completed';
                        requiredTask.Description += 'Claim Payment - ' + claimPayment.Name + ' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimPayment.Id 
                            + '] (Status - ' + claimPayment.Status__c + '; Amount - ' + claimPayment.Total_Payment__c + ');\n';
                    }else{
                        
                        requiredTask.Description += 'Claim Payment - ' + claimPayment.Name + ' [' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + claimPayment.Id 
                            + '] (Status - ' + claimPayment.Status__c + '; Amount - ' + claimPayment.Total_Payment__c + ');\n';
                        
                    }
                    feedItems.add(createFeedItemForPayment(isAccept, claimPayment, comments));
                    claimReservesOrPaymentsToUpdate.add(claimPayment);
                }
                
                if (requiredTask.Status == 'Completed') {
                    insert createFinalTask('Payments', isAccept, requiredClaim, requiredTask, (String) claimReservesOrPaymentsToUpdate.get(0).get('Notes__c'));
                }
            }
            
            
            System.debug(claimReservesOrPaymentsToUpdate.size());
            if (claimReservesOrPaymentsToUpdate.size() != 0) {
                update claimReservesOrPaymentsToUpdate;
            }
            if(isClaimReserve){
                List<Claim_Reserve__c> claimReserves = [SELECT Id, Name, Status__c, Notes__c, Reserve_Amount__c, Claim__c, Claim_Coverage__r.Name 
                                                        FROM Claim_Reserve__c 
                                                        WHERE Claim__c = :requiredTask.WhatId 
                                                        AND RecordTypeId = :claimReserveRecordTypeId
                                                        AND Status__c = 'Pending Approval']; 
                if(claimReserves.size() == 0 && requiredClaim.Claim_Adjuster__c!=null){
                    requiredTask.ownerId = requiredClaim.Claim_Adjuster__c;
                }
            }else{
                List<Claim_Payment__c> claimPayments = [SELECT Id, Name, Status__c, Notes__c, Total_Payment__c, Claim__c 
                                                        FROM Claim_Payment__c 
                                                        WHERE Claim__c = :requiredTask.WhatId
                                                        AND Status__c = 'Pending Approval'];
                if(claimPayments.size() == 0 && requiredClaim.Claim_Adjuster__c!=null){
                    requiredTask.ownerId = requiredClaim.Claim_Adjuster__c;
                }
            }
            update requiredTask;
            if (feedItems.size() != 0) {
                insert feedItems;
            }
        }catch(DmlException e){
            //Any type of Validation Rule error message, Required field missing error message, Trigger error message etc..
            //we can get from DmlException
            String msg = 'Error: ';
            //Get All DML Messages
            for (Integer i = 0; i < e.getNumDml(); i++) {
                //Get Validation Rule & Trigger Error Messages
                msg =+ e.getDmlMessage(i) +  '\n' ;
            }
            //throw DML exception message
            // return null;
            System.debug('Error: '+msg);
            throw new AuraHandledException(msg); 
        }catch(Exception e){
            //throw all other exception message
            throw new AuraHandledException('Error: '+e.getMessage());
        }
        finally {
        }
    }
    @AuraEnabled
    public static claimReserveAuraWrapper fetchRole(Id taskRecordId) {
        claimReserveAuraWrapper clWrap = new claimReserveAuraWrapper();
        try{
            
            Task requiredTask = [SELECT Id, RecordTypeId, WhatId, Status, OwnerId,Owner.UserRole.Name, Approval_Type__c FROM Task WHERE Id = :taskRecordId];
            User taskOwner = [SELECT Id, ManagerId, UserRoleId FROM User WHERE Id = :requiredTask.OwnerId];
            Set<ID> allRequiredUserRoles = Utils.getParentRoles(taskOwner.UserRoleId);
            allRequiredUserRoles.add(taskOwner.UserRoleId);
            
            for(UserRole ur: [SELECT Id, Name FROM UserRole WHERE Id IN :allRequiredUserRoles]) {
                System.debug('Role Name  ==  ' + ur.Name);
            }
            
            clWrap.userRoleName = requiredTask.Owner.UserRole.Name;
            if(allRequiredUserRoles.contains(UserInfo.getUserRoleId())){
                clWrap.showApproval = true;
                
            }else{
                clWrap.showApproval = false;
            }
            if(requiredTask.recordTypeId == CLAIM_TASK_RESERVE_RT_ID){
                clWrap.isClaimReserve = true;
            }else if(requiredTask.recordTypeId == CLAIM_TASK_PAYMENT_RT_ID){
                clWrap.isClaimReserve = false;
            }
            return clWrap;
        }catch(Exception ex){
            System.debug('EX Line:::'+ex.getLineNumber()); 
            System.debug('EX Msg:::'+ex.getMessage()); 
            throw new AuraHandledException('Error: '+ex.getMessage());
        }
    }
    
    public class claimReserveAuraWrapper{
        @auraEnabled public Claim_Reserve__c crObj {get;set;}
        @auraEnabled public Claim_payment__c cpayObj {get;set;}
        @auraEnabled public String approvalStatus {get;set;}
        @auraEnabled public String userRoleName {get;set;}
        @auraEnabled public boolean showApproval {get;set;}
        @auraEnabled public String approvalComments{get;set;}
        @auraEnabled public boolean isClaimReserve{get;set;}
    }
    
    
    public static FeedItem createFeedItemForReserve(Boolean isAccept, Claim_Reserve__c claimReserve, String comments){
        FeedItem item = new FeedItem();
        item.ParentId = claimReserve.Claim__c;
        item.Body = 'Claim Reserve on Coverage ' + claimReserve.Claim_Coverage__r.Name + ' has been ' + (isAccept ? 'accepted.' : 'rejected.') + (comments != null ? ' Notes: \n' + comments : '');
        return item;
    }
    
    public static FeedItem createFeedItemForPayment(Boolean isAccept, Claim_Payment__c claimPayment, String comments){
        FeedItem item = new FeedItem();
        item.ParentId = claimPayment.Claim__c;
        item.Body = 'Claim Payment ' + claimPayment.Name + ' has been ' + (isAccept ? 'accepted.' : 'rejected.') + (comments != null ? ' Notes: \n' + comments : '');
        return item;
    }
    
    public static String createNotes(Boolean isAccept, String comments) {
        return '• ' + (isAccept ? 'Accepted' : 'Rejected') + ' by ' + UserInfo.getName() + (comments != null && String.isNotEmpty(comments) ? ' with comments: "' + comments + '".' : ' without any comments.');
    }
    
    public static Double getSumOfRelatedReservesAmount(List<Claim_Reserve__c> claimReserves) {
        Double sumOfRelatedReservesAmount = 0;
        for (Claim_Reserve__c claimReserve : claimReserves) {
            sumOfRelatedReservesAmount += claimReserve.Reserve_Amount__c;
        }
        return sumOfRelatedReservesAmount;
    }
    
    public static Double getSumOfRelatedPaymentsAmount(List<Claim_Payment__c> claimPayments) {
        Double sumOfRelatedPaymentsAmount = 0;
        for (Claim_Payment__c claimPayment : claimPayments) {
            if (claimPayment.Total_Payment__c != null) {
                sumOfRelatedPaymentsAmount += claimPayment.Total_Payment__c;
            }
        }
        return sumOfRelatedPaymentsAmount;
    }
    
    public static Task createFinalTask(String objType, Boolean isAccept, Claim claim, Task task, String notes) {
        Task finalTask = new Task();
        finalTask.RecordTypeId = CLAIM_TASK_RT_ID;
        finalTask.Subject = objType + (isAccept ? ' accepted' : ' rejected') + ' (Claim - ' + claim.Name + ')';
        finalTask.WhatId = claim.Id;
        finalTask.OwnerId = task.CreatedById;
        finalTask.Status = 'Open';
        finalTask.Priority = 'Normal';
        finalTask.Disposition__c = 'Claims';
        finalTask.Description = notes;
        return finalTask;
    }
    
    
    
}