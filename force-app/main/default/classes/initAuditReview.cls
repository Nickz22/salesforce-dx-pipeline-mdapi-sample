public class initAuditReview {
	
	/*
   * @author          Nick Zozaya
     * @description     Dispatch DML operations as a result of Audit__c creation.
   * @return          void
     * @param           String auditId
     */
	@AuraEnabled
	public static void createAuditObjects(){

		List<PermissionSetAssignment> permSetAssignments = [SELECT AssigneeId, PermissionSetId, Assignee.Name FROM PermissionSetAssignment WHERE Assignee.IsActive = true];
		List<ObjectPermissions> allObjectPermissions = initAuditUtility.getAllObjectPermissions();

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