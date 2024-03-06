// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

/**
 select Id, (select Id, TREX1__Debit__c, TREX1__Credit__c from TREX1__Journal_Entries__r where TREX1__GL_Code__c = '10-10-000-23001')
  from Account 
 where Id IN (select TREX1__Account__c from TREX1__Journal_Entry__c where TREX1__GL_Code__c = '10-10-000-23001') 
 limit 50

 select Id, (select TREX1__Credit__c from trex1__Journal_Entries__r where TREX1__GL_Code__c = '10-10-000-23001')
  from trex1__Registration__c
 where TREX1__Start_Date__c >= 2023-07-01
   and CreatedDate < 2023-07-01T00:00:00.000-05:00 


select Id, (select Id, TREX1__Debit__c, TREX1__Credit__c, TREX1__Effective_Date_Time__c from TREX1__Journal_Entries__r where TREX1__GL_Code__c = '10-10-000-23001')
  from TREX1__Transaction__c
 where Id IN (select TREX1__Transaction__c from TREX1__Journal_Entry__c where TREX1__GL_Code__c = '10-10-000-23001') 
 limit 50

 */



