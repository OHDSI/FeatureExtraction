-- Feature construction
WITH rawData (
{@aggregated} ? {
	subject_id,
	cohort_start_date,
} : {
	row_id,
}
	days
	)
AS (
	SELECT 
{@aggregated} ? {
		subject_id,
		cohort_start_date,
} : {
		cohort.@row_id_field AS row_id,
}
		DATEDIFF(DAY, observation_period_start_date, cohort_start_date) AS days
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.observation_period
		ON cohort.subject_id = observation_period.person_id
		AND observation_period_start_date <= cohort_start_date
		AND observation_period_end_date >= cohort_start_date
{@cohort_definition_id != -1} ? {	WHERE cohort.cohort_definition_id = @cohort_definition_id}
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
	SELECT CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) THEN MIN(days) ELSE 0 END AS min_value,
		MAX(days) AS max_value,
		SUM(days) / (1.0 * (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id})) AS average_value,
		SQRT((1.0 * COUNT(*)*SUM(days * days) - 1.0 * SUM(days)*SUM(days)) / (1.0 * COUNT(*)*(1.0 * COUNT(*) - 1)))  AS standard_deviation,
		COUNT(*) AS count_value,
		(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) - COUNT(*) AS count_no_value,
		(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) AS population_size
	FROM rawData
	),
prepStats (
	days,
	total,
	rn
	)
AS (
	SELECT days,
		COUNT(*) AS total,
		ROW_NUMBER() OVER (
			ORDER BY days
			) AS rn
	FROM rawData
	GROUP BY days
	),
prepStats2 (
	days,
	total,
	accumulated
	)
AS (
	SELECT s.days,
		s.total,
		SUM(p.total) AS accumulated
	FROM prepStats s
	INNER JOIN prepStats p
		ON p.rn <= s.rn
	GROUP BY s.days,
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
	days AS covariate_value 
INTO @covariate_table
FROM rawData
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
;
}

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	'observation time (days) prior to index ' AS covariate_name,
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
	NULL AS end_day,
}
	'N' AS is_binary,
	'Y' AS missing_means_zero;	
