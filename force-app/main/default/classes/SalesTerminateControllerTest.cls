@isTest
public class SalesTerminateControllerTest {
    @TestSetup static void testData(){
        Account accOBJ = new Account();
        accOBJ.Name = 'Test';
        accOBJ.Sync_to_AgentSync__c = 'Yes';
        accOBJ.NPN__c = '12345';
        insert accOBJ;

        Contact con = new Contact();
        con.LastName = 'Test';
        con.AccountId = accOBJ.ID;
        con.Sync_to_AgentSync__c = 'Yes';
        con.PodRole__c = 'Customer Service';
        insert con;
    }
    @isTest static void testSalesTerminate(){
        Test.startTest();
        Id conId = [SELECT ID FROM Contact LIMIT 1].ID;
        SalesTerminateController.checkAlreadyTerminated(conId);
        SalesTerminateController.terminateTheAgent(conId);
        Test.stopTest();
        
    }
}