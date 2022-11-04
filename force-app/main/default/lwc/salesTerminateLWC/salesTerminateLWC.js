import { LightningElement,api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import checkAlreadyTerminated from '@salesforce/apex/SalesTerminateController.checkAlreadyTerminated';
import terminateTheAgent from '@salesforce/apex/SalesTerminateController.terminateTheAgent';
import AgentTerminatedSuccess from '@salesforce/label/c.AgentTerminatedSuccess';
import TerminateAgent from '@salesforce/label/c.TerminateAgent';
import AgentAlreadyTerminated from '@salesforce/label/c.AgentAlreadyTerminated';
import { CurrentPageReference } from 'lightning/navigation';

export default class SalesTerminateLWC extends LightningElement {
    
isModalOpen = true;
spinner = true;
isAlreadyTerminated = false;
terminationDone = false;
showTerminate = true;
cancelActionName = 'Cancel';
recordId;

 @wire(CurrentPageReference)
 getStateParameters(currentPageReference) {
     if (currentPageReference) {
         this.recordId = currentPageReference.state.recordId;
     }
 }

 label = {
        AgentTerminatedSuccess,
        TerminateAgent,
        AgentAlreadyTerminated
    };
connectedCallback(){
   // alert(this.recordId)
     checkAlreadyTerminated({ recordId: this.recordId})
		.then(result => {
         //   alert(result)
        if(result == "true"){
            this.isAlreadyTerminated = result;
            this.showTerminate = false;
            this.cancelActionName = 'OK';
        }   
        this.spinner = false;     
		})
		.catch(error => {
            alert(error.body.message)
            this.spinner = false;
		})

 }

handleCancel(){
  this.dispatchEvent(new CloseActionScreenEvent());
}

handleTerminate(){
    this.spinner = true;
 terminateTheAgent({ recordId: this.recordId })
		.then(result => {
           // alert('terminated')
           this.isAlreadyTerminated = false;
            this.terminationDone = true;
            this.showTerminate = false;
            this.cancelActionName = 'OK';
            this.spinner = false;   

             eval("$A.get('e.force:refreshView').fire();");  
		})
		.catch(error => {
            alert(error.body.message)
            this.spinner = false;
		})
}

}