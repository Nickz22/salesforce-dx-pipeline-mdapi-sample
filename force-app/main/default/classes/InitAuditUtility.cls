public class InitAuditUtility {

	// init in-scope object labels
	static final List<String> objApiNames = getInScopeApiNames();
	static final List<String> objLabels = getInScopeLabels();

	/*
   * @author          Nick Zozaya
     * @description     Method to retrieve ObjectPermissions
   * @return          List<ObjectPermissions>
     * @param           Set<String> revieweeIds
     */
	public static List<ObjectPermissions> getAllObjectPermissions(){

		for(In_Scope_Audit_Object__mdt inScopeObject : [SELECT Label, Api_Name__c FROM In_Scope_Audit_Object__mdt]){

			objLabels.add(inScopeObject.Label);
			objApiNames.add(inScopeObject.Api_Name__c);
		}
		/*
		** Find any ObjectPermission where ParentId == PermissionSetAssignment.PermissionSetId
		*/
		List<ObjectPermissions> allObjectPermissions = [SELECT Id, ParentId, PermissionsRead, PermissionsDelete, PermissionsEdit, PermissionsViewAllRecords, PermissionsModifyAllRecords, SObjectType
														FROM ObjectPermissions
														WHERE (ParentId IN (SELECT PermissionSetId
																			FROM PermissionSetAssignment
																			WHERE Assignee.IsActive = true))
														AND
														PermissionsRead = true
														AND
											 		   SobjectType IN: objApiNames];


		return allObjectPermissions;

	} 

    /*
   * @author          Nick Zozaya
     * @description     Method to retrieve Map of User.Id to ObjectPermissions
   * @return          Map<Map<String,String>, List<Map<String, String>>>
     * @param           Set<String> revieweeIds
     */
	public static Map<Map<String,String>, List<Map<String, String>>> findUarUserAccess(List<ObjectPermissions> allObjectPermissions, List<PermissionSetAssignment> listPermSetAssignments, Map<Map<String,String>, List<Map<String, String>>> nameByPermissionMap){
		
		// init return Map
		Map<Map<String,String>, List<Map<String, String>>> userPermissionByNameMap = nameByPermissionMap;

		// init top-level permissions container for all objects
		Map<String, String> opportunityAccessMap = new Map<String, String>();
		Map<String, String> accountAccessMap = new Map<String, String>();
		Map<String, String> caseAccessMap = new Map<String, String>();

		String loopVar;

		// loop thru list of map {PermissionSetId => PermissionSetAssignment}
		for(PermissionSetAssignment pSa : listPermSetAssignments){

			// keep top-level loop key
			loopVar = pSa.PermissionSetId;

			// keep Id of Assignee
			Map<String,String> userIdMap = new Map<String,String>();

			// init key of this users permissions map
			userIdMap.put('UserId', pSa.AssigneeId);

			// initialize empty entries for each object
			Map<String, Map<String, String>> objAccessMaps = initAccessMaps(userPermissionByNameMap, userIdMap, objLabels);

			// Loop thru all ObjectPermissions
			for(ObjectPermissions objPermission : allObjectPermissions){

				// isolate type
				String objPermSObjType = objPermission.SobjectType;

				// find matching ObjectPermissions
				if(loopVar == objPermission.ParentId){

					// store in-loop SObjectPermission in map
					Map<String, String> currentPermissionMap = new Map<String, String>{ 'currentReadAccess' => String.valueOf(objPermission.PermissionsRead), 'currentEditAccess' => String.valueOf(objPermission.PermissionsEdit), 'currentDelAccess' => String.valueOf(objPermission.PermissionsDelete), 'currentViewAllAccess' => String.valueOf(objPermission.PermissionsViewAllRecords), 'currentModifyAllAccess' => String.valueOf(objPermission.PermissionsModifyAllRecords)};

					// check type of in-loop obj permission
					if(objPermSObjType == Constants.OPPORTUNITY_OBJ){

						objAccessMaps.put(Constants.OPPORTUNITY_OBJ, newObjPermissionMap(userPermissionByNameMap, userIdMap, currentPermissionMap, objAccessMaps.get(Constants.OPPORTUNITY_OBJ), Constants.OPPORTUNITY_OBJ));

					}else if(objPermSObjType == Constants.ACCOUNT_OBJ){
						
						objAccessMaps.put(Constants.ACCOUNT_OBJ, newObjPermissionMap(userPermissionByNameMap, userIdMap, currentPermissionMap, objAccessMaps.get(Constants.ACCOUNT_OBJ), Constants.ACCOUNT_OBJ));

					}else if(objPermSObjType == Constants.CASE_OBJ){
						
						objAccessMaps.put(Constants.CASE_OBJ, newObjPermissionMap(userPermissionByNameMap, userIdMap, currentPermissionMap, objAccessMaps.get(Constants.CASE_OBJ), Constants.CASE_OBJ));
					
					}
				}
			}

			// init entries for this PermissionSetAssignment Assignee
			opportunityAccessMap = getPermissionMap(objAccessMaps.get(Constants.OPPORTUNITY_OBJ), Constants.OPPORTUNITY_OBJ);
			accountAccessMap = getPermissionMap(objAccessMaps.get(Constants.ACCOUNT_OBJ), Constants.ACCOUNT_OBJ);
			caseAccessMap = getPermissionMap(objAccessMaps.get(Constants.CASE_OBJ), Constants.CASE_OBJ);
			
			// initialize updated top-level in-memory permission for each object
			List<Map<String, String>> uarUserAccessList = new List<Map<String, String>>{opportunityAccessMap, accountAccessMap, caseAccessMap};

			// replace old in-memory permissions
			userPermissionByNameMap.put(userIdMap, uarUserAccessList);
		}

		// return all users permissions
		return userPermissionByNameMap;
	}

	/*
   * @author          Nick Zozaya
     * @description     Method to return in-scope object labels
   * @return          List<String>
     * @param           
     */
     public static List<String> getInScopeLabels(){

     	List<String> objLabels = new List<String>();

     	for(In_Scope_Audit_Object__mdt inScopeObject : [SELECT Label, Api_Name__c FROM In_Scope_Audit_Object__mdt]){

			objLabels.add(inScopeObject.Label);
		}

		return objLabels;
     }

	/*
   * @author          Nick Zozaya
     * @description     Method to return in-scope object labels
   * @return          List<String>
     * @param           
     */
     public static List<String> getInScopeApiNames(){

     	List<String> objApiNames = new List<String>();

     	for(In_Scope_Audit_Object__mdt inScopeObject : [SELECT Label, Api_Name__c FROM In_Scope_Audit_Object__mdt]){

			objApiNames.add(inScopeObject.Api_Name__c);
		}

		return objApiNames;
     }

     /*
   * @author          Nick Zozaya
     * @description     Method to return in-scope object labels => apiName map
   * @return          Map<String, String>
     * @param           
     */
     public static Map<String, String> getInScopeMap(){

     	Map<String, String> objMap = new Map<String, String>();

     	for(In_Scope_Audit_Object__mdt inScopeObject : [SELECT Label, Api_Name__c FROM In_Scope_Audit_Object__mdt]){

			objMap.put(inScopeObject.API_Name__c, inScopeObject.Label);
		}

		return objMap;
     }


	/*
   * @author          Nick Zozaya
     * @description     Method to return top-level in memory user permissions.
   * @return          Map<String, Map<String, String>>
     * @param           Map<Map<String,String>, List<Map<String, String>>> userPermissionByNameMap, Map<String, String> userIdMap, List<String>  sObjectTypes
     */
	public static Map<String, Map<String, String>> initAccessMaps(Map<Map<String,String>, List<Map<String, String>>> userPermissionByNameMap, Map<String, String> userIdMap, List<String> sObjectTypes) {
		
		// return map
		Map<String, Map<String, String>> objAccessMaps = new Map<String, Map<String, String>>();

		// loop var
		Map<String, String> objAccessMap = new Map<String, String>();


		for(String objLabel : sObjectTypes){

			// init blank entry for each object
			objAccessMap = new Map<String, String>{'Read_Access'=>'false', 'Edit_Access'=>'false', 'Delete_Access'=>'false', 'View_All_Data'=>'false', 'Modify_All_Data'=>'false'};

			// check if user has an existing top-level entry
			if(userPermissionByNameMap.get(userIdMap)!=null){

				// loop through user's top-level entries
				for(Map<String,String> existingObjRight : userPermissionByNameMap.get(userIdMap)){

					// find this object's entry
					if(existingObjRight.get('SObjectType') == objLabel){

						// update in-loop memory with top-level access
						objAccessMap = existingObjRight;
					}
				}
			}

			// add this object's access to return map
			objAccessMaps.put(objLabel, objAccessMap);

		}
		
		return objAccessMaps;
	}

	/*
   * @author          Nick Zozaya
     * @description     Method to return updated object permission map for given sObjectType
   * @return          Map<String, String>
     * @param           Map<Map<String, String>, List<Map<String, String>>> userPermissionByNameMap, Map<String, String> userIdMap, Map<String, String> currentPermissionMap, Map<String, String> storedObjPermMap, String objLabel
     */
	public static Map<String, String> newObjPermissionMap(Map<Map<String, String>, List<Map<String, String>>> userPermissionByNameMap, Map<String, String> userIdMap, Map<String, String> currentPermissionMap, Map<String, String> storedObjPermMap, String objLabel){
		
		// grab in-loop object permission privileges
		String currentRead = currentPermissionMap.get('currentReadAccess');
		String currentEdit = currentPermissionMap.get('currentEditAccess');
		String currentDel  = currentPermissionMap.get('currentDelAccess');
		String currentModifyAllAccess = currentPermissionMap.get('currentModifyAllAccess');
		String currentViewAllAccess = currentPermissionMap.get('currentViewAllAccess');

		// return map
		Map<String, String> newObjPermMap = new Map<String, String>{'Read_Access' => 'false', 'Edit_Access' => 'false', 'Delete_Access' => 'false', 'View_All_Data' => 'false', 'Modify_All_Data' => 'false'};
		
		// layer in-loop obj permission over top-level in-memory permissions
		if(currentRead == 'true' || currentEdit == 'true' || currentDel == 'true' || currentModifyAllAccess == 'true' || currentViewAllAccess == 'true'){

			// if additional permissions found, add to return map
			if(currentRead == 'true'){ newObjPermMap.put('Read_Access', 'true');}else{newObjPermMap.put('Read_Access', storedObjPermMap == null ? 'false' : storedObjPermMap.get('Read_Access'));}
			if(currentEdit == 'true'){ newObjPermMap.put('Edit_Access', 'true');}else{newObjPermMap.put('Edit_Access', storedObjPermMap == null ? 'false' : storedObjPermMap.get('Edit_Access'));}
			if(currentDel == 'true'){ newObjPermMap.put('Delete_Access', 'true');}else{newObjPermMap.put('Delete_Access', storedObjPermMap == null ? 'false' : storedObjPermMap.get('Delete_Access'));}
			if(currentViewAllAccess == 'true'){ newObjPermMap.put('View_All_Data', 'true');}else{newObjPermMap.put('View_All_Data', storedObjPermMap == null ? 'false' : storedObjPermMap.get('View_All_Data'));}
			if(currentModifyAllAccess == 'true'){ newObjPermMap.put('Modify_All_Data', 'true');}else{newObjPermMap.put('Modify_All_Data', storedObjPermMap == null ? 'false' : storedObjPermMap.get('Modify_All_Data'));}

		}

		return newObjPermMap;
	}

	/*
   * @author          Nick Zozaya
     * @description     Method to couple object label and it's corresponding access map
   * @return          Map<String, String>
     * @param           Map<String, String> objMap, String objLabel
     */
	public static Map<String, String> getPermissionMap(Map<String, String> objMap, String objLabel){

		// Map<String, String> objAccessMap = new Map<String, String>();


		objMap.put('SObjectType', objLabel);

		return objMap;

	}

	/*
   * @author          Nick Zozaya
     * @description     Method to return Map of user id to corresponding snapshot
   * @return          Map<Id, User_Permissions_Snapshot__c>
     * @param           Map<Map<String,String>,List<Map<String,String>>> userPermissionByNameMap
     */
	public static Map<Id, User_Permissions_Snapshot__c> newSnapshotPermissions(Map<Map<String,String>,List<Map<String,String>>> userPermissionByNameMap){

		// init return map
		Map<Id, User_Permissions_Snapshot__c> returnMap = new Map<Id, User_Permissions_Snapshot__c>();

		// store user ids for apex bind var
		List<String> userIds = new List<String>();

		// user id for each permission map
		for(Map<String, String> key : userPermissionByNameMap.keyset()) userIds.add(key.get('UserId'));

		// isolate Users
		Map<Id, User> uar_Users = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN: userIds]);

		// loop thru users and respective permissions
		for(Map<String, String> key : userPermissionByNameMap.keyset()){

			// init this user's Permission Snapshot
			User_Permissions_Snapshot__c currentUserPermissionSnapshot = new User_Permissions_Snapshot__c();
			currentUserPermissionSnapshot.Name = uar_Users.get(key.get('UserId')).Name;
			currentUserPermissionSnapshot.User__c = uar_Users.get(key.get('UserId')).Id;
			currentUserPermissionSnapshot.Modify_All_Access__c = '';
			currentUserPermissionSnapshot.View_All_Access__c = '';
			currentUserPermissionSnapshot.Delete_Access__c = '';
			currentUserPermissionSnapshot.Edit_Access__c = '';
			currentUserPermissionSnapshot.Read_Access__c = '';

			
			// grab user's access to each obj
			List<Map<String, String>> objPermissionsList = userPermissionByNameMap.get(key);

			// loop thru each entry
			for(Map<String, String> objPermission : objPermissionsList){

				// isolate type
				String sObjType = objPermission.get('SObjectType');

				// update snapshot

				/*
				 * need to test this code to see if it takes care of multiple object types being added to one picklist field
				*/
				if(objPermission.get('Modify_All_Data') == 'true' && !(currentUserPermissionSnapshot.Modify_All_Access__c.contains(sObjType))) currentUserPermissionSnapshot.Modify_All_Access__c += sObjType+'; ';
				if(objPermission.get('View_All_Data') == 'true' && !(currentUserPermissionSnapshot.View_All_Access__c.contains(sObjType))) currentUserPermissionSnapshot.View_All_Access__c += sObjType+'; ';
				if(objPermission.get('Delete_Access') == 'true' && !(currentUserPermissionSnapshot.Delete_Access__c.contains(sObjType))) currentUserPermissionSnapshot.Delete_Access__c += sObjType+'; ';
				if(objPermission.get('Edit_Access') == 'true' && !(currentUserPermissionSnapshot.Edit_Access__c.contains(sObjType))) currentUserPermissionSnapshot.Edit_Access__c += sObjType+'; ';
				if(objPermission.get('Read_Access') == 'true' && !(currentUserPermissionSnapshot.Read_Access__c.contains(sObjType))) currentUserPermissionSnapshot.Read_Access__c += sObjType+'; ';
			}

			// add users snapshot to return map
			returnMap.put(currentUserPermissionSnapshot.User__c, currentUserPermissionSnapshot);
		}

		// insert snapshots
		insert returnMap.values();

		return returnMap;
	}

	/*
   * @author          Nick Zozaya
     * @description     Method to update new snapshots with system permissions
   * @return          void
     * @param           Map<Id, User_Permissions_Snapshot__c> newSnapshots
     */
	public static void updateSystemPermissions(Map<Id, User_Permissions_Snapshot__c> newSnapshots){

		// isolate user ids for apex bind var
		Set<Id> userIds = newSnapshots.keyset();

		// get permissionSetAssignments related to snapshots
		Map<Id, PermissionSetAssignment> assignments = new Map<Id, PermissionSetAssignment>([SELECT PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN: userIds]);

		// get in-scope system permissions from related permissionSets
		Map<Id, PermissionSet> allPermissionSets = new Map<Id, PermissionSet>(
														[SELECT PermissionsApiEnabled, PermissionsAuthorApex, PermissionsBulkApiHardDelete,
														PermissionsCreateCustomizeReports,
														PermissionsInstallPackaging, PermissionsImportCustomObjects,
														PermissionsManagePvtRptsAndDashbds, PermissionsManageRemoteAccess,
														PermissionsManageCustomPermissions, PermissionsManageCustomReportTypes, PermissionsManageDashbdsInPubFolders,
														PermissionsManageDataIntegrations, PermissionsManageInteraction, PermissionsManageReportsInPubFolders, 
														PermissionsManageSessionPermissionSets, PermissionsManageTwoFactor, PermissionsDelegatedTwoFactor,
														PermissionsModifyMetadata, PermissionsPasswordNeverExpires, PermissionsCreateReportInLightning,
														PermissionsNewReportBuilder, PermissionsScheduleReports, PermissionsTransferAnyEntity, 
														PermissionsTwoFactorApi, PermissionsForceTwoFactor, PermissionsAssignPermissionSets,
														PermissionsManageInternalUsers, PermissionsManageIpAddresses, PermissionsManageLoginAccessPolicies, 
														PermissionsManagePasswordPolicies, PermissionsManageProfilesPermissionsets, PermissionsManageRoles, 
														PermissionsManageSharing, PermissionsManageUsers, PermissionsResetPasswords, PermissionsViewAllUsers
												 FROM PermissionSet 
												 WHERE Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN: userIds)]
												 );
		// init Schema.SObjectType param
		final String objType = 'PermissionSet';

		// get map {field api name => field label}
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType schema = schemaMap.get(objType);
		Map<String, Schema.SObjectField> fieldMap = schema.getDescribe().fields.getMap();

		// init update list
		List<User_Permissions_Snapshot__c> updateSnapshots = new List<User_Permissions_Snapshot__c>();

		// init loop var
		PermissionSetAssignment loopVar;

		// loop thru snapshots
		for(User_Permissions_Snapshot__c snapshot : newSnapshots.values()){

			// loop thru assignment Ids
			for(Id key : assignments.keyset()) {

				// get PermissionSetAssignment
				loopVar = assignments.get(key);

				// find assignments where assignee == snapshot user
				if(snapshot.User__c == loopVar.AssigneeId){

					// get related PermissionSet
					PermissionSet p = allPermissionSets.get(loopVar.PermissionSetId);

					// get in-memory PermissionSet fields
					Map<String, Object> fieldsToValue = p.getPopulatedFieldsAsMap();

					// loop over PermissionSet system permissions
					for(String fieldName : fieldsToValue.keyset()){

						// check if PermissionSet grants permission
						if(fieldsToValue.get(fieldName) == true){

							// get label string from field token
							String label = String.valueOf(fieldMap.get(fieldName).getDescribe().getLabel());

							// to ensure we dont add duplicate values, check current picklist values
							if(snapshot.System_Permissions__c != null && !(snapshot.System_Permissions__c.contains(label))){

								// add this label to field
								snapshot.System_Permissions__c += label+ '; ';	

							}else if(snapshot.System_Permissions__c == null){

								// add first label to field
								snapshot.System_Permissions__c = label+'; ';
							}	
						}
					}
				}
			}
			// add updated snapshot to update list
			updateSnapshots.add(snapshot);
		}

		update updateSnapshots;
	}	

	public static String getAutoProcUserEmail(){
        User autoProc = [SELECT Email FROM User WHERE Email LIKE 'autoproc@%' LIMIT 1];
        return autoProc.Email;
    }
}