IF OBJECT_ID('tempdb..#covariate_ids', 'U') IS NOT NULL
	DROP TABLE #covariate_ids;

SELECT DISTINCT measurement_concept_id,
  unit_concept_id,
  (measurement_concept_id * 1000000) + ((unit_concept_id % 1000) * 1000) + @analysis_id AS covariate_id
INTO #covariate_ids
FROM @cdm_database_schema.measurement
WHERE value_as_number IS NOT NULL; 

-- Feature construction
WITH rawData (
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
	)
AS (
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
			row_id,
{@temporal} ? {
			time_id,
			ROW_NUMBER() OVER (PARTITION BY row_id, measurement_concept_id, time_id ORDER BY measurement_date DESC) AS rn,
} : {
			ROW_NUMBER() OVER (PARTITION BY row_id, measurement_concept_id ORDER BY measurement_date DESC) AS rn,
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
			AND measurement_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)
			AND measurement_concept_id != 0
}	
			AND value_as_number IS NOT NULL 			
{@cohort_definition_id != -1} ? {			AND cohort.cohort_definition_id = @cohort_definition_id}
	) temp
	WHERE rn = 1
)
{@aggregated} ? {
, overallStats (
	measurement_concept_id,
	unit_concept_id,
{@temporal} ? {
    time_id,
}	
	min_value,
	max_value,
	average_value,
	standard_deviation,
	count_value
	)
AS (
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
	FROM rawData
	GROUP BY measurement_concept_id,
		unit_concept_id
{@temporal} ? {
		,time_id
}		
	),
prepStats (
	measurement_concept_id,
	unit_concept_id,
{@temporal} ? {
		time_id,
}	
	value_as_number,
	total,
	rn
	)
AS (
	SELECT measurement_concept_id,
		unit_concept_id,
	{@temporal} ? {
		time_id,
	}	value_as_number,
		COUNT(*) AS total,
		ROW_NUMBER() OVER (PARTITION BY measurement_concept_id, unit_concept_id	ORDER BY value_as_number) AS rn
	FROM rawData
	GROUP BY value_as_number,
{@temporal} ? {
		time_id,
}	
		measurement_concept_id,
		unit_concept_id
	),
prepStats2 (
	measurement_concept_id,
	unit_concept_id,
{@temporal} ? {
	time_id,
}	
	value_as_number,
	total,
	accumulated
	)
AS (
	SELECT s.measurement_concept_id,
		s.unit_concept_id,
{@temporal} ? {
		s.time_id,
}	
		s.value_as_number,
		s.total,
		SUM(p.total) AS accumulated
	FROM prepStats s
	INNER JOIN prepStats p
		ON p.rn <= s.rn
	GROUP BY s.measurement_concept_id,
		s.unit_concept_id,
{@temporal} ? {
		s.time_id,
}			
		s.value_as_number,
		s.total,
		s.rn		
	)
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
FROM prepStats2 p
INNER JOIN overallStats o
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
FROM rawData
INNER JOIN #covariate_ids covariate_ids
	ON rawData.measurement_concept_id = covariate_ids.measurement_concept_id
		AND	rawData.unit_concept_id = covariate_ids.unit_concept_id	
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
	CASE WHEN unit_concept.concept_id = 0 THEN
		CONCAT('measurement value: ', measurement_concept.concept_id, '-', measurement_concept.concept_name, ' (Unknown unit)')
	ELSE 	
		CONCAT('measurement value: ', measurement_concept.concept_id, '-', measurement_concept.concept_name, ' (', unit_concept.concept_name, ')')
	END AS covariate_name,
} : {
	CASE WHEN unit_concept.concept_id = 0 THEN
		CONCAT('measurement value during day @start_day through @end_day days relative to index: ', measurement_concept.concept_id, '-', measurement_concept.concept_name, ' (Unknown unit)')
	ELSE 	
		CONCAT('measurement value during day @start_day through @end_day days relative to index: ', measurement_concept.concept_id, '-', measurement_concept.concept_name, ' (', unit_concept.concept_name, ')')
	END AS covariate_name,
}
	@analysis_id AS analysis_id,
	covariate_ids.measurement_concept_id AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) temp
INNER JOIN #covariate_ids covariate_ids
	ON covariate_ids.covariate_id = temp.covariate_id
INNER JOIN @cdm_database_schema.concept measurement_concept
	ON covariate_ids.measurement_concept_id = measurement_concept.concept_id
INNER JOIN @cdm_database_schema.concept unit_concept
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
	'@analysis_name' AS analysis_name,
	'@domain_id' AS domain_id,
{!@temporal} ? {
	NULL AS start_day,
	NULL AS end_day,
}
	'N' AS is_binary,
	'N' AS missing_means_zero;	

TRUNCATE TABLE #covariate_ids;
DROP TABLE #covariate_ids;