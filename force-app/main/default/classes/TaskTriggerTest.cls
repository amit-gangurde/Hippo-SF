@IsTest
private class TaskTriggerTest {
  @IsTest
  static void testUpdateParentLeads() {
    UnitTestHelper.prepareDevEnvCustomSettings();

    Lead ld = UnitTestHelper.prepareB2CLead(true, 'MD');
    System.assertNotEquals(null, ld.OwnerId);

    test.startTest();

    Task tsk = UnitTestHelper.getLeadTask(
      false,
      ld.OwnerId,
      ld.Id,
      null,
      'testUpdateParentLeads'
    );
    tsk.Disposition__c = 'Inside Rep';
    insert tsk;
    List<Lead> leads = [
      SELECT Id, Status, Disqualified_Reason__c
      FROM Lead
      WHERE Id = :ld.Id
    ];
    System.assertEquals(1, leads.size());
    //System.assertEquals('Cancelled', leads[0].Status);
    System.assertEquals('Inside Agent', leads[0].Disqualified_Reason__c);

    /*
        tsk.Disposition__c = 'Outside Partner'; // value is no longer in use (inactive in picklist)
        update tsk;
        leads = [Select Id, Status, Disqualified_Reason__c From Lead Where Id =: ld.Id];
        System.assertEquals(1, leads.size());
        // System.assertEquals('Cancelled', leads[0].Status);
        System.assertEquals('Outside Agent', leads[0].Disqualified_Reason__c);
         */

    tsk.Disposition__c = 'DNC';
    update tsk;
    leads = [
      SELECT Id, Status, Disqualified_Reason__c
      FROM Lead
      WHERE Id = :ld.Id
    ];
    System.assertEquals(1, leads.size());
    //System.assertEquals('Cancelled', leads[0].Status);
    System.assertEquals('Unable to contact', leads[0].Disqualified_Reason__c);

    tsk.Disposition__c = 'Fake Lead';
    update tsk;
    leads = [
      SELECT Id, Status, Disqualified_Reason__c
      FROM Lead
      WHERE Id = :ld.Id
    ];
    System.assertEquals(1, leads.size());
    //System.assertEquals('Cancelled', leads[0].Status);
    System.assertEquals('Fake Contact Info', leads[0].Disqualified_Reason__c);

    /*
        tsk.Disposition__c = 'Already Purchased with another company';
        update tsk;
        leads = [Select Id, Status, Disqualified_Reason__c From Lead Where Id =: ld.Id];
        System.assertEquals(1, leads.size());
        System.assertEquals('Cancelled', leads[0].Status);
        System.assertEquals('Not Interested', leads[0].Disqualified_Reason__c);
        */

    test.stopTest();
  }

  @IsTest
  static void testCreateFollowUpTasks() {
    UnitTestHelper.prepareDevEnvCustomSettings();

    Lead ld = UnitTestHelper.prepareB2CLead(true, 'MD');

    test.startTest();

    Messaging.SingleEmailMessage mail = UnitTestHelper.getEmailMessage(
      ld,
      true
    );
    List<Messaging.SendEmailResult> results = Messaging.sendEmail(
      new List<Messaging.SingleEmailMessage>{ mail }
    );
    system.debug('send email results: ' + results);

    test.stopTest();

    List<Task> email_Tasks = [SELECT Id FROM Task WHERE TaskSubtype = 'Email'];
    System.assertEquals(1, email_Tasks.size());
    List<Task> followUp_Tasks = [
      SELECT Id
      FROM Task
      WHERE Subject = 'Follow up on email'
    ];
    //System.assertEquals(1, followUp_Tasks.size());
  }

  @IsTest
  static void deleteTaskCustomPermission_Test() {
    User userWithCustomPermission = new User(
      FirstName = 'Test',
      LastName = 'User',
      Username = 'user@hippo.com',
      Email = 'user@hippo.com',
      Alias = 'testu',
      TimeZoneSidKey = 'America/Denver',
      LocaleSidKey = 'en_us',
      EmailEncodingKey = 'UTF-8',
      ProfileId = [SELECT Id FROM Profile LIMIT 1]
      .Id,
      LanguageLocaleKey = 'en_us'
    );
    Task t;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert userWithCustomPermission;
      t = new Task(
        Subject = 'Test task',
        Status = 'New',
        OwnerId = userWithCustomPermission.Id
      );
      insert t;
    }

    System.runAs(userWithCustomPermission) {
      try {
        delete t;
      } catch (Exception e) {
        System.assert(
          e.getMessage().contains('You do not have permission to delete tasks')
        );
      }
    }

    System.runAs(new User(Id = UserInfo.getUserId())) {
      PermissionSet ps = new PermissionSet(Label = 'mockPs', Name = 'mockPs');
      insert ps;

      SetupEntityAccess sea = new SetupEntityAccess(
        ParentId = ps.Id,
        SetupEntityId = [
          SELECT Id
          FROM CustomPermission
          WHERE DeveloperName = 'AllowDeleteTasksAndDocs'
        ][0]
        .Id
      );
      insert sea;

      PermissionSetAssignment psa = new PermissionSetAssignment(
        AssigneeId = userWithCustomPermission.Id,
        PermissionSetId = ps.Id
      );
      insert psa;
    }

    System.runAs(userWithCustomPermission) {
      delete t;
    }
  }
}