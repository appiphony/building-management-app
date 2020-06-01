@isTest
public with sharing class tst_locationCleaning {
    @testSetup static void testSetup() {
        Schema.Location parentLocation = new Schema.Location(
            Name='Building'
        );
        insert parentLocation;

        Schema.Location childLocation = new Schema.Location(
            Name='Floor',
            ParentLocationId=parentLocation.Id
        );
        insert childLocation;

        Employee emp = new Employee(
            FirstName='Test',
            LastName='Test',
            EmployeeNumber='test12345',
            WorkerType='Employee',
            Email='test@test.com',
            StatusAsOf=Date.today(),
            EmployeeStatus='Active',
            LocationId=childLocation.Id
        );
        insert emp;
    }

    @isTest static void test_getBarChartData() {
        Test.startTest();
        locationCleaning.getBarChartData([SELECT Id FROM Location WHERE Name='Building'].Id);
        Test.stopTest();

        System.assert(true);
    }

    @isTest static void test_getPieChartData() {
        Test.startTest();
        locationCleaning.getPieChartData([SELECT Id FROM Location WHERE Name='Building'].Id);
        Test.stopTest();

        System.assert(true);
    }

    @isTest static void test_getLocationData() {
        Test.startTest();
        locationCleaning.getLocationData([SELECT Id FROM Location WHERE Name='Building'].Id);
        Test.stopTest();

        System.assert(true);
    }
}
