IF OBJECT_ID('tempdb..#chads2_concepts', 'U') IS NOT NULL
  DROP TABLE #chads2_concepts;
CREATE TABLE #chads2_concepts (
	diag_category_id INT,
	concept_id INT
	);

IF OBJECT_ID('tempdb..#chads2_scoring', 'U') IS NOT NULL
	DROP TABLE #chads2_scoring;

CREATE TABLE #chads2_scoring (
	diag_category_id INT,
	diag_category_name VARCHAR(255),
	weight INT
	);

--Congestive heart failure
INSERT INTO #chads2_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	1,
	'Congestive heart failure',
	1
	);

INSERT INTO #chads2_concepts (
	diag_category_id,
	concept_id
	)
SELECT 1,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (316139);

--Hypertension
INSERT INTO #chads2_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	2,
	'Hypertension',
	1
	);

INSERT INTO #chads2_concepts (
	diag_category_id,
	concept_id
	)
SELECT 2,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (316866);

--Diabetes
INSERT INTO #chads2_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	4,
	'Diabetes',
	1
	);

INSERT INTO #chads2_concepts (
	diag_category_id,
	concept_id
	)
SELECT 4,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (201820);

--Stroke
INSERT INTO #chads2_scoring (
	diag_category_id,
	diag_category_name,
	weight
	)
VALUES (
	5,
	'Stroke',
	2
	);

INSERT INTO #chads2_concepts (
	diag_category_id,
	concept_id
	)
SELECT 5,
	descendant_concept_id
FROM @cdm_database_schema.concept_ancestor
WHERE ancestor_concept_id IN (381591, 434056);

-- Feature construction
{@aggregated} ? {
IF OBJECT_ID('tempdb..#chads2_data', 'U') IS NOT NULL
	DROP TABLE #chads2_data;

IF OBJECT_ID('tempdb..#chads2_stats', 'U') IS NOT NULL
	DROP TABLE #chads2_stats;

IF OBJECT_ID('tempdb..#chads2_prep', 'U') IS NOT NULL
	DROP TABLE #chads2_prep;

IF OBJECT_ID('tempdb..#chads2_prep2', 'U') IS NOT NULL
	DROP TABLE #chads2_prep2;

SELECT cohort_definition_id,
	subject_id,
	cohort_start_date,
	SUM(weight) AS score
INTO #chads2_data
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
	SELECT DISTINCT chads2_scoring.diag_category_id,
		chads2_scoring.weight,
{@aggregated} ? {
		cohort_definition_id,
		cohort.subject_id,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}			
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.condition_era
		ON cohort.subject_id = condition_era.person_id
	INNER JOIN #chads2_concepts chads2_concepts
		ON condition_era.condition_concept_id = chads2_concepts.concept_id
	INNER JOIN #chads2_scoring chads2_scoring
		ON chads2_concepts.diag_category_id = chads2_scoring.diag_category_id
{@temporal} ? {		
	WHERE condition_era_start_date <= cohort.cohort_start_date
} : {
	WHERE condition_era_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}

	UNION
	
	SELECT 3 AS diag_category_id,
		CASE WHEN (YEAR(cohort_start_date) - year_of_birth) >= 75 THEN 1 ELSE 0 END AS weight,
{@aggregated} ? {
		cohort_definition_id,
		cohort.subject_id,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}	  
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.person
		ON cohort.subject_id = person.person_id
{@cohort_definition_id != -1} ? {	WHERE cohort.cohort_definition_id IN (@cohort_definition_id)}
	) temp
{@aggregated} ? {
GROUP BY cohort_definition_id,
	subject_id,
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
	FROM #chads2_data
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
INTO #chads2_stats
FROM t1
INNER JOIN t2
	ON t1.cohort_definition_id = t2.cohort_definition_id;

SELECT cohort_definition_id,
	score,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id ORDER BY score) AS rn
INTO #chads2_prep
FROM #chads2_data
GROUP BY cohort_definition_id,
	score;
	
SELECT s.cohort_definition_id,
	s.score,
	SUM(p.total) AS accumulated
INTO #chads2_prep2	
FROM #chads2_prep s
INNER JOIN #chads2_prep p
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
FROM #chads2_prep2 p
INNER JOIN #chads2_stats o
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
	
TRUNCATE TABLE #chads2_data;
DROP TABLE #chads2_data;

TRUNCATE TABLE #chads2_stats;
DROP TABLE #chads2_stats;

TRUNCATE TABLE #chads2_prep;
DROP TABLE #chads2_prep;

TRUNCATE TABLE #chads2_prep2;
DROP TABLE #chads2_prep2;	
} 

TRUNCATE TABLE #chads2_concepts;

DROP TABLE #chads2_concepts;

TRUNCATE TABLE #chads2_scoring;

DROP TABLE #chads2_scoring;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	CAST('CHADS2' AS VARCHAR(512)) AS covariate_name,
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
