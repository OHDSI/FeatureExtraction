-- Feature construction
{@aggregated} ? {
DROP TABLE IF EXISTS #occ_count_data;
DROP TABLE IF EXISTS #occ_count_stats;
DROP TABLE IF EXISTS #occ_count_prep;
DROP TABLE IF EXISTS #occ_count_prep2;
}

SELECT CAST(covariate_cohort.cohort_definition_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    time_id,
}	
{@aggregated} ? {
	COUNT(DISTINCT covariate_cohort.cohort_start_date) AS occurrence_count,
	main_cohort.cohort_definition_id,
	main_cohort.subject_id,
	main_cohort.cohort_start_date
INTO #occ_count_data
} : {
	COUNT(DISTINCT covariate_cohort.cohort_start_date) AS covariate_value,
	main_cohort.@row_id_field AS row_id
INTO @covariate_table
}	
FROM @cohort_table main_cohort
INNER JOIN @covariate_cohort_table covariate_cohort
	ON main_cohort.subject_id = covariate_cohort.subject_id 
INNER JOIN #covariate_cohort_ref covariate_cohort_ref
	ON covariate_cohort.cohort_definition_id = covariate_cohort_ref.cohort_id
{@temporal} ? {
INNER JOIN #time_period time_period
	ON covariate_cohort.cohort_start_date <= DATEADD(DAY, time_period.end_day, main_cohort.cohort_start_date)
	AND CASE WHEN covariate_cohort.cohort_end_date IS NULL THEN covariate_cohort.cohort_start_date ELSE covariate_cohort.cohort_end_date END >= DATEADD(DAY, time_period.start_day, main_cohort.cohort_start_date)
} : {
WHERE covariate_cohort.cohort_start_date <= DATEADD(DAY, @end_day, main_cohort.cohort_start_date)
{@start_day != 'anyTimePrior'} ? {		
		AND CASE WHEN covariate_cohort.cohort_end_date IS NULL THEN covariate_cohort.cohort_start_date ELSE covariate_cohort.cohort_end_date END >= DATEADD(DAY, @start_day, main_cohort.cohort_start_date)
}
}	
{@included_cov_table != ''} ? {		AND CAST(covariate_cohort.cohort_definition_id AS BIGINT) * 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
{@cohort_definition_id != -1} ? {		AND main_cohort.cohort_definition_id IN (@cohort_definition_id)}
GROUP BY covariate_cohort.cohort_definition_id,
{@temporal} ? {
		time_id,
}	
{@aggregated} ? {
		main_cohort.cohort_definition_id,
		main_cohort.subject_id,
		main_cohort.cohort_start_date
} : {
		main_cohort.@row_id_field
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
		covariate_id,
{@temporal} ? {
		time_id,
}	
		MIN(occurrence_count) AS min_occurrence_count, 
		MAX(occurrence_count) AS max_occurrence_count, 
		SUM(CAST(occurrence_count AS BIGINT)) AS sum_occurrence_count,
		SUM(CAST(occurrence_count AS BIGINT) * CAST(occurrence_count AS BIGINT)) AS squared_occurrence_count
	FROM #occ_count_data
	GROUP BY cohort_definition_id,
{@temporal} ? {
		time_id,
}	
		covariate_id
	)
SELECT t1.cohort_definition_id,
	CASE WHEN t2.cnt = t1.cnt THEN t2.min_occurrence_count ELSE 0 END AS min_value,
	t2.max_occurrence_count AS max_value,
	covariate_id,
{@temporal} ? {
	time_id,
}	
	CAST(t2.sum_occurrence_count / (1.0 * t1.cnt) AS FLOAT) AS average_value,
	CAST(CASE
		WHEN t2.cnt = 1 THEN 0 
		ELSE SQRT((1.0 * t2.cnt*t2.squared_occurrence_count - 1.0 * t2.sum_occurrence_count*t2.sum_occurrence_count) / (1.0 * t2.cnt*(1.0 * t2.cnt - 1))) 
	END AS FLOAT) AS standard_deviation,
	t2.cnt AS count_value,
	t1.cnt - t2.cnt AS count_no_value,
	t1.cnt AS population_size
INTO #occ_count_stats
FROM t1
INNER JOIN t2
	ON t1.cohort_definition_id = t2.cohort_definition_id;

SELECT cohort_definition_id, 
{@temporal} ? {
	time_id,
}	
	occurrence_count,
	COUNT(*) AS total,
	covariate_id,
{@temporal} ? {	
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id, covariate_id, time_id ORDER BY occurrence_count) AS rn
} : {
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id, covariate_id ORDER BY occurrence_count) AS rn
}
INTO #occ_count_prep
FROM #occ_count_data
GROUP BY cohort_definition_id,
{@temporal} ? {
	time_id,
}	
	covariate_id,
	occurrence_count;
	
SELECT s.cohort_definition_id,
{@temporal} ? {
	s.time_id,
}	
	s.covariate_id,
	s.occurrence_count,
	SUM(p.total) AS accumulated
INTO #occ_count_prep2	
FROM #occ_count_prep s
INNER JOIN #occ_count_prep p
	ON p.rn <= s.rn
		AND p.cohort_definition_id = s.cohort_definition_id
		AND p.covariate_id = s.covariate_id
{@temporal} ? {
	AND p.time_id = s.time_id
}	
GROUP BY s.cohort_definition_id,
{@temporal} ? {
	s.time_id,
}	
	s.covariate_id,
	s.occurrence_count;

SELECT o.covariate_id,
	o.cohort_definition_id,
{@temporal} ? {
	o.time_id,
}	
	o.count_value,
	o.min_value,
	o.max_value,
	CAST(o.average_value AS FLOAT) average_value,
	CAST(o.standard_deviation AS FLOAT) standard_deviation,
	CASE 
		WHEN .50 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .50 * o.population_size THEN occurrence_count	END) 
		END AS median_value,
	CASE 
		WHEN .10 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .10 * o.population_size THEN occurrence_count	END) 
		END AS p10_value,		
	CASE 
		WHEN .25 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .25 * o.population_size THEN occurrence_count	END) 
		END AS p25_value,	
	CASE 
		WHEN .75 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .75 * o.population_size THEN occurrence_count	END) 
		END AS p75_value,	
	CASE 
		WHEN .90 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .90 * o.population_size THEN occurrence_count	END) 
		END AS p90_value		
INTO @covariate_table
FROM #occ_count_prep2 p
INNER JOIN #occ_count_stats o
	ON p.covariate_id = o.covariate_id
		AND p.cohort_definition_id = o.cohort_definition_id
{@temporal} ? {
		AND p.time_id = o.time_id
}	
{@included_cov_table != ''} ? {WHERE covariate_id IN (SELECT id FROM @included_cov_table)}
GROUP BY o.cohort_definition_id,
{@temporal} ? {
	o.time_id,
}	
	o.count_value,
	o.count_no_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.covariate_id,
	o.population_size;
	
TRUNCATE TABLE #occ_count_data;
DROP TABLE #occ_count_data;

TRUNCATE TABLE #occ_count_stats;
DROP TABLE #occ_count_stats;

TRUNCATE TABLE #occ_count_prep;
DROP TABLE #occ_count_prep;

TRUNCATE TABLE #occ_count_prep2;
DROP TABLE #occ_count_prep2;	
} 

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
{@temporal | @temporal_sequence} ? {
	CAST(CONCAT('cohort count: ', cohort_name) AS VARCHAR(512)) AS covariate_name,
} : {
{@start_day == 'anyTimePrior'} ? {
	CAST(CONCAT('cohort count any time prior through @end_day days relative to index: ', cohort_name) AS VARCHAR(512)) AS covariate_name,
} : {
	CAST(CONCAT('cohort count during day @start_day through @end_day days relative to index: ', cohort_name) AS VARCHAR(512)) AS covariate_name,
}
}
	@analysis_id AS analysis_id,
	0 AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1
LEFT JOIN #covariate_cohort_ref
	ON cohort_id = CAST((covariate_id - @analysis_id) / 1000 AS INT);
	
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
	CAST('cohort' AS VARCHAR(20)) AS domain_id,
{!@temporal} ? {
{@start_day == 'anyTimePrior'} ? {
	CAST(NULL AS INT) AS start_day,
} : {
	
	{@temporal_sequence} ? {@sequence_start_day} : {@start_day}  AS start_day,
}
	{@temporal_sequence} ? {@sequence_end_day} : {@end_day} AS end_day,
}
	CAST('N' AS VARCHAR(1)) AS is_binary,
	CAST('Y' AS VARCHAR(1)) AS missing_means_zero;
