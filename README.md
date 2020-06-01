# Building Maintenence App for Work.com

The goal of this app is to aid in tracking location cleanliness. This app consists of 2 code bases: our base package (data model and app) and our extension package (components that work with Command Center and triggers to keep data in sync)

## Config

Follow these steps to set up an org with our app

There are ways that you can configure an org with our app. The first is by installing the base unmanaged package and then the extension unmanaged package. The second is by pushing the base-master branch from this repo into an org, followed by pushing the extension-master branch. In both cases, you will need to have an org with work.com enabled and the Command Center managed package installed. Follow the steps below to get up and running.

### Using Unmanaged Packages
1) Create new org with work.com enabled and Command Center managed package installed. Refer to this doc for instructions: https://salesforce.quip.com/UiuYAvbyZAKQ
2) Install our unmanaged Building Maintenance Base package (https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5w000005qoKM)
3) Run script to generate work.com data from WorkDotCom-Partners github (https://github.com/forcedotcom/WorkDotCom-Partners)
4) Install our unmanaged Building Maintenance Extension package (https://login.salesforce.com/packaging/installPackage.apexp?p0=04t4S000000gquw)
5) Checkout extension-master brnach and run sfdx force:apex:execute -f ./dx-utils/apex-scripts/convertData.apex to create data for our objs from existing work.com data
6) Clone Command Center page and drag Location Cleaning, Employee Risk by Location, and Clean Status by Floor Components onto the page and save
7) (Optional) Drag Reset Cleaning Data componenent onto page to reset cleaning records for floors

### Using Scratch Org
1) Create new org with work.com enabled and Command Center managed package installed. Refer to this doc for instructions: https://salesforce.quip.com/UiuYAvbyZAKQ
2) Checkout base-master branch and push to your scratch org
3) Run script to generate work.com data from WorkDotCom-Partners github (https://github.com/forcedotcom/WorkDotCom-Partners)
4) Checkout extension-master and push to your scratch org
5) Run sfdx force:apex:execute -f ./dx-utils/apex-scripts/convertData.apex to create data for our objs from existing work.com data
6) Clone Command Center page and drag Location Cleaning, Employee Risk by Location, and Clean Status by Floor Components onto the page and save
7) (Optional) Drag Reset Cleaning Data componenent onto page to reset cleaning records for floors