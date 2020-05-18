import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';

import getLocationData from '@salesforce/apex/locationCleaning.getLocationData';
import getListViews from '@salesforce/apex/locationCleaning.getListViews';
import getEmployeeCounts from '@salesforce/apex/locationCleaning.getEmployeeCounts';
 
//will be part of core when GA, replace back2work with lightning and remove __c
import COMMAND_CENTER from "@salesforce/messageChannel/back2work__CommandCenterMessageChannel__c";

export default class LocationCleaning extends NavigationMixin(LightningElement) {
    @wire(MessageContext)
    messageContext;

    subscription;

    listViews;

    @track locationId;
    @track locationName;

    @track locationDatas = [];

    @track locationData = {};
    @track sublocationData = {};

    @track loading;

    connectedCallback() {
        if (this.subscription) {
            return;
        }

        //subscribe to command center messages
        this.subscription = subscribe(this.messageContext, COMMAND_CENTER, message => {this.handleMessage(message)}, {scope: APPLICATION_SCOPE});

        this.getLocationData();
        this.getListViews();
    }
    
    handleMessage(message) {
        if(message.EventSource == 'CommandCenter' && message.EventType == 'CC_LOCATION_CHANGE') {
            this.template.querySelector('.slds-card__body.slds-scrollable_y').scrollTop = 0;

            //handle location change from command center
            this.locationId = message.EventPayload.locationId;
            this.locationName = message.EventPayload.locationName;

            this.getLocationData();
       }
    }

    showLocation(event) {
        this.template.querySelector('.slds-card__body.slds-scrollable_y').scrollTop = 0;
        let buildingId = event.currentTarget.dataset.id;

        this.locationData = this.locationDatas.find(building => {
            return building.Id == buildingId;
        })

        this.sublocationData = {};

        this.locationId = this.locationData.wdcLocation__c;
    }

    showSublocation(event) {
        this.template.querySelector('.slds-card__body.slds-scrollable_y').scrollTop = 0;
        let sublocationId = event.currentTarget.dataset.id;

        getEmployeeCounts({sublocationId: sublocationId})
        .then(res => {
            let employeeData = JSON.parse(res);

            let sublocationData = this.locationData.wdctest__Floors__r.records.find(flr => {
                return flr.Id == sublocationId;
            })

            this.sublocationData = Object.assign(sublocationData, employeeData);
        })
    }

    getLocationData() {
        getLocationData({locationId : this.locationId})
        .then(res => {
            this.locationDatas = JSON.parse(res);
            this.locationData = this.locationId ? this.locationDatas[0] : {};
            this.sublocationData = {};
        })
    }

    handleBreadcrumbClick(event) {
        this.template.querySelector('.slds-card__body.slds-scrollable_y').scrollTop = 0;
        
        this.sublocationData = {};

        if(event.currentTarget.dataset.value == 'All') {
            this.locationData = {};
            this.locationId = null;
        }
    }

    getListViews() {
        getListViews()
        .then(res => {
            this.listViews = JSON.parse(res);
        })
    }

    nav(event) {
        let value = event.detail.value ? event.detail.value : event.currentTarget.value;

        let navData;

        if(value.includes('|')) {
            //list view
            let data = value.split('|');

            navData = {
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: data[0],
                    actionName: 'list'
                },
                state: {
                    filterName: data[1]
                }
            }
        } else{
            //record page
            navData = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: value,
                    actionName: 'view'
                }
            }
        }

        this[NavigationMixin.GenerateUrl](navData).then(url => {
            window.open(url);
        });

    }

    disconnectedCallback() {
        //unsubscribe on unrender
        if (this.subscription) {
            unsubscribe(this.subscription);
        }
    }
}