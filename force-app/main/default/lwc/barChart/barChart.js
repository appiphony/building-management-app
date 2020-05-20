import { LightningElement, track, wire } from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import COMMAND_CENTER from "@salesforce/messageChannel/back2work__CommandCenterMessageChannel__c";

import getBarChartData from '@salesforce/apex/locationCleaning.getBarChartData';


export default class barChart extends LightningElement {
    @wire(MessageContext)
    messageContext;

    subscription;

    @track isChartJsInitialized;
    chart;

    @track locationName = 'All Locations'
    @track locationId

    config = {
        type: 'bar',
        data: {
            labels: [],
            datasets: [{
                label: 'At Risk Employees',
                data: [],
                backgroundColor: '#D4504C'
            },
            {
                label: 'Safe Employees',
                data: [],
                backgroundColor: '#215CA0'
            }]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    }
                }]
            },
            responsive: true,
            maintainAspectRatio: false
        }
    };

    connectedCallback() {
        if (this.subscription) {
            return;
        }

        //subscribe to command center messages
        this.subscription = subscribe(this.messageContext, COMMAND_CENTER, message => {this.handleMessage(message)}, {scope: APPLICATION_SCOPE});
    }

    handleMessage(message) {
        if(message.EventSource == 'CommandCenter' && message.EventType == 'CC_LOCATION_CHANGE') {
            this.locationId = message.EventPayload.locationId;
            this.locationName = message.EventPayload.locationName;

            this.getChartData();
       }
    }

    getChartData() {
        getBarChartData({locationId: this.locationId})
        .then(res => {
            let response = JSON.parse(res);
            if(this.chart) {
                this.chart.destroy();
            }

            const ctx = this.template.querySelector('canvas.barchart').getContext('2d');
            this.config.data.labels = response.labels;
            this.config.data.datasets[0].data = response.atRiskData;
            this.config.data.datasets[1].data = response.safeData;

            this.chart = new window.Chart(ctx, this.config);

            this.chart.canvas.parentNode.style.height = '350px';
            this.chart.canvas.parentNode.style.width = '350opx';
        })
        .catch(e => {
            debugger
        })
    }

    renderedCallback() {
        if (this.isChartJsInitialized) {
            return;
        }
        this.isChartJsInitialized = true;

        Promise.all([
            loadScript(this, chartjs)
        ]).then(() => {
            this.getChartData();
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading ChartJS',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
    }
}