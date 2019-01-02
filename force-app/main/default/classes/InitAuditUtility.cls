public class InitAuditUtility {

	static String configId;

	public class utilException extends Exception {}

	// init in-scope object labels
	static final List<String> objApiNames = getInScopeApiNames();
	static final List<String> objLabels = getInScopeLabels();
	static final Map<String, String> scopedMap = getInScopeMap();

	/*
   * @author          Nick Zozaya
     * @description     Method to retrieve ObjectPermissions
   * @return          List<ObjectPermissions>
     * @param           Set<String> revieweeIds
     */
	public static void createConfig(List<String> selectedPermissions){

		D_V__Access_Check_Configuration__c config = new D_V__Access_Check_Configuration__c();

		String sysPerms;

		for(String s : selectedPermissions){

			sysPerms += s+'; ';
		}

		System.debug('sysPerms concatenated string: '+sysPerms);

		config.System_Permissions__c = sysPerms;

		insert config;

		configId = config.Id;
	}

	/*
   * @author          Nick Zozaya
     * @description     Method to retrieve ObjectPermissions
   * @return          List<ObjectPermissions>
     * @param           Set<String> revieweeIds
     */
	public static List<ObjectPermissions> getAllObjectPermissions(){

		// pretty sure we can remove this as List<String> is being set via methods
		List<In_Scope_Object__mdt> scope = [SELECT Label, Api_Name__c FROM In_Scope_Object__mdt];

		if(scope.size() > 0){

			for(In_Scope_Object__mdt inScopeObject : scope){

				objLabels.add(inScopeObject.Label);
				objApiNames.add(inScopeObject.Api_Name__c);
			}

		}else{

			throw new utilException(System.Label.noScopeErrorMsg);

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
     * @param           List<ObjectPermissions> allObjectPermissions, List<PermissionSetAssignment> listPermSetAssignments, Map<Map<String,String>, List<Map<String, String>>> nameByPermissionMap
     */
	public static Map<Map<String,String>, List<Map<String, String>>> findUarUserAccess(List<ObjectPermissions> allObjectPermissions, List<PermissionSetAssignment> listPermSetAssignments, Map<Map<String,String>, List<Map<String, String>>> nameByPermissionMap){
		
		// return Map
		Map<Map<String,String>, List<Map<String, String>>> userPermissionByNameMap = nameByPermissionMap;

		String loopVar;

		// loop thru list of PermissionSetAssignments
		for(PermissionSetAssignment pSa : listPermSetAssignments){

			/*
			* initialize container to hold this assignee's permissions,
			 * with empty entries in it for each in-scope object
			*/
			List<Map<String, String>> c = new List<Map<String, String>>();

			// add map to c for every in-scope object
			for(String label : objLabels){

				// this will hold read, edit, delete, view/modify all info  
				Map<String, String> accessMap = new Map<String, String>();

				// specify object
				accessMap.put('SObjectType', label);

				// add to container
				c.add(accessMap);
			}

			// get parent PermSetId
			loopVar = pSa.PermissionSetId;

			// this will hold Id of Assignee
			Map<String,String> userIdMap = new Map<String,String>();

			// init key of this user's permission map(s)
			userIdMap.put('UserId', pSa.AssigneeId);

			/*
			* To ensure we start with most current permissions, set objAccessMaps 
			 * equal to this user's userPermissionByNameMap entry (userPermissionByNameMap 
			* will either be blank or populated depending on which batch number this is).
			 */
			Map<String, Map<String, String>> objAccessMaps = initAccessMaps(userPermissionByNameMap, userIdMap, objLabels);

			// Loop thru all ObjectPermissions
			for(ObjectPermissions objPermission : allObjectPermissions){

				// isolate type
				String objPermSObjType = objPermission.SobjectType;

				// find matching ObjectPermissions
				if(loopVar == objPermission.ParentId){

					// store this ObjectPermission's relevant fields in map
					Map<String, String> currentPermissionMap = new Map<String, String>{ 'currentReadAccess' => String.valueOf(objPermission.PermissionsRead), 'currentEditAccess' => String.valueOf(objPermission.PermissionsEdit), 'currentDelAccess' => String.valueOf(objPermission.PermissionsDelete), 'currentViewAllAccess' => String.valueOf(objPermission.PermissionsViewAllRecords), 'currentModifyAllAccess' => String.valueOf(objPermission.PermissionsModifyAllRecords)};

					// overwrite this user's existing objAccessMap entry with updated entry
					objAccessMaps.put(scopedMap.get(objPermSObjType), newObjPermissionMap(userPermissionByNameMap, userIdMap, currentPermissionMap, objAccessMaps.get(scopedMap.get(objPermSObjType)), scopedMap.get(objPermSObjType)));
				}
			}
			
			//System.debug('<---objAccessMaps----> \n'+objAccessMaps+'\n <---allAccessMaps---->\n'+allAccessMaps);

			// loop thru user's perms via SObjectType
			for(String key : objAccessMaps.keyset()){
				
				// find which top-level entry matches this key
				for(Map<String, String> m : c){

					// this key matches that key
					if(m.get('SObjectType') == key){
						
						// get keyset of permissions map ("Read_Access", "View_Access", etc.)
						for(String k : objAccessMaps.get(key).keyset()){
							
							if(userPermissionByNameMap != null){

								System.debug('userPermissionByNameMap entry BEFORE this users allAccessMaps.clone() update: '+userPermissionByNameMap);
							}
							/* 
							* add permissions to top-level container, which only 
							 * contains SObjectType prior to this line of code
							*/
							m.put(k, objAccessMaps.get(key).get(k));

							if(userPermissionByNameMap != null){

								System.debug('userPermissionByNameMap entry AFTER this users allAccessMaps.clone() update: '+userPermissionByNameMap);
							}
						}
					}
				}
			}

			// replace old in-memory permissions
			userPermissionByNameMap.put(userIdMap, c);
			System.debug('userPBNM updated: '+userPermissionByNameMap);
		}

		System.debug('<----(FINAL) userPermissionByNameMap---->\n'+userPermissionByNameMap);
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

     	List<In_Scope_Object__mdt> scope = [SELECT Label, Api_Name__c FROM In_Scope_Object__mdt];

		if(scope.size() > 0){

			for(In_Scope_Object__mdt inScopeObject : scope){

				objLabels.add(inScopeObject.Label);
			}
		}else{
			
			throw new utilException(System.Label.noScopeErrorMsg);
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

     	List<In_Scope_Object__mdt> scope = [SELECT Label, Api_Name__c FROM In_Scope_Object__mdt];

		if(scope.size() > 0){

			for(In_Scope_Object__mdt inScopeObject : scope){

				objApiNames.add(inScopeObject.Api_Name__c);
			}
		}else{
			
			throw new utilException(System.Label.noScopeErrorMsg);
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

		List<In_Scope_Object__mdt> scope = [SELECT Label, Api_Name__c FROM In_Scope_Object__mdt];

		if(scope.size() > 0){

			for(In_Scope_Object__mdt inScopeObject : scope){

				objMap.put(inScopeObject.API_Name__c, inScopeObject.Label);
			}
		}else{
			
			throw new utilException(System.Label.noScopeErrorMsg);
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

			// check if user has existing entry for this obj
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
		
		// grab this ObjectPermission's privileges 
		String currentRead = currentPermissionMap.get('currentReadAccess');
		String currentEdit = currentPermissionMap.get('currentEditAccess');
		String currentDel  = currentPermissionMap.get('currentDelAccess');
		String currentModifyAllAccess = currentPermissionMap.get('currentModifyAllAccess');
		String currentViewAllAccess = currentPermissionMap.get('currentViewAllAccess');

		// init empty return map
		Map<String, String> newObjPermMap = new Map<String, String>{'Read_Access' => 'false', 'Edit_Access' => 'false', 'Delete_Access' => 'false', 'View_All_Data' => 'false', 'Modify_All_Data' => 'false'};
		
		// layer this ObjectPermission over top-level in-memory permissions
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
		for(Map<String, String> key : userPermissionByNameMap.keyset()){ 
			
			userIds.add(key.get('UserId'));
		}

		// isolate Users
		Map<Id, User> uar_Users = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN: userIds]);

		// loop thru users and respective permissions
		for(Map<String, String> key : userPermissionByNameMap.keyset()){	

			// init this user's Permission Snapshot
			User_Permissions_Snapshot__c currentUserPermissionSnapshot = new User_Permissions_Snapshot__c();
			currentUserPermissionSnapshot.Name = uar_Users.get(key.get('UserId')).Name;
			currentUserPermissionSnapshot.D_V__User__c = uar_Users.get(key.get('UserId')).Id;
			currentUserPermissionSnapshot.D_V__Modify_All_Access__c = '';
			currentUserPermissionSnapshot.D_V__View_All_Access__c = '';
			currentUserPermissionSnapshot.D_V__Delete_Access__c = '';
			currentUserPermissionSnapshot.D_V__Edit_Access__c = '';
			currentUserPermissionSnapshot.D_V__Read_Access__c = '';

			
			// grab user's access to each obj
			List<Map<String, String>> objPermissionsList = userPermissionByNameMap.get(key);

			// loop thru each entry
			for(Map<String, String> objPermission : objPermissionsList){

				// isolate type
				String sObjType = objPermission.get('SObjectType');

				// update snapshot
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
		/*Map<Id, PermissionSet> allPermissionSets = new Map<Id, PermissionSet>(
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
												 );*/

		// get field to create query string out of
		D_V__Access_Check_Configuration__c config = [SELECT System_Permissions__c FROM D_V__Access_Check_Configuration__c WHERE Id=: configId];

		// create query substring out of semi-colon separated field
		String queryFields = config.System_Permissions__c.replace(';', ',');

		// create query string
		String queryString = '[SELECT '+queryFields+' FROM PermissionSet WHERE Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN: userIds)]'; 

		// dyanamic SOQL
		Map<Id, PermissionSet> allPermissionSets = new Map<Id, PermissionSet>((List<PermissionSet>) Database.query(queryString));

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