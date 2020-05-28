trigger wdcEmployee on Employee (after insert, after update) {
    try{

    Map<String, wdctest__Employee__c> employeeByWdcEmployeeId = new Map<String, wdctest__Employee__c>();
    Map<String, String> floorIdByLocationId = new Map<String, String>();
    Set<Id> wdcEmpIds = Trigger.newMap.keySet();

    //get all related wdctest__Employee__c records that exist
    //go thru all trigger.new and check if record exists, use it else new
    //for status field, need to get value from config map
    //for floor field, need to get floors with locations that are on emps

    Set<String> empFields = new Set<String>();
    empFields.addAll(config.b2WEmployeeFieldByemployeeField.keySet());
    empFields.add('Id');
    empFields.add('wdctest__Floor__c');
    empFields.add('wdctest__Floor__r.wdctestext__wdcLocation__c');
    empFields.add('wdctestext__wdcEmployee__c');

    List<String> queryFields = new List<String>();
    queryFields.addAll(empFields);

    String query = 'SELECT ' + String.join(queryFields, ',') + 
                   ' FROM wdctest__Employee__c' + 
                   ' WHERE wdctestext__wdcEmployee__c =: wdcEmpIds';

    List<wdctest__Employee__c> emps = Database.query(query);

    for(wdctest__Employee__c emp : emps) {
        if(String.isNotEmpty(emp.wdctestext__wdcEmployee__c)) {
            employeeByWdcEmployeeId.put(emp.wdctestext__wdcEmployee__c, emp);
        }
    }

    for(Employee emp : Trigger.new) {
        floorIdByLocationId.put(emp.LocationId, '');
    }

    for(wdctest__Floor__c flr : [SELECT Id, wdctestext__wdcLocation__c FROM wdctest__Floor__c WHERE wdctestext__wdcLocation__c =: floorIdByLocationId.keySet()]) {
        floorIdByLocationId.put(flr.wdctestext__wdcLocation__c, flr.Id);
    }


    Map<String, String> fieldMap = new Map<String, String>();
    for(String key : config.b2WEmployeeFieldByemployeeField.keySet()) {
        fieldMap.put(config.b2WEmployeeFieldByemployeeField.get(key), key);
    }

    String objType = 'wdctest__Employee__c';

    List<sObject> recordsToUpsert = (List<sObject>)Type.forName('List<' + objType + '>').newInstance();
    for(String recordId : Trigger.newMap.keySet()) {
        sObject wdcRecord = (sObject)Type.forName(objType).newInstance();

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

        if(wdcRecord.get('wdctestext__wdcEmployee__c') == null || recordId != recordMap.get('wdctestext__wdcEmployee__c')) {
            wdcRecord.put('wdctestext__wdcEmployee__c', recordId);
            addToList = true;
        }

        Id locId = Trigger.newMap.get(recordId).LocationId;
        if(String.isNotEmpty(locId)) {
            Id flrId = floorIdByLocationId.get(locId);
            if(flrId != (Id)wdcRecord.get('wdctest__Floor__c')) {
                wdcRecord.put('wdctest__Floor__c', flrId);
                addToList = true;
            }
        }

        if(wdcRecord.Id == null || addToList) {
            System.debug('******** ADDED **********');
            if(wdcRecord.get('wdctest__Status__c') == null) {
                wdcRecord.put('wdctest__Status__c', 'Unknown');
            }
            recordsToUpsert.add(wdcRecord);   
        }
    }
    System.debug('***** wdcEmployee recordsToUpsert: ' + recordsToUpsert);
    upsert recordsToUpsert;
    } catch(Exception e) {
        System.debug('*************** message: ' + e.getMessage());
        System.debug('*************** stack: ' + e.getStackTraceString());
    }
}