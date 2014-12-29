public with sharing class PobControllerExt {
	
	// Summary, filter, etc
	public String heading {get;set;}
	public String categoryFilter {get;set;}
	public Integer units {get;set;}
	public Decimal pricePerUnit {get;set;}
	
	// Records
	public Order__c po {get;set;}
	public List<Wrapper> wrappers {get;set;}
	
	// Private stuff
	private List<Lot__c> lots;
	private Map<Id, Wrapper> lot2Wrappers = new Map<Id, Wrapper>();
	private Map<Id, Decimal> quantityMap = new Map<Id, Decimal>(); 
	private Integer currentPage;
	private Integer pageOffset;
	private Integer pageSize = 5;
	private Integer totalPages;
	private Integer recordCount;
	
	// Constructor
	public PobControllerExt(ApexPages.StandardController stdController) {
		po = (Order__c) stdController.getRecord();
		wrappers = new List<Wrapper>();
		
		if (isEdit()) {
			// existing PO
			heading = po.Name;
			List<Line_Item__c> lineItems = [
				SELECT Units__c, Lot__c, Amount__c 
				FROM Line_Item__c 
				WHERE Order__c = :po.Id
			];
			for (Line_Item__c li : lineItems) {
				quantityMap.put(li.Id, li.Units__c);	
			}
		} else {
			// new PO
			heading = Label.POB_Heading_New;
		}
		
		updateRecordCount();
		goToPage(1);
	}
	
	// Exposed methods
	public List<SelectOption> getFilterValues () {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', Label.POB_NoFilter));
		Schema.DescribeFieldResult fd = Lot__c.Product_Category__c.getDescribe();
		for (Schema.PicklistEntry ple : fd.getPicklistValues()) {
			options.add(new SelectOption(ple.value, ple.label));
		}
		return options;
	}
	
	public void firstPage() {
		goToPage(1);
	}
	
	public void lastPage() { 
		goToPage(totalPages);
	}
	
	public boolean getPrevDisabled() {
		return (currentPage > 1) ? false : true;
	}
	
	public boolean getNextDisabled() {
		return (currentPage<totalPages) ? false : true;
	}
	
	public Integer getNumberOfPages() {
		return totalPages;
	}
	
	public Integer getCurrentPage() {
		return currentPage;
	}
	
	public void nextPage() {
		if (!getNextDisabled()) {
			goToPage(currentPage+1);
		}
	}
	
	public void prevPage() {
		if (!getPrevDisabled()) {
			goToPage(currentPage-1);
		}
	}
	
	// Utility methods - stuff
	private void goToPage(Integer page) {
		
		// calculate offset
		currentPage = (page >= 1) ? page : 1;
		pageOffset = (page-1) * pageSize;
		pageOffset = (pageOffset!=null && pageOffset>=0) ? pageOffset : 0;

		// load all products in the page ...
		lots = [
			SELECT Id, Name, Product__c, Product_Category__c, Unit_Price__c, Remaining__c 
			FROM Lot__c 
			ORDER BY Name 
			LIMIT :pageSize 
			OFFSET :pageOffset
		];
		
		// ... then get/create wrappers for all fetched products		
		for (Lot__c l : lots) { 
			Decimal units = quantityMap.get(l.id)!=null ? quantityMap.get(l.id) : 0;
			Wrapper w = lot2Wrappers.get(l.id) !=null ? lot2Wrappers.get(l.id) : new Wrapper(l, units);
			wrappers.add(w);
			lot2Wrappers.put(l.id, w);
		}
	}
	
	private void updateRecordCount() {
		List<AggregateResult> ar = [SELECT COUNT(Id) c FROM Lot__c];
		recordCount = (ar.size()>0) ? (Integer) ar.get(0).get('c') : null;
		totalPages = recordCount / pageSize + ( Math.mod(recordCount, pageSize) > 0 ? 1 : 0);
	}
	
	// Utility methods
	private boolean isEdit() {
		return (po!=null && po.Id!=null) ? true : false;
	} 
	
	// Inner classes
	public class Wrapper {
		
		public Decimal units {set;get;}
		public Lot__c product {set;get;}
		
		public Wrapper(Lot__c product) {
			this.units = 0;
			this.product = product;
		}
		
		public Wrapper(Lot__c product, Decimal units) {
			this.units = units;
			this.product = product;
		}
	}
	
}