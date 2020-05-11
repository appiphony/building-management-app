public with sharing class dataMigrationBatchHelper {

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAPPING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    wdctest__Building__c                     |  Location
        Name                                 |      Name
        wdctest__Location__c                 |      Location
            wdctest__Location__Latitude__c   |          Location__Latitude__c
            wdctest__Location__Longitude__c  |          Location__Longitude__c
                                             |
    wdctest__Floor__c                        |  Location
        Name                                 |      Name
        wdctest__Level__c                    |      LocationLevel
        wdctest__Cleaning_Frequency_Days__c  |      Cleaning_Frequency_Days__c *
        wdctest__Building__c                 |      ParentLocationId
                                             |
    wdctest__Employee__c                     |  back2work__Employee__c
        wdctest__First_Name__c               |      back2work__FirstName__c
        wdctest__Last_Name__c                |      back2work__LastName__c
        wdctest__Status__c                   |      back2work__WellnessStatus__c
        wdctest__Floor__c                    |      back2work__Location__c
    
    wdctest__Cleaning__c **                  |  N/A

    * For field on Floor that doesnt correspond to any field on Location (wdctest__Cleaning_Frequency_Days__c),
    instruct customers to create custom fields with the same api name (Cleaning_Frequency_Days__c) and we
    will attempt to populate it (if the field exists)

    ** wdctest__Cleaning__c does not need to be duplicated to work.com object.
    Instead, just need to add lookup to Floor(Location) in ext package

    */

    public static void processRecords(List<wdctest__Floor__c> sublocations) {
        try{
            /*
            TODO: 
                • ext id on location
                • status mapping(wdctest => back2work)
            */

            wdctest__Floor__c sublocation = sublocations.get(0);

            //create parent location (wdctest__Building__c)
            sObject newParentLocation = (sObject)Type.forName('Location').newInstance();
            newParentLocation.put('Name', sublocation.wdctest__Building__r.Name);
            newParentLocation.put('Location__Latitude__c', sublocation.wdctest__Building__r.wdctest__Location__Latitude__c);
            newParentLocation.put('Location__Longitude__c', sublocation.wdctest__Building__r.wdctest__Location__Longitude__c);
            insert newParentLocation;

            //create sublocation (wdctest__Floor__c)
            sObject newSublocation = (sObject)Type.forName('Location').newInstance();
            newParentLocation.put('Name', sublocation.Name);
            newParentLocation.put('LocationLevel', sublocation.wdctest__Level__c);
            newParentLocation.put('ParentLocationId', newParentLocation.Id);
            insert newSublocation;

            //create employees (wdctest__Employee__c)
            List<sObject> newEmployees = new List<sObject>();
            for(wdctest__Employee__c employee : sublocation.wdctest__Employees__r) {
                sObject newEmployee = (sObject)Type.forName('back2work__Employee__c').newInstance();
                newEmployee.put('back2work__FirstName__c');
                newEmployee.put('back2work__LastName__c');
                newEmployee.put('back2work__WellnessStatus__c');
                newEmployee.put('back2work__Location__c', newSublocation.ParentLocationId);
            }
            insert newEmployees;

            //update existing cleanings to point to new sublocation
            for(wdctest__Cleaning__c cleaning : sublocation.wdctest__Cleanings__r) {
                cleaning.wdcext__Location__c = newSublocation.Id;
            }
            update sublocation.wdctest__Cleanings__r;

        } catch(Exception e) {

        }
    }
}
