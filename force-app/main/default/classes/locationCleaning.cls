public with sharing class locationCleaning {
    @AuraEnabled
    public static String getBarChartData(String locationId) {
        try{
            String buildingQuery = 'SELECT Id, Name,' +
                                   '(' + 
                                       'SELECT Id, Cleaning_Overdue__c, Total_Employees__c ' + 
                                       'FROM Floors__r ORDER BY Name ASC' + 
                                   ')' + 
                                   'FROM Building__c';

            if(String.isNotEmpty(locationId)) {
                //cast to id for safety
                Id recordId = (Id)locationId;
                buildingQuery += ' WHERE wdcLocation__c = :recordId';
            } else{
                buildingQuery += ' WHERE Total_Employees__c != 0 ORDER BY Name ASC LIMIT 10';
            }

            List<String> buildingLabels = new List<String>();
            List<Integer> atRiskEmployees = new List<Integer>();
            List<Integer> safeEmployees = new List<Integer>();

            for(sObject bldg : Database.query(buildingQuery)) {
                Map<String, Object> bldgMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(bldg));

                buildingLabels.add((String)bldgMap.get('Name'));

                Integer atRisk = 0;
                Integer safe = 0;
                Map<String, Object> floorsMap = (Map<String, Object>)bldgMap.get('Floors__r');
                List<Object> floors = (List<Object>)floorsMap.get('records');

                for(Object flr : floors) {
                    Map<String, Object> floorMap = (Map<String, Object>)flr;
                    if((Boolean)floorMap.get('Cleaning_Overdue__c')) {
                        atRisk += Integer.valueOf(floorMap.get('Total_Employees__c'));
                    } else{
                        safe += Integer.valueOf(floorMap.get('Total_Employees__c'));
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
        } catch(Exception e) {
            String message = e.getMessage() + '\n' + e.getLineNumber() + '\n' + e.getStackTraceString();
            insert new Error__c(
                Message__c=message
            );
            return message;
        }
    }

    @AuraEnabled
    public static String getPieChartData(String locationId) {
        try{
            String query = 'SELECT COUNT(Id) floors, Cleaning_Overdue__c' + 
                                   ' FROM Floor__c';

            if(String.isNotEmpty(locationId)) {
                //cast to id for safety
                Id recordId = (Id)locationId;
                query += ' WHERE Building__r.wdcLocation__c = :recordId';
            }

            query += ' GROUP BY Cleaning_Overdue__c';

            Map<String, Integer> numFloorsByStatus = new Map<String, Integer> {
                'clean' => 0,
                'dirty' => 0
            };

            for(AggregateResult ar : Database.query(query)) {
                if((Boolean)ar.get('Cleaning_Overdue__c')) {
                    numFloorsByStatus.put('dirty', (Integer)ar.get('floors'));
                } else{
                    numFloorsByStatus.put('clean', (Integer)ar.get('floors'));
                }
            }

            return JSON.serialize(numFloorsByStatus);
        } catch(Exception e) {
            String message = e.getMessage() + '\n' + e.getLineNumber() + '\n' + e.getStackTraceString();
            insert new Error__c(
                Message__c=message
            );
            return message;
        }
    }

    @AuraEnabled
    public static String getLocationData(String locationId) {
        try{
            //get buildings based on location id
            String buildingQuery = 'SELECT Id, Name , Total_Employees__c, wdcLocation__c, ' +
                                   '(' + 
                                       'SELECT Id, Name, Cleaning_Frequency_Days__c, Cleaning_Overdue__c, ' + 
                                           'Days_Since_Last_Cleaning__c, Last_Cleaning_Time__c, Total_Employees__c ' + 
                                       'FROM Floors__r ORDER BY Name ASC' + 
                                   ')' + 
                                   'FROM Building__c';

            if(String.isNotEmpty(locationId)) {
                //cast to id for safety
                Id recordId = (Id)locationId;
                buildingQuery += ' WHERE wdcLocation__c = :recordId';
            } else{
                buildingQuery += ' WHERE Total_Employees__c != 0 ORDER BY Name ASC LIMIT 10';
            }

            List<Map<String, Object>> buildingData = new List<Map<String, Object>>();
            for(sObject bldg : Database.query(buildingQuery)) {
                Map<String, Object> bldgMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(bldg));

                if(bldgMap.containsKey('Floors__r')) {
                    Map<String, Object> floorsMap = (Map<String, Object>)bldgMap.get('Floors__r');
                    List<Object> floors = (List<Object>)floorsMap.get('records');

                    //formatting data for frontend
                    Boolean needsCleaning = false;
                    for(Object flr : floors) {
                        Map<String, Object> flrMap = (Map<String, Object>)flr;

                        if((Boolean)flrMap.get('Cleaning_Overdue__c')) {
                            needsCleaning = true;
                        }

                        Decimal cleaningFreq = (Decimal)flrMap.get('Cleaning_Frequency_Days__c');
                        Decimal daysSinceLastClean = (Decimal)flrMap.get('Days_Since_Last_Cleaning__c');

                        Decimal nextCleaning = (cleaningFreq - daysSinceLastClean) * 24; //convert from days to hrs
                        Decimal freqHrs = cleaningFreq * 24; //convert from days to hrs

                        Decimal barWidthPercentage = (nextCleaning/freqHrs) * 100;
                        String barWidthStyle = 'width:' + barWidthPercentage.setScale(2, RoundingMode.HALF_EVEN) + '%;';

                        flrMap.put('nextCleaning', nextCleaning.setScale(2, RoundingMode.HALF_EVEN));
                        flrMap.put('freqHrs', freqHrs.setScale(2, RoundingMode.HALF_EVEN));
                        flrMap.put('barWidth', barWidthStyle);

                        String lastCleaningStr = (String)flrMap.get('Last_Cleaning_Time__c');
                        DateTime lastCleaning = DateTime.valueOf(lastCleaningStr.replace('T', ' '));
                        flrMap.put('lastCleaning', lastCleaning.getTime());
                    }

                    bldgMap.put('needsCleaning', needsCleaning);
                }

                buildingData.add(bldgMap);
            }

            return JSON.serialize(buildingData);

            } catch(Exception e) {
                String message = e.getMessage() + '\n' + e.getLineNumber() + '\n' + e.getStackTraceString();
                insert new Error__c(
                    Message__c=message
                );
                return message;
            }
    }

    @AuraEnabled
    public static String getListViews() {
        Map<String, String> listViewIdByObjNameAndDevName = new Map<String, String>();
        for(ListView lv : [SELECT Id, SobjectType, DeveloperName 
                           FROM ListView 
                           WHERE SobjectType = 'Location' 
                              OR SobjectType = 'Building__c' 
                              OR SobjectType = 'Floor__c' 
                              OR SobjectType = 'Employee__c']) {
            listViewIdByObjNameAndDevName.put(lv.SobjectType + '|' + lv.DeveloperName, lv.Id);
        }
        return JSON.serialize(listViewIdByObjNameAndDevName);
    }

    @AuraEnabled
    public static String getEmployeeCounts(String sublocationId) {
        //cast to Id for safety
        Id floorId = (Id)sublocationId;

        Map<String, Object> employeeCounts = new Map<String, Object>();

        String queryString = 'SELECT count(Id) employees, Status__c status' + 
                             ' FROM Employee__c ' + 
                             ' WHERE Floor__c =: floorId' + 
                             ' GROUP BY Status__c';

        for(AggregateResult res : Database.query(queryString)) {
            employeeCounts.put((String)res.get('status'), res.get('employees'));
        }

        return JSON.serialize(employeeCounts);

    }

    @AuraEnabled
    public static void resetCleaningData() {
        //delete all previous cleanings
        delete Database.query('SELECT Id FROM Cleaning__c');

        //create new cleanings for floors
        List<sObject> cleanings = (List<sObject>)Type.forName('List<Cleaning__c>').newInstance();
        for(sObject flr : Database.query('SELECT Id FROM Floor__c')) {
            Integer minutes = Integer.valueOf(Math.random() * 60 * -24);
            DateTime cleanTime = DateTime.now().addMinutes(minutes);

            sObject cleaning = (sObject)Type.forName('Cleaning__c').newInstance();
            cleaning.put('Floor__c', (String)flr.get('Id'));
            cleaning.put('Cleaning_Time__c', cleanTime);
            cleanings.add(cleaning);
        }
        insert cleanings;
    }
}
