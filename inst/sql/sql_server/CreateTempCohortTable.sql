{DEFAULT @cdm_version == '4'}
{DEFAULT @cohort_ids == ''}
{DEFAULT @cohort_database_schema_table == '#cohort_temp'}

SELECT * 
INTO #cohort_for_covar_temp 
FROM @cohort_database_schema_table 
{cohort_ids != ''} ? {
{@cdm_version == '4'} ? {
WHERE cohort_concept_id IN (@cohort_ids)
} : {
WHERE cohort_definition_id IN (@cohort_ids)
}
}
;