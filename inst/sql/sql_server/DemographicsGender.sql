-- Feature construction
SELECT 
	CAST(gender_concept_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
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
WHERE gender_concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND gender_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND gender_concept_id IN (SELECT concept_id FROM #included_cov)}	
{@aggregated} ? {		
GROUP BY gender_concept_id
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
	CONCAT('Gender = ', concept_name) AS covariate_name,
	@analysis_id AS analysis_id,
	concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1
INNER JOIN @cdm_database_schema.concept
	ON concept_id = CAST((covariate_id - @analysis_id) / 1000 AS INT);
