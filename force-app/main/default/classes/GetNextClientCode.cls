public with sharing class GetNextClientCode {

    @InvocableMethod(label='Get Next Client Code' description='Returns the next available Lydiam client code in 28786XXX format.')
    public static List<Result> getNextCode(List<Request> requests) {
        List<Result> results = new List<Result>();

        List<Account> existing = [
            SELECT Client_Code__c
            FROM Account
            WHERE Client_Code__c LIKE '28786%'
            ORDER BY Client_Code__c DESC
            LIMIT 1
        ];

        String nextCode;
        if (existing.isEmpty()) {
            nextCode = '28786001';
        } else {
            String lastCode = existing[0].Client_Code__c;
            try {
                Integer lastNum = Integer.valueOf(lastCode.substring(5));
                Integer nextNum = lastNum + 1;
                String suffix = String.valueOf(nextNum);
                while (suffix.length() < 3) {
                    suffix = '0' + suffix;
                }
                nextCode = '28786' + suffix;
            } catch (Exception e) {
                nextCode = '28786001';
            }
        }

        Result r = new Result();
        r.nextClientCode = nextCode;
        results.add(r);
        return results;
    }

    public class Request {
        @InvocableVariable(label='Account Id' required=false)
        public String accountId;
    }

    public class Result {
        @InvocableVariable(label='Next Client Code')
        public String nextClientCode;
    }
}
