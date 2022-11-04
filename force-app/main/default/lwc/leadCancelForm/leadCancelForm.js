import {api, LightningElement} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadCancelForm extends LightningElement {

    @api recordId;

    connectedCallback() {

        console.log('LeadCancelForm LWC Component Loaded Successfully');
        console.log('recordId == ' + this.recordId);
    }

    handleSuccess(event) {

        console.log('updated lead id == ' + event.detail.id);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Lead successfully updated.',
            variant: 'success',
        }));
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleReset(event) {

        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );

        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }

        this.dispatchEvent(new CustomEvent('close'));
    }
}