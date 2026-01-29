SELECT first_use.*
INTO @cohort_table
FROM (
  SELECT drug_concept_id AS cohort_definition_id,
  	MIN(drug_era_start_date) AS cohort_start_date,
  	MIN(drug_era_end_date) AS cohort_end_date,
  	person_id AS subject_id
  FROM @cdm_database_schema.drug_era
  WHERE drug_concept_id = 1118084-- celecoxib
    OR drug_concept_id = 1124300 --diclofenac
  GROUP BY drug_concept_id, 
    person_id
) first_use 
INNER JOIN @cdm_database_schema.observation_period
  ON first_use.subject_id = observation_period.person_id
  AND cohort_start_date >= observation_period_start_date
  AND cohort_end_date <= observation_period_end_date
WHERE DATEDIFF(DAY, observation_period_start_date, cohort_start_date) >= 365
;

IF OBJECT_ID('@cohort_database_schema.@cohort_attribute_table', 'U') IS NOT NULL
	DROP TABLE @cohort_database_schema.@cohort_attribute_table;
	
IF OBJECT_ID('@cohort_database_schema.@attribute_definition_table', 'U') IS NOT NULL
	DROP TABLE @cohort_database_schema.@attribute_definition_table;


SELECT cohort_definition_id,
    subject_id,
	cohort_start_date,
	1 AS attribute_definition_id,
	DATEDIFF(DAY, observation_period_start_date, cohort_start_date) AS value_as_number
INTO @cohort_database_schema.@cohort_attribute_table
FROM @cohort_table cohort
INNER JOIN @cdm_database_schema.observation_period op
	ON op.person_id = cohort.subject_id
WHERE cohort.cohort_start_date >= op.observation_period_start_date
	AND cohort.cohort_start_date <= op.observation_period_end_date
{@cohort_definition_ids != ''} ? {
	AND cohort.cohort_definition_id IN (@cohort_definition_ids)
}
;
	
SELECT 1 AS attribute_definition_id,
  'Length of observation in days' AS attribute_name
INTO @cohort_database_schema.@attribute_definition_table
;
