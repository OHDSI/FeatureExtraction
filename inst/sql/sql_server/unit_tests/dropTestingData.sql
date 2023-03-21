IF OBJECT_ID('tempdb..@cohort_table', 'U') IS NOT NULL
  DROP TABLE @cohort_table;

IF OBJECT_ID('@cohort_database_schema.@cohort_attribute_table', 'U') IS NOT NULL
	DROP TABLE @cohort_database_schema.@cohort_attribute_table;
	
IF OBJECT_ID('@cohort_database_schema.@attribute_definition_table', 'U') IS NOT NULL
	DROP TABLE @cohort_database_schema.@attribute_definition_table;
