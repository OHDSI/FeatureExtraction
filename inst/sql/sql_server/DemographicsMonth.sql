-- Feature construction
{!@aggregated} ? {--HINT DISTRIBUTE_ON_KEY(row_id)}
SELECT MONTH(cohort_start_date) * 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    NULL AS time_id,
}	
{@aggregated} ? {
	COUNT(*) AS covariate_value
} : {
	cohort.@row_id_field AS row_id,
	1 AS covariate_value 
}
INTO @covariate_table
FROM @cohort_table cohort
INNER JOIN @cdm_database_schema.person
	ON cohort.subject_id = person.person_id
{@has_excluded_covariate_concept_ids} ? {}
{@has_included_covariate_concept_ids} ? {}
{@has_included_covariate_ids} ? {WHERE MONTH(cohort_start_date) * 1000 + @analysis_id IN (SELECT concept_id FROM #included_cov_by_id)}	
{@aggregated} ? {		
GROUP BY MONTH(cohort_start_date)
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
	CONCAT ('Index month: ', CAST((covariate_id - @analysis_id) / 1000 AS VARCHAR)) AS covariate_name,
	@analysis_id AS analysis_id,
	0 AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1;
