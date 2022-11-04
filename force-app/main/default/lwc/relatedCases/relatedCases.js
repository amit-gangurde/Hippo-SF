/************************************************************************************************************************************
Author : Amit Gangurde
Description : This LWC component is for the related cases on case record page based on the AccountID.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     ISSUE NUMBER         DATE           AUTHOR             DETAIL
1         			           14/09/2022    Amit Gangurde      Initial Development
**************************************************************************************************************************************/

import { LightningElement,wire,api,track } from 'lwc';
import fetchRelatedCases from '@salesforce/apex/AccRelatedCases.fetchCases';

// datatable columns with row actions. Set sortable = true
const columns = [
    { label: 'Case Number', fieldName: 'CaseNumber', sortable: "true"},
    { label: 'Case Status', fieldName: 'Status', sortable: "true"},
    { label: 'Record Type', fieldName: 'recordTypeName', sortable: "true"},
    { label: 'Created Date', fieldName: 'CreatedDate', sortable: "true"}
];

export default class RelatedCases extends LightningElement {

    @track data;
    @track error;
    @track columns = columns;
    @api recordId;

    @wire( fetchRelatedCases,{RecId:'$recordId'})
    wiredAccount( value ) {
        const { data, error } = value;
        if ( data ) {
            let tempRecords = JSON.parse( JSON.stringify( data ) );
            let newArray = [];
             tempRecords.forEach(record => {
                let newrecord = {};
                newrecord.CaseNumber = record.CaseNumber;
                newrecord.Status = record.Status;                
                newrecord.recordTypeName = record.RecordType.Name;
                newrecord.CreatedDate = record.CreatedDate;
                newArray.push(newrecord);
            });

            this.data = newArray;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.data = undefined;
        }
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    } 

}