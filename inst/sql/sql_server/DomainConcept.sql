-- Feature construction
SELECT 
	CAST(@domain_concept_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
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
	SELECT DISTINCT @domain_concept_id,
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
	INNER JOIN @cdm_database_schema.@domain_table
		ON cohort.subject_id = @domain_table.person_id
{@temporal} ? {
	INNER JOIN #time_period time_period
		ON @domain_start_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
		AND @domain_end_date >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
	WHERE @domain_concept_id != 0
} : {
	WHERE @domain_start_date <= DATEADD(DAY, @end_day, cohort.cohort_start_date)
{@start_day != 'anyTimePrior'} ? {		AND @domain_end_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)}
		AND @domain_concept_id != 0
}
{@sub_type == 'inpatient'} ? {	AND condition_type_concept_id IN (38000183, 38000184, 38000199, 38000200)}
{@excluded_concept_table != ''} ? {		AND @domain_concept_id NOT IN (SELECT id FROM @excluded_concept_table)}
{@included_concept_table != ''} ? {		AND @domain_concept_id IN (SELECT id FROM @included_concept_table)}
{@included_cov_table != ''} ? {		AND CAST(@domain_concept_id AS BIGINT) * 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
) by_row_id
{@aggregated} ? {		
GROUP BY cohort_definition_id,
	@domain_concept_id
{@temporal} ? {
    ,time_id
} 
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
	CAST(CONCAT('@domain_table: ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END {@sub_type == 'inpatient'} ? {, ' (inpatient)'}) AS VARCHAR(512)) AS covariate_name,
} : {
{@start_day == 'anyTimePrior'} ? {
	CAST(CONCAT('@domain_table any time prior through @end_day days relative to index: ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END {@sub_type == 'inpatient'} ? {, ' (inpatient)'}) AS VARCHAR(512)) AS covariate_name,
} : {
	CAST(CONCAT('@domain_table during day @start_day through @end_day days relative to index: ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END {@sub_type == 'inpatient'} ? {, ' (inpatient)'}) AS VARCHAR(512)) AS covariate_name,
}
}
	@analysis_id AS analysis_id,
	CAST((covariate_id - @analysis_id) / 1000 AS INT) AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1
LEFT JOIN @cdm_database_schema.concept
	ON concept_id = CAST((covariate_id - @analysis_id) / 1000 AS INT);
	
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

