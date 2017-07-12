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

#' Get default covariate information from the database
#'
#' @description
#' Constructs a large default set of covariates for one or more cohorts using data in the CDM schema.
#' Includes covariates for all drugs, drug classes, condition, condition classes, procedures,
#' observations, etc.
#'
#' @param covariateSettings   An object of type \code{defaultCovariateSettings} as created using the
#'                            \code{\link{createCovariateSettings}} function.
#'
#' @template GetCovarParams
#'
#' @export
getDbDefaultCovariateData <- function(connection,
                                      oracleTempSchema = NULL,
                                      cdmDatabaseSchema,
                                      cohortTempTable = "cohort_person",
                                      rowIdField = "subject_id",
                                      covariateSettings,
                                      aggregated = FALSE,
                                      temporal = FALSE) {
  if (!is(covariateSettings, "covariateSettings")) {
    stop("Covariate settings object not of type covariateSettings") 
  }
  
  # Convert arguments to table of feature sets:
  fileName <- system.file("csv","FeatureSets.csv", package = "FeatureExtraction")
  featureSets <- read.csv(fileName)
  useNames <- names(covariateSettings)[grepl("use.*", names(covariateSettings))]
  featureSets <- featureSets[normName(featureSets$analysisName) %in% normName(gsub("use", "", useNames)), ]
  days <- unlist(covariateSettings[grepl(".*Days$", names(covariateSettings))])
  featureSets$startDay <- plyr::mapvalues(featureSets$startDay, names(days), -days, warn_missing = FALSE)
  featureSets$endDay <- plyr::mapvalues(featureSets$endDay, names(days), -days, warn_missing = FALSE)
  
  # Upload excluded concept IDs if needed -----------------------------------
  excludedCovariateConceptIds <- covariateSettings$excludedCovariateConceptIds
  addDescendantsToExclude <- covariateSettings$addDescendantsToExclude
  if (is.null(excludedCovariateConceptIds) || length(excludedCovariateConceptIds) ==
      0) {
    hasExcludedCovariateConceptIds <- FALSE
  } else {
    if (!is.numeric(excludedCovariateConceptIds))
      stop("excludedCovariateConceptIds must be a (vector of) numeric")
    hasExcludedCovariateConceptIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#excluded_cov",
                                   data = data.frame(concept_id = as.integer(excludedCovariateConceptIds)),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
    if (!is.null(addDescendantsToExclude) && addDescendantsToExclude) {
      writeLines("Adding descendants to concepts to exclude")
      sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "IncludeDescendants.sql",
                                               packageName = "FeatureExtraction",
                                               dbms = attr(connection, "dbms"),
                                               oracleTempSchema = oracleTempSchema,
                                               cdm_database_schema = cdmDatabaseSchema,
                                               table_name = "#excluded_cov")
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }
  
  # Upload included concept IDs if needed -----------------------------------
  includedCovariateConceptIds <- covariateSettings$includedCovariateConceptIds
  addDescendantsToInclude <- covariateSettings$addDescendantsToInclude
  if (is.null(includedCovariateConceptIds) || length(includedCovariateConceptIds) ==
      0) {
    hasIncludedCovariateConceptIds <- FALSE
  } else {
    if (!is.numeric(includedCovariateConceptIds))
      stop("includedCovariateConceptIds must be a (vector of) numeric")
    hasIncludedCovariateConceptIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#included_cov",
                                   data = data.frame(concept_id = as.integer(includedCovariateConceptIds)),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
    if (!is.null(addDescendantsToInclude) && addDescendantsToInclude) {
      writeLines("Adding descendants to concepts to include")
      sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "IncludeDescendants.sql",
                                               packageName = "FeatureExtraction",
                                               dbms = attr(connection, "dbms"),
                                               oracleTempSchema = oracleTempSchema,
                                               cdm_database_schema = cdmDatabaseSchema,
                                               table_name = "#included_cov")
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }
  
  # Upload included covariate IDs if needed -----------------------------------
  includedCovariateIds <- covariateSettings$includedCovariateIds
  if (is.null(includedCovariateIds) || length(includedCovariateIds) ==
      0) {
    hasIncludedCovariateIds <- FALSE
  } else {
    if (!is.numeric(includedCovariateIds))
      stop("includedCovariateIds must be a (vector of) numeric")
    hasIncludedCovariateIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#included_cov_by_id",
                                   data = data.frame(covariate_id = includedCovariateIds),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
  }
  
  ### TODO: create #time_period for temporal features
  
  # Generate covariates and refs  ----------------------------------
  writeLines("Generating features")
  start <- Sys.time()
  ### TODO: maybe possible to filter analysis IDs based on includedCovariateIds
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "CreateCovRefTable.sql",
                                           packageName = "FeatureExtraction",
                                           dbms = attr(connection, "dbms"),
                                           oracleTempSchema = oracleTempSchema)
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  covTableNames <- paste0("#cov_", featureSets$analysisId)
  for (i in 1:nrow(featureSets)) {
    writeLines(paste("-", featureSets$analysisName[i]))
    args <- list(sqlFilename = featureSets$sqlFileName[i],
                 packageName = featureSets$sqlPackage[i],
                 dbms = attr(connection, "dbms"),
                 oracleTempSchema = oracleTempSchema,
                 temporal = temporal,
                 aggregated = aggregated,
                 covariate_table = covTableNames[i],
                 cohort_table = cohortTempTable,
                 row_id_field = rowIdField,
                 analysis_id = featureSets$analysisId[i],
                 cdm_database_schema = cdmDatabaseSchema,
                 has_excluded_covariate_concept_ids = hasExcludedCovariateConceptIds,
                 has_included_covariate_concept_ids = hasIncludedCovariateConceptIds,
                 has_included_covariate_ids = hasIncludedCovariateIds)
    if (featureSets$startDay[i] != "") {
      args$start_day <- featureSets$startDay[i]
    }
    if (featureSets$endDay[i] != "") {
      args$end_day <- featureSets$endDay[i]
    }
    sql <- do.call(SqlRender::loadRenderTranslateSql, args)
    DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  }
  delta <- Sys.time() - start
  writeLines(paste("Generating features took", signif(delta, 3), attr(delta, "units")))
  
  # Download covariates and ref  -----------------------------------
  writeLines("Downloading data")
  start <- Sys.time()
  
  if (aggregated) {
    fieldString <- "covariate_id, sum_value, min_value, max_value, average_value, standard_deviation"
  } else {
    fieldString <- "covariate_id, covariate_value, row_id"
  }
  if (temporal) {
    fieldString <- paste0(fieldString, ", time_id")
  }
  sql <- paste("SELECT", 
               fieldString, 
               "\nINTO #cov_all\nFROM (\n",
               paste(paste("SELECT", fieldString, "FROM", covTableNames), collapse = "\nUNION ALL\n"),
               "\n) all_covariates;")
  if (!aggregated) {
    sql <- paste("--HINT DISTRIBUTE_ON_KEY(row_id)", sql, sep = "\n")
  }
  sql <- SqlRender::translateSql(sql = sql, 
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  covariateSql <- paste("SELECT", fieldString, "FROM #cov_all ORDER BY covariate_id")
  if (!aggregated) {
    covariateSql <- paste0(covariateSql, ", row_id")
  }
  covariateSql <- SqlRender::translateSql(sql = covariateSql,
                                          targetDialect = attr(connection, "dbms"),
                                          oracleTempSchema = oracleTempSchema)$sql
  covariates <- DatabaseConnector::querySql.ffdf(connection, covariateSql)
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
  covariateRefSql <- "SELECT covariate_id, covariate_name, analysis_id, concept_id  FROM #cov_ref ORDER BY covariate_id"
  covariateRefSql <- SqlRender::translateSql(sql = covariateRefSql,
                                             targetDialect = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema)$sql
  covariateRef <- DatabaseConnector::querySql.ffdf(connection, covariateRefSql)
  colnames(covariateRef) <- SqlRender::snakeCaseToCamelCase(colnames(covariateRef))
  covariateRef$analysisName <- covariateSettings$analysisName[match(covariateRef$analysisId, covariateSettings$analysisId)]

  delta <- Sys.time() - start
  writeLines(paste("Downloading data took", signif(delta, 3), attr(delta, "units")))
  
  # Drop temp tables ----------------------------------
  tempTables <- c(covTableNames, "#cov_all", "#cov_ref")
  if (temporal) {
    tempTables <- c(tempTables, "#time_periods")
  }
  sql <- paste0("TRUNCATE TABLE ", tempTables, "; DROP TABLE ", tempTables, ";")
  sql <- paste(sql, collapse = "\n")
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  
  covariateData <- list(covariates = covariates, covariateRef = covariateRef, metaData = list())
  if (nrow(covariateData$covariates) == 0) {
    warning("No data found")
  } else {
    open(covariateData$covariates)
  }
  class(covariateData) <- "covariateData"
  return(covariateData)
}

normName <- function(x) {
  return(gsub("[^a-z]", "", tolower(x)))
}

 
# createCovariateSettings <- function(useDemographicsGender = FALSE,
#                                     useDemographicsAge = FALSE,
#                                     useDemographicsIndexYear = FALSE,
#                                     useDemographicsIndexMonth = FALSE,
#                                     useConditionOccurrenceLongTerm = FALSE,
#                                     useConditionOccurrenceShortTerm = FALSE,
#                                     useConditionEraLongTerm = FALSE,
#                                     useConditionEraShortTerm = FALSE,
#                                     useConditionGroupEraLongTerm = FALSE,
#                                     useConditionGroupEraShortTerm = FALSE,
#                                     useDrugExposureLongTerm = FALSE,
#                                     useDrugExposureShortTerm = FALSE,
#                                     useDrugEraLongTerm = FALSE,
#                                     useDrugEraShortTerm = FALSE,
#                                     useDrugGroupEraLongTerm = FALSE,
#                                     useDrugGroupEraShortTerm = FALSE,
#                                     useProcedureOccurrenceLongTerm = FALSE,
#                                     useProcedureOccurrenceShortTerm = FALSE,
#                                     useDeviceExposureLongTerm = FALSE,
#                                     useDeviceExposureShortTerm = FALSE,
#                                     useMeasurementLongTerm = FALSE,
#                                     useMeasurementShortTerm = FALSE,
#                                     useObservationLongTerm = FALSE,
#                                     useObservationShortTerm = FALSE,
#                                     useCharlsonIndex = FALSE,
#                                     longTermDays = 365,
#                                     shortTermDays = 30,
#                                     windowEndDays = 0,
#                                     excludedCovariateConceptIds = c(),
#                                     addDescendantsToExclude = TRUE,
#                                     includedCovariateConceptIds = c(),
#                                     addDescendantsToInclude = TRUE,
#                                     includedCovariateIds = c(),
#                                     deleteCovariatesSmallCount = 100) {
#   formalNames <- names(formals(createCovariateSettings))
#   
#   fileName <- system.file("csv","FeatureSets.csv", package = "FeatureExtraction")
#   featureSet <- read.csv(fileName)
#   
#   useNames <- formalNames[grepl("use.*", formalNames)]
#   useNames <- useNames[as.logical(mget(useNames))]
#   featureSet <- featureSet[normName(featureSet$analysisName) %in% normName(gsub("use", "", useNames)), ]
#   
#   daysNames <- formalNames[grepl(".*Days$", formalNames)]
#   days <- -as.integer(mget(daysNames))
#   featureSet$startDay <- plyr::mapvalues(featureSet$startDay, daysNames, days, warn_missing = FALSE)
#   featureSet$endDay <- plyr::mapvalues(featureSet$endDay, daysNames, days, warn_missing = FALSE)
#   inclusionExclusion <- list(excludedCovariateConceptIds = excludedCovariateConceptIds,
#                              addDescendantsToExclude = addDescendantsToExclude,
#                              includedCovariateConceptIds = includedCovariateConceptIds,
#                              addDescendantsToInclude = addDescendantsToInclude,
#                              includedCovariateIds = includedCovariateIds,
#                              deleteCovariatesSmallCount = deleteCovariatesSmallCount)
#   covariateSettings <- list(featureSet = featureSet,
#                             inclusionExclusion = inclusionExclusion)
#   class(covariateSettings) <- append(class(covariateSettings), "covariateSettings")
#   return(covariateSettings)
# }
# 

