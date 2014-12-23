@isTest
private class TestDataFactory {
	
	private static final String TEST_ACCOUNT_NAME = 'My Test Account';
	
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

    
}