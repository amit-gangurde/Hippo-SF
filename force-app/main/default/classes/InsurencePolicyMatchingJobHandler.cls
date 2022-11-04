/*******************************************************************************************
* @Name         InsurencePolicyMatchingJobHandler
* @Author       Convene-tech
* @Date         12/16/2021
* @Description  This class query Insurency Policy and perform license matching and handle the logics here.
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0            convene-tech      12/24/2021          Modified
*******************************************************************************************/
public class InsurencePolicyMatchingJobHandler {
    public static void handlePolicyLicenseMatching(List<InsurancePolicy> insurepolicyLst){
        Set<Id> producerIdset = new Set<Id>();
        Set<Id> contactIdset = new Set<Id>();
        Map<Id,List<License__c>> licenseMaplist = new  Map<Id,List<License__c>>();
        Map<Id,List<Carrier_Appointment__c>> carrierAppointmentMaplist = new  Map<Id,List<Carrier_Appointment__c>>();
        for(InsurancePolicy ins: insurepolicyLst){
            if(ins.Producer__c!=null){
                contactIdset.add(ins.Producer__c);
            }
        }
        
        System.debug('=contactIdset='+contactIdset);
        For(License__c license:[SELECT ID,Contact__c,State_Code__c FROM License__c WHERE Contact__c IN: contactIdset AND Active__c = 'Yes']){
            List<License__c> licesneLst = new List<License__c>();
            licesneLst.add(license);
            if(licenseMaplist.containsKey(license.Contact__c)){
                licesneLst.addAll(licenseMaplist.get(license.Contact__c));
                licenseMaplist.put(license.Contact__c,licesneLst);
            }else{
                licenseMaplist.put(license.Contact__c,licesneLst);  
            }
        }
        System.debug('=licenseMaplist='+licenseMaplist);
        
        For(Carrier_Appointment__c carrierApp:[SELECT ID,Contact__c,State_Code__c FROM Carrier_Appointment__c WHERE Contact__c IN: contactIdset AND Status__c!='Terminated']){
            List<Carrier_Appointment__c> CarrierAppLst = new List<Carrier_Appointment__c>();
            CarrierAppLst.add(carrierApp);
            if(carrierAppointmentMaplist.containsKey(carrierApp.Contact__c)){
                CarrierAppLst.addAll(carrierAppointmentMaplist.get(carrierApp.Contact__c));
                carrierAppointmentMaplist.put(carrierApp.Contact__c,CarrierAppLst);
            }else{
                carrierAppointmentMaplist.put(carrierApp.Contact__c,CarrierAppLst);  
            }
        }
        
        System.debug('=carrierAppointmentMaplist='+carrierAppointmentMaplist);
        List<Insurance_Policy_License__c> insPolicyLst = new List<Insurance_Policy_License__c>();
        integer licenseSize = 0;
        for(InsurancePolicy ins: insurepolicyLst){
            if(ins.Producer__c!=null && carrierAppointmentMaplist.containsKey(ins.Producer__c) && carrierAppointmentMaplist.get(ins.Producer__c)!=null){
                for(Carrier_Appointment__c carrierApp: carrierAppointmentMaplist.get(ins.Producer__c)){
                    if(carrierApp.State_Code__c!=null &&  ins.State__c!=null && carrierApp.State_Code__c.toUpperCase() == ins.State__c.toUpperCase()){
                        if(ins.Producer__c!=null && licenseMaplist.get(ins.Producer__c)!=null){
                            for(License__c license: licenseMaplist.get(ins.Producer__c)){
                                if(license.State_Code__c!=null &&  ins.State__c!=null && license.State_Code__c.toUpperCase() == ins.State__c.toUpperCase()){
                                    Insurance_Policy_License__c insPolicy = new Insurance_Policy_License__c();
                                    insPolicy.Producer__c =ins.ProducerId;
                                    insPolicy.Carrier_Appointment__c = carrierApp.Id;
                                    insPolicy.License__c = license.id;
                                    insPolicy.Insurance_Policy__c = ins.id;
                                    insPolicy.Contact__c = ins.Producer__c;
                                    insPolicy.UpsertKey__c = insPolicy.Contact__c+'_'+insPolicy.Insurance_Policy__c;//+'_'+ insPolicy.Carrier_Appointment__c+'_'+insPolicy.License__c;
                                    insPolicyLst.add(insPolicy);
                                    licenseSize++;
                                }
                            }
                            if(licenseSize == 0){
                                Insurance_Policy_License__c insPolicy = new Insurance_Policy_License__c();
                                insPolicy.Producer__c =ins.ProducerId;
                                insPolicy.Carrier_Appointment__c = carrierApp.Id;
                                // insPolicy.License__c = license.id;
                                insPolicy.Insurance_Policy__c = ins.id;
                                insPolicy.Contact__c = ins.Producer__c;
                                insPolicy.UpsertKey__c = insPolicy.Contact__c+'_'+insPolicy.Insurance_Policy__c;
                                //insPolicy.UpsertKey__c = insPolicy.Insurance_Policy__c+'_'+ insPolicy.Carrier_Appointment__c+'_'+insPolicy.License__c;
                                insPolicyLst.add(insPolicy);
                                licenseSize = 0;
                            }
                            
                        }else{
                            Insurance_Policy_License__c insPolicy = new Insurance_Policy_License__c();
                            insPolicy.Producer__c =ins.ProducerId;
                            insPolicy.Carrier_Appointment__c = carrierApp.Id;
                            // insPolicy.License__c = license.id;
                            insPolicy.Insurance_Policy__c = ins.id;
                            insPolicy.Contact__c = ins.Producer__c;
                            insPolicy.UpsertKey__c = insPolicy.Contact__c+'_'+insPolicy.Insurance_Policy__c;
                            //insPolicy.UpsertKey__c = insPolicy.Insurance_Policy__c+'_'+ insPolicy.Carrier_Appointment__c+'_'+insPolicy.License__c;
                            insPolicyLst.add(insPolicy);
                        }
                    }
                }
            }else{
                if(ins.Producer__c!=null && licenseMaplist.get(ins.Producer__c)!=null){
                    for(License__c license: licenseMaplist.get(ins.Producer__c)){
                        if(license.State_Code__c!=null &&  ins.State__c!=null && license.State_Code__c.toUpperCase() == ins.State__c.toUpperCase()){
                            Insurance_Policy_License__c insPolicy = new Insurance_Policy_License__c();
                            insPolicy.Producer__c =ins.ProducerId;
                            //  insPolicy.Carrier_Appointment__c = carrierApp.Id;
                            insPolicy.License__c = license.id;
                            insPolicy.Insurance_Policy__c = ins.id;
                            insPolicy.Contact__c = ins.Producer__c;
                            insPolicy.UpsertKey__c = insPolicy.Contact__c+'_'+insPolicy.Insurance_Policy__c;
                            // insPolicy.UpsertKey__c = insPolicy.Insurance_Policy__c+'_'+ insPolicy.Carrier_Appointment__c+'_'+insPolicy.License__c;
                            insPolicyLst.add(insPolicy);
                        }
                    }
                }
                
            }
            licenseSize = 0;
        }
        // upsert insPolicyLst UpsertKey__c;
        Map<String,Insurance_Policy_License__c> upsertMap = new Map<String,Insurance_Policy_License__c>();
        for(Insurance_Policy_License__c ins: insPolicyLst){
            upsertMap.put(ins.UpsertKey__c,ins);
        }
        if(upsertMap.size()>0){
            upsert upsertMap.values() UpsertKey__c;
        }
        Map<Id,Set<Id>> licenseIdLstMap = new Map<Id,Set<Id>>();
        for(Insurance_Policy_License__c insLicense: insPolicyLst){
            if(insLicense.license__c!=null){
                Set<Id> LicenseSet = new Set<Id>();
                LicenseSet.add(insLicense.Id);
                if(licenseIdLstMap.containsKey(insLicense.license__c)){
                    LicenseSet.addAll(licenseIdLstMap.get(insLicense.license__c));
                    licenseIdLstMap.put(insLicense.license__c,LicenseSet);
                }else{
                    licenseIdLstMap.put(insLicense.license__c,LicenseSet);  
                }
            }
        }
        
        Map<Id,Insurance_Policy_License__c> insurancePolicyUpdMap = new Map<Id,Insurance_Policy_License__c>();
        for(Line_of_Authority__c line:[SELECT ID,License__c FROM Line_of_Authority__c WHERE License__c IN: licenseIdLstMap.keySet()]){
            if(licenseIdLstMap.containsKey(line.License__c)){
                for(Id licenseId: licenseIdLstMap.get(line.License__c)){
                    if(licenseId!=null){
                        Insurance_Policy_License__c insPolicy = new Insurance_Policy_License__c();
                        insPolicy.Id = licenseId;
                        insPolicy.Line_of_Authority__c = line.id;
                        insurancePolicyUpdMap.put(insPolicy.Id,insPolicy);
                    }
                }
            }
        }
        if(insurancePolicyUpdMap.size()>0){
            update insurancePolicyUpdMap.values();
        }
    }
}