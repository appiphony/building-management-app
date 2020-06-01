trigger wdcLocation on Location (after insert, after update) {
    try{
        
        Map<String, Schema.Location> floorLocationsById = new Map<String, Schema.Location>();
        Map<String, Schema.Location> buildingLocationsById = new Map<String, Schema.Location>();
        Map<String, String> buildingIdByParentLocationId = new Map<String, String>();

        //separate floors from buildings
        for(Schema.Location loc : Trigger.new) {
            if(String.isNotEmpty(loc.ParentLocationId)) {
                //floor
                floorLocationsById.put(loc.Id, loc);
                buildingIdByParentLocationId.put(loc.ParentLocationId, '');
            } else{
                //building
                buildingLocationsById.put(loc.Id, loc);
            }
        }

        //get all buildings that are parents of floors
        for(Building__c bldg : [SELECT Id, wdcLocation__c FROM Building__c WHERE wdcLocation__c =: buildingIdByParentLocationId.keySet()]) {
            buildingIdByParentLocationId.put(bldg.wdcLocation__c, bldg.Id);
        }

        //build proper field maps based on config file
        Map<String, String> buildingFieldByLocationField = new Map<String, String>();
        for(String key : config.locationFieldByBuildingField.keySet()) {
            buildingFieldByLocationField.put(config.locationFieldByBuildingField.get(key), key);
        }

        Map<String, String> floorFieldByLocationField = new Map<String, String>();
        for(String key : config.locationFieldByFloorField.keySet()) {
            floorFieldByLocationField.put(config.locationFieldByFloorField.get(key), key);
        }

        Set<String> bldgFields = new Set<String>();
        bldgFields.addAll(buildingFieldByLocationField.values());
        bldgFields.add('wdcLocation__c');

        List<String> bldgQueryFields = new List<String>();
        bldgQueryFields.addAll(bldgFields);

        Set<String> flrFields = new Set<String>();
        flrFields.addAll(floorFieldByLocationField.values());
        flrFields.add('wdcLocation__c');

        List<String> flrQueryFields = new List<String>();
        flrQueryFields.addAll(flrFields);


        Set<String> bldgLocations = buildingLocationsById.keySet();
        Set<String> floorLocations = floorLocationsById.keySet();

        List<Building__c> bldgs = Database.query('SELECT ' + String.join(bldgQueryFields, ',') +
                                                          ' FROM Building__c' +
                                                          ' WHERE wdcLocation__c = :bldgLocations');

        List<Floor__c> floors = Database.query('SELECT ' + String.join(flrQueryFields, ',') + 
                                                        ' FROM Floor__c' +
                                                        ' WHERE wdcLocation__c = :floorLocations');

        Map<String, sObject> buildingByLocationId = new Map<String, sObject>();
        Map<String, sObject> floorByLocationId = new Map<String, sObject>();
        for(Building__c bldg : bldgs) {
            if(String.isNotEmpty(bldg.wdcLocation__c)) {
                buildingByLocationId.put(bldg.wdcLocation__c, bldg);
            }
        }

        for(Floor__c flr : floors) {
            if(String.isNotEmpty(flr.wdcLocation__c)) {
                floorByLocationId.put(flr.wdcLocation__c, flr);
            }
        }

        String bldgObjType = 'Building__c';
        String flrObjType = 'Floor__c';

        List<sObject> bldgsToUpsert = (List<sObject>)Type.forName('List<' + bldgObjType + '>').newInstance();
        List<sObject> flrsToUpsert = (List<sObject>)Type.forName('List<' + flrObjType + '>').newInstance();

        for(String recordId : Trigger.newMap.keySet()) {
            Boolean addToList = false;
            sObject wdcRecord;
            Map<String, String> fieldMap;
            Schema.Location locRecord = Trigger.newMap.get(recordId);
            if(locRecord.ParentLocationId == null) {
                //building
                wdcRecord = (sObject)Type.forName(bldgObjType).newInstance();
                fieldMap = buildingFieldByLocationField;
                if(buildingByLocationId.containsKey(recordId)) {
                    //use existing
                    wdcRecord = (sObject)JSON.deserialize(JSON.serialize(buildingByLocationId.get(recordId)), Type.forName('sObject'));
                }
            } else{
                //floor
                wdcRecord = (sObject)Type.forName(flrObjType).newInstance();
                fieldMap = floorFieldByLocationField;
                if(floorByLocationId.containsKey(recordId)) {
                    //use existing
                    wdcRecord = (sObject)JSON.deserialize(JSON.serialize(floorByLocationId.get(recordId)), Type.forName('sObject'));
                }
            }

            if(wdcRecord.get('wdcLocation__c') == null || (String)wdcRecord.get('wdcLocation__c') != locRecord.Id) {
                wdcRecord.put('wdcLocation__c', locRecord.Id);
                addToList = true;
            }

            Map<String, Object> recordMap = locRecord.getPopulatedFieldsAsMap();
            for(String field : recordMap.keySet()) {
                if(fieldMap.containsKey(field)) {
                    String wdcField = fieldMap.get(field);
                    if(fieldMap.containsKey(field) && wdcField != 'Id' && wdcRecord.get(wdcField) != recordMap.get(field)) {
                        wdcRecord.put(wdcField, recordMap.get(field));
                        addToList = true;
                    }
                }
            }

            if(wdcRecord.get('Id') == null || addToList) {
                if(locRecord.ParentLocationId == null) {
                    bldgsToUpsert.add(wdcRecord);
                } else{
                    if(String.isNotEmpty(locRecord.ParentLocationId) && buildingIdByParentLocationId.containsKey(locRecord.ParentLocationId)) {
                        //only upsert if has building 
                        String bldgId = buildingIdByParentLocationId.get(locRecord.ParentLocationId);
                        wdcRecord.put('Building__c', bldgId);

                        //populate with random cleaning freq if null
                        if(wdcRecord.get('Cleaning_Frequency_Days__c') == null) {
                            Integer freqIndex = Integer.valueOf(Math.random()*config.frequencies.size());
                            wdcRecord.put('Cleaning_Frequency_Days__c', config.frequencies.get(freqIndex));
                        }
                        flrsToUpsert.add(wdcRecord);
                    }
                }
            }
        }

        upsert bldgsToUpsert;
        upsert flrsToUpsert;
    }catch(Exception e){
    }
}