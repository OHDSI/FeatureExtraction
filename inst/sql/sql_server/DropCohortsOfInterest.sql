/***********************************
File DropCohortsOfInterest.sql
***********************************/

IF OBJECT_ID('@cohortsTable', 'U') IS NOT NULL
  DROP TABLE @cohortsTable;
