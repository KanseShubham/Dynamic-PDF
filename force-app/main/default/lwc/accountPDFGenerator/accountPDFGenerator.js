import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatePDF from '@salesforce/apex/AccountPDFGenerator.generateFromLWC';
import sendPDF from '@salesforce/apex/AccountPDFGenerator.sendLatestPDFToCustomer';

import { getRecord } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';

export default class AccountPdfGenerator extends LightningElement {

    @api recordId;
    @track isOpen = false;
    selected = [];

    // 🔹 Get Account Name for dynamic toast
    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
    account;

    get accountName(){
        return this.account?.data?.fields?.Name?.value;
    }

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
        if(event.target.checked){
            this.selected.push(event.target.value);
        } else {
            this.selected = this.selected.filter(f => f !== event.target.value);
        }
    }

    // ✅ Send Email
    sendEmail(){
        sendPDF({ recordId: this.recordId })
        .then(() => {
            this.showToast(
                'Success',
                'Email has been sent to ' + this.accountName,
                'success'
            );
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    // ✅ Generate PDF
    handleDone(){

        if(this.selected.length === 0){
            this.showToast('Error', 'Please select at least one field.', 'error');
            return;
        }

        generatePDF({
            recordId: this.recordId,
            selectedFields: this.selected.join(',')
        })
        .then(() => {
            this.showToast(
                'Success',
                'PDF has been created and attached to this record.',
                'success'
            );
            this.isOpen = false;
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    // 🔹 Reusable Toast
    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
