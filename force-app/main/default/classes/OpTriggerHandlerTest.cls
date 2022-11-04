@isTest
public class OpTriggerHandlerTest {
    @testsetup
    public static void SetupData(){        
        UnitTestHelper.prepareDevEnvCustomSettings();
        Account objAcc = UnitTestHelper.prepareAccount();        
        op__c objectop = new op__c ();
        objectop.Status__c= 'New';
        objectop.Account__c = objAcc.id;
        objectop.Type__c = 'Auto';
        objectop.Op_Origin__c = 'Support';
        insert objectop;        
    }
    @isTest
    static public void OpStatusToWorking() {
        op__c objectop = [Select id from op__c LIMIT 1];
        objectop.Status__c = 'Working';
        update objectop;
    }
    @isTest
    static public void OpStatusToQuoted() {
        op__c objectop = [Select id from op__c LIMIT 1];
        objectop.Status__c = 'Quoted';
        update objectop;
    }
}