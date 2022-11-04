global class EmailToLeadHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        Lead objLead = new lead();
        
        system.debug('I am in Email Service');

        String strName = this.parseEmailContent(email.plainTextBody, 'Name: ');
        String strPhoneNbr = this.parseEmailContent(email.plainTextBody, 'Phone Number: ');  
        String strEmail = this.parseEmailContent(email.plainTextBody, 'Email: ');
        String strStreet = this.parseEmailContent(email.plainTextBody, 'Street: ');
        String strCity = this.parseEmailContent(email.plainTextBody, 'City: ');
        String strState = this.parseEmailContent(email.plainTextBody, 'State: ');
        String strZip = this.parseEmailContent(email.plainTextBody, 'Zip: ');

        if ( String.isNotBlank(strEmail) && EmailToLeadHandler.validateEmail(strEmail) ) {

            objLead.Email = strEmail;
        }

        if ( String.isNotBlank(strPhoneNbr) ) {

            objLead.Phone = strPhoneNbr;
        }

        if ( String.isNotBlank(strStreet) ) {

            objLead.Street = strStreet;
        }

        if ( String.isNotBlank(strCity) ) {

            objLead.City = strCity;
        }

        if ( String.isNotBlank(strState) ) {

            objLead.State = strState;
        }

        if ( String.isNotBlank(strZip) ) {

            objLead.PostalCode = strZip;
        }

        // Below Logic is for Splitting the name into First name and Last Name
        //string fullName = 'Adrian Rules z';
        string[] names = strName.Split(' ');
        system.debug('names==> '+names);
        string strFName = '';
        string strLName = '';
        if ( names.size() == 0 ) {
        // No Name
        }
        else if ( names.size() == 1 ) {

            strLName = names[0];
        }
        else if ( names.size() == 2 ) {

            strFName = names[0];
            strLName = names[1];
        }
        else if ( names.size() == 3 ) {

            strFName = names[0]+' '+names[1];
            strLName = names[2];
        }
        else if ( names.size() == 4 ) {

            strFName = names[0]+' '+names[1]+' '+names[3];
            strLName = names[4];
        }

        if ( !String.isBlank(strLName) ) {

            objLead.FirstName = strFName;
            objLead.LastName = strLName;
        }

        system.debug('strFName==> ' + strFName);
        system.debug('strLName==> ' + strLName);
        system.debug('strPhoneNbr==> ' + strPhoneNbr);
        system.debug('strEmail==> ' + strEmail);
        system.debug('strFName==> ' + strFName);
        system.debug('strStreet==> ' + strStreet);
        system.debug('strCity==> ' + strCity);
        system.debug('strState==> ' + strState);
        system.debug('strZip==> ' + strZip);

        Id EmailLeadsRTId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(System.Label.EmailToLeadHandler_AmeriSave_Lead).getRecordTypeId();

        objLead.RecordTypeId = EmailLeadsRTId;
        objLead.Lead_Source__c = 'AmeriSave Email';
        objLead.UTM_Source__c  = 'RequestCall';

        for (Group groupRec : [Select Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'AmeriSave_Leads'] ) {
            system.debug('Setting Lead Owner ==> ' + groupRec);
            objLead.OwnerId = groupRec.id;
        }

        String orgName = Utils.getHippoSettings('Email to Lead Organization');
        orgName = String.isBlank(orgName) ? 'AmeriSave' : orgName;
        List<Account> org = [Select Id, Name FROM Account WHERE Name =: orgName LIMIT 1];
        system.debug('org ==> ' + org);
        if ( !org.isEmpty() ) {

            objLead.Organization__c = org[0].Id;
        }

        try {

            system.debug('Before insert objLead ==> ' + objLead);
            insert objLead;
            system.debug('After insert objLead ==> ' + objLead);
        }
        catch(Exception Ex) {

            System.debug('Exception in EmailToLeadHandler '+Ex);
        }

        result.success = true;

        return result;
    }
    
    public static Boolean validateEmail(String email) {

        Boolean res = true;
            
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: http://www.regular-expressions.info/email.html
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);
    
        if ( !MyMatcher.matches() )
            res = false;

        return res; 
    }

    global String parseEmailContent(String emailText, String dataLabal) {

        emailText += '\n';
        String dataValue = '';
        Integer  labalIdx = emailText.indexOf(dataLabal);

        if ( labalIdx >= 0 ) {

            dataValue = emailText.substring(labalIdx + dataLabal.length(), emailText.indexOf('\n', labalIdx + dataLabal.length()));
            if ( String.isNotBlank(dataValue) ) {

                dataValue = dataValue.trim();
            }
        }

        return dataValue;
      }
     
}