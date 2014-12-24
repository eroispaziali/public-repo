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
private class LineItemTriggerTest {
	
	private static final Decimal TEST_PRICE_ORANGES = 4;
	private static final Decimal TEST_PRICE_APPLES = 2;
	private static final Decimal TEST_PRICE_PEARS = 3;
	
	@IsTest(seeAllData=false)
	private static void testOrdersWithManyLineItems() {
		
		// Prepare data (accounts, lots, orders)
		Account a = TestDataFactory.createAccount();
		Account b = TestDataFactory.createAccount();
		insert new List<Account> { a,b };
		
		Lot__c apples = TestDataFactory.createLot('apples', TEST_PRICE_APPLES);
    	Lot__c pears = TestDataFactory.createLot('pears', TEST_PRICE_PEARS);
    	Lot__c oranges = TestDataFactory.createLot('oranges', TEST_PRICE_ORANGES);
    	List<Lot__c> lots = new List<Lot__c> { pears, oranges, apples }; 
    	insert lots;
    	
    	Order__c myOrder = TestDataFactory.createOrder(a);
    	Order__c anotherOrder = TestDataFactory.createOrder(a);
    	Order__c someoneElsesOrder = TestDataFactory.createOrder(b);
    	insert new List<Order__c> { myOrder, anotherOrder, someoneElsesOrder };
    	
    	/* Bulk INSERT
    	 * Create many orders and line items in the same transactions, ensure that logic works without order overlaps 
    	=============================================================================================================== */
    	List<Line_Item__c> lineItems = new List<Line_Item__c>();
    	Line_Item__c myApples = TestDataFactory.createLineItem(myOrder, apples, 10);
    	Line_Item__c myOranges = TestDataFactory.createLineItem(myOrder, oranges, 9);
    	Line_Item__c myPearsFirstBit = TestDataFactory.createLineItem(myOrder, pears, 6);
    	Line_Item__c myPearsSecondBit = TestDataFactory.createLineItem(myOrder, pears, 5); 
    	lineItems.add( myOranges );
    	lineItems.add( myApples );
    	lineItems.add( myPearsFirstBit );
    	lineItems.add( myPearsSecondBit );
    	
    	// create other orders to ensure bulk processing works
    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, apples, 20) );
    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, pears, 7) );
    	lineItems.add( TestDataFactory.createLineItem(anotherOrder, oranges, 6) );
    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, oranges, 1) );
    	lineItems.add( TestDataFactory.createLineItem(someoneElsesOrder, pears, 2) );
    	insert lineItems;
    	
		// Reload myOrder and assert results on insert    	
    	myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
    	System.assertEquals( 9*TEST_PRICE_ORANGES + (6+5)*TEST_PRICE_PEARS + 10*TEST_PRICE_APPLES, myOrder.Purchased__c, 'Purchased price is incorrect on insert');
    	System.assertEquals('pears', myOrder.Product_Category_1__c,  'First product category is incorrect on insert');
    	System.assertEquals(11, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on insert');
    	System.assertEquals('apples', myOrder.Product_Category_2__c, 'Second product category is incorrect on insert');
    	System.assertEquals(10, myOrder.Product_Category_Units_2__c, 'Second product category units are incorrect on insert');

    	/* BULK UPDATE
    	 * Update some line items with different number of units, ensure logic works
    	============================================================================== */
		List<Line_Item__c> orangesAndApples = new List<Line_Item__c> { myApples, myOranges }; 
		myApples.Units__c = 20;
		myOranges.Units__c = 7;
		update orangesAndApples; 
		
		// Reload myOrder and check expected results
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		System.assertEquals( 7*TEST_PRICE_ORANGES + (6+5)*TEST_PRICE_PEARS + 20*TEST_PRICE_APPLES, myOrder.Purchased__c, 'Purchased price is incorrect on update');
    	System.assertEquals('apples', myOrder.Product_Category_1__c,  'First product category is incorrect on update');
    	System.assertEquals(20, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on update');
    	System.assertEquals('pears', myOrder.Product_Category_2__c, 'Second product category is incorrect on update');
    	System.assertEquals(11, myOrder.Product_Category_Units_2__c, 'Second product category units are incorrect on update');
    	
    	/* BULK DELETE
    	 * Delete something from the order, but leave something else in, ensure logic works
    	===================================================================================== */
    	delete orangesAndApples;
    	
		// Reload myOrder and check expected results
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		System.assertEquals( (6+5)*TEST_PRICE_PEARS, myOrder.Purchased__c, 'Purchased price is incorrect on delete');
    	System.assertEquals('pears', myOrder.Product_Category_1__c,  'First product category is incorrect on delete');
    	System.assertEquals(11, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on delete');
    	System.assertEquals(null, myOrder.Product_Category_2__c, 'Second product category should be null on delete');
    	System.assertEquals(null, myOrder.Product_Category_Units_2__c, 'Second product category should be null on delete');
    	
		/* BULK UNDELETE
	 	 * Restore what was removed from the order above, ensure logic works
    	====================================================================== */
    	undelete orangesAndApples;
    	
    	// Reload myOrder and check expected results
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		System.assertEquals( 7*TEST_PRICE_ORANGES + (6+5)*TEST_PRICE_PEARS + 20*TEST_PRICE_APPLES, myOrder.Purchased__c, 'Purchased price is incorrect on undelete');
    	System.assertEquals('apples', myOrder.Product_Category_1__c,  'First product category is incorrect on undelete');
    	System.assertEquals(20, myOrder.Product_Category_Units_1__c, 'First product category units are incorrect on undelete');
    	System.assertEquals('pears', myOrder.Product_Category_2__c, 'Second product category is incorrect on undelete');
    	System.assertEquals(11, myOrder.Product_Category_Units_2__c, 'Second product category units are incorrect on undelete');
    	

		/* ADDITIONAL
		   Empty the order, ensure logic works 
    	======================================== */
    	List<Line_Item__c> allMyOrderItems = [SELECT Id FROM Line_Item__c WHERE Order__c = :myOrder.Id];
    	delete allMyOrderItems;
    	
    	// Reload myOrder and check expected results
		myOrder = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id = :myOrder.Id][0];
		System.assertEquals(0, myOrder.Purchased__c, 'Purchased price is incorrect on and empty order');
    	System.assertEquals(null, myOrder.Product_Category_1__c,  'First product category should be null on an empty order');
    	System.assertEquals(null, myOrder.Product_Category_Units_1__c, 'First product category units should be null on an empty order');
    	System.assertEquals(null, myOrder.Product_Category_2__c, 'Second product category should be null on an empty order');
    	System.assertEquals(null, myOrder.Product_Category_Units_2__c, 'Second product category should be null on an empty order');
		
	}
    
}