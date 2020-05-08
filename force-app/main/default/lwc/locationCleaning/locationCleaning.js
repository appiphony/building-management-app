import { LightningElement } from 'lwc';

export default class LocationCleaning extends LightningElement {
    /// DEMO STATES - refactor or remove these ///
    noLocationView = true;
    locationView = false;
    subLocationView = false;
    /// END DEMO STATES ///

    handleLocationRowClick() {
        this.noLocationView = false
        this.locationView = true;
    }

    handleSubLocationClick() {
        this.subLocationView = true;
        this.locationView = false;
    }

    handleBackClick() {
        this.locationView = true;
        this.subLocationView = false;
    }
}