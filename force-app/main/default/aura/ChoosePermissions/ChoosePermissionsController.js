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

    handleMouseOver : function(component, event, helper){

        // to set relative top/left of div, get sibling position
        var checkboxGroup = component.find("checkboxGroup").getElement().getBoundingClientRect();

        var containerDiv = component.find("container-div").getElement().getBoundingClientRect();

        // to maintain div scroll, only set positioning once
        if(!(component.get("{!v.scrollerDivTopSet}"))){

            // set scroller-div top
            component.set("{!v.scrollerDivTop}", checkboxGroup.top);

            // set scroller-div left
            component.set("{!v.scrollerDivLeft}", checkboxGroup.right + ((containerDiv.right - checkboxGroup.right)/5));

            // set a sticky top height using dynamically derived coordinates
            component.set("{!v.dynamicStyles}", "position: fixed; border: 1px solid grey; border-radius: 15px;");

            // ensure we don't set again
            component.set("{!v.scrollerDivTopSet}", true);

            // to enable moving div, apply fixed positioning
            $A.util.addClass(component.find("selected-permissions"), "scroller-div");
        }

    },

    handleSelect : function(component, event){

        // get attribute
        var p = component.get("{!v.chosenPerms}");
        
        // apply selected checkbox values to attribute
        p = event.getParam("value");

        // set div content
        component.set("{!v.chosenPerms}", p);

        // show div
        component.set("{!v.showSelectedPermissions}", "true");
    },


    launchAccessChecker : function(component, event, helper){

        var action = component.get("c.createAuditObjects");

        // set apex method param
        action.setParams({ selectedPermissions : component.get("{!v.chosenPerms}")});

        // callback actions
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {

                // process successfully initiated, fire toast
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Saved",
                    "message": "Access check queued. You'll receive an email when it's complete.",
                    "type": "SUCCESS"
                });
                resultsToast.fire();
                
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
})
