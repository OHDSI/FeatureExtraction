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
{@aggregated} ? {
IF OBJECT_ID('tempdb..#raw_data', 'U') IS NOT NULL
	DROP TABLE #raw_data;

IF OBJECT_ID('tempdb..#overall_stats', 'U') IS NOT NULL
	DROP TABLE #overall_stats;

IF OBJECT_ID('tempdb..#prep_stats', 'U') IS NOT NULL
	DROP TABLE #prep_stats;

IF OBJECT_ID('tempdb..#prep_stats2', 'U') IS NOT NULL
	DROP TABLE #prep_stats2;

SELECT subject_id,
	cohort_start_date,
	SUM(weight) AS score
INTO #raw_data
} : {
SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}	
	row_id,
	SUM(weight) AS covariate_value
INTO @covariate_table
}
FROM (
	SELECT DISTINCT charlson_scoring.diag_category_id,
		charlson_scoring.weight,
{@aggregated} ? {
		cohort.subject_id,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
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
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id = @cohort_definition_id}
	) temp
{@aggregated} ? {
GROUP BY subject_id,
			cohort_start_date
} : {
GROUP BY row_id
}	
;

{@aggregated} ? {
SELECT CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) THEN MIN(score) ELSE 0 END AS min_value,
	MAX(score) AS max_value,
	SUM(score) / (1.0 * (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id})) AS average_value,
	CASE WHEN COUNT(*) = 1 THEN 0 ELSE SQRT((1.0 * COUNT(*)*SUM(score * score) - 1.0 * SUM(score)*SUM(score)) / (1.0 * COUNT(*)*(1.0 * COUNT(*) - 1))) END AS standard_deviation,
	COUNT(*) AS count_value,
	(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) - COUNT(*) AS count_no_value,
	(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) AS population_size
INTO #overall_stats
FROM #raw_data;

SELECT score,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (ORDER BY score) AS rn
INTO #prep_stats
FROM #raw_data
GROUP BY score;
	
SELECT s.score,
	SUM(p.total) AS accumulated
INTO #prep_stats2	
FROM #prep_stats s
INNER JOIN #prep_stats p
	ON p.rn <= s.rn
GROUP BY s.score;

SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
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
FROM #prep_stats2 p
CROSS JOIN #overall_stats o
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
GROUP BY o.count_value,
	o.count_no_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.population_size;
	
TRUNCATE TABLE #raw_data;
DROP TABLE #raw_data;

TRUNCATE TABLE #overall_stats;
DROP TABLE #overall_stats;

TRUNCATE TABLE #prep_stats;
DROP TABLE #prep_stats;

TRUNCATE TABLE #prep_stats2;
DROP TABLE #prep_stats2;	
} 

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
	CAST(NULL AS INT) AS start_day,
	@end_day AS end_day,
}
	'N' AS is_binary,
	'Y' AS missing_means_zero;
