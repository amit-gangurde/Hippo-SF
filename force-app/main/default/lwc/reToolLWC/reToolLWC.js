/************************************************************************************************************************************
Author : Amit Gangurde
Description : This LWC component is for ReTool Application.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         			           22/09/2022    Amit Gangurde      Initial Development
**************************************************************************************************************************************/

import { LightningElement, wire,api ,track} from 'lwc';
import PodLeadApex from '@salesforce/apex/ReToolApex.PodLeadIds';
export default class App extends LightningElement {

    @api recordId;
    @track url;
    
    @wire( PodLeadApex,{RecId:'$recordId'})
    wiredPodDetails( value ) {
        const { data, error } = value;
        if ( data ) {
            let toolURL = JSON.parse( JSON.stringify( data ) );
            this.url = toolURL;          
        }
        else if ( error ) {
            console.log('Error : '+error);  
        }
    }
}