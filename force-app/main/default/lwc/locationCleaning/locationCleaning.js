import { LightningElement } from 'lwc';

export default class LocationCleaning extends LightningElement {
    /// DEMO STATES - refactor or remove these ///
    noLocationView = true;
    locationView = false;
    subLocationView = false;
    /// END DEMO STATES ///

    handleShowAllLocations() {
        this.noLocationView = true;
        this.locationView = false;
        this.subLocationView = false;
    }

    handleShowLocation() {
        this.noLocationView = false;
        this.locationView = true;
        this.subLocationView = false;
    }

    handleShowSubLocation() {
        this.noLocationView = false;
        this.locationView = false;
        this.subLocationView = true;
    }
}