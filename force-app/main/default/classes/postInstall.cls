global without sharing class postInstall implements InstallHandler {

    global void onInstall(System.InstallContext context) {
        dataMigrationBatchHelper.transferData();
    }
}
