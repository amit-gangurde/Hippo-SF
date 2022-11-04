({
    doInit : function(component, event, helper) {
        var action = component.get("c.Accessstoppayment");
        action.setParams({
            "RecordId":component.get("v.recordId")
        });
        action.setCallback(this,function(data){
            
            if(data.getState() === "SUCCESS"){
                var message =  data.getReturnValue();
                var title;
                var  type;
                if(message.includes('Error')){
                    title = 'Error';
                    type = 'Error';
                }else{
                    title = 'Success';
                    type = 'Success'; 
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": title,
                    "message": message,
                    "type" : type
                });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
               // component.set("v.loaded","true");
            }else{
                alert('error');
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                //component.set("v.loaded","true");
            }
            
            
        });
        $A.enqueueAction(action); 
    }
})