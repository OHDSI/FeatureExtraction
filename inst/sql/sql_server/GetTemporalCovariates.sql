/************************************************************************
@file GetTemporalCovariates.sql

Copyright 2017 Observational Health Data Sciences and Informatics

This file is part of FeatureExtraction

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
************************************************************************/

{DEFAULT @cdm_database_schema = 'CDM4_SIM.dbo' } 
{DEFAULT @cohort_temp_table = '#cohort_person'}
{DEFAULT @row_id_field = 'person_id'}
{DEFAULT @use_covariate_condition_era_start = TRUE} 
{DEFAULT @use_covariate_condition_era_present = TRUE} 
{DEFAULT @use_covariate_drug_era_start = FALSE} 
{DEFAULT @use_covariate_drug_era_present = FALSE} 
{DEFAULT @use_covariate_drug_group_start = FALSE} 
{DEFAULT @use_covariate_drug_group_present = FALSE} 
{DEFAULT @use_covariate_procedure_occurrence = FALSE} 
{DEFAULT @use_covariate_procedure_group = FALSE} 
{DEFAULT @use_covariate_measurement_value = FALSE} 
{DEFAULT @use_covariate_measurement_below = TRUE} 
{DEFAULT @use_covariate_measurement_above = TRUE} 
{DEFAULT @use_covariate_visit = FALSE} 
{DEFAULT @has_excluded_covariate_concept_ids} 
{DEFAULT @has_included_covariate_concept_ids} 

IF OBJECT_ID('tempdb..#cov', 'U') IS NOT NULL
	DROP TABLE #cov;

IF OBJECT_ID('tempdb..#cov_ref', 'U') IS NOT NULL
	DROP TABLE #cov_ref;

CREATE TABLE #cov_ref (
	covariate_id BIGINT,
	covariate_name VARCHAR(512),
	analysis_id INT,
	concept_id INT
	);
	
IF OBJECT_ID('tempdb..#dummy', 'U') IS NOT NULL
	DROP TABLE #dummy;

CREATE TABLE #dummy (
	row_id BIGINT,
	covariate_id BIGINT,
	time_id INT,
	covariate_value INT
	);

/**************************
***************************
CONDITION ERA
***************************
**************************/

{@use_covariate_condition_era_start} ? {

--condition era starts in time period
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.condition_concept_id AS BIGINT) * 1000 + 101 AS covariate_id,
	tp1.time_id AS time_id,
	1 AS covariate_value
INTO #cov_co_start
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_era ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.condition_era_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.condition_era_start_date, cp1.cohort_start_date) >= tp1.start_day
WHERE ce1.condition_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.condition_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.condition_concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Condition era start observed:  ' + CAST((p1.covariate_id-101)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	101 AS analysis_id,
	(p1.covariate_id-101)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_co_start) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-101)/1000 = c1.concept_id
;
}


{@use_covariate_condition_era_present} ? {

--condition era is present in time period
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.condition_concept_id AS BIGINT) * 1000 + 102 AS covariate_id,
	tp1.time_id AS time_id,
	1 AS covariate_value
INTO #cov_co_pres
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_era ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.condition_era_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.condition_era_end_date, cp1.cohort_start_date) >= tp1.start_day
WHERE ce1.condition_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.condition_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.condition_concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Condition era observed:  ' + CAST((p1.covariate_id-102)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	102 AS analysis_id,
	(p1.covariate_id-102)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_co_pres) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-102)/1000 = c1.concept_id
;
}


/**************************
***************************
MEASUREMENT
***************************
**************************/

{@use_covariate_measurement_value} ? {

--measurement value. Take last value if multiple values in period
SELECT row_id,
  covariate_id,
  time_id,
  covariate_value
INTO #cov_meas_val
FROM (
SELECT cp1.@row_id_field AS row_id,
	CAST(m1.measurement_concept_id AS BIGINT) * 1000 + 601 AS covariate_id,
	tp1.time_id AS time_id,
	value_as_number AS covariate_value,
	ROW_NUMBER() OVER (PARTITION BY cp1.@row_id_field, measurement_concept_id, time_id ORDER BY measurement_date DESC) AS rn1
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.measurement m1
	ON cp1.subject_id = m1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, m1.measurement_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, m1.measurement_date, cp1.cohort_start_date) >= tp1.start_day
WHERE m1.measurement_concept_id != 0 
	AND value_as_number IS NOT NULL 
{@has_excluded_covariate_concept_ids} ? {	AND m1.measurement_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND m1.measurement_concept_id IN (SELECT concept_id FROM #included_cov)}
) temp
WHERE rn1 = 1;


INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Measurement value:  ' + CAST((p1.covariate_id-601)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	601 AS analysis_id,
	(p1.covariate_id-601)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_meas_val) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-601)/1000 = c1.concept_id
;
}

/**********************************************
***********************************************
put all temp tables together into one cov table
***********************************************
**********************************************/

SELECT row_id, covariate_id, time_id, covariate_value
INTO #cov
FROM
(

SELECT row_id, covariate_id, time_id, covariate_value FROM #dummy

{@use_covariate_condition_era_start} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_co_start
}

{@use_covariate_condition_era_present} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_co_pres
}

{@use_covariate_measurement_value} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_meas_val
}
) all_covariates;

/**********************************************
***********************************************
Cleanup: delete all temp tables
***********************************************
**********************************************/
IF OBJECT_ID('tempdb..#cov_co_start', 'U') IS NOT NULL
  DROP TABLE #cov_co_start;
IF OBJECT_ID('tempdb..#cov_co_pres', 'U') IS NOT NULL
  DROP TABLE #cov_co_pres;
IF OBJECT_ID('tempdb..#cov_meas_val', 'U') IS NOT NULL
  DROP TABLE #cov_meas_val;  
TRUNCATE TABLE #dummy;
  DROP TABLE #dummy;

{@has_excluded_covariate_concept_ids} ? {
TRUNCATE TABLE #excluded_cov;

DROP TABLE #excluded_cov;
}

{@has_included_covariate_concept_ids} ? {
TRUNCATE TABLE #included_cov;

DROP TABLE #included_cov;
}

TRUNCATE TABLE #time_period;
DROP TABLE #time_period;