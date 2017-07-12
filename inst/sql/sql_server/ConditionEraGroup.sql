IF OBJECT_ID('tempdb..#condition_group', 'U') IS NOT NULL
	DROP TABLE #condition_group;

SELECT DISTINCT descendant_concept_id,
  ancestor_concept_id
INTO #condition_group
FROM @cdm_database_schema.concept_ancestor
INNER JOIN (
	SELECT concept_id
	FROM @cdm_database_schema.concept
	INNER JOIN @cdm_database_schema.concept_ancestor
	ON ancestor_concept_id = 441840 /* SNOMED clinical finding */
		AND concept_id = descendant_concept_id
	WHERE (min_levels_of_separation > 2
		OR concept_id IN (433736, 433595, 441408, 72404, 192671, 137977, 434621, 437312, 439847, 4171917, 438555, 4299449, 375258, 76784, 40483532, 4145627, 434157, 433778, 258449, 313878)
		) 
		AND LOWER(concept_name) NOT LIKE '%finding'
		AND LOWER(concept_name) NOT LIKE 'disorder of%'
		AND LOWER(concept_name) NOT LIKE 'finding of%'
		AND LOWER(concept_name) NOT LIKE 'disease of%'
		AND LOWER(concept_name) NOT LIKE 'injury of%'
		AND LOWER(concept_name) NOT LIKE '%by site'
		AND LOWER(concept_name) NOT LIKE '%by body site'
		AND LOWER(concept_name) NOT LIKE '%by mechanism'
		AND LOWER(concept_name) NOT LIKE '%of body region'
		AND LOWER(concept_name) NOT LIKE '%of anatomical site'
		AND LOWER(concept_name) NOT LIKE '%of specific body structure%'
		AND LOWER(domain_id) = 'condition'
{@has_excluded_covariate_concept_ids} ? {		AND concept_id NOT IN (SELECT concept_id FROM #excluded_cov)}
{@has_included_covariate_concept_ids} ? {		AND concept_id IN (SELECT concept_id FROM #included_cov)}
) valid_groups
	ON ancestor_concept_id = valid_groups.concept_id
WHERE ancestor_concept_id != descendant_concept_id
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
	INNER JOIN @cdm_database_schema.condition_era
		ON cohort.subject_id = condition_era.person_id
	INNER JOIN #condition_group
		ON condition_concept_id = descendant_concept_id
{@temporal} ? {
	INNER JOIN #time_period
		ON condition_era_start_date <= DATEADD(DAY, time_period.end_day, cohort.cohort_start_date)
		AND condition_era_end_date >= DATEADD(DAY, time_period.start_day, cohort.cohort_start_date)
	WHERE condition_concept_id != 0
} : {
	WHERE condition_era_start_date < DATEADD(DAY, @end_day, cohort.cohort_start_date)
		AND condition_era_end_date >= DATEADD(DAY, @start_day, cohort.cohort_start_date)
		AND condition_concept_id != 0
{@has_included_covariate_ids} ? {		AND CAST(ancestor_concept_id AS BIGINT) * 1000 + @analysis_id IN (SELECT covariate_id FROM #included_cov_by_id)}
}
) temp
{@aggregated} ? {		
GROUP BY ancestor_concept_id
{@temporal} ? {
    ,time_id
}	
}
;
TRUNCATE TABLE #condition_group;

DROP TABLE #condition_group;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
{@temporal} ? {
	CONCAT('Condition group era: ', concept_id, '-', concept_name) AS covariate_name,
} : {
	CONCAT('Condition group era during day @start_day through @end_day days relative to index: ', concept_id, '-', concept_name) AS covariate_name,
}
	@analysis_id AS analysis_id,
	concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1
INNER JOIN @cdm_database_schema.concept
	ON concept_id = CAST((covariate_id - @analysis_id) / 1000 AS INT);
