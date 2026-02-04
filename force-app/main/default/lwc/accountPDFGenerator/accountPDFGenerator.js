import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatePDF from '@salesforce/apex/AccountPDFGenerator.generateFromLWC';

export default class AccountPdfGenerator extends LightningElement {

    @api recordId;
    @track isOpen = false;
    selected = [];

    fields = [
        {label:'Account Name', api:'Name'},
        {label:'Account Number', api:'AccountNumber'},
        {label:'Site', api:'Site'},
        {label:'Account Summary', api:'Account_Summary__c'},
        {label:'Active', api:'Active__c'},
        {label:'Annual Revenue', api:'AnnualRevenue'},
        {label:'Customer Priority', api:'CustomerPriority__c'},
        {label:'Industry', api:'Industry'},
        {label:'Rating', api:'Rating'},
        {label:'Website', api:'Website'}
    ];

    openModal(){
        this.isOpen = true;
    }

    closeModal(){
        this.isOpen = false;
    }

    handleCheck(event){
        if(event.target.checked)
            this.selected.push(event.target.value);
        else
            this.selected = this.selected.filter(f => f !== event.target.value);
    }

    handleDone(){
        generatePDF({
            recordId: this.recordId,
            selectedFields: this.selected.join(',')
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'PDF has been created and attached to this record. Check Notes & Attachments section.',
                    variant: 'success'
                })
            );
            this.isOpen = false;
        });
    }
}
