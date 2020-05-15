global class postInstall implements InstallHandler {

    global void onInstall(System.InstallContext context) {
        //sync data if package has not been installed before
        if(context.previousVersion() == null) {
            Database.executebatch(new dataMigrationBatch(), 1);
        }
    }
}
