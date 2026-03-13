import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWorkspaceData from '@salesforce/apex/OnboardingWorkspaceController.getWorkspaceData';
import getWorkspaceDataForRefresh from '@salesforce/apex/OnboardingWorkspaceController.getWorkspaceDataForRefresh';
import executeStatusAction from '@salesforce/apex/OnboardingWorkspaceController.executeStatusAction';
import updateStatusFromPath from '@salesforce/apex/OnboardingWorkspaceController.updateStatusFromPath';
import registerPartyDocumentUploads from '@salesforce/apex/OnboardingWorkspaceController.registerPartyDocumentUploads';

const PARTY_COLUMNS = [
    {
        label: 'Party',
        fieldName: 'name',
        type: 'text'
    },
    { label: 'Role', fieldName: 'role' },
    { label: 'Role Description', fieldName: 'roleDescription' },
    { label: 'Ownership %', fieldName: 'ownershipPercentage', type: 'number' },
    { label: 'PEP', fieldName: 'pepDisplay' },
    { label: 'Email', fieldName: 'email' },
    { label: 'Phone', fieldName: 'phone' },
    {
        label: 'Upload Docs',
        type: 'button',
        initialWidth: 130,
        typeAttributes: {
            label: 'Upload',
            name: 'upload_party_docs',
            variant: 'brand-outline'
        }
    },
    {
        label: 'Edit Party',
        type: 'button-icon',
        initialWidth: 110,
        typeAttributes: {
            iconName: 'utility:edit',
            name: 'edit_party',
            title: 'Edit Party',
            alternativeText: 'Edit Party',
            variant: 'border-filled'
        }
    },
    {
        label: 'Edit Address',
        type: 'button-icon',
        initialWidth: 120,
        typeAttributes: {
            iconName: 'utility:edit',
            name: 'edit_address',
            title: 'Edit Address',
            alternativeText: 'Edit Address',
            variant: 'border-filled',
            disabled: { fieldName: 'disableAddressActions' }
        }
    }
];

const DECLARATION_COLUMNS = [
    {
        label: 'Declaration',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'declarationType' }, target: '_blank' }
    },
    { label: 'Accepted', fieldName: 'acceptedDisplay' },
    { label: 'Signature Name', fieldName: 'signatureName' },
    { label: 'Accepted On', fieldName: 'acceptedOn', type: 'date' }
];

const DOCUMENT_COLUMNS = [
    {
        label: 'Document Record',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
    },
    { label: 'Document Type', fieldName: 'documentType' },
    { label: 'Required', fieldName: 'requiredDisplay' },
    { label: 'Received', fieldName: 'receivedDisplay' },
    {
        label: 'File',
        fieldName: 'fileUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'fileLabel' }, target: '_blank' }
    }
];

const STATUS_PATH_STEPS = Object.freeze([
    { label: 'Draft', value: 'Draft' },
    { label: 'In Progress', value: 'In_Progress' },
    { label: 'Submitted', value: 'Submitted' },
    { label: 'Under Review', value: 'Under_Review' },
    { label: 'Approved', value: 'Approved' },
    { label: 'Rejected', value: 'Rejected' },
    { label: 'Converted', value: 'Converted' }
]);
const PARTY_TYPE_INDIVIDUAL = 'individual';
const PARTY_TYPE_CORPORATE = 'corporate';

export default class OnboardingWorkspace extends LightningElement {
    @api recordId;

    @track workspace;
    @track isLoading = false;
    @track isSaving = false;
    @track errorMessage = '';
    @track isRecordModalOpen = false;
    @track modalRecordId;
    @track modalObjectApiName;
    @track modalMode = 'view';
    @track modalTitle = '';
    @track modalPartyType = '';
    @track modalPartyRole = '';
    @track isPartyUploadModalOpen = false;
    @track selectedPartyId;
    @track selectedPartyName = '';
    @track uploadDocumentType = 'Party_Document';
    @track isPathUpdating = false;
    @track isStatusPathVisible = true;
    @track statusPathCurrentStepValue = 'Draft';
    @track selectedStatusPathStep = 'Draft';

    partyColumns = PARTY_COLUMNS;
    declarationColumns = DECLARATION_COLUMNS;
    documentColumns = DOCUMENT_COLUMNS;
    statusPathSteps = STATUS_PATH_STEPS;
    uploadDocumentTypeOptions = [
        { label: 'Party Document', value: 'Party_Document' },
        { label: 'Passport', value: 'Passport' },
        { label: 'Proof of Address', value: 'Proof_of_Address' },
        { label: 'Source of Wealth Evidence', value: 'Source_of_Wealth_Evidence' }
    ];

    /**
     * Initializes the workspace payload for the current onboarding application.
     */
    connectedCallback() {
        this.loadWorkspace();
    }

    /**
     * Loads the workspace aggregate data from Apex.
     * @param {boolean} forceRefresh
     * @returns {Promise<void>}
     */
    async loadWorkspace(forceRefresh = false) {
        if (!this.recordId) {
            this.errorMessage = 'Record Id is missing.';
            return;
        }
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const data = forceRefresh
                ? await getWorkspaceDataForRefresh({ applicationId: this.recordId })
                : await getWorkspaceData({ applicationId: this.recordId });
            this.workspace = this.normalizeWorkspace(data);
            this.syncStatusPathWithWorkspace(forceRefresh);
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Normalizes and safely clones workspace response for template rendering.
     * @param {object} data
     * @returns {object}
     */
    normalizeWorkspace(data) {
        let workspace = {};
        try {
            // Clone Apex response to avoid mutating Lightning proxy objects.
            workspace = JSON.parse(JSON.stringify(data || {}));
        } catch (e) {
            workspace = data ? { ...data } : {};
        }
        workspace.parties = (workspace.parties || []).map((row) => ({
            ...row,
            pepDisplay: row.isPep ? 'Yes' : 'No',
            disableAddressActions: !row.addressRecordUrl
        }));
        workspace.declarations = (workspace.declarations || []).map((row) => ({
            ...row,
            acceptedDisplay: row.accepted ? 'Yes' : 'No'
        }));
        workspace.documents = (workspace.documents || []).map((row) => ({
            ...row,
            requiredDisplay: row.isRequired ? 'Yes' : 'No',
            receivedDisplay: row.isReceived ? 'Yes' : 'No',
            fileLabel: row.fileLabel || ''
        }));
        workspace.blockers = workspace.blockers || [];
        workspace.actions = workspace.actions || {};
        return workspace;
    }

    /**
     * Indicates whether workspace data has loaded successfully.
     * @returns {boolean}
     */
    get hasWorkspace() {
        return !!this.workspace;
    }

    /**
     * Indicates whether the workspace has review blockers.
     * @returns {boolean}
     */
    get hasBlockers() {
        return this.workspace && this.workspace.blockers && this.workspace.blockers.length > 0;
    }

    /**
     * Indicates whether conversion section should be displayed.
     * @returns {boolean}
     */
    get showConvertSection() {
        return this.workspace && this.workspace.actions && this.workspace.actions.showConvert;
    }

    /**
     * Indicates whether applicant link is available.
     * @returns {boolean}
     */
    get hasApplicant() {
        return !!(this.workspace && this.workspace.applicant && this.workspace.applicant.recordId);
    }

    /**
     * Indicates whether business profile link is available.
     * @returns {boolean}
     */
    get hasBusinessProfile() {
        return !!(this.workspace && this.workspace.businessProfile && this.workspace.businessProfile.recordId);
    }

    /**
     * Indicates whether converted account link is available.
     * @returns {boolean}
     */
    get hasConvertedAccount() {
        return !!(this.workspace && this.workspace.convertedAccountId);
    }

    /**
     * Displays context-aware label for business profile section.
     * @returns {string}
     */
    get businessProfileLabel() {
        const clientType = (this.workspace?.clientType || '').toLowerCase();
        return clientType.includes('private') ? 'Business Profile (FX Context)' : 'Business Profile';
    }

    /**
     * Normalized client type value for conditional rendering.
     * @returns {string}
     */
    get normalizedClientType() {
        return (this.workspace?.clientType || '').toLowerCase();
    }

    /**
     * Indicates whether current application is corporate.
     * @returns {boolean}
     */
    get isCorporateClient() {
        return this.normalizedClientType.includes('corporate');
    }

    /**
     * Indicates whether current application is private individual.
     * @returns {boolean}
     */
    get isPrivateClient() {
        return this.normalizedClientType.includes('private');
    }

    /**
     * Shows declaration acceptance progress in "X / Y" format.
     * @returns {string}
     */
    get declarationProgress() {
        const accepted = this.workspace?.declarationAcceptedCount ?? 0;
        const total = this.workspace?.declarationTotalCount ?? 0;
        return `${accepted} / ${total}`;
    }

    /**
     * Provides human-friendly Yes/No display for EDD flag.
     * @returns {string}
     */
    get eddDisplay() {
        return this.workspace?.eddRequired ? 'Yes' : 'No';
    }

    /**
     * Provides human-friendly Yes/No display for PEP flag.
     * @returns {string}
     */
    get pepDisplay() {
        return this.workspace?.pepFlag ? 'Yes' : 'No';
    }

    /**
     * Provides human-friendly Yes/No display for sanctions flag.
     * @returns {string}
     */
    get sanctionsDisplay() {
        return this.workspace?.sanctionsFlag ? 'Yes' : 'No';
    }

    /**
     * Indicates whether party rows are available.
     * @returns {boolean}
     */
    get hasParties() {
        return (this.workspace?.parties || []).length > 0;
    }

    /**
     * Indicates whether declaration rows are available.
     * @returns {boolean}
     */
    get hasDeclarations() {
        return (this.workspace?.declarations || []).length > 0;
    }

    /**
     * Indicates whether document rows are available.
     * @returns {boolean}
     */
    get hasDocuments() {
        return (this.workspace?.documents || []).length > 0;
    }

    /**
     * Indicates whether business profile details are available.
     * @returns {boolean}
     */
    get hasBusinessProfileDetails() {
        return !!this.workspace?.businessProfileDetails;
    }

    /**
     * Indicates whether private FX-context business profile fields are available.
     * @returns {boolean}
     */
    get hasPrivateFxBusinessProfileDetails() {
        const details = this.workspace?.businessProfileDetails;
        if (!this.isPrivateClient || !details) {
            return false;
        }
        return this.isValuePresent(details.currenciesToSend) ||
            this.isValuePresent(details.currenciesToReceive) ||
            this.isValuePresent(details.countriesSentTo) ||
            this.isValuePresent(details.countriesReceivedFrom);
    }

    /**
     * Indicates whether corporate business profile fields are available.
     * @returns {boolean}
     */
    get hasCorporateBusinessProfileDetails() {
        const details = this.workspace?.businessProfileDetails;
        if (!this.isCorporateClient || !details) {
            return false;
        }
        return this.isValuePresent(details.purposeOfAccount) ||
            this.isValuePresent(details.industry) ||
            this.isValuePresent(details.productsAndServices) ||
            this.isValuePresent(details.paymentFlowTypes) ||
            this.isValuePresent(details.currenciesToSend) ||
            this.isValuePresent(details.currenciesToReceive) ||
            this.isValuePresent(details.expectedTransactionsPerMonth) ||
            this.isValuePresent(details.expectedAnnualVolume) ||
            this.isValuePresent(details.typicalValuePerTransaction) ||
            this.isValuePresent(details.largestSingleTransaction) ||
            this.isValuePresent(details.primarySourceOfFunds) ||
            this.isValuePresent(details.sourceOfWealthExplanation) ||
            this.isValuePresent(details.regulatorName) ||
            this.isValuePresent(details.regulatoryLicenceNumber) ||
            this.isValuePresent(details.regulatoryJurisdiction) ||
            details.isRegulated === true ||
            details.isRegulated === false;
    }

    /**
     * Indicates whether applicant address details are available.
     * @returns {boolean}
     */
    get hasApplicantAddress() {
        return !!this.workspace?.applicantAddress?.recordId;
    }

    /**
     * Indicates whether private risk details should be shown.
     * @returns {boolean}
     */
    get hasPrivateRiskDetails() {
        const details = this.workspace?.privateRiskDetails;
        if (!this.isPrivateClient || !details) {
            return false;
        }
        return this.isValuePresent(details.expectedMonthlyVolume) ||
            this.isValuePresent(details.estimatedTransactionsPerMonth) ||
            this.isValuePresent(details.sourceOfWealth) ||
            this.isValuePresent(details.sourceOfWealthExplanation) ||
            this.isValuePresent(details.geographicExposure) ||
            this.isValuePresent(details.intendedUseOfAccount);
    }

    /**
     * Formats address line for compact display.
     * @returns {string}
     */
    get applicantAddressLine() {
        const address = this.workspace?.applicantAddress;
        if (!address) {
            return '-';
        }
        const parts = [address.street, address.city, address.state, address.postalCode, address.country].filter(
            (part) => !!part
        );
        return parts.join(', ') || '-';
    }

    /**
     * Human-friendly regulated flag display.
     * @returns {string}
     */
    get businessProfileIsRegulatedDisplay() {
        return this.workspace?.businessProfileDetails?.isRegulated ? 'Yes' : 'No';
    }

    /**
     * Indicates whether party edit modal is currently open.
     * @returns {boolean}
     */
    get isPartyEditModal() {
        return this.isRecordModalOpen &&
            this.modalObjectApiName === 'Party__c' &&
            this.modalMode === 'edit';
    }

    /**
     * Shows private party-specific editable fields in Party edit modal.
     * @returns {boolean}
     */
    get showPrivatePartyFieldSet() {
        return this.isPartyEditModal &&
            (this.normalizedModalPartyType === PARTY_TYPE_INDIVIDUAL || this.isPrivateApplicantPartyModal);
    }

    /**
     * Shows corporate party-specific editable fields in Party edit modal.
     * @returns {boolean}
     */
    get showCorporatePartyFieldSet() {
        return this.isPartyEditModal &&
            (this.normalizedModalPartyType === PARTY_TYPE_CORPORATE || this.isCorporateApplicantPartyModal);
    }

    /**
     * Fallback field set for Party edit when client type is unknown.
     * @returns {boolean}
     */
    get showFallbackPartyFieldSet() {
        return this.isPartyEditModal &&
            this.normalizedModalPartyType !== PARTY_TYPE_INDIVIDUAL &&
            this.normalizedModalPartyType !== PARTY_TYPE_CORPORATE &&
            !this.isPrivateApplicantPartyModal &&
            !this.isCorporateApplicantPartyModal;
    }

    /**
     * Normalized selected party type for fieldset routing.
     * @returns {string}
     */
    get normalizedModalPartyType() {
        return String(this.modalPartyType || '').trim().toLowerCase();
    }

    /**
     * Indicates whether selected party row is Applicant role.
     * @returns {boolean}
     */
    get isApplicantPartyModal() {
        return String(this.modalPartyRole || '').trim().toLowerCase() === 'applicant';
    }

    /**
     * Indicates whether selected party row is Applicant in a corporate application.
     * @returns {boolean}
     */
    get isCorporateApplicantPartyModal() {
        return this.isApplicantPartyModal && this.isCorporateClient;
    }

    /**
     * Indicates whether selected party row is Applicant in a private application.
     * @returns {boolean}
     */
    get isPrivateApplicantPartyModal() {
        return this.isApplicantPartyModal && this.isPrivateClient;
    }

    /**
     * Indicates whether refresh should be disabled.
     * @returns {boolean}
     */
    get isRefreshDisabled() {
        return this.isLoading || this.isSaving || this.isPathUpdating;
    }

    /**
     * Returns status badge classes based on current status.
     * @returns {string}
     */
    get statusBadgeClass() {
        const status = (this.workspace && this.workspace.status) || '';
        if (status === 'Approved') {
            return 'slds-badge slds-theme_success';
        }
        if (status === 'Rejected') {
            return 'slds-badge slds-theme_error';
        }
        if (status === 'Under_Review') {
            return 'slds-badge slds-theme_warning';
        }
        return 'slds-badge';
    }

    /**
     * Returns the normalized current status value for path rendering.
     * @returns {string}
     */
    get statusPathCurrentStep() {
        return this.statusPathCurrentStepValue;
    }

    /**
     * Resolves and applies the current status-path step from workspace status.
     * When forceRerender is true, remounts the path to clear user-clicked visual state.
     * @param {boolean} forceRerender
     */
    syncStatusPathWithWorkspace(forceRerender = false) {
        const currentStatus = this.workspace?.status;
        const hasMatch = STATUS_PATH_STEPS.some((step) => step.value === currentStatus);
        const resolvedStep = hasMatch ? currentStatus : 'Draft';

        if (forceRerender || resolvedStep === this.statusPathCurrentStepValue) {
            this.isStatusPathVisible = false;
            this.statusPathCurrentStepValue = resolvedStep;
            this.selectedStatusPathStep = resolvedStep;
            Promise.resolve().then(() => {
                this.isStatusPathVisible = true;
            });
            return;
        }

        this.statusPathCurrentStepValue = resolvedStep;
        this.selectedStatusPathStep = resolvedStep;
    }

    /**
     * Captures selected path step from click interaction.
     * @param {Event} event
     */
    handleStatusPathStepSelect(event) {
        const selectedStep = event?.target?.value || event?.currentTarget?.dataset?.value;
        const hasMatch = STATUS_PATH_STEPS.some((step) => step.value === selectedStep);
        if (hasMatch) {
            this.selectedStatusPathStep = selectedStep;
        }
    }

    /**
     * Captures selected path step from focus interaction for keyboard/mobile support.
     * @param {CustomEvent} event
     */
    handleStatusPathStepFocus(event) {
        const selectedFromDetail = event?.detail?.value;
        if (selectedFromDetail && STATUS_PATH_STEPS.some((step) => step.value === selectedFromDetail)) {
            this.selectedStatusPathStep = selectedFromDetail;
            return;
        }

        const selectedIndex = event?.detail?.index;
        if (typeof selectedIndex === 'number' && STATUS_PATH_STEPS[selectedIndex]) {
            this.selectedStatusPathStep = STATUS_PATH_STEPS[selectedIndex].value;
        }
    }

    /**
     * Executes status transition action and refreshes workspace.
     * @param {Event} event
     * @returns {Promise<void>}
     */
    async handleStatusAction(event) {
        const actionName = event.target.dataset.action;
        if (!actionName || !this.recordId) {
            return;
        }
        this.isSaving = true;
        this.errorMessage = '';
        try {
            const updated = await executeStatusAction({
                applicationId: this.recordId,
                actionName
            });
            this.workspace = this.normalizeWorkspace(updated);
            this.syncStatusPathWithWorkspace(true);
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * Handles row-level actions in Related Parties grid.
     * @param {CustomEvent} event
     */
    handlePartyRowAction(event) {
        event.preventDefault?.();
        event.stopPropagation?.();
        const actionName = event.detail?.action?.name;
        const row = event.detail?.row || {};
        if (!actionName) {
            return;
        }
        if (actionName === 'edit_party') {
            this.openRecordModal({
                recordId: row.partyId,
                objectApiName: 'Party__c',
                mode: 'edit',
                title: 'Edit Party',
                partyType: row.partyType,
                partyRole: row.role
            });
            return;
        }
        if (actionName === 'edit_address') {
            this.openRecordModal({
                recordId: row.addressRecordId,
                objectApiName: 'Party_Address__c',
                mode: 'edit',
                title: 'Edit Address'
            });
            return;
        }
        if (actionName === 'upload_party_docs') {
            this.openPartyUploadModal(row);
        }
    }

    /**
     * Opens party-specific document upload modal.
     * @param {object} partyRow
     */
    openPartyUploadModal(partyRow) {
        if (!partyRow?.partyId) {
            return;
        }
        this.selectedPartyId = partyRow.partyId;
        this.selectedPartyName = partyRow.name || 'Party';
        this.uploadDocumentType = 'Party_Document';
        this.isPartyUploadModalOpen = true;
    }

    /**
     * Closes upload modal and clears state.
     */
    handleClosePartyUploadModal() {
        this.isPartyUploadModalOpen = false;
        this.selectedPartyId = null;
        this.selectedPartyName = '';
        this.uploadDocumentType = 'Party_Document';
    }

    /**
     * Handles document type selection for party uploads.
     * @param {CustomEvent} event
     */
    handleUploadDocumentTypeChange(event) {
        this.uploadDocumentType = event.detail?.value || 'Party_Document';
    }

    /**
     * Links uploaded files to Document Submission rows for selected party.
     * @param {CustomEvent} event
     */
    async handlePartyUploadFinished(event) {
        const uploadedFiles = event.detail?.files || [];
        const contentDocumentIds = uploadedFiles
            .map((file) => file.documentId)
            .filter((id) => !!id);
        if (!this.recordId || !this.selectedPartyId || contentDocumentIds.length === 0) {
            return;
        }
        this.isSaving = true;
        this.errorMessage = '';
        try {
            await registerPartyDocumentUploads({
                applicationId: this.recordId,
                partyId: this.selectedPartyId,
                documentType: this.uploadDocumentType,
                contentDocumentIds
            });
            this.showToast(
                'Upload successful',
                `${uploadedFiles.length} file(s) uploaded for ${this.selectedPartyName}.`,
                'success'
            );
            this.handleClosePartyUploadModal();
            await this.loadWorkspace(true);
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
            this.showToast('Upload failed', this.errorMessage, 'error');
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * Opens modal with record details in view/edit mode.
     * @param {object} options
     */
    openRecordModal(options) {
        const { recordId, objectApiName, mode, title, partyType, partyRole } = options || {};
        if (!recordId || !objectApiName) {
            return;
        }
        this.modalRecordId = recordId;
        this.modalObjectApiName = objectApiName;
        this.modalMode = mode || 'view';
        this.modalTitle = title || 'Record Details';
        this.modalPartyType = partyType || '';
        this.modalPartyRole = partyRole || '';
        this.isRecordModalOpen = true;
    }

    /**
     * Closes the active record modal.
     */
    handleCloseRecordModal() {
        this.isRecordModalOpen = false;
        this.modalRecordId = null;
        this.modalObjectApiName = null;
        this.modalMode = 'view';
        this.modalTitle = '';
        this.modalPartyType = '';
        this.modalPartyRole = '';
    }

    /**
     * Refreshes workspace after successful record edit.
     */
    handleRecordSaveSuccess() {
        this.handleCloseRecordModal();
        this.loadWorkspace(true);
    }

    /**
     * Handles modal form errors.
     * @param {CustomEvent} event
     */
    handleRecordFormError(event) {
        this.errorMessage = this.extractErrorMessage(event?.detail);
    }

    /**
     * Performs a manual refresh of workspace data.
     */
    handleRefresh() {
        this.loadWorkspace(true);
    }

    /**
     * Refreshes workspace data and confirms current status-path synchronization.
     * @returns {Promise<void>}
     */
    async handleUpdateStatusPath() {
        const currentStatus = this.workspace?.status || '';
        const targetStatus = this.selectedStatusPathStep || currentStatus;
        if (!targetStatus) {
            this.showToast('Status update', 'Select a valid status from the path first.', 'warning');
            return;
        }
        this.isPathUpdating = true;
        this.errorMessage = '';
        try {
            const updated = await updateStatusFromPath({
                applicationId: this.recordId,
                targetStatus
            });
            this.workspace = this.normalizeWorkspace(updated);
            this.syncStatusPathWithWorkspace(true);
            this.showToast('Status updated', `Application status updated to ${this.workspace?.status || targetStatus}.`, 'success');
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
            this.showToast('Status update failed', this.errorMessage, 'error');
            this.syncStatusPathWithWorkspace(true);
        } finally {
            this.isPathUpdating = false;
        }
    }

    /**
     * Extracts human-readable error message from framework and Apex errors.
     * @param {*} error
     * @returns {string}
     */
    extractErrorMessage(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unexpected error occurred.';
    }

    /**
     * Returns true when a field has a meaningful value.
     * @param {*} value
     * @returns {boolean}
     */
    isValuePresent(value) {
        if (value === null || value === undefined) {
            return false;
        }
        return String(value).trim().length > 0;
    }

    /**
     * Displays a toast to provide user feedback.
     * @param {string} title
     * @param {string} message
     * @param {'success'|'error'|'warning'|'info'} variant
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}