public with sharing class QACockpit {

    public static QACockpit instance = new QACockpit();

    public class QACockpitSetting {

        public QACockpitSetting(String qa_settings, Boolean enabled, String metadata) {

            this.qa_settings = qa_settings;
            this.enabled = enabled;
            this.metadata = metadata;
        }

        @AuraEnabled public String qa_settings {get; set;}
        @AuraEnabled public Boolean enabled {get; set;}
        @AuraEnabled public String metadata {get; set;}
    }

    @AuraEnabled public QACockpitSetting qacp_Force_Inside_Business_Hours_for_EST { get; set; }
    @AuraEnabled public QACockpitSetting qacp_Force_Outside_of_Business_Hours_for_EST { get; set; }
    @AuraEnabled public QACockpitSetting qacp_Force_Inside_Business_Hours_for_PST { get; set; }
    @AuraEnabled public QACockpitSetting qacp_Force_Outside_of_Business_Hours_for_PST { get; set; }
    @AuraEnabled public QACockpitSetting qacp_Lead_is_Always_Workable { get; set; }
    @AuraEnabled public QACockpitSetting qacp_Application_User_Mode { get; set; }

    public QACockpit() {

        qacp_Force_Inside_Business_Hours_for_EST = QACockpit.isQASettingEnabled('Force_Inside_Business_Hours_for_EST');
        qacp_Force_Outside_of_Business_Hours_for_EST = QACockpit.isQASettingEnabled('Force_Outside_of_Business_Hours_for_EST');
        qacp_Force_Inside_Business_Hours_for_PST = QACockpit.isQASettingEnabled('Force_Inside_Business_Hours_for_PST');
        qacp_Force_Outside_of_Business_Hours_for_PST = QACockpit.isQASettingEnabled('Force_Outside_of_Business_Hours_for_PST');
        qacp_Lead_is_Always_Workable = QACockpit.isQASettingEnabled('Lead_is_Always_Workable');
        qacp_Application_User_Mode = QACockpit.isQASettingEnabled('Application_User_Mode');
    }

    public static QACockpitSetting isQASettingEnabled(String qa_settings) {

        QACockpitSetting qaCockpitSetting = new QACockpitSetting(qa_settings, false, '');

        QA_Cockpit__mdt[] qa_cockpit = [SELECT MasterLabel, QualifiedApiName, Enabled__c, Metadata__c FROM QA_Cockpit__mdt Where QualifiedApiName =: qa_settings];

        if ( qa_cockpit.size() == 1 ) {

            qaCockpitSetting.enabled  = qa_cockpit[0].Enabled__c;
            qaCockpitSetting.metadata = qa_cockpit[0].Metadata__c;
        }

        return qaCockpitSetting;
    }
}