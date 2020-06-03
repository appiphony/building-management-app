import { LightningElement, track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import resetCleaningData from '@salesforce/apex/locationCleaning.resetCleaningData';

export default class ResetCleaningData extends LightningElement {
    @track loading = false;

    resetCleaningData() {
        this.loading = true;
        resetCleaningData()
        .then(res => {
            const evt = new ShowToastEvent({
                title: 'Success!',
                message: 'Cleaning data reset.',
                variant: 'success',
            });
            this.dispatchEvent(evt);

            this.loading = false
        })
    }
}