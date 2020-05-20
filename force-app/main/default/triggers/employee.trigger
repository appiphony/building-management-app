trigger employee on wdctest__Employee__c (before insert) {
    Map<String, String> b2wEmployeeIdByEmployeeId = new Map<String, String>();
    Map<String, String> employeeIdByb2wEmployeeId = new Map<String, String>();
    for(wdctest__Employee__c emp : Trigger.new) {
        if(String.isNotEmpty(emp.wdcEmployee__c)) {
            b2wEmployeeIdByEmployeeId.put(emp.Id, emp.wdcEmployee__c);
            employeeIdByb2wEmployeeId(emp.wdcEmployee__c, emp.Id);
        }
    }

    Set<String> b2wEmpFields = config.employeeFieldByB2WEmployeeField.keySet();
    b2wEmpFields.add('Id');

    List<String> queryFields = new List<String>();
    queryFields.addAll(b2wEmpFields);

    List<String> empIds = b2wEmployeeIdByEmployeeId.values();

    String b2wEmployeeQuery = 'SELECT ' + String.join(queryFields, ',') + 
                              ' FROM back2work__Employee__c' + 
                              ' WHERE Id =: empIds';

    Map<String, sObject> existingRecordByTriggerObjId = new Map<String, sObject>();

    for(sObject existingB2wEmployee : Database.query(query)) {
        existingRecordByTriggerObjId.put(employeeIdByb2wEmployeeId.get(existingB2wEmployee.Id), existingB2wEmployee);
    }

    String objType = 'back2work__Employee__c';
    //force map to map<string, sObject> for helper method
    //Map<String, sObject> triggerNew = (Map<String, sObject>)JSON.deserialize(JSON.serialize(Trigger.newMap), Type.forName('Map<String, sObject>'));
    Map<String, String> fieldMap = config.employeeFieldByB2WEmployeeField
    //dataMigrationBatchHelper.processTriggerRecords(triggerNew, b2wEmployeeIdByEmployeeId, config.employeeFieldByB2WEmployeeField, 'back2work__Employee__c');
    List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<' + objType + '>').newInstance();
    for(String recordId : Trigger.newMap.keySet()) {
        System.debug('******* recordId: ' + recordId);
        sObject wdcRecord = (sObject)Type.forName(objType).newInstance();

        if(existingRecordByTriggerObjId.containsKey(recordId)) {
            //if corresponding location exists, update
            wdcRecord = existingRecordByTriggerObjId.get(recordId);
            System.debug('********* EXISTING: ' + wdcRecord);
        }

        Map<String, Object> recordMap = Trigger.newMap.get(recordId).getPopulatedFieldsAsMap();
        Boolean addToList = false;
        for(String field : recordMap.keySet()) {
            System.debug('*********** field: ' + field);
            if(fieldMap.containsKey(field)) {
                String wdcField = fieldMap.get(field);
                System.debug('*********** wdcField: ' + wdcField);
                System.debug('*********** wdcRecord.get(wdcField): ' + wdcRecord.get(wdcField));
                System.debug('*********** recordMap.get(field): ' + recordMap.get(field));
                if(fieldMap.containsKey(field) && wdcField != 'Id' && wdcRecord.get(wdcField) != recordMap.get(field)) {
                    wdcRecord.put(wdcField, recordMap.get(field));
                    addToList = true;
                }   
            }
        }
        System.debug('********** addToList: ' + addToList);
        System.debug('********** wdcRecord.Id : ' + wdcRecord.Id);
        if(wdcRecord.Id == null || addToList) {
            System.debug('**** ADDED ****');
            recordsToUpsert.add(wdcRecord);   
        }
    }
    upsert recordsToUpsert;
}