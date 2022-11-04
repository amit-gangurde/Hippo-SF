({
	invoke : function(component, event, helper) {
        $A.get("e.force:navigateToSObject").setParams({
            "recordId": component.get("v.recId")
        }).fire();
	}
})