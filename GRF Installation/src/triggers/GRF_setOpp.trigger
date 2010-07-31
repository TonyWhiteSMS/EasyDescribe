trigger GRF_setOpp on Correspondence__c (after insert, after update) {
     system.debug('*** Set the Contact look-up on the Correspondence');
    // Set the Contact look-up on the Correspondence based on matching email address
     if (trigger.new.size()== 1 && trigger.new[0].Amount_Paid_to_Chapter__c>0){
      
         
        Correspondence__c corr = trigger.new[0];
       
        integer opCount = [Select count() from Opportunity where grf_Correspondence__c=:corr.Id];
         system.debug('*** Set the Contact look-up on the Correspondence' + opCount);
         If (opCount ==1) {
            system.debug('*** An Opportunity Exists That References this Corr.');
            Opportunity op = [Select Id, Amount from Opportunity where grf_Correspondence__c=:corr.Id];
            op.Amount = corr.Amount_Paid_to_Charity_Org__c;
            update op;}
          If (opCount == 0 || opCount == null){
            system.debug('*** Create a new Opportunity');
            Opportunity newOpp = new Opportunity(
               grf_Correspondence__c = corr.Id,
               Amount = corr.Amount_Paid_to_Charity_Org__c,
               AccountId = corr.Account_Id__c,
               StageName = 'Closed',
               CloseDate =  corr.CreatedDate.date(),
               Name = corr.Name );
              
             insert newOpp;
               
         }
     
      }
    }