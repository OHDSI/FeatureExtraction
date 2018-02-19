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
	days
INTO #raw_data
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
{@cohort_definition_id != -1} ? {	WHERE cohort.cohort_definition_id = @cohort_definition_id}
	) raw_data;

{@aggregated} ? {
WITH t1 AS (
	SELECT COUNT(*) AS cnt 
	FROM @cohort_table 
{@cohort_definition_id != -1} ? {	WHERE cohort_definition_id = @cohort_definition_id}
	),
t2 AS (
	SELECT COUNT(*) AS cnt, 
		MIN(days) AS min_days, 
		MAX(days) AS max_days, 
		SUM(CAST(days AS BIGINT)) AS sum_days, 
		SUM(CAST(days AS BIGINT) * CAST(days AS BIGINT)) AS squared_days 
	FROM #raw_data
	)
SELECT CASE WHEN t2.cnt = t1.cnt THEN t2.min_days ELSE 0 END AS min_value,
	t2.max_days AS max_value,
	t2.sum_days / (1.0 * t1.cnt) AS average_value,
	CASE WHEN t2.cnt = 1 THEN 0 ELSE SQRT((1.0 * t2.cnt*t2.squared_days - 1.0 * t2.sum_days*t2.sum_days) / (1.0 * t2.cnt*(1.0 * t2.cnt - 1))) END AS standard_deviation,
	t2.cnt AS count_value,
	t1.cnt - t2.cnt AS count_no_value,
	t1.cnt AS population_size
INTO #overall_stats
FROM t1, t2;

SELECT days,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (ORDER BY days) AS rn
INTO #prep_stats
FROM #raw_data
GROUP BY days;
	
SELECT s.days,
	SUM(p.total) AS accumulated
INTO #prep_stats2	
FROM #prep_stats s
INNER JOIN #prep_stats p
	ON p.rn <= s.rn
GROUP BY s.days;

SELECT CAST(1000 + @analysis_id AS BIGINT) AS covariate_id,
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
