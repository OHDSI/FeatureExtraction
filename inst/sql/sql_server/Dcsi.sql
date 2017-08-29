IF OBJECT_ID('tempdb..#dcsi_scoring', 'U') IS NOT NULL
	DROP TABLE #dcsi_scoring;

CREATE TABLE #dcsi_scoring (
	dcsi_category VARCHAR(255)
	,dcsi_icd9_code VARCHAR(255)
	,dcsi_concept_id INT
	,dcsi_score INT
	);

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Retinopathy' AS dcsi_category
	,source_code
	,target_concept_id
	,1 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '250.5%'
	OR source_code IN (
		'362.01'
		,'362.1'
		,'362.83'
		,'362.53'
		,'362.81'
		,'362.82'
		);

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Retinopathy' AS dcsi_category
	,source_code
	,target_concept_id
	,2 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '361%'
	OR source_code LIKE '369%'
	OR source_code IN (
		'362.02'
		,'379.23'
		);

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Nephropathy' AS dcsi_category
	,source_code
	,target_concept_id
	,1 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code IN (
		'250.4'
		,'580'
		,'581'
		,'581.81'
		,'582'
		,'583'
		)
	OR source_code LIKE '580%'
	OR source_code LIKE '581%'
	OR source_code LIKE '582%'
	OR source_code LIKE '583%';

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Nephropathy' AS dcsi_category
	,source_code
	,target_concept_id
	,2 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code IN (
		'585'
		,'586'
		,'593.9'
		)
	OR source_code LIKE '585%'
	OR source_code LIKE '586%'
	OR source_code LIKE '593.9%';

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Neuropathy' AS dcsi_category
	,source_code
	,target_concept_id
	,1 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code IN (
		'356.9'
		,'250.6'
		,'358.1'
		,'951.0'
		,'951.1'
		,'951.3'
		,'713.5'
		,'357.2'
		,'596.54'
		,'337.0'
		,'337.1'
		,'564.5'
		,'536.3'
		,'458.0'
		)
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

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Cerebrovascular' AS dcsi_category
	,source_code
	,target_concept_id
	,1 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '435%';

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Cerebrovascular' AS dcsi_category
	,source_code
	,target_concept_id
	,2 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code IN (
		'431'
		,'433'
		,'434'
		,'436'
		)
	OR source_code LIKE '431%'
	OR source_code LIKE '433%'
	OR source_code LIKE '434%'
	OR source_code LIKE '436%';

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Cardiovascular' AS dcsi_category
	,source_code
	,target_concept_id
	,1 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '440%'
	OR source_code LIKE '411%'
	OR source_code LIKE '413%'
	OR source_code LIKE '414%'
	OR source_code LIKE '429.2%';

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Cardiovascular' AS dcsi_category
	,source_code
	,target_concept_id
	,2 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '410%'
	OR source_code LIKE '427.1%'
	OR source_code LIKE '427.3%'
	OR source_code LIKE '427.4%'
	OR source_code LIKE '427.5%'
	OR source_code LIKE '412%'
	OR source_code LIKE '428%'
	OR source_code LIKE '441%'
	OR source_code IN (
		'440.23'
		,'440.24'
		);

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Peripheral vascular disease' AS dcsi_category
	,source_code
	,target_concept_id
	,1 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '250.7%'
	OR source_code LIKE '442.3%'
	OR source_code LIKE '892.1%'
	OR source_code LIKE '443.9%'
	OR source_code IN ('443.81');

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Peripheral vascular disease' AS dcsi_category
	,source_code
	,target_concept_id
	,2 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '785.4%'
	OR source_code LIKE '707.1%'
	OR source_code LIKE '040.0%'
	OR source_code IN ('444.22');

INSERT INTO #dcsi_scoring (
	dcsi_category
	,dcsi_icd9_code
	,dcsi_concept_id
	,dcsi_score
	)
SELECT 'Metabolic' AS dcsi_category
	,source_code
	,target_concept_id
	,2 AS dcsi_score
FROM (
	SELECT source.concept_code AS source_code
		,target.concept_id AS target_concept_id
	FROM @cdm_database_schema.concept_relationship
	INNER JOIN @cdm_database_schema.concept source ON source.concept_id = concept_relationship.concept_id_1
	INNER JOIN @cdm_database_schema.concept target ON target.concept_id = concept_relationship.concept_id_2
	WHERE LOWER(source.vocabulary_id) = 'icd9cm'
		AND LOWER(target.vocabulary_id) = 'snomed'
		AND LOWER(relationship_id) = 'maps to'
	) source_to_concept_map
WHERE source_code LIKE '250.1%'
	OR source_code LIKE '250.2%'
	OR source_code LIKE '250.3%';

-- Feature construction
WITH rawData (
{@aggregated} ? {
	subject_id,
	cohort_start_date,
} : {
	row_id,
}
	score
	)
AS (
	SELECT 
{@aggregated} ? {
		subject_id,
		cohort_start_date,
} : {
		row_id,
}
		SUM(max_score) AS score
	FROM (
		SELECT dcsi_category,
			MAX(dcsi_score) AS max_score,
{@aggregated} ? {
			cohort.subject_id,
			cohort.cohort_start_date
} : {
			cohort.@row_id_field AS row_id
}			
		FROM @cohort_table cohort
		INNER JOIN @cdm_database_schema.condition_era condition_era
			ON cohort.subject_id = condition_era.person_id
		INNER JOIN #dcsi_scoring dcsi_scoring
			ON condition_concept_id = dcsi_scoring.dcsi_concept_id
{@temporal} ? {		
		WHERE condition_era_start_date <= cohort.cohort_start_date
} : {
		WHERE condition_era_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id = @cohort_definition_id}
{@aggregated} ? {
		GROUP BY subject_id,
			cohort_start_date,
			dcsi_category
} : {
		GROUP BY row_id,
			dcsi_category
}
	) temp
{@aggregated} ? {
	GROUP BY subject_id,
			cohort_start_date
} : {
	GROUP BY row_id
}
)
{@aggregated} ? {
, overallStats (
	min_value,
	max_value,
	average_value,
	standard_deviation,
	count_value,
	count_no_value,
	population_size
	)
AS (
	SELECT CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) THEN MIN(score) ELSE 0 END AS min_value,
		MAX(score) AS max_value,
		SUM(score) / (1.0 * (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id})) AS average_value,
		SQRT((1.0 * COUNT(*)*SUM(score * score) - 1.0 * SUM(score)*SUM(score)) / (1.0 * COUNT(*)*(1.0 * COUNT(*) - 1)))  AS standard_deviation,
		COUNT(*) AS count_value,
		(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) - COUNT(*) AS count_no_value,
		(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) AS population_size
	FROM rawData
	),
prepStats (
	score,
	total,
	rn
	)
AS (
	SELECT score,
		COUNT(*) AS total,
		ROW_NUMBER() OVER (
			ORDER BY score
			) AS rn
	FROM rawData
	GROUP BY score
	),
prepStats2 (
	score,
	total,
	accumulated
	)
AS (
	SELECT s.score,
		s.total,
		SUM(p.total) AS accumulated
	FROM prepStats s
	INNER JOIN prepStats p
		ON p.rn <= s.rn
	GROUP BY s.score,
		s.total,
		s.rn
	)
SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    NULL AS time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
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
FROM prepStats2 p
CROSS JOIN overallStats o
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
GROUP BY o.count_value,
	o.count_no_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.population_size;
} : {
SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    NULL AS time_id,
}	
	row_id,
	score AS covariate_value 
INTO @covariate_table
FROM rawData
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
;
}

TRUNCATE TABLE #dcsi_scoring;

DROP TABLE #dcsi_scoring;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	'Diabetes Comorbidity Severity Index (DCSI)' AS covariate_name,
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
	'@analysis_name' AS analysis_name,
	'@domain_id' AS domain_id,
{!@temporal} ? {
	NULL AS start_day,
	@end_day AS end_day,
}
	'N' AS is_binary,
	'Y' AS missing_means_zero;
