@isTest
private class TestDataFactory {
	
	private static final String TEST_ACCOUNT_NAME = 'My Test Account';
	private static final String TEST_PRODUCT_NAME = 'Product Name';
	
	public static Account createAccount() {
		Account a = new Account(
			name = TEST_ACCOUNT_NAME
		);
		return a;	
	}
	
	public static Order__c createOrder() {
		Order__c o = new Order__c();
		return o;
	}
	
	public static Line_Item__c createLineItem() {
		Line_Item__c li = new Line_Item__c();
		return li; 
	}
	
	public static Lot__c createLot(String productCategory) {
		Lot__c lot = new Lot__c(Product_Category__c = productCategory);
		return lot;
	}
    
}