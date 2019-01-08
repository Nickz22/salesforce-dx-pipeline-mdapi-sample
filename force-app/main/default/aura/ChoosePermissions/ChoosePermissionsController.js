({
    /*
   * @author          Nick Zozaya
     * @description     dispatch helper action to set checkboxGroup values
   * @return          Void
     * @param         	component, helper
	*/
    getPermSetFields : function(component, helper) {

        var action = component.get("c.getPermissionSetFields");

        // callback actions
        action.setCallback(this, function(response) {

            // get callback status
            var state = response.getState();

            if(state === "SUCCESS"){
            
                helper.getSystemPermissions(component, response.getReturnValue());

            }else if(state === "ERROR"){
                
                helper.handleGetSysPermErrors(component, response.getError());
            }
        });

        // queue @AuraEnabled method
        $A.enqueueAction(action);
    },

    /*
   * @author          Nick Zozaya
     * @description     dispatch helper action to set Selected Permissions values
   * @return          Void
     * @param         	component, event, helper
	*/
    handleSelect : function(component, event, helper){

        helper.setSelectedPermissions(component, event);
    },

    /*
   * @author          Nick Zozaya
     * @description     launch access checker via apex method, then dispatch helper actions to handle return result
   * @return          Void
     * @param         	component, helper
	*/
    launchAccessChecker : function(component, helper){

        var action = component.get("c.createAuditObjects");
        /*
        * infer context from {!v.recordId} attribute, which will be empty if check wasn't launched from Access_Check_Configuration__c record page.
         *
        * set apex params
         */
        action.setParams({ selectedPermissions : component.get("{!v.chosenPerms}"), configId : component.get("{!v.recordId}") });

        // callback actions
        action.setCallback(this, function(response){

            var state = response.getState();

            if(state === "SUCCESS"){

                helper.launchToast(component);

            }else if(state === "ERROR"){

                helper.handleLaunchErrors(response.getError());
            }
        });
        // queue @AuraEnabled method
        $A.enqueueAction(action);
    },
})
