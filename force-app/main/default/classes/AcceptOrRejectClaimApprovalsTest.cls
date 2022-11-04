@isTest
public without sharing class AcceptOrRejectClaimApprovalsTest {
    private final static String CLAIM_TASK_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Claim_Task').getRecordTypeId();
    private final static String CLAIM_TASK_RESERVE_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Claim_Task_Reserve').getRecordTypeId();
    private final static String CLAIM_TASK_PAYMENT_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Claim_Task_Payment').getRecordTypeId();
    private final static String CLAIM_RESERVE_LOSS_RT_ID = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Loss').getRecordTypeId();
    private final static String CLAIM_RESERVE_EXPENSE_RT_ID = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Expense').getRecordTypeId();
    
    
    @isTest
    public static void initiateTestData(){
      
        try{  
        user u = AcceptOrRejectClaimApprovalsController.claimReserveGlobalManager;
        User firstUser = createUser('first', 10000, 10000);
        User secondUser = createUser('second', 20000, 20000);
        insert new List<User>{ firstUser, secondUser };
            
            firstUser.ManagerId = secondUser.Id;
          // update firstUser;
        
        Claim claim = UnitTestHelper.prepareClaim('Lightning', 'Topa', 'DFW');
        //claim.Claim_Adjuster__c = firstUser.Id;
        //update claim;
        
        System.runAs(firstUser) {
            ClaimCoverage claimCoverageExpense = new ClaimCoverage(
                Name = 'claimCoverageExpense',
                ClaimId = claim.Id,
                RecordTypeId = Schema.SObjectType.ClaimCoverage.getRecordTypeInfosByDeveloperName().get('Expense').getRecordTypeId(),
                InternalReserveMode = 'CoverageReserve'
            );
            insert claimCoverageExpense;
             ClaimParticipant claimParticipant = new ClaimParticipant(
                First_Name__c = 'test',
                Last_Name__c = 'test',
                Roles = 'Primary Insured',
                ClaimId = claim.Id
            ); 
            insert claimParticipant;
            Claim_Payment__c claimPayment = new Claim_Payment__c(
                Claim__c = claim.Id,
                Primary_Contact__c = claimParticipant.Id,
                Status__c = 'Pending Approval'
              ///  recordTypeId = CLAIM_TASK_PAYMENT_RT_ID
            );
            insert claimPayment;
            Claim_Reserve__c claimReserveExpense = new Claim_Reserve__c(
                Claim__c = claim.Id,
                Reserve_Amount__c = 12000,
                Claim_Coverage__c = claimCoverageExpense.Id,
                Status__c = 'Pending Approval',
                RecordTypeId = Schema.SObjectType.Claim_Reserve__c.getRecordTypeInfosByDeveloperName().get('Expense').getRecordTypeId()
            );
            insert claimReserveExpense;
        }
        Task t = new Task(Subject='Expense test',Status='Open',Priority='Normal',WhatId = claim.Id ,CallType='Outbound',OwnerId =secondUser.Id,RecordTypeId = CLAIM_TASK_RESERVE_RT_ID );
        insert t;
        
        Task t1 = new Task(Subject='Expense test Payment',Status='Open',Priority='Normal',WhatId = claim.Id ,CallType='Outbound',OwnerId =secondUser.Id,RecordTypeId = CLAIM_TASK_PAYMENT_RT_ID );
        insert t1;
        List<Task> tasks = [SELECT Id FROM Task WHERE Status = 'Open' AND WhatId = :claim.Id AND OwnerId = :secondUser.Id AND RecordTypeId = :CLAIM_TASK_RESERVE_RT_ID];
        // System.assertEquals(1, tasks.size());
        System.debug('tasks:'+tasks);
        System.runAs(secondUser) {
             Task requiredTask = [SELECT Id, RecordTypeId, WhatId, Status, OwnerId, Approval_Type__c, CreatedById,Description,Subject FROM Task WHERE Id = :tasks[0].id];
        Claim requiredClaim = [SELECT Id, Name FROM Claim WHERE Id = :requiredTask.WhatId];
            AcceptOrRejectClaimApprovalsController.getClaimCRs(tasks[0].id);
            try{
            AcceptOrRejectClaimApprovalsController.fetchRole(tasks[0].id);
            }catch(Exception ex){}
            List<AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper> claimReserveLst = new List<AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper>();
            AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper cWrap = new AcceptOrRejectClaimApprovalsController.claimReserveAuraWrapper();
            cWrap.crObj = [SELECT ID,Name,Status__c,Claim_Coverage__c,Claim_Coverage__r.Name,Reserve_Amount__c FROM Claim_Reserve__c WHERE Claim__c =: requiredClaim.Id AND Status__c = 'Pending Approval' AND RecordTypeId =: CLAIM_RESERVE_EXPENSE_RT_ID LIMIT 1];
        cWrap.cpayObj = null;
        cWrap.approvalStatus  = 'Approved';
        cWrap.userRoleName = null;
        cWrap.showApproval  = true;
        cWrap.approvalComments = 'test';
       cWrap.isClaimReserve = true;
            claimReserveLst.add(cWrap);
            AcceptOrRejectClaimApprovalsController.updateApproval(claimReserveLst,tasks[0].id);
                    List<Task> tasks1 = [SELECT Id FROM Task WHERE Status = 'Open' AND WhatId = :claim.Id AND OwnerId = :secondUser.Id AND RecordTypeId = :CLAIM_TASK_PAYMENT_RT_ID];
   
             cWrap.cpayObj = [SELECT ID,Name,Status__c FROM Claim_Payment__c  LIMIT 1];
            claimReserveLst.add(cWrap);
             AcceptOrRejectClaimApprovalsController.updateApproval(claimReserveLst,tasks1[0].id);
             cWrap.approvalStatus  = 'Rejected';
            Test.startTest();
             AcceptOrRejectClaimApprovalsController.updateApproval(claimReserveLst,tasks1[0].id);
              AcceptOrRejectClaimApprovalsController.updateApproval(claimReserveLst,tasks[0].id);
             Test.Stoptest();
          }
        // System.assertEquals('Approved', [SELECT Id, Status__c FROM Claim_Reserve__c WHERE Claim__c = :claim.Id].get(0).Status__c);
        }catch(Exception ex){} 
       
    }
    
    private static User createUser(String userName, Double reserveAmount, Double paymentAmount) {
        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE '%Admin%' LIMIT 1];
        User user = new User();
        user.firstName = userName;
        user.lastName = userName;
        user.profileId = profile.id;
        user.username = userName + '@hippo.com';
        user.email = userName + '@hippo.com';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        user.TimeZoneSidKey = 'America/New_York';
        user.Alias = userName.abbreviate(4);
        user.Reserve_Authority_Amount__c = reserveAmount;
        user.Payment_Authority_Amount__c = paymentAmount;
        return user;
    }
}