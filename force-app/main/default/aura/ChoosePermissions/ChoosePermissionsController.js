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

            // set scroller-div top to height of checkboxGroup
            component.set("{!v.scrollerDivTop}", checkboxGroup.top);

            // set scroller-div next to checkboxGroup
            component.set("{!v.scrollerDivLeft}", checkboxGroup.right + ((containerDiv.right - checkboxGroup.right)/10));

            // component.set("{!v.scrollerDivBottom}", checkboxGroup.bottom);

            // set a sticky top height using dynamically derived coordinates
            component.set("{!v.dynamicStyles}", "position: fixed; border: 1px solid #fe840e; border-radius: 15px;");

            // ensure we don't set again
            component.set("{!v.scrollerDivTopSet}", true);
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

        // get apex method
        var action = component.get("c.createAuditObjects");
        /*
        * infer context from {!v.recordId} attribute, which 
         * will be empty if check wasn't launched from
        * Access Check Configuration record page.
         */        

        // set apex params
        action.setParams({ 
                            selectedPermissions : component.get("{!v.chosenPerms}"),
                            configId : component.get("{!v.recordId}")
                        });

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
                
            }else if (state === "ERROR") {
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
