trigger building on wdctest__Building__c (after insert, after update) {
    Set<Id> buildingIds = Trigger.newMap.keySet();
    String queryString = 'SELECT Id, wdcext__Building__c ' + 
                         'FROM Location ' + 
                         'WHERE wdcext__Building__c =: buildingIds';

    Map<String, sObject> locationsByBuildingId = new Map<String, sObject>();
    for(sObject loc : Database.query(queryString)) {
        locationsByBuildingId.put((String)loc.get('wdcext__Building__c'), loc);
    }

    //force map to map<string, sObject> for helper method
    Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));

    dataMigrationBatchHelper.processTriggerRecords(triggerNew, locationsByBuildingId, config.locationFieldByBuildingField, 'Schema.Location');
}