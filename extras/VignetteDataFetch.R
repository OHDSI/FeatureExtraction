# @file VignetteDataFetch.R
#
# Copyright 2020 Observational Health Data Sciences and Informatics
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

dbms <- "pdw"
user <- NULL
pw <- NULL
server <- Sys.getenv("PDW_SERVER")
port <- Sys.getenv("PDW_PORT")
cdmDatabaseSchema <- "cdm_truven_mdcd_v569.dbo"
resultsDatabaseSchema <- "scratch.dbo"
cdmVersion <- "5"
extraSettings <- NULL

vignetteFolder <- "s:/temp/vignetteFeatureExtraction"
if (!file.exists(vignetteFolder))
  dir.create(vignetteFolder)


connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port,
                                                                extraSettings = extraSettings)
connection <- DatabaseConnector::connect(connectionDetails)

sql <- loadRenderTranslateSql("cohortsOfInterest.sql",
                              packageName = "FeatureExtraction",
                              dbms = dbms,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = resultsDatabaseSchema)
DatabaseConnector::executeSql(connection, sql)

# Check number of subjects per cohort:
sql <- paste("SELECT cohort_definition_id, COUNT(*) AS count",
             "FROM @resultsDatabaseSchema.cohorts_of_interest",
             "GROUP BY cohort_definition_id")
sql <- render(sql, resultsDatabaseSchema = resultsDatabaseSchema)
sql <- translate(sql, targetDialect = connectionDetails$dbms)
DatabaseConnector::querySql(connection, sql)

DatabaseConnector::disconnect(connection)

covariateSettings <- createDefaultCovariateSettings()

covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                    cdmDatabaseSchema = cdmDatabaseSchema,
                                    cohortDatabaseSchema = resultsDatabaseSchema,
                                    cohortTable = "cohorts_of_interest",
                                    cohortId = 1118084,
                                    rowIdField = "subject_id",
                                    covariateSettings = covariateSettings)

saveCovariateData(covariateData, file.path(vignetteFolder, "covariatesPerPerson"))
# covariateData <- loadCovariateData(file.path(vignetteFolder, "covariatesPerPerson"))
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

covariateData2 <- getDbCovariateData(connectionDetails = connectionDetails,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     cohortDatabaseSchema = resultsDatabaseSchema,
                                     cohortTable = "cohorts_of_interest",
                                     cohortId = 1118084,
                                     covariateSettings = covariateSettings,
                                     aggregated = TRUE)


saveCovariateData(covariateData2, file.path(vignetteFolder, "aggregatedCovariates"))

# covariateData2 <- loadCovariateData(file.path(vignetteFolder, "aggregatedCovariates"))

result <- createTable1(covariateData2)

covariateSettings <- createTable1CovariateSettings()

covariateData2b <- getDbCovariateData(connectionDetails = connectionDetails,
                                      cdmDatabaseSchema = cdmDatabaseSchema,
                                      cohortDatabaseSchema = resultsDatabaseSchema,
                                      cohortTable = "cohorts_of_interest",
                                      cohortId = 1118084,
                                      covariateSettings = covariateSettings,
                                      aggregated = TRUE)

saveCovariateData(covariateData2b, file.path(vignetteFolder, "table1Covariates"))

# covariateData2b <- loadCovariateData(file.path(vignetteFolder, "table1Covariates"))

result <- createTable1(covariateData2b)

covariateSettings <- createTable1CovariateSettings(excludedCovariateConceptIds = c(1118084, 1124300),
                                                   addDescendantsToExclude = TRUE)

covDiclofenac <- getDbCovariateData(connectionDetails = connectionDetails,
                                    cdmDatabaseSchema = cdmDatabaseSchema,
                                    cohortDatabaseSchema = resultsDatabaseSchema,
                                    cohortTable = "cohorts_of_interest",
                                    cohortId = 1124300,
                                    covariateSettings = covariateSettings,
                                    aggregated = TRUE)

saveCovariateData(covDiclofenac, file.path(vignetteFolder, "covDiclofenac"))

covCelecoxib <- getDbCovariateData(connectionDetails = connectionDetails,
                                   cdmDatabaseSchema = cdmDatabaseSchema,
                                   cohortDatabaseSchema = resultsDatabaseSchema,
                                   cohortTable = "cohorts_of_interest",
                                   cohortId = 1118084,
                                   covariateSettings = covariateSettings,
                                   aggregated = TRUE)

saveCovariateData(covCelecoxib, file.path(vignetteFolder, "covCelecoxib"))

covCelecoxib <- loadCovariateData(file.path(vignetteFolder, "covCelecoxib"))
covDiclofenac <- loadCovariateData(file.path(vignetteFolder, "covDiclofenac"))

std <- computeStandardizedDifference(covCelecoxib, covDiclofenac)
head(std)
result <- createTable1(covCelecoxib, covDiclofenac)

covariateData1 <- covCelecoxib 
covariateData2 <- covDiclofenac 
specifications = getDefaultTable1Specifications()
output <- "two columns"

covariateData2 <- loadCovariateData(file.path(vignetteFolder, "aggregatedCovariates"))
x <- dplyr::collect(covariateData2$covariates)
total <- sum(x$sumValue)
sum(x$sumValue[x$sumValue < 100]) / total
x <- merge(x, dplyr::collect(covariateData2$covariateRef))
x <- x[order(-x$sumValue), ]

# Tests for custom covariate builders ----------------------------

createLooCovariateSettings <- function(useLengthOfObs = TRUE) {
  covariateSettings <- list(useLengthOfObs = useLengthOfObs)
  attr(covariateSettings, "fun") <- "getDbLooCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}


getDbLooCovariateData <- function(connection,
                                  oracleTempSchema = NULL,
                                  cdmDatabaseSchema,
                                  cohortTable = "#cohort_person",
                                  cohortId = -1,
                                  cdmVersion = "5",
                                  rowIdField = "subject_id",
                                  covariateSettings,
                                  aggregated = FALSE) {
  writeLines("Constructing length of observation covariates")
  if (covariateSettings$useLengthOfObs == FALSE) {
    return(NULL)
  }
  if (aggregated)
    stop("Aggregation not supported")
  
  # Some SQL to construct the covariate:
  sql <- paste("SELECT @row_id_field AS row_id, 1 AS covariate_id,",
               "DATEDIFF(DAY, observation_period_start_date, cohort_start_date)",
               "AS covariate_value",
               "FROM @cohort_table c",
               "INNER JOIN @cdm_database_schema.observation_period op",
               "ON op.person_id = c.subject_id",
               "WHERE cohort_start_date >= observation_period_start_date",
               "AND cohort_start_date <= observation_period_end_date",
               "{@cohort_id != -1} ? {AND cohort_definition_id = @cohort_id}")
  sql <- SqlRender::render(sql,
                           cohort_table = cohortTable,
                           cohort_id = cohortId,
                           row_id_field = rowIdField,
                           cdm_database_schema = cdmDatabaseSchema)
  sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
  
  # Retrieve the covariate:
  covariates <- DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE)
  
  # Construct covariate reference:
  covariateRef <- data.frame(covariateId = 1,
                             covariateName = "Length of observation",
                             analysisId = 1,
                             conceptId = 0)

  # Construct analysis reference:
  analysisRef <- data.frame(analysisId = 1,
                            analysisName = "Length of observation",
                            domainId = "Demographics",
                            startDay = 0,
                            endDay = 0,
                            isBinary = "N",
                            missingMeansZero = "Y")

  # Construct analysis reference:
  metaData <- list(sql = sql, call = match.call())
  result <- Andromeda::andromeda(covariates = covariates, 
                 covariateRef = covariateRef, 
                 analysisRef = analysisRef)
  attr(result, "metaData") <- metaData
  class(result) <- "CovariateData"
  return(result)
}

looCovSet <- createLooCovariateSettings(useLengthOfObs = TRUE)

covariates <- getDbCovariateData(connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = resultsDatabaseSchema,
                                 cohortTable = "rehospitalization",
                                 cohortId = 1,
                                 covariateSettings = looCovSet)

aggCovs <- aggregateCovariates(covariates)

covariateSettings <- createCovariateSettings(useDemographicsGender = TRUE,
                                             useDemographicsAgeGroup = TRUE,
                                             useDemographicsRace = TRUE,
                                             useDemographicsEthnicity = TRUE,
                                             useDemographicsIndexYear = TRUE,
                                             useDemographicsIndexMonth = TRUE)

looCovSet <- createLooCovariateSettings(useLengthOfObs = TRUE)

covariateSettingsList <- list(covariateSettings, looCovSet)

covariates <- getDbCovariateData(connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = resultsDatabaseSchema,
                                 cohortTable = "rehospitalization",
                                 cohortId = 1,
                                 covariateSettings = covariateSettingsList)
covariates$analysisRef



# Tests for code in cohort attribute covariate builder -------------------------------

library(SqlRender)
library(DatabaseConnector)
library(FeatureExtraction)

dbms <- "pdw"
user <- NULL
pw <- NULL
server <- Sys.getenv("PDW_SERVER")
port <- Sys.getenv("PDW_PORT")
cdmDatabaseSchema <- "cdm_truven_mdcd_v569.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cdmVersion <- "5"
extraSettings <- NULL

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
connection <- DatabaseConnector::connect(connectionDetails)

# Build cohorts:
sql <- SqlRender::loadRenderTranslateSql("HospitalizationCohorts.sql",
                                         packageName = "PatientLevelPrediction",
                                         dbms = dbms,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         resultsDatabaseSchema = cohortDatabaseSchema,
                                         post_time = 30,
                                         pre_time = 365)
DatabaseConnector::executeSql(connection, sql)

# Build cohort attributes:
sql <- SqlRender::loadRenderTranslateSql("LengthOfObsCohortAttr.sql",
                                         packageName = "FeatureExtraction",
                                         dbms = dbms,
                                         cdm_database_schema = cdmDatabaseSchema,
                                         cohort_database_schema = cohortDatabaseSchema,
                                         cohort_table = "rehospitalization",
                                         cohort_attribute_table = "loo_cohort_attribute",
                                         attribute_definition_table = "loo_attribute_definition",
                                         cohort_definition_ids = c(1, 2))
DatabaseConnector::executeSql(connection, sql)


querySql(connection, "SELECT TOP 100 * FROM scratch.dbo.loo_cohort_attribute")

looCovSet <- createCohortAttrCovariateSettings(attrDatabaseSchema = cohortDatabaseSchema,
                                               cohortAttrTable = "loo_cohort_attribute",
                                               attrDefinitionTable = "loo_attribute_definition",
                                               includeAttrIds = c(),
                                               isBinary = FALSE,
                                               missingMeansZero = FALSE)

covariates <- getDbCovariateData(connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 cohortTable = "rehospitalization",
                                 cohortId = 1,
                                 covariateSettings = looCovSet)
summary(covariates)

aggCovs <- aggregateCovariates(covariates)

covariateSettings <- createCovariateSettings(useDemographicsGender = TRUE,
                                             useDemographicsAgeGroup = TRUE,
                                             useDemographicsRace = TRUE,
                                             useDemographicsEthnicity = TRUE,
                                             useDemographicsIndexYear = TRUE,
                                             useDemographicsIndexMonth = TRUE)
looCovSet <- createCohortAttrCovariateSettings(attrDatabaseSchema = cohortDatabaseSchema,
                                               cohortAttrTable = "loo_cohort_attribute",
                                               attrDefinitionTable = "loo_attribute_definition",
                                               includeAttrIds = c())
covariateSettingsList <- list(covariateSettings, looCovSet)

covariates <- getDbCovariateData(connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 cohortTable = "rehospitalization",
                                 cohortId = 1,
                                 covariateSettings = covariateSettingsList)


sql <- "DROP TABLE @cohort_database_schema.rehospitalization"
sql <- SqlRender::render(sql, cohort_database_schema = cohortDatabaseSchema)
sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
DatabaseConnector::executeSql(connection, sql)
DatabaseConnector::disconnect(connection)
