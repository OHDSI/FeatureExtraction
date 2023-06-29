/************************************************************************
@file GetAttrCovariates.sql

Copyright 2023 Observational Health Data Sciences and Informatics

This file is part of FeatureExtraction

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
************************************************************************/

{DEFAULT @attr_database_schema = 'CDM_SIM.dbo' } 
{DEFAULT @cohort_table = '#cohort_person'}
{DEFAULT @cohort_id = -1}
{DEFAULT @row_id_field = 'person_id'}
{DEFAULT @cohort_attribute_table = 'cohort_attribute'} 
{DEFAULT @has_include_attr_ids = FALSE} 

SELECT cohort.@row_id_field AS row_id,
  cohort_attribute.attribute_definition_id AS covariate_id,
  cohort_attribute.value_as_number AS covariate_value
FROM @attr_database_schema.@cohort_attribute_table cohort_attribute
INNER JOIN @cohort_table cohort
ON cohort_attribute.subject_id = cohort.subject_id
AND cohort_attribute.cohort_definition_id = cohort.cohort_definition_id
AND cohort_attribute.subject_id = cohort.subject_id
{@has_include_attr_ids} ? {
INNER JOIN #included_attr included_attr
ON included_attr.attribute_definition_id = cohort_attribute.attribute_definition_id
}
{@cohort_id != -1} ? {
WHERE cohort.cohort_definition_id = @cohort_id
}
;
