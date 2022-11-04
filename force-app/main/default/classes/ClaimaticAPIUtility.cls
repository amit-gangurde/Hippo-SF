public class ClaimaticAPIUtility{
    public static Log__c createLogRecord(Exception e,String type,String className,String MethodName,String objectName,String recId,String CustomMessage,String status){
        Log__c log = new Log__c();
        if (e != null) {
            log.Message__c = e.getMessage() + '-' + e.getLineNumber() + '-' + e.getStackTraceString();
        } else {
            log.Message__c = CustomMessage;
        }
        log.Type__c = type;
        log.Class_Name__c = className;
        log.Method_Name__c = MethodName;
        log.Object_Type__c = objectName;
        log.Record_Id__c = recId;
        log.Status__c = status;
        return log;
    }

    public static Log__c createLogRecord(String Integration,String EndPoint,String Request,String Response,String StatusCode,String Type,String Status){
        Log__c log = new Log__c();
        log.Type__c = Type;
        log.Status__c = Status;
        log.Integration__c = Integration;
        log.Endpoint__c = EndPoint;
        log.Request__c = Request;
        log.Response__c = Response;
        log.StatusCode__c = StatusCode;
        return log;
    }

    public static String getPolicyType(String policyType) {
        if (policyType.containsIgnoreCase('home')) {
            return 'HO';
        }
        return '';
    }

    public static Decimal getCoverage(Claim c, String coverageNamePrefix, Decimal defaultValue) {
        for(ClaimCoverage coverage: c.ClaimCoverages) {
            System.debug(coverage);
            if (coverage.Name.startsWithIgnoreCase(coverageNamePrefix)) {
                return coverage.Coverage_Amount__c;
            }
        }
        return defaultValue;
    }

    public static Decimal getDeductible(Claim c, String deductibleNamePrefix, Decimal defaultValue) {
        for(Claim_Deductible__c deductible: c.Claim_Deductibles__r) {
            if (deductible.Name.startsWithIgnoreCase(deductibleNamePrefix)) {
                return deductible.Deductible_Amount__c;
            }
        }
        return defaultValue;
    }

    public static Boolean wasFieldQueried(SObject sobj, String field) {
        Map<String, Object> populatedFields = sobj.getPopulatedFieldsAsMap();
        return populatedFields.containsKey(field);
    }

    public static String getCarrier(Claim c) {
        if (wasFieldQueried(c, 'Carrier__c') && String.isNotBlank(c.Carrier__c)) {
            return c.Carrier__c;
        }
        return c.PolicyNumber.Carrier__c;
    }

    public static String booleanToOneIncFlag(Boolean bool) {
        return bool != false ? 'Y' : 'N';
    }
}