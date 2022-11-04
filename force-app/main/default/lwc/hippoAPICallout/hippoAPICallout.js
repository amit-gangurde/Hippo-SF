import { LightningElement, wire, api } from 'lwc';
import createQuoteAPI from '@salesforce/apex/HippoAPIController.createQuoteAPI';
import retrieveQuoteAPI from '@salesforce/apex/HippoAPIController.retrieveQuoteAPI';
import Id from '@salesforce/user/Id';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const LEAD_FIELDS = ['Lead.Street', 'Lead.City', 'Lead.State', 'Lead.PostalCode', 'Lead.FirstName', 'Lead.LastName', 'Lead.Phone', 'Lead.Email', 'Lead.RecordTypeId', 'Lead.QuoteId__c', 'Lead.Organization__c'];
const USER_FIELDS = ['User.Email', 'User.Authorized_States__c'];

export default class HippoAPICallout extends LightningElement {
    @api recordId;
    searchQuoteId = '';
    recordTypeId = '';
    isLoaded = false;
    userId = Id;
    organizationId = '';
    quoteURL;
    lead;
    user;

    errorURL;

    @wire(getRecord, { recordId: '$recordId', fields: LEAD_FIELDS })
    getLeadRecord({data, error}) {

        console.log('getLeadRecord => ', data, error);

        if (data) {

            this.lead = data;
            this.recordTypeId = data.fields.RecordTypeId.value;
            this.isLoaded = true;

            if (!data.fields.QuoteId__c.value) {

                this.searchQuoteId = '';
                this.quoteURL = '';
            }

            if (!data.fields.Organization__c.value) {

                this.organizationId = '';
            }
            else {

                this.organizationId = data.fields.Organization__c.value;
            }

            if (data.fields.QuoteId__c.value && this.searchQuoteId != data.fields.QuoteId__c.value /*&& data.fields.Organization__c.value*/) {

                this.searchQuoteId = data.fields.QuoteId__c.value;
                this.handleQuoteView();
            }

        } else if (error) {
            //console.log('ERROR =>', JSON.stringify(error));
            this.showToast('Lead Error', error.body.message, 'error');
        }
    }

    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    getUserRecord({data, error}) {
        console.log('getUserRecord => ', data, error);
        if (data) {
            this.user = data;
        } else if (error) {
            //console.log('ERROR =>', JSON.stringify(error));
            this.showToast('User Error', error.body.message, 'error');
        }
    }

    handleQuoteNew() {
        //debugger;
        this.quoteURL='';
        let validation = this.handleValidation(this.lead, this.user);
        //console.log('validation', validation);
        if (validation) {
            createQuoteAPI({
                leadId : this.recordId,
                userId : this.userId
            }).then(result => {
                //console.log('result');
                //console.log(result);
                this.searchQuoteId = result.quoteId;
                //console.log('searchQuoteId => ', this.searchQuoteId);
                getRecordNotifyChange([{recordId: this.recordId}]);
                this.handleQuoteView();
            })
                .catch(error => {
                    //console.error('error');
                    //console.error(error);
                    this.showToast('Something went wrong retrieving QuoteId', error.body.message, 'error', 'sticky');
                });
        }

    }

    handleQuoteView() {
        //debugger;
        this.quoteURL = '';
        //this.isLoaded = false;
        retrieveQuoteAPI({
            quoteId : this.searchQuoteId,
            recordTypeId : this.recordTypeId,
            userId : this.userId,
            organizationId : this.organizationId
        }).then(result => {
            //console.log('result2');
            //console.log(result);
            //console.log(result.quoteUrl);
            this.quoteURL = result.quoteUrl;
            //this.isLoaded = true;
            //this.errorURL = undefined;
        })
            .catch(error => {
                //console.error('error2');
                //console.error(error);
                this.showToast('Something went wrong retrieving QuoteURL', error.body.message, 'error', 'sticky');
                //this.errorURL = error.body.message;
                //this.isLoaded = true;
            });
    }

    handleValidation(leadRecord, userRecord) {
        let leadFields = leadRecord.fields;
        let leadMissingFields = Object.entries(leadFields).filter(entry => {
            let field = entry[0];
            let fieldValues = entry[1];
            return field != 'QuoteId__c' && field != 'Organization__c' && !fieldValues.value;
        });

        let leadMissingFieldNames = leadMissingFields.map(entry => {
            if (entry[0] === 'PostalCode') {
                return 'Zip/Postal Code';
            } else if (entry[0] === 'FirstName') {
                return 'First Name';
            } else if (entry[0] === 'LastName') {
                return 'Last Name';
            }
            return entry[0];
        });

        if (leadMissingFieldNames.length) {
            this.showToast("Error!!", "Require Lead fields are missing: " + leadMissingFieldNames.toString().replaceAll(",",", "), "error");
            //console.error('error leadMissingFieldNames', leadMissingFieldNames.toString().replaceAll(",",", "));
        }

        let userFields = userRecord.fields;
        let userMissingFields = Object.entries(userFields).filter(entry => {
            let field = entry[0];
            let fieldValues = entry[1];
            return !fieldValues.value;
        });

        let userMissingFieldNames = userMissingFields.map(entry => {
            if (entry[0] === 'Authorized_States__c') {
                return 'Authorized States';
            }
            return entry[0];
        })

        if (userMissingFieldNames.length) {
            this.showToast("Error!!", "Require User fields are missing: " + userMissingFieldNames.toString().replaceAll(",",", "), "error");
            //console.error('error Street', userMissingFieldNames.toString().replaceAll(",",", "));
        }

        if (leadMissingFieldNames.length || userMissingFieldNames.length) {
            return false;
        }

        return true;
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        })
        this.dispatchEvent(event)
    }

}