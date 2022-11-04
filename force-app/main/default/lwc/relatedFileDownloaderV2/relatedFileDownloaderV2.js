import { LightningElement, api, track, wire } from 'lwc';
import getContentDetails from '@salesforce/apex/ContentManagerService.getContentDetails';
import { NavigationMixin } from 'lightning/navigation';

export default class RelatedFileDownloaderV2 extends NavigationMixin(LightningElement) {

    @api recordId;
    @api showsync; 
    @track dataList;
    isLoading = false;
    finalDownloadUrl = '';

    connectedCallback() {
        this.handleSync();
    }

    getBaseUrl(){
        let baseUrl = 'https://'+location.host+'/';
        return baseUrl;
    }

    // handleSync(){
    //     this.isLoading = true;
    //     getContentDetails({
    //         recordId : this.recordId
    //     })
    //     .then(result => {
    //         let parsedData = JSON.parse(result);
    //         let stringifiedData = JSON.stringify(parsedData);
    //         let finalData = JSON.parse(stringifiedData);
    //         let baseUrl = this.getBaseUrl();
    //         finalData.forEach(file => {
    //             file.downloadUrl = baseUrl+'sfc/servlet.shepherd/document/download/'+file.ContentDocumentId;
    //             file.fileUrl = baseUrl+'sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId='+file.Id;
    //         });
    //         this.dataList = finalData;
    //     })
    //     .catch(error => {
    //         console.error('**** error **** \n ',error)
    //     })
    //     .finally(()=>{
    //         this.isLoading = false;
    //     });
    // }

    handleSync(){
        this.isLoading = true;
        getContentDetails({
            recordId : this.recordId
        })
        .then(result => {
            let parsedData = JSON.parse(result);
            let stringifiedData = JSON.stringify(parsedData);
            let finalData = JSON.parse(stringifiedData);
            let baseUrl = this.getBaseUrl();
            let delimitedSelectedIdList = '';
            finalData.forEach(file => {
                delimitedSelectedIdList += file.Id + '/'
            });
            delimitedSelectedIdList = delimitedSelectedIdList.slice(0,delimitedSelectedIdList.length-1);
            this.finalDownloadUrl += baseUrl + '/sfc/servlet.shepherd/version/download/' + delimitedSelectedIdList + '?';
            console.log(this.finalDownloadUrl);
            this.dataList = finalData;
        })
        .catch(error => {
            console.error('**** error **** \n ',error)
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }

    // downloadAllFiles(){
    //     this.dataList.forEach(file => {
    //         this[NavigationMixin.Navigate]({
    //             type: 'standard__webPage',
    //             attributes: {
    //                 url: file.downloadUrl
    //             }
    //         }, false 
    //         );
    //         console.log("S U C C E S S");
    //     })
    // }

    downloadAllFiles(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.finalDownloadUrl
            }
        }, false 
        );
        console.log("S U C C E S S");
    }

}