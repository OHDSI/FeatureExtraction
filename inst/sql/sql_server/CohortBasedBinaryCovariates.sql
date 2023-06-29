-- Feature construction
SELECT 
	CAST(covariate_cohort_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
{@temporal | @temporal_sequence} ? {
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
	SELECT DISTINCT covariate_cohort.cohort_definition_id AS covariate_cohort_id,
{@temporal} ? {
		time_id,
}
{@temporal_sequence} ? {
		FLOOR(DATEDIFF(@time_part, covariate_cohort.cohort_start_date, cohort.cohort_start_date)*1.0/@time_interval ) as time_id,
}
{@aggregated} ? {
		cohort.cohort_definition_id,
		cohort.subject_id,
		cohort.cohort_start_date
} : {
		cohort.@row_id_field AS row_id
}
	FROM @cohort_table cohort
	INNER JOIN @covariate_cohort_table covariate_cohort
		ON cohort.subject_id = covariate_cohort.subject_id
	INNER JOIN #covariate_cohort_ref covariate_cohort_ref
		ON covariate_cohort.cohort_definition_id = covariate_cohort_ref.cohort_id
{@temporal} ? {
	INNER JOIN #time_period time_period
		ON covariate_cohort.cohort_start_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
	WHERE CASE WHEN covariate_cohort.cohort_end_date IS NULL THEN covariate_cohort.cohort_start_date ELSE covariate_cohort.cohort_end_date END  >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
} : {
	WHERE covariate_cohort.cohort_start_date <= DATEADD(DAY, {@temporal_sequence} ? {@sequence_end_day} : {@end_day}, cohort.cohort_start_date)
{@start_day != 'anyTimePrior'} ? {		
		AND CASE WHEN covariate_cohort.cohort_end_date IS NULL THEN covariate_cohort.cohort_start_date ELSE covariate_cohort.cohort_end_date END >= DATEADD(DAY, {@temporal_sequence} ? {@sequence_start_day} : {@start_day}, cohort.cohort_start_date)
}
}
{@included_cov_table != ''} ? {		AND CAST(covariate_cohort.cohort_definition_id AS BIGINT) * 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
) by_row_id
{@aggregated} ? {		
GROUP BY cohort_definition_id,
	covariate_cohort_id
{@temporal | @temporal_sequence} ? {
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
{@temporal | @temporal_sequence} ? {
	CAST(CONCAT('cohort: ', cohort_name) AS VARCHAR(512)) AS covariate_name,
} : {
{@start_day == 'anyTimePrior'} ? {
	CAST(CONCAT('cohort any time prior through @end_day days relative to index: ', cohort_name) AS VARCHAR(512)) AS covariate_name,
} : {
	CAST(CONCAT('cohort during day @start_day through @end_day days relative to index: ', cohort_name) AS VARCHAR(512)) AS covariate_name,
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
	CAST('Y' AS VARCHAR(1)) AS is_binary,
	CAST(NULL AS VARCHAR(1)) AS missing_means_zero;
