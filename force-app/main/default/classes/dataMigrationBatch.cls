global class dataMigrationBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //query for all sublocations
        String query = 'SELECT Id, wdctest__Building__c, wdctest__Building__r.Name, wdctest__Building__r.wdctest__Location__c,' + 
                              'wdctest__Cleaning_Frequency_Days__c, wdctest__Cleaning_Overdue__c, wdctest__Days_Since_Last_Cleaning__c,' + 
                              'wdctest__Last_Cleaning_Time__c, wdctest__Total_Employees__c, wdctest__Level__c,' + 
                                  '(' + 
                                    'SELECT Id, wdctest__First_Name__c, wdctest__Last_Name__c, wdctest__Status__c ' + 
                                    'FROM wdctest__Employees__r' + 
                                  '),' + 
                                  '(' + 
                                    'SELECT Id, wdctest__Cleaning_Time__c, wdcext__Location__c ' +
                                    'FROM wdctest__Cleanings__r' + 
                                  ') ' + 
                       'FROM wdctest__Floor__c';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        //process sublocation and related records
        dataMigrationBatchHelper.processRecords(scope);
    }

    global void finish(Database.BatchableContext BC) {
        //nothing
    }
}
