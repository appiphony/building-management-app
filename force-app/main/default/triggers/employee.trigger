trigger employee on wdctest__Employee__c (before insert) {
    Map<String, String> b2wEmployeeIdByEmployeeId = new Map<String, String>();
    for(wdctest__Employee__c emp : Trigger.new) {
        if(String.isNotEmpty(emp.wdcEmployee__c)) {
            b2wEmployeeIdByEmployeeId.put(emp.Id, emp.wdcEmployee__c);
        }
    }

    //force map to map<string, sObject> for helper method
    Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));

    //dataMigrationBatchHelper.processTriggerRecords(triggerNew, b2wEmployeeIdByEmployeeId, config.employeeFieldByB2WEmployeeField, 'back2work__Employee__c');
}