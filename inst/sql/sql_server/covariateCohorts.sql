/************************
File covariateCohorts.sql
*************************/
DROP TABLE IF EXISTS @cohort_database_schema.@cohort_table;

CREATE TABLE @cohort_database_schema.@cohort_table (
	cohort_definition_id INT,
	subject_id BIGINT,
	cohort_start_date DATE,
	cohort_end_date DATE
	);

INSERT INTO @cohort_database_schema.@cohort_table (
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT 1,
	person_id,
	MIN(drug_era_start_date),
	MIN(drug_era_end_date)
FROM @cdm_database_schema.drug_era
WHERE drug_concept_id = 1124300 --diclofenac
GROUP BY person_id;

INSERT INTO @cohort_database_schema.@cohort_table (
	cohort_definition_id,
	subject_id,
	cohort_start_date,
	cohort_end_date
	)
SELECT 2,
	condition_occurrence.person_id,
	MIN(condition_start_date),
	MIN(observation_period_end_date)
FROM @cdm_database_schema.condition_occurrence
INNER JOIN @cdm_database_schema.drug_exposure
	ON condition_occurrence.person_id = drug_exposure.person_id
		AND drug_exposure_start_date >= condition_start_date
		AND drug_exposure_start_date < DATEADD(DAY, 30, condition_start_date)
INNER JOIN @cdm_database_schema.observation_period
	ON condition_occurrence.person_id = observation_period.person_id
		AND condition_start_date >= observation_period_start_date
		AND condition_start_date <= observation_period_end_date
WHERE condition_concept_id IN (
		SELECT descendant_concept_id
		FROM @cdm_database_schema.concept_ancestor
		WHERE ancestor_concept_id = 201826 -- Type 2 diabetes mellitus
		)
	AND drug_concept_id IN (
		SELECT descendant_concept_id
		FROM @cdm_database_schema.concept_ancestor
		WHERE ancestor_concept_id = 21600712 -- DRUGS USED IN DIABETES (ATC A10)
		)
GROUP BY condition_occurrence.person_id;
