@IsTest
public class RelatedFilesDownloaderTest {
    @IsTest
    static void downloadsAllRelatedFilesGivenEntityId() {
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

        RelatedFilesDownloader controller = new RelatedFilesDownloader();
        controller.donloadAllRelatedFiles(acc.Id);
    }
}