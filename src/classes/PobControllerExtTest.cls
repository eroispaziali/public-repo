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

	static testMethod void testFilter() {
		// should work
		// products should be in alphabetical order
	}

    static testMethod void testPaginationNoProducts() {
		
		// Prepare data
		Account myAccount = TestDataFactory.createAccount();
    	insert myAccount;
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
    	
    	// Create controller
		ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);
    	
    	System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
    	System.assertEquals(true, ce.getNextDisabled(), 'Next button should be disabled');
    	System.assertEquals(0, ce.getNumberOfPages(), 'No products, 0 pages expected');
    	System.assertEquals(1, ce.getCurrentPage(), 'No products, 0 pages expected');
    	
    	
    	
    }
    
    static testMethod void testCreateNewOrder() {
    	
    	// create lots (3x pages, 5,5,2 elements)
    	List<Lot__c> lots = TestDataFactory.createLots(12);

    	insert lots;
    	Account myAccount = TestDataFactory.createAccount();

    	insert myAccount;
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
    	
    	// Create controllers
    	ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);

		// Test heading    	
    	System.assertEquals(Label.POB_Heading_New, ce.heading, 'Heading is incorrect');
    	
    	// Test pagination controls
        System.assertEquals(true, ce.getPrevDisabled(), 'Prev button should be disabled');
        
    }
    
    static testMethod void testEditExistingOrder() {
    	// create lots (3x pages, 5,5,2 elements)
    	List<Lot__c> lots = TestDataFactory.createLots(12);
    	insert lots;
    	
    	Account myAccount = TestDataFactory.createAccount();
    	insert myAccount;
    	
    	Order__c myOrder = TestDataFactory.createOrder(myAccount);
    	insert myOrder;
    	
		// Create controllers
    	ApexPages.StandardController sc = new ApexPages.standardController(myOrder);
    	PobControllerExt ce = new PobControllerExt(sc);

		// Test heading    	
    	System.assertEquals(myOrder.name, ce.heading, 'Heading is incorrect');
    	
    	
    	
    }
}