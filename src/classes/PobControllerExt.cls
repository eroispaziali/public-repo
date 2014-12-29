public with sharing class PobControllerExt {
	
	public String heading {get;set;}
	public String categoryFilter {get;set;}
	public Order__c po {get;set;}
	public List<Lot__c> lots {get;set;}

	public PobControllerExt(ApexPages.StandardController stdController) {
		po = (Order__c) stdController.getRecord();
		heading = (po!=null && po.Id!=null) ? po.Name : Label.POB_Heading_New;
		lots = [SELECT Id,Name FROM Lot__c ORDER BY Name];
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