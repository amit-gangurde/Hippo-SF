@IsTest
private class EmailToLeadHandlerTest {

    @IsTest
    static void testInboundEmail() {

        UnitTestHelper.prepareDevEnvCustomSettings();

        Account acc_AmeriSave = UnitTestHelper.prepareAccount(true,'AmeriSave');

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        email.subject = 'New AIA Lead';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = 'Home buyer lead:\n' +
                'Name: Rama Nagal\n' +
                'Street:  101 Willow Oak Dr\n' +
                'City: BAXTER\n' +
                'State: TX\n' +
                'Zip: 38544\n' +
                'Phone Number: 2562562560\n' +
                'Email: leadtest@gmail.cot';

        test.startTest();

        EmailToLeadHandler testInbound = new EmailToLeadHandler();
        testInbound.handleInboundEmail(email, env);

        test.stopTest();
    }
}