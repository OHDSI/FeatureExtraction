IF OBJECT_ID('tempdb..#efi_concepts', 'U') IS NOT NULL
	DROP TABLE #efi_concepts;

CREATE TABLE #efi_concepts (
	diag_category_id INT,
	concept_id INT,
	min_levels_of_separation INT,
	domain_id VARCHAR(255)
	);

IF OBJECT_ID('tempdb..#efi_scoring', 'U') IS NOT NULL
	DROP TABLE #efi_scoring;

CREATE TABLE #efi_scoring (
	diag_category_id INT,
	diag_category_name VARCHAR(255),
	weight INT
	);

--Arthritis
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	1,	
	'Arthritis',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 1,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4291025);

--Atrial Fibrillation
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	2,	
	'Atrial Fibrillation',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 2,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (313217);

--Chronic Kidney Disease
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	3,	
	'Chronic Kidney Disease',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 3,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (46271022);

--Coronary Heart Disease
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	4,	
	'Coronary Heart Disease',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 4,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (317576);

--Diabetes
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	5,	
	'Diabetes',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 5,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (201826);

--Foot Problems
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	6,	
	'Foot problems',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 6,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4169905, 4182187);

--Fragility fracture
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	7,	
	'Fragility fracture',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 7,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (44791986);

--Heart Failure
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	8,	
	'Heart Failure',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 8,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (316139);

--Heart valve disease
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	9,	
	'Heart valve disease',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 9,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4281749);

--Hypertension
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	10,	
	'Hypertension',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 10,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (316866);

--Hypotension, syncope
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	11,	
	'Hypotension, syncope',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 11,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (443240, 4037508)
UNION
SELECT 11,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4151718)
;

--Osteoporosis
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	12,	
	'Osteoporosis',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 12,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (80502);

--Parkinson’s Disease
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	13,	
	'Parkinson’s Disease',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 13,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (381270);

--Peptic Ulcer
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	14,	
	'Peptic Ulcer',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 14,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4027663);

--Peripheral Vascular Disease
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	15,	
	'Peripheral Vascular Disease',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 15,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (321052);

--Respiratory Disease
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	16,	
	'Respiratory Disease',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 16,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (320136);

--Skin ulcer
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	17,	
	'Skin ulcer',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 17,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (135333)
UNION
SELECT 17,
	descendant_concept_id,
	min_levels_of_separation,
	'Procedure'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4080500)
;

--Stroke and TIA
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	18,	
	'Stroke and TIA',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 18,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (381316, 373503);

--Thyroid Disorders
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	19,	
	'Thyroid Disorders',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 19,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (141253);

--Urinary System Disease
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	20,	
	'Urinary system disease',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 20,
	descendant_concept_id,
	min_levels_of_separation,
	'Device'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4145656);

--Dizziness
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	21,	
	'Dizziness',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 21,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4012520);

--Dyspnoea
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	22,	
	'Dyspnoea',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 22,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (312437);

--Falls
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	23,	
	'Falls',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 23,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (436583);

--Memory and Cognitive Problems
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	24,	
	'Memory and Cognitive Problems',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 24,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (443432);

--Sleep Disturbance
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	26,	
	'Sleep Disturbance',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 26,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4158489, 436962, 4156060);

--Urinary Incontinence
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	27,
	'Urinary Incontinence',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 27,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (197672);

--Weight Loss and Anorexia
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	28,	
	'Weight Loss and Anorexia',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 28,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4275273, 40491502);

--Activity Limitation
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	29,	
	'Activity Limitation',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 29,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4058154);

--Hearing Loss
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	30,	
	'Hearing Loss',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 30,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4038030)
UNION
SELECT 30,
	descendant_concept_id,
	min_levels_of_separation,
	'Device'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4246497)
;

--Housebound
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	31,	
	'Housebound',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 31,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4052962);

--Mobility and Transfer problems
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	32,	
	'Mobility and Transfer problems',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 32,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4306934, 4052477, 4052468)
UNION
SELECT 32,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4012645)
;

--Requirement for Care
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	33,	
	'Requirement for Care',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 33,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4080054, 4052331, 44791364, 4081589, 4080053);

--Social Vulnerability
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	34,	
	'Social Vulnerability',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 34,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4309238, 4019835, 4307853, 4307117, 44791055, 4218604)
UNION
SELECT 34,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4022661, 4143188, 4053087, 36716273)
;

--Vision Problems, Blindness
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	35,	
	'Vision Problems, Blindness',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 35,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (44790784)
UNION
SELECT 35,
	descendant_concept_id,
	min_levels_of_separation,
	'Observation'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (4102251, 44791072, 4016895)
;

--Anaemia & Haematinic Deficiency
INSERT INTO #efi_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	36,	
	'Anaemia & Haematinic Deficiency',
	1
	);

INSERT INTO #efi_concepts (
	diag_category_id,
	concept_id,
 	min_levels_of_separation,
	domain_id
	)
SELECT 36,
	descendant_concept_id,
	min_levels_of_separation,
	'Condition'
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (439777);

-- Feature construction
{@aggregated} ? {
IF OBJECT_ID('tempdb..#efi_data', 'U') IS NOT NULL
	DROP TABLE #efi_data;

IF OBJECT_ID('tempdb..#efi_stats', 'U') IS NOT NULL
	DROP TABLE #efi_stats;

IF OBJECT_ID('tempdb..#efi_prep', 'U') IS NOT NULL
	DROP TABLE #efi_prep;

IF OBJECT_ID('tempdb..#efi_prep2', 'U') IS NOT NULL
	DROP TABLE #efi_prep2;

SELECT cohort_definition_id,
	@row_id_field,
	cohort_start_date,
	SUM(weight) AS score
INTO #efi_data
} : {
SELECT CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}	
	row_id,
	SUM(weight) AS covariate_value
INTO @covariate_table
}
FROM (
-- Condition
	SELECT DISTINCT efi_scoring.diag_category_id,
		efi_scoring.weight,
{@aggregated} ? {
		cohort_definition_id,
		cohort.@row_id_field,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.condition_era condition_era
		ON cohort.@row_id_field = condition_era.person_id
	INNER JOIN #efi_concepts efi_concepts
		ON condition_era.condition_concept_id = efi_concepts.concept_id
	INNER JOIN #efi_scoring efi_scoring
		ON efi_concepts.diag_category_id = efi_scoring.diag_category_id
{@temporal} ? {		
	WHERE condition_era_start_date <= cohort.cohort_start_date
} : {
	WHERE condition_era_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
AND efi_concepts.domain_id = 'Condition'
UNION
-- Observation
	SELECT DISTINCT efi_scoring.diag_category_id,
		efi_scoring.weight,
{@aggregated} ? {
		cohort_definition_id,
		cohort.@row_id_field,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.observation observation
		ON cohort.@row_id_field = observation.person_id
	INNER JOIN #efi_concepts efi_concepts
		ON observation.observation_concept_id = efi_concepts.concept_id
	INNER JOIN #efi_scoring efi_scoring
		ON efi_concepts.diag_category_id = efi_scoring.diag_category_id
{@temporal} ? {		
	WHERE observation_date <= cohort.cohort_start_date
} : {
	WHERE observation_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
AND efi_concepts.domain_id = 'Observation'
UNION
-- Procedure
	SELECT DISTINCT efi_scoring.diag_category_id,
		efi_scoring.weight,
{@aggregated} ? {
		cohort_definition_id,
		cohort.@row_id_field,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.procedure_occurrence procedure_occurrence
		ON cohort.@row_id_field = procedure_occurrence.person_id
	INNER JOIN #efi_concepts efi_concepts
		ON procedure_occurrence.procedure_concept_id = efi_concepts.concept_id
	INNER JOIN #efi_scoring efi_scoring
		ON efi_concepts.diag_category_id = efi_scoring.diag_category_id
{@temporal} ? {		
	WHERE procedure_date <= cohort.cohort_start_date
} : {
	WHERE procedure_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
AND efi_concepts.domain_id = 'Procedure'
UNION
-- Device
	SELECT DISTINCT efi_scoring.diag_category_id,
		efi_scoring.weight,
{@aggregated} ? {
		cohort_definition_id,
		cohort.@row_id_field,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.device_exposure device_exposure
		ON cohort.@row_id_field = device_exposure.person_id
	INNER JOIN #efi_concepts efi_concepts
		ON device_exposure.device_concept_id = efi_concepts.concept_id
	INNER JOIN #efi_scoring efi_scoring
		ON efi_concepts.diag_category_id = efi_scoring.diag_category_id
{@temporal} ? {		
	WHERE device_exposure_start_date <= cohort.cohort_start_date
} : {
	WHERE device_exposure_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
AND efi_concepts.domain_id = 'Device'
UNION
-- Poly-pharmacy
	SELECT 25 AS diag_category_id,
		1 AS weight,
{@aggregated} ? {
		cohort_definition_id,
		@row_id_field,
		cohort_start_date
} : {
		@row_id_field AS row_id
}			
	FROM 
	(
		SELECT cohort.cohort_definition_id,
		cohort.@row_id_field,
		cohort.cohort_start_date,
		COUNT (distinct drug_concept_id) AS ingrd_count
		FROM @cohort_table cohort
		INNER JOIN @cdm_database_schema.drug_era
			ON cohort.@row_id_field = drug_era.person_id
		WHERE drug_concept_id != 0
{@temporal} ? {		
	AND drug_era_start_date <= cohort.cohort_start_date
} : {
	AND drug_era_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
	AND drug_era_end_date >= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
		GROUP BY cohort.cohort_definition_id,
		cohort.@row_id_field,
		cohort.cohort_start_date
	)	q
	WHERE ingrd_count>=5
	) temp
{@aggregated} ? {
GROUP BY cohort_definition_id,
	@row_id_field,
	cohort_start_date
} : {
GROUP BY row_id
}	
;

{@aggregated} ? {
WITH t1 AS (
	SELECT cohort_definition_id,
		COUNT(*) AS cnt 
	FROM @cohort_table 
{@cohort_definition_id != -1} ? {	WHERE cohort_definition_id IN (@cohort_definition_id)}
	GROUP BY cohort_definition_id
	),
t2 AS (
	SELECT cohort_definition_id,
		COUNT(*) AS cnt, 
		MIN(score) AS min_score, 
		MAX(score) AS max_score, 
		SUM(score) AS sum_score,
		SUM(score * score) as squared_score
	FROM #efi_data
	GROUP BY cohort_definition_id
	)
SELECT t1.cohort_definition_id,
	CASE WHEN t2.cnt = t1.cnt THEN t2.min_score ELSE 0 END AS min_value,
	t2.max_score AS max_value,
	CAST(t2.sum_score / (1.0 * t1.cnt) AS FLOAT) AS average_value,
	CAST(CASE WHEN t2.cnt = 1 THEN 0 ELSE SQRT((1.0 * t2.cnt*t2.squared_score - 1.0 * t2.sum_score*t2.sum_score) / (1.0 * t2.cnt*(1.0 * t2.cnt - 1))) END AS FLOAT) AS standard_deviation,
	t2.cnt AS count_value,
	t1.cnt - t2.cnt AS count_no_value,
	t1.cnt AS population_size
INTO #efi_stats
FROM t1
INNER JOIN t2
	ON t1.cohort_definition_id = t2.cohort_definition_id;

SELECT cohort_definition_id,
	score,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id ORDER BY score) AS rn
INTO #efi_prep
FROM #efi_data
GROUP BY cohort_definition_id,
	score;
	
SELECT s.cohort_definition_id,
	s.score,
	SUM(p.total) AS accumulated
INTO #efi_prep2	
FROM #efi_prep s
INNER JOIN #efi_prep p
	ON p.rn <= s.rn
		AND p.cohort_definition_id = s.cohort_definition_id
GROUP BY s.cohort_definition_id,
	s.score;

SELECT o.cohort_definition_id,
	CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	CAST(o.average_value AS FLOAT) average_value,
	CAST(o.standard_deviation AS FLOAT) standard_deviation,
	CASE 
		WHEN .50 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .50 * o.population_size THEN score	END) 
		END AS median_value,
	CASE 
		WHEN .10 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .10 * o.population_size THEN score	END) 
		END AS p10_value,		
	CASE 
		WHEN .25 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .25 * o.population_size THEN score	END) 
		END AS p25_value,	
	CASE 
		WHEN .75 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .75 * o.population_size THEN score	END) 
		END AS p75_value,	
	CASE 
		WHEN .90 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .90 * o.population_size THEN score	END) 
		END AS p90_value		
INTO @covariate_table
FROM #efi_prep2 p
INNER JOIN #efi_stats o
	ON p.cohort_definition_id = o.cohort_definition_id
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
GROUP BY o.count_value,
	o.count_no_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.population_size,
	o.cohort_definition_id;
	
TRUNCATE TABLE #efi_data;
DROP TABLE #efi_data;

TRUNCATE TABLE #efi_stats;
DROP TABLE #efi_stats;

TRUNCATE TABLE #efi_prep;
DROP TABLE #efi_prep;

TRUNCATE TABLE #efi_prep2;
DROP TABLE #efi_prep2;	
} 

TRUNCATE TABLE #efi_concepts;

DROP TABLE #efi_concepts;

TRUNCATE TABLE #efi_scoring;

DROP TABLE #efi_scoring;

