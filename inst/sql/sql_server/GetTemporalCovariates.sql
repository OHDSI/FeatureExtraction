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

{DEFAULT @cdm_database_schema = 'CDM5_SIM.dbo' } 
{DEFAULT @cohort_temp_table = '#cohort_person'}
{DEFAULT @row_id_field = 'person_id'}
{DEFAULT @concept_class_id = 'concept_class_id'} 
{DEFAULT @use_covariate_condition_era_start = FALSE} 
{DEFAULT @use_covariate_condition_era_present = TRUE} 
{DEFAULT @use_covariate_drug_era_start = FALSE} 
{DEFAULT @use_covariate_drug_era_present = FALSE} 
{DEFAULT @use_covariate_condition_group = TRUE}
{DEFAULT @use_covariate_condition_group_meddra = TRUE} 
{DEFAULT @use_covariate_condition_group_snomed = TRUE} /* BUG */
/* To Do
{DEFAULT @use_covariate_drug_group_start = FALSE} 
{DEFAULT @use_covariate_drug_group_present = FALSE} 
*/
{DEFAULT @use_covariate_procedure_occurrence = FALSE} 
{DEFAULT @use_covariate_procedure_group = FALSE}
{DEFAULT @use_covariate_measurement_value = FALSE} 
{DEFAULT @use_covariate_measurement_below = FALSE} 
{DEFAULT @use_covariate_measurement_above = FALSE} 
{DEFAULT @use_covariate_visit_occurrence = FALSE} 
{DEFAULT @use_covariate_concept_counts = FALSE} 
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
CONDITION GROUP
***************************
**************************/



{@use_covariate_condition_group} ? {


IF OBJECT_ID('tempdb..#condition_group', 'U') IS NOT NULL
	DROP TABLE #condition_group;


select descendant_concept_id,
  ancestor_concept_id
  INTO #condition_group
from
(

{@use_covariate_condition_group_meddra} ? {
SELECT DISTINCT ca1.descendant_concept_id,
	ca1.ancestor_concept_id
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 100
		AND analysis_id < 200
	) ccr1
INNER JOIN @cdm_database_schema.concept_ancestor ca1
	ON ccr1.concept_id = ca1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON ca1.ancestor_concept_id = c1.concept_id
WHERE c1.vocabulary_id = 'MedDRA'
	AND c1.@concept_class_id <> 'System Organ Class'
	AND c1.concept_id NOT IN (36302170, 36303153, 36313966)
{@has_excluded_covariate_concept_ids} ? {	AND c1.concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND c1.concept_id IN (SELECT concept_id FROM #included_cov)}

{@use_covariate_condition_group_snomed} ? { UNION }
}

{@use_covariate_condition_group_snomed} ? {
SELECT DISTINCT ca1.descendant_concept_id,
  ca1.ancestor_concept_id
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 100
		AND analysis_id < 200
	) ccr1
INNER JOIN @cdm_database_schema.concept_ancestor ca1
	ON ccr1.concept_id = ca1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON ca1.ancestor_concept_id = c1.concept_id
WHERE c1.vocabulary_id = 'SNOMED'
  AND c1.@concept_class_id = 'Clinical finding'
  AND ca1.min_levels_of_separation = 1
  AND c1.concept_id NOT IN (select distinct descendant_concept_id from @cdm_database_schema.concept_ancestor where ancestor_concept_id = 441840 /*clinical finding*/ and max_levels_of_separation <= 2)
{@has_excluded_covariate_concept_ids} ? {  AND c1.concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {  AND c1.concept_id IN (SELECT concept_id FROM #included_cov)}
}
) t1
;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT DISTINCT CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 50 + ccr1.analysis_id AS covariate_id,
	CASE
		WHEN analysis_id = 101
			THEN 'Condition era start observed within condition group:  '
		WHEN analysis_id = 102
			THEN 'Condition era observed within condition group:  '
		ELSE 'Other condition group analysis'
		END + CAST(cg1.ancestor_concept_id AS VARCHAR) + '-' + c1.concept_name AS covariate_name,
	ccr1.analysis_id,
	cg1.ancestor_concept_id AS concept_id
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 100
		AND analysis_id < 200
	) ccr1
INNER JOIN #condition_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON cg1.ancestor_concept_id = c1.concept_id;


SELECT DISTINCT cc1.row_id,
	CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 50 + ccr1.analysis_id AS covariate_id,
  cc1.time_id,
	1 AS covariate_value
INTO #cov_cg
FROM (
SELECT row_id, covariate_id, time_id, covariate_value FROM #dummy
{@use_covariate_condition_era_start} ? {
UNION
SELECT row_id, covariate_id, time_id, covariate_value
FROM ##cov_co_start
}
{@use_covariate_condition_era_present} ? {
UNION
SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_co_pres
}
) cc1
INNER JOIN (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 100
		AND analysis_id < 200
	) ccr1
	ON cc1.covariate_id = ccr1.covariate_id
INNER JOIN #condition_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
;

TRUNCATE TABLE #condition_group;
DROP TABLE #condition_group;
}

/**************************
***************************
DRUG ERA
***************************
**************************/

{@use_covariate_drug_era_start} ? {

--drug era starts in time period
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.drug_concept_id AS BIGINT) * 1000 + 201 AS covariate_id,
	tp1.time_id AS time_id,
	1 AS covariate_value
INTO #cov_dr_start
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.drug_era_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.drug_era_start_date, cp1.cohort_start_date) >= tp1.start_day
WHERE ce1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Drug era start observed:  ' + CAST((p1.covariate_id-201)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	201 AS analysis_id,
	(p1.covariate_id-201)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_dr_start) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-201)/1000 = c1.concept_id
;
}


{@use_covariate_drug_era_present} ? {

--drug era is present in time period
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.drug_concept_id AS BIGINT) * 1000 + 202 AS covariate_id,
	tp1.time_id AS time_id,
	1 AS covariate_value
INTO #cov_dr_pres
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.drug_era_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.drug_era_end_date, cp1.cohort_start_date) >= tp1.start_day
WHERE ce1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Drug era observed:  ' + CAST((p1.covariate_id-202)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	202 AS analysis_id,
	(p1.covariate_id-202)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_dr_pres) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-202)/1000 = c1.concept_id
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

{@use_covariate_measurement_below} ? {

--measurement value below lowerlimit. Take last value if multiple values in period
SELECT row_id,
  covariate_id,
  time_id,
  covariate_value
INTO #cov_meas_below
FROM (
SELECT cp1.@row_id_field AS row_id,
	CAST(m1.measurement_concept_id AS BIGINT) * 1000 + 601 AS covariate_id,
	tp1.time_id AS time_id,
	value_as_number AS covariate_value,
	range_low AS range_low,
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
		AND m1.value_as_number >= 0
		AND m1.range_low >= 0
		AND m1.range_high >= 0
	) t1
WHERE RN1 = 1
	AND covariate_value < range_low;

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Measurement numeric value below normal range :  ' + CAST((p1.covariate_id-903)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	903 AS analysis_id,
	(p1.covariate_id-903)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_meas_below) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-903)/1000 = c1.concept_id
;
}

{@use_covariate_measurement_above} ? {

--measurement value above upper limit. Take last value if multiple values in period
SELECT row_id,
  covariate_id,
  time_id,
  covariate_value
INTO #cov_meas_above
FROM (
SELECT cp1.@row_id_field AS row_id,
	CAST(m1.measurement_concept_id AS BIGINT) * 1000 + 601 AS covariate_id,
	tp1.time_id AS time_id,
	value_as_number AS covariate_value,
	range_high AS range_high,
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
		AND m1.value_as_number >= 0
		AND m1.range_low >= 0
		AND m1.range_high >= 0
	) t1
WHERE RN1 = 1
	AND covariate_value > range_high;

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Measurement numeric value above normal range :  ' + CAST((p1.covariate_id-904)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	903 AS analysis_id,
	(p1.covariate_id-904)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_meas_above) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-904)/1000 = c1.concept_id
;
}

/**************************
***************************
PROCEDURE
***************************
**************************/
{@use_covariate_procedure_occurrence} ? {

--procedure is present in time period
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.procedure_concept_id AS BIGINT) * 1000 + 701 AS covariate_id,
	tp1.time_id AS time_id,
	1 AS covariate_value
INTO #cov_pr_oc
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.procedure_occurrence ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.procedure_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.procedure_date, cp1.cohort_start_date) >= tp1.start_day
WHERE ce1.procedure_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.procedure_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.procedure_concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Procedure observed:  ' + CAST((p1.covariate_id-701)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	701 AS analysis_id,
	(p1.covariate_id-701)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_pr_oc) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-701)/1000 = c1.concept_id
;
}

/**************************
***************************
PROCEDURE GROUP
***************************
**************************/

{@use_covariate_procedure_group} ? {

IF OBJECT_ID('tempdb..#procedure_group', 'U') IS NOT NULL
  DROP TABLE #procedure_group;

--SNOMED
SELECT DISTINCT ca1.descendant_concept_id,
	ca1.ancestor_concept_id
  INTO #procedure_group
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 700
		AND analysis_id < 800
	) ccr1
INNER JOIN @cdm_database_schema.concept_ancestor ca1
	ON ccr1.concept_id = ca1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON ca1.ancestor_concept_id = c1.concept_id
{@cdm_version == '4'} ? {
WHERE c1.vocabulary_id = 1
} : { 
WHERE c1.vocabulary_id = 'SNOMED'
}
	AND ca1.min_levels_of_separation <= 2
	AND c1.concept_id NOT IN (0,
	76094,67368, 46042, 40949, 31332, 28263, 24955, 18791, 13449, 12571, 10678, 10592, 9878, 9727, 9652, 9451, 9192, 8975, 8930, 8786, 8370, 8161, 7763, 7059, 6923, 6752, 6690, 6611, 6336, 6264, 6204, 6003, 5783)
{@has_excluded_covariate_concept_ids} ? {	AND c1.concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND c1.concept_id IN (SELECT concept_id FROM #included_cov)}		
;


INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT DISTINCT CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 50 + ccr1.analysis_id AS covariate_id,
	CASE
		WHEN analysis_id = 701
			THEN 'Procedure observed within procedure group:  '
  ELSE 'Other procedure group analysis'
		END + CAST(cg1.ancestor_concept_id AS VARCHAR) + '-' + c1.concept_name AS covariate_name,
	ccr1.analysis_id,
	cg1.ancestor_concept_id AS concept_id
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 700
		AND analysis_id < 800
	) ccr1
INNER JOIN #procedure_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON cg1.ancestor_concept_id = c1.concept_id;


SELECT DISTINCT cc1.row_id,
	CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 50 + ccr1.analysis_id AS covariate_id,
	time_id,
	1 AS covariate_value
INTO #cov_pg
FROM (

SELECT row_id, covariate_id, time_id, covariate_value FROM #dummy

{@use_covariate_procedure_occurrence} ? {
UNION
SELECT row_id, covariate_id, time_id, covariate_value FROM #cov_pr_oc
}


) cc1
INNER JOIN (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 700
		AND analysis_id < 800
	) ccr1
	ON cc1.covariate_id = ccr1.covariate_id
INNER JOIN #procedure_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
;

TRUNCATE TABLE #procedure_group;

DROP TABLE #procedure_group;
}

/**************************
***************************
OBSERVATION
***************************
**************************/
{@use_covariate_observation_occurrence} ? {

--observation is present in time period
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.observation_concept_id AS BIGINT) * 1000 + 801 AS covariate_id,
	tp1.time_id AS time_id,
	1 AS covariate_value
INTO #cov_ob_oc
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.observation ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.observation_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.observation_date, cp1.cohort_start_date) >= tp1.start_day
WHERE ce1.observation_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.observation_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.observation_concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Observation observed:  ' + CAST((p1.covariate_id-801)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	801 AS analysis_id,
	(p1.covariate_id-801)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_ob_oc) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-801)/1000 = c1.concept_id
;
}

/**************************
***************************
VISIT
***************************
**************************/
{@use_covariate_visit_occurrence} ? {

--visit is present in time period
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.visit_concept_id AS BIGINT) * 1000 + 901 AS covariate_id,
	tp1.time_id AS time_id,
	1 AS covariate_value
INTO #cov_vi_oc
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.visit_occurrence ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.visit_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.visit_start_date, cp1.cohort_start_date) >= tp1.start_day
WHERE ce1.visit_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.observation_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.observation_concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	'Visit observed:  ' + CAST((p1.covariate_id-901)/1000 AS VARCHAR) + '-' + CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END AS covariate_name,
	901 AS analysis_id,
	(p1.covariate_id-901)/1000 AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_vi_oc) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-901)/1000 = c1.concept_id
;
}

/**************************
***************************
DATA DENSITY CONCEPT COUNTS
***************************
**************************/
{@use_covariate_concept_counts} ? {

--Number of distinct conditions observed in timewindow
SELECT cp1.@row_id_field AS row_id,
	1000 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(DISTINCT ce1.condition_concept_id) AS covariate_value
    INTO #cov_dd_cond
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_era ce1
	ON cp1.subject_id = ce1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, ce1.condition_era_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, ce1.condition_era_start_date, cp1.cohort_start_date) >= tp1.start_day
GROUP BY cp1.@row_id_field, tp1.time_id;


INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1000,
	'Number of distinct conditions ',
	1000,
	0
	);


--Number of distinct drug ingredients observed in timewindow
SELECT cp1.@row_id_field AS row_id,
	1001 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(DISTINCT de1.drug_concept_id) AS covariate_value
  INTO #cov_dd_drug
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era de1
	ON cp1.subject_id = de1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, de1.drug_era_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, de1.drug_era_start_date, cp1.cohort_start_date) >= tp1.start_day
GROUP BY cp1.@row_id_field, tp1.time_id;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1001,
	'Number of distinct drug ingredients',
	1001,
	0
	);


--Number of distinct procedures observed in timewindow
SELECT cp1.@row_id_field AS row_id,
	1002 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(DISTINCT po1.procedure_concept_id) AS covariate_value
  INTO #cov_dd_proc
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.procedure_occurrence po1
	ON cp1.subject_id = po1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, po1.procedure_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, po1.procedure_date, cp1.cohort_start_date) >= tp1.start_day
GROUP BY cp1.@row_id_field, tp1.time_id;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1002,
	'Number of distinct procedures',
	1002,
	0
	);


--Number of distinct observations observed in timewindow
SELECT cp1.@row_id_field AS row_id,
	1003 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(DISTINCT o1.observation_concept_id) AS covariate_value
  INTO #cov_dd_obs
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.observation o1
	ON cp1.subject_id = o1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, o1.observation_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, o1.observation_date, cp1.cohort_start_date) >= tp1.start_day
GROUP BY cp1.@row_id_field, tp1.time_id;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1003,
	'Number of distinct observations',
	1003,
	0
	);
	


--Number of visits observed in timewindow
SELECT cp1.@row_id_field AS row_id,
	1004 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(vo1.visit_occurrence_id) AS covariate_value
  INTO #cov_dd_visit_all
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.visit_occurrence vo1
	ON cp1.subject_id = vo1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, vo1.visit_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, vo1.visit_start_date, cp1.cohort_start_date) >= tp1.start_day
GROUP BY cp1.@row_id_field, tp1.time_id;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1004,
	'Number of visits',
	1004,
	0
	);


--Number of inpatient visits observed in timewindow
SELECT cp1.@row_id_field AS row_id,
	1005 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(vo1.visit_occurrence_id) AS covariate_value
  INTO #cov_dd_visit_inpt
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.visit_occurrence vo1
	ON cp1.subject_id = vo1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, vo1.visit_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, vo1.visit_start_date, cp1.cohort_start_date) >= tp1.start_day
{@cdm_version == '4'} ? {
	AND vo1.place_of_service_concept_id = 9201
} : {
	AND vo1.visit_concept_id = 9201
}
GROUP BY cp1.@row_id_field, tp1.time_id;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1005,
	'Number of inpatient visits',
	1005,
	0
	);


--Number of ER visits observed in timewindow
SELECT cp1.@row_id_field AS row_id,
	1006 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(vo1.visit_occurrence_id) AS covariate_value
INTO #cov_dd_visit_er
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.visit_occurrence vo1
	ON cp1.subject_id = vo1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, vo1.visit_start_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, vo1.visit_start_date, cp1.cohort_start_date) >= tp1.start_day
{@cdm_version == '4'} ? {
	AND vo1.place_of_service_concept_id = 9203
} : {
	AND vo1.visit_concept_id = 9203
}
GROUP BY cp1.@row_id_field, tp1.time_id;


INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1006,
	'Number of ER visits observed in 365d on or prior to cohort index',
	1006,
	0
	);
	
{@cdm_version != '4'} ? {
--Number of distinct measurements observed in 365d on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1007 AS covariate_id,
	tp1.time_id AS time_id,
	COUNT(DISTINCT o1.measurement_concept_id) AS covariate_value
  INTO #cov_dd_meas
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.measurement o1
	ON cp1.subject_id = o1.person_id
INNER JOIN #time_period tp1
    ON DATEDIFF(DAY, o1.measurement_date, cp1.cohort_start_date) <= tp1.end_day
    AND DATEDIFF(DAY, o1.measurement_date, cp1.cohort_start_date) >= tp1.start_day
GROUP BY cp1.@row_id_field, tp1.time_id;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1007,
	'Number of distinct measurements',
	1007,
	0
	);
}
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

{@use_covariate_condition_group} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_cg
}

{@use_covariate_drug_era_start} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dr_start
}

{@use_covariate_drug_era_present} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dr_pres
}

{@use_covariate_measurement_value} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_meas_val
}

{@use_covariate_measurement_below} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_meas_below
}

{@use_covariate_measurement_above} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_meas_above
}

{@use_covariate_procedure_occurrence} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_pr_oc
}

{@use_covariate_procedure_group} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_pg

}
{@use_covariate_observation_occurrence} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_ob_oc
}

{@use_covariate_visit_occurrence} ? {
UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_vi_oc
}

{@use_covariate_concept_counts} ? {

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_cond

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_drug

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_proc

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_obs

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_visit_all

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_visit_inpt

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_visit_er

UNION

SELECT row_id, covariate_id, time_id, covariate_value
FROM #cov_dd_meas
}

) all_covariates
ORDER BY row_id,time_id;

/**********************************************
***********************************************
Cleanup: delete all temp tables
***********************************************
**********************************************/
IF OBJECT_ID('tempdb..#cov_co_start', 'U') IS NOT NULL
  DROP TABLE #cov_co_start;
IF OBJECT_ID('tempdb..#cov_co_pres', 'U') IS NOT NULL
  DROP TABLE #cov_co_pres;
IF OBJECT_ID('tempdb..#cov_cg', 'U') IS NOT NULL
  DROP TABLE #cov_cg;
IF OBJECT_ID('tempdb..#cov_dr_start', 'U') IS NOT NULL
  DROP TABLE #cov_dr_start;
IF OBJECT_ID('tempdb..#cov_dr_pres', 'U') IS NOT NULL
  DROP TABLE #cov_dr_pres;
IF OBJECT_ID('tempdb..#cov_meas_val', 'U') IS NOT NULL
  DROP TABLE #cov_meas_val;  
IF OBJECT_ID('tempdb..#cov_meas_below', 'U') IS NOT NULL
  DROP TABLE #cov_meas_below;  
IF OBJECT_ID('tempdb..#cov_meas_above', 'U') IS NOT NULL
  DROP TABLE #cov_meas_above;  
IF OBJECT_ID('tempdb..#cov_pr_oc', 'U') IS NOT NULL
  DROP TABLE #cov_pr_oc; 
IF OBJECT_ID('tempdb..#cov_pg', 'U') IS NOT NULL
  DROP TABLE #cov_pg;
IF OBJECT_ID('tempdb..#cov_ob_oc', 'U') IS NOT NULL
  DROP TABLE #cov_ob_oc; 
IF OBJECT_ID('tempdb..#cov_vi_oc', 'U') IS NOT NULL
  DROP TABLE #cov_vi_oc; 
IF OBJECT_ID('tempdb..#cov_dd_cond', 'U') IS NOT NULL
  DROP TABLE #cov_dd_cond;
IF OBJECT_ID('tempdb..#cov_dd_drug', 'U') IS NOT NULL
  DROP TABLE #cov_dd_drug;
IF OBJECT_ID('tempdb..#cov_dd_proc', 'U') IS NOT NULL
  DROP TABLE #cov_dd_proc;
IF OBJECT_ID('tempdb..#cov_dd_obs', 'U') IS NOT NULL
  DROP TABLE #cov_dd_obs;
IF OBJECT_ID('tempdb..#cov_dd_visit_all', 'U') IS NOT NULL
  DROP TABLE #cov_dd_visit_all;
IF OBJECT_ID('tempdb..#cov_dd_visit_inpt', 'U') IS NOT NULL
  DROP TABLE #cov_dd_visit_inpt;
IF OBJECT_ID('tempdb..#cov_dd_visit_er', 'U') IS NOT NULL
  DROP TABLE #cov_dd_visit_er;

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