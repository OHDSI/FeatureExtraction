/************************************************************************
Copyright 2021 Observational Health Data Sciences and Informatics

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
{DEFAULT @table_name == '#include_concepts'}
{DEFAULT @cdm_database_schema == 'cdm'}

INSERT INTO @table_name (concept_id)
SELECT descendant_concept_id 
FROM @table_name this_table
INNER JOIN @cdm_database_schema.concept_ancestor
ON concept_id = ancestor_concept_id
WHERE concept_id != descendant_concept_id;
