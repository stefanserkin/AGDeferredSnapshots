/**
 * Calculate deferred revenue, per transaction as of a certain date
 */

Datetime dtAsOf = Datetime.newInstance(2023, 7, 1);
System.debug(':::::dtAsOf --> ' + dtAsOf);

Map<Id, Decimal> mapDeferredAmounts = new Map<Id, Decimal>();

List<TREX1__Transaction__c> lstTrans = [
    SELECT Id, 
           (SELECT Id, TREX1__Net_Credit_Amount__c, TREX1__Effective_Date_Time__c 
              FROM TREX1__Journal_Entries__r 
             WHERE TREX1__GL_Code__c = '10-10-000-23001'
               AND TREX1__Effective_Date_Time__c < :dtAsOf)
      FROM TREX1__Transaction__c
     WHERE Id IN (SELECT TREX1__Transaction__c 
                    FROM TREX1__Journal_Entry__c 
                   WHERE TREX1__GL_Code__c = '10-10-000-23001') 
];

Decimal grandTotal = 0.00;
for (TREX1__Transaction__c trans : lstTrans) {
    Decimal total = 0.00;
    for (TREX1__Journal_Entry__c je : trans.TREX1__Journal_Entries__r) {
        total += je.TREX1__Net_Credit_Amount__c;
    }
    if (total > 0.00) {
        mapDeferredAmounts.put(trans.Id, total);
        grandTotal += total;
    }
}

System.debug(':::: found ' + mapDeferredAmounts.size() + ' transactions');
System.debug(':::: total --> ' + grandTotal);
