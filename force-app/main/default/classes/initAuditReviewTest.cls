@isTest (SeeAllData=false)
private class initAuditReviewTest {

	// static final String alias = 'sys_adm';

	@isTest (SeeAllData=false)
	static void createAuditObjectsTest() {

		initAuditReview.createAuditObjects();
	/*
		Map<Id, User_Permissions_Snapshot__c> snapshots = new Map<Id, User_Permissions_Snapshot__c>([SELECT Id FROM User_Permissions_Snapshot__c]);

		List<PermissionSetAssignment> pSa = [SELECT PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId=:uarUsers[0].User__c ];

		System.assert(pSa != null, 'pSa is null');

		Map<String, String> scopedObjMap = initAuditUtility.getInScopeMap();
		
		List<ObjectPermissions> objPerms = [SELECT SObjectType, PermissionsRead, PermissionsEdit, PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords
				 							  FROM ObjectPermissions
				 							 WHERE ParentId =: pSa[0].PermissionSetId AND SobjectType IN: scopedObjMap.keyset()];

		User_Permissions_Snapshot__c uPs = [SELECT Read_Access__c, Edit_Access__c, Delete_Access__c, View_All_Access__c, Modify_All_Access__c, User__c, User__r.LastName FROM User_Permissions_Snapshot__c WHERE User__c=: uarUsers[0].User__c];
		
		System.assert(uPs != null, 'no snapshot with given UserId found');
		System.debug('uPs: ' +uPs);
/*
 * begin snapshot --> ObjectPermissions assertions
*/
	/*
		// if null field we shouldnt assert from snapshot
		if(uPs.Read_Access__c != null) validateSnapshotField('read', uPs.Read_Access__c.split(';'), objPerms, scopedObjMap);
		if(uPs.Edit_Access__c != null) validateSnapshotField('edit', uPs.Edit_Access__c.split(';'), objPerms, scopedObjMap);
		if(uPs.Delete_Access__c != null) validateSnapshotField('delete', uPs.Delete_Access__c.split(';'), objPerms, scopedObjMap);
		if(uPs.View_All_Access__c != null) validateSnapshotField('viewAll', uPs.View_All_Access__c.split(';'), objPerms, scopedObjMap);
		if(uPs.Modify_All_Access__c != null) validateSnapshotField('modifyAll',uPs.Modify_All_Access__c.split(';'), objPerms, scopedObjMap);

/*
 * begin ObjectPermissions --> snapshot assertions
*/
	/*	Integer i = 0;

		for(ObjectPermissions objPerm : objPerms){		

			i++;		 				 

			String objLabel = scopedObjMap.get(objPerm.SObjectType);

			if(objPerm.PermissionsRead){

				System.assertEquals(uPs.Read_Access__c.contains(objLabel), true, 'snapshot missing objPerm Read access...objLabel that wasnt found in snapshot: '+objLabel);

			}

			if(objPerm.PermissionsEdit){

			 	System.assertEquals(uPs.Edit_Access__c.contains(objLabel), true, 'snapshot missing objPerm Edit access');

			}

			if(objPerm.PermissionsDelete){

			 	System.assertEquals(uPs.Delete_Access__c.contains(objLabel), true, 'snapshot missing objPerm Delete access');

			}

			if(objPerm.PermissionsModifyAllRecords){

			 	System.assertEquals(uPs.Modify_All_Access__c.contains(objLabel), true, 'snapshot missing objPerm Modify All Access__c access');

			}

			if(objPerm.PermissionsViewAllRecords){

				System.assertEquals(uPs.View_All_Access__c.contains(objLabel), true, 'snapshot missing objPerm View All Access access');
			
			}
		}
	}

	public static void validateSnapshotField(String accessLvl, List<String> field, List<ObjectPermissions> objPerms, Map<String, String> scopedObjMap){
	
		Boolean foundObj;

		for(String s : field){

			foundObj = false;

			for(ObjectPermissions objPerm : objPerms){

				if(scopedObjMap.get(objPerm.SObjectType) == s){

					foundObj = true;

					if(accessLvl == 'read'){

						System.assertEquals(true, objPerm.PermissionsRead, 'read permissions missing from ObjectPermissions');
					
					}else if(accessLvl == 'edit'){
					
						System.assertEquals(true, objPerm.PermissionsEdit, 'edit permissions missing from ObjectPermissions');
					
					}else if(accessLvl == 'delete'){

						System.assertEquals(true, objPerm.PermissionsDelete, 'delete permissions missing from ObjectPermissions');

					}else if( accessLvl == 'viewAll'){

						System.assertEquals(true, objPerm.PermissionsViewAllRecords, 'viewAll permissions missing from ObjectPermissions');
					
					}else if( accessLvl == 'modifyAll'){

						System.assertEquals(true, objPerm.PermissionsRead, 'read permissions missing from ObjectPermissions');

					}
				}
			}

			System.assertEquals(true, foundObj, 'didnt find ObjectPermission SObjectType in snapshot.Read_Access__c');
		}
	*/}
}