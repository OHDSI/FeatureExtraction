# Copyright 2025 Observational Health Data Sciences and Informatics
#
# This file is part of FeatureExtraction
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This code should be used to fetch the data that is used in the cohort-based covariates vignette.  
library(FeatureExtraction)
library(SqlRender)
vignetteFolder <- "s:/temp/vignetteFeatureExtractionCohortBased"

# MDCD on RedShift
connectionDetails <- createConnectionDetails(dbms = "redshift",
                                             connectionString = keyring::key_get("redShiftConnectionStringOhdaMdcd"),
                                             user = keyring::key_get("redShiftUserName"),
                                             password = keyring::key_get("redShiftPassword"))
cdmDatabaseSchema <- "cdm_truven_mdcd_v1978"
cohortDatabaseSchema <- "scratch_mschuemi"
cohortTable <- "feature_extraction_cohort_based"
cdmVersion <- "5"


# Create cohorts -------------------------------------------------------
connection <- connect(connectionDetails)
sql <- readSql(system.file("sql", "sql_server", "covariateCohorts.sql", package = "FeatureExtraction"))
renderTranslateExecuteSql(connection = connection,
                          sql = sql,
                          cdm_database_schema = cdmDatabaseSchema,
                          cohort_database_schema = cohortDatabaseSchema,
                          cohort_table = cohortTable)

# Check number of subjects per cohort:
sql <- paste("SELECT cohort_definition_id, 
                COUNT(*) AS count",
             "FROM @cohort_database_schema.@cohort_table",
             "GROUP BY cohort_definition_id")
renderTranslateQuerySql(connection = connection,
                        sql = sql,
                        cohort_database_schema = cohortDatabaseSchema,
                        cohort_table = cohortTable)
disconnect(connection)


# Construct covariates -----------------------------------------------
covariateCohorts <- tibble(cohortId = 2,
                           cohortName = "Type 2 diabetes")

covariateSettings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                        covariateCohorts = covariateCohorts,
                                                        valueType = "binary",
                                                        startDay = -365,
                                                        endDay = 0)

covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                    cdmDatabaseSchema = cdmDatabaseSchema,
                                    cohortDatabaseSchema = cohortDatabaseSchema,
                                    cohortTable = cohortTable,
                                    cohortIds = c(1),
                                    rowIdField = "subject_id",
                                    covariateSettings = covariateSettings)

saveCovariateData(covariateData, file.path(vignetteFolder, "covariatesPerPerson"))
# covariateData <- loadCovariateData(file.path(vignetteFolder, "covariatesPerPerson"))
summary(covariateData)
covariateData$covariateRef


covariateSettings1 <- createCovariateSettings(useDemographicsGender = TRUE,
                                              useDemographicsAgeGroup = TRUE,
                                              useDemographicsRace = TRUE,
                                              useDemographicsEthnicity = TRUE,
                                              useDemographicsIndexYear = TRUE,
                                              useDemographicsIndexMonth = TRUE)

covariateCohorts <- tibble(cohortId = 2,
                           cohortName = "Type 2 diabetes")

covariateSettings2 <- createCohortBasedCovariateSettings(analysisId = 999,
                                                         covariateCohorts = covariateCohorts,
                                                         valueType = "binary",
                                                         startDay = -365,
                                                         endDay = 0)

covariateSettingsList <- list(covariateSettings1, covariateSettings2)

covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                    cdmDatabaseSchema = cdmDatabaseSchema,
                                    cohortDatabaseSchema = cohortDatabaseSchema,
                                    cohortTable = cohortTable,
                                    cohortIds = c(1),
                                    rowIdField = "subject_id",
                                    covariateSettings = covariateSettingsList,
                                    aggregated = TRUE)

saveCovariateData(covariateData, file.path(vignetteFolder, "covariatesAggregated"))
# covariateData <- loadCovariateData(file.path(vignetteFolder, "covariatesAggregated"))
summary(covariateData)

# Clean up ---------------------------------------------------------------------
connection <- connect(connectionDetails)
sql <- "DROP TABLE @cohort_database_schema.@cohort_table"
renderTranslateExecuteSql(connection = connection,
                          sql = sql,
                          cohort_database_schema = cohortDatabaseSchema,
                          cohort_table = cohortTable)
disconnect(connection)
