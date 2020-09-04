-- Feature construction
SELECT 
	CAST(ethnicity_concept_id  AS BIGINT) * 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}		
{@aggregated} ? {
	cohort_definition_id,
	COUNT(*) AS sum_value
} : {
	cohort.@row_id_field AS row_id,
	1 AS covariate_value 
}
INTO @covariate_table
FROM @cohort_table cohort
INNER JOIN @cdm_database_schema.person
	ON cohort.subject_id = person.person_id
WHERE ethnicity_concept_id  IN (
		SELECT concept_id
		FROM @cdm_database_schema.concept
		WHERE LOWER(concept_class_id) = 'ethnicity'
		)
{@excluded_concept_table != ''} ? {	AND ethnicity_concept_id  NOT IN (SELECT id FROM @excluded_concept_table)}
{@included_concept_table != ''} ? {	AND ethnicity_concept_id  IN (SELECT id FROM @included_concept_table)}	
{@included_cov_table != ''} ? {	AND CAST(ethnicity_concept_id  AS BIGINT) * 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}	
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
{@aggregated} ? {		
GROUP BY cohort_definition_id,
	ethnicity_concept_id 
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
	CAST(CONCAT('ethnicity = ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END) AS VARCHAR(512)) AS covariate_name,
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
	CAST(NULL AS INT) AS start_day,
	CAST(NULL AS INT) AS end_day,
}
	CAST('Y' AS VARCHAR(1)) AS is_binary,
	CAST(NULL AS VARCHAR(1)) AS missing_means_zero;
