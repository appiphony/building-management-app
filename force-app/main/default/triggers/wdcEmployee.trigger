trigger wdcEmployee on back2work__Employee__c (after insert, after update) {
    Map<String, String> wdcEmployeeIdByEmployeeId = new Map<String, String>();
    Set<Id> wdcEmpIds = Trigger.newMap.keySet();
    List<wdctest__Employee__c> emps = [SELECT Id, wdctest__Floor__r.wdcLocation__c, wdcEmployee__c 
                                       FROM wdctest__Employee__c
                                       WHERE wdcEmployee__c =: wdcEmpIds];

    for(wdctest__Employee__c emp : emps) {
        if(String.isNotEmpty(emp.wdcEmployee__c)) {
            wdcEmployeeIdByEmployeeId.put(emp.Id, emp.wdcEmployee__c);
        }
    }

    //force map to map<string, sObject> for helper method
    Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));

    Map<String, String> b2WEmployeeFieldByEmployeeField = new Map<String, String>();
    for(String key : config.employeeFieldByB2WEmployeeField.keySet()) {
        b2WEmployeeFieldByEmployeeField.put(config.employeeFieldByB2WEmployeeField.get(key), key);
    }

    //dataMigrationBatchHelper.processTriggerRecords(triggerNew, wdcEmployeeIdByEmployeeId, b2WEmployeeFieldByEmployeeField, 'wdctest__Employee__c');
}