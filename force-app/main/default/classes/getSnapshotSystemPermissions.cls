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

		Integer s = allNewSnapshots.keyset().size();

		// loop thru snapshots
		for(Id userId : allNewSnapshots.keyset()){

			i++;

			if(s > 300){

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

			}else {

				// update snapshot batch
				initAuditUtility.updateSystemPermissions(allNewSnapshots);

				// break because we just updated all relevant Snapshots
				break;
			}
		}

		// find only metadata instance which holds Id of Access_Check_Configuration__c associated with this check
		D_V__Access_Configuration_Id__c thisConfigId = [SELECT Name, D_V__Value__c FROM D_V__Access_Configuration_Id__c];

		// hard delete unnecessary custom setting
		delete thisConfigId;
		Database.emptyRecycleBin(thisConfigId);
	}
}