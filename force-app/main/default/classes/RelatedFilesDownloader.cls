public without sharing class RelatedFilesDownloader {
    public PageReference donloadAllRelatedFiles (String recordId) {
        
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink WHERE LinkedEntityId =: recordId];
        
        Set<Id> contentDocumentsId = new Set<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            contentDocumentsId.add(contentDocumentLink.ContentDocumentId);
        }
        
        //List<ContentDocument> contentDocuments = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentsId];
        
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentsId];
        
        List<ContentDistribution> contentDistributions = new List<ContentDistribution>();
        for (ContentVersion contentVersion : contentVersions) {
            ContentDistribution cd = new ContentDistribution();
            cd.Name = '(Distribution) ' + contentDocument.Title;
            cd.ContentVersionId = contentVersion.Id;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesLinkLatestVersion = true;
            cd.PreferencesNotifyOnVisit = false;
            cd.PreferencesPasswordRequired = false;
            cd.PreferencesAllowOriginalDownload = true;
            contentDistributions.add(cd);
        }
        insert contentDistributions;
        
        Set<Id> contentDistributionIds = new Set<Id>();
        for (ContentDistribution contentDistribution : contentDistributions) {
            contentDistributionIds.add(contentDistribution.Id);
        }
        
        List<ContentDistribution> distributions = [SELECT Id, ContentDocumentId, ContentDownloadUrl, DistributionPublicUrl FROM ContentDistribution WHERE Id IN :contentDistributionIds];
        System.debug(distributions.get(0).ContentDownloadUrl);
        return new PageReference(distributions.get(0).ContentDownloadUrl);
        
    }
}