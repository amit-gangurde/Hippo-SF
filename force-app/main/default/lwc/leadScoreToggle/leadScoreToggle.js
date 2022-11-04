import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getLeadScores from '@salesforce/apex/Utils.getLeadScores';
import toggleLeadScore from '@salesforce/apex/CustomMetadataHelper.toggleLeadScore';

export default class LeadScoreToggle extends LightningElement {

    @track toggled_score_label;
    @track toggled_score_value;
    @track jobIdSaveResult;
    @track error;
    @track lead_scores = [];

    @wire(getLeadScores) //lead_scores;
    wiredLeadScores({ error, data }) {
        if (data) {
            console.log('leadScores() data...' + JSON.stringify(data));
            for(const item of data){
                const leadscoreitem = {
                    apiName: item.QualifiedApiName,
                    label: item.MasterLabel,
                    value: item.Checked__c,
                    additionalText: item.Additional_Text__c,
                    friendly_label: item.MasterLabel + (item.Additional_Text__c !== undefined ? item.Additional_Text__c : '')
                };
                this.lead_scores.push(leadscoreitem);
            }
            console.log('lead_scores ----- ',this.lead_scores);
        } else if (error) {
            this.error = error;
            console.error(error);
        }
    }

    constructor() {

        super();
        console.log('constructor()...');
        console.log('constructor lead_scores == ' + this.lead_scores);
    }

    connectedCallback() {

        console.log('connectedCallback()...');
        console.log('LeadScoreToggle LWC Component Loaded Successfully');
        console.log('lead_scores == ' + this.lead_scores);
        console.log('connectedCallback() this.lead_scores...' + JSON.stringify(this.lead_scores));
    }

    showSuccessToast(leadScore, leadScoreValue) {

        const event = new ShowToastEvent({
            title: 'Success!',
            variant: 'success',
            mode: 'dismissable',
            message: 'Successfully saved lead score {0}! Value was chaned to {1}',
            messageData: [leadScore, leadScoreValue]
        });
        this.dispatchEvent(event);
    }

    showErrorToast(error) {

        const event = new ShowToastEvent({
            title: 'Application Error',
            variant: 'error',
            mode: 'dismissable',
            message: 'Something went wrong, {0}',
            messageData: [error]
        });
        this.dispatchEvent(evt);
    }

    handleChange(event) {

        debugger;
        this.toggled_score_label = event.target.name; //label;
        this.toggled_score_value = event.target.checked;
        toggleLeadScore({ leadScore: this.toggled_score_label, checked: this.toggled_score_value })
            .then(result => {
                this.jobIdSaveResult = result;
                this.error = undefined;
                this.showSuccessToast(this.toggled_score_label, this.toggled_score_value.toString());
            })
            .catch(error => {
                this.error = error;
                this.jobIdSaveResult = undefined;
                showErrorToast(this.error);
            })
    }
}