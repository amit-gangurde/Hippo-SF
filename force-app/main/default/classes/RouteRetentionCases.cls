public with sharing class RouteRetentionCases {

    public static void route() {

        try {

            String retention_queue_dev_name = Utils.getHippoSettings('Retention Cases Queue');
            String retentionCasesQueueId = Utils.getQueueId(retention_queue_dev_name);

            User currentUser = [Select Id, Name, TimeZoneSidKey from User where id =: UserInfo.getUserId()];

            if ( currentUser.TimeZoneSidKey.toLowerCase().equals('america/new_york') ) {

                String est_pending_queue_dev_name = Utils.getHippoSettings('Pending Cases EST Queue');
                String estPendingCasesQueueId = Utils.getQueueId(est_pending_queue_dev_name);

                List<Case> est_pendingCases = [Select Id, OwnerId from Case Where  OwnerId = :estPendingCasesQueueId Order By CreatedDate ASC Limit 10000];
                for (Case myCase : est_pendingCases ) {

                    myCase.OwnerId = retentionCasesQueueId;
                }
                update est_pendingCases;
            }
            else if ( currentUser.TimeZoneSidKey.toLowerCase().equals('america/los_angeles') ) {

                String pst_pending_queue_dev_name = Utils.getHippoSettings('Pending Cases PST Queue');
                String pstPendingCasesQueueId = Utils.getQueueId(pst_pending_queue_dev_name);

                List<Case> pst_pendingCases = [Select Id, OwnerId from Case Where  OwnerId = :pstPendingCasesQueueId Order By CreatedDate ASC Limit 10000];
                for (Case myCase : pst_pendingCases ) {

                    myCase.OwnerId = retentionCasesQueueId;
                }
                update pst_pendingCases;
            }
        }
        catch(Exception ex) {

            System.debug('Exception from RouteRetentionCases execution: ' + ex.getMessage());
        }
    }
}