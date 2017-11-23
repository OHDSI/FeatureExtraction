IF OBJECT_ID('tempdb..#covariate_ids', 'U') IS NOT NULL
	DROP TABLE #covariate_ids;

SELECT DISTINCT measurement_concept_id,
  unit_concept_id,
  (CAST(measurement_concept_id AS BIGINT) * 1000000) + ((unit_concept_id - (FLOOR(unit_concept_id / 1000) * 1000)) * 1000) + @analysis_id AS covariate_id
INTO #covariate_ids
FROM @cdm_database_schema.measurement
WHERE value_as_number IS NOT NULL; 

-- Feature construction
IF OBJECT_ID('tempdb..#raw_data', 'U') IS NOT NULL
	DROP TABLE #raw_data;
	
SELECT 
{@aggregated} ? {
		subject_id,
		cohort_start_date,
} : {
		row_id,
}
{@temporal} ? {
    time_id,
}	
	measurement_concept_id,
	unit_concept_id,
	value_as_number
INTO #raw_data
FROM (
	SELECT 
{@aggregated} ? {
		subject_id,
		cohort_start_date,
{@temporal} ? {
		time_id,
		ROW_NUMBER() OVER (PARTITION BY subject_id, cohort_start_date, measurement_concept_id, time_id ORDER BY measurement_date DESC) AS rn,
} : {
		ROW_NUMBER() OVER (PARTITION BY subject_id, cohort_start_date, measurement_concept_id ORDER BY measurement_date DESC) AS rn,
}
} : {
		cohort.@row_id_field AS row_id,
{@temporal} ? {
		time_id,
		ROW_NUMBER() OVER (PARTITION BY cohort.@row_id_field, measurement_concept_id, time_id ORDER BY measurement_date DESC) AS rn,
} : {
		ROW_NUMBER() OVER (PARTITION BY cohort.@row_id_field, measurement_concept_id ORDER BY measurement_date DESC) AS rn,
}
}
		measurement_concept_id,
		unit_concept_id,
		value_as_number
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.measurement
		ON cohort.subject_id = measurement.person_id
{@temporal} ? {
	INNER JOIN #time_period time_period
		ON measurement_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
		AND measurement_date >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
	WHERE measurement_concept_id != 0 
} : {
	WHERE measurement_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
{@start_day != 'anyTimePrior'} ? {				AND measurement_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)}
		AND measurement_concept_id != 0
}	
		AND value_as_number IS NOT NULL 			
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id = @cohort_definition_id}
) temp
WHERE rn = 1;	

{@aggregated} ? {
IF OBJECT_ID('tempdb..#overall_stats', 'U') IS NOT NULL
	DROP TABLE #overall_stats;

IF OBJECT_ID('tempdb..#prep_stats', 'U') IS NOT NULL
	DROP TABLE #prep_stats;

IF OBJECT_ID('tempdb..#prep_stats2', 'U') IS NOT NULL
	DROP TABLE #prep_stats2;

SELECT measurement_concept_id,
	unit_concept_id,
{@temporal} ? {
	time_id,
}
	MIN(value_as_number) AS min_value,
	MAX(value_as_number) AS max_value,
	AVG(value_as_number) AS average_value,
	STDEV(value_as_number) AS standard_deviation,
	COUNT(*) AS count_value
INTO #overall_stats
FROM #raw_data
GROUP BY measurement_concept_id,
{@temporal} ? {
	time_id,
}
	unit_concept_id;

SELECT measurement_concept_id,
	unit_concept_id,
{@temporal} ? {
	time_id,
}	
	value_as_number,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (PARTITION BY measurement_concept_id, unit_concept_id	ORDER BY value_as_number) AS rn
INTO #prep_stats
FROM #raw_data
GROUP BY value_as_number,
{@temporal} ? {
	time_id,
}	
	measurement_concept_id,
	unit_concept_id;
	
SELECT s.measurement_concept_id,
	s.unit_concept_id,
{@temporal} ? {
	s.time_id,
}	
	s.value_as_number,
	SUM(p.total) AS accumulated
INTO #prep_stats2	
FROM #prep_stats s
INNER JOIN #prep_stats p
	ON p.rn <= s.rn
GROUP BY s.measurement_concept_id,
	s.unit_concept_id,
{@temporal} ? {
	s.time_id,
}			
	s.value_as_number;
	
SELECT covariate_id,
{@temporal} ? {
    o.time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	MIN(CASE WHEN p.accumulated >= .50 * o.count_value THEN value_as_number END) AS median_value,
	MIN(CASE WHEN p.accumulated >= .10 * o.count_value THEN value_as_number END) AS p10_value,
	MIN(CASE WHEN p.accumulated >= .25 * o.count_value THEN value_as_number END) AS p25_value,
	MIN(CASE WHEN p.accumulated >= .75 * o.count_value THEN value_as_number END) AS p75_value,
	MIN(CASE WHEN p.accumulated >= .90 * o.count_value THEN value_as_number END) AS p90_value	
INTO @covariate_table
FROM #prep_stats2 p
INNER JOIN #overall_stats o
	ON o.measurement_concept_id = p.measurement_concept_id
		AND	o.unit_concept_id = p.unit_concept_id
{@temporal} ? {
		AND	o.time_id = p.time_id
}		
INNER JOIN #covariate_ids covariate_ids
	ON o.measurement_concept_id = covariate_ids.measurement_concept_id
		AND	o.unit_concept_id = covariate_ids.unit_concept_id
{@included_cov_table != ''} ? {WHERE covariate_id IN (SELECT id FROM @included_cov_table)}
GROUP BY covariate_id,
{@temporal} ? {
    o.time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation;
} : {
SELECT covariate_id,
{@temporal} ? {
    time_id,
}	
	row_id,
	value_as_number AS covariate_value 
INTO @covariate_table
FROM #raw_data raw_data
INNER JOIN #covariate_ids covariate_ids
	ON raw_data.measurement_concept_id = covariate_ids.measurement_concept_id
		AND	raw_data.unit_concept_id = covariate_ids.unit_concept_id	
{@included_cov_table != ''} ? {WHERE covariate_id IN (SELECT id FROM @included_cov_table)}
;
}

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT temp.covariate_id,
{@temporal} ? {
	CAST(CASE WHEN unit_concept.concept_id IS NULL OR unit_concept.concept_id = 0 THEN
		CONCAT('measurement value: ', CASE WHEN measurement_concept.concept_name IS NULL THEN 'Unknown concept' ELSE measurement_concept.concept_name END, ' (Unknown unit)')
	ELSE 	
		CONCAT('measurement value: ',  CASE WHEN measurement_concept.concept_name IS NULL THEN 'Unknown concept' ELSE measurement_concept.concept_name END, ' (', unit_concept.concept_name, ')')
	END AS VARCHAR(512)) AS covariate_name,
} : {
{@start_day == 'anyTimePrior'} ? {
	CAST(CASE WHEN unit_concept.concept_id = 0 THEN
		CONCAT('measurement value during any time prior through @end_day days relative to index: ', measurement_concept.concept_name, ' (Unknown unit)')
	ELSE 	
		CONCAT('measurement value during any time prior through @end_day days relative to index: ', measurement_concept.concept_name, ' (', unit_concept.concept_name, ')')
	END AS VARCHAR(512)) AS covariate_name,

} : {
	CAST(CASE WHEN unit_concept.concept_id = 0 THEN
		CONCAT('measurement value during day @start_day through @end_day days relative to index: ', measurement_concept.concept_name, ' (Unknown unit)')
	ELSE 	
		CONCAT('measurement value during day @start_day through @end_day days relative to index: ', measurement_concept.concept_name, ' (', unit_concept.concept_name, ')')
	END AS VARCHAR(512)) AS covariate_name,
}
}
	@analysis_id AS analysis_id,
	covariate_ids.measurement_concept_id AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) temp
INNER JOIN #covariate_ids covariate_ids
	ON covariate_ids.covariate_id = temp.covariate_id
LEFT JOIN @cdm_database_schema.concept measurement_concept
	ON covariate_ids.measurement_concept_id = measurement_concept.concept_id
LEFT JOIN @cdm_database_schema.concept unit_concept
	ON covariate_ids.unit_concept_id = unit_concept.concept_id;
	
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
	CAST('N' AS VARCHAR(1)) AS missing_means_zero;

TRUNCATE TABLE #covariate_ids;
DROP TABLE #covariate_ids;
