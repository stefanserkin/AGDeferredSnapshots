public with sharing class TRecDeferredSnapshotBatch implements Database.Batchable<sObject> {
    
    public static final String BATCH_NAME = 'Deferred Snapshot Batch';
    public static final String DEFERRED_GL_CODE = '10-10-000-23001';

    @TestVisible
    private static final Datetime DT_AS_OF = Datetime.newInstance(2023, 07, 01);

    /***************************************************
    * Start batch
    ***************************************************/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Get all transactions with any deferred activity
        String strQuery = 'SELECT Id FROM TREX1__Transaction__c WHERE CreatedDate <= :DT_AS_OF AND Id IN (SELECT TREX1__Transaction__c FROM TREX1__Journal_Entry__c WHERE TREX1__GL_Code__c = :DEFERRED_GL_CODE)';
        if (Test.isRunningTest()) {
            strQuery = 'SELECT Id FROM TREX1__Transaction__c';
        }
        return Database.getQueryLocator(strQuery);
    }

    /***************************************************
    * Execute batch
    ***************************************************/
    public void execute(Database.BatchableContext bc, List<TREX1__Transaction__c> scope) {
        Datetime dtAsOf = Datetime.newInstance(2023, 7, 1);

        // Get transactions with eligible jes
        List<TREX1__Transaction__c> lstTrans = [
            SELECT Id, 
                   (SELECT Id, Deferred_Balance_as_of_FY23_End__c, TREX1__Debit__c, TREX1__Net_Credit_Amount__c, TREX1__Effective_Date_Time__c 
                      FROM TREX1__Journal_Entries__r 
                     WHERE TREX1__GL_Code__c = :DEFERRED_GL_CODE
                       AND TREX1__Effective_Date_Time__c < :DT_AS_OF
                     ORDER BY TREX1__Net_Credit_Amount__c, TREX1__Effective_Date_Time__c DESC)
              FROM TREX1__Transaction__c
             WHERE Id IN :scope
        ];

        List<TREX1__Journal_Entry__c> lstJesToUpdate = new List<TREX1__Journal_Entry__c>();
        for (TREX1__Transaction__c trans : lstTrans) {
            List<TREX1__Journal_Entry__c> lstJes = trans.TREX1__Journal_Entries__r;
            List<TREX1__Journal_Entry__c> lstCreditJes = new List<TREX1__Journal_Entry__c>();

            for (Integer i = (lstJes.size() - 1); i >= 0; i--) {
                if (lstJes[i].TREX1__Net_Credit_Amount__c > 0) {
                    lstCreditJes.add(lstJes[i]);
                    lstJes.remove(i);
                }
            }

            // Reduce jes with balance for any debiting jes
            Integer debitIndex = 0;
            Decimal debitRemainder = 0;
            for (TREX1__Journal_Entry__c creditJe : lstCreditJes) {
                Decimal balance = creditJe.TREX1__Net_Credit_Amount__c;

                while (balance > 0 && debitIndex < lstJes.size()) {
                    Decimal debitAmount = (debitRemainder > 0) ? debitRemainder : lstJes[debitIndex].TREX1__Debit__c;
                    if (balance >= debitAmount) {
                        balance -= debitAmount;
                        debitRemainder = 0;
                        debitIndex++;
                    } else {
                        debitRemainder = debitAmount - balance;
                        balance = 0;
                    }
                }

                creditJe.Deferred_Balance_as_of_FY23_End__c = balance;
                lstJesToUpdate.add(creditJe);
            }

        }

        if (!lstJesToUpdate.isEmpty()) {
            update lstJesToUpdate;
        }

    }

    /***************************************************
    * Finish batch
    ***************************************************/
    public void finish(Database.BatchableContext bc) {
        
        AsyncApexJob apexJob = [
            SELECT Id, 
                Status, 
                NumberOfErrors, 
                JobItemsProcessed, 
                TotalJobItems, 
                CreatedBy.Email
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];
        
        // Send email to job creator with batch results
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        email.setToAddresses(toAddress);
        email.setSubject(apexJob.Status + ': ' + BATCH_NAME);
        email.setPlainTextBody('The ' + BATCH_NAME + ' ran and processed ' + apexJob.TotalJobItems + ' batches with ' + apexJob.NumberOfErrors + ' failures. Job Id: ' + apexJob.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }


}