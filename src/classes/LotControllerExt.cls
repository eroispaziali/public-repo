public with sharing class LotControllerExt {
	
		public Integer pageNumber {get;set;}
		public Integer numberOfPages {get;set;}
		public List<Lot__c> lots {get;set;}
	
		public LotControllerExt(ApexPages.StandardSetController stdSetController) {
			lots = stdSetController.getRecords();
	}
	

}