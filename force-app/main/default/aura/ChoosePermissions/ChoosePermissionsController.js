({
    getPermSetFields : function(component, event, helper) {

        var action = component.get("c.getPermissionSetFields");

        // callback actions
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {

                var returnPerms = response.getReturnValue();

                var optionList = [];

                for(var i = 0; i < returnPerms.length; i++){

                    optionList.push({"label": returnPerms[i], "value": returnPerms[i]});

                }

                component.set("{!v.permissions}", optionList);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        throw new AuraHandledException("Error message: " + 
                        errors[0].message);
                    }
                }
            }
        });
        // queue @AuraEnabled method
        $A.enqueueAction(action);

    }
})
