import { LightningElement, track } from 'lwc';
import { createMessageContext, releaseMessageContext, subscribe } from 'lightning/messageService';

import getLocationData from '@salesforce/apex/locationCleaning.getLocationData';
 
//will be part of core when GA, remove __c
// import COMMAND_CENTER from "@salesforce/messageChannel/CommandCenterMessageChannel";

export default class LocationCleaning extends LightningElement {
    /// DEMO STATES - refactor or remove these ///
    noLocationView = true;
    locationView = false;
    subLocationView = false;

    @track locationId;
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

    context = createMessageContext();
    subscription = null;
    
    connectedCallback() {
        this.getData();

        if (this.subscription) {
            return;
        }

        //subscribe to command center messages
        // this.subscription = subscribe(this.context, COMMAND_CENTER, (message) => {
        //     this.handleMessage(message);
        // });
    }
    
    handleMessage(message) {
        if(message.EventSource == 'CommandCenter' && message.EventType == 'CC_LOCATION_CHANGE') {
            //handle location change from command center
            this.locationId = e.EventPayload.locationId;
            let locationName = e.EventPayload.locationName;

            this.getData();
       }
    }

    getData(locationId) {
        getLocationData({locationId : this.locationId})
        .then(res => {

        })
    }
    
    disconnectedCallback() {
        //unregister subscription
        releaseMessageContext(this.context);
    }
}