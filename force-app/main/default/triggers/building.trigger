trigger building on wdctest__Building__c (after insert, after update) {
    Map<String, String> buildingIdBylocationId = new Map<String, String>();
    Map<String, Schema.Location> locationByBuildingId = new Map<String, Schema.Location>();

    for(wdctest__Building__c bldg : Trigger.new) {
        if(String.isNotEmpty(bldg.wdctestext__wdcLocation__c)) {
            buildingIdBylocationId.put(bldg.wdctestext__wdcLocation__c, bldg.Id);
        }
    }

    Set<String> locIds = buildingIdBylocationId.keySet();

    Set<String> locFields = new Set<String>();
    locFields.addAll(config.locationFieldByBuildingField.values());
    locFields.add('Id');

    List<String> queryFields = new List<String>();
    queryFields.addAll(locFields);

    String query = 'SELECT ' + String.join(queryFields, ',') + 
                   ' FROM Location' + 
                   ' WHERE Id =: locIds';

    List<Schema.Location> locations = Database.query(query);

    for(Schema.Location loc : locations) {
        locationByBuildingId.put(buildingIdBylocationId.get(loc.Id), loc);
    }

    Map<String, String> fieldMap = config.locationFieldByBuildingField;

    String objType = 'Schema.Location';

    List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<' + objType + '>').newInstance();

    for(String recordId : Trigger.newMap.keySet()) {
        sObject wdcRecord = (sObject)Type.forName(objType).newInstance();

        if(locationByBuildingId.containsKey(recordId)) {
            //if corresponding location exists, update
            wdcRecord = (sObject)JSON.deserialize(JSON.serialize(locationByBuildingId.get(recordId)), Type.forName('sObject'));
        }

        Map<String, Object> recordMap = Trigger.newMap.get(recordId).getPopulatedFieldsAsMap();
        Boolean addToList = false;
        for(String field : recordMap.keySet()) {
            if(fieldMap.containsKey(field)) {
                String wdcField = fieldMap.get(field);
                if(fieldMap.containsKey(field) && wdcField != 'Id' && wdcRecord.get(wdcField) != recordMap.get(field)) {
                    wdcRecord.put(wdcField, recordMap.get(field));
                    addToList = true;
                }
            }
        }

        if(wdcRecord.Id == null || addToList) {
            recordsToUpsert.add(wdcRecord);   
        }
    }

    upsert recordsToUpsert;
}