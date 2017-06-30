-- Feature construction
SELECT FLOOR((YEAR(cohort_start_date) - p1.YEAR_OF_BIRTH) / 5) * 1000 + @analysis_id AS covariate_id,
{@temporal} ? {
    NULL AS time_id,
}	
{@aggregated} ? {
	COUNT(*) AS covariate_value
} : {
	cohort.@row_id_field AS row_id,
	1 AS covariate_value 
}
FROM @cohort_table cohort
INNER JOIN @cdm_database_schema.person
	ON cohort.subject_id = person.person_id
{@aggregated} ? {		
GROUP BY FLOOR((YEAR(cohort_start_date) - p1.YEAR_OF_BIRTH) / 5)
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
	CONCAT (
		'Age group: ',
		CAST(5 * (covariate_id - @analysis_id) / 1000 AS VARCHAR),
		'-',
		CAST(1 + 5 * (covariate_id - @analysis_id) / 1000 AS VARCHAR)
		) AS covariate_name,
	@analysis_id AS analysis_id,
	0 AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1;
