trigger wdcEmployee on Employee (after insert, after update) {
    try{
        Map<String, sObject> employeeByWdcEmployeeId = (Map<String, sObject>) Type.forName('Map<String, Employee__c>').newInstance();
        Map<String, String> floorIdByLocationId = new Map<String, String>();
        Set<Id> wdcEmpIds = Trigger.newMap.keySet();

        //get all related Employee__c records that exist
        //go thru all trigger.new and check if record exists, use it else new
        //for status field, need to get value from config map
        //for floor field, need to get floors with locations that are on emps

        Set<String> empFields = new Set<String>();
        empFields.addAll(config.b2WEmployeeFieldByemployeeField.keySet());
        empFields.add('Id');
        empFields.add('Floor__c');
        empFields.add('Floor__r.wdcLocation__c');
        empFields.add('wdcEmployee__c');

        List<String> queryFields = new List<String>();
        queryFields.addAll(empFields);

        String query = 'SELECT ' + String.join(queryFields, ',') + 
                       ' FROM Employee__c' + 
                       ' WHERE wdcEmployee__c =: wdcEmpIds';

        List<sObject> emps = Database.query(query);

        for(sObject emp : emps) {
            String wdcEmployee = (String)emp.get('wdcEmployee__c');
            if(String.isNotEmpty(wdcEmployee)) {
                employeeByWdcEmployeeId.put(wdcEmployee, emp);
            }
        }

        for(Employee emp : Trigger.new) {
            floorIdByLocationId.put(emp.LocationId, '');
        }

        Set<String> locationIds = floorIdByLocationId.keySet();
        for(sObject flr : Database.query('SELECT Id, wdcLocation__c FROM Floor__c WHERE wdcLocation__c =: locationIds')) {
            floorIdByLocationId.put((String)flr.get('wdcLocation__c'), (String)flr.get('Id'));
        }


        Map<String, String> fieldMap = new Map<String, String>();
        for(String key : config.b2WEmployeeFieldByemployeeField.keySet()) {
            fieldMap.put(config.b2WEmployeeFieldByemployeeField.get(key), key);
        }

        List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<Employee__c>').newInstance();
        for(String recordId : Trigger.newMap.keySet()) {
            sObject wdcRecord = (sObject)Type.forName('Employee__c').newInstance();

            if(employeeByWdcEmployeeId.containsKey(recordId)) {
                //if corresponding location exists, update
                wdcRecord = (sObject)JSON.deserialize(JSON.serialize(employeeByWdcEmployeeId.get(recordId)), Type.forName('sObject'));
            }

            Map<String, Object> recordMap = Trigger.newMap.get(recordId).getPopulatedFieldsAsMap();
            Boolean addToList = false;
            for(String field : recordMap.keySet()) {
                if(fieldMap.containsKey(field)) {
                    String wdcField = fieldMap.get(field);
                    if(fieldMap.containsKey(field) && wdcField != 'Id') {
                        if(field == 'CurrentWellnessStatus') {
                            Map<String, String> statusMap = new Map<String, String>();
                            for(String key : config.back2workStatusByWdcTestStatus.keySet()) {
                                statusMap.put(config.back2workStatusByWdcTestStatus.get(key), key);
                            }

                            String value = statusMap.get((String)recordMap.get(field));
                            if(wdcRecord.get(wdcField) != value) {
                                wdcRecord.put(wdcField, value);
                                addToList = true;
                            }
                        } else if(wdcRecord.get(wdcField) != recordMap.get(field)) {
                            wdcRecord.put(wdcField, recordMap.get(field));
                            addToList = true;
                        }
                    }
                }
            }

            if(wdcRecord.get('wdcEmployee__c') == null || recordId != recordMap.get('wdcEmployee__c')) {
                wdcRecord.put('wdcEmployee__c', recordId);
                addToList = true;
            }

            Id locId = Trigger.newMap.get(recordId).LocationId;
            if(String.isNotEmpty(locId)) {
                Id flrId = floorIdByLocationId.get(locId);
                if(flrId != (Id)wdcRecord.get('Floor__c')) {
                    wdcRecord.put('Floor__c', flrId);
                    addToList = true;
                }
            }

            if(wdcRecord.Id == null || addToList) {
                if(wdcRecord.get('Status__c') == null) {
                    wdcRecord.put('Status__c', 'Unknown');
                }
                recordsToUpsert.add(wdcRecord);   
            }
        }

        upsert recordsToUpsert;
    } catch(Exception e) {
    }
}