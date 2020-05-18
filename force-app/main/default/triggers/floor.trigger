trigger floor on wdctest__Floor__c (before insert) {
    Map<String, String> locationIdByFloorId = new Map<String, String>();
    for(wdctest__Floor__c flr : Trigger.new) {
        if(String.isNotEmpty(flr.wdcLocation__c)) {
            locationIdByFloorId.put(flr.Id, flr.wdcLocation__c);
        }
    }

    //force map to map<string, sObject> for helper method
    Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));

    dataMigrationBatchHelper.processTriggerRecords(triggerNew, locationIdByFloorId, config.locationFieldByFloorField, 'Schema.Location');
}