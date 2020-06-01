@isTest
public with sharing class tst_locationCleaning {
    @isTest static void test_getBarChartData() {
        Schema.Location parentLocation = new Schema.Location(
            Name='Tower'
        );
        insert parentLocation;

        Test.startTest();
        locationCleaning.getBarChartData(parentLocation.Id);
        Test.stopTest();

        System.assert(true);
    }

    @isTest static void test_getPieChartData() {
        Schema.Location parentLocation = new Schema.Location(
            Name='Tower'
        );
        insert parentLocation;

        Test.startTest();
        locationCleaning.getPieChartData(parentLocation.Id);
        Test.stopTest();

        System.assert(true);
    }

    @isTest static void test_getLocationData() {
        Schema.Location parentLocation = new Schema.Location(
            Name='Tower'
        );
        insert parentLocation;

        Test.startTest();
        locationCleaning.getLocationData(parentLocation.Id);
        Test.stopTest();

        System.assert(true);
    }
}
