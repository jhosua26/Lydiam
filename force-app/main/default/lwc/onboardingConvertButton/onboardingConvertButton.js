import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import checkEligibility from '@salesforce/apex/OnboardingConversionController.checkConversionEligibility';
import convertApplication from '@salesforce/apex/OnboardingConversionController.convertToAccountAndContacts';

const PHASE = Object.freeze({
    LOADING: 'loading',
    ELIGIBLE: 'eligible',
    INELIGIBLE: 'ineligible',
    CONVERTING: 'converting',
    SUCCESS: 'success',
    ERROR: 'error'
});

export default class OnboardingConvertButton extends NavigationMixin(LightningElement) {
    @api recordId;

    phase = PHASE.LOADING;
    eligibilityMessage = '';
    alreadyConvertedAccountId = null;
    conversionMessage = '';
    errorMessage = '';
    newAccountId = null;

    get isLoading() { return this.phase === PHASE.LOADING; }
    get showEligibilityError() { return this.phase === PHASE.INELIGIBLE; }
    get showConfirmation() { return this.phase === PHASE.ELIGIBLE; }
    get isConverting() { return this.phase === PHASE.CONVERTING; }
    get showSuccess() { return this.phase === PHASE.SUCCESS; }
    get showError() { return this.phase === PHASE.ERROR; }

    get convertedAccountUrl() {
        return this.alreadyConvertedAccountId
            ? `/lightning/r/Account/${this.alreadyConvertedAccountId}/view`
            : '#';
    }

    get newAccountUrl() {
        return this.newAccountId
            ? `/lightning/r/Account/${this.newAccountId}/view`
            : '#';
    }

    connectedCallback() {
        this.runEligibilityCheck();
    }

    async runEligibilityCheck() {
        this.phase = PHASE.LOADING;
        try {
            const result = await checkEligibility({ applicationId: this.recordId });
            if (result.eligible) {
                this.eligibilityMessage = result.reason;
                this.phase = PHASE.ELIGIBLE;
            } else {
                this.eligibilityMessage = result.reason;
                this.alreadyConvertedAccountId = result.alreadyConvertedAccountId || null;
                this.phase = PHASE.INELIGIBLE;
            }
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
            this.phase = PHASE.ERROR;
        }
    }

    async handleConvert() {
        this.phase = PHASE.CONVERTING;
        try {
            const result = await convertApplication({ applicationId: this.recordId });
            if (result.isSuccess) {
                this.newAccountId = result.accountId;
                this.conversionMessage = result.message;
                this.phase = PHASE.SUCCESS;
            } else {
                this.errorMessage = result.message || 'Unknown error during conversion.';
                this.phase = PHASE.ERROR;
            }
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
            this.phase = PHASE.ERROR;
        }
    }

    /**
     * @description Extracts a human-readable message from various error shapes.
     */
    extractErrorMessage(error) {
        if (typeof error === 'string') { return error; }
        if (error?.body?.message) { return error.body.message; }
        if (error?.message) { return error.message; }
        return 'An unexpected error occurred.';
    }
}