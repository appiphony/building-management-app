trigger wdcLocation on Location (before insert) {
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

    List<wdctest__Floor__c> floors = [SELECT Id, wdcLocation__c
                                      FROM wdctest__Floor__c
                                      WHERE wdcLocation__c = :floorLocationsById.keySet()];

    List<wdctest__Building__c> bldgs = [SELECT Id, wdcLocation__c
                                        FROM wdctest__Building__c
                                        WHERE wdcLocation__c = :buildingLocationsById.keySet()];



    Map<String, String> locationIdByFloorId = new Map<String, String>();
    Map<String, String> locationIdByBuildingId = new Map<String, String>();
    for(wdctest__Floor__c flr : floors) {
        if(String.isNotEmpty(flr.wdcLocation__c)) {
            locationIdByFloorId.put(flr.Id, flr.wdcLocation__c);
        }
    }

    for(wdctest__Building__c bldg : bldgs) {
        if(String.isNotEmpty(bldg.wdcLocation__c)) {
            locationIdByBuildingId.put(bldg.Id, bldg.wdcLocation__c);
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

    dataMigrationBatchHelper.processTriggerRecords(buildingLocationsById, locationIdByBuildingId, buildingFieldByLocationField, 'wdctest__Building__c');
    dataMigrationBatchHelper.processTriggerRecords(floorLocationsById, locationIdByFloorId, floorFieldByLocationField, 'wdctest__Floor__c');
}