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
	private static final String APPLES = 'Apples';
	private static final String PEARS = 'Pears';
	private static final String ORANGES = 'Oranges';
	private static final Integer NUMBER_OF_LOTS_ORANGES = 5;
	private static final Integer NUMBER_OF_LOTS_PEARS = 7;
	private static final Integer EXPECTED_PAGES_ORANGES_AND_PEARS = 3;
	private static final Integer EXPECTED_PAGES_ORANGES_ONLY = 1;
	private static final Integer EXPECTED_PAGES_PEARS_ONLY = 2;
	private static final Decimal TEST_ORDER_BUDGET = 150000;
	
	/*
        List<Apexpages.Message> msgs = ApexPages.getMessages();
		for (Apexpages.Message msg:msgs) {
			System.debug('***ERROR '  + msg);
		}
    */

	/** 
		TEST PRODUCT CATEGORY FILTER
		==========================================================================================
    	Ensure category filter works properly when the page is created, 
    	the filter is set and reset back.
    		1) by default the filter must be off
    		2) when turned on only products of a specific category must be shown
    		3) if the value of the filter isn't found, no results shoul be displayed
    	========================================================================================== */
	static testMethod void testCategoryFilter() {
		
		// Vars, users & data
		Account myAccount;
		Order__c myOrder;
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		System.runAs(inventoryManager) {
			List<Lot__c> lotsOfPears = TestDataFactory.createLots(PEARS, NUMBER_OF_LOTS_PEARS);
    		List<Lot__c> lotsOfOranges = TestDataFactory.createLots(ORANGES, NUMBER_OF_LOTS_ORANGES);
    		insert lotsOfPears;
    		insert lotsOfOranges;
		}
		
		System.runAs(accountManager) {
			myAccount = TestDataFactory.createAccount();
    		insert myAccount;
    		
    		Test.startTest();
    		
	    		// Create controller    	
		    	myOrder = TestDataFactory.createOrder(myAccount);
				ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
		    	PobControllerExt ce = new PobControllerExt(sc);
		    	
		    	// Test picklist values are loaded
		    	List<SelectOption> options = ce.getFilterValues();
		    	System.assertEquals(true, options.size()>0, 'Options expected in the filter picklist');
		    	
		    	
		    	/* 	(1)  By default filter must be OFF
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
		    	
		    	/* 	(2) Turn ON filter, using showing only products of a specific category
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
		    	
		    	/* 	(3) Turn ON filter, using a category that has no records
		    		Check number of pages, products count for each category
				============================================================================ */
		    	ce.categoryFilter = 'This category does not exist';
		    	ce.updateFilter();
		    	System.assertEquals(0, ce.getNumberOfPages(), 'No pages should be found when filtering by a product category that does not exist');
		    	System.assertEquals(0, ce.wrappers.size(), 'Page should be empty when filtering by a category not found');
	    	
	    	Test.stopTest();
		}
	}
	

	/** 
    	TEST PAGINATION (Positive case)
    	======================================================================
    	Ensure pagination works correctly when some products/lots are
    	in the database. Checks:
    	- default page is #1
    	- number of items per page
    	- number of pages
    	- prev/next
    	- first/last
    	====================================================================== */	
	static testMethod void testPaginationWithProducts() {
		
		// Setup users
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		// Prepare products
		System.runAs(inventoryManager) {
			List<Lot__c> lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
			insert lots;
		}
		
		// Create account, controller and start testing
		System.runAs(accountManager) {
			
			// Test data
			Account myAccount = TestDataFactory.createAccount();
	    	insert myAccount;
	    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
	    	insert myOrder;
			
			Test.startTest();
			
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
	    	
	    	Test.stopTest();
		}
	}

	/** 
    	TEST PAGINATION (Negative case, no products available)
    	======================================================================
    	Ensure pagination works correctly even if no products are available
    	in the database.
    	====================================================================== */
    static testMethod void testPaginationNoProducts() {
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		System.runAs(accountManager) {
    		Test.startTest();
    		
    		// Prepare data
			Account myAccount = TestDataFactory.createAccount();
    		insert myAccount;
    	
    		// Create controller
    		Order__c myOrder = TestDataFactory.createOrder(myAccount);
			ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
	    	PobControllerExt ce = new PobControllerExt(sc);
	    	
	    	// Check pagination buttons
	    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
	    	System.assertEquals(true, ce.getNextDisabled(), 'Next button should be disabled');
	    	System.assertEquals(0, ce.getNumberOfPages(), 'No products, no pages expected');
	    	System.assertEquals(1, ce.getCurrentPage(), 'No products, 1 pages expected');
	    	Test.stopTest();
		}
    }
    
    /** 
    	TEST PAGE HEADER CORRECTNESS
    	======================================================================
    	Ensure heading is as expected:
    	(1) when creating new orders (label) 
    	(2) when updateing existing orders (order name)
    	====================================================================== */
    static testMethod void testPageHeading() {
    	
    	// Setup users
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		
		System.runAs(inventoryManager) {
			List<Lot__c> lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
    		insert lots;
		}
		
		Test.startTest();
		
		// (1) Check heading on new orders
		System.runAs(accountManager) {

			// Create transient order
			Account myAccount = TestDataFactory.createAccount();
    		insert myAccount;	
			Order__c myOrder = TestDataFactory.createOrder(TEST_ORDER_BUDGET);
    		myOrder.Store__c = myAccount.Id;
    		
    		// Create controller to edit the new order
			ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
	    	PobControllerExt ce = new PobControllerExt(sc);
	    	Test.setCurrentPage(Page.pob);
	    	System.assertEquals(Label.POB_Heading_New, ce.heading, 'Heading is incorrect when creating a new order');
		}
		
		// (2) Check heading on existing orders
		System.runAs(accountManager) {
			
			// Create persisted order
			Account myAccount = TestDataFactory.createAccount();
    		insert myAccount;
			Order__c myOrder = TestDataFactory.createOrder(TEST_ORDER_BUDGET);
    		myOrder.Store__c = myAccount.Id;
    		insert myOrder;
    		
    		// Create controller to edit the existing order
			ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
	    	PobControllerExt ce = new PobControllerExt(sc);
	    	Test.setCurrentPage(Page.pob);
	    	System.assertEquals(myOrder.name, ce.heading, 'Unexpected heading on Purchase Order Builder');
		}
		
		Test.stopTest();
    }
    
    /** 
		TEST LOAD AND UPDATE OF AN EXISTING ORDER
    	======================================================================
    	Load a new order and ensure
    	- (1) order and line items are loaded
    	- (2) on save order and line items are updated 
    	====================================================================== */
	static testMethod void testLoadAndEditExistingOrder() {
		
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		Set<Id> existingLotIds = new Set<Id>();
		List<Lot__c> lots;
		Order__c myOrder;
		
		System.runAs(inventoryManager) {
    		lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
    		insert lots;
    	}
    	
    	// Setup account + order with line items
    	System.runAs(accountManager) {
			Account myAccount = TestDataFactory.createAccount();
    		insert myAccount;	
    		myOrder = TestDataFactory.createOrder(TEST_ORDER_BUDGET);
    		myOrder.Store__c = myAccount.Id;
    		insert myOrder;
    		
    		List<Line_Item__c> lineItems = new List<Line_Item__c>();
    		for (Integer i=0; i<2; i++) {
    			lineItems.add( TestDataFactory.createLineItem(myOrder,lots[i],10) );
    			existingLotIds.add(lots[i].Id);
    		}
    		insert lineItems;
    	}
    	
    	// Run tests
    	System.runAs(accountManager) {
			ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
	    	PobControllerExt ce = new PobControllerExt(sc);
	    	
	    	// Start test
	    	Test.setCurrentPage(Page.pob);
	    	Test.startTest();
	    	
	    	// (1) Test page load
    		for (PobControllerExt.Wrapper w : ce.wrappers) {
    			System.assertEquals(myOrder, ce.po, 'Wrong order loaded');
    			if (existingLotIds.contains(w.product.id)) {
    				System.assertEquals(10, w.units, 'Units should be pre-populated for products included in this order');
    			} else {
    				System.assertEquals(0, w.units, 'Units should be 0 for products not included as line items in this order');
    			}
    		}
    		
    		// (2) edit and save
    		ce.po.Name = 'Updated order name';
    		for (Lot__c l : lots) {
    			if (existingLotIds.contains(l.id)) {
    				ce.setLotQuantity(l.id, 20);
    			} else {
    				ce.setLotQuantity(l.id, 1);
    			}
    		}
    		
    		// Save
	        PageReference nextPage = ce.save();
	        System.assertEquals(sc.view().getUrl(), nextPage.getUrl(), 'Unexpected page reference');
			List<Order__c> orders = [SELECT Id FROM Order__c];
	        List<Line_Item__c> lineItems = [SELECT Id, Order__c, Lot__c, Units__c FROM Line_Item__c];
	        
	        // ensure Order is created with related line items...
	        System.assertEquals(1, orders.size(), 'Unexpected - number of orders created after save is inconsistent');
	        System.assertEquals(5, lineItems.size(), 'Unexpected - inconsistent number of line items');
	        
	        // Ensure line items are correct
	        // a) refer to the right Order__c and Lot__c
	        // b) contain the right units
	        Boolean newLineItemsFound = false;
	        Boolean existingLineItemsFound = false; 
	        for (Line_Item__c li : lineItems) {
	        	System.assertEquals(myOrder.Id, li.Order__c, 'Unexpected - line item do not match order');
	        	if (existingLotIds.contains(li.Lot__c)) {
	        		System.assertEquals(20,li.Units__c);
	        		existingLineItemsFound = true;
	        	} else {
	        		System.assertEquals(1,li.Units__c);
	        		newLineItemsFound = true;
	        	}
	        }
	        System.assertEquals(true, existingLineItemsFound, 'Existing line items should have been to be modified');
	        System.assertEquals(true, newLineItemsFound, 'New line items should have been added');
    		
	    	Test.stopTest();
    	}
    }
    
	/** 
		TEST CREATION OF A NEW ORDER (Positive case)
    	======================================================================
    	Create a new order and ensure
    	- orders or line items are created 
    	- line items refer to the right lots and order
    	- user is redirected to the order detail page 
    	====================================================================== */
    static testMethod void testCreateNewOrder() {
    	
		User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		List<Lot__c> lots;
    	
    	System.runAs(inventoryManager) {
    		lots = TestDataFactory.createLots(NUMBER_OF_LOTS);
    		insert lots;
    	}
    	
    	System.runAs(accountManager) {
    		Account myAccount = TestDataFactory.createAccount();
    		insert myAccount;	
    		
    		// Transient order
    		Order__c myOrder = TestDataFactory.createOrder(TEST_ORDER_BUDGET);
    		myOrder.Store__c = myAccount.Id;
    		
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
	        
	        // 2) Add a couple of products
	        // check summary and selection
	        ce.setLotQuantity(ce.wrappers[0].product.Id, 2);
	        ce.setLotQuantity(ce.wrappers[1].product.Id, 3);
	        ce.updateSelection();
	        System.assertEquals(2, ce.wrappers[0].units, 'Selection error - Inconsistent number of units');
	        System.assertEquals(3, ce.wrappers[1].units, 'Selection error - Inconsistent number of units');
	        System.assertEquals(5, ce.getUnits(), 'Summary error - Unexpected value in number of units');
	        System.assertEquals(TestDataFactory.TEST_LOT_PRICE, ce.getPricePerUnit(), 'Summary error - Unexpected value in price per unit');
	        
	        // Save
	        PageReference nextPage = ce.save();
	        System.assertEquals(sc.view().getUrl(), nextPage.getUrl(), 'Unexpected page reference');
			List<Order__c> orders = [SELECT Id FROM Order__c];
	        List<Line_Item__c> lineItems = [SELECT Id, Order__c, Lot__c, Units__c FROM Line_Item__c];
	        
	        // 1) ensure Order is created with related line items...
	        System.assertEquals(1, orders.size(), 'Unexpected - number of orders created after save is inconsistent');
	        System.assertEquals(2, lineItems.size(), 'Unexpected - inconsistent number of line items');
	        
	        // 2) Check that line items refer to the right Order__c and Lot__c 
	        Boolean firstLotFound = false, secondLotFound = false;
	        for (Line_Item__c li : lineItems) {
	        	System.assertEquals(orders[0].Id, li.Order__c, 'Unexpected - line item do not match order');
	        	if (li.Lot__c == ce.wrappers[0].product.Id) {
	        		firstLotFound = true;
	        	}
	        	if (li.Lot__c == ce.wrappers[1].product.Id) {
	        		secondLotFound = true;
	        	}
	        }
	        System.assertEquals(true, firstLotFound, 'Line items do not refer to product lots');
	        System.assertEquals(true, secondLotFound, 'Line items do not refer to product lots');
	        
	        // End test
	        Test.stopTest();
    	} 
    }
    
    
    /** 
    	TEST ORDER BUDGET VALIDATION
    	======================================================================
    	1) Ensure orders below 100k cannot be created
    	2) Create a new order that is over budget and ensure
    	- no orders or line items are created 
    	- the right error message is displayed 
    	- user is redirected stays on the same page to re-enter data
    	====================================================================== 
    */
    static testMethod void testBudgetValidation() {
    	
    	User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		Lot__c someApples = null, somePears = null;
		Order__c myOrder;
    	
    	// Prepare lots
    	System.runAs(inventoryManager) {
    		someApples = TestDataFactory.createLot(APPLES, 1000);
    		somePears = TestDataFactory.createLot(PEARS, 1);
    		insert new List<Lot__c> { someApples, somePears };
    	}
    	
    	// Create accounts and order
    	System.runAs(accountManager) {
		    Account myAccount = TestDataFactory.createAccount();
	    	insert myAccount;
	    	
	    	// 1) Order below 100k
	    	myOrder = TestDataFactory.createOrder(10);
	    	DmlException expected = null;
	    	try {
	    		insert myOrder;
	    	} catch (DmlException e) {
	    		expected = e;
	    	}
	    	System.assertNotEquals(null, expected, 'Should not be able to create orders below 100k');
	    	System.assertEquals(0, [SELECT Id FROM Order__c].size(), 'No order should be created');
	    	
	    	
	    	// 2) Budget is 100k
	    	myOrder = TestDataFactory.createOrder(100000);
	    	myOrder.Store__c = myAccount.Id;
    	}
    	
    	// Create controllers and start test
    	System.runAs(accountManager) {
	    	ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
	    	PobControllerExt ce = new PobControllerExt(sc);
	    	Test.setCurrentPage(Page.pob);
	    	Test.startTest();
	    	
	    		// Set quantities & hit save
	    		// These quantities will make the order go over budget (100001k)
				ce.setLotQuantity(someApples.Id, 100);
	    		ce.setLotQuantity(somePears.Id, 1);
	    		ce.updateSelection();
		        PageReference nextPage = ce.save();
		        
		        // Verify results
		        System.assertEquals(null, nextPage, 'Unexpected page reference, validation error expected here');
		        ApexPages.currentPage().getParameters().put('hasError','true');  
		    	System.assertEquals(true, ApexPages.getMessages().size()>0, 'Unexpected - error messages expected');
		    	Boolean expectedMessageFound = false;
		    	for (ApexPages.Message m : ApexPages.getMessages()) {
		    		if (m.getDetail().contains('Purchased exceeds budget')) {
		    			expectedMessageFound = true;
		    		}
		    	}
		    	System.assertEquals(true, expectedMessageFound, 'Unexpected error message');
		        List<Order__c> orders = [SELECT Id FROM Order__c];
		        List<Line_Item__c> lineItems = [SELECT Id, Order__c, Lot__c, Units__c FROM Line_Item__c];
		        System.assertEquals(0, orders.size(), 'Transaction rollback expected here. No order shoud be created on errors');
		        System.assertEquals(0, lineItems.size(), 'No line items should be created on errors');
		        
	    	Test.stopTest();
    	}
    }
    
	/** 
    	TEST VALIDATION ON MISSING STORES
    	====================================================================== 
    	Create a new order that is not related to any store, ensure
    	- no orders or line items are created 
    	- an error message is displayed
    	- user is redirected stays on the same page to re-enter data
    	====================================================================== */
    static testMethod void testMissingStoreValidation() {
    	
    	User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		Lot__c someApples = null, somePears = null;
		Order__c myOrder;
    	
    	// Prepare lots
    	System.runAs(inventoryManager) {
    		someApples = TestDataFactory.createLot(APPLES, 1000);
    		somePears = TestDataFactory.createLot(PEARS, 1);
    		insert new List<Lot__c> { someApples, somePears };
    	}
    	
    	// Create accounts and order
    	System.runAs(accountManager) {
		    Account myAccount = TestDataFactory.createAccount();
	    	insert myAccount;
	    	
	    	// Order with null store
	    	myOrder = TestDataFactory.createOrder(100000);
	    	myOrder.Store__c = null;
    	}
    	
    	// Create controllers and start test
    	System.runAs(accountManager) {
	    	ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
	    	PobControllerExt ce = new PobControllerExt(sc);
	    	Test.setCurrentPage(Page.pob);
	    	Test.startTest();
	    	
	    		// Set quantities & hit save
				ce.setLotQuantity(someApples.Id, 10);
	    		ce.setLotQuantity(somePears.Id, 1);
	    		ce.updateSelection();
		        PageReference nextPage = ce.save();
		        
		        // Verify results
		        System.assertEquals(null, nextPage, 'Unexpected page reference, validation error expected here');
		        ApexPages.currentPage().getParameters().put('hasError','true');  
		    	System.assertEquals(true, ApexPages.getMessages().size()>0, 'Unexpected - error messages expected');
		        List<Order__c> orders = [SELECT Id FROM Order__c];
		        List<Line_Item__c> lineItems = [SELECT Id, Order__c, Lot__c, Units__c FROM Line_Item__c];
		        System.assertEquals(0, orders.size(), 'Transaction rollback expected here. No order shoud be created on errors');
		        System.assertEquals(0, lineItems.size(), 'No line items should be created on errors');
		        
	    	Test.stopTest();
    	}
    }
    
    
    /*
    static testMethod void testEditExistingOrder() {
    	
    	User accountManager = TestDataFactory.createUser('Account Managers', 'aManager');
		User inventoryManager = TestDataFactory.createUser('Inventory Managers','iManager');
		Lot__c someApples = null, somePears = null;
		Order__c myOrder;
    	
    	// 1) Prepare data
    	System.runAs(inventoryManager) {
    		someApples = TestDataFactory.createLot(APPLES, 1000);
    		somePears = TestDataFactory.createLot(PEARS, 5000);
    		insert new List<Lot__c> { someApples, somePears };
    	}
    	
    	System.runAs(accountManager) {
		    Account myAccount = TestDataFactory.createAccount();
	    	insert myAccount;
	    	
	    	myOrder = TestDataFactory.createOrder(100000);
	    	myOrder.Store__c = myAccount.Id;
	    	insert myOrder;
	    	
	    	Line_Item__c liApples = TestDataFactory.createLineItem(myOrder, someApples, 100);
	    	Line_Item__c liPears = TestDataFactory.createLineItem(myOrder, somePears, 1);
	    	insert new List<Line_Item__c> { liApples, liPears };
    	}
    	
    	// 2) Check test case
    	ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	
    	//TEST CASE 1 check exceeding budget
    	Test.setCurrentPage(Page.pob);
    	Test.startTest();
    		
    		System.assertEquals(myOrder.name, ce.heading, 'Unexpected heading on Purchase Order Builder');
    		
	        // Try to save, errors are expected (no store given)
	        PageReference nextPage = ce.save();
	        System.assertEquals(null, nextPage, 'Unexpected page reference, validation error expected here');
	        ApexPages.currentPage().getParameters().put('hasError','true');  
	    	System.assertEquals(1, ApexPages.getMessages().size(), 'Unexpected - error messages expected');
	    	System.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains('Purchased exceeds budget'), 'Unexpected error message');
	        List<Order__c> orders = [SELECT Id FROM Order__c];
	        List<Line_Item__c> lineItems = [SELECT Id, Order__c, Lot__c, Units__c FROM Line_Item__c];
	        System.assertEquals(0, orders.size(), 'Transaction rollback expected here. No order shoud be created on errors');
	        System.assertEquals(0, lineItems.size(), 'No line items should be created on errors');
    		
    		
    	Test.stopTest();
    	
    	
    	//TEST CASE 2 check okay budget
    	//TEST CASE 3 check order is below minimum (100k)
    	
    	
    }*/
}