public class ReassignLeads 
{
    public static void reassignToQueue()
    {
        //get the Id of the Leads queue to reassign the non worked Leads to that queue
        Group leadQueue = [SELECT Id, Name FROM Group Where DeveloperName = 'B2C_Sales' and Type = 'Queue']; 
        DateTime currentTime = System.now();
        
        //get the cut off time from custom metadata record
        Lead_Reassignment__mdt leadType = [SELECT LeadAcceptedTimeCutOff__c FROM Lead_Reassignment__mdt WHERE DeveloperName = 'B2C_Lead'];
        Integer acceptCO = leadType.LeadAcceptedTimeCutOff__c.intValue();

        DateTime acceptTimeExceed = currentTime.addHours(-acceptCO);
        System.debug('AcceptedCutOffTime from Custom Metadata: ' + acceptCO);
        
        List<Lead> leadsToUpdate = new List<Lead>();

        List<Lead> newLeads = getNewLeads(acceptTimeExceed);
        if(!newLeads.IsEmpty())
        {
            for(Lead lead : newLeads)
            {
            	lead.OwnerId = leadQueue.Id;
            	leadsToUpdate.add(lead);
            }
        }
        if(!leadsToUpdate.IsEmpty())
        {
            update leadsToUpdate;
            System.debug('Lead size to be updated:' + leadsToUpdate.size());
        }
    }
    
	public static List<Lead> getNewLeads(DateTime leadAcceptedTimeExceed)
    {
        Id RecordTypeIdLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('B2C Sales').getRecordTypeId();
        System.debug('RT Id: ' + RecordTypeIdLead);
        
        //Get all the leads whose status is New and which is accepted more than an hour ago
        List<Lead> newLeads = [SELECT Id, Status, RecordTypeId, Work_Accepted_Time__c FROM Lead
                               WHERE RecordTypeId = :RecordTypeIdLead AND Status = 'New' AND Work_Accepted_Time__c != NULL AND Work_Accepted_Time__c <= :leadAcceptedTimeExceed]; 
        System.debug('Lead size:' + newLeads.size());
         
        return newLeads;
    }       
}