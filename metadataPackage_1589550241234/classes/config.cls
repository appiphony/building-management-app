public with sharing class config {
    //map our employee status to b2w employee status
    public static Map<String, String> back2workStatusByWdcTestStatus = new Map<String, String> {
        'Remote' => 'Remote Work Only',
        'Available' => 'Available to Work',
        'Unavailable' => 'Unavailable',
        'Unknown' => 'Unknown'
    };

    //
    public static Map<String, String> locationFieldByBuildingField = new Map<String, String> {
        'wdcBuilding__c' => 'Id',
        'Name' => 'Name',
        'wdctest__Location__Latitude__s' => 'Latitude',
        'wdctest__Location__Longitude__s' => 'Longitude'
    };

    public static Map<String, String> locationFieldByFloorField = new Map<String, String> {
        'wdcFloor__c' => 'Id',
        'Name' => 'Name',
        'wdctest__Level__c' => 'LocationLevel',
        'wdctest__Cleaning_Frequency_Days__c' => 'wdcext__Cleaning_Frequency_Days__c',
        'wdctest__Building__c' => 'ParentLocationId'
    };

    public static Map<String, String> employeeFieldByB2WEmployeeField = new Map<String, String> {
        'wdcEmployee__c' => 'Id',
        'wdctest__First_Name__c' => 'back2work__FirstName__c',
        'wdctest__Last_Name__c' => 'back2work__LastName__c',
        'wdctest__Status__c' => 'back2work__WellnessStatus__c',
        'wdctest__Floor__c' => 'back2work__Location__c'
    };
}
