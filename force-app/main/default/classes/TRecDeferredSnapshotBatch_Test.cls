@IsTest
private class TRecDeferredSnapshotBatch_Test {

    @TestSetup
    static void makeData() {
        Integer amount = 100;
        Datetime dtValidEffectiveDatetime = Datetime.newInstance(
            TRecDeferredSnapshotBatch.DT_AS_OF.date().addDays(-1),
            TRecDeferredSnapshotBatch.DT_AS_OF.time()
        );

        // Contact with account id
        List<Contact> lstContacts = TestDataFactory.createContacts(1);
        insert lstContacts;
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];

        // GL account
        List<TREX1__GL_Account__c> lstGlAccs = TestDataFactory.createGlAccounts(2);
        lstGlAccs[0].TREX1__GL_Account_Number__c = TRecDeferredSnapshotBatch.DEFERRED_GL_CODE;
        insert lstGlAccs;

        // Transaction
        TREX1__Transaction__c tr = TestDataFactory.createManualAdjustmentTransaction(
            ct,
            amount,
            TRecDeferredSnapshotBatch.DEFERRED_GL_CODE, 
            'Credit'
        );

        // Update effective datetimes to date in valid fiscal year
        List<TREX1__Journal_Entry__c> lstJesToAdjust = [
            SELECT Id, TREX1__Effective_Date_Time__c
              FROM TREX1__Journal_Entry__c
        ];
        for (TREX1__Journal_Entry__c je : lstJesToAdjust) {
            je.TREX1__Effective_Date_Time__c = dtValidEffectiveDatetime;
        }
        update lstJesToAdjust;

        // Retrieve tli created with transaction
        TREX1__Transaction_Line_Item__c tli = [SELECT Id FROM TREX1__Transaction_Line_Item__c WHERE TREX1__Transaction__c = :tr.Id LIMIT 1];

        // Accounting event for deferred recognition
        TREX1__Accounting_Event__c ae = new TREX1__Accounting_Event__c();
        ae.TREX1__Transaction__c = tr.Id;
        ae.TREX1__Transaction_Line_Item__c = tli.Id;
        ae.TREX1__Effective_Date__c = Date.today();
        ae.TREX1__Effective_Date_Time__c = dtValidEffectiveDatetime;
        ae.TREX1__Type__c = 'Manual Adjustment';
        ae.TREX1__Total__c = amount;
        ae.TREX1__Annotation__c = 'Deferred recognition';
        ae.TREX1__Account__c = tr.TREX1__Account__c;
        ae.TREX1__Contact__c = tr.TREX1__Contact__c;
        insert ae;
        
        List<TREX1__Journal_Entry__c> lstJEs = new List<TREX1__Journal_Entry__c>();
        // Debit
        TREX1__Journal_Entry__c debit = new TREX1__Journal_Entry__c();
        debit.TREX1__Transaction__c = ae.TREX1__Transaction__c;
        debit.TREX1__Transaction_Line_Item__c = ae.TREX1__Transaction_Line_Item__c;
        debit.TREX1__Effective_Date_Time__c = dtValidEffectiveDatetime;
        debit.TREX1__Account__c = ae.TREX1__Account__c;
        debit.TREX1__Contact__c = ae.TREX1__Contact__c;
        debit.TREX1__Accounting_Event__c = ae.Id;
        debit.TREX1__GL_Code__c = TRecDeferredSnapshotBatch.DEFERRED_GL_CODE;
        debit.TREX1__Type__c = 'Manual Adjustment';
        debit.TREX1__Debit__c = ae.TREX1__Total__c;
        debit.TREX1__Credit__c = 0;
        lstJEs.add(debit);
        // Credit
        TREX1__Journal_Entry__c credit = new TREX1__Journal_Entry__c();
        credit.TREX1__Transaction__c = ae.TREX1__Transaction__c;
        credit.TREX1__Transaction_Line_Item__c = ae.TREX1__Transaction_Line_Item__c;
        credit.TREX1__Effective_Date_Time__c = dtValidEffectiveDatetime;
        credit.TREX1__Account__c = ae.TREX1__Account__c;
        credit.TREX1__Contact__c = ae.TREX1__Contact__c;
        credit.TREX1__Accounting_Event__c = ae.Id;
        credit.TREX1__GL_Code__c = lstGlAccs[1].TREX1__GL_Account_Number__c;
        credit.TREX1__Type__c = 'Manual Adjustment';
        credit.TREX1__Debit__c = 0;
        credit.TREX1__Credit__c = ae.TREX1__Total__c;
        lstJEs.add(credit);
        insert lstJEs;
    }
    
    @IsTest
    static void testDeferredSnapshotBatch() {
        Test.startTest();
        TRecDeferredSnapshotBatch batch = new TRecDeferredSnapshotBatch();
        Id batchId = Database.executeBatch(batch, 50);
        Test.stopTest();
        Assert.isNotNull(batchId, 'Should have received a batch id');
        TREX1__Journal_Entry__c creditJe = [
            SELECT Id, Deferred_Balance_as_of_FY23_End__c
              FROM TREX1__Journal_Entry__c 
             WHERE TREX1__GL_Code__c = :TRecDeferredSnapshotBatch.DEFERRED_GL_CODE
               AND TREX1__Credit__c > 0
             LIMIT 1
        ];
        Assert.areEqual(0, creditJe.Deferred_Balance_as_of_FY23_End__c, 'Debit jes should have removed all deferred balance');
    }

}