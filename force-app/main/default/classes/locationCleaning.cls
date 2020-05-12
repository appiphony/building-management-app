public with sharing class locationCleaning {
    public class response {
        public Boolean isSuccess;
        public Map<String, Object> results;
        public String errMsg;
        public String stack;
        public Integer lineNumber;

        public response() {
            this.isSuccess = true;
            this.results = new Map<String, Object>();
        }

        public void addError(String errMsg){
            this.errMsg = errMsg;
            this.isSuccess = false;
        }

        public void addError(Exception e){
            System.debug('******************* error msg ' + e.getMessage());
            System.debug('******************* error stack ' + e.getStackTraceString());

            this.stack = e.getStackTraceString();
            this.lineNumber = e.getLineNumber();
            this.errMsg = e.getMessage();
            this.isSuccess = false;
        }

        public void put(String key, Object val){
            results.put(key, val);
        }

        public String getJsonString() {
            return JSON.serialize(this);
        }
    }

    @AuraEnabled
    public static String getLocationData(String locationId) {
        response res = new response();
        try{
            String queryString = 'SELECT Id, Name, Business__c, Business__r.wdctest__Total_Employees__c FROM Location';

            if(String.isNotEmpty(locationId)) {
                //cast to id for safety
                Id recordId = (Id)locationId;
                queryString += ' WHERE Id = :recordId';
            }

            List<sObject> locations = Database.query(queryString);
        } catch(Exception e) {
            response.addError(e);
        }
        return response.getJsonString();
    }
}
