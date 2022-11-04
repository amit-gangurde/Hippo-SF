({ 
    doInit : function(component, event, helper) {
        var getUserRole = component.get("c.fetchRole");
        getUserRole.setParams({"taskRecordId":component.get("v.recordId")});
        getUserRole.setCallback(this,function(data){
            if(data.getState() === "SUCCESS"){
                component.set("v.usrRole",data.getReturnValue())
               
                var obj = data.getReturnValue();
              //   alert(obj.showApproval)
                if(obj.showApproval == true ){
                //  
                
                component.set("v.isClaimReserve",obj.isClaimReserve)
                component.set("v.showApproval","true");
                var getCRRecords = component.get("c.getClaimCRs");
                getCRRecords.setParams({"taskId":component.get("v.recordId")});
                getCRRecords.setCallback(this,function(data){
                    if(data.getState() === "SUCCESS"){
                        console.log(obj)
                        component.set("v.crList",data.getReturnValue())
                        component.set("v.isSpinner","false");
                    }else if(data.getState() === "ERROR"){
                component.set("v.isSpinner","false");
                var errors = data.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // alert(errors[0].message);
                        component.set("v.errorMessage",errors[0].message);
                        component.set("v.isError","true");
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message:errors[0].message,
                            duration:' 5000',
                            key: 'info_alt',
                            type: 'error'
                            
                        });
                        // toastEvent.fire();
                    }
                }
            }else if (data.getState() === "INCOMPLETE") {
                component.set("v.isSpinner","false");
                component.set("v.errorMessage","Error Occured! Please Contact your Admin.");
                component.set("v.isError","true");
                
            }
                });
                $A.enqueueAction(getCRRecords);
                }else{
                     component.set("v.isSpinner","false");
                }
            }
              component.set("v.isSpinner","false");
        });
        $A.enqueueAction(getUserRole);
        
        
        
    },
    UpdateApprovalInfo : function(component, event, helper) {
        component.set("v.isError","false");
        component.set("v.isSpinner","true");
        var getCRRecords = component.get("c.updateApproval");
        
        getCRRecords.setParams({"claimReserveLst":component.get("v.crList"),"taskId":component.get("v.recordId")});
        getCRRecords.setCallback(this,function(data){
            //  alert(data.getState());
            if(data.getState() === "SUCCESS"){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The record has been updated successfully."
                });
                toastEvent.fire();
                component.set("v.isSpinner","false");
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire(); 
            }else if(data.getState() === "ERROR"){
                component.set("v.isSpinner","false");
                var errors = data.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // alert(errors[0].message);
                        component.set("v.errorMessage",errors[0].message);
                        component.set("v.isError","true");
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error',
                            message:errors[0].message,
                            duration:' 5000',
                            key: 'info_alt',
                            type: 'error'
                            
                        });
                        // toastEvent.fire();
                    }
                }
            }else if (data.getState() === "INCOMPLETE") {
                component.set("v.isSpinner","false");
                component.set("v.errorMessage","Error Occured! Please Contact your Admin.");
                component.set("v.isError","true");
                
            }
        });
        $A.enqueueAction(getCRRecords);
    },
    closeModel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire(); 
    }
})