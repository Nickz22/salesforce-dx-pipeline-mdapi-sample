public class insertConfigId implements Queueable {
    
    // init constructor params
	String configId;

	public insertConfigId(String configId){

        // assign Access_Check_Configuration__c Id
		this.configId = configId;

	}

    public void execute(QueueableContext context) {
      /*  
        // init custom setting
    	D_V__Access_Configuration_Id__c config = new D_V__Access_Configuration_Id__c();

        // set custom setting value
		config.D_V__Value__c = configId;

        // give current datetime as name
        config.Name = String.valueOf(datetime.now());

		insert config;
       
        System.debug('insert custom setting: '+config);
         */

	}
}
