/*
Class Name      : Constants
*/
public with sharing class Constants {

    /*
     * Object: Case
    */
    public static final String CASE_OBJ = 'Case';

    /*
     * Object: Account
    */
    public static final String ACCOUNT_OBJ = 'Account';

    /*
     * Object: Opportunity
    */
    public static final String OPPORTUNITY_OBJ = 'Opportunity';

    /*
     * Profile
    */
    public static final String ADMIN_PROFILE = 'System Administrator';
    public static final String ACCOUNT_EXECUTIVE_PROFILE = 'Account Executive';
    public static final String ACCOUNT_MANAGER_PROFILE = 'Account Manager';
    public static final String AD_OPERATIONS_PROFILE = 'Ad Operations';
    public static final String API_USER_PROFILE = 'API User';
    public static final String PLACED_PROFILE = 'Placed-Sales';

    public static Id ADMIN_PROFILE_ID {
        public get {
            if (ADMIN_PROFILE_ID == null) {
                ADMIN_PROFILE_ID = [SELECT Profile.Id FROM PermissionSet WHERE Profile.Name = :ADMIN_PROFILE AND IsCustom = false LIMIT 1].Profile.Id;
            }

            return ADMIN_PROFILE_ID;
        }
        private set;
    }

    public static Id CUSTOM_ADMIN_PROFILE_ID {
        public get {
            if (CUSTOM_ADMIN_PROFILE_ID == null) {
                CUSTOM_ADMIN_PROFILE_ID = [SELECT Profile.Id FROM PermissionSet WHERE Profile.Name=: ADMIN_PROFILE AND IsCustom = true LIMIT 1].Profile.Id;
                System.debug(CUSTOM_ADMIN_PROFILE_ID);
            }

            return CUSTOM_ADMIN_PROFILE_ID;
        }
        private set;
    }

    private static String profileName;

    /**
     * @author          Badri
     * @description     Helper method to get profile name by Id
     * @return          String
     * @param           Id profileid
     */
    public static String getProfileNameById (Id profileId) {

        if (profileName == null) {
            profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        }
        return profileName;
    }
}