/***********************************
File DropCohortsOfInterest.sql
***********************************/

IF OBJECT_ID('@resultsDatabaseSchema.@cohortsTable', 'U') IS NOT NULL
  DROP TABLE @resultsDatabaseSchema.@cohortsTable;
