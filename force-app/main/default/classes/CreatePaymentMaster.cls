public class CreatePaymentMaster {
    public static PaymentAuth_Integration_System__c payAuthSetting;
    public static Id logId;
    @AuraEnabled
    public static String createPayment(Id recordID){
        String sessionId = null;
       
        try{
           if(claimCoverageApprovalValidate(recordId)){
            payAuthSetting =  PaymentAuth_Integration_System__c.getOrgDefaults();
            List<Claim_Payment__c> cPlist = new List<Claim_Payment__c>();
            Claim_Payment__c claimPayment = [SELECT Id,
                                             Payment_Amount_in_words__c,
                                             Payment_Method_Inc__c,
                                             Total_Payment__c,
                                             Request_Reason__c,
                                             Expedite__c,
                                             Certified__c,
                                             Print_Locally__c,
                                             CreatedById,
                                             CreatedBy.FirstName,
                                             CreatedBy.LastName,
                                             CreatedBy.Email,
                                             Claim__r.Claim_Adjuster__r.Email,
                                             Claim__r.Claim_Adjuster__r.FirstName,
                                             Claim__r.Claim_Adjuster__r.LastName,
                                             Claim__r.Claim_Adjuster__c,
                                             Claim__r.Claim_Adjuster__r.Claimatic_Integration_ID__c,
                                             Claim__r.Peril__c,
                                             Claim__r.Carrier__c,
                                             Claim__r.PolicyNumber.Name,
                                             Claim__r.Date_of_Loss__c,
                                             Claim__r.Name,
                                             Claim__r.ClaimType,
                                             Claim__r.PolicyNumber.Carrier__c,
                                             Claim__r.PolicyNumber.State__c,
                                             Claim__r.PolicyNumber.Street__c,
                                             Claim__r.PolicyNumber.Street2__c,
                                             Claim__r.PolicyNumber.Zip__c,
                                             Claim__r.PolicyNumber.City__c,
                                             Primary_Contact__c,
                                             Primary_Contact__r.First_Name__c,
                                             Primary_Contact__r.Last_Name__c,
                                             Primary_Contact__r.MobilePhone__c,
                                             Primary_Contact__r.OfficePhone__c,
                                             Primary_Contact__r.Email__c,
                                             Primary_Contact__r.Mail_To__c,
                                             Primary_Contact__r.Country__c,
                                             Primary_Contact__r.Zip_Code__c,
                                             Primary_Contact__r.State__c,
                                             Primary_Contact__r.Street__c,
                                             Primary_Contact__r.City__c,
                                             Primary_Contact__r.ParticipantContact.Email,
                                             Primary_Contact__r.ParticipantContact.MobilePhone,
                                             Primary_Contact__r.ParticipantContact.Id,
                                             Primary_Contact__r.ParticipantContact.FirstName,
                                             Primary_Contact__r.ParticipantContact.LastName,
                                             Secondary_Contact__c,
                                             Secondary_Contact__r.Name,
                                             Secondary_Contact__r.MobilePhone__c,
                                             Secondary_Contact__r.First_Name__c,
                                             Secondary_Contact__r.Last_Name__c,
                                             Secondary_Contact__r.OfficePhone__c,
                                             Secondary_Contact__r.Email__c,
                                             Secondary_Contact__r.ParticipantContact.Id,
                                             Secondary_Contact__r.ParticipantContact.FirstName,
                                             Secondary_Contact__r.ParticipantContact.LastName,
                                             Secondary_Contact__r.ParticipantContact.Email,
                                             Secondary_Contact__r.ParticipantContact.MobilePhone,
                                             Third_Contact__c,
                                             Third_Contact__r.First_Name__c,
                                             Third_Contact__r.Last_Name__c,
                                             Fourth_Contact__c,
                                             Fourth_Contact__r.First_Name__c,
                                             Fourth_Contact__r.Last_Name__c,
                                             Claim_Vendors__c,
                                             Claim_Vendors__r.Name,
                                             Claim_Vendors__r.Business_type__c,
                                             Claim_Vendors__r.Business_Sub_Type__c,
                                             Claim_Vendors__r.Contact_Email__c,
                                             Claim_Vendors__r.Street__c,
                                             Claim_Vendors__r.Street_2__c,
                                             Claim_Vendors__r.City__c,
                                             Claim_Vendors__r.State__c,
                                             Claim_Vendors__r.Zip_Code__c,
                                             Claim_Vendors__r.Country__c,
                                             Loan_Number__c,
                                             Mortgagee__c,
                                             Mortgagee__r.Name,
                                             Mortgagee__r.Business_type__c,
                                             Mortgagee__r.Business_Sub_Type__c,
                                             Mortgagee__r.Contact_Email__c,
                                             Mortgagee__r.Street__c,
                                             Mortgagee__r.Street_2__c,
                                             Mortgagee__r.City__c,
                                             Mortgagee__r.State__c,
                                             Mortgagee__r.Zip_Code__c,
                                             Mortgagee__r.Country__c,
                                             Invoice_ID__c,
                                             Customer_Payment_Note__c,
                                             RecordTypeId,
                                             RecordType.Name
                                             FROM Claim_Payment__c WHERE Id =: recordID];
            paymentAttributes payAtt = new paymentAttributes();
            System.debug('Payment_Method_Inc__c=='+claimPayment.Payment_Method_Inc__c);
            System.debug('Print_Locally__c=='+claimPayment.Print_Locally__c);
            System.debug('Expedite__c=='+claimPayment.Expedite__c);
            String text3 = '';
            if(!String.isBlank(claimPayment.Payment_Method_Inc__c)){
                if(claimPayment.Payment_Method_Inc__c == 'Claimant Digital' || (claimPayment.Payment_Method_Inc__c == 'Claimant Check' && claimPayment.Print_Locally__c == false && claimPayment.Expedite__c == false) ){ // //Pay an insured or claimant that is a business digitally
                    //**********Pay Insure or Claim Digitally or bussiness digitally or expedite *******************
                    payAtt.PM_PaymentType = 'Contact(s)';
                    if(claimPayment.Payment_Method_Inc__c == 'Claimant Digital'){
                        payAtt.PMETHOD = 'Let Customer Pickup';
                    }else{
                        payAtt.PMETHOD = 'Check';
                    }
                    
                    //*** Adding
                    payAtt.PMA_Street = claimPayment.Primary_Contact__r.Street__c;
                    payAtt.PMA_City = claimPayment.Primary_Contact__r.City__c;
                    payAtt.PMA_State = claimPayment.Primary_Contact__r.State__c;
                    payAtt.PMA_Zipcode = claimPayment.Primary_Contact__r.Zip_Code__c;
                    payAtt.PMA_Country = claimPayment.Primary_Contact__r.Country__c;
                    payAtt.PMA_MailTo = claimPayment.Primary_Contact__r.Mail_To__c;
                    
                    payAtt.PCON_ContactId = claimPayment.Primary_Contact__c;//
                    payAtt.PCON_FirstName = claimPayment.Primary_Contact__r.First_Name__c;//
                    payAtt.PCON_LastName = claimPayment.Primary_Contact__r.Last_Name__c;//
                    payAtt.PCON_MobilePhone = claimPayment.Primary_Contact__r.MobilePhone__c;
                    payAtt.PCON_OfficePhone = claimPayment.Primary_Contact__r.OfficePhone__c;
                    payAtt.PCON_EmailAddress = claimPayment.Primary_Contact__r.Email__c;
                    
                    if(claimPayment.Primary_Contact__c != null && (claimPayment.Primary_Contact__r.First_Name__c!='' || claimPayment.Primary_Contact__r.Last_Name__c!='' ) ){
                        if(claimPayment.Primary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Primary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    
                    
                    if(claimPayment.Secondary_Contact__c != null && (claimPayment.Secondary_Contact__r.First_Name__c!='' || claimPayment.Secondary_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        
                        if(claimPayment.Secondary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Secondary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    if(claimPayment.Third_Contact__c  != null && (claimPayment.Third_Contact__r.First_Name__c!='' || claimPayment.Third_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        
                        if(claimPayment.Third_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Third_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.Last_Name__c+' ';
                        }
                    }
                    if(claimPayment.Fourth_Contact__c != null && (claimPayment.Fourth_Contact__r.First_Name__c!='' || claimPayment.Fourth_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        
                        if(claimPayment.Fourth_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Fourth_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.Last_Name__c+' ';
                        }
                    }
                    payAtt.PM_Additional_Text_3 = text3;
                    
                    if (claimPayment.Mortgagee__c != null) {
                        payAtt.PM_PaymentType = 'Contact(s) and Mortgagee';
                        payAtt.BUS_BusinessId = claimPayment.Mortgagee__c;
                        payAtt.BUS_Name = claimPayment.Mortgagee__r?.Name;
                        payAtt.BUS_Type = claimPayment.Mortgagee__r?.Business_type__c;
                        payAtt.BUS_EmailAddress = claimPayment.Mortgagee__r?.Contact_Email__c;
                        payAtt.PM_LoanAccountNumber = claimPayment.Loan_Number__c;
                        payAtt.PA_Street = claimPayment.Claim__r?.PolicyNumber?.Street__c;
                        payAtt.PA_City = claimPayment.Claim__r?.PolicyNumber?.City__c;
                        payAtt.PA_State = Utils.mapStateValue(claimPayment.Claim__r?.PolicyNumber?.State__c);
                        payAtt.PA_Zipcode = claimPayment.Claim__r?.PolicyNumber?.Zip__c;
                        // hardcoding property country for now
                        payAtt.PA_Country = 'US';
                    }
                }
                else if(claimPayment.Payment_Method_Inc__c == 'Claimant Check' && claimPayment.Third_Contact__c ==null && claimPayment.Fourth_Contact__c ==null){ //Claimant Check //Issue a check to an insured or claimant (+ Expedite)
                    payAtt.PM_PaymentType = 'Contact(s)';
                    payAtt.PMETHOD = 'Check';
                    //payAtt.PM_Additional_Text_3 = claimPayment.Primary_Contact__r.ParticipantContact.FirstName+' '+claimPayment.Primary_Contact__r.ParticipantContact.LastName;
                    if(claimPayment.Primary_Contact__c != null && (claimPayment.Primary_Contact__r.First_Name__c!='' || claimPayment.Primary_Contact__r.Last_Name__c!='' ) ){
                        if(claimPayment.Primary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Primary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    
                    if(claimPayment.Secondary_Contact__c != null && (claimPayment.Secondary_Contact__r.First_Name__c!='' || claimPayment.Secondary_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        if(claimPayment.Secondary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Secondary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    if(claimPayment.Third_Contact__c  != null && (claimPayment.Third_Contact__r.First_Name__c!='' || claimPayment.Third_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        
                        if(claimPayment.Third_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Third_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.Last_Name__c+' ';
                        }
                    }
                    if(claimPayment.Fourth_Contact__c   != null && (claimPayment.Fourth_Contact__r.First_Name__c!='' || claimPayment.Fourth_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        
                        if(claimPayment.Fourth_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Fourth_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.Last_Name__c+' ';
                        }
                    }
                    payAtt.PM_Additional_Text_3 = text3;
                    payAtt.PMA_Street = claimPayment.Primary_Contact__r.Street__c;
                    payAtt.PMA_City = claimPayment.Primary_Contact__r.City__c;
                    payAtt.PMA_State = claimPayment.Primary_Contact__r.State__c;
                    payAtt.PMA_Zipcode = claimPayment.Primary_Contact__r.Zip_Code__c;
                    payAtt.PMA_Country = claimPayment.Primary_Contact__r.Country__c;
                    payAtt.PMA_MailTo = claimPayment.Primary_Contact__r.Mail_To__c;
                    
                    payAtt.PM_Expedite = claimPayment.Expedite__c!=false?'Y':'N';
                    payAtt.PM_PrintNow = claimPayment.Print_Locally__c == true ?'Y':'N';
                    
                    //****Adding
                    payAtt.PCON_ContactId = claimPayment.Primary_Contact__c;//
                    payAtt.PCON_FirstName = claimPayment.Primary_Contact__r.First_Name__c;//
                    payAtt.PCON_LastName = claimPayment.Primary_Contact__r.Last_Name__c;//
                    payAtt.PCON_MobilePhone = claimPayment.Primary_Contact__r.MobilePhone__c;
                    payAtt.PCON_OfficePhone = claimPayment.Primary_Contact__r.OfficePhone__c;
                    payAtt.PCON_EmailAddress = claimPayment.Primary_Contact__r.Email__c;
                    
                    if (claimPayment.Mortgagee__c != null) {
                        payAtt.PM_PaymentType = 'Contact(s) and Mortgagee';
                        payAtt.BUS_BusinessId = claimPayment.Mortgagee__c;
                        payAtt.BUS_Name = claimPayment.Mortgagee__r?.Name;
                        payAtt.BUS_Type = claimPayment.Mortgagee__r?.Business_type__c;
                        payAtt.BUS_EmailAddress = claimPayment.Mortgagee__r?.Contact_Email__c;
                        payAtt.PM_LoanAccountNumber = claimPayment.Loan_Number__c;
                        payAtt.PA_Street = claimPayment.Claim__r?.PolicyNumber?.Street__c;
                        payAtt.PA_City = claimPayment.Claim__r?.PolicyNumber?.City__c;
                        payAtt.PA_State = Utils.mapStateValue(claimPayment.Claim__r?.PolicyNumber?.State__c);
                        payAtt.PA_Zipcode = claimPayment.Claim__r?.PolicyNumber?.Zip__c;
                        // hardcoding property country for now
                        payAtt.PA_Country = 'US';
                    }
                }
                else if(claimPayment.Payment_Method_Inc__c == 'Claimant Check' && claimPayment.Print_Locally__c == false && (claimPayment.Third_Contact__c!=null || claimPayment.Fourth_Contact__c !=null)){ //Make a Payment to an Insured/Claimant with 3 or More Parties (Check Only)
                    
                    if(claimPayment.Primary_Contact__c != null && (claimPayment.Primary_Contact__r.First_Name__c!='' || claimPayment.Primary_Contact__r.Last_Name__c!='' ) ){
                        if(claimPayment.Primary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Primary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    
                    if(claimPayment.Secondary_Contact__c != null && (claimPayment.Secondary_Contact__r.First_Name__c!='' || claimPayment.Secondary_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        if(claimPayment.Secondary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Secondary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    
                    if(claimPayment.Third_Contact__c != null && (claimPayment.Third_Contact__r.First_Name__c!='' || claimPayment.Third_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        if(claimPayment.Third_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Third_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.Last_Name__c+' ';
                        }
                    }
                    
                    if(claimPayment.Fourth_Contact__c != null && (claimPayment.Fourth_Contact__r.First_Name__c!='' || claimPayment.Fourth_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        if(claimPayment.Fourth_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Fourth_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Fourth_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Fourth_Contact__r.Last_Name__c+' ';
                        }
                    }
                    
                    payAtt.PM_PaymentType = 'Contact(s)';
                    payAtt.PMETHOD = 'Check';
                    
                    
                    payAtt.PCON_ContactId = claimPayment.Primary_Contact__c;//
                    payAtt.PCON_FirstName = claimPayment.Primary_Contact__r.First_Name__c;//
                    payAtt.PCON_LastName = claimPayment.Primary_Contact__r.Last_Name__c;//
                    payAtt.PCON_MobilePhone = claimPayment.Primary_Contact__r.MobilePhone__c;
                    payAtt.PCON_OfficePhone = claimPayment.Primary_Contact__r.OfficePhone__c;
                    payAtt.PCON_EmailAddress = claimPayment.Primary_Contact__r.Email__c;
                    
                    //  payAtt.PCON_SSN = '';
                    // payAtt.PCON_DOB = '';
                    //
                    payAtt.SCON_ContactId = claimPayment.Secondary_Contact__c;//
                    payAtt.SCON_FirstName = claimPayment.Secondary_Contact__r.First_Name__c;//
                    payAtt.SCON_LastName = claimPayment.Secondary_Contact__r.Last_Name__c;//
                    payAtt.SCON_MobilePhone = claimPayment.Secondary_Contact__r.MobilePhone__c;
                    payAtt.SCON_OfficePhone = claimPayment.Secondary_Contact__r.OfficePhone__c;
                    payAtt.SCON_EmailAddress = claimPayment.Secondary_Contact__r.Email__c;
                    //  payAtt.PCON_SSN = '';
                    // payAtt.PCON_DOB = '';
                    //
                    
                    //*** Adding
                    payAtt.PMA_Street = claimPayment.Primary_Contact__r.Street__c;
                    payAtt.PMA_City = claimPayment.Primary_Contact__r.City__c;
                    payAtt.PMA_State = claimPayment.Primary_Contact__r.State__c;
                    payAtt.PMA_Zipcode = claimPayment.Primary_Contact__r.Zip_Code__c;
                    payAtt.PMA_Country = claimPayment.Primary_Contact__r.Country__c;
                    payAtt.PMA_MailTo = claimPayment.Primary_Contact__r.Mail_To__c;
                    
                    payAtt.PM_Expedite =  claimPayment.Expedite__c!=False?'Y':'N';
                    payAtt.PM_Additional_Text_3 = text3; //claimPayment.Primary_Contact__r.ParticipantContact.FirstName+' '+claimPayment.Primary_Contact__r.ParticipantContact.LastName+' AND '+claimPayment.Primary_Contact__r.ParticipantContact.FirstName+' '+claimPayment.Primary_Contact__r.ParticipantContact.LastName;
                    
                    if (claimPayment.Mortgagee__c != null) {
                        payAtt.PM_PaymentType = 'Contact(s) and Mortgagee';
                        payAtt.BUS_BusinessId = claimPayment.Mortgagee__c;
                        payAtt.BUS_Name = claimPayment.Mortgagee__r?.Name;
                        payAtt.BUS_Type = claimPayment.Mortgagee__r?.Business_type__c;
                        payAtt.BUS_EmailAddress = claimPayment.Mortgagee__r?.Contact_Email__c;
                        payAtt.PM_LoanAccountNumber = claimPayment.Loan_Number__c;
                        payAtt.PA_Street = claimPayment.Claim__r?.PolicyNumber?.Street__c;
                        payAtt.PA_City = claimPayment.Claim__r?.PolicyNumber?.City__c;
                        payAtt.PA_State = Utils.mapStateValue(claimPayment.Claim__r?.PolicyNumber?.State__c);
                        payAtt.PA_Zipcode = claimPayment.Claim__r?.PolicyNumber?.Zip__c;
                        // hardcoding property country for now
                        payAtt.PA_Country = 'US';
                    }
                }
                else if(claimPayment.Payment_Method_Inc__c == 'Claimant Check'){
                    if(claimPayment.Primary_Contact__c != null && (claimPayment.Primary_Contact__r.First_Name__c!='' || claimPayment.Primary_Contact__r.Last_Name__c!='' ) ){
                        if(claimPayment.Primary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Primary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Primary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    
                    if(claimPayment.Secondary_Contact__c != null && (claimPayment.Secondary_Contact__r.First_Name__c!='' || claimPayment.Secondary_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        if(claimPayment.Secondary_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Secondary_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Secondary_Contact__r.Last_Name__c+' ';
                        }
                    }
                    if(claimPayment.Third_Contact__c  != null && (claimPayment.Third_Contact__r.First_Name__c!='' || claimPayment.Third_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        
                        if(claimPayment.Third_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Third_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Third_Contact__r.Last_Name__c+' ';
                        }
                    }
                    if(claimPayment.Fourth_Contact__c != null && (claimPayment.Fourth_Contact__r.First_Name__c!='' || claimPayment.Fourth_Contact__r.Last_Name__c!='' )){
                        if((text3!=null && text3!='') || (String.isBlank(text3))){
                            if(text3!=null && text3!=''){
                                text3 += 'AND ';
                            }
                        }
                        if(claimPayment.Fourth_Contact__r.First_Name__c!=''){
                            text3 += claimPayment.Fourth_Contact__r.First_Name__c+' ';
                        }
                        if(claimPayment.Fourth_Contact__r.Last_Name__c!=''){
                            text3 += claimPayment.Fourth_Contact__r.Last_Name__c+' ';
                        }
                    }
                    payAtt.PM_Additional_Text_3 = text3;
                    
                    payAtt.PM_PaymentType = 'Contact(s)';
                    payAtt.PMETHOD = 'Check';
                    payAtt.PM_PrintNow = claimPayment.Print_Locally__c == true ?'Y':'N';
                    payAtt.PM_Expedite =  claimPayment.Expedite__c!=false?'Y':'N';
                    //Call Get Document API --> with returned paymentID
                    //*** Adding
                    payAtt.PMA_Street = claimPayment.Primary_Contact__r.Street__c;
                    payAtt.PMA_City = claimPayment.Primary_Contact__r.City__c;
                    payAtt.PMA_State = claimPayment.Primary_Contact__r.State__c;
                    payAtt.PMA_Zipcode = claimPayment.Primary_Contact__r.Zip_Code__c;
                    payAtt.PMA_Country = claimPayment.Primary_Contact__r.Country__c;
                    payAtt.PMA_MailTo = claimPayment.Primary_Contact__r.Mail_To__c;
                    
                    payAtt.PCON_ContactId = claimPayment.Primary_Contact__c;//
                    payAtt.PCON_FirstName = claimPayment.Primary_Contact__r.First_Name__c;//
                    payAtt.PCON_LastName = claimPayment.Primary_Contact__r.Last_Name__c;//
                    payAtt.PCON_MobilePhone = claimPayment.Primary_Contact__r.MobilePhone__c;
                    payAtt.PCON_OfficePhone = claimPayment.Primary_Contact__r.OfficePhone__c;
                    payAtt.PCON_EmailAddress = claimPayment.Primary_Contact__r.Email__c;
                    
                    if (claimPayment.Mortgagee__c != null) {
                        payAtt.PM_PaymentType = 'Contact(s) and Mortgagee';
                        payAtt.BUS_BusinessId = claimPayment.Mortgagee__c;
                        payAtt.BUS_Name = claimPayment.Mortgagee__r?.Name;
                        payAtt.BUS_Type = claimPayment.Mortgagee__r?.Business_type__c;
                        payAtt.BUS_EmailAddress = claimPayment.Mortgagee__r?.Contact_Email__c;
                        payAtt.PM_LoanAccountNumber = claimPayment.Loan_Number__c;
                        payAtt.PA_Street = claimPayment.Claim__r?.PolicyNumber?.Street__c;
                        payAtt.PA_City = claimPayment.Claim__r?.PolicyNumber?.City__c;
                        payAtt.PA_State = Utils.mapStateValue(claimPayment.Claim__r?.PolicyNumber?.State__c);
                        payAtt.PA_Zipcode = claimPayment.Claim__r?.PolicyNumber?.Zip__c;
                        // hardcoding property country for now
                        payAtt.PA_Country = 'US';
                    }
                }
                else if(claimPayment.Payment_Method_Inc__c == 'Vendor Digital'){  //Pay a vendor
                    //*********Make a Payment to an Insured/Claimant with 3 or More Parties (Check Only)*************
                    payAtt.PM_PaymentType = 'Vendor';
                    //*** Adding
                    payAtt.PMA_Street = claimPayment.Claim_Vendors__r.Street__c;
                    payAtt.PMA_City = claimPayment.Claim_Vendors__r.City__c;
                    payAtt.PMA_State = claimPayment.Claim_Vendors__r.State__c;
                    payAtt.PMA_Zipcode = claimPayment.Claim_Vendors__r.Zip_Code__c;
                    payAtt.PMA_Country = claimPayment.Claim_Vendors__r.Country__c;
                    
                    payAtt.BUS_BusinessId = claimPayment.Claim_Vendors__c;
                    payAtt.BUS_Name = claimPayment.Claim_Vendors__r.Name;
                    payAtt.BUS_Type = claimPayment.Claim_Vendors__r.Business_type__c;
                    payAtt.BUS_SubType = claimPayment.Claim_Vendors__r.Business_Sub_Type__c;
                    payAtt.BUS_EmailAddress = claimPayment.Claim_Vendors__r?.Contact_Email__c;
                    payAtt.PM_Additional_Text_1 = claimPayment.Invoice_ID__c;
                    
                }
                else if(claimPayment.Payment_Method_Inc__c == 'Vendor Digital with Approval'){   //Pay a vendor with approval
                    payAtt.PM_PaymentType = 'Contact(s) and Vendor';
                    payAtt.PCON_Approval_Reqd  = 'Y';
                    
                    //*** Adding
                    payAtt.PMA_Street = claimPayment.Claim_Vendors__r.Street__c;
                    payAtt.PMA_City = claimPayment.Claim_Vendors__r.City__c;
                    payAtt.PMA_State = claimPayment.Claim_Vendors__r.State__c;
                    payAtt.PMA_Zipcode = claimPayment.Claim_Vendors__r.Zip_Code__c;
                    payAtt.PMA_Country = claimPayment.Claim_Vendors__r.Country__c;
                    
                    payAtt.BUS_BusinessId = claimPayment.Claim_Vendors__c;
                    payAtt.BUS_Name = claimPayment.Claim_Vendors__r.Name;
                    payAtt.BUS_Type = claimPayment.Claim_Vendors__r.Business_type__c;
                    payAtt.BUS_SubType = claimPayment.Claim_Vendors__r.Business_Sub_Type__c;
                    payAtt.BUS_EmailAddress = claimPayment.Claim_Vendors__r?.Contact_Email__c;
                        
                    payAtt.PCON_ContactId = claimPayment.Primary_Contact__c;//
                    payAtt.PCON_FirstName = claimPayment.Primary_Contact__r.First_Name__c;//
                    payAtt.PCON_LastName = claimPayment.Primary_Contact__r.Last_Name__c;//
                    payAtt.PCON_MobilePhone = claimPayment.Primary_Contact__r.MobilePhone__c;
                    payAtt.PCON_OfficePhone = claimPayment.Primary_Contact__r.OfficePhone__c;
                    payAtt.PCON_EmailAddress = claimPayment.Primary_Contact__r.Email__c;
                    payAtt.PM_Additional_Text_1 = claimPayment.Invoice_ID__c;
                    
                }
                else if(claimPayment.Payment_Method_Inc__c == 'Vendor Check'){ //a. Vendor Check //Issue a check to a vendor
                    payAtt.PM_PaymentType = 'Vendor';
                    payAtt.PMETHOD = 'Check';
                    payAtt.PM_Expedite =  claimPayment.Expedite__c!=false?'Y':'N';
                    
                    //*** Adding
                    payAtt.PMA_Street = claimPayment.Claim_Vendors__r.Street__c;
                    payAtt.PMA_City = claimPayment.Claim_Vendors__r.City__c;
                    payAtt.PMA_State = claimPayment.Claim_Vendors__r.State__c;
                    payAtt.PMA_Zipcode = claimPayment.Claim_Vendors__r.Zip_Code__c;
                    payAtt.PMA_Country = claimPayment.Claim_Vendors__r.Country__c;
                    
                    payAtt.BUS_BusinessId = claimPayment.Claim_Vendors__c;
                    payAtt.BUS_Name = claimPayment.Claim_Vendors__r.Name;
                    payAtt.BUS_Type = claimPayment.Claim_Vendors__r.Business_type__c;
                    payAtt.BUS_SubType = claimPayment.Claim_Vendors__r.Business_Sub_Type__c;
                    payAtt.BUS_EmailAddress = claimPayment.Claim_Vendors__r?.Contact_Email__c;
                    payAtt.PM_Additional_Text_1 = claimPayment.Invoice_ID__c;
                }
                
                if (payAtt.PMA_Country == 'United States' || payAtt.PMA_Country == 'USA' || payAtt.PMA_Country == 'U.S.') {
                    payAtt.PMA_Country = 'US';
                }
                payAtt.PMA_State = Utils.mapStateValue(payAtt.PMA_State);
                payAtt.PM_PaymentID = claimPayment.Id;
                payAtt.PM_Amount = String.valueOf(claimPayment.Total_Payment__c);
                System.debug('payment amount===' + payAtt.PM_Amount);
                payAtt.PM_RequestReason = claimPayment.Request_Reason__c;
               // payAtt.PM_Amount = '1500';
                
                payAtt.PM_Certified = claimPayment.Certified__c;
                payAtt.PM_ENV = Constants.PM_DEV;  // Need to change when we move to Production................ DEV,QA,PROD
                payAtt.PM_CarrierId = claimPayment.Claim__r.PolicyNumber.Carrier__c;
                payAtt.PM_UserId = claimPayment.CreatedById; //
                payAtt.PM_User_FirstName =claimPayment.CreatedBy.FirstName; //
                payAtt.PM_User_LastName = claimPayment.CreatedBy.LastName;//
                payAtt.PM_User_EmailAddress = claimPayment.CreatedBy.Email;//
                
                payAtt.CL_ClaimNumber = claimPayment.Claim__r.Name;//
                payAtt.CL_ClaimType  = claimPayment.Claim__r.ClaimType;
                payAtt.CL_CauseofLoss  =  claimPayment.Claim__r.Peril__c;
                payAtt.CL_DateofLoss = claimPayment.Claim__r.Date_of_Loss__c!=null?String.valueOf(claimPayment.Claim__r.Date_of_Loss__c):null;
                payAtt.CL_PolicyNumber =  claimPayment.Claim__r.PolicyNumber.Name;
                payAtt.CL_CoverageType = claimPayment.Customer_Payment_Note__c;
                
                if ( claimPayment.RecordType.Name.equals('Digital') && null != claimPayment.Secondary_Contact__c ) {
                    
                    payAtt.SCON_ContactId = claimPayment.Secondary_Contact__r.Id;
                    payAtt.SCON_FirstName = claimPayment.Secondary_Contact__r.First_Name__c;
                    payAtt.SCON_LastName = claimPayment.Secondary_Contact__r.Last_Name__c;
                    payAtt.SCON_MobilePhone = claimPayment.Secondary_Contact__r.MobilePhone__c;
                    payAtt.SCON_EmailAddress = claimPayment.Secondary_Contact__r.Email__c;
                }
                
                System.debug('JSON===='+JSON.serialize(payAtt,true));
                
                CreatePaymentWrapper payWrap = new CreatePaymentWrapper();
                sessionId = PaymentAuth.getSessionID();
                // payWrap.session = PaymentAuth.getSessionID();
                //  payWrap.str_json = JSON.serialize(payAtt,true);
                String JSONRes = '{"session":"'+sessionId+'","str_json":"'+ JSON.serialize(JSON.serialize(payAtt,true))+'"}';
                JSONRes = JSONRes.replace('""', '"');
                System.debug(JSONRes);
                
                String logWrap = '';
                String urlEncodedBody = CalloutHelper.buildMethodCall(Constants.method_CreatePaymentMaster, JSONRes);
                System.debug('urlEncodedBody=='+urlEncodedBody);
                
                HttpResponse response = CalloutHelper.callCalloutHelper(urlEncodedBody,payAuthSetting.Base_URL__c,Constants.method_POST);
                System.debug('response=='+response.getBody());
                if(response.getStatusCode() == 200){
                    String responseBody = response.getBody();
                    //Integration_Log__c errorLog = ErrorLogCapture.integrationLog('CreatePaymentMaster',payAuthSetting.Base_URL__c,'POST','createPayment','Transaction/Claim Payment',recordId,'Success',null);
                    // insert errorLog;
                    // logId = errorLog.Id;
                    // ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
                    
                    if(responseBody.contains('"Error Message"')){
                        responseBody = response.getBody().replace('"Error Message"','"Error_Message"');
                    }
                    paymentResponseWrapper payResponse = new paymentResponseWrapper();
                    payResponse = (paymentResponseWrapper) JSON.deserialize(responseBody, paymentResponseWrapper.class);
                    
                    Transaction__c transOBJ = new Transaction__c();
                    transOBJ.CR_Payment_ID__c = payResponse.PM_PaymentID;
                    transOBJ.Status__c = payResponse.Status;
                    transOBJ.Original_Method__c = payResponse.PM_PaymentMethod;
                    transOBJ.TransactionID__c = payResponse.PM_TranId;
                    transOBJ.Claim_Payment__c = recordID;
                    transOBJ.Payment_Status__c = payResponse.PM_Status;
                    transOBJ.ErrorMessage__c = payResponse.Error_Message;
                    insert transOBJ;
                    
                    Claim_Payment__c cPay = new Claim_Payment__c();
                    cPay.Transaction_Status__c = payResponse.PM_Status;
                    cPay.Id = recordID;
                    update cPay;
                    
                   
                    if(payResponse.Status == 'Error'){
                        Integration_Log__c errorLog = ErrorLogCapture.integrationLog('CreatePaymentMaster',payAuthSetting.Base_URL__c,'POST','createPayment','Transaction/Claim Payment',recordId,'Failure',null);
                        insert errorLog;
                        logId = errorLog.Id;
                        ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
                        
                        
                        if(errorLog!=null && errorLog.Id!=null){
                            Integration_Log__c errorLogUpd = new   Integration_Log__c();
                            errorLogUpd.Id = errorLog.Id;
                            errorLogUpd.Transaction__c = transOBJ.Id;
                            update errorLogUpd;
                        }
                    }
                    if(!String.isBlank(payResponse.Error_Message)){
                        return  'Error: '+humanizeErrorMessages(payResponse.Error_Message, claimPayment.Payment_Method_Inc__c);
                    }else{
                         if (claimPayment.Print_Locally__c && payResponse.Status != 'Error') {
                             System.debug('==Entered Claims get Doc ===');
                           //     Flow.Interview.Get_Document flow1 = new Flow.Interview.Get_Document(cPlist);
      //  flow1.start();
                //       callDocMethod(claimPayment.Id, sessionId);
                    }
                        return  'Transaction Successfull..!';
                    }
                    
                      
                }else{
                    String responseBody = response.getBody();
                    Integration_Log__c errorLog = ErrorLogCapture.integrationLog('CreatePaymentMaster',payAuthSetting.Base_URL__c,'POST','createPayment','Transaction/Claim Payment',recordId,'Failure',null);
                    insert errorLog;
                    logId = errorLog.Id;
                    ErrorLogCapture.createAttachment('Response',responseBody,errorLog.Id);
                    
                }
              
               // PaymentAuth.endSessionBase(sessionId);
            }else{
                return 'Error: Select Payment Type Inc..!';
            }
           }else{
               return 'Error: Claim reserve associated to claim record is in draft status, please get it approved.';
           }
            return 'Error: Contact Your System Admin..!';
        }catch(Exception ex){
            System.debug('ex.getStackTraceString:::'+ex.getStackTraceString());
            System.debug('ex:::'+ex);
            if (sessionId != null) {
                PaymentAuth.endSessionBase(sessionId);
            }
            ErrorLogCapture.integrationErrorLog('CreatePaymentMaster',ex,logId,'createPayment','Error','DML');
            return 'Error: '+ex.getMessage();
        }
    }
    public static void handleFromTrigger(List<Claim_Payment__c> claimPaymentList){
        for(Claim_Payment__c cPayment: claimPaymentList){
            calloutFromTrigger(cPayment.Id);
        }
    }
  
     @future(callout=true)
    public static void calloutFromTrigger(id claimId){
          createPayment(claimId);
    }
    public static String humanizeErrorMessages (String ErrorMessage, String paymentMethod) {
        String paymentTarget = paymentMethod.containsIgnoreCase('vendor') ? 'claim vendor' : 'primary participant';
        if (ErrorMessage.containsIgnoreCase('PM_Amount') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The payment amount (total payment) was invalid, please make sure ' +
                'that you have created at least one Claim Payment Item with a ' +
                'non-zero payment amount';
        }
        if (ErrorMessage.containsIgnoreCase('PMA_Street') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The street address for the ' + paymentTarget + ' is missing or invalid, ' +
                'please check to make sure that the primary participant has an address set.';
        }
        if (ErrorMessage.containsIgnoreCase('PMA_City') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The city for the ' + paymentTarget + ' is missing or invalid, ' +
                'please check to make sure that the primary participant has ' +
                'an address set with a city.';
        }
        if (ErrorMessage.containsIgnoreCase('PMA_Zipcode') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The zipcode for the ' + paymentTarget + ' is missing or invalid, ' +
                'please check to make sure that the primary participant has a valid zipcode set.';
        }
        if (ErrorMessage.containsIgnoreCase('PMA_State') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The state for the ' + paymentTarget + '  address is invalid, ' +
                'please check to make sure it is a valid US state';
        }
        if (ErrorMessage.containsIgnoreCase('PMA_Country') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The country for the ' + paymentTarget + ' address is invalid, ' +
                'please check to make sure it is either the united states or ' +
                'a valid two letter country code';
        }
        if (ErrorMessage.containsIgnoreCase('BUS_Name') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The vendor name is invalid, please make sure that you have a vendor selected, or change ' +
                'to a payment type that is not to a vendor';
        }
        if (ErrorMessage.containsIgnoreCase('BUS_Type') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The business type for the vendor is invalid, please make sure that you have a vendor selected, ' +
                'or change to a payment type that is not to a vendor';
        }
        if (ErrorMessage.containsIgnoreCase('BUS_SubType') && ErrorMessage.containsIgnoreCase('valid')) {
            return 'The business subtype for the vendor is invalid, please make sure that you have a vendor ' +
                'selected, or change to a payment type that is not to a vendor';
        }
        return ErrorMessage;
    }
    public static boolean claimCoverageApprovalValidate(Id recordId){
        Set<Id> claimReserveIdSet = new Set<id>();
        for(Claim_Payment_Item__c cItem:[SELECT ID,Claim_Reserve__c FROM Claim_Payment_Item__c WHERE Claim_Payment__c =: recordId]){
            claimReserveIdSet.add(cItem.Claim_Reserve__c);
        }
        System.debug('------claimReserveIdSet='+claimReserveIdSet);
        for(Claim_Reserve__c claimR:[SELECT Id,Status__c FROM Claim_Reserve__c WHERE Id IN:claimReserveIdSet AND Status__c != 'Approved']){
            System.debug('------claimR'+claimR);
            
            return false;
        }
        return true;
    }
    public class CreatePaymentWrapper{
        public String session;
        public String str_json;
        
    }
    public class paymentAttributes{
        public String PM_RequestReason;
        public String PM_Expedite;
        public boolean PM_Certified;
        public String PM_ENV;
        public String CL_ClaimType;
        public String CL_CoverageType;
        public String CL_CauseofLoss;
        public String CL_DateofLoss;
        public String CL_PolicyNumber;
        public String PCON_MobilePhone;
        public String PCON_OfficePhone;
        public String PCON_EmailAddress;
        public String PCON_SSN;
        public String PCON_DOB;
        public String PCON_FirstName;
        public String PCON_ContactId;
        public String PCON_LastName;
        public String PCON_Approval_Reqd;
        public String PM_PrintNow;
        public String SCON_MobilePhone;
        public String SCON_OfficePhone;
        public String SCON_EmailAddress;
        public String SCON_SSN;
        public String SCON_DOB;
        public String SCON_FirstName;
        public String SCON_ContactId;
        public String SCON_LastName;
        public String CL_ClaimNumber;
        public String PMA_Street;
        public String PM_User_EmailAddress;
        public String PMA_City;
        public String PM_User_LastName;
        public String PMA_State;
        public String PM_User_FirstName;
        public String PMA_Zipcode;
        public String PM_UserId;
        public String PMA_Country;
        public String PM_Amount;
        public String PMETHOD;
        public String PM_PaymentType;
        public String PMA_MailTo;
        public String PM_PaymentID;
        public String PM_Additional_Text_1;
        public String PM_Additional_Text_3;
        public String PM_CarrierId;
        public String BUS_BusinessId;
        public String BUS_Name;
        public String BUS_Type;
        public String BUS_SubType;
        public String BUS_EmailAddress;
        public String PA_Street;
        public String PA_City;
        public String PA_State;
        public String PA_Zipcode;
        public String PA_Country;
        public String PM_LoanAccountNumber;
    }
    public class paymentResponseWrapper{
        public String PM_PaymentID;
        public String PM_Status;
        public String PM_Id;
        public String PM_PaymentMethod;
        public String Status;
        public String PM_TranId;
        public String Error_Message;
    }
}