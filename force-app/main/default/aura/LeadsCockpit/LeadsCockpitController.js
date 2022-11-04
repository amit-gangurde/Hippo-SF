({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.isUserAllowed");

        action.setCallback(this,function(data) {

            var state = data.getState();

            if (state === "SUCCESS") {

                var res =  data.getReturnValue();
                console.log('User is allowed to work with Leads Cockpit: ' + res);
                component.set("v.displayCockpit", res);
            }
            else if (state === "INCOMPLETE") {

            }
            else if (state === "ERROR") {

                var toastEvent = $A.get("e.force:showToast");
                var message = '';

                var errors = data.getError();

                if (errors) {

                    for (var i=0; i < errors.length; i++) {

                        for (var j=0; errors[i].pageErrors && j < errors[i].pageErrors.length; j++) {

                            message += (message.length > 0 ? '\n' : '') + errors[i].pageErrors[j].message;
                        }

                        if (errors[i].fieldErrors) {

                            for (var fieldError in errors[i].fieldErrors) {

                                var thisFieldError = errors[i].fieldErrors[fieldError];

                                for(var j=0; j < thisFieldError.length; j++) {

                                    message += (message.length > 0 ? '\n' : '') + thisFieldError[j].message;
                                }
                            }
                        }

                        if (errors[i].message) {

                            message += (message.length > 0 ? '\n' : '') + errors[i].message;
                        }
                    }

                    console.log("Error message: " + message);
                }
                else {

                    console.log("Unknown error");
                    message += (message.length > 0 ? '\n' : '') + 'Unknown error';
                }

                toastEvent.setParams({
                    mode: 'sticky',
                    title: 'Error',
                    type: 'error',
                    message: message
                });

                toastEvent.fire();
            }
            else
            {
                component.set("v.displayCockpit", false);
            }
        });

        $A.enqueueAction(action);
    }
});