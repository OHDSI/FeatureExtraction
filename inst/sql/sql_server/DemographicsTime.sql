-- Feature construction
{@aggregated} ? {
IF OBJECT_ID('tempdb..#dem_time_data', 'U') IS NOT NULL
	DROP TABLE #dem_time_data;

IF OBJECT_ID('tempdb..#dem_time_stats', 'U') IS NOT NULL
	DROP TABLE #dem_time_stats;

IF OBJECT_ID('tempdb..#dem_time_prep', 'U') IS NOT NULL
	DROP TABLE #dem_time_prep;

IF OBJECT_ID('tempdb..#dem_time_prep2', 'U') IS NOT NULL
	DROP TABLE #dem_time_prep2;

SELECT subject_id,
	cohort_definition_id,
	cohort_start_date,
	days
INTO #dem_time_data
} : {
SELECT CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}	
	row_id,
	days AS covariate_value
INTO @covariate_table	
}
FROM (
	SELECT 
{@aggregated} ? {
		cohort_definition_id,
		subject_id,
		cohort_start_date,	
} : {
		cohort.@row_id_field AS row_id,	
}
{@sub_type == 'priorObservation'} ? {
		DATEDIFF(DAY, observation_period_start_date, cohort_start_date) AS days
} 
{@sub_type == 'postObservation'} ? {
		DATEDIFF(DAY, cohort_start_date, observation_period_end_date) AS days
} 
{@sub_type == 'inCohort'} ? {
		DATEDIFF(DAY, cohort_start_date, cohort_end_date) AS days
} 
	FROM @cohort_table cohort
{@sub_type != 'inCohort'} ? {
	INNER JOIN @cdm_database_schema.observation_period
		ON cohort.subject_id = observation_period.person_id
		AND observation_period_start_date <= cohort_start_date
		AND observation_period_end_date >= cohort_start_date
}
{@cohort_definition_id != -1} ? {	WHERE cohort.cohort_definition_id IN (@cohort_definition_id)}
	) raw_data;

{@aggregated} ? {
WITH t1 AS (
	SELECT cohort_definition_id,
		COUNT(*) AS cnt 
	FROM @cohort_table 
{@cohort_definition_id != -1} ? {	WHERE cohort_definition_id IN(@cohort_definition_id)}
	GROUP BY cohort_definition_id
	),
t2 AS (
	SELECT cohort_definition_id,
		COUNT(*) AS cnt, 
		MIN(days) AS min_days, 
		MAX(days) AS max_days, 
		SUM(CAST(days AS BIGINT)) AS sum_days, 
		SUM(CAST(days AS BIGINT) * CAST(days AS BIGINT)) AS squared_days 
	FROM #dem_time_data
	GROUP BY cohort_definition_id
	)
SELECT t1.cohort_definition_id,
	CASE WHEN t2.cnt = t1.cnt THEN t2.min_days ELSE 0 END AS min_value,
	t2.max_days AS max_value,
	CAST(t2.sum_days / (1.0 * t1.cnt) AS FLOAT) AS average_value,
	CAST(CASE WHEN t2.cnt = 1 THEN 0 ELSE SQRT((1.0 * t2.cnt*t2.squared_days - 1.0 * t2.sum_days*t2.sum_days) / (1.0 * t2.cnt*(1.0 * t2.cnt - 1))) END AS FLOAT) AS standard_deviation,
	t2.cnt AS count_value,
	t1.cnt - t2.cnt AS count_no_value,
	t1.cnt AS population_size
INTO #dem_time_stats
FROM t1
INNER JOIN t2
	ON t1.cohort_definition_id = t2.cohort_definition_id;

SELECT cohort_definition_id,
	days,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id ORDER BY days) AS rn
INTO #dem_time_prep
FROM #dem_time_data
GROUP BY cohort_definition_id,
	days;
	
SELECT s.cohort_definition_id,
	s.days,
	SUM(p.total) AS accumulated
INTO #dem_time_prep2	
FROM #dem_time_prep s
INNER JOIN #dem_time_prep p
	ON p.rn <= s.rn
		AND p.cohort_definition_id = s.cohort_definition_id
GROUP BY s.cohort_definition_id,
	s.days;

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
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .50 * o.population_size THEN days	END) 
		END AS median_value,
	CASE 
		WHEN .10 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .10 * o.population_size THEN days	END) 
		END AS p10_value,		
	CASE 
		WHEN .25 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .25 * o.population_size THEN days	END) 
		END AS p25_value,	
	CASE 
		WHEN .75 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .75 * o.population_size THEN days	END) 
		END AS p75_value,	
	CASE 
		WHEN .90 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .90 * o.population_size THEN days	END) 
		END AS p90_value		
INTO @covariate_table
FROM #dem_time_prep2 p
INNER JOIN #dem_time_stats o
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
	
TRUNCATE TABLE #dem_time_data;
DROP TABLE #dem_time_data;

TRUNCATE TABLE #dem_time_stats;
DROP TABLE #dem_time_stats;

TRUNCATE TABLE #dem_time_prep;
DROP TABLE #dem_time_prep;

TRUNCATE TABLE #dem_time_prep2;
DROP TABLE #dem_time_prep2;	
} 

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
{@sub_type == 'priorObservation'} ? {
	CAST('observation time (days) prior to index' AS VARCHAR(512)) AS covariate_name,
} 
{@sub_type == 'postObservation'} ? {
	CAST('observation time (days) after index' AS VARCHAR(512)) AS covariate_name,
} 
{@sub_type == 'inCohort'} ? {
	CAST('time (days) between cohort start and end' AS VARCHAR(512)) AS covariate_name,
}
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
	CAST(NULL AS INT) AS end_day,
}
	CAST('N' AS VARCHAR(1)) AS is_binary,
	CAST('Y' AS VARCHAR(1)) AS missing_means_zero;
