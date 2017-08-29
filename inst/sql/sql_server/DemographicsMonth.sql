-- Feature construction
SELECT MONTH(cohort_start_date) * 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    NULL AS time_id,
}	
{@aggregated} ? {
	COUNT(*) AS sum_value,
	COUNT(*) / (1.0 * (SELECT COUNT(*) FROM @cohort_table {@cohort_definition_id != -1} ? {WHERE cohort_definition_id = @cohort_definition_id})) AS average_value
} : {
	cohort.@row_id_field AS row_id,
	1 AS covariate_value 
}
INTO @covariate_table
FROM @cohort_table cohort
INNER JOIN @cdm_database_schema.person
	ON cohort.subject_id = person.person_id
{@included_cov_table != ''} ? {WHERE MONTH(cohort_start_date) * 1000 + @analysis_id IN (SELECT id FROM @included_cov_table}	
{@cohort_definition_id != -1} ? {
	{@included_cov_table != ''} ? {		AND} :{WHERE} cohort.cohort_definition_id = @cohort_definition_id
}
{@aggregated} ? {		
GROUP BY MONTH(cohort_start_date)
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
	CONCAT ('index month: ', CAST((covariate_id - @analysis_id) / 1000 AS VARCHAR)) AS covariate_name,
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
	'Y' AS is_binary,
	NULL AS missing_means_zero;
