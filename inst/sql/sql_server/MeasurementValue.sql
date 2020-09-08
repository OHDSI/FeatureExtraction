IF OBJECT_ID('tempdb..#meas_cov', 'U') IS NOT NULL
	DROP TABLE #meas_cov;

SELECT DISTINCT measurement_concept_id,
  unit_concept_id,
  CAST((CAST(measurement_concept_id AS BIGINT) * 1000000) + ((unit_concept_id - (FLOOR(unit_concept_id / 1000) * 1000)) * 1000) + @analysis_id AS BIGINT) AS covariate_id
INTO #meas_cov
FROM @cdm_database_schema.measurement
WHERE value_as_number IS NOT NULL
{@excluded_concept_table != ''} ? {		AND measurement_concept_id NOT IN (SELECT id FROM @excluded_concept_table)}
{@included_concept_table != ''} ? {		AND measurement_concept_id IN (SELECT id FROM @included_concept_table)}
{@included_cov_table != ''} ? {		AND CAST((CAST(measurement_concept_id AS BIGINT) * 1000000) + ((unit_concept_id - (FLOOR(unit_concept_id / 1000) * 1000)) * 1000) + @analysis_id AS BIGINT) IN (SELECT id FROM @included_cov_table)}
; 

-- Feature construction
IF OBJECT_ID('tempdb..#meas_val_data', 'U') IS NOT NULL
	DROP TABLE #meas_val_data;
	
SELECT 
{@aggregated} ? {
		cohort_definition_id,
		subject_id,
		cohort_start_date,
} : {
		row_id,
}
{@temporal} ? {
    time_id,
}	
	covariate_id,
	value_as_number
INTO #meas_val_data
FROM (
	SELECT 
{@aggregated} ? {
		cohort_definition_id,
		subject_id,
		cohort_start_date,
{@temporal} ? {
		time_id,
		ROW_NUMBER() OVER (PARTITION BY cohort_definition_id, subject_id, cohort_start_date, measurement.measurement_concept_id, time_id ORDER BY measurement_date DESC, measurement.unit_concept_id, value_as_number) AS rn,
} : {
		ROW_NUMBER() OVER (PARTITION BY cohort_definition_id, subject_id, cohort_start_date, measurement.measurement_concept_id ORDER BY measurement_date DESC, measurement.unit_concept_id, value_as_number) AS rn,
}
} : {
		cohort.@row_id_field AS row_id,
{@temporal} ? {
		time_id,
		ROW_NUMBER() OVER (PARTITION BY cohort.@row_id_field, measurement.measurement_concept_id, time_id ORDER BY measurement_date DESC, measurement.unit_concept_id, value_as_number) AS rn,
} : {
		ROW_NUMBER() OVER (PARTITION BY cohort.@row_id_field, measurement.measurement_concept_id ORDER BY measurement_date DESC, measurement.unit_concept_id, value_as_number) AS rn,
}
}
		covariate_id,
		value_as_number
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.measurement
		ON cohort.subject_id = measurement.person_id
	INNER JOIN #meas_cov meas_cov
		ON meas_cov.measurement_concept_id = measurement.measurement_concept_id 
			AND meas_cov.unit_concept_id = measurement.unit_concept_id 
{@temporal} ? {
	INNER JOIN #time_period time_period
		ON measurement_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
		AND measurement_date >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
	WHERE measurement.measurement_concept_id != 0 
} : {
	WHERE measurement_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
{@start_day != 'anyTimePrior'} ? {				AND measurement_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)}
		AND measurement.measurement_concept_id != 0
}	
		AND value_as_number IS NOT NULL 			
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
) temp
WHERE rn = 1;	

{@aggregated} ? {
IF OBJECT_ID('tempdb..#meas_val_stats', 'U') IS NOT NULL
	DROP TABLE #meas_val_stats;

IF OBJECT_ID('tempdb..#meas_val_prep', 'U') IS NOT NULL
	DROP TABLE #meas_val_prep;

IF OBJECT_ID('tempdb..#meas_val_prep2', 'U') IS NOT NULL
	DROP TABLE #meas_val_prep2;

SELECT cohort_definition_id,
	covariate_id,
{@temporal} ? {
	time_id,
}
	MIN(value_as_number) AS min_value,
	MAX(value_as_number) AS max_value,
	CAST(AVG(value_as_number) AS FLOAT) AS average_value,
	CAST(STDEV(value_as_number) AS FLOAT) AS standard_deviation,
	COUNT(*) AS count_value
INTO #meas_val_stats
FROM #meas_val_data
GROUP BY cohort_definition_id,
{@temporal} ? {
	time_id,
}
	covariate_id;

SELECT cohort_definition_id,
	covariate_id,
{@temporal} ? {
	time_id,
}	
	value_as_number,
	COUNT(*) AS total,
	ROW_NUMBER() OVER (PARTITION BY cohort_definition_id, covariate_id ORDER BY value_as_number) AS rn
INTO #meas_val_prep
FROM #meas_val_data
GROUP BY cohort_definition_id,
	value_as_number,
{@temporal} ? {
	time_id,
}	
	covariate_id;
	
SELECT s.cohort_definition_id,
	s.covariate_id,
{@temporal} ? {
	s.time_id,
}	
	s.value_as_number,
	SUM(p.total) AS accumulated
INTO #meas_val_prep2	
FROM #meas_val_prep s
INNER JOIN #meas_val_prep p
	ON p.rn <= s.rn
		AND p.covariate_id = s.covariate_id
		AND p.cohort_definition_id = s.cohort_definition_id
GROUP BY s.cohort_definition_id,
	s.covariate_id,
{@temporal} ? {
	s.time_id,
}			
	s.value_as_number;
	
SELECT o.cohort_definition_id,
	o.covariate_id,
{@temporal} ? {
    o.time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	CAST(o.average_value AS FLOAT) average_value,
	CAST(o.standard_deviation AS FLOAT) standard_deviation,
	MIN(CASE WHEN p.accumulated >= .50 * o.count_value THEN value_as_number END) AS median_value,
	MIN(CASE WHEN p.accumulated >= .10 * o.count_value THEN value_as_number END) AS p10_value,
	MIN(CASE WHEN p.accumulated >= .25 * o.count_value THEN value_as_number END) AS p25_value,
	MIN(CASE WHEN p.accumulated >= .75 * o.count_value THEN value_as_number END) AS p75_value,
	MIN(CASE WHEN p.accumulated >= .90 * o.count_value THEN value_as_number END) AS p90_value	
INTO @covariate_table
FROM #meas_val_prep2 p
INNER JOIN #meas_val_stats o
	ON o.covariate_id = p.covariate_id
		AND o.cohort_definition_id = p.cohort_definition_id
{@temporal} ? {
		AND	o.time_id = p.time_id
}		
GROUP BY o.covariate_id,
{@temporal} ? {
    o.time_id,
}
	o.count_value,
	o.min_value,
	o.max_value,
	o.average_value,
	o.standard_deviation,
	o.cohort_definition_id;
} : {
SELECT covariate_id,
{@temporal} ? {
    time_id,
}	
	row_id,
	value_as_number AS covariate_value 
INTO @covariate_table
FROM #meas_val_data raw_data;
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
INNER JOIN #meas_cov covariate_ids
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

TRUNCATE TABLE #meas_cov;
DROP TABLE #meas_cov;
