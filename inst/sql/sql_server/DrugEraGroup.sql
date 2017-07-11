IF OBJECT_ID('tempdb..#drug_group', 'U') IS NOT NULL
	DROP TABLE #drug_group;

SELECT DISTINCT descendant_concept_id,
  ancestor_concept_id
INTO #drug_group
FROM @cdm_database_schema.concept_ancestor
INNER JOIN @cdm_database_schema.concept
	ON ancestor_concept_id = concept_id
WHERE LOWER(vocabulary_id) = 'atc'
	AND LEN(concept_code) IN (1, 3, 4, 5)
	AND concept_id != 0
{@has_excluded_covariate_concept_ids} ? {	AND descendant_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND descendant_concept_id IN (SELECT concept_id FROM #included_cov)}
{@has_excluded_covariate_concept_ids} ? {	AND ancestor_concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {	AND ancestor_concept_id IN (SELECT concept_id FROM #included_cov)}
;

-- Feature construction
{!@aggregated} ? {--HINT DISTRIBUTE_ON_KEY(row_id)}
SELECT 
	CAST(ancestor_concept_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    time_id,
}	
{@aggregated} ? {
	COUNT(*) AS sum_value,
	CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM @cohort_table) THEN 1 ELSE 0 END AS min_value,
	1 AS max_value,
	COUNT(*) / (1.0 * (SELECT COUNT(*) FROM @cohort_table)) AS average_value,
	SQRT((COUNT(*) / (1.0 * (SELECT COUNT(*) FROM @cohort_table)))*(1 - (COUNT(*) / (1.0 * (SELECT COUNT(*) FROM @cohort_table))))/(1.0 * (SELECT COUNT(*) FROM @cohort_table)))  AS standard_deviation
} : {
	row_id,
	1 AS covariate_value 
}
INTO @covariate_table
FROM (
	SELECT DISTINCT cohort.@row_id_field AS row_id,
{@temporal} ? {
		time_id,
}	
		ancestor_concept_id
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.drug_era
		ON cohort.subject_id = drug_era.person_id
	INNER JOIN #drug_group
		ON drug_concept_id = descendant_concept_id
{@temporal} ? {
	INNER JOIN #time_period
		ON drug_era_start_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
		AND drug_era_end_date >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
	WHERE drug_concept_id != 0
} : {
	WHERE drug_era_start_date < DATEADD(DAY, @end_day, cohort.cohort_start_date)
		AND drug_era_end_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)
		AND drug_concept_id != 0
}
{@has_included_covariate_ids} ? {		AND CAST(ancestor_concept_id AS BIGINT) * 1000 + @analysis_id IN (SELECT concept_id FROM #included_cov_by_id)}
) temp
{@aggregated} ? {		
GROUP BY ancestor_concept_id
{@temporal} ? {
    ,time_id
}	
}
;
TRUNCATE TABLE #drug_group;

DROP TABLE #drug_group;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
{@temporal} ? {
	CONCAT('Drug group era: ', concept_id, '-', concept_name) AS covariate_name,
} : {
	CONCAT('Drug group era during day @start_day through @end_day days relative to index: ', concept_id, '-', concept_name) AS covariate_name,
}
	@analysis_id AS analysis_id,
	concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1
INNER JOIN @cdm_database_schema.concept
	ON concept_id = CAST((covariate_id - @analysis_id) / 1000 AS INT);
