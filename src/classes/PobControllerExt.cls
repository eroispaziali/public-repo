public with sharing class PobControllerExt {
	
	public String heading {get;set;}
	public String categoryFilter {get;set;}
	
	// Summary
	public Integer units {get;set;}
	public Decimal pricePerUnit {get;set;}
	
	
	public Order__c po {get;set;}
	public List<Lot__c> lots {get;set;}
	
	// Paging stuff
	private static final Integer ITEMS_PER_PAGE = 10;
	private Integer myOffset {get;set;}
	
	
	public PobControllerExt(ApexPages.StandardController stdController) {
		po = (Order__c) stdController.getRecord();
		heading = (po!=null && po.Id!=null) ? po.Name : Label.POB_Heading_New;
		setPage(1);
	}
	
	private void setPage(Integer page) {
		myOffset = 0;
		lots = [SELECT Id,Name,Product__c, Product_Category__c, Unit_Price__c,Remaining__c FROM Lot__c ORDER BY Name LIMIT :ITEMS_PER_PAGE OFFSET :myOffset];
	}
	
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
		myOffset = 0;
	}
	
	public void lastPage() {
		
	}
	
	public void nextPage() {
		myOffset =+ ITEMS_PER_PAGE;
	}
	
	public void prevPage() {
		myOffset -= ITEMS_PER_PAGE;
	}
	


}