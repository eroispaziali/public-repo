public with sharing class OliTriggerHandler {
	
	public static void updateRelatedOrders(List<Line_Item__c> items) {
		
		// prepare related orders
		Set<Id> orderIds = new Set<Id>();
		for (Line_Item__c i : items) {
			orderIds.add(i.Order__c);
		}
		
		// load required data for related orders
		List<Order__c> orders = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id in :orderIds];
		
		// force reload all line items for orders above
		List<Line_Item__c> lineItems = [SELECT Order__c, Amount__c, Lot__r.Product_Category__c, Units__c FROM Line_Item__c WHERE Order__c in :orderIds];
		
		// business logic
		updatePurchasedAmount(orders, lineItems);
		updateCategories(orders, lineItems);
		
		// persist
		update orders;
	}
	
	private static void updatePurchasedAmount(List<Order__c> orders, List<Line_Item__c> lineItems) {
		
		// Calculate all amounts
		Map<Id, Decimal> orderToAmountMap = new Map<Id, Decimal>();
		for (Line_Item__c i : lineItems) {
			
			// calculate amount
			Decimal thisOrderAmount = orderToAmountMap.get(i.Order__c);
			thisOrderAmount = (thisOrderAmount!=null) ? thisOrderAmount : 0; 
			thisOrderAmount = thisOrderAmount + i.Amount__c; 
			orderToAmountMap.put(i.Order__c, thisOrderAmount);

		}
		
		// Update all orders
		for (Order__c o : orders) {
			o.Purchased__c = orderToAmountMap.get(o.Id);
		}
	}
	
	private static void updateCategories(List<Order__c> orders, List<Line_Item__c> lineItems) {
		CategoryCounter cc = new CategoryCounter(lineItems);
		Map<Id, List<CategoryWrapper>> resultMap = cc.getResultMap();
		for (Order__c o : orders) {
			List<CategoryWrapper> ranking = resultMap.get(o.Id);
			if (ranking!=null) {
				if (ranking.size()>0) {
					o.Product_Category_1__c = ranking.get(0).name;
					o.Product_Category_Units_1__c = ranking.get(0).units;
				}
				if (ranking.size()>1) {
					o.Product_Category_2__c = ranking.get(1).name;
					o.Product_Category_Units_2__c = ranking.get(1).units;
				}
			}
		}
	}
	

	/* INNER CLASSES BELOW */	

	private class CategoryCounter {
		
		// data structure to contain counting wrappers, per product category, per order
		private Map<Id, Map<String, CategoryWrapper>> orderMap = new Map<Id, Map<String, CategoryWrapper>> ();

		// constructor from a set of line items
		public CategoryCounter(List<Line_Item__c> lineItems) {
			for (Line_Item__c li : lineItems) { 
				add(li.Order__c, li.Lot__r.Product_Category__c, li.Units__c);
			}
		}
		
		// Maintain an inner data structure counting wrappers (units), per product category, per order
		private void add(Id orderId, String productCategory, Decimal units) {
			Map<String, CategoryWrapper> wrapperMap = orderMap.get(orderId);
			wrapperMap = (wrapperMap!=null) ? wrapperMap : new Map<String, CategoryWrapper>();  
			CategoryWrapper wrapper = wrapperMap.get(productCategory);
			wrapper = (wrapper!=null) ? wrapper : new CategoryWrapper(productCategory); 
			wrapper.addUnits(units);
			wrapperMap.put(productCategory, wrapper); 
			orderMap.put(orderId, wrapperMap);
		}
		
		// Retrieve ordered results
		public Map<Id, List<CategoryWrapper>> getResultMap() {
			Map<Id, List<CategoryWrapper>> resultMap = new Map<Id, List<CategoryWrapper>>(); 
			Set<Id> orderIds = orderMap.keySet();
			for (Id orderId : orderIds) {
				List<CategoryWrapper> wrapperList = orderMap.get(orderId).values();
				wrapperList.sort();
				resultMap.put(orderId, wrapperList);
			}
			return resultMap;
		}
	}
	
	// Sortable wrapper for product categories
	private class CategoryWrapper implements Comparable {
		public String name {get;set;}
		public Decimal units {get;set;}
		
		public CategoryWrapper(String productCategory) {
			this.name = productCategory;
			this.units = 0;
		}
		
		public void addUnits(Decimal units) {
			this.units += units;
		}
		
		public Integer compareTo(Object compareTo) {
			CategoryWrapper wrapped = (CategoryWrapper) compareTo;
			if (units>wrapped.units) return 1;
			if (units<wrapped.units) return -1;
			return 0;
		}
	} 

}