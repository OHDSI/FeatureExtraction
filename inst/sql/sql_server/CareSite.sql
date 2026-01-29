-- Feature construction
SELECT 
	CAST(care_site_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    CAST(NULL AS INT) AS time_id,
}		
{@temporal_sequence} ? {
    CAST(NULL AS INT) AS time_id,
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
	SELECT cohort.cohort_definition_id,
		cohort.@row_id_field AS row_id,
		CASE 
			WHEN visit_detail.care_site_id IS NOT NULL THEN visit_detail.care_site_id
			WHEN visit_occurrence.care_site_id IS NOT NULL THEN visit_occurrence.care_site_id
			ELSE person.care_site_id
		END AS care_site_id,
		ROW_NUMBER() OVER (PARTITION BY cohort_definition_id, cohort.@row_id_field ORDER BY visit_detail.visit_detail_end_date,  visit_occurrence.visit_end_date) AS rn
	FROM @cohort_table cohort
	INNER JOIN @cdm_database_schema.person
		ON cohort.subject_id = person.person_id
	LEFT JOIN @cdm_database_schema.visit_occurrence
		ON cohort.subject_id = visit_occurrence.person_id	
			AND visit_occurrence.visit_start_date <= cohort.cohort_start_date
			AND visit_occurrence.visit_end_date >= cohort.cohort_start_date
	LEFT JOIN @cdm_database_schema.visit_detail
		ON cohort.subject_id = visit_detail.person_id	
			AND visit_detail.visit_detail_start_date <= cohort.cohort_start_date
			AND visit_detail.visit_detail_end_date >= cohort.cohort_start_date
	WHERE NOT (person.care_site_id IS NULL 
		AND visit_occurrence.care_site_id IS NULL 
		AND visit_detail.care_site_id IS NULL
	)
{@cohort_definition_id != -1} ? {		AND cohort.cohort_definition_id IN (@cohort_definition_id)}
	) care_site
WHERE rn = 1
{@included_cov_table != ''} ? {	AND CAST(care_site_id AS BIGINT) * 1000 + @analysis_id IN (SELECT id FROM @included_cov_table)}	

{@aggregated} ? {		
GROUP BY cohort_definition_id,
	care_site_id
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
	CAST(CONCAT('care site ID = ', CAST((covariate_id - @analysis_id) / 1000 AS INT)) AS VARCHAR(512)) AS covariate_name,
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
	CAST('@analysis_name' AS VARCHAR(512)) AS analysis_name,
	CAST('@domain_id' AS VARCHAR(20)) AS domain_id,
{!@temporal} ? {
	CAST(NULL AS INT) AS start_day,
	CAST(NULL AS INT) AS end_day,
}
	CAST('Y' AS VARCHAR(1)) AS is_binary,
	CAST(NULL AS VARCHAR(1)) AS missing_means_zero;
