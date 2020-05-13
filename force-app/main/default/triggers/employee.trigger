trigger employee on wdctest__Employee__c (before insert) {
    Set<Id> employeeIds = Trigger.newMap.keySet();
    String queryString = 'SELECT Id, wdcext__Employee__c ' + 
                         'FROM back2work__Employee__c ' + 
                         'WHERE wdcext__Employee__c =: employeeIds';

    Map<String, sObject> b2wEmployeeByEmployeeId = new Map<String, sObject>();
    for(sObject emp : Database.query(queryString)) {
        b2wEmployeeByEmployeeId.put((String)loc.get('wdcext__Employee__c'), emp);
    }

    //force map to map<string, sObject> for helper method
    Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));

    dataMigrationBatchHelper.processTriggerRecords(triggerNew, locationsByBuildingId, config.employeeFieldByB2WEmployeeField, 'back2work__Employee__c');
}