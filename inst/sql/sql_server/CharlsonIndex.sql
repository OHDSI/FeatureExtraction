IF OBJECT_ID('tempdb..#charlson_concepts', 'U') IS NOT NULL
	DROP TABLE #charlson_concepts;

CREATE TABLE #charlson_concepts (
	diag_category_id INT,
	concept_id INT
	);

IF OBJECT_ID('tempdb..#charlson_scoring', 'U') IS NOT NULL
	DROP TABLE #charlson_scoring;

CREATE TABLE #charlson_scoring (
	diag_category_id INT,
	diag_category_name VARCHAR(255),
	weight INT
	);

--acute myocardial infarction
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	1,
	'Myocardial infarction',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 1,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4329847);

--Congestive heart failure
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	2,
	'Congestive heart failure',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 2,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (316139);

--Peripheral vascular disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	3,
	'Peripheral vascular disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 3,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (321052);

--Cerebrovascular disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	4,
	'Cerebrovascular disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 4,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (381591, 434056);

--Dementia
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	5,
	'Dementia',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 5,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4182210);

--Chronic pulmonary disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	6,
	'Chronic pulmonary disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 6,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4063381);

--Rheumatologic disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	7,
	'Rheumatologic disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 7,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (257628, 134442, 80800, 80809, 256197, 255348);

--Peptic ulcer disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	8,
	'Peptic ulcer disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 8,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4247120);

--Mild liver disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	9,
	'Mild liver disease',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 9,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4064161, 4212540);

--Diabetes (mild to moderate)
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	10,
	'Diabetes (mild to moderate)',
	1
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 10,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (201820);

--Diabetes with chronic complications
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	11,
	'Diabetes with chronic complications',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 11,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4192279, 443767, 442793);

--Hemoplegia or paralegia
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	12,
	'Hemoplegia or paralegia',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 12,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (192606, 374022);

--Renal disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	13,
	'Renal disease',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 13,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4030518);

--Any malignancy
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	14,
	'Any malignancy',
	2
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 14,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (443392);

--Moderate to severe liver disease
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	15,
	'Moderate to severe liver disease',
	3
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 15,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4245975, 4029488, 192680, 24966);

--Metastatic solid tumor
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	16,
	'Metastatic solid tumor',
	6
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 16,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (432851);

--AIDS
INSERT INTO #charlson_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	17,
	'AIDS',
	6
	);

INSERT INTO #charlson_concepts (
	diag_category_id,
	concept_id
	)
SELECT 17,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (439727);

-- Feature construction
{!@aggregated} ? {--HINT DISTRIBUTE_ON_KEY(row_id)}
SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    NULL AS time_id,
}	
{@aggregated} ? {
	SUM(weight) AS covariate_value
} : {
	row_id,
	SUM(weight) AS covariate_value 
}
INTO @covariate_table
FROM (
	SELECT DISTINCT cohort.@row_id_field AS row_id,
		charlson_scoring.diag_category_id,
		charlson_scoring.weight
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.condition_era condition_era
		ON cohort.subject_id = condition_era.person_id
	INNER JOIN #charlson_concepts charlson_concepts
		ON condition_era.condition_concept_id = charlson_concepts.concept_id
	INNER JOIN #charlson_scoring charlson_scoring
		ON charlson_concepts.diag_category_id = charlson_scoring.diag_category_id
{@temporal} ? {		
	WHERE condition_era_start_date <= cohort.cohort_start_date
} : {
	WHERE condition_era_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
) temp
{@has_excluded_covariate_concept_ids} ? {}
{@has_included_covariate_concept_ids} ? {}
{@has_included_covariate_ids} ? {WHERE 1000 + @analysis_id IN (SELECT concept_id FROM #included_cov_by_id)}
{!@aggregated} ? {
GROUP BY row_id
}
;

TRUNCATE TABLE #charlson_concepts;

DROP TABLE #charlson_concepts;

TRUNCATE TABLE #charlson_scoring;

DROP TABLE #charlson_scoring;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	'Charlson index - Romano adaptation' AS covariate_name,
	@analysis_id AS analysis_id,
	0 AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1;