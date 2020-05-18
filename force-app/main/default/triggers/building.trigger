trigger building on wdctest__Building__c (after insert, after update) {
    Map<String, String> locationIdByBuildingId = new Map<String, String>();
    for(wdctest__Building__c bldg : Trigger.new) {
        if(String.isNotEmpty(bldg.wdcLocation__c)) {
            locationIdByBuildingId.put(bldg.Id, bldg.wdcLocation__c);
        }
    }

    //force map to map<string, sObject> for helper method
    Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));

    dataMigrationBatchHelper.processTriggerRecords(triggerNew, locationIdByBuildingId, config.locationFieldByBuildingField, 'Schema.Location');
}