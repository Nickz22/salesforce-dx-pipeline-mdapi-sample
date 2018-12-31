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

    },

    launchAccessChecker : function(component, event, helper){


    },

    handleSelect : function(component, event, helper){

        var text = component.get("{!v.chosenPerms}");
        
        text = event.getParam("value");

        var checkboxGroup = component.find('checkboxGroup').getElement().getBoundingClientRect();

        console.log('outerDiv.getBoundingClientRec().top: '+checkboxGroup.top);

        if(!(component.get("{!v.scrollerDivTopSet}"))){

            // set scroller-div top
            component.set("{!v.scrollerDivTop}", checkboxGroup.top);

            // set scroller-div right
            component.set("{!v.scrollerDivLeft}", checkboxGroup.right);

            component.set("{!v.scrollerDivTopSet}", true);
        }

        // set div content
        component.set("{!v.chosenPerms}", text);

        // show div
        component.set("{!v.showSelectedPermissions}", "true");
    }
})
