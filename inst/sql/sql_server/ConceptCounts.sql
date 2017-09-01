-- Feature construction
WITH rawData (
{@aggregated} ? {
{@temporal} ? {
	time_id,
}
	subject_id,
	cohort_start_date,
} : {
	row_id,
}
	concept_count
	)
AS (
	SELECT 
{@temporal} ? {
		time_id,
}	
{@aggregated} ? {
		subject_id,
		cohort_start_date,
} : {
		cohort.@row_id_field AS row_id,
}
{@distinct_concepts} ? {
		COUNT(DISTINCT @domain_concept_id) AS concept_count
} : {
		COUNT(*) AS concept_count
}
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.@domain_table
		ON cohort.subject_id = @domain_table.person_id
{@temporal} ? {
	INNER JOIN #time_period time_period
		ON @domain_start_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
		AND @domain_end_date >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
	WHERE @domain_concept_id != 0
} : {
	WHERE @domain_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
		AND @domain_end_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)
		AND @domain_concept_id != 0
}
{@excluded_concept_table != ''} ? {		AND @domain_concept_id NOT IN (SELECT id FROM @excluded_concept_table)}
{@included_concept_table != ''} ? {		AND @domain_concept_id IN (SELECT id FROM @included_concept_table)}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id = @cohort_definition_id}
	GROUP BY 
{@temporal} ? {
		time_id,
}	
{@aggregated} ? {
		subject_id,
		cohort_start_date
} : {
		row_id
}	
)
{@aggregated} ? {
, overallStats (
{@temporal} ? {
    time_id,
}
	min_value,
	max_value,
	average_value,
	standard_deviation,
	count_value,
	count_no_value,
	population_size
	)
AS (
	SELECT 
{@temporal} ? {
		time_id,
}
		CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) THEN MIN(concept_count) ELSE 0 END AS min_value,
		MAX(concept_count) AS max_value,
		SUM(concept_count) / (1.0 * (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id})) AS average_value,
		SQRT((1.0 * COUNT(*)*SUM(concept_count * concept_count) - 1.0 * SUM(concept_count)*SUM(concept_count)) / (1.0 * COUNT(*)*(1.0 * COUNT(*) - 1)))  AS standard_deviation,
		COUNT(*) AS count_value,
		(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) - COUNT(*) AS count_no_value,
		(SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id}) AS population_size
	FROM rawData
	),
prepStats (
{@temporal} ? {
    time_id,
}
	concept_count,
	total,
	rn
	)
AS (
	SELECT 
{@temporal} ? {
		time_id,
}
		concept_count,
		COUNT(*) AS total,
		ROW_NUMBER() OVER (
			ORDER BY concept_count
			) AS rn
	FROM rawData
	GROUP BY concept_count
	),
prepStats2 (
{@temporal} ? {
    time_id,
}
	concept_count,
	total,
	accumulated
	)
AS (
	SELECT 
{@temporal} ? {
		time_id,
}
		s.concept_count,
		s.total,
		SUM(p.total) AS accumulated
	FROM prepStats s
	INNER JOIN prepStats p
		ON p.rn <= s.rn
	GROUP BY s.concept_count,
		s.total,
		s.rn
	)
SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    o.time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	CASE 
		WHEN .50 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .50 * o.population_size THEN concept_count	END) 
		END AS median_value,
	CASE 
		WHEN .10 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .10 * o.population_size THEN concept_count	END) 
		END AS p10_value,		
	CASE 
		WHEN .25 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .25 * o.population_size THEN concept_count	END) 
		END AS p25_value,	
	CASE 
		WHEN .75 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .75 * o.population_size THEN concept_count	END) 
		END AS p75_value,	
	CASE 
		WHEN .90 * o.population_size < count_no_value THEN 0
		ELSE MIN(CASE WHEN p.accumulated + count_no_value >= .90 * o.population_size THEN concept_count	END) 
		END AS p90_value		
INTO @covariate_table
FROM prepStats2 p
CROSS JOIN overallStats o
{@included_cov_table != ''} ? {WHERE 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
GROUP BY 
{@temporal} ? {
    o.time_id,
}	
	o.count_value,
	o.count_no_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.population_size;
} : {
SELECT 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    time_id,
}	
	row_id,
	concept_count AS covariate_value 
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
{@temporal} ? {
{@distinct_concepts} ? {
	'@domain_table distinct concept count' AS covariate_name,
} : {
	'@domain_table concept count' AS covariate_name,
}
} : {
{@distinct_concepts} ? {
	'@domain_table distinct concept count during day @start_day through @end_day days relative to index' AS covariate_name,
} : {
	'@domain_table concept count during day @start_day through @end_day days relative to index' AS covariate_name,
}
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
	'@analysis_name' AS analysis_name,
	'@domain_id' AS domain_id,
{!@temporal} ? {
	NULL AS start_day,
	NULL AS end_day,
}
	'N' AS is_binary,
	'Y' AS missing_means_zero;	
