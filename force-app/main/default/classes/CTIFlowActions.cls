/**
 * Created by lironkeren on 29/05/2022.
 */

global class CTIFlowActions {

    webService static void setAgentOnlineOnAWS() {

        try {

            System.debug('setAgentOnlineOnAWS, User Information: ' + UserInfo.getName() + ', ' + UserInfo.getUserId());
            User current_user = [SELECT Id, Online_On_AWS__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            current_user.Online_On_AWS__c = true;
            update current_user;
        }
        catch (Exception ex) {

            System.debug('Exception from setAgentOnlineOnAWS: ' + ex.getMessage());
        }
    }

    webService static void setAgentOfflineOnAWS() {

        try {

            System.debug('setAgentOfflineOnAWS, User Information: ' + UserInfo.getName() + ', ' + UserInfo.getUserId());
            User current_user = [SELECT Id, Online_On_AWS__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            current_user.Online_On_AWS__c = false;
            update current_user;
        }
        catch (Exception ex) {

            System.debug('Exception from setAgentOfflineOnAWS: ' + ex.getMessage());
        }
    }

    webService static void setAgentOnVoiceCall() {

        try {

            System.debug('setAgentOnVoiceCall, User Information: ' + UserInfo.getName() + ', ' + UserInfo.getUserId());
            User current_user = [SELECT Id, On_a_Call__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            current_user.On_a_Call__c = true;
            update current_user;
        }
        catch (Exception ex) {

            System.debug('Exception from setAgentOnVoiceCall: ' + ex.getMessage());
        }
    }

    webService static void setAgentNotOnVoiceCall() {

        try {

            System.debug('setAgentNotOnVoiceCall, User Information: ' + UserInfo.getName() + ', ' + UserInfo.getUserId());
            User current_user = [SELECT Id, On_a_Call__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            current_user.On_a_Call__c = false;
            update current_user;
        }
        catch (Exception ex) {

            System.debug('Exception from setAgentNotOnVoiceCall: ' + ex.getMessage());
        }
    }
}