@isTest
private class BT_AccountsEndpointTest {
    //Establish some "global" constants for the tests
	private static final String ACME_NAME = 'Acme';
    private static final String ACME_BT_ID = '123';
    
    @TestSetup
    static void setup(){
        insert new Account(Name=ACME_NAME, Braintree_ID__c=ACME_BT_ID);
    }
    
    
    static TestMethod void creatingNewParentAccount(){
        String btID = '001', name = 'test';
        
        Test.startTest();
        BT_AccountsEndpoint.doPost(btId, name);
        Test.stopTest();
        
        Account[] accounts = [SELECT Id, Name, Braintree_ID__c FROM Account ORDER BY Name];
        System.assertEquals(2, accounts.size(), 'Failed to create new Account');
        System.assertEquals(btID, accounts[1].Braintree_ID__c);
        System.assertEquals(name, accounts[1].Name);
    }
    
    static TestMethod void creatingNewChildAccount(){
        String btID = '124', name = ACME_NAME;
        
        Test.startTest();
        BT_AccountsEndpoint.doPost(btId, name);
        Test.stopTest();
        
        Account[] accounts = [SELECT Id, Name, Braintree_ID__c, ParentId, Parent.Braintree_ID__c FROM Account ORDER BY Id];
        System.assertEquals(2, accounts.size(), 'Failed to create new child Account');
        System.assertEquals(btID, accounts[1].Braintree_ID__c);
        System.assertEquals(ACME_BT_ID, accounts[1].Parent.Braintree_ID__c);
    }
    
    static TestMethod void updatingExistingAccount(){
        Account parent = new Account(Name = ACME_NAME, Braintree_ID__c='124');
        insert parent;
        Test.startTest();
        BT_AccountsEndpoint.doPost(ACME_BT_ID, ACME_NAME);
        Test.stopTest();
        
        Account[] accounts = [SELECT Id, Name, Braintree_ID__c, ParentId, Parent.Braintree_ID__c FROM Account WHERE Id !=:parent.Id];
        System.assertEquals(1, accounts.size(), 'Failed to establish new parent Account link');
        System.assertEquals(ACME_BT_ID, accounts[0].Braintree_ID__c);
        System.assertEquals(parent.Braintree_ID__c, accounts[0].Parent.Braintree_ID__c);
    }
    
    static TestMethod void accomplishNothingInParticular(){
        Test.startTest();
        String response = BT_AccountsEndpoint.doPost(ACME_BT_ID, ACME_NAME);
        Test.stopTest();
        
        Account[] accounts = [SELECT Id, Name FROM Account];
        System.assertEquals(1, accounts.size());
        System.assertEquals(String.valueOf(accounts[0]), response);
    }
    
    static TestMethod void throwBadIdError(){
        String badId = '\'broken Id';
        Test.startTest();
        String response = BT_AccountsEndpoint.doPost(badId, ACME_NAME);
        Test.stopTest();
        System.assertEquals(BT_AccountsEndpoint.ERROR_BAD_ID+badId, response);
    }
    
    static TestMethod void throwBadNameError(){
        String badName = '\'broken \'Name';
        Test.startTest();
        String response = BT_AccountsEndpoint.doPost(ACME_BT_ID, badName);
        Test.stopTest();
        System.assertEquals(BT_AccountsEndpoint.ERROR_BAD_NAME+badName, response);
    }
    
}