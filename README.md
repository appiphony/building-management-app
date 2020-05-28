# Building Maintenence App for Work.com

The goal of this app is to aid in tracking location cleaning. This app consists of 2 code bases: our base package (data model and app) and our extension package (components that work with Command Center)

## Config

Follow these steps to set up an org with our app

1) Create new org with work.com enabled and command center managed package installed
2) Install Base package (https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5w000004Lpu3)
3) Run script to generate Location/Employee/Individual/etc. Data (from WorkDotCom-Partners github)
4) Install extension package (https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5w000005G8Fm)
5) Run wdctestext.dataMigrationBatchHelper.transferData() to create data for our objs from existing work.com data
6) Clone Command Center page and drag Location Cleaning, Employee Risk by Location, and Clean Status by Floor Components onto the page and save