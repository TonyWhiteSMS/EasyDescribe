trigger GRF_createFundraisingSite on Opportunity (after insert) {

// Create a Fundraising Site after an Opportunity is created
  System.debug ('*** Creating a new fundraising site-'+ trigger.new[0].grf01_Fundraising_Event_Name__c);
  if (trigger.new.size()== 1 && trigger.new[0].grf01_Fundraising_Event_Name__c  <> null)  {
    
    Opportunity op = trigger.new[0] ;
    
    RecordType setUp = [Select Id, Name from RecordType where Name = 'Site Set-up' limit 1];
    
    Fundraising_Event__c newSite = new Fundraising_Event__c(
       Name = op.grf01_Fundraising_Event_Name__c,Event_Date__c = op.grf01_Fundraising_Event_Proposed_Date__c,
       Chapter__c = op.AccountId, Opportunity__c = op.Id,RecordTypeId=setUp.Id,
       Expected_Attendance__c=op.grf01_Fundraising_Event_Attendance_Goal__c,
       Event_Description__c = op.grf01_Event_Description__c,
       Expected_Revenue__c = op.grf01_Fundraising_Goal_Dollars__c);

    insert newSite;
     
  }    
}