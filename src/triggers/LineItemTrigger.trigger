trigger LineItemTrigger on Line_Item__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (Trigger.isAfter && Trigger.isInsert) {
    	LineItemTriggerHandler.handleAfterInsert(Trigger.new);
	}
	

}