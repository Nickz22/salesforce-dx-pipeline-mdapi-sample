public class initAuditReview {

	/*
   * @author          Nick Zozaya
     * @description     Get relevant PermissionSet fields for Access Check UI.
   * @return          List<String>
     * @param         	
	 */
	@AuraEnabled
	public static List<String> getPermissionSetFields(){

		List<String> returnFields = new List<String>();

		Map<String, Schema.SObjectField> fieldMap = initAuditUtility.getFieldMap('PermissionSet');

		for(String key : fieldMap.keyset()){
			
			if(key.contains('permissions')) returnFields.add(fieldMap.get(key).getDescribe().getLabel());
		}

		return returnFields;
	}

	/*
   * @author          Nick Zozaya
     * @description     Dispatch DML operations associated with Launch Access Check button.
   * @return          void
     * @param           List<String> selectedPermissions, String configId
     */
	@AuraEnabled
	public static void createAuditObjects(List<String> selectedPermissions, String configId){

		System.debug('configId is: '+configId);
		
		// check where launch occurred
		if(configId == '' || configId == null){
			/* 
			* launched from app homepage, 
			 * create Access Check Configuration
			*/
			initAuditUtility.createConfig(selectedPermissions);
		}else{
			/*
			* launch from config record page,
			 * find Access Check Configuration
			*/
			initAuditUtility.reuseConfig(configId);
		}

		// get all active PermissionSetAssignments
		List<PermissionSetAssignment> permSetAssignments = [SELECT AssigneeId, PermissionSetId, Assignee.Name FROM PermissionSetAssignment WHERE Assignee.IsActive = true];
		
		// get all in-scope ObjectPermissions (defined by In_Scope_Object_mdt records)
		List<ObjectPermissions> allObjectPermissions = initAuditUtility.getAllObjectPermissions();

		// initialize container for user's permissions
		Map<Map<String, String>, List<Map<String, String>>> nameToPermissionMap = new Map<Map<String, String>, List<Map<String, String>>>();

		if(!Test.isRunningTest()){

			// aggregate object-permissions at user level
			System.enqueueJob(new aggregateObjectPermissions(allObjectPermissions, permSetAssignments, nameToPermissionMap));

		}else{
			/*
			  * only runs during test
			 */
			// aggregate object-permissions at user level
			System.enqueueJob(new aggregateObjectPermissions(allObjectPermissions, permSetAssignments, nameToPermissionMap));

			nameToPermissionMap = initAuditUtility.findUarUserAccess(allObjectPermissions, permSetAssignments, nameToPermissionMap);

			// create permission snapshot records
			System.enqueueJob(new initPermissionSnapshots(nameToPermissionMap));
			// to update System_Permissions__c, return new User Permission Snapshots    
			Map<Id, User_Permissions_Snapshot__c> newSnapshots = initAuditUtility.newSnapshotPermissions(nameToPermissionMap);
			// init batch container
			Map<Id, User_Permissions_Snapshot__c> batchedSnapshots = new Map<Id, User_Permissions_Snapshot__c>();	        
			// queue batch update
	    System.enqueueJob(new getSnapshotSystemPermissions(batchedSnapshots, newSnapshots));

		}
	}
}