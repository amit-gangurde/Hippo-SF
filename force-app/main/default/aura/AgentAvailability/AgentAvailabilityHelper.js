({

    initUtilityItem : function(component, event, helper) {

        //debugger;

        const utilityBarAPI = component.find("utilitybar");
        utilityBarAPI.getEnclosingUtilityId().then(function (utilityId) {

            console.log("utilityId", utilityId);
        });

        utilityBarAPI.getUtilityInfo().then(function(response) {

            console.log(response);

            if (typeof response !== 'undefined') {

                if (response.utilityVisible) {

                    //utilityBarAPI.minimizeUtility();
                } else {

                    helper.disableUtilityPopOut(component, event, helper);
                    //utilityBarAPI.openUtility();
                }
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    disableUtilityPopOut: function(component, event, helper) {

        var utilityBarAPI = component.find("utilitybar");

        utilityBarAPI.disableUtilityPopOut({
            disabled: true,
            disabledText: "Pop-out is disabled"
        });

        helper.setAgentAvailability(component, event, helper);
    },

    setAgentAvailability: function (component, event, helper) {

        //debugger;

        var action = component.get("c.anyAgentAvailable_v2");
        action.setParams({ queueDevName : 'HAS_Internal_Referrals' });

        // Create a callback that is executed after
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Print the value returned from the server
                var res = response.getReturnValue();
                console.log("anyAgentAvailable (From server): " + res);

                var utilityBarAPI = component.find("utilitybar");

                if (res === true) {

                    utilityBarAPI.setUtilityLabel({label: $A.get("$Label.c.HAS_available_for_Warm_Transfer")});
                    utilityBarAPI.setUtilityIcon({
                        icon: "success",
                        options:{
                            iconVariant: "success"
                        }
                    });
                }
                else {

                    utilityBarAPI.setUtilityLabel({label: $A.get("$Label.c.HAS_not_available_for_Warm_Transfer")});
                    utilityBarAPI.setUtilityIcon({
                        icon: "error",
                        options:{
                            iconVariant: "error"
                        }
                    });
                }

                // fire LMS event to LWC component that also visualize the same availability indication
                var payload = {
                    IsAgentAvailable: res
                };
                component.find("lmsCTIAgentAvailability").publish(payload);

                // You would typically fire a event here to trigger
                // client-side notification that the server-side
                // action is complete
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }

            setTimeout(function() {
                helper.disableUtilityPopOut(component, event, helper);
            }, 500);
        });

        // optionally set storable, abortable, background flag here

        // A client-side action could cause multiple events,
        // which could trigger other events and
        // other server-side action calls.
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
    }
});