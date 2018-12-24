public class aggregateObjectPermissions implements Queueable {
	
    // init constructor params
	List<ObjectPermissions> remainingObjectPermissions = new List<ObjectPermissions>();
	List<PermissionSetAssignment> listPermSetAssignments = new List<PermissionSetAssignment>();
	Map<Map<String, String>, List<Map<String, String>>> nameToPermissionMap = new Map<Map<String, String>, List<Map<String, String>>>();

	public aggregateObjectPermissions(List<ObjectPermissions> remainingObjectPermissions, List<PermissionSetAssignment> listPermSetAssignments, Map<Map<String, String>, List<Map<String, String>>> nameToPermissionMap){
		
        // assign values to constructor params
        this.remainingObjectPermissions = remainingObjectPermissions;
		this.listPermSetAssignments = listPermSetAssignments;
		this.nameToPermissionMap = nameToPermissionMap;

	}

	public void execute(QueueableContext context) {

       /* 
         * run permission aggregation algorithm
        */
        if(!Test.isRunningTest()){ 

        	List<ObjectPermissions> batchObjectPermissions = new List<ObjectPermissions>();

        	Integer i = 0;

        	// batch at 250
			while(i < 250 && remainingObjectPermissions.size()>0){ 

				batchObjectPermissions.add(remainingObjectPermissions[0]);
				remainingObjectPermissions.remove(0);

				i++;
    		}

		    nameToPermissionMap = initAuditUtility.findUarUserAccess(batchObjectPermissions, listPermSetAssignments, nameToPermissionMap);

        	if(remainingObjectPermissions.size()>0){

        		System.enqueueJob(new aggregateObjectPermissions(remainingObjectPermissions, listPermSetAssignments, nameToPermissionMap));
        	
        	}else{

        		// create permission snapshot records
        		System.enqueueJob(new initPermissionSnapshots(nameToPermissionMap));

        	}

        }else{

	        /*
	         * cant chain queueuable apex in test context -  
	        */
	        System.debug('testing');

        }
	}
}