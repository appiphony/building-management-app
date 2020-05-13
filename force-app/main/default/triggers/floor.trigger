trigger floor on wdctest__Floor__c (before insert) {
    Set<Id> employeeIds = Trigger.newMap.keySet();
    String queryString = 'SELECT Id, wdcext__Floor__c ' + 
                         'FROM Location ' + 
                         'WHERE wdcext__Floor__c =: employeeIds';

    Map<String, sObject> locationByFloorId = new Map<String, sObject>();
    for(sObject loc : Database.query(queryString)) {
        locationByFloorId.put((String)loc.get('wdcext__Floor__c'), loc);
    }

    //force map to map<string, sObject> for helper method
    Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));

    dataMigrationBatchHelper.processTriggerRecords(triggerNew, locationsByBuildingId, config.locationFieldByFloorField, 'Schema.Location');
}