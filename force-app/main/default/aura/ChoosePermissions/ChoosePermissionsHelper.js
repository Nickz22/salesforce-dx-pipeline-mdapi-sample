({
    /*
   * @author          Nick Zozaya
     * @description     push returned PermissionSet.SystemPermissions into lightning component
   * @return          Void
     * @param         	component, returnPerms
	*/
    getSystemPermissions : function(component, returnPerms) {

        // initialize container
        var optionList = [];

        // iterate over returned System Permissions
        for(var i = 0; i < returnPerms.length; i++){

            // add permission to container
            optionList.push({ "label" : returnPerms[i], "value" : returnPerms[i]});

        }

        // set attribute value
        component.set("{!v.permissions}", optionList);
    },

    /*
   * @author          Nick Zozaya
     * @description     throw error when apex-action returns error
   * @return          Void
     * @param         	errors
	*/
    handleGetSysPermErrors : function(errors) {

        if (errors) {

            if (errors[0] && errors[0].message) {

                throw new AuraHandledException("Error message: " + errors[0].message);
            }
        }
    },

    /*
   * @author          Nick Zozaya
     * @description     add selected System Permission to attribute
   * @return          Void
     * @param         	component, event
	*/
    setSelectedPermissions : function(component, event){

        // get attribute
        var p = component.get("{!v.chosenPerms}");
        
        // apply selected checkbox values to attribute
        p = event.getParam("value");

        // set div content
        component.set("{!v.chosenPerms}", p);

        // show div
        component.set("{!v.showSelectedPermissions}", "true");
    },

    /*
   * @author          Nick Zozaya
     * @description     fire toast message
   * @return          Void
     * @param         	
	*/
    launchToast : function(){

        // process successfully initiated, fire toast
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": "Saved",
            "message": "Access check queued. You'll receive an email when it's complete.",
            "type": "SUCCESS"
        });

        resultsToast.fire();
    },

    /*
   * @author          Nick Zozaya
     * @description     throw error when apex-action returns error
   * @return          Void
     * @param         	errors
	*/
    handleLaunchError : function(errors){

        if (errors) {
            if (errors[0] && errors[0].message) {
                throw new AuraHandledException("Error message: " + errors[0].message);
            }
        }
    }
})
