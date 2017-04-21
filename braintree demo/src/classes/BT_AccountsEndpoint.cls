@RestResource(urlMapping='/Account/*')
global class BT_AccountsEndpoint {
    @TestVisible private static final String ERROR_BAD_ID =  'Malformed Braintree Id:';
    @TestVisible private static final String ERROR_BAD_NAME ='Supplied name is invalid:';
    @TestVisible private static final String ERROR_EXCEPTION='An exception has occurred.';
    
    @HttpPost
    global static String doPost(String braintreeId, String name) {
        String retVal;
        if(!isValidBraintreeId(braintreeId)){
            retVal = ERROR_BAD_ID + braintreeId;
        }else if(!isInputSafe(name)){
            retVal = ERROR_BAD_NAME + name;
        }else{
            try{
                String[] queryParams = new List<String>{	'\''+braintreeId+'\'', '\''+name+'\''	};
                Account[] accounts = Database.query(
                    String.format('SELECT Id, ParentId, Name FROM Account WHERE Braintree_ID__c ={0} LIMIT 1',  queryParams)
                );
                Account[] parentAccounts = Database.query(
                    String.format('SELECT Id FROM Account WHERE ParentId = NULL AND Braintree_ID__c !={0} AND Name ={1} LIMIT 1',  queryParams)
                );
                
                Account acc = (accounts.isEmpty() ? NULL : accounts[0]);
                Account parentAcc = (parentAccounts.isEmpty() ? NULL : parentAccounts[0]);
                
                if(acc == NULL){
                    acc = new Account(Name = name, Braintree_ID__c = braintreeId);
                    if(parentAcc != NULL){
                        acc.ParentId = parentAcc.Id;
                    }
                    insert acc;
                } else if(parentAcc != NULL && acc.ParentId == NULL){
                    //Assuming: 1) we don't want to overwrite an existing parent relationship because...
                    //			2) which Account is considered the parent is unlikely/unable to change
                    acc.ParentId = parentAcc.Id;
                    update acc;
                }
                retVal = String.valueOf(acc);
                
            }catch(Exception ex){
                //handle this in some appropriate manner, but definitely don't risk exposing stack traces to the outside world
                //should only be reachable if a validation or DML error is encountered for some reason downstream
                retVal = ERROR_EXCEPTION;
            }
        }
        
        return retVal;
    }
    
    private static Boolean isValidBraintreeId(String braintreeId){
        //Should pass the input through some regex filters to check that it at least
        //resembles a valid Id for our system, but since I don't know what it should
        //look like, let us assume only a small amount of ill intent
        return isInputSafe(braintreeId) /*&& resultOfOtherChecks*/;
    }
    
    private static Boolean isInputSafe(String input){
        return String.isNotBlank(input) && String.escapeSingleQuotes(input).equals(input);
    }
}