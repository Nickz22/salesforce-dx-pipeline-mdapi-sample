public class initPermissionSnapshots implements Queueable {

	// init constructor params
	Map<Map<String, String>, List<Map<String, String>>> nameToPermissionMap = new Map<Map<String, String>, List<Map<String, String>>>();

	public initPermissionSnapshots(Map<Map<String, String>, List<Map<String, String>>> nameToPermissionMap){

		this.nameToPermissionMap = nameToPermissionMap;

	}

	public void execute(QueueableContext context) {
    
    	// to update System_Permissions__c, return new User Permission Snapshots    
        Map<Id, User_Permissions_Snapshot__c> newSnapshots = initAuditUtility.newSnapshotPermissions(nameToPermissionMap);

        // init batch container
		Map<Id, User_Permissions_Snapshot__c> batchedSnapshots = new Map<Id, User_Permissions_Snapshot__c>();
		
        if(!Test.isRunningTest()){ 	        

			// queue batch update
	        System.enqueueJob(new getSnapshotSystemPermissions(batchedSnapshots, newSnapshots));

	    }else{

	    	System.debug('testing');

	    }

	}
}