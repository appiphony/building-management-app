public with sharing class locationCleaning {

    @AuraEnabled
    public static String getLocationData(String locationId) {
        String queryString = 'SELECT Id, Name, Building__c, Building__r.wdctest__Total_Employees__c FROM Location';

        if(String.isNotEmpty(locationId)) {
            //cast to id for safety
            Id recordId = (Id)locationId;
            queryString += ' WHERE Id = :recordId';
        }

        queryString += ' LIMIT 20';

        List<sObject> locations = Database.query(queryString);

        //need list of business ids so i can query floors to see what needs cleaning
        List<String> bldgIds = new List<String>();
        for(sObject loc : locations) {
            if(loc.get('Building__c') != null) {
                bldgIds.add((String)loc.get('Building__c'));
            }
        }

        Set<String> bldgsNeedingCleaning = new Set<String>();
        for(wdctest__Floor__c floorNeedingCleaning : [SELECT Id, wdctest__Building__c
                                                         FROM wdctest__Floor__c
                                                         WHERE wdctest__Building__c =: bldgIds]) {
            bldgsNeedingCleaning.add(floorNeedingCleaning.wdctest__Building__c);
        }

        List<Map<String, Object>> locationData = new List<Map<String, Object>>();
        for(sObject loc : locations) {
            Map<String, Object> locMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(loc));
            locMap.put('cleaningOverdue', bldgsNeedingCleaning.contains((String)loc.get('Id')));
            locationData.add(locMap);
        }

        return JSON.serialize(locationData);
    }
}
