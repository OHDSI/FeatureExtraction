--Hospital Frailty Risk Score (HFRS)
--Reference: Gilbert et al. “Development and Validation of a Hospital Frailty Risk Score Focusing on Older People in Acute Care Settings Using Electronic Hospital Records: An Observational Study.” The Lancet 391, no. 10132 (May 5, 2018): 1775–82. https://doi.org/10.1016/S0140-6736(18)30668-8.

IF OBJECT_ID('tempdb..#hfrs_scoring', 'U') IS NOT NULL
	DROP TABLE #hfrs_scoring;

CREATE TABLE #hfrs_scoring (
	hfrs_category VARCHAR(255),
	hfrs_icd10_code VARCHAR(255),
	hfrs_concept_id INT,
	hfrs_score FLOAT
	);

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Dementia in Alzheimers disease' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	7.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'F00%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Hemiplegia' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	4.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'G81%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Alzheimers disease' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	4.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'G30%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Sequelae of cerebrovascular disease' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	3.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'I69%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other nervous and musculoskeletal systems' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	3.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R29%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other disorders of urinary system' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	3.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'N39%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Delirium' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	3.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'F05%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Unspecified fall' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	3.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'W19%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Superficial injury of head' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	3.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S00%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Unspecified haematuria' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	3.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R31%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other bacterial agents' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'B96%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other cognitive functions and awareness' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R41%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Abnormalities of gait and mobility' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R26%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other cerebrovascular diseases' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'I67%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Convulsions not elsewhere classified' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R56%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Somnolence stupor and coma' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R40%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Complications of genitourinary prosthesis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'T83%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Intracranial injury' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S06%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fracture of shoulder and upper arm' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S42%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('fluid electrolyte and acid base balance' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'E87%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other joint disorders' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M25%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Volume depletion' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'E86%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Senility' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R54%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('rehabilitation procedures' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z50%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Unspecified dementia' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'F03%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other fall on same level' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'W18%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Problems related to medical facilities' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z75%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Vascular dementia' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'F01%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Superficial injury of lower leg' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S80%';
--completed until here

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Cellulitis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	2.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'L03%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Blindness and low vision' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'H54%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Deficiency of other B group vitamins' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'E53%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Problems related to social environment' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z60%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Parkinsons disease' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'G20%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Syncope and collapse' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R55%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fracture of rib sternum and thoracic spine' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S22%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other functional intestinal disorders' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'K59%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Acute renal failure' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'N17%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Decubitus ulcer' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'L89%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Carrier of infectious disease' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z22%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Streptococcus and staphylococcus' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'B95%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Ulcer of lower limb' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'L97%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other symptoms involving general sensations and perceptions' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R44%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Duodenal ulcer' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'K26%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Hypotension' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'I95%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Unspecified renal failure' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'N19%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other septicaemia' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'A41%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Personal history of other diseases and conditions' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z87%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Respiratory failure' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'J96%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Exposure to unspecified factor' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'X59%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other arthrosis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M19%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Epilepsy' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'G40%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Osteoporosis without pathological fracture' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M81%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fracture of femur' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S72%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fracture of lumbar spine and pelvis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S32%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other disorders of pancreatic internal secretion' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'E16%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Abnormal results of function studies' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R94%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Chronic renal failure' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'N18%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Retention of urine' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R33%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Unknown and unspecified causes of morbidity' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R69%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other disorders of kidney and ureter' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'N28%';


INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Unspecified urinary incontinence' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R32%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other degenerative diseases of nervous system' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'G31%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Nosocomial condition' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Y95%';

--completed from here
INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other and unspecified injuries of head' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S09%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Symptoms and signs involving emotional state' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R45%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Transient cerebral ischaemic attacks' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.2 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'G45%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Problems related to careprovider dependency' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z74%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other soft tissue disorders not elsewhere classified' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M79%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fall involving bed' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'W06%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Open wound of head' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S01%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other bacterial intestinal infections' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'A04%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Infectious Diarrhoea and gastroenteritis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'A09%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Pneumonia organism unspecified' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'J18%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Pneumonitis due to solids and liquids' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'J69%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Speech disturbances not elsewhere classified' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R47%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Vitamin D deficiency' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'E55%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Artificial opening status' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z93%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Gangrene not elsewhere classified' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	1.0 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R02%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Symptoms and signs concerning food and fluid intake' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R63%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other hearing loss' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'H91%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fall on and from stairs and steps' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'W10%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fall on same level from slipping tripping and stumbling' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'W01%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Thyrotoxicosis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'E05%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Scoliosis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.9 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M41%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Dysphagia' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R13%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Dependence on enabling machines and devices' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z99%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Agent resistant to penicillin and related antibiotics' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'U80%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Osteoporosis with pathological fracture' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M80%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other diseases of digestive system' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'K92%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Cerebral Infarction' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.8 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'I63%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Calculus of kidney and ureter' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'N20%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Mental and behavioural disorders due to use of alcohol' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'F10%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other medical procedures causing abnormal reaction' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Y84%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Abnormalities of heart beat' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R00%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Unspecified acute lower respiratory infection' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.7 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'J22%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Problems related to lifemanagement difficulty' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z73%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other abnormal findings of blood chemistry' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.6 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R79%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Personal history of riskfactors' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'Z91%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Open wound of forearm' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'S51%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Depressive episode' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'F32%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Spinal stenosis secondary code only' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.5 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M48%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Disorders of mineral metabolism' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'E83%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Polyarthrosis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'M15%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other anaemias' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'D64%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other local infections of skin and subcutaneous tissue' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.4 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'L08%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Nausea and vomiting' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R11%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Other noninfective gastroenteritis and colitis' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.3 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'K52%';

INSERT INTO #hfrs_scoring (
	hfrs_category,
	hfrs_icd10_code,
	hfrs_concept_id,
	hfrs_score
	)
SELECT CAST('Fever of unknown origin' AS VARCHAR(255)) AS hfrs_category,
	CAST(source_code AS VARCHAR(255)),
	target_concept_id,
	0.1 AS hfrs_score
FROM (
	SELECT source.concept_code AS source_code,
		target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source
		ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target
		ON target.concept_id = concept_relationship.concept_id_2
	WHERE source.vocabulary_id = 'ICD10'
		AND target.vocabulary_id = 'SNOMED'
		AND relationship_id = 'Maps to'
	) source_to_concept_map
WHERE source_code LIKE 'R50%';
--completed until here
-- Feature construction
{@aggregated} ? {
IF OBJECT_ID('tempdb..#hfrs_data', 'U') IS NOT NULL
	DROP TABLE #hfrs_data;

IF OBJECT_ID('tempdb..#hfrs_stats', 'U') IS NOT NULL
	DROP TABLE #hfrs_stats;

IF OBJECT_ID('tempdb..#hfrs_prep', 'U') IS NOT NULL
	DROP TABLE #hfrs_prep;

IF OBJECT_ID('tempdb..#hfrs_prep2', 'U') IS NOT NULL
	DROP TABLE #hfrs_prep2;

SELECT cohort_definition_id,
	subject_id,
	cohort_start_date,
	SUM(max_score) AS score
INTO #hfrs_data
} : {
SELECT CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}	
	row_id,
	SUM(max_score) AS covariate_value
INTO @covariate_table
}
FROM (
	SELECT hfrs_category,
		MAX(hfrs_score) AS max_score,
{@aggregated} ? {
		cohort_definition_id,
		cohort.subject_id,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.condition_era condition_era
		ON cohort.subject_id = condition_era.person_id
	INNER JOIN #hfrs_scoring hfrs_scoring
		ON condition_concept_id = hfrs_scoring.hfrs_concept_id
{@temporal} ? {		
	WHERE condition_era_start_date <= cohort.cohort_start_date
} : {
	WHERE condition_era_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
{@aggregated} ? {
	GROUP BY cohort_definition_id,
		subject_id,
		cohort_start_date,
		hfrs_category
} : {
	GROUP BY cohort.@row_id_field,
		hfrs_category
}
	) temp
{@aggregated} ? {
GROUP BY subject_id,
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
		SUM(score*score) AS squared_score 
	FROM #hfrs_data
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
INTO #hfrs_stats
FROM t1
INNER JOIN t2
	ON t1.cohort_definition_id = t2.cohort_definition_id;

SELECT cohort_definition_id,
	score,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id ORDER BY score) AS rn
INTO #hfrs_prep
FROM #hfrs_data
GROUP BY cohort_definition_id,
	score;
	
SELECT s.cohort_definition_id,
	s.score,
	SUM(p.total) AS accumulated
INTO #hfrs_prep2	
FROM #hfrs_prep s
INNER JOIN #hfrs_prep p
	ON p.rn <= s.rn
		AND p.cohort_definition_id = s.cohort_definition_id
GROUP BY s.cohort_definition_id,
	s.score;

SELECT o.cohort_definition_id,
	CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}
	o.cohort_definition_id,
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
FROM #hfrs_prep2 p
INNER JOIN #hfrs_stats o
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
	
TRUNCATE TABLE #hfrs_data;
DROP TABLE #hfrs_data;

TRUNCATE TABLE #hfrs_stats;
DROP TABLE #hfrs_stats;

TRUNCATE TABLE #hfrs_prep;
DROP TABLE #hfrs_prep;

TRUNCATE TABLE #hfrs_prep2;
DROP TABLE #hfrs_prep2;	
} 

TRUNCATE TABLE #hfrs_scoring;

DROP TABLE #hfrs_scoring;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	CAST('Hospital Frailty Risk Score (hfrs)' AS VARCHAR(512)) AS covariate_name,
	@analysis_id AS analysis_id,
	0 AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1;
	
INSERT INTO #analysis_ref (
	analysis_id,
	analysis_name,
	domain_id,
{!@temporal} ? {
	start_day,
	end_day,
}
	is_binary,
	missing_means_zero
	)
SELECT @analysis_id AS analysis_id,
	CAST('@analysis_name' AS VARCHAR(512)) AS analysis_name,
	CAST('@domain_id' AS VARCHAR(20)) AS domain_id,
{!@temporal} ? {
	CAST(NULL AS INT) AS start_day,
	@end_day AS end_day,
}
	CAST('N' AS VARCHAR(1)) AS is_binary,
	CAST('Y' AS VARCHAR(1)) AS missing_means_zero;
