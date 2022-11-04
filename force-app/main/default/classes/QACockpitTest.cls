@isTest
public class QACockpitTest {

    @isTest static void test_QACockpit() {

        QACockpit.QACockpitSetting qaCockpitSetting1 = QACockpit.instance.qacp_Force_Inside_Business_Hours_for_EST;
        QACockpit.QACockpitSetting qaCockpitSetting2 = QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_EST;
        QACockpit.QACockpitSetting qaCockpitSetting3 = QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_PST;
        QACockpit.QACockpitSetting qaCockpitSetting4 = QACockpit.instance.qacp_Force_Outside_of_Business_Hours_for_PST;
        QACockpit.QACockpitSetting qaCockpitSetting5 = QACockpit.instance.qacp_Lead_is_Always_Workable;
        QACockpit.QACockpitSetting qaCockpitSetting6 = QACockpit.instance.qacp_Application_User_Mode;
    }
}