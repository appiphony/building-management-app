public with sharing class dataMigrationBatchHelper {

    /*
    Namespaces:
        • wdctest -> Building App (Appiphony) Base Package
        • wdcext -> Building App (Appiphony) Extension Package
        • back2work -> Work.com Package

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAPPING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    wdctest__Building__c                     |  Location
        Id                                   |      wdcext__Building__c *
        Name                                 |      Name
        wdctest__Location__c                 |      Location
            wdctest__Location__Latitude__c   |          Location__Latitude__c
            wdctest__Location__Longitude__c  |          Location__Longitude__c
                                             |
    wdctest__Floor__c                        |  Location
        Id                                   |      wdcext__Floor__c *
        Name                                 |      Name
        wdctest__Level__c                    |      LocationLevel
        wdctest__Cleaning_Frequency_Days__c  |      wdcext__Cleaning_Frequency_Days__c
        wdctest__Building__c                 |      ParentLocationId
                                             |
    wdctest__Employee__c                     |  back2work__Employee__c
        Id                                   |      wdcext__Employee__c *
        wdctest__First_Name__c               |      back2work__FirstName__c
        wdctest__Last_Name__c                |      back2work__LastName__c
        wdctest__Status__c                   |      back2work__WellnessStatus__c
        wdctest__Floor__c                    |      back2work__Location__c
                                             |
    wdctest__Cleaning__c **                  |  N/A
        wdcext__Location__c
    
    * Adding External Id fields to Building, Floor, and Employee in extension package to hold corresponding 
    work.com record ids. These will be used to keep records in sync in triggers.

    ** wdctest__Cleaning__c does not need to be duplicated to work.com object b/c no corresponding 
    object exists. Instead, just need to add lookup to Location in ext package.
    */

    public static void processRecords(List<wdctest__Floor__c> sublocations) {
        try{

            wdctest__Floor__c existingFloor = sublocations.get(0);

            String buildingId = existingFloor.wdctest__Building__c;

            wdctest__Building__c building = [SELECT Id, wdcLocation__c 
                                             FROM wdctest__Building__c 
                                             WHERE Id =: buildingId];

            if(String.isEmpty(building.wdcLocation__c)) {
                //create parent Location
                sObject parentLocation = (sObject)Type.forName('Schema.Location').newInstance();
                parentLocation.put('Name', existingFloor.wdctest__Building__r.Name);
                parentLocation.put('Latitude', existingFloor.wdctest__Building__r.wdctest__Location__c.getLatitude());
                parentLocation.put('Longitude', existingFloor.wdctest__Building__r.wdctest__Location__c.getLongitude());
                insert parentLocation;

                //update existing wdctest building with location id
                //TODO: uncomment once added to package
                //building.wdcLocation__c = parentLocation.Id;
                update building;
            }

            //create sublocation (Floor)
            sObject newSublocation = (sObject)Type.forName('Schema.Location').newInstance();
            newSublocation.put('Name', existingFloor.Name);
            newSublocation.put('ParentLocationId', building.wdcLocation__c);
            insert newSublocation;

            //update existing wdctest floor with sublocation id
            //TODO: uncomment once added to package
            //existingFloor.wdcLocation__c = newSublocation.Id;
            update existingFloor;

            //create employees (Employee)
            Map<String, sObject> newEmployeesByExistingId = (Map<String, sObject>)Type.forName('Map<String, back2work__Employee__c>').newInstance();

            for(wdctest__Employee__c employee : existingFloor.wdctest__Employees__r) {
                sObject newEmployee = (sObject)Type.forName('back2work__Employee__c').newInstance();
                newEmployee.put('back2work__FirstName__c', employee.wdctest__First_Name__c);
                newEmployee.put('back2work__LastName__c', employee.wdctest__Last_Name__c);
                newEmployee.put('back2work__Location__c', newSublocation.Id);

                //TODO: need to add to data model to populate
                newEmployee.put('back2work__Email__c', 'test@test.com');//Email
                newEmployee.put('back2work__EmployeeNumber__c', employee.Id); //External Id
                newEmployee.put('back2work__EmployeeStatus__c', 'Active'); //Active, Inactive, Terminated, Leave
                newEmployee.put('back2work__StatusAsOf__c', Date.today()); //Date
                newEmployee.put('back2work__WorkerType__c', 'Employee'); //Employee, Intern, Contractor, Alumnus

                //need to get wellness status from map b/c values aren't exactly the same
                if(String.isNotEmpty(employee.wdctest__Status__c)) {
                    String wellnessStatus = back2workStatusByWdcTestStatus.get(employee.wdctest__Status__c);
                    newEmployee.put('back2work__WellnessStatus__c', wellnessStatus);
                }

                newEmployeesByExistingId.put(employee.Id, newEmployee);
            }

            insert newEmployeesByExistingId.values();

            //update existing wdctest employee records with wdc employee id
            for(wdctest__Employee__c employee : existingFloor.wdctest__Employees__r) {
                //TODO: uncomment once added to package
                //employee.wdcEmployee__c = newEmployeesByExistingId.get(employee.Id).Id;
            }

            update existingFloor.wdctest__Employees__r;

        } catch(Exception e) {

        }
    }

    public static void processTriggerRecords(Map<String, sObject> triggerNew, Map<String, sObject> recordsByTriggerObjId, Map<String, String> fieldMap, String objType) {
        for(String recordId : triggerNew.keySet()) {
            sObject loc = (sObject)Type.forName(objType).newInstance();

            if(recordsByTriggerObjId.containsKey(recordId)) {
                //if corresponding location exists, update
                loc = recordsByTriggerObjId.get(recordId);
            } else{
                //else, add to map
                recordsByTriggerObjId.put(recordId, loc);
            }

            Map<String, Object> recordMap = Trigger.newMap.get(recordId).getPopulatedFieldsAsMap();

            for(String field : recordMap.keySet()) {
                if(fieldMap.containsKey(field)) {
                    String locationField = fieldMap.get(field);
                    loc.put(locationField, recordMap.get(field));
                }
            }
        }

        List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<' + objType + '>').newInstance();
        recordsToUpsert.addAll(recordsByTriggerObjId.values());

        upsert recordsToUpsert;
    }
}
