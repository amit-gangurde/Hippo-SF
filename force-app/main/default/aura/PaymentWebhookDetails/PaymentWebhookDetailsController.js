({
	doInit : function(component, event, helper) {
		var action = component.get("c.getWebHookInfo");
        action.setParams({"recordId":component.get("v.recordId")});
        action.setCallback(this,function(data){
            if(data.getState() === "SUCCESS"){
                var payInfo = data.getReturnValue();
                console.log(payInfo.isWebHookData)
                console.log(payInfo.Id)
                component.set("v.isWebHookData",payInfo.isWebHookData);
                component.set("v.payInfoId",payInfo.Id);
            }
        });
        $A.enqueueAction(action);
	},
    // common reusable function for toggle sections
    toggleSection : function(component, event, helper) {
        // dynamically get aura:id name from 'data-auraId' attribute
        var sectionAuraId = event.target.getAttribute("data-auraId");
        // get section Div element using aura:id
        var sectionDiv = component.find(sectionAuraId).getElement();
        /* The search() method searches for 'slds-is-open' class, and returns the position of the match.
         * This method returns -1 if no match is found.
        */
        var sectionState = sectionDiv.getAttribute('class').search('slds-is-open');

        // -1 if 'slds-is-open' class is missing...then set 'slds-is-open' class else set slds-is-close class to element
        if(sectionState == -1){
            sectionDiv.setAttribute('class' , 'slds-section slds-is-open');
        }else{
            sectionDiv.setAttribute('class' , 'slds-section slds-is-close');
        }
    }
})