public with sharing class dataMigrationBatchHelper {

    /*
    Namespaces:
        • wdctest -> Building App (Appiphony) Base Package
        • wdcext -> Building App (Appiphony) Extension Package
        • back2work -> Work.com Package

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAPPING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    wdctest__Building__c                     |  Location
        wdcBuilding__c *                     |      Id
        Name                                 |      Name
        wdctest__Location__c                 |      Location
            wdctest__Location__Latitude__c   |          Location__Latitude__c
            wdctest__Location__Longitude__c  |          Location__Longitude__c
                                             |
    wdctest__Floor__c                        |  Location
        wdcFloor__c *                        |      Id
        Name                                 |      Name
        wdctest__Level__c                    |      LocationLevel
        wdctest__Cleaning_Frequency_Days__c  |      wdcCleaning_Frequency_Days__c
        wdctest__Building__c                 |      ParentLocationId
                                             |
    wdctest__Employee__c                     |  back2work__Employee__c
        wdcEmployee__c *                     |      Id
        wdctest__First_Name__c               |      back2work__FirstName__c
        wdctest__Last_Name__c                |      back2work__LastName__c
        wdctest__Status__c                   |      back2work__WellnessStatus__c
        wdctest__Floor__c                    |      back2work__Location__c
                                             |
    wdctest__Cleaning__c **                  |  N/A


    * Adding External Id fields to Building, Floor, and Employee in extension package to hold corresponding 
    work.com record ids. These will be used to keep records in sync in triggers and ensure we dont inser duplicates
    in initial data sync

    ** wdctest__Cleaning__c does not need to be duplicated to work.com object b/c no corresponding 
    object exists. Instead, just need to add lookup to Location in ext package.
    */

    public static void transferData() {
        try{
            //get all locations
            Set<String> locationQueryFields = new Set<String>();
            locationQueryFields.addAll(config.locationFieldByBuildingField.values());
            locationQueryFields.addAll(config.locationFieldByFloorField.values());
            locationQueryFields.add('Id');
            locationQueryFields.add('ParentLocationId');
    
            List<String> locationFields = new List<String>();
            locationFields.addAll(locationQueryFields);
    
            String locationQuery = 'SELECT ' + String.join(locationFields, ',') + 
                                   ' FROM Location';
            List<sObject> locations = Database.query(locationQuery);
    
            Map<String, wdctest__Building__c> newBuildingsByLocationId = new Map<String, wdctest__Building__c>();
            Map<String, List<wdctest__Floor__c>> newFloorsByParentLocationId = new Map<String, List<wdctest__Floor__c>>();
            //populate building and floor records based on locations
            for(sObject loc : locations) {
                if(loc.get('ParentLocationId') != null) {
                    wdctest__Floor__c newFloor = new wdctest__Floor__c();
                    for(String key : config.locationFieldByFloorField.keySet()) {
                        String wdcField = config.locationFieldByFloorField.get(key);
                        if(loc.get(wdcField) != null) {
                            newFloor.put(key, loc.get(wdcField));
                        }
                    }
                    
                    if(newFloorsByParentLocationId.containsKey((String)loc.get('ParentLocationId'))) {
                        newFloorsByParentLocationId.get((String)loc.get('ParentLocationId')).add(newFloor);
                    } else{
                        newFloorsByParentLocationId.put((String)loc.get('ParentLocationId'), new List<wdctest__Floor__c>{newFloor});
                    }
                } else{
                    wdctest__Building__c newBuilding = new wdctest__Building__c();
                    for(String key : config.locationFieldByBuildingField.keySet()) {
                        String wdcField = config.locationFieldByBuildingField.get(key);
                        if(loc.get(wdcField) != null) {
                            newBuilding.put(key, loc.get(wdcField));
                        }
                    }
                    newBuildingsByLocationId.put((String)loc.get('Id'), newBuilding);
                }
            }
            insert newBuildingsByLocationId.values();
        
            List<wdctest__Floor__c> newFloors = new List<wdctest__Floor__c>();
            //populate parent building field on floors
            for(String key : newFloorsByParentLocationId.keySet()) {
                wdctest__Building__c parentBuilding = newBuildingsByLocationId.get(key);
                for(wdctest__Floor__c flr : newFloorsByParentLocationId.get(key)) {
                    flr.put('wdctest__Building__c', parentBuilding.Id);
                    newFloors.add(flr);
                }
            }
            insert newFloors;
    
            //get all employees
            Set<String> employeeQueryFields = new Set<String>();
            employeeQueryFields.addAll(config.employeeFieldByB2WEmployeeField.values());
            employeeQueryFields.add('Id');
    
            List<String> employeeFields = new List<String>();
            employeeFields.addAll(employeeQueryFields);
    
            String employeeQuery = 'SELECT ' + String.join(employeeFields, ',') + 
                                   ' FROM back2work__Employee__c';
            List<sObject> employees = Database.query(employeeQuery);
    
            Map<String, List<wdctest__Employee__c>> newEmployeesByLocationId = new Map<String, List<wdctest__Employee__c>>();

            Map<String, String> wdcStatusByb2wStatus = new Map<String, String>();
            for(String key : config.back2workStatusByWdcTestStatus.keySet()) {
                wdcStatusByb2wStatus.put(config.back2workStatusByWdcTestStatus.get(key), key);
            }

            //populate employee records
            for(sObject emp : employees) {
                wdctest__Employee__c newEmployee = new wdctest__Employee__c();
                for(String key : config.employeeFieldByB2WEmployeeField.keySet()) {
                    String wdcField = config.employeeFieldByB2WEmployeeField.get(key);
                    if(emp.get(wdcField) != null) {
                        if(key == 'wdctest__Status__c') {
                            newEmployee.put(key, wdcStatusByb2wStatus.get((String)emp.get(wdcField)));
                        } else{
                            newEmployee.put(key, emp.get(wdcField));
                        }
                    }
                }
    
                if(newEmployeesByLocationId.containsKey((String)emp.get('back2work__Location__c'))) {
                    newEmployeesByLocationId.get((String)emp.get('back2work__Location__c')).add(newEmployee);
                } else{
                    newEmployeesByLocationId.put((String)emp.get('back2work__Location__c'), new List<wdctest__Employee__c>{newEmployee});
                }
            }

            //build map of locationId => floorId
            Map<String, String> floorIdByLocationId = new Map<String, String>();
            for(sObject flrs : newFloors) {
                floorIdByLocationId.put((String)flr.get('wdcLocation__c'), flr.Id);
            }

            List<wdctest__Employee__c> newEmployees = new List<wdctest__Employee__c>();
            for(String locId : newEmployeesByLocationId.keySet()) {
                String floorId;
                if(floorIdByLocationId.containsKey(locId)) {
                    floorId = floorIdByLocationId.get(locId);
                } else if(newFloorsByParentLocationId.containsKey(locId)) {
                    floorId = (String)newFloorsByParentLocationId.get(locId).get(0).get('Id');
                }

                for(wdctest__Employee__c emp : newEmployeesByLocationId.get(locId)) {
                    emp.put('wdctest__Floor__c', floorId);
                    newEmployees.add(emp);
                }
            }
            insert newEmployees;   
        } catch (Exception e) {
            System.debug('*********** message: ' + e.getMessage());
            System.debug('*********** stack: ' + e.getStackTraceString());
        }
    }

    public static void createCleanings() {
        delete [SELECT Id FROM wdctest__Cleaning__c];
        List<wdctest__Cleaning__c> cleanings = new List<wdctest__Cleaning__c>();
        for(wdctest__Floor__c flr : [SELECT Id FROM wdctest__Floor__c]) {
            cleanings.add(new wdctest__Cleaning__c(wdctest__Floor__c = flr.Id, wdctest__Cleaning_Time__c = DateTime.now()));
        }
        insert cleanings;
    }

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
                building.wdcLocation__c = parentLocation.Id;
                update building;
            }

            //create sublocation (Floor)
            sObject newSublocation = (sObject)Type.forName('Schema.Location').newInstance();
            newSublocation.put('Name', existingFloor.Name);
            newSublocation.put('ParentLocationId', building.wdcLocation__c);
            insert newSublocation;

            //update existing wdctest floor with sublocation id
            existingFloor.wdcLocation__c = newSublocation.Id;
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
                    String wellnessStatus = config.back2workStatusByWdcTestStatus.get(employee.wdctest__Status__c);
                    newEmployee.put('back2work__WellnessStatus__c', wellnessStatus);
                }

                newEmployeesByExistingId.put(employee.Id, newEmployee);
            }

            insert newEmployeesByExistingId.values();

            //update existing wdctest employee records with wdc employee id
            for(wdctest__Employee__c employee : existingFloor.wdctest__Employees__r) {
                employee.wdcEmployee__c = newEmployeesByExistingId.get(employee.Id).Id;
            }

            update existingFloor.wdctest__Employees__r;

        } catch(Exception e) {

        }
    }

    public static void processTriggerRecords(Map<String, sObject> triggerNew, Map<String, sObject> existingRecordByTriggerObjId, Map<String, String> fieldMap, String objType) {
        System.debug('******* objType: ' + objType);
        System.debug('******* existingRecordByTriggerObjId: ' + existingRecordByTriggerObjId);

        List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<' + objType + '>').newInstance();
        for(String recordId : triggerNew.keySet()) {
            System.debug('******* recordId: ' + recordId);
            sObject wdcRecord = (sObject)Type.forName(objType).newInstance();

            if(existingRecordByTriggerObjId.containsKey(recordId)) {
                //if corresponding location exists, update
                wdcRecord = existingRecordByTriggerObjId.get(recordId);
                System.debug('********* EXISTING: ' + wdcRecord);
            }

            Map<String, Object> recordMap = TriggerNew.get(recordId).getPopulatedFieldsAsMap();
            Boolean addToList = false;
            for(String field : recordMap.keySet()) {
                System.debug('*********** field: ' + field);
                if(fieldMap.containsKey(field)) {
                    String wdcField = fieldMap.get(field);
                    System.debug('*********** wdcField: ' + wdcField);
                    System.debug('*********** wdcRecord.get(wdcField): ' + wdcRecord.get(wdcField));
                    System.debug('*********** recordMap.get(field): ' + recordMap.get(field));
                    if(fieldMap.containsKey(field) && wdcField != 'Id' && wdcRecord.get(wdcField) != recordMap.get(field)) {
                        wdcRecord.put(wdcField, recordMap.get(field));
                        addToList = true;
                    }   
                }
            }
            System.debug('********** addToList: ' + addToList);
            System.debug('********** wdcRecord.Id : ' + wdcRecord.Id);
            if(wdcRecord.Id == null || addToList) {
                System.debug('**** ADDED ****');
                recordsToUpsert.add(wdcRecord);   
            }
        }
        upsert recordsToUpsert;
    }
}
