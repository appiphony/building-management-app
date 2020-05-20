public with sharing class locationCleaning {
    @AuraEnabled
    public static String getBarChartData(String locationId) {
        String buildingQuery = 'SELECT Id, Name,' +
                               '(' + 
                                   'SELECT Id, wdctest__Cleaning_Overdue__c, wdctest__Total_Employees__c ' + 
                                   'FROM wdctest__Floors__r ORDER BY Name ASC' + 
                               ')' + 
                               'FROM wdctest__Building__c';

        if(String.isNotEmpty(locationId)) {
            //cast to id for safety
            Id recordId = (Id)locationId;
            buildingQuery += ' WHERE wdcLocation__c = :recordId';
        } else{
            buildingQuery += ' ORDER BY Name ASC LIMIT 10';
        }

        List<String> buildingLabels = new List<String>();
        List<Integer> atRiskEmployees = new List<Integer>();
        List<Integer> safeEmployees = new List<Integer>();

        for(wdctest__Building__c bldg : Database.query(buildingQuery)) {
            buildingLabels.add(bldg.Name);
            Integer atRisk = 0;
            Integer safe = 0;
            for(wdctest__Floor__c flr : bldg.wdctest__Floors__r) {
                if(flr.wdctest__Cleaning_Overdue__c) {
                    atRisk += Integer.valueOf(flr.wdctest__Total_Employees__c);
                } else{
                    safe += Integer.valueOf(flr.wdctest__Total_Employees__c);
                }
            }
            atRiskEmployees.add(atRisk);
            safeEmployees.add(safe);
        }
        Map<String, Object> data = new Map<String, Object>{
            'labels' => buildingLabels,
            'atRiskData' => atRiskEmployees,
            'safeData' => safeEmployees
        };

        return JSON.serialize(data);
    }

    @AuraEnabled
    public static String getPieChartData(String locationId) {
        String query = 'SELECT COUNT(Id) floors, wdctest__Cleaning_Overdue__c' + 
                               ' FROM wdctest__Floor__c';

        if(String.isNotEmpty(locationId)) {
            //cast to id for safety
            Id recordId = (Id)locationId;
            query += ' WHERE wdctest__Building__r.wdcLocation__c = :recordId';
        }

        query += ' GROUP BY wdctest__Cleaning_Overdue__c';

        Map<String, Integer> numFloorsByStatus = new Map<String, Integer> {
            'clean' => 0,
            'dirty' => 0
        };

        for(AggregateResult ar : Database.query(query)) {
            if((Boolean)ar.get('wdctest__Cleaning_Overdue__c')) {
                numFloorsByStatus.put('dirty', (Integer)ar.get('floors'));
            } else{
                numFloorsByStatus.put('clean', (Integer)ar.get('floors'));
            }
        }

        return JSON.serialize(numFloorsByStatus);
    }

    @AuraEnabled
    public static String getLocationData(String locationId) {
        //get buildings based on location id
        String buildingQuery = 'SELECT Id, Name , wdctest__Total_Employees__c, wdcLocation__c, ' +
                               '(' + 
                                   'SELECT Id, Name, wdctest__Cleaning_Frequency_Days__c, wdctest__Cleaning_Overdue__c, ' + 
                                       'wdctest__Days_Since_Last_Cleaning__c, wdctest__Last_Cleaning_Time__c, wdctest__Total_Employees__c ' + 
                                   'FROM wdctest__Floors__r ORDER BY wdctest__Level__c ASC, Name ASC' + 
                               ')' + 
                               'FROM wdctest__Building__c';

        if(String.isNotEmpty(locationId)) {
            //cast to id for safety
            Id recordId = (Id)locationId;
            buildingQuery += ' WHERE wdcLocation__c = :recordId';
        } else{
            buildingQuery += ' ORDER BY Name ASC LIMIT 10';
        }

        List<Map<String, Object>> buildingData = new List<Map<String, Object>>();
        for(sObject bldg : Database.query(buildingQuery)) {
            Map<String, Object> bldgMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(bldg));

            if(bldgMap.containsKey('wdctest__Floors__r')) {
                Map<String, Object> floorsMap = (Map<String, Object>)bldgMap.get('wdctest__Floors__r');
                List<Object> floors = (List<Object>)floorsMap.get('records');

                //formatting data for frontend
                Boolean needsCleaning = false;
                for(Object flr : floors) {
                    Map<String, Object> flrMap = (Map<String, Object>)flr;

                    if((Boolean)flrMap.get('wdctest__Cleaning_Overdue__c')) {
                        needsCleaning = true;
                    }

                    Decimal cleaningFreq = (Decimal)flrMap.get('wdctest__Cleaning_Frequency_Days__c');
                    Decimal daysSinceLastClean = (Decimal)flrMap.get('wdctest__Days_Since_Last_Cleaning__c');

                    Decimal nextCleaning = (cleaningFreq - daysSinceLastClean) * 24; //convert from days to hrs
                    Decimal freqHrs = cleaningFreq * 24; //convert from days to hrs

                    Decimal barWidthPercentage = (nextCleaning/freqHrs) * 100;
                    String barWidthStyle = 'width:' + barWidthPercentage.setScale(2, RoundingMode.HALF_EVEN) + '%;';

                    flrMap.put('nextCleaning', nextCleaning.setScale(2, RoundingMode.HALF_EVEN));
                    flrMap.put('freqHrs', freqHrs.setScale(2, RoundingMode.HALF_EVEN));
                    flrMap.put('barWidth', barWidthStyle);

                    String lastCleaningStr = (String)flrMap.get('wdctest__Last_Cleaning_Time__c');
                    DateTime lastCleaning = DateTime.valueOf(lastCleaningStr.replace('T', ' '));
                    flrMap.put('lastCleaning', lastCleaning.getTime());
                }

                bldgMap.put('needsCleaning', needsCleaning);
            }

            buildingData.add(bldgMap);
        }

        return JSON.serialize(buildingData);
    }

    @AuraEnabled
    public static String getListViews() {
        Map<String, String> listViewIdByObjNameAndDevName = new Map<String, String>();
        for(ListView lv : [SELECT Id, SobjectType, DeveloperName 
                           FROM ListView 
                           WHERE SobjectType = 'Location' 
                              OR SobjectType = 'wdctest__Building__c' 
                              OR SobjectType = 'wdctest__Floor__c' 
                              OR SobjectType = 'wdctest__Employee__c']) {
            listViewIdByObjNameAndDevName.put(lv.SobjectType + '|' + lv.DeveloperName, lv.Id);
        }
        return JSON.serialize(listViewIdByObjNameAndDevName);
    }

    @AuraEnabled
    public static String getEmployeeCounts(String sublocationId) {
        //cast to Id for safety
        Id floorId = (Id)sublocationId;

        Map<String, Object> employeeCounts = new Map<String, Object>();

        for(AggregateResult res : [SELECT count(Id) employees, wdctest__status__c status
                                   FROM wdctest__Employee__c 
                                   WHERE wdctest__Floor__c =: floorId
                                   GROUP BY wdctest__status__c]) {
            employeeCounts.put((String)res.get('status'), res.get('employees'));
        }

        return JSON.serialize(employeeCounts);

    }
}
