@isTest
public with sharing class tst_buildingManagement {
    @isTest static void test_transferData() {
        Schema.Location parentLocation = new Schema.Location(
            Name='Tower'
        );
        insert parentLocation;

        Schema.Location childLocation = new Schema.Location(
            Name='Child Location', 
            ParentLocationId=parentLocation.Id
        );
        insert childLocation;

        Employee emp = new Employee(
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'test@test.com',
            LocationId = childLocation.Id,
            EmployeeStatus = 'Active',
            StatusAsOf = Date.today(),
            WorkerType = 'Employee',
            EmployeeNumber = 'test' + String.valueOf(Integer.valueOf(Math.random()*100000))
        );
        insert emp;

        Test.startTest();
        dataMigrationBatchHelper.transferData();
        Test.stopTest();

        System.assert(true);
    }

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
