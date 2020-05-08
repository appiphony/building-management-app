import { LightningElement } from 'lwc';

export default class LocationCleaning extends LightningElement {
    /// DEMO STATES - refactor or remove these ///
    noLocationView = false;
    locationView = true;
    subLocationView = false;
    /// END DEMO STATES ///

    handleSubLocationClick() {
        this.subLocationView = true;
        this.locationView = false;
    }

    handleBackClick() {
        this.locationView = true;
        this.subLocationView = false;
    }
}