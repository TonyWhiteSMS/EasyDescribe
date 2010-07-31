trigger GRF_setContact on Correspondence__c (before insert,before update) {
    
    // Set Look-ups to link Corrospondence records to Contacts and Opportunities
    
    // Set the Contact look-up on the Correspondence based on matching emails
     if (trigger.new.size()== 1){
        Correspondence__c corr = trigger.new[0];
     if (corr.contact__c == null) {
       try {
         Contact con = [Select Id, email from Contact where email=:corr.email__c limit 1];
         corr.Contact__c = con.Id;
         System.debug('Correspondence Contact ID - ' + corr.Contact__c);
         }
       catch (exception e) {}  
      } //system.debug('Check if Payment Completed');
      if (corr.status__c == 'Payment Completed') {
         System.debug('Payment Completed - Set to Opportunity' + corr.opportunity_id__c);
           corr.opportunity__c =corr.opportunity_id__c;
       
         } 
       else {
         corr.opportunity__c=null;
         System.debug('*** Correspondence Not Associated with an Opportunity');}

    }
   }