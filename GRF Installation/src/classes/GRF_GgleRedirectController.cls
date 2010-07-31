public with sharing class GRF_GgleRedirectController {
     public String strItem1Name {get;set;}
     public String strItem1Desc {get;set;}   
     public String strItem1Quantity {get;set;}  
     public String strItem1Price {get;set;}    
     public String strItem2Name {get;set;}
     public String strItem2Desc {get;set;}
     public String strItem2Price {get;set;}
     public String strItem2Quantity {get;set;}   
     
    

    public GRF_GgleRedirectController() {   
       strItem1Name = ApexPages.currentPage().getParameters().get('item_name_1');
       strItem1Desc = ApexPages.currentPage().getParameters().get('item_desc_1');
       strItem1Quantity = ApexPages.currentPage().getParameters().get('item_quantity_1');
       strItem1Price = ApexPages.currentPage().getParameters().get('item_price_1');
       strItem2Name = ApexPages.currentPage().getParameters().get('item_name_2');
       strItem2Desc = ApexPages.currentPage().getParameters().get('item_desc_2');
       strItem2Quantity = ApexPages.currentPage().getParameters().get('item_quantity_2');
       strItem2Price = ApexPages.currentPage().getParameters().get('item_price_2');    
       

    }//end GoogleRedirectController
     public static testmethod void testGoogleRedirectControllerV1() {
         GRF_GgleRedirectController g = new GRF_GgleRedirectController();
     }
}