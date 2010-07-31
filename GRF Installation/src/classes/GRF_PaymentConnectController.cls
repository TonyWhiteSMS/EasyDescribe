public class GRF_PaymentConnectController {

    public PageReference googleDonation() {
        return null;
    }


    public PageReference paypalDonation() {
        return null;
    }

    // GRF Added Fields
    public string grf_admissionfee {get;set;}
    public string grf_correspondenceid {get;set;}
    public string grf_eventid {get;set;}
    public string grf_email {get;set;}
    // GRF End of Added Fields


    public Contact contact {get;set;}
    public pymt__PaymentX__c payment {get;set;}
    public pymt__Payment_Profile__c paymentProfile {get;set;}
    public pymt__Processor_Connection__c processor;

    
    public List<SelectOption> suggestedDonationOptions {get;set;}
    public String selectedDonationAmount {get;set;}
    public String otherDonationAmount {get;set;}
    public Decimal donationAmount {get;set;}
    public String recurringPeriod {get;set;}
    public Decimal occurrences {get;set;}

    // Credit Card fields
    public String fnameOnCard {get;set;}
    public String lnameOnCard {get;set;}
    public String companyName {get;set;}
    public String billingStreet {get;set;}
    public String billingCity {get;set;}
    public String billingState {get;set;}
    public String billingPostalCode {get;set;}
    public String billingCountry {get;set;}
    public String shippingStreet {get;set;}
    public String shippingCity {get;set;}
    public String shippingState {get;set;}
    public String shippingPostalCode {get;set;}
    public String shippingCountry {get;set;}

    
    // Form state control
    public String viewState {get;set;}  // campaign_not_found, get_donor_info, get_card_info, review_and_submit, 
    public Boolean showRecurring {get;set;} // Flag controls the display of recurring payment options on form
    public Boolean showPayPalButton {get;set;}      // Flag to enable payPal Express Checkout button (if applicable)            
    public Boolean isRecurring {get;set;}  // Indicates whether or not donor has selected a recurring donation option
    public String processorName {get;set;}  // nickname for the payment processor being used (paypal, authnet, google)
    public Boolean disableForm {get;set;}
    
        
    
   
        
    public class LocalException extends Exception {}
    
    public GRF_PaymentConnectController() {

        // Set start state for form
        this.disableForm = false; 
        this.showPayPalButton = false;
        this.viewState = 'get_donor_info';
        this.isRecurring = false;
        this.contact = new Contact();
        this.suggestedDonationOptions = new List<SelectOption>();
   
        // GRF Initialization Starts Here
       
        contact.firstname = ApexPages.currentPage().getParameters().get('firstname');
        system.debug('fnameoncard: ' + fnameoncard);
        contact.lastname = ApexPages.currentPage().getParameters().get('lastname');
        contact.email = ApexPages.currentPage().getParameters().get('email');
        otherDonationAmount = ApexPages.currentPage().getParameters().get('donationamount');  
        grf_admissionfee = ApexPages.currentPage().getParameters().get('admissionfee');
        grf_correspondenceid = ApexPages.currentPage().getParameters().get('correspondenceid');
        grf_eventid = ApexPages.currentPage().getParameters().get('eventid');
   
        // GRF Initialization Ends Here
   
        try {
            String payPalBtnParm = ApexPages.currentPage().getParameters().get('payPalBtn');
            payPalBtnParm = isNullOrEmpty(payPalBtnParm)?'0':payPalBtnParm;
            this.showPayPalButton = (payPalBtnParm == '1' || payPalBtnParm.equalsIgnoreCase('true'));  

            this.recurringPeriod = 'Monthly';
            //this.recurringPeriod = 'Annual';                  
                
            String[] donationOptions = new String[]{'50','100','200','300'};
            for (String option :donationOptions) {
                this.suggestedDonationOptions.add(new SelectOption(option, '$'+option));    
            }
            this.suggestedDonationOptions.add(new SelectOption('Other', 'Other:'));
    
            // Retrieve default processor connection record
            // Otherwise search for the first available supported processor connection
            pymt__Processor_Connection__c[] connections = [Select id, pymt__default_connection__c, 
                                                            pymt__processor_id__c, 
                                                            pymt__test_mode__c, 
                                                            pymt__Default_Currency__c,  
                                                            pymt__PP_Merchant_Id__c,
                                                            pymt__Auto_Create_Account__c,
                                                            pymt__Default_Account__c,
                                                            pymt__PaymentConnect_Setup__r.pymt__Gateway_Simulation_Mode__c 
                                                            from pymt__Processor_Connection__c where isDeleted = false 
                                                                and (pymt__processor_id__c like 'paypal' 
                                                                        or pymt__processor_id__c like 'authorize.net'
                                                                        or pymt__processor_id__c like 'google'
                                                            ) ];
            if (connections.size()>0) {
                Boolean found = false;
                for (pymt__Processor_Connection__c conn :connections) {
                    if (conn.pymt__default_connection__c) {
                        this.processor = conn;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    this.processor = connections[0];
                }
            }   
            
            
            if (this.processor == null) throw new LocalException('Error retrieving processor connection record.');
            this.processorName = this.processor.pymt__processor_id__c.toLowerCase(); // paypal, authorize.net, google
                
            // Enable/disable the recurring donations form options based on settings and supported payment processors
            if (this.processorName.equalsIgnoreCase('PayPal') || this.processorName.equalsIgnoreCase('Authorize.Net')) {
                this.showRecurring = true;
            } else {
                this.showRecurring = false;
            }
                                
                
            if (this.payment == null) {
                this.payment = new pymt__PaymentX__c();
            }
                
        } catch(Exception ex) {
            System.debug('An error was encountered setting up the donation page: '+ex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error was encountered loading the page. '+ex.getMessage()));
            this.disableForm = true;
        }
            
    }

    
    private Boolean isNullOrEmpty(String astring) {
        if (astring == null) return true;
        if (astring.trim()=='') return true;
        return false;
    }


    
    // merge differences in two contacts, save to SF and return the updated contact
    public Contact mergeContacts(Contact inSF, Contact local) {
        
        if (!isNullOrEmpty(local.mailingStreet)) inSF.mailingStreet = local.mailingStreet;
        if (!isNullOrEmpty(local.mailingCity)) inSF.mailingCity = local.mailingCity;
        if (!isNullOrEmpty(local.mailingState)) inSF.mailingState = local.mailingState;
        if (!isNullOrEmpty(local.mailingPostalCode)) inSF.mailingPostalCode = local.mailingPostalCode;
        if (!isNullOrEmpty(local.mailingCountry)) inSF.mailingCountry = local.mailingCountry;
        update inSF;
        return inSF; 
        
    } 
    
    public PageReference nullAction() {
        return null;
    }

    private Decimal retrieveDonationAmount() {
        decimal val;
        if (isNullOrEmpty(this.grf_admissionfee)){
           val=0;}
          else {
           val=Decimal.valueOf(this.grf_admissionfee.replaceall(',','')) ;}
         if (!isNullOrEmpty(this.otherDonationAmount) ) {
           val=val + Decimal.valueOf(this.otherDonationAmount.replaceall(',','')) ;}
  
  //GRF only uses other donation amount
  
  /*GRF Not Applicable
     if (isNullOrEmpty(this.selectedDonationAmount) || this.selectedDonationAmount.equalsIgnoreCase('other') ) {
        } else {
           val = this.selectedDonationAmount; }*/
   
        try {
            return val;
        } catch (Exception ex) {            
        }
        return 0;
    }

    
    public PageReference clickOtherAmount() {
        this.selectedDonationAmount = 'Other';
        return null;
    }

        
    // Search for the current visitor in Salesforce Contacts
    private Contact findContact(Contact contact) {
        Contact[] contacts = [Select id, email, account.name, firstname, lastname, mailingstreet, mailingcity, mailingstate, mailingpostalcode,
                    mailingcountry, accountId from Contact where email = :contact.email limit 5 ];
        if (contacts.size() >0) return contacts[0];
        
        return null;
    }
    
    public Boolean setupDonorRecord() {
        // find contact in SF or create new
        try {
            Contact searchResult = findContact(this.contact);
          // GRF at client request removed contact merge, put back by removing setting search result to null
            searchResult = null;
            if (searchResult <> null) {
                this.contact = mergeContacts(searchResult, this.contact);                
            } else {
                Account newAccount = new Account();
                if (this.processor.pymt__Auto_Create_Account__c  <> null) {
                    try {
                        if (this.processor.pymt__Auto_Create_Account__c.equalsIgnoreCase('Use Default Account') && 
                        isNullOrEmpty(this.contact.accountId)) {
                            this.contact.accountId = this.processor.pymt__Default_Account__c;
                        } else if ((this.processor.pymt__Auto_Create_Account__c.equalsIgnoreCase('Create Business Account') ||
                            this.processor.pymt__Auto_Create_Account__c.equalsIgnoreCase('Create Individual or Business Account')) && 
                            !isNullOrEmpty(this.companyName)) {
                            newAccount.name = this.companyName;     
                        } else if ((this.processor.pymt__Auto_Create_Account__c.equalsIgnoreCase('Create Individual Account') ||
                            this.processor.pymt__Auto_Create_Account__c.equalsIgnoreCase('Create Individual or Business Account')) && 
                            isNullOrEmpty(this.companyName)) {
                            newAccount.name = this.contact.firstname + ' '+ this.contact.lastname;
                            newAccount.pymt__Convert_To_Person_Account__c = true;
                        }

                        insert newAccount;
                        this.contact.accountId = newAccount.Id;
                    } catch (Exception ex2) {
                        // Error adding new account
                    }
                }
                insert this.contact;
            
            }
            this.fnameOnCard = this.contact.firstname;
            this.lnameOnCard = this.contact.lastname;
            this.billingStreet = this.contact.mailingStreet;        
            this.billingCity = this.contact.mailingCity;        
            this.billingState = this.contact.mailingState;      
            this.billingPostalCode = this.contact.mailingPostalCode;        
            this.billingCountry = this.contact.mailingCountry;      
            
            return true;
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR,
             'An error was encountered processing contact information. '+ex.getMessage()));
        }
        return false;
        
    }
    
    public Boolean setupDonationRecord() {  
        try {       
            // Determine donation amount 
            this.donationAmount = retrieveDonationAmount();
            
            if (this.donationAmount == 0) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select a donation amount.'));                           
                return false;
            }
            
            
            // Setup Payment record
            if (this.payment == null) {
                this.payment = new pymt__PaymentX__c();
            }
            
            this.payment.name = 'Correspondence: ' + grf_correspondenceid ;
            this.payment.pymt__amount__c = this.donationAmount;
            this.payment.pymt__contact__c = this.contact.id;
            this.payment.pymt__onpaymentcompleted_trigger__c = '';
            this.payment.pymt__status__c = 'In Process';
            this.payment.pymt__date__c = System.today();
            this.payment.pymt__payment_processor__c = this.processor.pymt__processor_id__c;
            this.payment.pymt__processor_connection__c = this.processor.id;
            this.payment.pymt__Is_Test_Transaction__c = this.processor.pymt__Test_Mode__c ||
               this.processor.pymt__PaymentConnect_Setup__r.pymt__Gateway_Simulation_Mode__c;
            this.payment.pymt__Currency_ISO_Code__c = this.processor.pymt__Default_Currency__c;
            this.payment.pymt__log__c = ' ++++ Website Donation:\n'+ 'Credit card charge for '+
                                            this.payment.pymt__Amount__c + this.payment.pymt__Currency_ISO_Code__c;
            if (this.payment.id == null) {
                insert this.payment; 
            } else {
                update this.payment;
            }
        
        
            return true;
            
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
            'An error was encountered setting up the donation record. '+ex.getMessage()));
        }
        return false;   
    } 
/*
    public pymt__Payment_Profile__c setupRecurringPaymentProfile() {
        // Determine donation amount 
        this.donationAmount = retrieveDonationAmount();
        if (this.donationAmount == 0) {
               ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select a donation amount.'));                            
            return null;
        }
                        
        String recordTypeId;
            
        try {               
            if (this.paymentProfile == null) {
                this.paymentProfile = new pymt__Payment_Profile__c();
                this.paymentProfile.pymt__Contact__c = this.contact.Id;

            }
            String period;          
            if (this.recurringPeriod == 'Monthly') period = 'Month';
            if (this.recurringPeriod == 'Annual') period = 'Year';
            Double frequency = 1;
            Double recurringAmount = this.donationAmount;
            if (this.processor.pymt__processor_id__c.equalsIgnoreCase('PayPal')){
                // Retrieve PayPal recurring payment record type to store in payment profile
                recordTypeId = [Select id from RecordType where developername like 'PayPal_Recurring_Payment'].id;
                

            } else if (this.processor.pymt__processor_id__c.equalsIgnoreCase('authorize.net')){
                // Retrieve PayPal recurring payment record type to store in payment profile

                recordTypeId = [Select id from RecordType where developername like 'AuthNet_Subscription'].id;
            
                if (period.equalsIgnoreCase('Day')) {period = 'Day'; frequency = frequency;}
                if (period.equalsIgnoreCase('Week')) { period = 'Day'; frequency = frequency * 7;}
                if (period.equalsIgnoreCase('Semi/Month')) { period = 'Day'; frequency = frequency * 15;}
                 // approximate of every half month as authnet doesn't offer semi-monthly option
                if (period.equalsIgnoreCase('Month')) {period = 'Month';frequency = frequency; }
                if (period.equalsIgnoreCase('Year')) { period = 'Month'; frequency = frequency * 12;}
                            
            } else {
                // recurring payments for this processor type not yet supported.
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
            'Current default payment processor not supported for recurring payments ('+this.processorName+').'));
                return null;                
            }

            this.paymentProfile.name = 'Recurring Donation Profile';
            this.paymentProfile.recordTypeId = recordTypeId;
            this.paymentProfile.pymt__Account__c = this.contact.accountId;
            this.paymentProfile.pymt__Processor_Connection__c = this.processor.Id;
            this.paymentProfile.pymt__Subscription_Start_Date__c = Date.today();
            this.paymentProfile.pymt__Subscription_Status__c = 'Not Activated';  // temporary status used until subscription has been activated
            this.paymentProfile.pymt__Period__c = period;
            this.paymentProfile.pymt__Frequency__c = frequency;
            this.paymentProfile.pymt__Amount__c = recurringAmount;  
            this.paymentProfile.pymt__Total_Occurrences__c = this.occurrences;                      
            
            if (this.paymentProfile.id == null) {
                insert this.paymentProfile;
            } else {
                update this.paymentProfile;
            }   
            return this.paymentProfile;
            
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error setting up payment profile. '+ex.getMessage()));

            return null;
        }       
    }
*/
    public Boolean isFormComplete() {
        Boolean complete = true;
        
        if (isNullOrEmpty(this.contact.firstname)) {    
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide your firstname.'));
            complete = false;
        }
        if (isNullOrEmpty(this.contact.lastname)) { 
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide your lastname.'));
            complete = false;
        }
        if (isNullOrEmpty(this.contact.email)) {    
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please provide an email address.'));
            complete = false;
        }
        
        if ((isNullOrEmpty(this.selectedDonationAmount) || this.selectedDonationAmount.equalsIgnoreCase('other')) 
            && isNullOrEmpty(this.otherDonationAmount)) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select or enter a donation amount.'));
            complete = false;
                
            }
            
        return complete; 
    }
    
    /*
    public PageReference payPalDonation() {
        if (!isFormComplete()) return null;
        
        try {
            if (!setupDonorRecord()) return null;           

            if (this.isRecurring){
                // Set up recurring payment profile and redirect to subscription checkout page
                this.paymentProfile = setupRecurringPaymentProfile();
                if (this.paymentProfile == null) return null;
            } else {
                // Setup single payment record and redirect to site checkout page.
                if (!setupDonationRecord()) return null;            
            
            }

            String paymentURL = '';
            if (this.isRecurring) {
                if (this.processor.pymt__Test_Mode__c) {
                    paymentURL += 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_xclick-subscriptions';            
                } else {
                    paymentURL += 'https://www.paypal.com/cgi-bin/webscr?cmd=_xclick-subscriptions';            
                }
                paymentURL += '&business='+this.processor.pymt__PP_Merchant_id__c;
                paymentURL += '&lc=US&item_name='+'Donation';
                paymentURL += '&invoice=&no_note=1&no_shipping=1&a3='+this.donationAmount;
                paymentURL += '&currency_code='+ this.processor.pymt__Default_Currency__c;
                paymentURL += '&custom='+EncodingUtil.UrlEncode('pmtxid='+this.payment.id,'UTF-8');
                String period;
                if (this.recurringPeriod == 'Monthly') period = 'M';
                if (this.recurringPeriod == 'Annual') period = 'Y';
                  
                paymentURL += '&src=1&p3=1&t3='+period;
                paymentURL += '&sra=1&bn=PP%2dSubscriptionsBF%3abtn_subscribeCC_LG%2egif%3aNonHosted';  


            } else {
                if (this.processor.pymt__Test_Mode__c) {
                    paymentURL += 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_xclick';          
                } else {
                    paymentURL += 'https://www.paypal.com/cgi-bin/webscr?cmd=_xclick';          
                }
                paymentURL += '&business='+this.processor.pymt__PP_Merchant_id__c;
                paymentURL += '&lc=US&item_name='+'Donation';
                paymentURL += '&invoice=&item_number=1&amount='+this.donationAmount;
                paymentURL += '&currency_code='+ this.processor.pymt__Default_Currency__c;
                paymentURL += '&custom='+EncodingUtil.UrlEncode('pmtxid='+this.payment.id,'UTF-8');

                paymentURL += '&bn=PP%2dBuyNowBF%3abtn_buynowCC_LG%2egif%3aNonHosted';              
        
                this.payment.pymt__log__c = ' ++++ Website Donation:\n'+ 'PayPal transaction for '+
                                    this.payment.pymt__Amount__c + this.payment.pymt__Currency_ISO_Code__c;
                update this.payment;                
            }

            PageReference pageRef =  new PageReference(paymentURL);
            pageRef.setRedirect(true);
            return pageRef;

        } catch(Exception ex) {
            System.debug('An error was encountered preparing the donation: '+ex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR,
             'An error was encountered preparing your donation. '+ex.getMessage()));
            this.disableForm = true;
        }
        
        return null;

    } End Paypal Donation*/
    
    // Create an in-process payment with related records attached and redirect to the payment processor
    /*
    public PageReference googleDonation() {
        if (isFormComplete() == false) return null;
        if (this.isRecurring) return null; // google subscription not yet supported
    
        try {
            if (!setupDonorRecord() || !setupDonationRecord()) return null;         
            
                
            String cartXML = '';
                cartXML += '<checkout-shopping-cart xmlns="http://checkout.google.com/schema/2">';
                
                cartXML += '<shopping-cart>';
                    cartXML += '<merchant-private-data>';
                        if (this.contact <> null) {
                            cartXML += '<sf-contactid>'+this.contact.Id+'</sf-contactid>';
                        }
                        if (this.contact.AccountId <> null) cartXML += '<sf-accountid>'+
                        this.contact.AccountId+'</sf-accountid>';
                        //cartXML += '<sf-opportunityid>'+opp.Id+'</sf-opportunityid>';
                        cartXML += '<pmtxid>'+this.payment.Id+'</pmtxid>';
                    cartXML += '</merchant-private-data>';
                    cartXML += '<items>';
                      cartXML += '<item>';
                        cartXML += '<item-name>Donation</item-name>';
                        cartXML += '<item-description></item-description>';
                        cartXML += '<unit-price currency="USD">'+this.donationAmount+'</unit-price>';
                        cartXML += '<quantity>1</quantity>';
                      cartXML += '</item>';
                    cartXML += '</items>';
                  cartXML += '</shopping-cart>';
                  cartXML += '<checkout-flow-support>';
                    cartXML += '<merchant-checkout-flow-support>';
                      //cartXML += '<shipping-methods>';
                      //  cartXML += '<flat-rate-shipping name="SuperShip Ground">';
                      //    cartXML += '<price currency="USD">0</price>';
                      //  cartXML += '</flat-rate-shipping>';
                      //cartXML += '</shipping-methods>';
                    cartXML += '</merchant-checkout-flow-support>';
                  cartXML += '</checkout-flow-support>';
                cartXML += '</checkout-shopping-cart>';
                    
    
            String paymentURL = EncodingUtil.urlDecode(pymt.GoogleConnector.encodedGoogleCheckoutURL(cartXML), 'UTF-8');        
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Google Checkout URL = '+paymentURL));
    
            if (paymentURL.startsWith('Error')) {
                return null;
            }
    
            this.payment.pymt__log__c = ' ++++ Website Donation:\n'+ 'Google Checkout transaction for '+
                                        this.payment.pymt__Amount__c + this.payment.pymt__Currency_ISO_Code__c;
            update this.payment;
            
            PageReference pageRef =  new PageReference(paymentURL);
            pageRef.setRedirect(true);
            return pageRef;

        } catch(Exception ex) {
            System.debug('An error was encountered preparing the donation: '+ex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
            'An error was encountered preparing your donation. '+ex.getMessage()));
            this.disableForm = true;
        }
        
        return null;

    }
     End Google Payment*/
    
    // Set up payment record for processing with Credit Card
    public PageReference creditCardDonation() {
        if (!isFormComplete()) return null;
        if (processor == null) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Configuration error.'));
            return null;    
        }

        try {
            if (!setupDonorRecord()) return null;       
            PageReference nextPage;
         /* GRF   if (this.isRecurring){
                // Set up recurring payment profile and redirect to subscription checkout page
                this.paymentProfile = setupRecurringPaymentProfile();
                if (this.paymentProfile== null) return null;
                if (this.processorName.equalsIgnoreCase('paypal')) {
                    nextPage = Page.PayPalSubscribe;    
                    nextPage.getParameters().put('ppid',this.paymentProfile.Id);
                } else  if (this.processorName.equalsIgnoreCase('authorize.net')) {
                    nextPage = Page.AuthNetSubscribe;   
                    nextPage.getParameters().put('ppid',this.paymentProfile.Id);
                } /
            } else {*/
                // Setup single payment record and redirect to site checkout page.
                if (!setupDonationRecord()) return null;            
                if (this.payment == null) {
                    throw new LocalException('Error setting up payment record.  Record is null.');
                }
                nextPage = Page.CardPayment;    
                nextPage.getParameters().put('pid',this.payment.Id);
            //}

            return nextPage;                
            

        
        } catch(Exception ex) {
            System.debug('An error was encountered preparing the donation: '+ex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR,
             'An error was encountered preparing your donation. '+ex.getMessage()));
            this.disableForm = true;
        }
        
        return null;
        
    }       


    public static testmethod void testGRF_PaymentConnectController() {
        String apexTestLabel = 'ApexTestGRF_PaymentConnectController';

        // Check to make sure settings record has been created, and PC is in Simulation Mode (to
        // prevent API callouts from being made during test method execution.
        pymt__Settings__c[] oldsettings = [ Select id, pymt__Gateway_Simulation_Mode__c
         from pymt__Settings__c where isdeleted = false ];
        if (oldsettings.size()>0) delete oldsettings;

        pymt__Settings__c settings = new pymt__Settings__c();
        settings.name = 'ApexTestSettings';
        settings.pymt__Gateway_Simulation_Mode__c = true;        
            
        insert settings;
        
        System.assert( settings.Id <> null, 'Error finding/creating settings record for test methods to use.');
        
        // Add processor connections
        pymt__Processor_Connection__c authnetConnection = new pymt__Processor_Connection__c();
            authnetConnection.name = 'ApexTestProcessorConnection1';
            authnetConnection.pymt__PaymentConnect_Setup__c = settings.id;
            authnetConnection.pymt__Auto_Create_Account__c = 'Create Individual Account';
            authnetConnection.pymt__Assigned_To_Terminal__c = true;
            authnetConnection.pymt__Processor_Id__c = 'Authorize.Net';
            authnetConnection.pymt__Authnet_Enable_Echecks__c = true;
            insert authnetConnection;
        pymt__Processor_Connection__c payPalConnection = new pymt__Processor_Connection__c();
            payPalConnection.name = 'ApexTestProcessorConnection2';
            payPalConnection.pymt__PaymentConnect_Setup__c = settings.id;
            payPalConnection.pymt__Auto_Create_Account__c = 'Create Business Account';
            payPalConnection.pymt__Assigned_To_Terminal__c = true;
            payPalConnection.pymt__Processor_Id__c = 'PayPal';
            payPalConnection.pymt__PP_Merchant_Id__c = 'ApexTestMerchantId';
            insert payPalConnection;
        pymt__Processor_Connection__c googleConnection = new pymt__Processor_Connection__c();
            googleConnection.name = 'ApexTestProcessorConnection3';
            googleConnection.pymt__PaymentConnect_Setup__c = settings.id;
            googleConnection.pymt__Processor_Id__c = 'Google';
            insert googleConnection;
                    
        // Set up a test account    
        Account[] accounts = [Select id from Account where isDeleted = false and name = :apexTestLabel ];
        if (accounts != null && accounts.size() > 0) delete accounts;
        Account account = new Account( name = apexTestLabel );
        insert account;
        
        // Set up a test contact
        Contact[] contacts = [Select id from Contact where isDeleted = false and lastname = :apexTestLabel];
        if (contacts != null && contacts.size() > 0) delete contacts;
        Contact contact = new Contact(firstname = 'Joey', 
                                      lastname = apexTestLabel,
                                      mailingstreet = '123 Oak Street',
                                      mailingcity = 'Encinitas',
                                      mailingstate = 'CA',
                                      mailingpostalcode = '92024',
                                      otherstreet = '456 Test Street',
                                      othercity = 'Encinitas',
                                      otherstate = 'CA',
                                      otherpostalcode = '92024',
                                      accountId = account.id,
                                      email = apexTestLabel+'@apextest.com'
                                      );
        insert contact;
        
        Contact dupecontact = new Contact(firstname = 'Joe', 
                                      lastname = apexTestLabel,
                                      mailingstreet = '123 Test Street',
                                      mailingcity = 'Encinitas',
                                      mailingstate = 'CA',
                                      mailingpostalcode = '92024',
                                      otherstreet = '456 Test Street',
                                      othercity = 'Encinitas',
                                      otherstate = 'CA',
                                      otherpostalcode = '92024',
                                      accountId = account.id,
                                      email = apexTestLabel+'@apextest.com'
                                      );
            
                Contact brandnewContact = new Contact(firstname = 'Joe', 
                                      lastname = apexTestLabel,
                                      mailingstreet = '123 Test Street',
                                      mailingcity = 'Encinitas',
                                      mailingstate = 'CA',
                                      mailingpostalcode = '92024',
                                      otherstreet = '456 Test Street',
                                      othercity = 'Encinitas',
                                      otherstate = 'CA',
                                      otherpostalcode = '92024',
                                      accountId = account.id,
                                      email = apexTestLabel+'_new@apextest.com'
                                      );
                                      
                                        
                 
        // Create an instance of the donationpage controller
        ApexPages.StandardController stdController;
        GRF_PaymentConnectController controller;

        // Scenario 1 - No campaign record Id (test error handling)
        controller = new GRF_PaymentConnectController();
    
        // Scenario 2 - Authnet credit card donation
        controller = new GRF_PaymentConnectController();

            System.assert(controller.retrieveDonationAmount()==0);  // test with valid values
           // controller.setupRecurringPaymentProfile(); // test error handling path (no donation amount)
            controller.setupDonationRecord(); // test error handling path (no donation amount)
    
            
            System.assert(controller.findContact(brandNewContact)==null,'Expected a null respond from findContact (for a new contact)');
            

        // Simulate entry of contact and creditcard information 
        controller.contact.firstname = 'Joe';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'@apextest.com';
        controller.contact.mailingstreet = '134 Torrey Pines Rd';
        controller.contact.mailingcity = 'Del Mar';
        controller.contact.mailingstate = 'CA';
        controller.contact.mailingpostalcode = '92021';
        controller.contact.mailingcountry = 'US';
                
        controller.nullAction();
        
        controller.selectedDonationAmount ='5';
        controller.retrieveDonationAmount();
        controller.otherDonationAmount = '7';
        controller.clickOtherAmount();
        System.assert(controller.retrieveDonationAmount() ==7); 
        
        controller.creditCardDonation();  // Call with incomplete card info.
        
        // Scenario 4 - AuthNet recurring credit card donation
        authNetConnection.pymt__Default_Connection__c = true;
        update authNetConnection;
        controller = new GRF_PaymentConnectController();
    
        controller.contact.firstname = 'Joe';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'@apextest.com';
                
        controller.selectedDonationAmount ='5';
        controller.isRecurring = true;

        controller.creditCardDonation();    
    
        // Scenario 2 - PayPal credit card donation
        payPalConnection.pymt__Default_Connection__c = true;
        update payPalConnection;
        controller = new GRF_PaymentConnectController();
    
        controller.isFormComplete(); 
        controller.contact.firstname = 'Joe';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'@apextest.com';
        controller.companyName = 'Acme';
                
        controller.selectedDonationAmount ='5';

        controller.creditCardDonation();        



        // Scenario 3 - PayPal one time donation
        payPalConnection.pymt__Default_Connection__c = true;
        update payPalConnection;
        controller = new GRF_PaymentConnectController();
    
        controller.contact.firstname = 'Joe';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'@apextest.com';
                
        controller.selectedDonationAmount ='5';

      // GRF  controller.payPalDonation();        

        // Scenario 4 - PayPal recurring donation
        payPalConnection.pymt__Default_Connection__c = true;
        update payPalConnection;
        controller = new GRF_PaymentConnectController();
    
        controller.contact.firstname = 'Joe';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'@apextest.com';
                
        controller.selectedDonationAmount ='5';
        controller.isRecurring = true;

       // GRF controller.payPalDonation();        

        // Scenario 5 - Google one time donation
        googleConnection.pymt__Default_Connection__c = true;
        update googleConnection;
        controller = new GRF_PaymentConnectController();

        controller.contact.firstname = 'Peter';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'2@apextest.com';  // new contact
                
        controller.selectedDonationAmount ='5';

       // controller.googleDonation();        

        // Scenario 6 - Test setupDonorRecord with new contact and company name with settings set to 'Create Business Account'
        payPalConnection.pymt__Default_Connection__c = true;
        update payPalConnection;
        controller = new GRF_PaymentConnectController();
    
        controller.contact.firstname = 'Jerry';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'_newWithBusiness@apextest.com';
        controller.companyName = 'Acme';
                
        controller.otherDonationAmount ='5';
        controller.setupDonorRecord();


        // Scenario 7 - Test setupDonorRecord with new contact and no company name with settings set to 'Create Individual Account'
        authNetConnection.pymt__Default_Connection__c = true;
        update authNetConnection;
        controller = new GRF_PaymentConnectController();
    
        controller.contact.firstname = 'Samantha';
        controller.contact.lastname = apexTestLabel;
        controller.contact.email = apexTestLabel+'_newWithoutBusiness@apextest.com';
        controller.companyName = '';
                
        controller.otherDonationAmount ='5';
        controller.setupDonorRecord();
    }

                
}