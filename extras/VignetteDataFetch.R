# @file VignetteDataFetch.R
#
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

# This code should be used to fetch the data that is used in the vignettes.  
library(SqlRender)
library(DatabaseConnector)
library(FeatureExtraction)

# Datafetch for main vignette ----------------------------------

cdmDatabaseSchema <- "main"
resultsDatabaseSchema <- "main"
cohortsTable <- "#cohorts_of_interest"

vignetteFolder <- "c:/temp/vignetteFeatureExtraction"
if (!file.exists(vignetteFolder))
  dir.create(vignetteFolder, recursive = T, showWarnings = F)

options(andromedaTempFolder = vignetteFolder)
connectionDetails <- Eunomia::getEunomiaConnectionDetails()
connection <- DatabaseConnector::connect(connectionDetails)

sql <- "SELECT first_use.*
INTO @cohortsTable
FROM (
  SELECT drug_concept_id AS cohort_definition_id,
  	MIN(drug_era_start_date) AS cohort_start_date,
  	MIN(drug_era_end_date) AS cohort_end_date,
  	person_id AS subject_id
  FROM @cdmDatabaseSchema.drug_era
  WHERE drug_concept_id = 1118084-- celecoxib
    OR drug_concept_id = 1124300 --diclofenac
  GROUP BY drug_concept_id, 
    person_id
) first_use 
INNER JOIN @cdmDatabaseSchema.observation_period
  ON first_use.subject_id = observation_period.person_id
  AND cohort_start_date >= observation_period_start_date
  AND cohort_end_date <= observation_period_end_date
WHERE DATEDIFF(DAY, observation_period_start_date, cohort_start_date) >= 365;"
sql <- render(sql, cohortsTable = cohortsTable, cdmDatabaseSchema = cdmDatabaseSchema)
sql <- translate(sql, targetDialect = connectionDetails$dbms)
DatabaseConnector::executeSql(connection, sql)

# Check number of subjects per cohort:
sql <- paste("SELECT cohort_definition_id, COUNT(*) AS count",
             "FROM @cohortsTable",
             "GROUP BY cohort_definition_id")
sql <- render(sql, cohortsTable = cohortsTable)
sql <- translate(sql, targetDialect = connectionDetails$dbms)
DatabaseConnector::querySql(connection, sql)

covariateSettings <- createDefaultCovariateSettings()

covariateData <- getDbCovariateData(connection = connection,
                                    cdmDatabaseSchema = cdmDatabaseSchema,
                                    cohortDatabaseSchema = resultsDatabaseSchema,
                                    cohortTable = cohortsTable,
                                    cohortTableIsTemp = TRUE,
                                    cohortIds = c(1118084),
                                    rowIdField = "subject_id",
                                    covariateSettings = covariateSettings)

saveCovariateData(covariateData, file.path(vignetteFolder, "covariatesPerPerson"))
covariateData <- loadCovariateData(file.path(vignetteFolder, "covariatesPerPerson"))
summary(covariateData)

tidyCovariates <- tidyCovariateData(covariateData,
                                    normalize = TRUE,
                                    removeRedundancy = TRUE,
                                    minFraction = 0.001)
deletedCovariateIds <- attr(tidyCovariates, "metaData")$deletedRedundantCovariateIds
saveRDS(deletedCovariateIds, file.path(vignetteFolder, "deletedRedundantCovariateIds.rds"))
deletedCovariateIds <- attr(tidyCovariates, "metaData")$deletedInfrequentCovariateIds
saveRDS(deletedCovariateIds, file.path(vignetteFolder, "deletedInfrequentCovariateIds.rds"))

# aggCovariates <- aggregateCovariates(covariateData)

covariateSettings <- createDefaultCovariateSettings()

covariateData2 <- getDbCovariateData(connection = connection,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     cohortDatabaseSchema = resultsDatabaseSchema,
                                     cohortTable = cohortsTable,
                                     cohortTableIsTemp = TRUE,
                                     cohortIds = c(1118084),
                                     covariateSettings = covariateSettings,
                                     aggregated = TRUE)


saveCovariateData(covariateData2, file.path(vignetteFolder, "aggregatedCovariates"))
covariateData2 <- loadCovariateData(file.path(vignetteFolder, "aggregatedCovariates"))

result <- createTable1(covariateData2, output = "one column")

covariateSettings <- createTable1CovariateSettings()

covariateData2b <- getDbCovariateData(connection = connection,
                                      cdmDatabaseSchema = cdmDatabaseSchema,
                                      cohortDatabaseSchema = resultsDatabaseSchema,
                                      cohortTable = cohortsTable,
                                      cohortTableIsTemp = TRUE,
                                      cohortIds = c(1118084),
                                      covariateSettings = covariateSettings,
                                      aggregated = TRUE)

saveCovariateData(covariateData2b, file.path(vignetteFolder, "table1Covariates"))
covariateData2b <- loadCovariateData(file.path(vignetteFolder, "table1Covariates"))

result <- createTable1(covariateData2b, output = "one column")

covariateSettings <- createTable1CovariateSettings(excludedCovariateConceptIds = c(1118084, 1124300),
                                                   addDescendantsToExclude = TRUE)

covDiclofenac <- getDbCovariateData(connection = connection,
                                    cdmDatabaseSchema = cdmDatabaseSchema,
                                    cohortDatabaseSchema = resultsDatabaseSchema,
                                    cohortTable = cohortsTable,
                                    cohortTableIsTemp = TRUE,
                                    cohortIds = c(1124300),
                                    covariateSettings = covariateSettings,
                                    aggregated = TRUE)

saveCovariateData(covDiclofenac, file.path(vignetteFolder, "covDiclofenac"))

covCelecoxib <- getDbCovariateData(connection = connection,
                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                   cohortDatabaseSchema = resultsDatabaseSchema,
                                   cohortTable = cohortsTable,
                                   cohortTableIsTemp = TRUE,
                                   cohortIds = c(1118084),
                                   covariateSettings = covariateSettings,
                                   aggregated = TRUE)

saveCovariateData(covCelecoxib, file.path(vignetteFolder, "covCelecoxib"))

DatabaseConnector::disconnect(connection)
