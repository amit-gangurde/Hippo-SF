@IsTest
public class LeadsCockpitControllerTest {

    @IsTest
    static void testIsUserNotAllowed() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        User running_user = UnitTestHelper.createuser();

        test.startTest();

        System.runAs(running_user) {

            Boolean res = LeadsCockpitController.isUserAllowed();
            System.assertEquals(false, res);
        }

        test.stopTest();
    }

    @IsTest
    static void testIsUserAllowed() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        User running_user = UnitTestHelper.createuser();

        test.startTest();

        System.runAs(running_user) {

            String required_permission_set = Utils.getHippoSettings('Leads Cockpit Permission Set API Name');

            PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name =: required_permission_set];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = running_user.Id, PermissionSetId = ps.Id);
            insert psa;

            Boolean res = LeadsCockpitController.isUserAllowed();
            System.assertEquals(true, res);
        }

        test.stopTest();
    }
}