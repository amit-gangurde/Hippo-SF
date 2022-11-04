@IsTest
public class ContentManagerServiceTest {
    @IsTest
    static void serializesContentDocumentsGivenLinkedEntityId() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        ContentVersion cv = new ContentVersion(
          Title = 'Test',
          PathOnClient = 'test',
          VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
          LinkedEntityId = acc.Id,
          ContentDocumentId = cv.ContentDocumentId
        );
        insert cdl;

        String json = ContentManagerService.getContentDetails(acc.Id);
        System.Assert(json.contains('"Test"'));
    }

    @IsTest
    static void returnsCorrectFileType() {
        System.assertEquals('application/vnd.openxmlformats-officedocument.wordprocessingml.document', ContentManagerService.ContentType('docx'));
        System.assertEquals('application/vnd.ms-excel', ContentManagerService.ContentType('csv'));
        System.assertEquals('audio/wav', ContentManagerService.ContentType('wav'));
        System.assertEquals('video/x-ms-wmv', ContentManagerService.ContentType('wmv'));
        System.assertEquals('audio/mpeg', ContentManagerService.ContentType('mp3'));
        System.assertEquals('video/mp4', ContentManagerService.ContentType('mp4'));
        System.assertEquals('image/png', ContentManagerService.ContentType('png'));
        System.assertEquals('application/pdf', ContentManagerService.ContentType('pdf'));
        System.assertEquals('image/jpeg', ContentManagerService.ContentType('jpg'));
    }
}