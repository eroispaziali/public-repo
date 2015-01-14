public with sharing class PobControllerExt {

	// Summary, filter, etc	
	public String heading {get;set;}
	public String categoryFilter {get;set;}
	private static final String SOQL_WITHOUT_FILTER = 'SELECT Id, Name, Product__c, Product_Category__c, Unit_Price__c, Remaining__c FROM Lot__c ORDER BY Name';
	private static final String SOQL_WITH_FILTER = 'SELECT Id, Name, Product__c, Product_Category__c, Unit_Price__c, Remaining__c FROM Lot__c WHERE Product_Category__c = :categoryFilter ORDER BY Name';
	
	// temp
	public Id lotId {get;set;}
	public String quantity {get;set;}
	
	// Records
	public Order__c po {get;set;}
	public List<Wrapper> wrappers {get;set;}

	@TestVisible 
	private Map<Id, Wrapper> wrappersMap = new Map<Id, Wrapper>();
	private Map<Id, Decimal> quantityMap = new Map<Id, Decimal>();
	
	private ApexPages.StandardSetController setCtrl;
	private ApexPages.StandardController stdCtrl;
	
	public PobControllerExt(ApexPages.StandardController stdController) {
		stdCtrl = stdController;
		po = (Order__c) stdCtrl.getRecord();
		if (isEditingExistingOrder()) {
			
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Editing an existing order'));
			
			heading = po.Name;
			List<Line_Item__c> existingLineItems = [SELECT Units__c, Lot__c, Amount__c FROM Line_Item__c WHERE Order__c = :po.Id];
			for (Line_Item__c li : existingLineItems) {
				quantityMap.put(li.Lot__c, li.Units__c);	
			}
		} else {
			// On a new Purchase Order
			heading = Label.POB_Heading_New;
		}
		
		resetFilter();
	}
	
	/* Public methods
	========================= */
	
	public boolean getNameIsEditable() {
		return (po.Id==null || po.Status__c != 'Closed') ? true : false;
	}
	
	public boolean getBudgetIsEditable() {
		return (po.Id==null || po.Status__c == 'Draft') ? true : false;
	}
	
	public boolean getStatusIsEditable() {
		return (po.Id==null || po.Status__c != 'Closed') ? true : false;
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
		setCtrl.first();
		refreshWrappers();
	}
	
	public void lastPage() { 
		setCtrl.last();
		refreshWrappers();
	}
	
	public boolean getPrevDisabled() {
		return !setCtrl.getHasPrevious();
	}
	
	public boolean getNextDisabled() {
		return !setCtrl.getHasNext();
	}
	
	public Integer getNumberOfPages() {
		Integer recordCount = setCtrl.getResultSize();
		Integer pageSize = setCtrl.getPageSize();
		return recordCount / pageSize + ( Math.mod(recordCount, pageSize) > 0 ? 1 : 0);
	}
	
	public Integer getCurrentPage() {
		return setCtrl.getPageNumber();
	}
	
	public void nextPage() {
		if (setCtrl.getHasNext()) {
			setCtrl.next();
			refreshWrappers();
		}
	}
	
	public void prevPage() {
		if (setCtrl.getHasPrevious()) {
			setCtrl.previous();
			refreshWrappers();
		}
	}
	
	public void updateSelection() {
		if (lotId!=null && quantity!=null) {
			setLotQuantity(lotId, Decimal.valueOf(quantity));
		} else {
			System.debug('*** Selection NOT updated');			
		}
	}
	
	public Decimal getUnits() {
		Decimal totalUnits = 0;
		for (Wrapper w : wrappersMap.values()) {
			totalUnits+=w.units;
		}
		return totalUnits;
	}
	
	public Decimal getPricePerUnit() {
		Decimal totalCost = 0;
		Decimal totalUnits = 0;
		for (Wrapper w : wrappersMap.values()) {
			totalCost += w.product.Unit_Price__c * w.units; 
			totalUnits+=w.units;
		}
		return (totalUnits!=0) ? totalCost/totalUnits : null;
	}
	
	public void resetFilter() {
		categoryFilter = '';
		updateFilter();
	}
	
	public void updateFilter() {
		String soql = (isFilterEnabled()) ? SOQL_WITH_FILTER : SOQL_WITHOUT_FILTER;
		setCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(soql));
		setCtrl.setPageSize(5);
		System.debug('*** Filter is being updated. IsEnabled: ' + isFilterEnabled());
		refreshWrappers();
	}
	
	public boolean validate() {
		return true;
	}
	
	public PageReference save() {
		if (validate()) {
			Savepoint sp = Database.setSavepoint();
			try {
				upsert po;
				PageReference saveResult = stdCtrl.save();
				
				// delete existing line items (if any)
				List<Line_Item__c> lineItems = [SELECT Id FROM Line_Item__c WHERE Order__c = :po.Id];
				if (lineItems!=null && lineItems.size()>0) {
					delete lineItems;
				}
				
				// create & insert new line items
				lineItems = new List<Line_Item__c>();
				for (Wrapper w : wrappersMap.values()) {
					if (w.units > 0) {
						Line_Item__c li = w.toLineItem();
						li.Order__c = po.Id;
						lineItems.add(li);
					}					
				}
				insert lineItems;
				System.debug('*** Save successful ***');
				PageReference nextPage = stdCtrl.view();
				nextPage.setRedirect(true);
				return nextPage;
			} catch (Exception e) {
				// In case of error rollback and stay on the same page (display errors)
				Database.rollback(sp);
				po.addError(e.getMessage());
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.POB_Friendly_Error_Message));
				ApexPages.addMessages(e);
			}
		}
		return null;
	}
	
	/* Utility methods (not exposed)
	================================== */
	
	private void refreshWrappers() {
		wrappers = new List<Wrapper>();
		List<Lot__c> lots = setCtrl.getRecords();
		for (Lot__c l : lots) { 
			Decimal units = getLotQuantity(l.Id);
			Wrapper w = getWrapper(l);
			w.units = units;
			wrappers.add(w);
		}
	}
	
	private boolean isFilterEnabled() {
		Boolean isEnabled = (categoryFilter!=null && categoryFilter!='');
		System.debug('*** IsFilterEnabled: ' + isEnabled + ', Value is: ' + categoryFilter) ;
		return isEnabled;
	}
	
	private boolean isEditingExistingOrder() {
		return (po!=null && po.Id!=null) ? true : false;
	}
	
	@TestVisible
	private void setLotQuantity(Id lotId, Decimal quantity) {
		quantityMap.put(lotId, quantity);
		refreshWrappers();
	}
	
	private Decimal getLotQuantity(Id lotId) {
		Decimal value = quantityMap.get(lotId)!=null ? quantityMap.get(lotId) : 0;
		System.debug('*** Quantity for product ' + lotId + ' is: ' + value);
		return value;
	}
	
	@TestVisible
	private Wrapper getWrapper(Lot__c l) {
		Wrapper w = wrappersMap.get(l.id) !=null ? wrappersMap.get(l.id) : new Wrapper(l, 0);
		wrappersMap.put(l.id, w);
		return w;
	}
	
	/* Inner classes
	========================= */
	
	public class Wrapper {
		
		public Decimal units {set;get;}
		public Lot__c product {set;get;}
		
		public Wrapper(Lot__c product, Decimal units) {
			this.units = units;
			this.product = product;
		}
		
		public Line_Item__c toLineItem() {
			Line_Item__c li = new Line_Item__c();
			li.Units__c = units;
			li.Lot__c = product.Id;
			return li;
		}
	}
	
}