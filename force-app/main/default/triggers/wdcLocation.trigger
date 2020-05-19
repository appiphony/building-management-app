trigger wdcLocation on Location (after insert, after update) {
    Map<String, sObject> floorLocationsById = new Map<String, sObject>();
    Map<String, sObject> buildingLocationsById = new Map<String, sObject>();

    for(Schema.Location loc : Trigger.new) {
        sObject locSobject = (sObject)JSON.deserialize(JSON.serialize(loc), Type.forName('sObject'));
        if(String.isNotEmpty(loc.ParentLocationId)) {
            //floor
            floorLocationsById.put(loc.Id, locSobject);
        } else{
            //building
            buildingLocationsById.put(loc.Id, locSobject);
        }
    }
    
    Map<String, String> buildingFieldByLocationField = new Map<String, String>();
    for(String key : config.locationFieldByBuildingField.keySet()) {
        buildingFieldByLocationField.put(config.locationFieldByBuildingField.get(key), key);
    }

    Map<String, String> floorFieldByLocationField = new Map<String, String>();
    for(String key : config.locationFieldByFloorField.keySet()) {
        floorFieldByLocationField.put(config.locationFieldByFloorField.get(key), key);
    }

    Set<String> floorLocations = floorLocationsById.keySet();
    Set<String> bldgLocations = buildingLocationsById.keySet();

    List<wdctest__Floor__c> floors = Database.query('SELECT ' + String.join(floorFieldByLocationField.values(), ',') + 
                                                    ' FROM wdctest__Floor__c' +
                                                    ' WHERE wdcLocation__c = :floorLocations');

    List<wdctest__Building__c> bldgs = Database.query('SELECT ' + String.join(buildingFieldByLocationField.values(), ',') +
                                                      ' FROM wdctest__Building__c' +
                                                      ' WHERE wdcLocation__c = :bldgLocations');



    Map<String, sObject> floorByLocationId = new Map<String, sObject>();
    Map<String, sObject> buildingByLocationId = new Map<String, sObject>();
    for(wdctest__Floor__c flr : floors) {
        if(String.isNotEmpty(flr.wdcLocation__c)) {
            floorByLocationId.put(flr.wdcLocation__c, flr);
        }
    }

    for(wdctest__Building__c bldg : bldgs) {
        if(String.isNotEmpty(bldg.wdcLocation__c)) {
            buildingByLocationId.put(bldg.wdcLocation__c, bldg);
        }
    }

    dataMigrationBatchHelper.processTriggerRecords(buildingLocationsById, buildingByLocationId, buildingFieldByLocationField, 'wdctest__Building__c');
    dataMigrationBatchHelper.processTriggerRecords(floorLocationsById, floorByLocationId, floorFieldByLocationField, 'wdctest__Floor__c');
}