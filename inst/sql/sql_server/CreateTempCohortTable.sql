/************************************************************************
Copyright 2017 Observational Health Data Sciences and Informatics

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
{DEFAULT @cohort_ids == ''}
{DEFAULT @cohort_database_schema_table == '#cohort_temp'}

SELECT * 
INTO #cohort_for_cov_temp 
FROM @cohort_database_schema_table 
{cohort_ids != ''} ? {
WHERE cohort_definition_id IN (@cohort_ids)
}
;
