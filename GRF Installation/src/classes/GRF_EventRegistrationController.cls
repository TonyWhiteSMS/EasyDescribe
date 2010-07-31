public class GRF_EventRegistrationController {
        public Correspondence__c c {get; set;}
        public Fundraising_Event__c theEvent {get;set;}
        public GRF_EventRegistrationController() { 
        c = new Correspondence__c();   
        String EventId = ApexPages.currentPage().getParameters().get('id');
        System.debug('*** EventId '+ EventId);
         if (EventId != null) { 
            theEvent = [Select id, Name,Chapter__c,Chapter_Logo_Graphic__c,Chapter_Logo_URL__c,
             Chapter_Logo_Width__c,Chapter_Logo_Height__c,Organization_Logo_URL__c, 
             Organization_Logo_Width__c,Organization_Logo_Height__c,Organization_Logo_Graphic__c,
             Event_Picture_URL__c, Event_Picture_Width__c,Event_Picture_Height__c,Event_Commentary__c,
             Event_Date__c,Event_Description__c, Event_Date_Time_When__c,
             Event_Location_Where__c, Event_Reason_and_Policies_Why__c, Event_Cost_How_Much__c, 
             Event_Map_Graphic__c ,Event_Map_URL__c, Event_Admission_Fee__c, Twitter_Username__c,
             Facebook_Username__c, Custom_Page_Name__c, Twitter_Search_Terms__c,
             Site_Type__c,For_more_information_contact__c,Event_Title__c,Event_Tagline__c,
             Support__c,Social_Media_Links_Label__c,Organization_Logo_Ch_Alt_Text__c,Chapter_Logo_Alt_Text__c,
             Flickr_Tags__c, Flickr_User_Id__c,Registration_Description__c, 
             Payment_Method_Website__c,Payment_Method_Door__c,Payment_Method_Chapter__c,
             Payment_Method_Organization__c,Chapter__r.Name,Event_Plan_Reviewed__c,Site_Closed__c,
             Funds_Raised_to_Date__c,Expected_Revenue__c,Display_Fundraising_Progress_Graphic__c,
             Payment_Processing_Page__c
             From Fundraising_Event__c 
                where id = :EventId LIMIT 1];
             }  
          else { 
             theEvent = [Select id,Name, Chapter__c,Chapter_Logo_Graphic__c,Chapter_Logo_URL__c,
             Chapter_Logo_Width__c,Chapter_Logo_Height__c,Organization_Logo_URL__c, 
             Organization_Logo_Width__c, Organization_Logo_Height__c,Organization_Logo_Graphic__c,
             Event_Picture_URL__c, Event_Picture_Width__c,Event_Picture_Height__c,Event_Commentary__c,
             Event_Date__c,Event_Description__c, Event_Date_Time_When__c,
             Event_Location_Where__c, Event_Reason_and_Policies_Why__c,
             Event_Cost_How_Much__c,Event_Map_Graphic__c,Event_Map_URL__c,Event_Admission_Fee__c,
             Twitter_Username__c,Facebook_Username__c, Custom_Page_Name__c,
             Twitter_Search_Terms__c ,Site_Type__c,For_more_information_contact__c,
             Event_Title__c,Event_Tagline__c , Support__c ,Social_Media_Links_Label__c,
             Organization_Logo_Ch_Alt_Text__c,Chapter_Logo_Alt_Text__c,
             Flickr_Tags__c, Flickr_User_Id__c,Registration_Description__c, 
             Payment_Method_Website__c,Payment_Method_Door__c,Payment_Method_Chapter__c,
             Payment_Method_Organization__c,Chapter__r.Name,Event_Plan_Reviewed__c,Site_Closed__c,
             Funds_Raised_to_Date__c,Expected_Revenue__c,Display_Fundraising_Progress_Graphic__c,
             Payment_Processing_Page__c
            From Fundraising_Event__c LIMIT 1];
         } 
         c.Fundraising_Event__c = theEvent.id; 
         Try {
           If (theEvent.Custom_Page_Name__c.length()==0)
             {theEvent.Custom_Page_Name__c = 'GRF_EventBlankPage'; }}
          Catch(exception e)
             {theEvent.Custom_Page_Name__c = 'GRF_EventBlankPage'; }
        } 

  
  public PageReference Print() {
    return Page.GRF_EventPDF; 
    } 

  public PageReference Register() {  
    System.debug('*** Registration ');
    Boolean isError = false;
    String strName = theEvent.Name +'-' + system.today()+': ' +c.First_Name__c +' ' +c.Last_Name__c;
    if (strName.length() > 80){
         strName = strName.substring(0,79);
     }            
     c.Source__c = 'Website';
     c.Name = strName;         
     try {
       If ( theEvent.Site_Type__c =='Donation' &&   c.Payment_Method__c == null){
        c.Payment_Method__c = 'Website';}   
       System.debug('*** Corr. Name' + c.name);  
       insert c;  
     }
     catch (Exception e) {
        System.debug('**** ' + e);    
        ApexPages.addMessages(e); 
        isError = true;   
        return Page.GRF_EventRegistration; 
      }            
      System.debug ('*** Payment Method '+ c.Payment_Method__c 
        +'&'+ApexPages.currentPage().getParameters().get('PaymentMethod') );
      If (c.Payment_Method__c =='Website' || theEvent.Site_Type__c =='Donation'  ||
           ApexPages.currentPage().getParameters().get('PaymentMethod')=='Website'){
           System.debug('*** Paying by Credit Card' + theEvent.Site_Type__c  + '****');
      
      /* If using Google Checkout
           PageReference pr;  
           pr = Page.GoogleRedirectV2;
           pr.getParameters().put('item_name_1','HELPSudanDonation');
           pr.getParameters().put('item_description_1','HELPSudanDonation (Id =' +c.Id +')');
           pr.getParameters().put('item_quantity_1','1');
           pr.getParameters().put('item_price_1',c.Amount_Donated_through_Org_Website__c.format());
           pr.getParameters().put('item_merchant_id_1',c.Id); 
           pr.getParameters().put('item_name_2','Admission');             
           pr.getParameters().put('item_description_2','Admission (Id =' +c.Id +')');
           pr.getParameters().put('item_quantity_2',c.Number_Planning_to_Attend__c.format());
           pr.getParameters().put('item_price_2',theEvent.Event_Admission_Fee__c.format());
           pr.getParameters().put('item_merchant_id_2',c.Id);
        */              
       
       // Payment Connect Processing
         PageReference pr = new PageReference(theEvent.Payment_Processing_Page__c);
         string cId =c.Id;
         system.debug('*** Correspondence Id' + cId);
         c = [Select Id,last_name__c, first_name__c, email__c,
             Amount_Donated_through_Org_Website__c,Number_Planning_to_Attend__c,
             Admissions_Fee_Paid_Through_Org_Website__c           
             from Correspondence__c where id=:cId limit 1] ;       
         pr.getParameters().put('eventid',theEvent.Id);
         pr.getParameters().put('firstname',c.first_name__c);
         try 
           {pr.getParameters().put('lastname',c.last_name__c);}
         catch(exception e){}
         try {pr.getParameters().put('email',c.email__c);}
         catch(exception e){}
         try {pr.getParameters().put('donationamount',c.Amount_Donated_through_Org_Website__c.format());} 
         catch(exception e)
           { pr.getParameters().put('donationamount','0');} 
        try{
          pr.getParameters().put('admissionfee',c.Admissions_Fee_Paid_Through_Org_Website__c.format());
         }
         catch(exception e){pr.getParameters().put('admissionfee','0');}
         pr.getParameters().put('correspondenceid',c.Id);
       // end of Payment Connect Processing
         return pr;   
       } 
       else{
       return page.GRF_EventRegistrationThankYou;} }
     
       public static testmethod void SuccessValidId (){
        System.debug('*** Test Create a New Opportunity');
        Opportunity o = new opportunity (Stagename = 'Open',
          closedate = system.date.today(),
          Name = 'Test1', grf01_Fundraising_Event_Name__c = 'Test1');
        insert o;  
        System.debug('*** Test Create a New Fundraising Event');
        Fundraising_Event__c f = new Fundraising_Event__c() ;
        f.Name='Test1';
        insert f;
          Test.setCurrentPageReference(new PageReference('Page.GRF_EventRegistration')); 
          System.currentPageReference().getParameters().put('id', f.id);
          System.currentPageReference().getParameters().put('PaymentMethod', 'Website');
          System.debug ('*** Fundraiser Id ' + ApexPages.currentPage().getParameters().get('id') );         
          GRF_EventRegistrationController controller = new GRF_EventRegistrationController();
          Correspondence__c corr = new Correspondence__c (Name = 'Test1', First_Name__c = 'Test 1', 
            Last_Name__c = 'Test 1', Fundraising_Event__c = f.id, Amount_Paid_to_Chapter__c = 10,
            email__c='test1@test.com',Payment_Method__c = 'Website' 
            );
          Controller.c=corr;
          Controller.Print();
          Controller.Register();
        corr.Amount_Paid_to_Chapter__c = 20;
        corr.status__c = 'Payment Completed';
        update corr;  
        
       }
        public static testmethod void SuccessInvalidId (){
        Fundraising_Event__c F = new Fundraising_Event__c() ;
        F.Name='Test2';
        insert F;
          Test.setCurrentPageReference(new PageReference('Page.GRF_EventRegistration')); 
          GRF_EventRegistrationController controller = new GRF_EventRegistrationController();
          Test.setCurrentPageReference(new PageReference('Page.GRF_EventRegistration'));
          Correspondence__c corr = new Correspondence__c (Name = 'Test 2', First_Name__c = 'Test 2', 
            Last_Name__c = 'Test 2', Fundraising_Event__c = f.id, Amount_Paid_to_Chapter__c = 10,
            email__c='test2@test.com',Payment_Method__c = 'Door' 
            );
          Controller.c=corr;
          Controller.Print(); 
          Controller.Register();
       }
       }