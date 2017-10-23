# @file VignetteDataFetch.R
#
# Copyright 2017 Observational Health Data Sciences and Informatics
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
options(fftempdir = "c:/FFtemp")

dbms <- "pdw"
user <- NULL
pw <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "cdm_truven_mdcd_v569.dbo"
resultsDatabaseSchema <- "scratch.dbo"
port <- 17001
cdmVersion <- "5"
extraSettings <- NULL

vignetteFolder <- "c:/temp/vignetteFeatureExtraction"
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
sql <- renderSql(sql, resultsDatabaseSchema = resultsDatabaseSchema)$sql
sql <- translateSql(sql, targetDialect = connectionDetails$dbms)$sql
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
deletedCovariateIds <- tidyCovariates$metaData$deletedRedundantCovariateIds
saveRDS(deletedCovariateIds, file.path(vignetteFolder, "deletedRedundantCovariateIds.rds"))
deletedCovariateIds <- tidyCovariates$metaData$deletedInfrequentCovariateIds
saveRDS(deletedCovariateIds, file.path(vignetteFolder, "deletedInfrequentCovariateIds.rds"))
# deletedCovariateIds <- readRDS(file.path(vignetteFolder, "deletedCovariateIds.rds"))

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

# some counting ------------------------
covariateData2 <- loadCovariateData(file.path(vignetteFolder, "aggregatedCovariates"))
x <- ff::as.ram(covariateData2$covariates)
total <- sum(x$sumValue)
sum(x$sumValue[x$sumValue < 100]) / total
x <- merge(x, ff::as.ram(covariateData2$covariateRef))
x <- x[order(-x$sumValue), ]

#### Datafetch for custom covariate builders #####

createLooCovariateSettings <- function(useLengthOfObs = TRUE) {
  covariateSettings <- list(useLengthOfObs = useLengthOfObs)
  attr(covariateSettings, "fun") <- "getDbLooCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}


getDbLooCovariateData <- function(connection,
                                  oracleTempSchema = NULL,
                                  cdmDatabaseSchema,
                                  cdmVersion = "4",
                                  cohortTempTable = "cohort_person",
                                  rowIdField = "subject_id",
                                  covariateSettings) {
  writeLines("Constructing length of observation covariates")
  if (covariateSettings$useLengthOfObs == FALSE) {
    return(NULL)
  }

  # Temp table names must start with a '#' in SQL Server, our source dialect:
  if (substr(cohortTempTable, 1, 1) != "#") {
    cohortTempTable <- paste("#", cohortTempTable, sep = "")
  }

  # Some SQL to construct the covariate:
  sql <- paste("SELECT @row_id_field AS row_id, 1 AS covariate_id,",
               "DATEDIFF(DAY, cohort_start_date, observation_period_start_date)",
               "AS covariate_value",
               "FROM @cohort_temp_table c",
               "INNER JOIN @cdm_database_schema.observation_period op",
               "ON op.person_id = c.subject_id",
               "WHERE cohort_start_date >= observation_period_start_date",
               "AND cohort_start_date <= observation_period_end_date")
  sql <- SqlRender::renderSql(sql,
                              cohort_temp_table = cohortTempTable,
                              row_id_field = rowIdField,
                              cdm_database_schema = cdmDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = attr(connection, "dbms"))$sql

  # Retrieve the covariate:
  covariates <- DatabaseConnector::querySql.ffdf(connection, sql)

  # Convert colum names to camelCase:
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))

  # Construct covariate reference:
  covariateRef <- data.frame(covariateId = 1,
                             covariateName = "Length of observation",
                             analysisId = 1,
                             conceptId = 0)
  covariateRef <- ff::as.ffdf(covariateRef)

  metaData <- list(sql = sql, call = match.call())
  result <- list(covariates = covariates, covariateRef = covariateRef, metaData = metaData)
  class(result) <- "covariateData"
  return(result)
}

looCovariateSettings <- createLooCovariateSettings(useLengthOfObs = TRUE)

plpData <- getDbPlpData(connectionDetails = connectionDetails,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        cohortDatabaseSchema = resultsDatabaseSchema,
                        cohortTable = "mschuemi_stroke",
                        cohortIds = 1,
                        useCohortEndDate = TRUE,
                        windowPersistence = 0,
                        covariateSettings = looCovariateSettings,
                        outcomeDatabaseSchema = resultsDatabaseSchema,
                        outcomeTable = "mschuemi_stroke",
                        outcomeIds = 2,
                        firstOutcomeOnly = TRUE,
                        cdmVersion = cdmVersion)

covariateSettings <- createCovariateSettings(useCovariateDemographics = TRUE,
                                             useCovariateDemographicsGender = TRUE,
                                             useCovariateDemographicsRace = TRUE,
                                             useCovariateDemographicsEthnicity = TRUE,
                                             useCovariateDemographicsAge = TRUE,
                                             useCovariateDemographicsYear = TRUE,
                                             useCovariateDemographicsMonth = TRUE)
looCovariateSettings <- createLooCovariateSettings(useLengthOfObs = TRUE)
covariateSettingsList <- list(covariateSettings, looCovariateSettings)

plpData <- getDbPlpData(connectionDetails = connectionDetails,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        cohortDatabaseSchema = resultsDatabaseSchema,
                        cohortTable = "mschuemi_stroke",
                        cohortIds = 1,
                        useCohortEndDate = TRUE,
                        windowPersistence = 0,
                        covariateSettings = covariateSettingsList,
                        outcomeDatabaseSchema = resultsDatabaseSchema,
                        outcomeTable = "mschuemi_stroke",
                        outcomeIds = 2,
                        firstOutcomeOnly = TRUE,
                        cdmVersion = cdmVersion)

covariateSettings <- createHdpsCovariateSettings(useCovariateCohortIdIs1 = FALSE,
                                                 useCovariateDemographics = TRUE,
                                                 useCovariateDemographicsGender = TRUE,
                                                 useCovariateDemographicsRace = TRUE,
                                                 useCovariateDemographicsEthnicity = TRUE,
                                                 useCovariateDemographicsAge = TRUE,
                                                 useCovariateDemographicsYear = TRUE,
                                                 useCovariateDemographicsMonth = TRUE,
                                                 useCovariateConditionOccurrence = TRUE,
                                                 useCovariate3DigitIcd9Inpatient180d = TRUE,
                                                 useCovariate3DigitIcd9Inpatient180dMedF = TRUE,
                                                 useCovariate3DigitIcd9Inpatient180d75F = TRUE,
                                                 useCovariate3DigitIcd9Ambulatory180d = TRUE,
                                                 useCovariate3DigitIcd9Ambulatory180dMedF = TRUE,
                                                 useCovariate3DigitIcd9Ambulatory180d75F = TRUE,
                                                 useCovariateDrugExposure = TRUE,
                                                 useCovariateIngredientExposure180d = TRUE,
                                                 useCovariateIngredientExposure180dMedF = TRUE,
                                                 useCovariateIngredientExposure180d75F = TRUE,
                                                 useCovariateProcedureOccurrence = TRUE,
                                                 useCovariateProcedureOccurrenceInpatient180d = TRUE,
                                                 useCovariateProcedureOccurrenceInpatient180dMedF = TRUE,
                                                 useCovariateProcedureOccurrenceInpatient180d75F = TRUE,
                                                 useCovariateProcedureOccurrenceAmbulatory180d = TRUE,
                                                 useCovariateProcedureOccurrenceAmbulatory180dMedF = TRUE,
                                                 useCovariateProcedureOccurrenceAmbulatory180d75F = TRUE,
                                                 excludedCovariateConceptIds = c(),
                                                 includedCovariateConceptIds = c(),
                                                 deleteCovariatesSmallCount = 100)



#### Datafetch for cohort attribute covariate builder #####

library(SqlRender)
library(DatabaseConnector)
library(FeatureExtraction)
setwd("s:/temp")
options(fftempdir = "s:/FFtemp")

pw <- NULL
dbms <- "sql server"
user <- NULL
server <- "RNDUSRDHIT07.jnj.com"
cdmDatabaseSchema <- "cdm_truven_mdcd.dbo"
resultsDatabaseSchema <- "scratch.dbo"
port <- NULL

dbms <- "postgresql"
server <- "localhost/ohdsi"
user <- "postgres"
pw <- "F1r3starter"
cdmDatabaseSchema <- "cdm4_sim"
resultsDatabaseSchema <- "scratch"
port <- NULL

pw <- NULL
dbms <- "pdw"
user <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "cdm_truven_mdcd_v5.dbo"
cohortDatabaseSchema <- "scratch.dbo"
oracleTempSchema <- NULL
port <- 17001
cdmVersion <- "5"

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
                                         packageName = "PatientLevelPrediction",
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
                                               includeAttrIds = c())

covariates <- getDbCovariateData(connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 cohortTable = "rehospitalization",
                                 cohortIds = 1,
                                 covariateSettings = looCovSet,
                                 cdmVersion = cdmVersion)
summary(covariates)



sql <- "DROP TABLE @cohort_database_schema.rehospitalization"
sql <- SqlRender::renderSql(sql, cohort_database_schema = cohortDatabaseSchema)$sql
sql <- SqlRender::translateSql(sql, targetDialect = attr(connection, "dbms"))$sql







covariateSettings <- createCovariateSettings(useCovariateDemographics = TRUE,
                                             useCovariateDemographicsGender = TRUE,
                                             useCovariateDemographicsRace = TRUE,
                                             useCovariateDemographicsEthnicity = TRUE,
                                             useCovariateDemographicsAge = TRUE,
                                             useCovariateDemographicsYear = TRUE,
                                             useCovariateDemographicsMonth = TRUE)
looCovSet <- createCohortAttrCovariateSettings(attrDatabaseSchema = cohortDatabaseSchema,
                                               cohortAttrTable = "loo_cohort_attribute",
                                               attrDefinitionTable = "loo_attribute_definition",
                                               includeAttrIds = c())
covariateSettingsList <- list(covariateSettings, looCovSet)

covariates <- getDbCovariateData(connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 cohortTable = "rehospitalization",
                                 cohortIds = 1,
                                 covariateSettings = covariateSettingsList,
                                 cdmVersion = cdmVersion)
