/************************************************************************
@file GetCovariates.sql

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
{DEFAULT @cdm_version == '4'}
{DEFAULT @cohort_temp_table = '#cohort_person'}
{DEFAULT @row_id_field = 'person_id'}
{DEFAULT @cohort_definition_id = 'cohort_concept_id'}
{DEFAULT @concept_class_id = 'concept_class'}
{DEFAULT @measurement = 'observation'}
{DEFAULT @use_covariate_demographics = TRUE}
{DEFAULT @use_covariate_demographics_age = TRUE}
{DEFAULT @use_covariate_demographics_gender = TRUE}
{DEFAULT @use_covariate_demographics_race = TRUE}
{DEFAULT @use_covariate_demographics_ethnicity = TRUE}
{DEFAULT @use_covariate_demographics_year = TRUE}
{DEFAULT @use_covariate_demographics_month = TRUE}
{DEFAULT @use_covariate_condition_occurrence = TRUE}
{DEFAULT @use_covariate_condition_occurrence_long_term = TRUE}
{DEFAULT @use_covariate_condition_occurrence_short_term = TRUE}
{DEFAULT @use_covariate_condition_occurrence_inpt_medium_term = TRUE}
{DEFAULT @use_covariate_condition_era = FALSE}
{DEFAULT @use_covariate_condition_era_ever = TRUE}
{DEFAULT @use_covariate_condition_era_overlap = TRUE}
{DEFAULT @use_covariate_condition_group = FALSE}
{DEFAULT @use_covariate_condition_group_meddra = TRUE}
{DEFAULT @use_covariate_condition_group_snomed = TRUE}
{DEFAULT @use_covariate_drug_exposure = FALSE}
{DEFAULT @use_covariate_drug_exposure_long_term = TRUE}
{DEFAULT @use_covariate_drug_exposure_short_term = TRUE}
{DEFAULT @use_covariate_drug_era = FALSE}
{DEFAULT @use_covariate_drug_era_long_term = TRUE}
{DEFAULT @use_covariate_drug_era_short_term = TRUE}
{DEFAULT @use_covariate_drug_era_overlap = TRUE}
{DEFAULT @use_covariate_drug_era_ever = TRUE}
{DEFAULT @use_covariate_drug_group = FALSE}
{DEFAULT @use_covariate_procedure_occurrence = FALSE}
{DEFAULT @use_covariate_procedure_occurrence_long_term = TRUE}
{DEFAULT @use_covariate_procedure_occurrence_short_term = TRUE}
{DEFAULT @use_covariate_procedure_group = FALSE}
{DEFAULT @use_covariate_observation = FALSE}
{DEFAULT @use_covariate_observation_long_term = TRUE}
{DEFAULT @use_covariate_observation_short_term = TRUE}
{DEFAULT @use_covariate_observation_count_long_term = TRUE}
{DEFAULT @use_covariate_measurement = FALSE}
{DEFAULT @use_covariate_measurement_long_term = TRUE}
{DEFAULT @use_covariate_measurement_short_term = TRUE}
{DEFAULT @use_covariate_measurement_below = TRUE}
{DEFAULT @use_covariate_measurement_above = TRUE}
{DEFAULT @use_covariate_measurement_count_long_term = TRUE}
{DEFAULT @use_covariate_concept_counts = FALSE}
{DEFAULT @use_covariate_risk_scores = FALSE}
{DEFAULT @use_covariate_risk_scores_Charlson = TRUE}
{DEFAULT @use_covariate_risk_scores_DCSI = TRUE}
{DEFAULT @use_covariate_risk_scores_CHADS2 = TRUE}
{DEFAULT @use_covariate_risk_scores_CHADS2VASc = TRUE}
{DEFAULT @use_covariate_interaction_year = FALSE}
{DEFAULT @use_covariate_interaction_month = FALSE}
{DEFAULT @has_excluded_covariate_concept_ids}
{DEFAULT @has_included_covariate_concept_ids}
{DEFAULT @delete_covariates_small_count = 100}
{DEFAULT @long_term_days = 365}
{DEFAULT @medium_term_days = 180}
{DEFAULT @short_term_days = 30}
{DEFAULT @window_end_days = 0}

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
	covariate_value INT
	);

/**************************
***************************
DEMOGRAPHICS
***************************
**************************/
{@use_covariate_demographics} ? {



{@use_covariate_demographics_gender} ? {
--gender
SELECT cp1.@row_id_field AS row_id,
	gender_concept_id AS covariate_id,
	1 AS covariate_value
INTO #cov_gender
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.person p1
	ON cp1.subject_id = p1.person_id
WHERE p1.gender_concept_id IN (
		SELECT concept_id
		FROM @cdm_database_schema.concept
		WHERE LOWER(@concept_class_id) = 'gender'
		);


INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
    CASE WHEN v1.concept_name IS NOT NULL
			THEN CONCAT('Gender = ', v1.concept_name)
		ELSE CONCAT('Gender = ', 'Unknown invalid concept')
		END AS covariate_name,
	2 AS analysis_id,
	p1.covariate_id AS concept_id
FROM (SELECT distinct covariate_id FROM #cov_gender) p1
LEFT JOIN (
	SELECT concept_id,
		concept_name
	FROM @cdm_database_schema.concept
	WHERE LOWER(@concept_class_id) = 'gender'
	) v1
	ON p1.covariate_id = v1.concept_id;

}


{@use_covariate_demographics_race} ? {
--race
SELECT cp1.@row_id_field AS row_id,
	race_concept_id AS covariate_id,
	1 AS covariate_value
  INTO #cov_race
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.person p1
	ON cp1.subject_id = p1.person_id
WHERE p1.race_concept_id IN (
		SELECT concept_id
		FROM @cdm_database_schema.concept
		WHERE LOWER(@concept_class_id) = 'race'
		);


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CASE WHEN v1.concept_name IS NOT NULL
  		THEN CONCAT('Race =', v1.concept_name)
		ELSE CONCAT('Race =', 'Unknown invalid concept')
		END  AS covariate_name,
	3 AS analysis_id,
	p1.covariate_id AS concept_id
FROM (SELECT distinct covariate_id FROM #cov_race) p1
LEFT JOIN (
	SELECT concept_id,
		concept_name
	FROM @cdm_database_schema.concept
	WHERE LOWER(@concept_class_id) = 'race'
	) v1
	ON p1.covariate_id = v1.concept_id;


}

{@use_covariate_demographics_ethnicity} ? {
--ethnicity
SELECT cp1.@row_id_field AS row_id,
	ethnicity_concept_id AS covariate_id,
	1 AS covariate_value
  INTO #cov_ethnicity
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.person p1
	ON cp1.subject_id = p1.person_id
WHERE p1.ethnicity_concept_id IN (
		SELECT concept_id
		FROM @cdm_database_schema.concept
		WHERE LOWER(@concept_class_id) = 'ethnicity'
		);



INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Ethnicity = ', CASE WHEN v1.concept_name IS NOT NULL
  		THEN v1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	4 AS analysis_id,
	p1.covariate_id AS concept_id
FROM (SELECT distinct covariate_id FROM #cov_ethnicity) p1
LEFT JOIN (
	SELECT concept_id,
		concept_name
	FROM @cdm_database_schema.concept
	WHERE LOWER(@concept_class_id) = 'ethnicity'
	) v1
	ON p1.covariate_id = v1.concept_id;


}


{@use_covariate_demographics_age} ? {
--age group
SELECT cp1.@row_id_field AS row_id,
	FLOOR((YEAR(cp1.cohort_start_date) - p1.YEAR_OF_BIRTH) / 5) + 10 AS covariate_id,
	1 AS covariate_value
    INTO #cov_age
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.person p1
	ON cp1.subject_id = p1.person_id
WHERE (YEAR(cp1.cohort_start_date) - p1.YEAR_OF_BIRTH) >= 0
	AND (YEAR(cp1.cohort_start_date) - p1.YEAR_OF_BIRTH) < 100;




INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Age group: ', CAST((covariate_id-10)*5 AS VARCHAR), '-', CAST((covariate_id-10+1)*5-1 AS VARCHAR)) AS covariate_name,
	5 AS analysis_id,
	0 AS concept_id
FROM (select distinct covariate_id FROM #cov_age) p1
;



}


{@use_covariate_demographics_year} ? {
--index year
SELECT cp1.@row_id_field AS row_id,
	YEAR(cohort_start_date) AS covariate_id,
	1 AS covariate_value
    INTO #cov_year
FROM @cohort_temp_table cp1;


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Index year: ', CAST(covariate_id AS VARCHAR)) AS covariate_name,
	6 AS analysis_id,
	0 AS concept_id
FROM (select distinct covariate_id FROM #cov_year) p1
;

}


{@use_covariate_demographics_month} ? {

--index month

SELECT cp1.@row_id_field AS row_id,
	MONTH(cohort_start_date) + 40 AS covariate_id,
	1 AS covariate_value
    INTO #cov_month
FROM @cohort_temp_table cp1;


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Index month: ', CAST(covariate_id-40 AS VARCHAR))  AS covariate_name,
	7 AS analysis_id,
	0 AS concept_id
FROM (select distinct covariate_id FROM #cov_month) p1
;

}

}



/**************************
***************************
CONDITION OCCURRENCE
***************************
**************************/
	{@use_covariate_condition_occurrence} ? { {@use_covariate_condition_occurrence_long_term} ? {

--conditions exist:  episode in last long_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(co1.condition_concept_id AS BIGINT) * 1000 + 101 AS covariate_id,
	1 AS covariate_value
  INTO #cov_co_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_occurrence co1
	ON cp1.subject_id = co1.person_id
WHERE co1.condition_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND co1.condition_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND co1.condition_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND co1.condition_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND co1.condition_start_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date);

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Condition occurrence record observed during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-101)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	101 AS analysis_id,
	CAST((p1.covariate_id-101)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_co_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-101)/1000 = c1.concept_id
;


} {@use_covariate_condition_occurrence_short_term} ? {

--conditions:  episode in last short_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(co1.condition_concept_id AS BIGINT) * 1000 + 102 AS covariate_id,
	1 AS covariate_value
  INTO #cov_co_short_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_occurrence co1
	ON cp1.subject_id = co1.person_id
WHERE co1.condition_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND co1.condition_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND co1.condition_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND co1.condition_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND co1.condition_start_date >= DATEADD(DAY, - @short_term_days, cp1.cohort_start_date);

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Condition occurrence record observed during short_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-102)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	102 AS analysis_id,
  CAST((p1.covariate_id-102)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_co_short_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-102)/1000 = c1.concept_id
;



} {@use_covariate_condition_occurrence_inpt_medium_term} ? {

--conditions:  primary inpatient diagnosis in last 180d

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(co1.condition_concept_id AS BIGINT) * 1000 + 103 AS covariate_id,
	1 AS covariate_value
  INTO #cov_co_inpt_med
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_occurrence co1
	ON cp1.subject_id = co1.person_id
WHERE co1.condition_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND co1.condition_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND co1.condition_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND co1.condition_type_concept_id IN (38000183, 38000184, 38000199, 38000200)
	AND co1.condition_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND co1.condition_start_date >= DATEADD(DAY, - @medium_term_days, cp1.cohort_start_date);



INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Condition occurrence record of primary inpatient diagnosis observed during 180d on or prior to cohort index:  ', CAST((p1.covariate_id-103)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	103 AS analysis_id,
	CAST((p1.covariate_id-103)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_co_inpt_med) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-103)/1000 = c1.concept_id
;


} }



/**************************
***************************
CONDITION ERA
***************************
**************************/
	{@use_covariate_condition_era} ? { {@use_covariate_condition_era_ever} ? {

--condition:  exist any time prior

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.condition_concept_id AS BIGINT) * 1000 + 201 AS covariate_id,
	1 AS covariate_value
  INTO #cov_ce_ever
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_era ce1
	ON cp1.subject_id = ce1.person_id
LEFT JOIN @cdm_database_schema.concept c1
	ON ce1.condition_concept_id = c1.concept_id
WHERE ce1.condition_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.condition_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.condition_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND ce1.condition_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date);


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
  concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Condition era record observed during anytime on or prior to cohort index:    ', CAST((p1.covariate_id-201)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	201 AS analysis_id,
	CAST((p1.covariate_id-201)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_ce_ever) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-201)/1000 = c1.concept_id
;

}


{@use_covariate_condition_era_overlap} ? {

--concurrent on index date (era overlapping)

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(ce1.condition_concept_id AS BIGINT) * 1000 + 202 AS covariate_id,
	1 AS covariate_value
  INTO #cov_ce_overlap
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_era ce1
	ON cp1.subject_id = ce1.person_id
LEFT JOIN @cdm_database_schema.concept c1
	ON ce1.condition_concept_id = c1.concept_id
WHERE ce1.condition_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND ce1.condition_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ce1.condition_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND ce1.condition_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND ce1.condition_era_end_date >= cp1.cohort_start_date;



INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
  concept_id
  )
SELECT p1.covariate_id,
	CONCAT('Condition era record observed concurrent (overlapping) with cohort index:    ', CAST((p1.covariate_id-202)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	202 AS analysis_id,
	CAST((p1.covariate_id-202)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_ce_overlap) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-202)/1000 = c1.concept_id
;



}

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
		AND analysis_id < 300
	) ccr1
INNER JOIN @cdm_database_schema.concept_ancestor ca1
	ON ccr1.concept_id = ca1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON ca1.ancestor_concept_id = c1.concept_id
{@cdm_version == '4'} ? {
WHERE c1.vocabulary_id = 15
} : {
WHERE LOWER(c1.vocabulary_id) = 'meddra'
}
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
		AND analysis_id < 300
	) ccr1
INNER JOIN @cdm_database_schema.concept_ancestor ca1
	ON ccr1.concept_id = ca1.descendant_concept_id
INNER JOIN (
	SELECT c1.concept_id, c1.concept_name, c1.vocabulary_id, c1.domain_id
	FROM @cdm_database_schema.concept c1
	INNER JOIN @cdm_database_schema.concept_ancestor ca1
	ON ca1.ancestor_concept_id = 441840 /* SNOMED clinical finding */
		AND c1.concept_id = ca1.descendant_concept_id
	WHERE (ca1.min_levels_of_separation > 2
		OR c1.concept_id IN (433736, 433595, 441408, 72404, 192671, 137977, 434621, 437312, 439847, 4171917, 438555, 4299449, 375258, 76784, 40483532, 4145627, 434157, 433778, 258449, 313878)
		) 
		AND LOWER(c1.concept_name) NOT LIKE '%finding'
		AND LOWER(c1.concept_name) NOT LIKE 'disorder of%'
		AND LOWER(c1.concept_name) NOT LIKE 'finding of%'
		AND LOWER(c1.concept_name) NOT LIKE 'disease of%'
		AND LOWER(c1.concept_name) NOT LIKE 'injury of%'
		AND LOWER(c1.concept_name) NOT LIKE '%by site'
		AND LOWER(c1.concept_name) NOT LIKE '%by body site'
		AND LOWER(c1.concept_name) NOT LIKE '%by mechanism'
		AND LOWER(c1.concept_name) NOT LIKE '%of body region'
		AND LOWER(c1.concept_name) NOT LIKE '%of anatomical site'
		AND LOWER(c1.concept_name) NOT LIKE '%of specific body structure%'
{@cdm_version == '4'} ? {
		AND LOWER(c1.@concept_class_id) = 'clinical finding'
} : {
		AND c1.domain_id = 'Condition'
}
) t1
ON ca1.ancestor_concept_id = t1.concept_id	
{@has_excluded_covariate_concept_ids} ? {  AND t1.concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {  AND t1.concept_id IN (SELECT concept_id FROM #included_cov)}
;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT DISTINCT CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 50 + ccr1.analysis_id AS covariate_id,
	CONCAT(CASE
		WHEN analysis_id = 101
			THEN 'Condition occurrence record observed during long_term_days on or prior to cohort index within condition group:  '
		WHEN analysis_id = 102
			THEN 'Condition occurrence record observed during short_term_days on or prior to cohort index within condition group:  '
		WHEN analysis_id = 103
			THEN 'Condition occurrence record of primary inpatient diagnosis observed during 180d on or prior to cohort index within condition group:  '
		WHEN analysis_id = 201
			THEN 'Condition era record observed during anytime on or prior to cohort index within condition group:  '
		WHEN analysis_id = 202
			THEN 'Condition era record observed concurrent (overlapping) with cohort index within condition group:  '
		ELSE 'Other condition group analysis'
		END, CAST(cg1.ancestor_concept_id AS VARCHAR), '-', c1.concept_name) AS covariate_name,
	ccr1.analysis_id,
	cg1.ancestor_concept_id AS concept_id
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 100
		AND analysis_id < 300
	) ccr1
INNER JOIN #condition_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON cg1.ancestor_concept_id = c1.concept_id;


SELECT DISTINCT cc1.row_id,
	CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 50 + ccr1.analysis_id AS covariate_id,
	1 AS covariate_value
INTO #cov_cg
FROM (
SELECT row_id, covariate_id, covariate_value FROM #dummy
{@use_covariate_condition_occurrence} ? {
{@use_covariate_condition_occurrence_long_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_co_long_term
}
{@use_covariate_condition_occurrence_short_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_co_short_term
}
{@use_covariate_condition_occurrence_inpt_medium_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_co_inpt_med
}
}

{@use_covariate_condition_era} ? {
{@use_covariate_condition_era_ever} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_ce_ever
}
{@use_covariate_condition_era_overlap} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_ce_overlap
}
}

) cc1
INNER JOIN (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 100
		AND analysis_id < 300
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
DRUG EXPOSURE
***************************
**************************/
	{@use_covariate_drug_exposure} ? { {@use_covariate_drug_exposure_long_term} ? {

--drug exist:  episode in last long_term_days prior

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(de1.drug_concept_id AS BIGINT) * 1000 + 401 AS covariate_id,
	1 AS covariate_value
INTO #cov_de_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_exposure de1
	ON cp1.subject_id = de1.person_id
WHERE de1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {  AND de1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {  AND de1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND de1.drug_exposure_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND de1.drug_exposure_start_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date);


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Drug exposure record observed during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-401)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	401 AS analysis_id,
	CAST((p1.covariate_id-401)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_de_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-401)/1000 = c1.concept_id
;
}


{@use_covariate_drug_exposure_short_term} ? {

--drug exist:  episode in last short_term_days prior

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(de1.drug_concept_id AS BIGINT) * 1000 + 402 AS covariate_id,
	1 AS covariate_value
  INTO #cov_de_short_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_exposure de1
	ON cp1.subject_id = de1.person_id
WHERE de1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND de1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND de1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND de1.drug_exposure_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND de1.drug_exposure_start_date >= DATEADD(DAY, - @short_term_days, cp1.cohort_start_date);


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Drug exposure record observed during short_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-402)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	402 AS analysis_id,
	CAST((p1.covariate_id-402)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_de_short_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-402)/1000 = c1.concept_id
;


}


}
/**************************
***************************
DRUG ERA
***************************
**************************/
	{@use_covariate_drug_era} ? { {@use_covariate_drug_era_long_term} ? {

--drug exist:  episode in last long_term_days prior

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(de1.drug_concept_id AS BIGINT) * 1000 + 501 AS covariate_id,
	1 AS covariate_value
INTO #cov_dera_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era de1
	ON cp1.subject_id = de1.person_id
WHERE de1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND de1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND de1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
 	AND de1.drug_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND de1.drug_era_end_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date);



INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Drug era record observed during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-501)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	501 AS analysis_id,
	CAST((p1.covariate_id-501)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_dera_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-501)/1000 = c1.concept_id
;


}


{@use_covariate_drug_era_short_term} ? {

--drug exist:  episode in last short_term_days prior

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(de1.drug_concept_id AS BIGINT) * 1000 + 502 AS covariate_id,
	1 AS covariate_value
INTO #cov_dera_short_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era de1
	ON cp1.subject_id = de1.person_id
WHERE de1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND de1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND de1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND de1.drug_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND de1.drug_era_end_date >= DATEADD(DAY, - @short_term_days, cp1.cohort_start_date);


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
  concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Drug era record observed during short_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-502)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	502 AS analysis_id,
	CAST((p1.covariate_id-502)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_dera_short_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-502)/1000 = c1.concept_id
;

}


{@use_covariate_drug_era_overlap} ? {

--concurrent on index date (era overlapping)

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(de1.drug_concept_id AS BIGINT) * 1000 + 503 AS covariate_id,
	1 AS covariate_value
  INTO #cov_dera_overlap
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era de1
	ON cp1.subject_id = de1.person_id
WHERE de1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND de1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND de1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND de1.drug_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND de1.drug_era_end_date >= cp1.cohort_start_date;


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
  concept_id
  )
SELECT p1.covariate_id,
	CONCAT('Drug era record observed concurrent (overlapping) with cohort index:  ', CAST((p1.covariate_id-503)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	503 AS analysis_id,
	CAST((p1.covariate_id-503)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_dera_overlap) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-503)/1000 = c1.concept_id
;

}


{@use_covariate_drug_era_ever} ? {

--drug exist:  episode in all time prior

SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(de1.drug_concept_id AS BIGINT) * 1000 + 504 AS covariate_id,
	1 AS covariate_value
  INTO #cov_dera_ever
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era de1
	ON cp1.subject_id = de1.person_id
WHERE de1.drug_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND de1.drug_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND de1.drug_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND de1.drug_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date);



INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
  concept_id
  )
SELECT p1.covariate_id,
  CONCAT('Drug era record observed during anytime on or prior to cohort index:  ', CAST((p1.covariate_id-504)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	504 AS analysis_id,
	CAST((p1.covariate_id-504)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_dera_ever) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-504)/1000 = c1.concept_id
;

} }



/**************************
***************************
DRUG GROUP
***************************
**************************/
	{@use_covariate_drug_group} ? {


IF OBJECT_ID('tempdb..#drug_group', 'U') IS NOT NULL
	DROP TABLE #drug_group;

--ATC
SELECT DISTINCT ca1.descendant_concept_id,
	ca1.ancestor_concept_id
  INTO #drug_group
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 400
		AND analysis_id < 600
	) ccr1
INNER JOIN @cdm_database_schema.concept_ancestor ca1
	ON ccr1.concept_id = ca1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON ca1.ancestor_concept_id = c1.concept_id
{@cdm_version == '4'} ? {
WHERE c1.vocabulary_id = 21
} : {
WHERE LOWER(c1.vocabulary_id) = 'atc'
}
	AND len(c1.concept_code) IN (1, 3, 4, 5)
	AND c1.concept_id != 0
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
	CONCAT(CASE
		WHEN analysis_id = 401
			THEN 'Drug exposure record observed during long_term_days on or prior to cohort index within drug group:  '
		WHEN analysis_id = 402
			THEN 'Drug exposure record observed during short_term_days on or prior to cohort index within drug group:  '
		WHEN analysis_id = 501
			THEN 'Drug era record observed during long_term_days on or prior to cohort index within drug group:  '
		WHEN analysis_id = 502
			THEN 'Drug era record observed during short_term_days on or prior to cohort index within drug group:  '
		WHEN analysis_id = 503
			THEN 'Drug era record observed concurrent (overlapping) with cohort index within drug group:  '
    WHEN analysis_id = 504
  		THEN 'Drug era record observed during anytime on or prior to cohort index within drug group:  '
  ELSE 'Other drug group analysis'
		END, CAST(cg1.ancestor_concept_id AS VARCHAR), '-', c1.concept_name) AS covariate_name,
	ccr1.analysis_id,
	cg1.ancestor_concept_id AS concept_id
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 400
		AND analysis_id < 600
	) ccr1
INNER JOIN #drug_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON cg1.ancestor_concept_id = c1.concept_id;


SELECT DISTINCT cc1.row_id,
	CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 50 + ccr1.analysis_id AS covariate_id,
	1 AS covariate_value
  INTO #cov_dg
FROM (
SELECT row_id, covariate_id, covariate_value FROM #dummy

{@use_covariate_drug_exposure} ? {
{@use_covariate_drug_exposure_long_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_de_long_term
}
{@use_covariate_drug_exposure_short_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_de_short_term
}
}

{@use_covariate_drug_era} ? {
{@use_covariate_drug_era_long_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_long_term
}
{@use_covariate_drug_era_short_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_short_term
}
{@use_covariate_drug_era_ever} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_ever
}
{@use_covariate_drug_era_overlap} ? {
UNION
SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_overlap
}
}

) cc1
INNER JOIN (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id > 400
		AND analysis_id < 600
	) ccr1
	ON cc1.covariate_id = ccr1.covariate_id
INNER JOIN #drug_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id;


{@use_covariate_drug_era_ever} ? {

--number of drugs within each ATC3 groupings all time prior
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT DISTINCT CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 601 AS covariate_id,
	CONCAT('Number of ingredients within the drug group observed all time on or prior to cohort index: ', CAST(cg1.ancestor_concept_id AS VARCHAR), '-', c1.concept_name) AS covariate_name,
	601 AS analysis_id,
	cg1.ancestor_concept_id AS concept_id
FROM (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id = 504
	) ccr1
INNER JOIN #drug_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON cg1.ancestor_concept_id = c1.concept_id
WHERE len(c1.concept_code) = 3;


SELECT cc1.row_id,
	CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 601 AS covariate_id,
	COUNT(DISTINCT ccr1.concept_id) AS covariate_value
    INTO #cov_dg_count
FROM #cov_dera_ever cc1
INNER JOIN (
	SELECT covariate_id,
		covariate_name,
		analysis_id,
		concept_id
	FROM #cov_ref
	WHERE analysis_id = 504
	) ccr1
	ON cc1.covariate_id = ccr1.covariate_id
INNER JOIN #drug_group cg1
	ON ccr1.concept_id = cg1.descendant_concept_id
INNER JOIN @cdm_database_schema.concept c1
	ON cg1.ancestor_concept_id = c1.concept_id
WHERE len(c1.concept_code) = 3
GROUP BY cc1.row_id,
	CAST(cg1.ancestor_concept_id AS BIGINT) * 1000 + 601;
}

TRUNCATE TABLE #drug_group;

DROP TABLE #drug_group;

}
/**************************
***************************
PROCEDURE OCCURRENCE
***************************
**************************/
	{@use_covariate_procedure_occurrence} ? { {@use_covariate_procedure_occurrence_long_term} ? {

--procedures exist:  episode in last long_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(po1.procedure_concept_id AS BIGINT) * 1000 + 701 AS covariate_id,
	1 AS covariate_value
  INTO #cov_po_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.procedure_occurrence po1
	ON cp1.subject_id = po1.person_id
WHERE po1.procedure_concept_id  != 0
{@has_excluded_covariate_concept_ids} ? {	AND po1.procedure_concept_id  NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND po1.procedure_concept_id  IN (SELECT concept_id FROM #included_cov)}
	AND po1.procedure_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND po1.procedure_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date);


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Procedure occurrence record observed during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-701)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	701 AS analysis_id,
	CAST((p1.covariate_id-701)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_po_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-701)/1000 = c1.concept_id
;
}

{@use_covariate_procedure_occurrence_short_term} ? {

--procedures exist:  episode in last short_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(po1.procedure_concept_id AS BIGINT) * 1000 + 702 AS covariate_id,
	1 AS covariate_value
  INTO #cov_po_short_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.procedure_occurrence po1
	ON cp1.subject_id = po1.person_id
WHERE po1.procedure_concept_id  != 0
{@has_excluded_covariate_concept_ids} ? {	AND po1.procedure_concept_id  NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND po1.procedure_concept_id  IN (SELECT concept_id FROM #included_cov)}
	AND po1.procedure_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND po1.procedure_date >= DATEADD(DAY, - @short_term_days, cp1.cohort_start_date);


INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
  analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Procedure occurrence record observed during short_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-702)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	702 AS analysis_id,
	CAST((p1.covariate_id-702)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_po_short_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-702)/1000 = c1.concept_id
;
}
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
WHERE LOWER(c1.vocabulary_id) = 'snomed'
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
	CONCAT(CASE
		WHEN analysis_id = 701
			THEN 'Procedure occurrence record observed during long_term_days on or prior to cohort index within procedure group:  '
		WHEN analysis_id = 702
			THEN 'Procedure occurrence record observed during short_term_days on or prior to cohort index within procedure group:  '
  ELSE 'Other procedure group analysis'
		END, CAST(cg1.ancestor_concept_id AS VARCHAR), '-', c1.concept_name) AS covariate_name,
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
	1 AS covariate_value
INTO #cov_pg
FROM (

SELECT row_id, covariate_id, covariate_value FROM #dummy

{@use_covariate_procedure_occurrence} ? {
{@use_covariate_procedure_occurrence_long_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value FROM #cov_po_long_term
}
{@use_covariate_procedure_occurrence_short_term} ? {
UNION
SELECT row_id, covariate_id, covariate_value FROM #cov_po_short_term
}
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
{@use_covariate_observation} ? {

{@use_covariate_observation_long_term} ? {

--observations exist:  episode in last long_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(o1.observation_concept_id AS BIGINT) * 1000 + 901 AS covariate_id,
	1 AS covariate_value
  INTO #cov_o_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.observation o1
	ON cp1.subject_id = o1.person_id
WHERE o1.observation_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND o1.observation_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND o1.observation_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND o1.observation_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.observation_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date);

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Observation record observed during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-901)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	901 AS analysis_id,
	CAST((p1.covariate_id-901)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_o_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-901)/1000 = c1.concept_id
;
}

{@use_covariate_observation_short_term} ? {

--observation exist:  episode in last short_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(o1.observation_concept_id AS BIGINT) * 1000 + 902 AS covariate_id,
	1 AS covariate_value
  INTO #cov_o_short_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.observation o1
	ON cp1.subject_id = o1.person_id
WHERE o1.observation_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND o1.observation_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND o1.observation_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND o1.observation_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.observation_date >= DATEADD(DAY, - @short_term_days, cp1.cohort_start_date);

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Observation record observed during short_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-902)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	902 AS analysis_id,
	CAST((p1.covariate_id-902)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_o_short_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-902)/1000 = c1.concept_id
;
}

{@use_covariate_observation_count_long_term} ? {

--number of observations:  episode in last long_term_days prior
SELECT cp1.@row_id_field AS row_id,
	CAST(o1.observation_concept_id AS BIGINT) * 1000 + 905 AS covariate_id,
	COUNT(observation_id) AS covariate_value
    INTO #cov_o_cnt_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.observation o1
	ON cp1.subject_id = o1.person_id
WHERE o1.observation_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND o1.observation_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND o1.observation_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND o1.observation_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.observation_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field,
	CAST(o1.observation_concept_id AS BIGINT) * 1000 + 905;

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Number of observations during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-905)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	905 AS analysis_id,
	CAST((p1.covariate_id-905)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_o_cnt_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-905)/1000 = c1.concept_id
;
}

}

{(cdm_version == '4' & @use_covariate_observation) | @use_covariate_measurement} ? {

{@use_covariate_measurement_below} ? {

--for numeric values with valid range, latest value within @medium_term_days below low
SELECT DISTINCT row_id,
	CAST(@measurement_concept_id AS BIGINT) * 1000 + 903 AS covariate_id,
	1 AS covariate_value
  INTO #cov_m_below
FROM (
	SELECT cp1.@row_id_field AS row_id,
		o1.@measurement_concept_id,
		o1.value_as_number,
		o1.range_low,
		o1.range_high,
		ROW_NUMBER() OVER (
			PARTITION BY cp1.@row_id_field,
			o1.@measurement_concept_id ORDER BY o1.@measurement_date DESC
			) AS rn1
	FROM @cohort_temp_table cp1
	INNER JOIN @cdm_database_schema.@measurement o1
		ON cp1.subject_id = o1.person_id
	WHERE o1.@measurement_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {		AND o1.@measurement_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {		AND o1.@measurement_concept_id IN (SELECT concept_id FROM #included_cov)}
		AND o1.@measurement_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
		AND o1.@measurement_date >= DATEADD(DAY, - @medium_term_days, cp1.cohort_start_date)
		AND o1.value_as_number >= 0
		AND o1.range_low >= 0
		AND o1.range_high >= 0
	) t1
WHERE RN1 = 1
	AND VALUE_AS_NUMBER < RANGE_LOW;

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Measurement numeric value below normal range for latest value within 180d of cohort index:  ', CAST((p1.covariate_id-903)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	903 AS analysis_id,
	CAST((p1.covariate_id-903)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_m_below) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-903)/1000 = c1.concept_id
;
}

{@use_covariate_measurement_above} ? {

--for numeric values with valid range, latest value above high
SELECT DISTINCT row_id,
	CAST(@measurement_concept_id AS BIGINT) * 1000 + 904 AS covariate_id,
	1 AS covariate_value
  INTO #cov_m_above
FROM (
	SELECT cp1.@row_id_field AS row_id,
		o1.@measurement_concept_id,
		o1.value_as_number,
		o1.range_low,
		o1.range_high,
		ROW_NUMBER() OVER (
			PARTITION BY cp1.@row_id_field,
			o1.@measurement_concept_id ORDER BY o1.@measurement_date DESC
			) AS rn1
	FROM @cohort_temp_table cp1
	INNER JOIN @cdm_database_schema.@measurement o1
		ON cp1.subject_id = o1.person_id
	WHERE o1.@measurement_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {		AND o1.@measurement_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {		AND o1.@measurement_concept_id IN (SELECT concept_id FROM #included_cov)}
		AND o1.@measurement_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
		AND o1.@measurement_date >= DATEADD(DAY, - @medium_term_days, cp1.cohort_start_date)
		AND o1.value_as_number >= 0
		AND o1.range_low >= 0
		AND o1.range_high >= 0
	) t1
WHERE RN1 = 1
	AND VALUE_AS_NUMBER > RANGE_HIGH;

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Measurement numeric value above normal range for latest value within 180d of cohort index:  ', CAST((p1.covariate_id-904)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	903 AS analysis_id,
	CAST((p1.covariate_id-904)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_m_above) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-904)/1000 = c1.concept_id
;
}
}

{@cdm_version != '4' & @use_covariate_measurement} ? {
{@use_covariate_measurement_long_term} ? {

--measurements exist:  episode in last long_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(o1.measurement_concept_id AS BIGINT) * 1000 + 901 AS covariate_id,
	1 AS covariate_value
  INTO #cov_m_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.measurement o1
	ON cp1.subject_id = o1.person_id
WHERE o1.measurement_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND o1.measurement_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND o1.measurement_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND o1.measurement_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.measurement_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date);

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Measurement record observed during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-901)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	901 AS analysis_id,
	CAST((p1.covariate_id-901)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_m_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-901)/1000 = c1.concept_id
;
}

{@use_covariate_measurement_short_term} ? {

--measurement exist:  episode in last short_term_days prior
SELECT DISTINCT cp1.@row_id_field AS row_id,
	CAST(o1.measurement_concept_id AS BIGINT) * 1000 + 902 AS covariate_id,
	1 AS covariate_value
  INTO #cov_m_short_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.measurement o1
	ON cp1.subject_id = o1.person_id
WHERE o1.measurement_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND o1.measurement_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND o1.measurement_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND o1.measurement_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.measurement_date >= DATEADD(DAY, - @short_term_days, cp1.cohort_start_date);

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Measurement record observed during short_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-902)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	902 AS analysis_id,
	CAST((p1.covariate_id-902)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_m_short_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-902)/1000 = c1.concept_id
;
}

{@use_covariate_measurement_count_long_term} ? {

--number of measurements:  episode in last long_term_days prior
SELECT cp1.@row_id_field AS row_id,
	CAST(o1.measurement_concept_id AS BIGINT) * 1000 + 905 AS covariate_id,
	COUNT(measurement_id) AS covariate_value
    INTO #cov_m_cnt_long_term
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.measurement o1
	ON cp1.subject_id = o1.person_id
WHERE o1.measurement_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND o1.measurement_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND o1.measurement_concept_id IN (SELECT concept_id FROM #included_cov)}
	AND o1.measurement_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.measurement_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field,
	CAST(o1.measurement_concept_id AS BIGINT) * 1000 + 905;

INSERT INTO #cov_ref (
  covariate_id,
  covariate_name,
	analysis_id,
	concept_id
	)
SELECT p1.covariate_id,
	CONCAT('Number of measurements during long_term_days on or prior to cohort index:  ', CAST((p1.covariate_id-905)/1000 AS VARCHAR), '-', CASE
		WHEN c1.concept_name IS NOT NULL
			THEN c1.concept_name
		ELSE 'Unknown invalid concept'
		END) AS covariate_name,
	905 AS analysis_id,
	CAST((p1.covariate_id-905)/1000 AS INT) AS concept_id
FROM (SELECT DISTINCT covariate_id FROM #cov_m_cnt_long_term) p1
LEFT JOIN @cdm_database_schema.concept c1
	ON (p1.covariate_id-905)/1000 = c1.concept_id
;
}
}


/**************************
***************************
DATA DENSITY CONCEPT COUNTS
***************************
**************************/
{@use_covariate_concept_counts} ? {

--Number of distinct conditions observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1000 AS covariate_id,
	COUNT(DISTINCT ce1.condition_concept_id) AS covariate_value
    INTO #cov_dd_cond
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.condition_era ce1
	ON cp1.subject_id = ce1.person_id
WHERE ce1.condition_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND ce1.condition_era_end_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field;


INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1000,
	'Number of distinct conditions observed in long_term_days on or prior to cohort index',
	1000,
	0
	);


--Number of distinct drug ingredients observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1001 AS covariate_id,
	COUNT(DISTINCT de1.drug_concept_id) AS covariate_value
  INTO #cov_dd_drug
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.drug_era de1
	ON cp1.subject_id = de1.person_id
WHERE de1.drug_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND de1.drug_era_start_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1001,
	'Number of distinct drug ingredients observed in long_term_days on or prior to cohort index',
	1001,
	0
	);


--Number of distinct procedures observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1002 AS covariate_id,
	COUNT(DISTINCT po1.procedure_concept_id) AS covariate_value
  INTO #cov_dd_proc
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.procedure_occurrence po1
	ON cp1.subject_id = po1.person_id
WHERE po1.procedure_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND po1.procedure_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1002,
	'Number of distinct procedures observed in long_term_days on or prior to cohort index',
	1002,
	0
	);


--Number of distinct observations observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1003 AS covariate_id,
	COUNT(DISTINCT o1.observation_concept_id) AS covariate_value
  INTO #cov_dd_obs
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.observation o1
	ON cp1.subject_id = o1.person_id
WHERE o1.observation_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.observation_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1003,
	'Number of distinct observations observed in long_term_days on or prior to cohort index',
	1003,
	0
	);

--Number of visits observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1004 AS covariate_id,
	COUNT(vo1.visit_occurrence_id) AS covariate_value
  INTO #cov_dd_visit_all
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.visit_occurrence vo1
	ON cp1.subject_id = vo1.person_id
WHERE vo1.visit_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND vo1.visit_start_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1004,
	'Number of visits observed in long_term_days on or prior to cohort index',
	1004,
	0
	);


--Number of inpatient visits observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1005 AS covariate_id,
	COUNT(vo1.visit_occurrence_id) AS covariate_value
  INTO #cov_dd_visit_inpt
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.visit_occurrence vo1
	ON cp1.subject_id = vo1.person_id
WHERE vo1.visit_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND vo1.visit_start_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
{@cdm_version == '4'} ? {
	AND vo1.place_of_service_concept_id = 9201
} : {
	AND vo1.visit_concept_id = 9201
}
GROUP BY cp1.@row_id_field;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1005,
	'Number of inpatient visits observed in long_term_days on or prior to cohort index',
	1005,
	0
	);


--Number of ER visits observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1006 AS covariate_id,
	COUNT(vo1.visit_occurrence_id) AS covariate_value
INTO #cov_dd_visit_er
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.visit_occurrence vo1
	ON cp1.subject_id = vo1.person_id
WHERE vo1.visit_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND vo1.visit_start_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
{@cdm_version == '4'} ? {
	AND vo1.place_of_service_concept_id = 9203
} : {
	AND vo1.visit_concept_id = 9203
}
GROUP BY cp1.@row_id_field;


INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1006,
	'Number of ER visits observed in long_term_days on or prior to cohort index',
	1006,
	0
	);

{@cdm_version != '4'} ? {
--Number of distinct measurements observed in long_term_days on or prior to cohort index
SELECT cp1.@row_id_field AS row_id,
	1007 AS covariate_id,
	COUNT(DISTINCT o1.measurement_concept_id) AS covariate_value
  INTO #cov_dd_meas
FROM @cohort_temp_table cp1
INNER JOIN @cdm_database_schema.measurement o1
	ON cp1.subject_id = o1.person_id
WHERE o1.measurement_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	AND o1.measurement_date >= DATEADD(DAY, - @long_term_days, cp1.cohort_start_date)
GROUP BY cp1.@row_id_field;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1007,
	'Number of distinct measurements observed in long_term_days on or prior to cohort index',
	1007,
	0
	);
}
}


/**************************
***************************
RISK SCORES
***************************
**************************/
{@use_covariate_risk_scores} ? {

{@use_covariate_risk_scores_Charlson} ? {
--CHARLSON

IF OBJECT_ID('tempdb..#Charlson_concepts', 'U') IS NOT NULL
  DROP TABLE #Charlson_concepts;

CREATE TABLE #Charlson_concepts (
	diag_category_id INT,
	concept_id INT
	);

IF OBJECT_ID('tempdb..#Charlson_scoring', 'U') IS NOT NULL
	DROP TABLE #Charlson_scoring;

CREATE TABLE #Charlson_scoring (
	diag_category_id INT,
	diag_category_name VARCHAR(255),
	weight INT
	);

--acute myocardial infarction
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (1,'Myocardial infarction',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 1, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4329847)
;

--Congestive heart failure
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (2,'Congestive heart failure',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 2, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (316139)
;


--Peripheral vascular disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (3,'Peripheral vascular disease',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 3, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (321052)
;

--Cerebrovascular disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (4,'Cerebrovascular disease',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 4, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (381591, 434056)
;

--Dementia
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (5,'Dementia',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 5, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (4182210)
;

--Chronic pulmonary disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (6,'Chronic pulmonary disease',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 6, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (4063381)
;

--Rheumatologic disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (7,'Rheumatologic disease',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 7, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (257628, 134442, 80800, 80809, 256197, 255348)
;

--Peptic ulcer disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (8,'Peptic ulcer disease',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 8, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (4247120)
;

--Mild liver disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (9,'Mild liver disease',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 9, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (4064161, 4212540)
;

--Diabetes (mild to moderate)
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (10,'Diabetes (mild to moderate)',1);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 10, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (201820)
;

--Diabetes with chronic complications
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (11,'Diabetes with chronic complications',2);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 11, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (4192279, 443767, 442793)
;

--Hemoplegia or paralegia
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (12,'Hemoplegia or paralegia',2);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 12, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (192606, 374022)
;

--Renal disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (13,'Renal disease',2);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 13, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (4030518)
;

--Any malignancy
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (14,'Any malignancy',2);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 14, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (443392)
;

--Moderate to severe liver disease
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (15,'Moderate to severe liver disease',3);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 15, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (4245975, 4029488, 192680, 24966)
;

--Metastatic solid tumor
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (16,'Metastatic solid tumor',6);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 16, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (432851)
;

--AIDS
INSERT INTO #Charlson_scoring (diag_category_id,diag_category_name,weight)
VALUES (17,'AIDS',6);

INSERT INTO #Charlson_concepts (diag_category_id,concept_id)
SELECT 17, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (439727)
;

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1100,
	'Charlson Index - Romano adaptation, using conditions all time on or prior to cohort index',
	1100,
	0
	);


SELECT row_id,
	1100 AS covariate_id,
	SUM(weight) AS covariate_value
INTO #cov_charlson
FROM (
	SELECT DISTINCT cp1.@row_id_field AS row_id,
		cs1.diag_category_id,
		cs1.weight
	FROM @cohort_temp_table cp1
	INNER JOIN @cdm_database_schema.condition_era ce1
		ON cp1.subject_id = ce1.person_id
	INNER JOIN #Charlson_concepts c1
		ON ce1.condition_concept_id = c1.concept_id
	INNER JOIN #Charlson_scoring cs1
		ON c1.diag_category_id = cs1.diag_category_id
	WHERE ce1.condition_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	) t1
GROUP BY row_id;

TRUNCATE TABLE #Charlson_concepts;

DROP TABLE #Charlson_concepts;

TRUNCATE TABLE #Charlson_scoring;

DROP TABLE #Charlson_scoring;
}

{@use_covariate_risk_scores_DCSI} ? {

--DCSI

IF OBJECT_ID('tempdb..#DCSI_scoring', 'U') IS NOT NULL
	DROP TABLE #DCSI_scoring;

CREATE TABLE #DCSI_scoring (
	DCSI_category VARCHAR(255),
	DCSI_ICD9_code VARCHAR(255),
	DCSI_concept_id INT,
	DCSI_score INT
	);

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Retinopathy' AS DCSI_category,
	source_code,
	target_concept_id,
	1 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id = 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE source_code LIKE '250.5%'
		OR source_code IN ('362.01', '362.1', '362.83', '362.53', '362.81', '362.82');

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Retinopathy' AS DCSI_category,
	source_code,
	target_concept_id,
	2 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE
	source_code LIKE '361%'
	OR source_code LIKE '369%'
	OR source_code IN ('362.02', '379.23');

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Nephropathy' AS DCSI_category,
	source_code,
	target_concept_id,
	1 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE
		source_code IN ('250.4', '580', '581', '581.81', '582', '583')
		OR source_code LIKE '580%'
		OR source_code LIKE '581%'
		OR source_code LIKE '582%'
		OR source_code LIKE '583%';

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Nephropathy' AS DCSI_category,
	source_code,
	target_concept_id,
	2 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE
		source_code IN ('585', '586', '593.9')
		OR source_code LIKE '585%'
		OR source_code LIKE '586%'
		OR source_code LIKE '593.9%';

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Neuropathy' AS DCSI_category,
	source_code,
	target_concept_id,
	1 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE
		source_code IN ('356.9', '250.6', '358.1', '951.0', '951.1', '951.3', '713.5', '357.2', '596.54', '337.0', '337.1', '564.5', '536.3', '458.0')
		OR (
			source_code >= '354.0'
			AND source_code <= '355.99'
			)
		OR source_code LIKE '356.9%'
		OR source_code LIKE '250.6%'
		OR source_code LIKE '358.1%'
		OR source_code LIKE '951.0%'
		OR source_code LIKE '951.1%'
		OR source_code LIKE '951.3%'
		OR source_code LIKE '713.5%'
		OR source_code LIKE '357.2%'
		OR source_code LIKE '337.0%'
		OR source_code LIKE '337.1%'
		OR source_code LIKE '564.5%'
		OR source_code LIKE '536.3%'
		OR source_code LIKE '458.0%';

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Cerebrovascular' AS DCSI_category,
	source_code,
	target_concept_id,
	1 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE source_code LIKE '435%';

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Cerebrovascular' AS DCSI_category,
	source_code,
	target_concept_id,
	2 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE   source_code IN ('431', '433', '434', '436')
		OR source_code LIKE '431%'
		OR source_code LIKE '433%'
		OR source_code LIKE '434%'
		OR source_code LIKE '436%';

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Cardiovascular' AS DCSI_category,
	source_code,
	target_concept_id,
	1 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE
		source_code LIKE '440%'
		OR source_code LIKE '411%'
		OR source_code LIKE '413%'
		OR source_code LIKE '414%'
		OR source_code LIKE '429.2%';

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Cardiovascular' AS DCSI_category,
	source_code,
	target_concept_id,
	2 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE   source_code LIKE '410%'
		OR source_code LIKE '427.1%'
		OR source_code LIKE '427.3%'
		OR source_code LIKE '427.4%'
		OR source_code LIKE '427.5%'
		OR source_code LIKE '412%'
		OR source_code LIKE '428%'
		OR source_code LIKE '441%'
		OR source_code IN ('440.23', '440.24');

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Peripheral vascular disease' AS DCSI_category,
	source_code,
	target_concept_id,
	1 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE
		source_code LIKE '250.7%'
		OR source_code LIKE '442.3%'
		OR source_code LIKE '892.1%'
		OR source_code LIKE '443.9%'
		OR source_code IN ('443.81');

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Peripheral vascular disease' AS DCSI_category,
	source_code,
	target_concept_id,
	2 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE   source_code LIKE '785.4%'
		OR source_code LIKE '707.1%'
		OR source_code LIKE '040.0%'
		OR source_code IN ('444.22');

INSERT INTO #DCSI_scoring (
	DCSI_category,
	DCSI_ICD9_code,
	DCSI_concept_id,
	DCSI_score
	)
SELECT 'Metabolic' AS DCSI_category,
	source_code,
	target_concept_id,
	2 AS DCSI_score
FROM (
{@cdm_version == '4'} ? {
	SELECT source_code, target_concept_id
	FROM @cdm_database_schema.SOURCE_TO_CONCEPT_MAP
	WHERE source_vocabulary_id= 2
	AND target_vocabulary_id = 1
} : {
	SELECT
	  source.concept_code AS source_code,
	  target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
	ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
	ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id )= 'icd9cm'
	  AND LOWER(target.vocabulary_id) = 'snomed'
	  AND LOWER(relationship_id) = 'maps to'
}
) source_to_concept_map
WHERE   source_code LIKE '250.1%'
		OR source_code LIKE '250.2%'
		OR source_code LIKE '250.3%';

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1101,
	'Diabetes Comorbidity Severity Index (DCSI), using conditions all time on or prior to cohort index',
	1101,
	0
	);


SELECT row_id,
	1101 AS covariate_id,
	SUM(max_score) AS covariate_value
INTO #cov_DCSI
FROM (
	SELECT cp1.@row_id_field AS row_id,
		ds1.dcsi_category,
		max(ds1.DCSI_score) AS max_score
	FROM @cohort_temp_table cp1
	INNER JOIN @cdm_database_schema.condition_era ce1
		ON cp1.subject_id = ce1.person_id
	INNER JOIN #DCSI_scoring ds1
		ON ce1.condition_concept_id = ds1.DCSI_concept_id
	WHERE ce1.condition_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)
	GROUP BY cp1.@row_id_field,
		ds1.dcsi_category
	) t1
GROUP BY row_id;

TRUNCATE TABLE #DCSI_scoring;

DROP TABLE #DCSI_scoring;
}

{@use_covariate_risk_scores_CHADS2} ? {

IF OBJECT_ID('tempdb..#CHADS2_concepts', 'U') IS NOT NULL
  DROP TABLE #CHADS2_concepts;

CREATE TABLE #CHADS2_concepts (
	diag_category_id INT,
	concept_id INT
	);

IF OBJECT_ID('tempdb..#CHADS2_scoring', 'U') IS NOT NULL
	DROP TABLE #CHADS2_scoring;

CREATE TABLE #CHADS2_scoring (
	diag_category_id INT,
	diag_category_name VARCHAR(255),
	weight INT
	);

--Congestive heart failure
INSERT INTO #CHADS2_scoring (diag_category_id,diag_category_name,weight)
VALUES (1,'Congestive heart failure',1);

INSERT INTO #CHADS2_concepts (diag_category_id,concept_id)
SELECT 1, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (316139)
;

--Hypertension
INSERT INTO #CHADS2_scoring (diag_category_id,diag_category_name,weight)
VALUES (2,'Hypertension',1);

INSERT INTO #CHADS2_concepts (diag_category_id,concept_id)
SELECT 2, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (316866)
;

--Age > 75
INSERT INTO #CHADS2_scoring (diag_category_id,diag_category_name,weight)
VALUES (3,'Age>75',1);

--no codes

--Diabetes
INSERT INTO #CHADS2_scoring (diag_category_id,diag_category_name,weight)
VALUES (4,'Diabetes',1);

INSERT INTO #CHADS2_concepts (diag_category_id,concept_id)
SELECT 4, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (201820)
;

--Stroke
INSERT INTO #CHADS2_scoring (diag_category_id,diag_category_name,weight)
VALUES (5,'Stroke',2);

INSERT INTO #CHADS2_concepts (diag_category_id,concept_id)
SELECT 5, descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id in (381591, 434056)
;

INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1102,
	'CHADS2, using conditions all time on or prior to cohort index',
	1102,
	0
	);


SELECT row_id,
	1102 AS covariate_id,
	SUM(weight) AS covariate_value
  INTO #cov_CHADS2
FROM (
	SELECT DISTINCT cp1.@row_id_field AS row_id,
		cs1.diag_category_id,
		cs1.weight
	FROM @cohort_temp_table cp1
	INNER JOIN @cdm_database_schema.condition_era ce1
		ON cp1.subject_id = ce1.person_id
	INNER JOIN #CHADS2_concepts c1
		ON ce1.condition_concept_id = c1.concept_id
	INNER JOIN #CHADS2_scoring cs1
		ON c1.diag_category_id = cs1.diag_category_id
	WHERE ce1.condition_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)

  UNION

  SELECT DISTINCT cp1.@row_id_field AS row_id,
		3 as diag_category_id,
		1 as weight
	FROM @cohort_temp_table cp1
  INNER JOIN @cdm_database_schema.person p1
  ON cp1.subject_id = p1.person_id
  WHERE year(cp1.cohort_start_date) - p1.year_of_birth >= 75

	) t1
GROUP BY row_id;

TRUNCATE TABLE #CHADS2_concepts;

DROP TABLE #CHADS2_concepts;

TRUNCATE TABLE #CHADS2_scoring;

DROP TABLE #CHADS2_scoring;
}

{@use_covariate_risk_scores_CHADS2VASc} ? {

IF OBJECT_ID('tempdb..#CHADS2VASc_concepts', 'U') IS NOT NULL
  DROP TABLE #CHADS2VASc_concepts;

CREATE TABLE #CHADS2VASc_concepts (
  diag_category_id INT,
	concept_id INT
	);

IF OBJECT_ID('tempdb..#CHADS2VASc_scoring', 'U') IS NOT NULL
	DROP TABLE #CHADS2VASc_scoring;

CREATE TABLE #CHADS2VASc_scoring (
	diag_category_id INT,
	diag_category_name VARCHAR(255),
	weight INT
	);

-- C: Congestive heart failure
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (1,'Congestive heart failure',1);

INSERT INTO #CHADS2VASc_concepts (diag_category_id,concept_id)
SELECT 1, c.concept_id
FROM (
  select distinct I.concept_id FROM
  (
    select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (316139,314378,318773,321319) and invalid_reason is null
    UNION
    select c.concept_id
    from @cdm_database_schema.CONCEPT c
    join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (316139,314378)
    and c.invalid_reason is null

  ) I
) C
;

-- H: Hypertension
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (2,'Hypertension',1);

INSERT INTO #CHADS2VASc_concepts (diag_category_id,concept_id)
SELECT 2, c.concept_id
FROM
(
  select distinct I.concept_id FROM
  (
    select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (320128,442604,201313) and invalid_reason is null
      UNION

    select c.concept_id
    from @cdm_database_schema.CONCEPT c
    join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (320128,442604,201313)
    and c.invalid_reason is null

  ) I
  LEFT JOIN
  (
    select concept_id from @cdm_database_schema.CONCEPT where concept_id in (197930)and invalid_reason is null
      UNION

    select c.concept_id
    from @cdm_database_schema.CONCEPT c
    join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (197930)
    and c.invalid_reason is null

  ) E ON I.concept_id = E.concept_id
  WHERE E.concept_id is null
) C
;

-- A2: Age > 75
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (3,'Age>75',2);

--no codes

-- D: Diabetes
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (4,'Diabetes',1);

INSERT INTO #CHADS2VASc_concepts (diag_category_id,concept_id)
SELECT 4, c.concept_id
FROM
(
  select distinct I.concept_id FROM
  (
    select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (201820,442793) and invalid_reason is null
      UNION

    select c.concept_id
    from @cdm_database_schema.CONCEPT c
    join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (201820,442793)
    and c.invalid_reason is null

  ) I
  LEFT JOIN
  (
    select concept_id from @cdm_database_schema.CONCEPT where concept_id in (195771,376112,4174977,4058243,193323,376979)and invalid_reason is null
    UNION

    select c.concept_id
    from @cdm_database_schema.CONCEPT c
    join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (195771,376112,4174977,4058243,193323,376979)
    and c.invalid_reason is null

  ) E ON I.concept_id = E.concept_id
  WHERE E.concept_id is null
) C
;

-- S2: Stroke
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (5,'Stroke',2);

INSERT INTO #CHADS2VASc_concepts (diag_category_id,concept_id)
SELECT 5, c.concept_id
FROM
(
  select distinct I.concept_id FROM
  (
    select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (4043731,4110192,375557,4108356,373503,434656,433505,376714,312337) and invalid_reason is null
      UNION

    select c.concept_id
    from @cdm_database_schema.CONCEPT c
    join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (4043731,4110192,375557,4108356,373503,434656,433505,376714,312337)
    and c.invalid_reason is null

  ) I
) C
;

-- V: Vascular disease (e.g. peripheral artery disease, myocardial infarction, aortic plaque)
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (6,'Vascular Disease', 1);

INSERT INTO #CHADS2VASc_concepts (diag_category_id,concept_id)
SELECT 6, c.concept_id FROM
(
  select distinct I.concept_id
  FROM
  (
    select DISTINCT concept_id from @cdm_database_schema.CONCEPT where concept_id in (312327,43020432,314962,312939,315288,317309,134380,196438,200138,194393,319047,40486130,317003,4313767,321596,317305,321886,314659,321887,437312,134057) and invalid_reason is null

    UNION

    select c.concept_id
    from @cdm_database_schema.CONCEPT c
    join @cdm_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
    and ca.ancestor_concept_id in (312327,43020432,314962,312939,315288,317309,134380,196438,200138,194393,319047,40486130,317003,4313767,321596)
    and c.invalid_reason is null

  ) I
) C
;

-- A: Age 65–74 years
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (7,'Age 65-74 Years', 1);

-- Sc: Sex category (i.e. female sex)
INSERT INTO #CHADS2VASc_scoring (diag_category_id,diag_category_name,weight)
VALUES (8,'Sex Category', 1);


INSERT INTO #cov_ref (
  covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
VALUES (
	1103,
	'CHADS2VASc, using conditions all time on or prior to cohort index',
	1103,
	0
	);


SELECT row_id,
	1103 AS covariate_id,
	SUM(weight) AS covariate_value
  INTO #cov_CHADS2VASc
FROM (
	SELECT DISTINCT cp1.@row_id_field AS row_id,
		cs1.diag_category_id,
		cs1.weight
	FROM @cohort_temp_table cp1
	INNER JOIN @cdm_database_schema.condition_era ce1
		ON cp1.subject_id = ce1.person_id
	INNER JOIN #CHADS2VASc_concepts c1
		ON ce1.condition_concept_id = c1.concept_id
	INNER JOIN #CHADS2VASc_scoring cs1
		ON c1.diag_category_id = cs1.diag_category_id
	WHERE ce1.condition_era_start_date <= DATEADD(DAY, - @window_end_days, cp1.cohort_start_date)

  UNION

  SELECT DISTINCT cp1.@row_id_field AS row_id,
		3 as diag_category_id,
		2 as weight
	FROM @cohort_temp_table cp1
  INNER JOIN @cdm_database_schema.person p1
    ON cp1.subject_id = p1.person_id
  WHERE year(cp1.cohort_start_date) - p1.year_of_birth >= 75

  UNION

  SELECT DISTINCT cp1.@row_id_field AS row_id,
		7 as diag_category_id,
		1 as weight
	FROM @cohort_temp_table cp1
  INNER JOIN @cdm_database_schema.person p1
    ON cp1.subject_id = p1.person_id
  WHERE year(cp1.cohort_start_date) - p1.year_of_birth between 65 and 74

  UNION

  SELECT DISTINCT cp1.@row_id_field AS row_id,
		8 as diag_category_id,
		1 as weight
  FROM @cohort_temp_table cp1
  INNER JOIN @cdm_database_schema.person p1
    ON cp1.subject_id = p1.person_id
  WHERE p1.gender_concept_id = 8532
) t1
GROUP BY row_id;

TRUNCATE TABLE #CHADS2VASc_concepts;

DROP TABLE #CHADS2VASc_concepts;

TRUNCATE TABLE #CHADS2VASc_scoring;

DROP TABLE #CHADS2VASc_scoring;
}

/*************

other risk scores to consider adding:

HAS_BLED

**************/
}



/***********************************

put all temp tables together into one cov table

***********************************/


SELECT row_id, covariate_id, covariate_value
INTO #cov_all
FROM
(

SELECT row_id, covariate_id, covariate_value FROM #dummy

{@use_covariate_demographics} ? {

{@use_covariate_demographics_gender} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_gender

}

{@use_covariate_demographics_race} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_race

}

{@use_covariate_demographics_ethnicity} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_ethnicity

}

{@use_covariate_demographics_age} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_age

}

{@use_covariate_demographics_year} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_year

}

{@use_covariate_demographics_month} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_month

}
}

{@use_covariate_condition_occurrence} ? {

{@use_covariate_condition_occurrence_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_co_long_term

}

{@use_covariate_condition_occurrence_short_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_co_short_term

}

{@use_covariate_condition_occurrence_inpt_medium_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_co_inpt_med

}

}


{@use_covariate_condition_era} ? {

{@use_covariate_condition_era_ever} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_ce_ever

}

{@use_covariate_condition_era_overlap} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_ce_overlap

}

}

{@use_covariate_condition_group} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_cg

}


{@use_covariate_drug_exposure} ? {

{@use_covariate_drug_exposure_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_de_long_term

}

{@use_covariate_drug_exposure_short_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_de_short_term

}

}


{@use_covariate_drug_era} ? {

{@use_covariate_drug_era_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_long_term

}

{@use_covariate_drug_era_short_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_short_term

}

{@use_covariate_drug_era_ever} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_ever

}

{@use_covariate_drug_era_overlap} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dera_overlap

}

}

{@use_covariate_drug_group} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dg


{@use_covariate_drug_era_ever} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dg_count
}

}


{@use_covariate_procedure_occurrence} ? {

{@use_covariate_procedure_occurrence_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_po_long_term

}

{@use_covariate_procedure_occurrence_short_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_po_short_term

}

}

{@use_covariate_procedure_group} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_pg

}

{@use_covariate_observation} ? {

{@use_covariate_observation_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_o_long_term

}

{@use_covariate_observation_short_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_o_short_term

}

{@use_covariate_observation_count_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_o_cnt_long_term

}

}

{(@cdm_version == '4' & @use_covariate_observation) | @use_covariate_measurement} ? {
{@use_covariate_measurement_below} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_m_below

}


{@use_covariate_measurement_above} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_m_above

}
}

{@cdm_version != '4' & @use_covariate_measurement} ? {

{@use_covariate_measurement_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_m_long_term

}

{@use_covariate_measurement_short_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_m_short_term

}

{@use_covariate_measurement_count_long_term} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_m_cnt_long_term

}

}

  {@use_covariate_concept_counts} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_cond

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_drug

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_proc

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_obs

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_visit_all

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_visit_inpt

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_visit_er

{@cdm_version != '4'} ? {
UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_dd_meas
}

}

{@use_covariate_risk_scores} ? {

{@use_covariate_risk_scores_Charlson} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_charlson

}

{@use_covariate_risk_scores_DCSI} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_DCSI

}

{@use_covariate_risk_scores_CHADS2} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_CHADS2

}

{@use_covariate_risk_scores_CHADS2VASc} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_CHADS2VASc

}

}

) all_covariates
;


/**************************
***************************
INTERACTION YEAR
***************************
**************************/
{@use_covariate_interaction_year} ? {

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT DISTINCT CAST(ccr1.covariate_id AS BIGINT) * 10000 + YEAR(cp1.cohort_start_date) AS covariate_id,
	CONCAT(ccr1.covariate_name, ' * interaction term with index year: ', CAST(YEAR(cp1.cohort_start_date) AS VARCHAR)) AS covariate_name,
	ccr1.analysis_id,
	ccr1.concept_id
FROM @cohort_temp_table cp1
INNER JOIN
  #cov_all  cc1
	ON cp1.@row_id_field = cc1.row_id
INNER JOIN #cov_ref ccr1
	ON cc1.covariate_id = ccr1.covariate_id
WHERE ccr1.analysis_id NOT IN (5)
	AND ccr1.covariate_id > 1;


SELECT DISTINCT cc1.row_id,
	CAST(cc1.covariate_id AS BIGINT) * 10000 + CAST(YEAR(cp1.cohort_start_date) AS BIGINT) AS covariate_id,
	cc1.covariate_value AS covariate_value
    INTO #cov_int_year
FROM @cohort_temp_table cp1
INNER JOIN #cov_all cc1
	ON cp1.@row_id_field = cc1.row_id
INNER JOIN #cov_ref ccr1
	ON cc1.covariate_id = ccr1.covariate_id
WHERE ccr1.analysis_id NOT IN (5)
	AND ccr1.covariate_id > 1;
}


/**************************
***************************
INTERACTION MONTH
***************************
**************************/
{@use_covariate_interaction_month} ? {

INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT DISTINCT CAST(ccr1.covariate_id AS BIGINT) * 10000 + CAST(MONTH(cp1.cohort_start_date) AS BIGINT) AS covariate_id,
	CONCAT(ccr1.covariate_name, ' * interaction term with index month: ', CAST(MONTH(cp1.cohort_start_date) AS VARCHAR)) AS covariate_name,
	ccr1.analysis_id,
	ccr1.concept_id
FROM @cohort_temp_table cp1
INNER JOIN #cov_all cc1
	ON cp1.@row_id_field = cc1.row_id
INNER JOIN #cov_ref ccr1
	ON cc1.covariate_id = ccr1.covariate_id
WHERE ccr1.analysis_id NOT IN (6)
	AND ccr1.covariate_id > 1;

SELECT DISTINCT cc1.row_id,
	CAST(cc1.covariate_id AS BIGINT) * 10000 + CAST(MONTH(cp1.cohort_start_date) AS BIGINT) AS covariate_id,
	cc1.covariate_value AS covariate_value
    INTO #cov_int_month
FROM @cohort_temp_table cp1
INNER JOIN #cov_all cc1
	ON cp1.@row_id_field = cc1.row_id
INNER JOIN #cov_ref ccr1
	ON cc1.covariate_id = ccr1.covariate_id
WHERE ccr1.analysis_id NOT IN (6)
	AND ccr1.covariate_id > 1;
}

{@delete_covariates_small_count != 0 } ? {

DELETE
FROM #cov_ref
WHERE covariate_id IN (
  	SELECT covariate_id
		FROM #cov_all
		GROUP BY covariate_id
		HAVING COUNT(row_id) <= @delete_covariates_small_count

{@use_covariate_interaction_year} ? {

UNION

SELECT covariate_id
    FROM #cov_int_year
		GROUP BY covariate_id
		HAVING COUNT(row_id) <= @delete_covariates_small_count

}

{@use_covariate_interaction_month} ? {

UNION

SELECT covariate_id
  	FROM #cov_int_month
		GROUP BY covariate_id
		HAVING COUNT(row_id) <= @delete_covariates_small_count

}
);
}

SELECT row_id, covariate_id, covariate_value
  INTO #cov
FROM (
	SELECT row_id, covariate_id, covariate_value
	FROM #cov_all
	WHERE covariate_id IN (
		SELECT covariate_id
			FROM #cov_ref
		)

{@use_covariate_interaction_year} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_int_year
WHERE covariate_id IN (
    SELECT covariate_id
		FROM #cov_ref
		)
}

{@use_covariate_interaction_month} ? {

UNION

SELECT row_id, covariate_id, covariate_value
FROM #cov_int_month
WHERE covariate_id IN (
    SELECT covariate_id
  	FROM #cov_ref
		)
}

) t1
;


IF OBJECT_ID('tempdb..#cov_gender', 'U') IS NOT NULL
  DROP TABLE #cov_gender;
IF OBJECT_ID('tempdb..#cov_race', 'U') IS NOT NULL
  DROP TABLE #cov_race;
IF OBJECT_ID('tempdb..#cov_ethnicity', 'U') IS NOT NULL
  DROP TABLE #cov_ethnicity;
IF OBJECT_ID('tempdb..#cov_age', 'U') IS NOT NULL
  DROP TABLE #cov_age;
IF OBJECT_ID('tempdb..#cov_year', 'U') IS NOT NULL
  DROP TABLE #cov_year;
IF OBJECT_ID('tempdb..#cov_month', 'U') IS NOT NULL
  DROP TABLE #cov_month;
IF OBJECT_ID('tempdb..#cov_co_long_term', 'U') IS NOT NULL
  DROP TABLE #cov_co_long_term;
IF OBJECT_ID('tempdb..#cov_co_short_term', 'U') IS NOT NULL
  DROP TABLE #cov_co_short_term;
IF OBJECT_ID('tempdb..#cov_co_inpt_med', 'U') IS NOT NULL
  DROP TABLE #cov_co_inpt_med;
IF OBJECT_ID('tempdb..#cov_ce_ever', 'U') IS NOT NULL
  DROP TABLE #cov_ce_ever;
IF OBJECT_ID('tempdb..#cov_ce_overlap', 'U') IS NOT NULL
  DROP TABLE #cov_ce_overlap;
IF OBJECT_ID('tempdb..#cov_cg', 'U') IS NOT NULL
  DROP TABLE #cov_cg;
IF OBJECT_ID('tempdb..#cov_de_long_term', 'U') IS NOT NULL
  DROP TABLE #cov_de_long_term;
IF OBJECT_ID('tempdb..#cov_de_short_term', 'U') IS NOT NULL
  DROP TABLE #cov_de_short_term;
IF OBJECT_ID('tempdb..#cov_dera_long_term', 'U') IS NOT NULL
  DROP TABLE #cov_dera_long_term;
IF OBJECT_ID('tempdb..#cov_dera_short_term', 'U') IS NOT NULL
  DROP TABLE #cov_dera_short_term;
IF OBJECT_ID('tempdb..#cov_dera_ever', 'U') IS NOT NULL
  DROP TABLE #cov_dera_ever;
IF OBJECT_ID('tempdb..#cov_dera_overlap', 'U') IS NOT NULL
  DROP TABLE #cov_dera_overlap;
IF OBJECT_ID('tempdb..#cov_dg', 'U') IS NOT NULL
  DROP TABLE #cov_dg;
IF OBJECT_ID('tempdb..#cov_dg_count', 'U') IS NOT NULL
  DROP TABLE #cov_dg_count;
IF OBJECT_ID('tempdb..#cov_po_long_term', 'U') IS NOT NULL
  DROP TABLE #cov_po_long_term;
IF OBJECT_ID('tempdb..#cov_po_short_term', 'U') IS NOT NULL
  DROP TABLE #cov_po_short_term;
IF OBJECT_ID('tempdb..#cov_pg', 'U') IS NOT NULL
  DROP TABLE #cov_pg;
IF OBJECT_ID('tempdb..#cov_o_long_term', 'U') IS NOT NULL
  DROP TABLE #cov_o_long_term;
IF OBJECT_ID('tempdb..#cov_o_short_term', 'U') IS NOT NULL
  DROP TABLE #cov_o_short_term;
IF OBJECT_ID('tempdb..#cov_m_below', 'U') IS NOT NULL
  DROP TABLE #cov_m_below;
IF OBJECT_ID('tempdb..#cov_m_above', 'U') IS NOT NULL
  DROP TABLE #cov_m_above;
IF OBJECT_ID('tempdb..#cov_m_cnt_long_term', 'U') IS NOT NULL
  DROP TABLE #cov_m_cnt_long_term;  
IF OBJECT_ID('tempdb..#cov_o_cnt_long_term', 'U') IS NOT NULL
  DROP TABLE #cov_o_cnt_long_term;
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
IF OBJECT_ID('tempdb..#cov_Charlson', 'U') IS NOT NULL
  DROP TABLE #cov_Charlson;
IF OBJECT_ID('tempdb..#cov_DCSI', 'U') IS NOT NULL
  DROP TABLE #cov_DCSI;
IF OBJECT_ID('tempdb..#cov_CHADS2', 'U') IS NOT NULL
  DROP TABLE #cov_CHADS2;
IF OBJECT_ID('tempdb..#cov_CHADS2VASc', 'U') IS NOT NULL
  DROP TABLE #cov_CHADS2VASc;

IF OBJECT_ID('tempdb..#cov_int_year', 'U') IS NOT NULL
  DROP TABLE #cov_int_year;
IF OBJECT_ID('tempdb..#cov_int_month', 'U') IS NOT NULL
  DROP TABLE #cov_int_month;
IF OBJECT_ID('tempdb..#cov_all', 'U') IS NOT NULL
  DROP TABLE #cov_all;
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
