trigger floor on Floor__c (after insert, after update) {
    try{
        
        Map<String, String> floorIdBylocationId = new Map<String, String>();
        Map<String, Schema.Location> locationByFloorId = new Map<String, Schema.Location>();

        for(Floor__c flr : Trigger.new) {
            if(String.isNotEmpty(flr.wdcLocation__c)) {
                floorIdBylocationId.put(flr.wdcLocation__c, flr.Id);
            }
        }

        Set<String> locIds = floorIdBylocationId.keySet();

        Set<String> locFields = new Set<String>();
        locFields.addAll(config.locationFieldByFloorField.values());
        locFields.add('Id');

        List<String> queryFields = new List<String>();
        queryFields.addAll(locFields);

        String query = 'SELECT ' + String.join(queryFields, ',') + 
                       ' FROM Location' + 
                       ' WHERE Id =: locIds';

        List<Schema.Location> locations = Database.query(query);

        for(Schema.Location loc : locations) {
            locationByFloorId.put(floorIdBylocationId.get(loc.Id), loc);
        }

        Map<String, String> fieldMap = config.locationFieldByFloorField;

        String objType = 'Schema.Location';

        List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<' + objType + '>').newInstance();

        for(String recordId : Trigger.newMap.keySet()) {
            sObject wdcRecord = (sObject)Type.forName(objType).newInstance();

            if(locationByFloorId.containsKey(recordId)) {
                //if corresponding location exists, update
                wdcRecord = (sObject)JSON.deserialize(JSON.serialize(locationByFloorId.get(recordId)), Type.forName('sObject'));
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
    }catch(Exception e){
    }
}