-- Feature construction
SELECT 
	(CAST(measurement_concept_id AS BIGINT) * 10000) + (range_group * 1000) + @analysis_id AS covariate_id,
{@temporal} ? {
    time_id,
}	
{@aggregated} ? {
	cohort_definition_id,
	COUNT(*) AS sum_value
} : {
	row_id,
	1 AS covariate_value 
}
INTO @covariate_table
FROM (
{@aggregated} ? {
	SELECT DISTINCT measurement_concept_id,
		range_group,		
{@temporal} ? {
		time_id,
}	
		cohort_definition_id,
		subject_id,
		cohort_start_date
    FROM (      
}
	SELECT measurement_concept_id,
		CASE 
			WHEN value_as_number < range_low THEN 1
			WHEN value_as_number > range_high THEN 3
			ELSE 2
		END AS range_group,		
{@temporal} ? {
		time_id,
}	
{@aggregated} ? {
		cohort_definition_id,
		cohort.subject_id,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}
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
		AND range_low IS NOT NULL
		AND range_high IS NOT NULL
{@excluded_concept_table != ''} ? {		AND measurement_concept_id NOT IN (SELECT id FROM @excluded_concept_table)}
{@included_concept_table != ''} ? {		AND measurement_concept_id IN (SELECT id FROM @included_concept_table)}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
{@aggregated} ? {
	)  grouped_1
}
) grouped_2
{@included_cov_table != ''} ? {WHERE (CAST(measurement_concept_id AS BIGINT) * 10000) + (range_group * 1000) + @analysis_id IN (SELECT id FROM @included_cov_table)}
GROUP BY measurement_concept_id,
	range_group
{@aggregated} ? {		
	,cohort_definition_id
} : {
	,row_id
} 
{@temporal} ? {
    ,time_id
} 
;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
{@temporal} ? {
	CAST(CONCAT('measurement ', range_name, ': ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END) AS VARCHAR(512)) AS covariate_name,
} : {
{@start_day == 'anyTimePrior'} ? {
	CAST(CONCAT('measurement ', range_name, ' during any time prior through @end_day days relative to index: ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END) AS VARCHAR(512)) AS covariate_name,
} : {
	CAST(CONCAT('measurement ', range_name, ' during day @start_day through @end_day days relative to index: ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END) AS VARCHAR(512)) AS covariate_name,
}
}
	@analysis_id AS analysis_id,
	CAST(FLOOR(covariate_id / 10000.0) AS INT) AS concept_id
FROM (
	SELECT DISTINCT covariate_id,
	   CASE 
			WHEN FLOOR(covariate_id / 1000.0) - (FLOOR(covariate_id / 10000.0) * 10) = 1 THEN 'below normal range'
			WHEN FLOOR(covariate_id / 1000.0) - (FLOOR(covariate_id / 10000.0) * 10) = 2 THEN 'within normal range'
			WHEN FLOOR(covariate_id / 1000.0) - (FLOOR(covariate_id / 10000.0) * 10) = 3 THEN 'above normal range'
	  END AS range_name
	FROM @covariate_table
	) t1
LEFT JOIN @cdm_database_schema.concept
	ON concept_id = FLOOR(covariate_id / 10000.0);
	
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
{@start_day == 'anyTimePrior'} ? {
	CAST(NULL AS INT) AS start_day,
} : {
	@start_day AS start_day,
}
	@end_day AS end_day,
}
	CAST('Y' AS VARCHAR(1)) AS is_binary,
	CAST(NULL AS VARCHAR(1)) AS missing_means_zero;

