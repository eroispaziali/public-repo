public with sharing class PobControllerExt {
	
	public Integer pageNumber {get;set;}
	public Integer numberOfPages {get;set;}
	
	public String heading {get;set;}
	public String categoryFilter {get;set;}
	public Order__c po {get;set;}

	public PobControllerExt(ApexPages.StandardController stdController) {
		po = (Order__c) stdController.getRecord();
		heading = (po!=null) ? po.Name : Label.POB_Heading_New;
	}
	
	public PobControllerExt(ApexPages.StandardSetController stdController) {
		po = (Order__c) stdController.getRecord();
		heading = (po!=null) ? po.Name : Label.POB_Heading_New;
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


}