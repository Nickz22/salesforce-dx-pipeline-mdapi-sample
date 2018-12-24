public class getSnapshotSystemPermissions implements Queueable {

        // init constructor params
	Map<Id, User_Permissions_Snapshot__c> allNewSnapshots = new Map<Id, User_Permissions_Snapshot__c>();
	Map<Id, User_Permissions_Snapshot__c> batchedSnapshots = new Map<Id, User_Permissions_Snapshot__c>();

	public getSnapshotSystemPermissions(Map<Id, User_Permissions_Snapshot__c> batchedSnapshots , Map<Id, User_Permissions_Snapshot__c> allNewSnapshots){

		this.allNewSnapshots = allNewSnapshots;
		this.batchedSnapshots = batchedSnapshots;

	}

	public void execute(QueueableContext context) {

		// batch iterator
		Integer i = 0;

		// loop thru snapshots
                for(Id userId : allNewSnapshots.keyset()){

                	i++;

                	// set batch size
                	if(i<300){

                		// to update, put snapshot in batched map
                		batchedSnapshots.put(userId, allNewSnapshots.get(userId));

                		// to keep track of progress, remove from main map
                		allNewSnapshots.remove(userId);

                	}else if(i==300){

                	       // update snapshot batch
                	       initAuditUtility.updateSystemPermissions(batchedSnapshots);

                	       // empty our batch container
                	       batchedSnapshots.clear();

                               if(!Test.isRunningTest()){

                        	       // requeue remaining snapshots
                        	       System.enqueueJob(new getSnapshotSystemPermissions(batchedSnapshots, allNewSnapshots));

                        	       break;
                                }
                                break;
                	}
        
                }
	}
}