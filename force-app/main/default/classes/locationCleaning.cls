public with sharing class locationCleaning {

    @AuraEnabled
    public static String getLocationData(String locationId) {
        String locationQuery = 'SELECT Id, Building__c ' + 
                               'FROM Location';

        if(String.isNotEmpty(locationId)) {
            //cast to id for safety
            Id recordId = (Id)locationId;
            queryString += ' WHERE Id = :recordId';
        } else{
            queryString += ' LIMIT 20';
        }


        List<sObject> locations = Database.query(queryString);

        //need list of business ids to query floors to see what needs cleaning
        List<String> bldgIds = new List<String>();
        for(sObject loc : locations) {
            if(loc.get('Building__c') != null) {
                bldgIds.add((String)loc.get('Building__c'));
            }
        }

        String buildingQuery = 'SELECT Id, Name ,' +
                               '(' + 
                                   'SELECT Id, Name, wdctest__Cleaning_Frequency_Days__c, wdctest__Cleaning_Overdue__c, ' + 
                                       'wdctest__Days_Since_Last_Cleaning__c, wdctest__Last_Cleaning_Time__c, wdctest__Total_Employees__c ' + 
                                   'FROM wdctest__Floors__r' + 
                               ')' + 
                               'FROM wdctest__Building__c ' + 
                               'WHERE Id =: bldgIds';

        List<sObject> buildings = Database.query(buildingQuery);

        List<Map<String, Object>> buildingData = new List<Map<String, Object>>();
        for(sObject bldg : buildings) {
            Map<String, Object> bldgMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(bldg));

            Boolean needsCleaning = false;
            for(wdctest__Floor__c flr : bldg.wdctest__Floors__r) {
                if(flr.wdctest__Cleaning_Overdue__c) {
                    needsCleaning = true;
                }
            }
            bldgMap.put('needsCleaning', needsCleaning);

            buildingData.add(bldgMap);
        }

        return JSON.serialize(buildingData);
    }
}
