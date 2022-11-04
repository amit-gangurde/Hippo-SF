@isTest
private class LangCaseTriggerTest {
    static void setUp(String text, List<String> tagNames) {
        String domain = 'hippo.lang.ai';
        String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYW5nX2tleSI6Ii9KSGNHVU1MNUhXRUp4NTZHdHY5V2JZZ1UwdmE4MUdCNkdhK3JSTXRrUkE9IiwibmFtZSI6IkFQSSB0b2tlbiIsImRvbWFpbiI6ImhpcHBvLTk0ODU2MjAiLCJhdWQiOiJMYW5nLmFpIEFQSSIsImlzcyI6IkxhbmcuYWkifQ._zWuZif4X8ezaS7RmjxRytpdGTQqz4NWpOU1keazlNo';
        String project_id = 'Zjozc8YQtNVOBcRh';
        Test.setMock(HttpCalloutMock.class, new LangHttpCalloutMock(domain, token, project_id, text, tagNames));

    }

    static Case createCase(String lossText, String damageText, Boolean isClaim) {
        RecordType recordType = [SELECT Id, Name From RecordType WHERE Name=:'Claim'];
        if (!isClaim) {
            recordType = [SELECT Id, Name From RecordType WHERE Name=:'Billing'];
        }
        Case caseElem = new Case(
            Subject='Test case',
            Loss_Description__c=lossText,
            Damage_Description__c=damageText,
            RecordTypeId=recordType.Id,
            Claims_Agreement__c='Agree',
            AccountId='0014V00001MljCOQAZ',
            Insurance_Policy__c='0YT6g000000hElzGAE',
            // This values are used in the Testing instance
            // AccountId='0014V00001MlIidQAF',
            // Insurance_Policy__c='0YT4V000000l38HWAQ',
            Peril__c='lightning'
        );
        insert caseElem;
    return caseElem;
    }

    @isTest static void testLangCaseTrigger() {
        // Set mock callout class 
        String lossText = 'the loss description for this test';
        String damageText = 'the damage description for this test';
        List<String> tagNames = new List<String>{'Entire House', 'Cause: Wildfire', 'Origin: Roof'};
        setUp(lossText + '. ' + damageText, tagNames);
        Test.startTest();
        Case caseElem = createCase(lossText, damageText, true);
        Test.stopTest();
        Case updatedCase = [SELECT Location__c, Cause__c, Origin__c  FROM Case WHERE Id = :caseElem.Id];
        system.debug(updatedCase);
        System.assertEquals(updatedCase.Location__c, 'Entire House');
        System.assertEquals(updatedCase.Cause__c, 'Cause: Wildfire');
        System.assertEquals(updatedCase.Origin__c, 'Origin: Roof');
    }
    @isTest static void testLangCaseTriggerWithPriority() {
        // Set mock callout class 
        String lossText = 'the loss description for this test';
        String damageText = 'the damage description for this test';
        List<String> tagNames = new List<String>{
            'Family Room', 'Roof', 
            'Cause: Toilet', 'Cause: Washing Machine',
            'Origin: Bathtub', 'Origin: Service Line'
        };
        setUp(lossText + '. ' + damageText, tagNames);
        Test.startTest();
        Case caseElem = createCase(lossText, damageText, true);
        Test.stopTest();
        Case updatedCase = [SELECT Location__c, Cause__c, Origin__c  FROM Case WHERE Id = :caseElem.Id];
        system.debug(updatedCase);
        System.assertEquals(updatedCase.Location__c, 'Roof');
        System.assertEquals(updatedCase.Cause__c, 'Cause: Washing Machine');
        System.assertEquals(updatedCase.Origin__c, 'Origin: Service Line');
   }
    @isTest static void testLangCaseTriggerOnlyClaims() {
        // Set mock callout class 
        String lossText = 'the loss description for this test';
        String damageText = 'the damage description for this test';
        List<String> tagNames = new List<String>{
            'Family Room', 'Roof', 
            'Cause: Toilet', 'Cause: Washing Machine',
            'Origin: Bathtub', 'Origin: Service Line'
        };
        setUp(lossText + '. ' + damageText, tagNames);
        Test.startTest();
        Case caseElem = createCase(lossText, damageText, false);
        Test.stopTest();
        Case updatedCase = [SELECT Location__c, Cause__c, Origin__c  FROM Case WHERE Id = :caseElem.Id];
        system.debug(updatedCase);
        System.assertEquals(updatedCase.Location__c, null);
        System.assertEquals(updatedCase.Cause__c, null);
        System.assertEquals(updatedCase.Origin__c, null);
   }
}

/*private class LangCaseTriggerTest {
    static void setUp(String text, List<String> tagNames) {
        String domain = 'hippo.lang.ai';
        String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsYW5nX2tleSI6Ii9KSGNHVU1MNUhXRUp4NTZHdHY5V2JZZ1UwdmE4MUdCNkdhK3JSTXRrUkE9IiwibmFtZSI6IkFQSSB0b2tlbiIsImRvbWFpbiI6ImhpcHBvLTk0ODU2MjAiLCJhdWQiOiJMYW5nLmFpIEFQSSIsImlzcyI6IkxhbmcuYWkifQ._zWuZif4X8ezaS7RmjxRytpdGTQqz4NWpOU1keazlNo';
        String project_id = 'Zjozc8YQtNVOBcRh';
        Test.setMock(HttpCalloutMock.class, new LangHttpCalloutMock(domain, token, project_id, text, tagNames));

    }
    static Case createCase(String lossText, String damageText, Boolean isClaim) {
        RecordType recordType = [SELECT Id, Name From RecordType WHERE Name=:'Claim'];
        if (!isClaim) {
            recordType = [SELECT Id, Name From RecordType WHERE Name=:'Billing'];
        }
        Case caseElem = new Case(
            Subject='Test case',
            Loss_Description__c=lossText,
            Damage_Description__c=damageText,
            RecordTypeId=recordType.Id,
            Claims_Agreement__c='Agree',
            AccountId='0014V00001MlIidQAF',
            Insurance_Policy__c='0YT4V000000l38HWAQ'
        );
        insert caseElem;
    return caseElem;
    }
    @isTest static void testLangCaseTrigger() {
        // Set mock callout class 
        String lossText = 'the loss description for this test';
        String damageText = 'the damage description for this test';
        List<String> tagNames = new List<String>{'Entire House', 'Cause: Wildfire', 'Origin: Roof'};
        setUp(lossText + '. ' + damageText, tagNames);
        Test.startTest();
        Case caseElem = createCase(lossText, damageText, true);
        Test.stopTest();
        Case updatedCase = [SELECT Location__c, Cause__c, Origin__c  FROM Case WHERE Id = :caseElem.Id];
        system.debug(updatedCase);
        System.assertEquals(updatedCase.Location__c, 'Entire House');
        System.assertEquals(updatedCase.Cause__c, 'Cause: Wildfire');
        System.assertEquals(updatedCase.Origin__c, 'Origin: Roof');
    }
    @isTest static void testLangCaseTriggerWithPriority() {
        // Set mock callout class 
        String lossText = 'the loss description for this test';
        String damageText = 'the damage description for this test';
        List<String> tagNames = new List<String>{
            'Family Room', 'Roof', 
            'Cause: Toilet', 'Cause: Washing Machine',
            'Origin: Bathtub', 'Origin: Service Line'
        };
        setUp(lossText + '. ' + damageText, tagNames);
        Test.startTest();
        Case caseElem = createCase(lossText, damageText, true);
        Test.stopTest();
        Case updatedCase = [SELECT Location__c, Cause__c, Origin__c  FROM Case WHERE Id = :caseElem.Id];
        system.debug(updatedCase);
        System.assertEquals(updatedCase.Location__c, 'Roof');
        System.assertEquals(updatedCase.Cause__c, 'Cause: Washing Machine');
        System.assertEquals(updatedCase.Origin__c, 'Origin: Service Line');
    }
    @isTest static void testLangCaseTriggerOnlyClaims() {
        // Set mock callout class 
        String lossText = 'the loss description for this test';
        String damageText = 'the damage description for this test';
        List<String> tagNames = new List<String>{
            'Family Room', 'Roof', 
            'Cause: Toilet', 'Cause: Washing Machine',
            'Origin: Bathtub', 'Origin: Service Line'
        };
        setUp(lossText + '. ' + damageText, tagNames);
        Test.startTest();
        Case caseElem = createCase(lossText, damageText, false);
        Test.stopTest();
        Case updatedCase = [SELECT Location__c, Cause__c, Origin__c  FROM Case WHERE Id = :caseElem.Id];
        system.debug(updatedCase);
        System.assertEquals(updatedCase.Location__c, null);
        System.assertEquals(updatedCase.Cause__c, null);
        System.assertEquals(updatedCase.Origin__c, null);
   }
}*/