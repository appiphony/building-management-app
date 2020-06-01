trigger employee on Employee__c (after insert, after update) {
    Map<String, String> employeeIdByb2wEmployeeId = new Map<String, String>();
    Map<String, String> locationIdByFloorId = new Map<String, String>();
    for(Employee__c emp : Trigger.new) {
        if(String.isNotEmpty(emp.wdcEmployee__c)) {
            employeeIdByb2wEmployeeId.put(emp.wdcEmployee__c, emp.Id);
            locationIdByFloorId.put(emp.Floor__c, '');
        }
    }

    for(FLoor__c flr : [SELECT Id, wdcLocation__c FROM Floor__c WHERE Id =: locationIdByFloorId.keySet()]) {
        locationIdByFloorId.put(flr.Id, flr.wdcLocation__c);
    }

    Set<String> b2wEmpFields = new Set<String>();
    b2wEmpFields.addAll(config.b2WEmployeeFieldByemployeeField.values());
    b2wEmpFields.add('Id');
    b2wEmpFields.add('LocationId');

    List<String> queryFields = new List<String>();
    queryFields.addAll(b2wEmpFields);

    Set<String> empIds = employeeIdByb2wEmployeeId.keySet();

    String query = 'SELECT ' + String.join(queryFields, ',') + 
                  ' FROM Employee' + 
                  ' WHERE Id =: empIds';

    Map<String, sObject> existingRecordByTriggerObjId = new Map<String, sObject>();

    for(sObject existingB2wEmployee : Database.query(query)) {
        existingRecordByTriggerObjId.put(employeeIdByb2wEmployeeId.get(existingB2wEmployee.Id), existingB2wEmployee);
    }

    Map<String, String> fieldMap = config.b2WEmployeeFieldByemployeeField;
    String objType = 'Employee';

    List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<' + objType + '>').newInstance();
    for(String recordId : Trigger.newMap.keySet()) {
        sObject wdcRecord = (sObject)Type.forName(objType).newInstance();

        Map<String, Object> recordMap = Trigger.newMap.get(recordId).getPopulatedFieldsAsMap();

        if(existingRecordByTriggerObjId.containsKey(recordId)) {
            //if corresponding employee exists, update
            wdcRecord = existingRecordByTriggerObjId.get(recordId);
        } else{
            String firstName = (String)recordMap.get('First_Name__c');
            String lastName = (String)recordMap.get('Last_Name__c');

            //populate required fields
            wdcRecord.put('Email', firstName.deleteWhitespace() + lastName.deleteWhitespace() + '@example.com');
            wdcRecord.put('EmployeeStatus', 'Active');
            wdcRecord.put('StatusAsOf', Date.today());
            wdcRecord.put('WorkerType', 'Employee');
            wdcRecord.put('EmployeeNumber', firstName.deleteWhitespace() + lastName.deleteWhitespace() + String.valueOf(Integer.valueOf(Math.random()*100000)));
        }

        Boolean addToList = false;
        for(String field : recordMap.keySet()) {
            if(fieldMap.containsKey(field)) {
                String wdcField = fieldMap.get(field);
                if(fieldMap.containsKey(field) && wdcField != 'Id') {
                    if(field == 'Status__c') {
                        String value = config.back2workStatusByWdcTestStatus.get((String)recordMap.get(field));
                        if(wdcRecord.get(wdcField) != value) {
                            wdcRecord.put(wdcField, value);
                            addToList = true;
                        }
                    } else if(wdcRecord.get(wdcField) != recordMap.get(field)){
                        wdcRecord.put(wdcField, recordMap.get(field));
                        addToList = true;
                    }
                }
            }
        }

        Id flrId = Trigger.newMap.get(recordId).Floor__c;

        if(String.isNotEmpty(flrId)) {
            Id locId = locationIdByFloorId.get(flrId);
            if(locId != (Id)wdcRecord.get('LocationId')) {
                wdcRecord.put('LocationId', locId);
                addToList = true;
            }
        }

        if(wdcRecord.Id == null || addToList) {
            recordsToUpsert.add(wdcRecord);   
        }
    }

    upsert recordsToUpsert;
}