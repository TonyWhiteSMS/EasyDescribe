global class GRF_PaymentEmailCatcher  implements Messaging.InboundEmailHandler {
    //Removed RT
   
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, 
    Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        System.debug('*** GRF Email Catcher');
        string body = email.plaintextbody;
        System.debug('*** Email Body' + body);       
        // create a task to store this email
        Task t = new Task();
      
    
        System.debug('*** The email subject is ' +email.subject);
        t.Subject = email.subject;
        t.Description = email.htmlBody;
        
        System.debug('*** Email is from = ' +envelope.fromAddress);
        
        
        //See if this is from Google, if so it's an order transaction
        if (email.replyTo  == 'noreply@checkout.google.com'){
            System.debug('*** body.indexOf(\'Google order number: \') ' 
            +body.indexOf('Google order number: '));
            System.debug('*** body.indexOf(\'(Id\') = ' +body.indexOf('(Id'));
 
            /* Google Checkout Commented Out until Required 
 
            if (body.indexOf('(Id') != -1){
                String strCId = body.substring(body.indexOf('(Id')+5, body.indexOf('(Id')+23);
                System.debug('*** I think the CId is ' +strCId);
                
                //Get the related correspondence
                List<Correspondence__c> lstCorr = [Select Id, Order_Number__c,
                 Fundraising_Event__r.OwnerId from Correspondence__c where Id =: strCId];
                
                if (lstCorr.size() > 0){
                    Correspondence__c c = lstCorr[0];
                    if (c.Transaction_Id__c == null &&body.indexOf('Google order number: ') != -1){
                     
              c.Transaction_Id__c = body.substring(body.indexOf('Google order number: ')+21,
              body.indexOf('Google order number: ')+36);
                        System.debug('*** Updating the Correspondence with Google Order Number '
                         +c.Order_Number__c);
                        update c;
                    } 
                    t.WhatId = c.Id;
                    t.OwnerId = c.Fundraising_Event__r.OwnerId;
                }
            }*/
        
        } 
         
           if (email.subject.indexOf('PaymentConnect Transaction')!= -1){
             System.debug('*** This is a payment connect transaction');
          //      t.RecordTypeId = idTransactRT;
            
                try{
                    String strCorrId = body.substring(body.indexOf('Correspondence:')+16,
                     body.indexOf('</correspondence>'));
                      System.debug('*** I think the Correspondence is:' +strCorrId+ '.');
                    Id idCorrId = (Id) strCorrId;
                    String strPayId = body.substring(body.indexOf('<payment>')+10, 
                    body.indexOf('</payment>'));
                    System.debug('I think the PayId is:' +strPayId +'.');
                    String strOrderNo = body.substring(body.indexOf('<order>')+8, 
                    body.indexOf('</order>'));
                    System.debug('I think the Order # is:' +strOrderNo +'.');
                    String strAmount = body.substring(body.indexOf('<amount> $')+10, 
                    body.indexOf('</amount>'));
                    System.debug('I think the Amount is:' +strAmount +'.');
                    pymt__PaymentX__c p = [Select Id,pymt__Contact__c from pymt__PaymentX__c 
                    where Id=:strPayId];
                    correspondence__c c = [Select Id,Name,Transaction_Id__c,Fundraising_Event__r.OwnerId 
                    from correspondence__c where Id=:strCorrId];
                        c.Order_Number__c = strOrderNo;
                        c.Transaction_Id__c = strPayId;
                        c.Status__c = 'Payment Completed';
                        c.Contact__c = p.pymt__Contact__c;
                        c.Amount_Paid_to_Charity_Org__c = decimal.valueof(strAmount);
                        update c;
                                        t.WhatId = c.Id;
                                t.OwnerId = c.Fundraising_Event__r.OwnerId;
}
                Catch(Exception e) {
                   System.debug('Error **** Malformed PaymentConnect Email');
                   }  
                }
           
        
        
        else {
        System.debug('*** This must be a customer e-mail transaction');
            t.Reply_To__c = email.replyTo;         
        }
        
        insert t;
        
        
        return result;
    }
    
     // Success Case
   public static testMethod void CustomerTest(){
       
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        Fundraising_Event__c F = new Fundraising_Event__c() ;
        F.Name='abc';
        insert F;
        Correspondence__c c = new Correspondence__c();
        c.name = 'abd';
        c.Fundraising_Event__c = F.Id;
        c.Transaction_Id__c = '12345';
        insert c;
      

        email.subject = 'test';
        email.fromName = 'test test';
        email.plainTextBody = 'order# 12345';
        email.htmlBody = 'order# 12345';
        envelope.fromAddress = 'user@acme.com';
        


        // setup controller object
        GRF_PaymentEmailCatcher catcher = new GRF_PaymentEmailCatcher();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
          

    
    }
      public static testMethod void GoogleCheckoutTest(){
       
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        Fundraising_Event__c F = new Fundraising_Event__c() ;
        F.Name='abc';
        insert F;
        Correspondence__c c = new Correspondence__c();
        c.name = 'abd';
        c.Fundraising_Event__c = F.Id;
        c.Transaction_Id__c = '12345';
        insert c;
      

        email.subject = 'test';
        email.fromName = 'test test';
        email.plainTextBody = 'Google order number: 123456789abcde '+'(Id ' + c.Id;
        email.htmlBody = 'Google order number: 123456789abcde '+'(Id ' + c.Id;
        email.replyto = 'noreply@a.com';
        envelope.fromAddress = 'user@acme.com';
        email.replyto = 'noreply@checkout.google.com';


        // setup controller object
        GRF_PaymentEmailCatcher catcher = new GRF_PaymentEmailCatcher();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
          

    
    }
        public static testMethod void PaymentConnect(){
       
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        Fundraising_Event__c F = new Fundraising_Event__c() ;
        F.Name='abc';
        insert F;
        Correspondence__c c = new Correspondence__c();
        c.name = 'abd';
        c.Fundraising_Event__c = F.Id;
        c.Transaction_Id__c = '12345';
        insert c;
      

        email.subject = 'PaymentConnect Transaction';
        email.fromName = 'test test';
        email.plainTextBody = 'Correspondence: ' + c.Id + ' payment ' + c.Id + ' order # 12345 amount 199999';
        email.htmlBody ='Correspondence: ' + c.Id + ' payment ' + c.Id + ' order # 12345 amount 199999';
        email.replyto = 'noreply@checkout.google.com';
        envelope.fromAddress = 'user@acme.com';
        email.replyto = 'noreply@checkout.google.com';


        // setup controller object
        GRF_PaymentEmailCatcher catcher = new GRF_PaymentEmailCatcher();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
          

    
    }
}