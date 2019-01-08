@isTest (SeeAllData=false)
private class initAuditReviewTest {

	static final List<String> homeLaunchPermissions = new List<String>{'Send Email', 'Mass Email', 'Edit Tasks'};

	/*
   * @author          Nick Zozaya
     * @description     Test Access Check launch from app homepage
   * @return          Void
     * @param         	
	 */
	@isTest (SeeAllData=false)
	static void createAuditObjectsTest() {

		// create access check configuration
		initAuditReview.createAuditObjects(homeLaunchPermissions, '');

		// get new snapshots
		Map<Id, User_Permissions_Snapshot__c> snapshots = new Map<Id, User_Permissions_Snapshot__c>([SELECT Id, User__c, Read_Access__c, Create_Access__c, Edit_Access__c, Delete_Access__c, View_All_Access__c, Modify_All_Access__c, System_Permissions__c FROM User_Permissions_Snapshot__c]);

		// get active users
		List<User> activeUsers = [SELECT Id, Profile.Name FROM User WHERE IsActive = TRUE AND Profile.Name != null];

		// get active user's (w/ profiles) PermissionSets
		Map<Id, PermissionSet> pSets = new Map<Id, PermissionSet>([SELECT Id, PermissionsEmailSingle, PermissionsEmailMass, PermissionsEditTask 
									   FROM PermissionSet
									   WHERE Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE Assignee.IsActive = true)]);

		// get active user PermissionSetAssignments
		List<PermissionSetAssignment> assignments = [SELECT PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE Assignee.IsActive = true];

		// ensure correct amount of snapshots were created
		System.assertEquals(activeUsers.size(), snapshots.size(), 'incorrect snapshot quantity detected');

		// get in-scope objects, defined by In_Scope_Object_mdt
		Map<String, String> scopedObjMap = initAuditUtility.getInScopeMap();

		// get active user's ObjectPermissions
		List<ObjectPermissions> objPerms = [SELECT SObjectType, ParentId, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords
				 							  FROM ObjectPermissions
				 							 WHERE ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE Assignee.IsActive = true) 
											  AND SobjectType IN: scopedObjMap.keyset()];
		
		Map<Id, List<ObjectPermissions>> userToPermission = new Map<Id, List<ObjectPermissions>>();
		List<ObjectPermissions> lo = new List<ObjectPermissions>();
		String uId;

		// give ObjectPermissions a PermissionSetAssignment.AssigneeId key
		for(PermissionSetAssignment p : assignments){

			// refresh our list container
			lo = new List<ObjectPermissions>();

			// keep assigneeId
			uId = p.AssigneeId;

			// look for matching ObjectPermissions
			for(ObjectPermissions o : objPerms){
				
				// compare o and p PermissionSetId
				if(o.ParentId == p.PermissionSetId){
					
					// add matching obj perm to container
					lo.add(o);
				}
			}

			// check for existing entry for this user
			if(userToPermission.get(uId) == null){
				
				// add first key-value set
				userToPermission.put(uId, lo);
			}else{
				
				// get user's in-memory permissions
				List<ObjectPermissions> currentPerms = userToPermission.get(uId);

				// add this ObjectPermissions list to in-memory list
				currentPerms.addAll(lo);

				// update in-memory list
				userToPermission.put(uId, currentPerms);
			}
		}

		// validate object permissions
		for(User_Permissions_Snapshot__c u : snapshots.values()){
			
			// containers for snapshot fields
			List<String> read = u.Read_Access__c == null ? new List<String>() : u.Read_Access__c.split(';');
			List<String> create = u.Create_Access__c == null ? new List<String>() : u.Create_Access__c.split(';');
			List<String> edit = u.Edit_Access__c == null ? new List<String>() : u.Edit_Access__c.split(';');
			List<String> d = u.Delete_Access__c == null ? new List<String>() : u.Delete_Access__c.split(';');
			List<String> viewAll = u.View_All_Access__c == null ? new List<String>() : u.View_All_Access__c.split(';');
			List<String> modifyAll = u.Modify_All_Access__c == null ? new List<String>() : u.Modify_All_Access__c.split(';');

			// loop through user Ids
			for(String assignee : userToPermission.keyset()){
				
				// found snapshot user
				if(assignee == u.User__c){
					
					// loop through user's in-memory ObjectPermissions
					for(ObjectPermissions o : userToPermission.get(assignee)){

						// isolate ObjectPermissions type
						String type = o.SobjectType;
						
						// assert snapshot fields based on ObjectPermission fields
						if(o.PermissionsRead){
							
							// ensure snapshot reflects permissions in ObjectPermission
							System.assertEquals(true, u.Read_Access__c.contains(type), '<---- snapshot read field inconsistency detected ----> ObjectPermission read: '+o.PermissionsRead+' snapshot read: '+u.Read_Access__c);
						    /*
							* explanation of why we're removing values from String representation of snapshot fields ☞ 4513e9a0-9197-4fc2-8101-5bbb864bcce3
							 *
							* check if this type has already been removed - this will be true if an ObjectPermission has already
							 * granted this level of access. In this case, we don't need to re-remove the type.
							*/
							if(read.indexOf(type) != -1){

									// remove the SObjectType we just checked
									String s = read.remove(read.indexOf(type));
									System.assertEquals(type, s, 'incorrect entry removed');		
							}
						}
						if(o.PermissionsCreate){

							System.assertEquals(true, u.Create_Access__c.contains(type), '<---- snapshot create field inconsistency detected ----> \n ObjectPermission create: '+o.PermissionsCreate+'\n snapshot create: '+u.Create_Access__c);
							
							if(create.indexOf(type) != -1){

									// remove the SObjectType we just checked
									String s = create.remove(create.indexOf(type));
									System.assertEquals(type, s, 'incorrect entry removed');		
							}
						}
						if(o.PermissionsEdit){
							
							System.assertEquals(true, u.Edit_Access__c.contains(type), '<---- snapshot edit field inconsistency detected ----> \n ObjectPermission edit: '+o.PermissionsEdit+'\n snapshot edit: '+u.Edit_Access__c);

							if(edit.indexOf(type) != -1){

									// remove the SObjectType we just checked
									String s = edit.remove(edit.indexOf(type));
									System.assertEquals(type, s, 'incorrect entry removed');		
							}
						}
						if(o.PermissionsDelete){

							System.assertEquals(true, u.Delete_Access__c.contains(type), '<---- snapshot delete field inconsistency detected ----> \n ObjectPermission delete: '+o.PermissionsDelete+'\n snapshot delete: '+u.Delete_Access__c);

							if(d.indexOf(type) != -1){

									// remove the SObjectType we just checked
									String s = d.remove(d.indexOf(type));
									System.assertEquals(type, s, 'incorrect entry removed');		
							}
						}
						if(o.PermissionsViewAllRecords){

							System.assertEquals(true, u.View_All_Access__c.contains(type), '<---- snapshot view all field inconsistency detected ----> \n ObjectPermission view all: '+o.PermissionsViewAllRecords+'\n snapshot view all: '+u.View_All_Access__c);

							if(viewAll.indexOf(type) != -1){

									// remove the SObjectType we just checked
									String s = viewAll.remove(viewAll.indexOf(type));
									System.assertEquals(type, s, 'incorrect entry removed');		
							}
						}
						if(o.PermissionsModifyAllRecords){

							System.assertEquals(true, u.Modify_All_Access__c.contains(type), '<---- snapshot read field inconsistency detected ----> \n ObjectPermission modify all: '+o.PermissionsModifyAllRecords+'\n snapshot modify all: '+u.Modify_All_Access__c);

							if(modifyAll.indexOf(type) != -1){

									// remove the SObjectType we just checked
									String s = modifyAll.remove(modifyAll.indexOf(type));
									System.assertEquals(type, s, 'incorrect entry removed');		
							}
						}
					}
				}
			}
			/*
			* validate User_Permissions_Snapshot__c 
			 * for excessive object permissions.
			*/
			System.assertEquals(read.size(), 0, 'snapshot read excessive permissions detected: '+read);
			System.assertEquals(create.size(), 0, 'snapshot create excessive permissions detected: '+create);
			System.assertEquals(edit.size(), 0, 'snapshot edit excessive permissions detected: '+edit);
			System.assertEquals(d.size(), 0, 'snapshot delete excessive permissions detected: '+d);
			System.assertEquals(viewAll.size(), 0, 'snapshot viewAll excessive permissions detected: '+viewAll);
			System.assertEquals(modifyAll.size(), 0, 'snapshot modifyAll excessive permissions detected: '+modifyAll);
		}
	}
}