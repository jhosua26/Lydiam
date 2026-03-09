import { LightningElement, api } from 'lwc';
import sendFormLinkEmail from '@salesforce/apex/SendFormLinkController.sendFormLinkEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SendApplicationLink extends LightningElement {
    @api recordId;

    isSelectionStep = true;
    isConfirmationStep = false;
    selectedForms = [];

    formOptions = [
        { label: 'Alternative Assets', value: '/application/s/alternative-assets' },
        { label: 'Corporate FX', value: '/application/s/corporate-fx' },
        { label: 'Alternative Asset Corporate', value: '/application/s/alternative-asset-Corporate' },
        { label: 'Private FX', value: '/application/s/private-fx' },
        { label: 'Partnership Account', value: '/application/s/partnership-account' }
    ];

    get isNextDisabled() {
        return this.selectedForms.length === 0;
    }

    get selectedLabels() {
        return this.selectedForms.map(route => {
            const option = this.formOptions.find(opt => opt.value === route);
            return option ? option.label : route;
        });
    }

    handleCheckboxChange(event) {
        this.selectedForms = event.detail.value;
    }

    goToConfirmStep() {
        this.isSelectionStep = false;
        this.isConfirmationStep = true;
    }

    goToSelectStep() {
        this.isSelectionStep = true;
        this.isConfirmationStep = false;
    }

    async sendForm() {
        try {
            await sendFormLinkEmail({
                leadId: this.recordId,
                formRoutes: this.selectedForms,
                formLabels: this.selectedLabels
            });

            this.showToast('Success', 'Email sent successfully!', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to send email', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}