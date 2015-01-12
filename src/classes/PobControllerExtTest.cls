/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class PobControllerExtTest {
	
	private static final Integer NUMBER_OF_LOTS = 12;
	private static final String PEARS = 'Pears';
	private static final String ORANGES = 'Oranges';
	private static final Integer NUMBER_OF_LOTS_ORANGES = 5;
	private static final Integer NUMBER_OF_LOTS_PEARS = 7;
	private static final Integer EXPECTED_PAGES_ORANGES_AND_PEARS = 3;
	private static final Integer EXPECTED_PAGES_ORANGES_ONLY = 1;
	private static final Integer EXPECTED_PAGES_PEARS_ONLY = 2;
	private static final Decimal TEST_ORDER_BUDGET = 150000;

	static testMethod void testAccess() {
		
	}
	
	static testMethod void testValidation() {
		
	}
	
	static testMethod void testFilter() {
		
		// Setup data
		Account myAccount = TestDataFactory.createAccount();
    	List<Lot__c> lotsOfPears = TestDataFactory.createLots(PEARS, NUMBER_OF_LOTS_PEARS);
    	List<Lot__c> lotsOfOranges = TestDataFactory.createLots(ORANGES, NUMBER_OF_LOTS_ORANGES);
    	insert myAccount;
    	insert lotsOfPears;
    	insert lotsOfOranges;
		
		// Create controller    	
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
		ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	// Test picklist values are loaded
    	List<SelectOption> options = ce.getFilterValues();
    	System.assertEquals(true, options.size()>0, 'Options expected in the filter picklist');
    	
    	
    	/* 	TEST CASE #1 
    		By default filter must be OFF
    		Check number of pages, products count for each category
		============================================================================ */
    	System.assertEquals(EXPECTED_PAGES_ORANGES_AND_PEARS, ce.getNumberOfPages(), 'Inconsistent number of pages when filter is OFF');
    	Integer orangesCount = 0, pearsCount = 0;
    	for (Integer i=0; i<ce.getNumberOfPages(); i++) {
    		System.assertNotEquals(0, ce.wrappers.size(), 'Empty pages detected when filter is OFF'); 
    		for (PobControllerExt.Wrapper w:ce.wrappers) {
    			if (w.product.Product_Category__c == PEARS) {
    				pearsCount++;
    			}
    			if (w.product.Product_Category__c == ORANGES) {
    				orangesCount++;
    			}
    		}
    		ce.nextPage();
    	} 
    	System.assertEquals(NUMBER_OF_LOTS_PEARS, pearsCount, 'Inconsisent products count across pages with filter OFF');
    	System.assertEquals(NUMBER_OF_LOTS_ORANGES, orangesCount, 'Inconsisent products count across pages with filter OFF');
    	
    	/* 	TEST CASE #2 
    		Turn ON filter, using showing only products of a specific category
    		Check number of pages, products count for each category
		============================================================================ */
    	ce.categoryFilter = PEARS;
    	ce.updateFilter();
    	System.assertEquals(EXPECTED_PAGES_PEARS_ONLY, ce.getNumberOfPages(), 'Inconsistent number of pages with filter ON');
    	orangesCount = pearsCount = 0;
    	for (Integer i=0; i<ce.getNumberOfPages(); i++) {
    		System.assertNotEquals(0, ce.wrappers.size(), 'Empty pages detected when filter is ON');
    		for (PobControllerExt.Wrapper w:ce.wrappers) {
    			if (w.product.Product_Category__c == PEARS) {
    				pearsCount++;
    			}
    			if (w.product.Product_Category__c == ORANGES) {
    				orangesCount++;
    			}
    		}
    		ce.nextPage();
    	} 
    	System.assertEquals(NUMBER_OF_LOTS_PEARS, pearsCount, 'Inconsisent products count across pages with filter ON');
    	System.assertEquals(0, orangesCount, 'Oranges should have been filtered out');
    	
    	/* 	TEST CASE #3 
    		Turn ON filter, using a category that has no records
    		Check number of pages, products count for each category
		============================================================================ */
    	ce.categoryFilter = 'This category does not exist';
    	ce.updateFilter();
    	System.assertEquals(0, ce.getNumberOfPages(), 'No pages should be found when filtering by a product category that does not exist');
    	System.assertEquals(0, ce.wrappers.size(), 'Page should be empty when filtering by a category not found');
	}
	
	static testMethod void testPaginationOnNewOrder() {
		
		// Setup data
		Account myAccount = TestDataFactory.createAccount();
    	List<Lot__c> lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
    	insert myAccount;
    	insert lots;
		
		// Create controller    	
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
		ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	// Default
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'Current page is expected to be 1st');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
    	
		// Next
		ce.nextPage();
		System.assertEquals(false, ce.getPrevDisabled(), 'Prev button should be enabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be enabled');
		System.assertEquals(2, ce.getCurrentPage(), 'Unexpected current page');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
    	
		// Previous
		ce.prevPage();
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'Current page is expected to be 1st');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
    	
    	// Last
    	ce.lastPage();
    	System.assertEquals(false, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(true, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(3, ce.getCurrentPage(), 'Current page is expected to be 3rds');
    	System.assertEquals(2, ce.wrappers.size(), '2 items expected in the page');
    	
    	// First
    	ce.firstPage();
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'Current page is expected to be 1st');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
	}
	
	static testMethod void testPaginationOnExistingOrder() {
		
		// Setup data
		Account myAccount = TestDataFactory.createAccount();
    	List<Lot__c> lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
    	insert myAccount;
    	insert lots;
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
    	insert myOrder;
		
		// Create controller    	
		ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	// Default
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'Current page is expected to be 1st');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
    	
		// Next
		ce.nextPage();
		System.assertEquals(false, ce.getPrevDisabled(), 'Prev button should be enabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be enabled');
		System.assertEquals(2, ce.getCurrentPage(), 'Unexpected current page');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
    	
		// Previous
		ce.prevPage();
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'Current page is expected to be 1st');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
    	
    	// Last
    	ce.lastPage();
    	System.assertEquals(false, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(true, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(3, ce.getCurrentPage(), 'Current page is expected to be 3rds');
    	System.assertEquals(2, ce.wrappers.size(), '2 items expected in the page');
    	
    	// First
    	ce.firstPage();
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(false, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(3, ce.getNumberOfPages(), '3 pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'Current page is expected to be 1st');
    	System.assertEquals(5, ce.wrappers.size(), '5 items expected in the page');
	}

    static testMethod void testPaginationNoProducts() {
		
		// Prepare data
		Account myAccount = TestDataFactory.createAccount();
    	insert myAccount;
    	
    	// Create controller
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
    	
		ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(true, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(0, ce.getNumberOfPages(), 'No products, no pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'No products, 0 pages expected');
    	
    }
    
    static testMethod void testFilterValues() {
    	
    	Test.setCurrentPage(Page.pob);
	    Account myAccount = TestDataFactory.createAccount();
	    Order__c myOrder = TestDataFactory.createOrder(myAccount);
    	insert myAccount;
    	
    	// 
		ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	
    	
    	
    	
    }
    
    /*
        List<Apexpages.Message> msgs = ApexPages.getMessages();
		for (Apexpages.Message msg:msgs) {
			System.debug('***ERROR '  + msg);
		}
    */
    static testMethod void testCreateNewOrder() {
    	
		// Setup data    	
    	List<Lot__c> lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
	    Account myAccount = TestDataFactory.createAccount();
    	insert lots;
    	insert myAccount;
    	
    	// Transient order
    	Order__c myOrder = TestDataFactory.createOrder(TEST_ORDER_BUDGET);
    	
    	// Create controllers
    	ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	// Start test
    	Test.setCurrentPage(Page.pob);
    	Test.startTest();

		// Test heading and pagination controls  	
    	System.assertEquals(Label.POB_Heading_New, ce.heading, 'Heading is incorrect when creating a new order');
        System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
        System.assertEquals(false, ce.getNextDisabled(), 'Prev button should be disabled');
        
		// 1) Empty Selection: Check summary and selection
        System.assertEquals(0, ce.getUnits(), 'Summary error - Unexpected value in number of units');
        System.assertEquals(null, ce.getPricePerUnit(), 'Summary error - Unexpected value in price per unit');
        for (PobControllerExt.Wrapper w : ce.wrappersMap.values()) {
        	System.assertEquals(0, w.units, 'Units should be 0 on an empty order');
        }
        
        // 2) Add a couple of products, check summary and selection
        ce.setLotQuantity(ce.wrappers[0].product.Id, 2);
        ce.setLotQuantity(ce.wrappers[1].product.Id, 3);
        ce.updateSelection();
        System.assertEquals(2, ce.wrappers[0].units, 'Selection error - Inconsistent number of units');
        System.assertEquals(3, ce.wrappers[1].units, 'Selection error - Inconsistent number of units');
        System.assertEquals(5, ce.getUnits(), 'Summary error - Unexpected value in number of units');
        System.assertEquals(TestDataFactory.TEST_LOT_PRICE, ce.getPricePerUnit(), 'Summary error - Unexpected value in price per unit');
        
        // Try to save, errors are expected (no store given)
        PageReference nextPage = ce.save();
        System.assertEquals(sc.view().getUrl(), nextPage.getUrl(), 'Unexpected page reference, validation error expected here');
        ApexPages.currentPage().getParameters().put('hasError','true');  
    	System.assertEquals(true, ApexPages.getMessages().size()>0, 'Unexpected - error messages expected');
        List<Order__c> orders = [SELECT Id FROM Order__c];
        List<Line_Item__c> lineItems = [SELECT Id, Order__c, Lot__c, Units__c FROM Line_Item__c];
        System.assertEquals(0, orders.size(), 'Unexpected - number of orders created after save is inconsistent');
        System.assertEquals(0, lineItems.size(), 'Unexpected - inconsistent number of line items');
        
        // Fix the error and try to save again
        ce.po.Store__c = myAccount.Id;
        nextPage = ce.save();
        System.assertEquals(null, nextPage.getUrl(), 'Unexpected page reference');
		orders = [SELECT Id FROM Order__c];
        lineItems = [SELECT Id, Order__c, Lot__c, Units__c FROM Line_Item__c];
        System.assertEquals(1, orders.size(), 'Unexpected - number of orders created after save is inconsistent');
        System.assertEquals(2, lineItems.size(), 'Unexpected - inconsistent number of line items');
        for (Line_Item__c li : lineItems) {
        	System.assertEquals(orders[0].Id, li.Order__c, 'Unexpected - line item do not match order');	
        }
        
        // End test
        Test.stopTest();
    }
    
    static testMethod void testEditExistingOrder() {
    	
    	// Setup data
    	List<Lot__c> lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
    	Account myAccount = TestDataFactory.createAccount();
    	insert lots;
    	insert myAccount;
    	
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
    	insert myOrder;
    	
    	List<Line_Item__c> lineItems = new List<Line_Item__c>();
    	for (Lot__c l : lots) {
    		 Line_Item__c li = TestDataFactory.createLineItem(myOrder, l, 1);
    		 lineItems.add(li);
    	}
    	insert lineItems;
    	
		// Create controllers
    	ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
		PageReference editPage = sc.edit();
    	//System.assertEquals(Page.POB, editPage, 'Edit page should be Purchase Order Builder');
    	//Test.setCurrentPage(editPage);
    	

		// Test heading and pagination controls    	
    	System.assertEquals(myOrder.name, ce.heading, 'Expected order name as heading when editing an existing order');
		System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
        System.assertEquals(false, ce.getNextDisabled(), 'Prev button should be disabled');
        
        //TODO: do stuff
    	
    }
}