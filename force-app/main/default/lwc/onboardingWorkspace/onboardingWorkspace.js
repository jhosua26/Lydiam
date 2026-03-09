import { LightningElement, api, track } from 'lwc';
import getWorkspaceData from '@salesforce/apex/OnboardingWorkspaceController.getWorkspaceData';
import executeStatusAction from '@salesforce/apex/OnboardingWorkspaceController.executeStatusAction';

const STATUS_ACTION = Object.freeze({
    START_REVIEW: 'START_REVIEW',
    APPROVE: 'APPROVE',
    REJECT: 'REJECT',
    RETURN_TO_IN_PROGRESS: 'RETURN_TO_IN_PROGRESS'
});

const PARTY_COLUMNS = [
    {
        label: 'Party',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'name' }, target: '_blank' }
    },
    { label: 'Role', fieldName: 'role' },
    { label: 'Role Description', fieldName: 'roleDescription' },
    { label: 'Ownership %', fieldName: 'ownershipPercentage', type: 'number' },
    { label: 'PEP', fieldName: 'pepDisplay' },
    { label: 'Email', fieldName: 'email' },
    { label: 'Phone', fieldName: 'phone' }
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

export default class OnboardingWorkspace extends LightningElement {
    @api recordId;

    @track workspace;
    @track isLoading = false;
    @track isSaving = false;
    @track errorMessage = '';

    partyColumns = PARTY_COLUMNS;
    declarationColumns = DECLARATION_COLUMNS;
    documentColumns = DOCUMENT_COLUMNS;

    connectedCallback() {
        this.loadWorkspace();
    }

    async loadWorkspace() {
        if (!this.recordId) {
            this.errorMessage = 'Record Id is missing.';
            return;
        }
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const data = await getWorkspaceData({ applicationId: this.recordId });
            this.workspace = this.normalizeWorkspace(data);
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

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
            pepDisplay: row.isPep ? 'Yes' : 'No'
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

    get hasWorkspace() {
        return !!this.workspace;
    }

    get hasBlockers() {
        return this.workspace && this.workspace.blockers && this.workspace.blockers.length > 0;
    }

    get showConvertSection() {
        return this.workspace && this.workspace.actions && this.workspace.actions.showConvert;
    }

    get isRefreshDisabled() {
        return this.isLoading || this.isSaving;
    }

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
        } catch (error) {
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.isSaving = false;
        }
    }

    handleRefresh() {
        this.loadWorkspace();
    }

    extractErrorMessage(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unexpected error occurred.';
    }
}

