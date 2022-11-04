import {LightningElement, api, wire, track} from 'lwc';
//import anyAgentAvailable from '@salesforce/apex/AgentAvailabilityController.anyAgentAvailable';
import HAS_available_for_Warm_Transfer from '@salesforce/label/c.HAS_available_for_Warm_Transfer';
import HAS_not_available_for_Warm_Transfer from '@salesforce/label/c.HAS_not_available_for_Warm_Transfer';

// Import message service features required for subscribing and the message channel
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from 'lightning/messageService';
import lmsAgentAvailabilityMC from "@salesforce/messageChannel/CTIAgentAvailability__c";

export default class LwcAgentAvailability extends LightningElement {

    subscription = null;
    isAgentAvailable;

    label = {
        HAS_available_for_Warm_Transfer,
        HAS_not_available_for_Warm_Transfer
    };

    //@api strQueueDevName;
    //@track isAgentAvailable = false;
    //@track error;

    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {

        debugger;
        console.log('LwcAgentAvailability LWC Component Loaded Successfully');
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {

        console.log('LwcAgentAvailability LWC Component Unloaded Successfully');
        this.unsubscribeToMessageChannel();
    }

    @wire(MessageContext)
    messageContext;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                lmsAgentAvailabilityMC,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        this.isAgentAvailable = message.IsAgentAvailable;
    }

    // Helper
    dispatchToast(error) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error loading agent availability',
                message: reduceErrors(error).join(', '),
                variant: 'error',
            })
        );
    }

    /*
    @wire(anyAgentAvailable, { queueDevName: '$strQueueDevName' })
    getAgentAvailability({data, error}) {
        debugger;
        console.log('DATA returned from APEX anyAgentAvailable =>', JSON.stringify(data));
        if (data) {
            this.isAgentAvailable = data;
        }
        else if (error) {
            console.log('ERROR returned from APEX anyAgentAvailable =>', JSON.stringify(error));
            this.error = error;
        }
    }
     */

}