public class CardPaymentController {


    public String paymentId {get;set;}
    public pymt__PaymentX__c payment {get;set;}
    
    public pymt__Settings__c settings{get;set;}
    public String processorConnectionId{get;set;}

    public pymt__Processor_Connection__c processor{get;set;}
    public pymt__Shopping_Cart_Item__c[] cartItems {get;set;}
    public contact checkoutContact {get;set;}

    public List<SelectOption> ccTypeOptions;
    private List<SelectOption> expMonthOptions;
    private List<SelectOption> expYearOptions;

    // Purchase amount values
    public Decimal preTaxAmount {get;set;}
    public Decimal shippingAmount {get;set;}
    public Decimal handlingAmount {get;set;}
    public Decimal totalAmount {get;set;}
    public String invoiceNumber {get;set;}
    
    // Address fields
    public String billingstreet {get;set;}
    public String billingcity {get;set;}
    public String billingstate {get;set;}
    public String billingpostalcode {get;set;}
    public String billingcountry {get;set;}

    // Credit Card fields
    public String fnameOnCard {get;set;}
    public String lnameOnCard {get;set;}
    public String creditCardNumber {get;set;}
    public String expirationMonth {get;set;} // Month part of expiration date
    public String expirationYear {get;set;}  // Year part of expiration date
    public String cardType {get;set;}   
    public String cvv {get;set;}
    
    // Process control vars
    public String submitStatus {get;set;}
    public Boolean disableForm {get;set;}

    // Layout and formatting controls
    public String bannerImage {get;set;}
    public String bannerImageId {get;set;}
    
        
    public class LocalException extends Exception {}    
    
    public CardPaymentController() {
        
        try {
            // Retrieve and process URL parameters (pid, cid, aid, pcid, address fields, finishURL, cancelURL, )
            this.processorConnectionId = ApexPages.currentPage().getParameters().get('pcid');
            this.paymentId = ApexPages.currentPage().getParameters().get('pid');    
    
    
            if (isNullOrEmpty(paymentId)) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error retrieving payment details.  Parameters missing.'));
                this.disableForm = true;
                return;         
            }
            
                   
            // Get paymentconnect settings (general settings)
            try {
                this.settings = [Select p.pymt__Tax__c, p.pymt__Gateway_Simulation_Mode__c, p.pymt__Admin_User__c, p.Name, p.Id 
                From pymt__Settings__c p where isDeleted = false ];
            } catch (Exception ex) {    
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading settings.  Please check to make sure a PaymentConnect settings object has been created.'));
                return; 
            }
    
            // Retrieve "In Process" Payment Record
            try {
                this.payment = [Select name, pymt__Currency_ISO_Code__c, pymt__Amount__c,
                                                pymt__Tax__c,
                                                pymt__Contact__c,
                                                pymt__status__c,
                                                pymt__Ship_To_Name__c,
                                                pymt__Ship_To_Street__c,
                                                pymt__Ship_To_City__c,
                                                pymt__Ship_To_State__c,
                                                pymt__Ship_To_Postal_Code__c,
                                                pymt__Ship_To_Country__c,
                                                pymt__Ship_To_Company__c,
                                                pymt__Ship_To_Phone__c,
                                                pymt__Contact__r.name,
                                                pymt__Contact__r.firstname,
                                                pymt__Contact__r.lastname,
                                                pymt__Contact__r.mailingStreet,
                                                pymt__Contact__r.mailingCity,
                                                pymt__Contact__r.mailingState,
                                                pymt__Contact__r.mailingPostalCode,
                                                pymt__Contact__r.mailingCountry,
                                                pymt__processor_connection__c,
                                                pymt__payment_processor__c,
                                                pymt__Is_Test_Transaction__c from pymt__PaymentX__c where id = :paymentId and isDeleted = false ];
                    this.checkoutContact = [Select id, name, firstname, lastname, mailingStreet, mailingCity, mailingState, mailingPostalCode, mailingcountry, email, phone, fax from Contact where id = :this.payment.pymt__Contact__c and isDeleted = false];
                    this.processorConnectionId = pymt.Util.assignIfNotEmpty(this.processorConnectionId, this.payment.pymt__processor_connection__c);
                    System.debug(this.payment);
            } Catch (Exception ex) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading payment record details.'));     
            }   
    
            if (this.payment == null) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: No payment record found.  Please contact the system administrator.'));     
                this.disableForm = true;
                return;
            }
    
            
            if (this.payment.pymt__status__c.equalsIgnoreCase('Completed') || this.payment.pymt__status__c.equalsIgnoreCase('Charged')) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This payment record has already been processed.'));       
                this.disableForm = true;
                return;
            }
    
            // Get processor connection settings (processor details)
            // if not specified, retrieves the first avail paypal or authnet processor connection
            try {
                pymt__Processor_Connection__c[] connections = [Select id, pymt__default_connection__c, 
                                                        pymt__processor_id__c, 
                                                        pymt__test_mode__c, 
                                                        pymt__enabled_card_types__c 
                                                        from pymt__Processor_Connection__c where isdeleted = false 
                                                        and (pymt__Processor_Id__c like 'PayPal' or pymt__Processor_Id__c like 'Authorize.net') ];
                if (connections.size() >0) {
                    for (pymt__Processor_Connection__c connection :connections) {
                        if (isNullOrEmpty(this.processorConnectionId) ) {
                            this.processor = connection;
                            break;
                        } else {
                            if (connection.id == this.processorConnectionId) {
                                this.processor = connection;
                            }
                        }
                    }   
                }       
                if (this.processor == null) {
                    ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading settings.  Please check to make sure a PaymentConnect processor connection object has been created.'));
                    
                }
            } catch (Exception ex) {    
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading settings.  Please check to make sure a PaymentConnect processor connection object has been created.'));
                return; 
            }       
    
            if (this.processor == null) {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: No processor connection found.  Please contact the system administrator.'));       
                this.disableForm = true;
                return;
            }
    
            
            // Retrieve contact information
            
            if (this.checkoutContact <> null) {                 
                this.billingstreet = this.checkoutContact.mailingstreet;
                this.billingcity = this.checkoutContact.mailingcity;
                this.billingstate = this.checkoutContact.mailingstate;
                this.billingpostalcode = this.checkoutContact.mailingpostalcode;
                this.billingcountry = this.checkoutContact.mailingcountry;
                            
                this.fnameOnCard = this.checkoutContact.firstname;
                this.lnameOnCard = this.checkoutContact.lastname;
            }
            
            // Setup page defaults
            this.expirationMonth = '01'; 
            this.expirationYear = ''+(Date.today().year()+1);
            
            this.submitStatus = 'ready';
        
        } catch(Exception ex) {
            System.debug('An error was encountered setting up the checkout page: '+ex);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error was encountered loading the page. '+ex.getMessage()));
            this.disableForm = true;
        }       
    }
    
    public Boolean getHasCartItems() {
        pymt__Shopping_Cart_Item__c[] cartItems = getAttachedCartItems();
        if (cartItems <> null && cartItems.size()>0) return true;
        return false;   
    }
    
    // Retrieve shopping cart items for the current payment record
    public pymt__Shopping_Cart_Item__c[] getAttachedCartItems() {
        if (this.cartItems <> null) return this.cartItems;
        
        if (this.checkoutContact <> null) {
            this.cartItems = [Select Id, Name, CreatedDate, LastModifiedDate, 
                                        pymt__Contact__c, 
                                        pymt__Lead__c, 
                                        pymt__On_Payment_Completed__c, 
                                        pymt__Payment_Completed__c, 
                                        pymt__Payment__c, 
                                        pymt__Product_Code__c, 
                                        pymt__Product__c, 
                                        pymt__Quantity__c, 
                                        pymt__Unit_Price__c 
                                        From pymt__Shopping_Cart_Item__c where pymt__Payment__c = :this.paymentId and isdeleted = false ];
            return this.cartItems;  
        }
        return null;
    }
    
    // Expiration Month select options
    public List<SelectOption> getExpMonthOptions() {
        if (this.expMonthOptions == null) {
        this.expMonthOptions = new List<SelectOption>(); 
        this.expMonthOptions.add(new SelectOption('01','Jan')); 
        this.expMonthOptions.add(new SelectOption('02','Feb')); 
        this.expMonthOptions.add(new SelectOption('03','Mar')); 
        this.expMonthOptions.add(new SelectOption('04','Apr')); 
        this.expMonthOptions.add(new SelectOption('05','May')); 
        this.expMonthOptions.add(new SelectOption('06','Jun')); 
        this.expMonthOptions.add(new SelectOption('07','Jul')); 
        this.expMonthOptions.add(new SelectOption('08','Aug')); 
        this.expMonthOptions.add(new SelectOption('09','Sep')); 
        this.expMonthOptions.add(new SelectOption('10','Oct')); 
        this.expMonthOptions.add(new SelectOption('11','Nov')); 
        this.expMonthOptions.add(new SelectOption('12','Dec')); 
        }
        return this.expMonthOptions; 
    }   

    // Expiration Year select options
    public List<SelectOption> getExpYearOptions() {
        if (this.expYearOptions == null) {
            this.expYearOptions = new List<SelectOption>();
            Integer thisYear = Date.today().year();
            for (integer i=0;i<15;i++) {
                String yearString = ''+(thisYear+i);
                this.expYearOptions.add(new SelectOption(yearString,yearString));
            } 
        }
        return this.expYearOptions; 
    }       

        
    // Credit Card type select list options
    public List<SelectOption> getCardTypeOptions() {
        if (this.processor == null) return null;
        List<SelectOption> options = new List<SelectOption>(); 
        if (isNullOrEmpty(this.processor.pymt__enabled_card_types__c)) {
            options.add(new SelectOption('Visa','Visa')); 
            options.add(new SelectOption('MasterCard','MasterCard')); 
            options.add(new SelectOption('Discover','Discover')); 
            options.add(new SelectOption('Amex','Amex')); 
            //options.add(new SelectOption('Maestro','Maestro')); 
            //options.add(new SelectOption('Solo','Solo')); 
        } else {
            String[] cardTypes = this.processor.pymt__enabled_card_types__c.split(';',-1);
            if (cardTypes.size()>0) {
                for (String cardType :cardTypes) {
                    options.add(new SelectOption(cardType,cardType));       
                }
            
            }       
        }    
        return options; 
    }   
        

    public PageReference processTransaction() {
        
        pymt.PaymentX.TransactionResultExt result;
        Boolean authorizeOnlyFlag = false;
        String description = 'Website Payment';
        String customerIP = getPtlIPAddress();
        String companyName = '';
        
        try {
        
            if (this.processor.pymt__processor_id__c.equalsIgnoreCase('PayPal')) {

                pymt.PayPalAPI.CustomerInfo customerInfo = new pymt.PayPalAPI.CustomerInfo();
                customerInfo.firstname = this.checkoutContact.firstname;
                customerInfo.lastname = this.checkoutContact.lastname;
                customerInfo.address = this.billingstreet;
                customerInfo.city = this.billingcity;
                customerInfo.state = this.billingstate;
                customerInfo.country = pymt.Util.convertCountryToISO(this.billingcountry); 
                customerInfo.postalcode = this.billingpostalcode;
                customerInfo.customerIP = getPtlIPAddress();
                
            
                pymt.PayPalAPI.ShippingInfo shippingInfo = new pymt.PayPalAPI.ShippingInfo();
                if (!isNullOrEmpty(this.payment.pymt__Ship_To_Street__c) && !isNullOrEmpty(this.payment.pymt__Ship_To_Name__c)){
                    shippingInfo.firstname = getFirstName(this.payment.pymt__Ship_To_Name__c);
                    shippingInfo.lastname = getLastName(this.payment.pymt__Ship_To_Name__c);
                    shippingInfo.company = this.payment.pymt__Ship_To_Company__c;
                    shippingInfo.address = this.payment.pymt__Ship_To_Street__c;
                    shippingInfo.city = this.payment.pymt__Ship_To_City__c;
                    shippingInfo.state = this.payment.pymt__Ship_To_State__c;
                    shippingInfo.postalcode = this.payment.pymt__Ship_To_Postal_Code__c;
                    shippingInfo.country = pymt.Util.convertCountryToISO(this.payment.pymt__Ship_To_Country__c);
                    shippingInfo.phone = this.payment.pymt__Ship_To_Phone__c;
                }
                
                pymt.PayPalAPI.LineItemInfo lineItems = null;
            
                result = pymt.PayPalConnector.chargeCreditCard(
                    description,
                    this.payment.pymt__amount__c,
                    this.payment.Id,
                    this.invoiceNumber,
                    customerInfo,
                    shippingInfo,
                    this.creditCardNumber,
                    this.cardType,
                    this.expirationMonth+this.expirationYear,
                    this.cvv,
                    lineItems,
                    this.preTaxAmount,
                    this.shippingAmount,
                    this.payment.pymt__Tax__c,
                    this.handlingAmount,
                    authorizeOnlyFlag
                    );
                    
            } else if (this.processor.pymt__processor_id__c.equalsIgnoreCase('authorize.net')) {
                
                Boolean emailCustomer = false;
                String authCode;
                Boolean taxExempt = false;
                String authenticationIndicator;
                String cardholderAuthValue;
                String poNumber;
            
                pymt.AuthNetAimAPI.CustomerInfo customerInfo = new pymt.AuthNetAimAPI.CustomerInfo();
                customerInfo.firstname = this.checkoutContact.firstname;
                customerInfo.lastname = this.checkoutContact.lastname;
                customerInfo.address = this.billingstreet;
                customerInfo.city = this.billingcity;
                customerInfo.state = this.billingstate;
                customerInfo.country = this.billingcountry;
                customerInfo.postalcode = this.billingpostalcode;
                customerInfo.customerIP = getPtlIPAddress();

                pymt.AuthNetAimAPI.ShippingInfo shippingInfo = new pymt.AuthNetAimAPI.ShippingInfo();
                
                shippingInfo.firstname = getFirstName(this.payment.pymt__Ship_To_Name__c);
                shippingInfo.lastname = getLastName(this.payment.pymt__Ship_To_Name__c);
                shippingInfo.company = this.payment.pymt__Ship_To_Company__c;
                shippingInfo.address = this.payment.pymt__ship_to_street__c;
                shippingInfo.city = this.payment.pymt__ship_to_city__c;
                shippingInfo.state = this.payment.pymt__ship_to_state__c;
                shippingInfo.postalcode = this.payment.pymt__ship_to_postal_code__c;
                shippingInfo.country = this.payment.pymt__ship_to_country__c;
                shippingInfo.phone = this.payment.pymt__Ship_To_Phone__c;
                            
                result = pymt.AuthNetConnector.chargeCreditCard(
                    description,
                    this.payment.pymt__amount__c,
                    this.payment.Id,
                    this.invoiceNumber,
                    poNumber,
                    emailCustomer,
                    customerInfo,
                    shippingInfo,
                    this.creditCardNumber,
                    this.expirationMonth+this.expirationYear,
                    this.cvv,
                    authCode,
                    taxExempt,
                    authenticationIndicator,
                    cardholderAuthValue,
                    authorizeOnlyFlag
                );
        
            System.debug('===> result: '+ result);
            
            } else {
                // unsupported processor type...
                return null;    
            }
    
            if (result == null) throw new LocalException('Null return value from charge card request.');
                
            String transResult = result.transResult;
            if (transResult == null) transResult = '';
            if (result.pxSuccess) {
                if (result.transResult.equalsIgnoreCase('Success') || result.transResult.equalsIgnoreCase('SuccessWithWarning')) {

                    if (result.transResult.equalsIgnoreCase('Success')) {
                        ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Payment accepted.'));   
                    } else {
                        ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Transaction completed with warning(s): '+result.transMessage)); 
                    }
                    this.submitStatus = 'completed';

                } else {
                    ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Transaction failed: '+result.transMessage));                  
                    this.submitStatus = 'failed';
                }
        
            
            } else {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Request failed: '+result.pxMessage));         
                this.submitStatus = 'failed';
            }
        
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error processing transaction: '+ex.getMessage()));            
            this.submitStatus = 'failed';
        }   
        return null;
    }

    public String getFirstName(String name) {
        if (isNullOrEmpty(name)) return '';
        String[] parts = name.split(' ', -1);
        if (parts.size()>1) return parts[0].trim();
        return '';  
        
    }   
    
    public String getLastName(String name) {
        if (isNullOrEmpty(name)) return '';
        String[] parts = name.split(' ', -1);
        String lastname = '';
        if (parts.size()>1) {
            parts[0] = '';  // clear firstname
            for (String part :parts) {
                lastname += part.trim() + ' ';
            }
            lastname = lastname.trim();
        }
        
        return lastname;    
        
    }   

    
    // Returns IP address of current user.
    public String getPtlIPAddress(){
        string ipAddress;
        if (isNullOrEmpty(ipAddress)){
            ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        }
        return ipAddress;
    }   
    
    private Boolean isNullOrEmpty(String astring) {
        if (astring == null) return true;
        if (astring.trim()=='') return true;
        return false;
    }
    
    public PageReference cancelTransaction() {
        PageReference cancelPage = Page.Donation;
        return cancelPage;
    
    }
    
    public PageReference finishTransaction() {
        PageReference finishPage = Page.Donation;
        return finishPage;
    
    }
    

    public static testmethod void testSiteCheckoutPageController() {
        // Check to make sure settings record has been created, and PC is in Simulation Mode (to
        // prevent API callouts from being made during test method execution.
        pymt__Settings__c[] oldsettings = [ Select id, pymt__Gateway_Simulation_Mode__c from pymt__Settings__c where isdeleted = false ];
        if (oldsettings.size()>0) delete oldsettings;

        pymt__Settings__c settings = new pymt__Settings__c();
        settings.name = 'ApexTestSettings';
        settings.pymt__Gateway_Simulation_Mode__c = true;        
            
        insert settings;
        
        System.assert( settings.Id <> null, 'Error finding/creating settings record for test methods to use.');
        
        // Add processor connections
        pymt__Processor_Connection__c connection1 = new pymt__Processor_Connection__c(
                name = 'ApexTestProcessorConnection1',
                pymt__PaymentConnect_Setup__c = settings.id,
                pymt__Assigned_To_Terminal__c = true,
                pymt__Processor_Id__c = 'Authorize.Net',
                pymt__Enabled_Card_Types__c = 'Visa;Mastercard',
                pymt__Authnet_Enable_Echecks__c = true);
            Database.SaveResult sr =    Database.insert(connection1);
            System.assert(sr.isSuccess(), 'Error inserting test processor connection object. '+sr);     
        pymt__Processor_Connection__c connection2 = new pymt__Processor_Connection__c(
                name = 'ApexTestProcessorConnection2',
                pymt__PaymentConnect_Setup__c = settings.id,
                pymt__Assigned_To_Terminal__c = true,
                pymt__Processor_Id__c = 'PayPal',
                pymt__Authnet_Enable_Echecks__c = false);
            sr =    Database.insert(connection2);
            System.assert(sr.isSuccess(), 'Error inserting test processor connection object: '+sr);     
            
        // Retrieve a closed/won stage
        String stagename = [Select o.MasterLabel, o.IsClosed, o.IsActive From OpportunityStage o where o.IsClosed = true limit 1].MasterLabel;
        
        String apexTestLabel = 'ApexTestSiteCheckoutPageController';
        
        Account[] accounts = [Select id from Account where isDeleted = false and name = :apexTestLabel ];
        if (accounts != null && accounts.size() > 0) delete accounts;
        Account account = new Account( name = apexTestLabel, BillingState = 'CA' );
        insert account;
         
        Contact[] contacts = [Select id from Contact where isDeleted = false and lastname = :apexTestLabel];
        if (contacts != null && contacts.size() > 0) delete contacts;
        Contact contact = new Contact(firstname = 'Albert', 
                                      lastname = apexTestLabel,
                                      mailingstreet = '123 Test Street',
                                      mailingcity = 'Encinitas',
                                      mailingstate = 'CA',
                                      mailingpostalcode = '92024',
                                      otherstreet = '456 Test Street',
                                      othercity = 'Encinitas',
                                      otherstate = 'CA',
                                      otherpostalcode = '92024',
                                      accountId = account.id
                                      );
        insert contact;

        String oppName = apexTestLabel+'Opp';
        Opportunity[] opps = [Select id from Opportunity where isDeleted = false and name = :oppName];
        if (opps != null && opps.size() > 0) delete opps;
        Opportunity newOpp = new Opportunity(name = oppName,
                                            closedate = System.today(),
                                            stagename = stagename,
                                            amount = 450.00
                                            );
        insert newOpp;
         
        pymt__PaymentX__c payment1 = new pymt__PaymentX__c(name = apexTestLabel,
                                                 pymt__amount__c = 450,
                                                 pymt__date__c = Date.today(),
                                                 pymt__status__c = 'In Process',
                                                 pymt__contact__c = contact.Id,
                                                 pymt__account__c = account.Id,
                                                 pymt__opportunity__c = newOpp.Id,
                                                 pymt__payment_processor__c = 'PayPal');
                                                 
        insert payment1;
        
        pymt__PaymentX__c payment2 = new pymt__PaymentX__c(name = apexTestLabel,
                                                 pymt__amount__c = 450,
                                                 pymt__date__c = Date.today(),
                                                 pymt__status__c = 'In Process',
                                                 pymt__contact__c = contact.Id,
                                                 pymt__account__c = account.Id,
                                                 pymt__opportunity__c = newOpp.Id,
                                                 pymt__processor_connection__c = connection2.id,
                                                 pymt__payment_processor__c = 'PayPal',
                                                 pymt__ship_to_name__c = 'Albert '+apexTestLabel,
                                                 pymt__ship_to_street__c = '123 Oak',
                                                 pymt__ship_to_city__c = 'Encinitas',
                                                 pymt__ship_to_state__c = 'CA',
                                                 pymt__ship_to_postal_code__c = '93034',
                                                 pymt__ship_to_country__c = 'US'
                                                 );
                                                 
        insert payment2;
        
        pymt__PaymentX__c completedPayment = new pymt__PaymentX__c(name = apexTestLabel,
                                                 pymt__amount__c = 450,
                                                 pymt__date__c = Date.today(),
                                                 pymt__status__c = 'Completed',
                                                 pymt__contact__c = contact.Id,
                                                 pymt__account__c = account.Id,
                                                 pymt__opportunity__c = newOpp.Id,
                                                 pymt__processor_connection__c = connection2.id,
                                                 pymt__payment_processor__c = 'PayPal',
                                                 pymt__ship_to_name__c = 'Albert '+apexTestLabel,
                                                 pymt__ship_to_street__c = '123 Oak',
                                                 pymt__ship_to_city__c = 'Encinitas',
                                                 pymt__ship_to_state__c = 'CA',
                                                 pymt__ship_to_postal_code__c = '93034',
                                                 pymt__ship_to_country__c = 'US'
                                                 );
                                                 
        insert completedPayment;
        
        pymt__Shopping_Cart_Item__c[] oldItems = [select id from pymt__Shopping_Cart_Item__c where isDeleted = false and name like :(apexTestLabel+'%')];
        if (oldItems.size()>0) delete oldItems;
        pymt__Shopping_Cart_Item__c[] cart_items = new pymt__Shopping_Cart_Item__c[]{};
        cart_items.add(new pymt__Shopping_Cart_Item__c(name = apexTestLabel+'_item1',
                                                        pymt__quantity__c = 1, 
                                                        pymt__unit_Price__c=3.45, 
                                                        pymt__product_code__c='1234', 
                                                        pymt__payment__c = payment2.id, 
                                                        pymt__contact__c = contact.id));
        cart_items.add(new pymt__Shopping_Cart_Item__c(name = apexTestLabel+'_item2',
                                                        pymt__quantity__c = 1, 
                                                        pymt__unit_Price__c=5.55, 
                                                        pymt__product_code__c='1235', 
                                                        pymt__payment__c = payment2.id, 
                                                        pymt__contact__c = contact.id));
        Database.SaveResult[] sr1 = Database.insert(cart_items);
        System.assert(sr1[0].isSuccess(), 'Error inserting test shopping cart items.');
        
        pymt__PaymentX__c payment3 = new pymt__PaymentX__c(name = apexTestLabel,
                                                 pymt__amount__c = 450,
                                                 pymt__date__c = Date.today(),
                                                 pymt__status__c = 'In Process',
                                                 pymt__contact__c = contact.Id,
                                                 pymt__account__c = account.Id,
                                                 pymt__opportunity__c = newOpp.Id,
                                                 pymt__processor_connection__c = connection1.id,
                                                 pymt__payment_processor__c = 'Authorize.Net',
                                                 pymt__ship_to_name__c = 'Albert '+apexTestLabel,
                                                 pymt__ship_to_street__c = '123 Oak',
                                                 pymt__ship_to_city__c = 'Encinitas',
                                                 pymt__ship_to_state__c = 'CA',
                                                 pymt__ship_to_postal_code__c = '93034',
                                                 pymt__ship_to_country__c = 'US'
                                                 );
                                                 
        insert payment3;
        
        CardPaymentController controller;                                                

        // Provoke error for not specifying payment record id...
        controller = new CardPaymentController();
        System.assert(controller.disableForm == true, 'Expected form to be disabled after passing in NULL payment record Id parameter.');
                 
        // Try again passing related items as parameters
        pymt__PaymentX__c payment = new pymt__PaymentX__c();        
        ApexPages.currentPage().getParameters().put('oid',newOpp.Id);
        ApexPages.currentPage().getParameters().put('aid',account.Id);
        ApexPages.currentPage().getParameters().put('cid',contact.Id);
        ApexPages.currentPage().getParameters().put('pid',payment1.Id);
        controller = new CardPaymentController();

        ApexPages.currentPage().getParameters().put('pid',payment2.Id);
        controller = new CardPaymentController();

        controller.getExpMonthOptions();
        controller.getExpYearOptions();
        
        pymt__Shopping_Cart_Item__c[] items = controller.getAttachedCartItems();
        System.assert(items.size()==2,'Expected to retrieve 2 cart items from payment record.');

        System.assert (controller.getFirstName('Bob Smith')=='Bob', 'Error parsing firstname out of name string');
        System.assert (controller.getLastName('Bob Smith')=='Smith', 'Error parsing lastname out of name string');
        System.assert (controller.getLastName('Bob van Smith')=='van Smith', 'Error parsing lastname out of name string');
        
        List<SelectOption> cardTypeOptions = controller.getCardTypeOptions();
        System.assert (cardTypeOptions.size() > 0, 'Card type select list options could not be found');
        
            
        // Run a test card using the PayPal processor connection
        controller.cardType = 'Visa';
        controller.creditCardNumber = '4111111111111111';
        controller.expirationMonth = '12';
        controller.expirationYear = ''+(Date.today().year() + 1);
        controller.cvv = '123';
        PageReference result =  controller.processTransaction(); 

        // Run a test card using the Authnet processor connection
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('pid',payment3.Id);
        controller = new CardPaymentController();
        controller.cardType = 'Visa';
        controller.creditCardNumber = '4111111111111111';
        controller.expirationMonth = '12';
        controller.expirationYear = ''+(Date.today().year() + 1);
        controller.cvv = '123';
        result =    controller.processTransaction(); 

        // Make sure enabled_card_types setting on connection2 is honored.
        System.assert(controller.getCardTypeOptions().size()==2,'Expected card type options list to contain only 2 card types.');
        
        // Try to load an already completed transaction
        ApexPages.currentPage().getParameters().clear();
        ApexPages.currentPage().getParameters().put('pid',completedPayment.Id);
        controller = new CardPaymentController();
        System.assert(controller.disableForm == true, 'Expected form to be disabled after passing in a "Completed" payment record.');
        
    }

    
}