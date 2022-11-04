@IsTest
public with sharing class ContentDocumentLinkTriggerTest {
    @IsTest
    static void deleteDocLinkCustomPermission_Test() {
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
        ContentDocumentLink cdl;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert userWithCustomPermission;
        }
        
        System.runAs(userWithCustomPermission) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            ContentVersion cv = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'test',
                VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body'),
                FirstPublishLocationId = userWithCustomPermission.Id
            );
            insert cv;
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            cdl = new ContentDocumentLink(
                LinkedEntityId = acc.Id,
                ContentDocumentId = cv.ContentDocumentId
            );
            insert cdl;
            // cdl = [
            //   SELECT Id
            //   FROM ContentDocumentLink
            //   WHERE LinkedEntityId = :acc.Id
            // ];
            try {
                delete cdl;
            } catch (Exception e) {
                System.assert(
                    e.getMessage()
                    .contains(
                        'You do not have permission to remove documents from a record'
                    )
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
            delete cdl;
        }
    }
}