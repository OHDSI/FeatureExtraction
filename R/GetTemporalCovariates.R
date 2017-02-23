# @file GetTemporalCovariates.R
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

#' Get default covariate information from the database
#'
#' @description
#' Constructs a large default set of covariates for one or more cohorts using data in the CDM schema.
#' Includes covariates for all drugs, drug classes, condition, condition classes, procedures,
#' observations, etc.
#'
#' @param covariateSettings   An object of type \code{temporalCovariateSettings} as created using the
#'                            \code{\link{createTemporalCovariateSettings}} function.
#'
#' @template GetCovarParams
#'
#' @export
getDbTemporalCovariateData <- function(connection,
                                       oracleTempSchema = NULL,
                                       cdmDatabaseSchema,
                                       cdmVersion = "4",
                                       cohortTempTable = "cohort_person",
                                       rowIdField = "subject_id",
                                       covariateSettings) {
  writeLines("Constructing temporal covariates")
  if (substr(cohortTempTable, 1, 1) != "#") {
    cohortTempTable <- paste("#", cohortTempTable, sep = "")
  }
  
  timePeriods <- data.frame(startDay = covariateSettings$startDays,
                            endDay = covariateSettings$endDays,
                            time_id = 1:length(covariateSettings$startDays))
  
  time_periods <- timePeriods
  colnames(time_periods) <- SqlRender::camelCaseToSnakeCase(colnames(time_periods))
  
  DatabaseConnector::insertTable(connection,
                                 tableName = "#time_period",
                                 data = time_periods,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE,
                                 tempTable = TRUE,
                                 oracleTempSchema = oracleTempSchema)
  
  if (is.null(covariateSettings$excludedCovariateConceptIds) || length(covariateSettings$excludedCovariateConceptIds) ==
      0) {
    hasExcludedCovariateConceptIds <- FALSE
  } else {
    if (!is.numeric(covariateSettings$excludedCovariateConceptIds))
      stop("excludedCovariateConceptIds must be a (vector of) numeric")
    hasExcludedCovariateConceptIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#excluded_cov",
                                   data = data.frame(concept_id = as.integer(covariateSettings$excludedCovariateConceptIds)),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
  }
  
  if (is.null(covariateSettings$includedCovariateConceptIds) || length(covariateSettings$includedCovariateConceptIds) ==
      0) {
    hasIncludedCovariateConceptIds <- FALSE
  } else {
    if (!is.numeric(covariateSettings$includedCovariateConceptIds))
      stop("includedCovariateConceptIds must be a (vector of) numeric")
    hasIncludedCovariateConceptIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#included_cov",
                                   data = data.frame(concept_id = as.integer(covariateSettings$includedCovariateConceptIds)),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
  }
  
  renderedSql <- SqlRender::loadRenderTranslateSql("GetTemporalCovariates.sql",
                                                   packageName = "FeatureExtraction",
                                                   dbms = attr(connection, "dbms"),
                                                   oracleTempSchema = oracleTempSchema,
                                                   cdm_database_schema = cdmDatabaseSchema,
                                                   cohort_temp_table = cohortTempTable,
                                                   row_id_field = rowIdField,
                                                   use_covariate_condition_era_start = covariateSettings$useCovariateConditionEraStart,
                                                   use_covariate_condition_era_present = covariateSettings$useCovariateConditionEraPresent,
                                                   use_covariate_measurement_value = covariateSettings$useCovariateMeasurementValue,
                                                   has_excluded_covariate_concept_ids = hasExcludedCovariateConceptIds,
                                                   has_included_covariate_concept_ids = hasIncludedCovariateConceptIds)
  
  DatabaseConnector::executeSql(connection, renderedSql)
  writeLines("Done")
  
  writeLines("Fetching data from server")
  start <- Sys.time()
  covariateSql <- "SELECT row_id, covariate_id, time_id, covariate_value FROM #cov"
  covariateSql <- SqlRender::renderSql(covariateSql)$sql
  covariateSql <- SqlRender::translateSql(covariateSql,
                                          "sql server",
                                          attr(connection, "dbms"),
                                          oracleTempSchema)$sql
  covariates <- DatabaseConnector::querySql.ffdf(connection, covariateSql)
  covariateRefSql <- "SELECT covariate_id, covariate_name, analysis_id, concept_id  FROM #cov_ref ORDER BY covariate_id"
  covariateRefSql <- SqlRender::translateSql(covariateRefSql,
                                             "sql server",
                                             attr(connection, "dbms"),
                                             oracleTempSchema)$sql
  covariateRef <- DatabaseConnector::querySql.ffdf(connection, covariateRefSql)
  
  delta <- Sys.time() - start
  writeLines(paste("Fetching data took", signif(delta, 3), attr(delta, "units")))
  
  renderedSql <- SqlRender::loadRenderTranslateSql("RemoveCovariateTempTables.sql",
                                                   packageName = "FeatureExtraction",
                                                   dbms = attr(connection, "dbms"),
                                                   oracleTempSchema = oracleTempSchema)
  DatabaseConnector::executeSql(connection,
                                renderedSql,
                                progressBar = FALSE,
                                reportOverallTime = FALSE)
  
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
  colnames(covariateRef) <- SqlRender::snakeCaseToCamelCase(colnames(covariateRef))
  
  metaData <- list(call = match.call())
  result <- list(covariates = covariates, covariateRef = covariateRef, timePeriods = timePeriods, metaData = metaData)
  class(result) <- "temporalCovariateData"
  return(result)
}


#' Create temporal covariate settings
#'
#' @details
#' creates an object specifying how covariates should be contructed from data in the CDM model.
#'
#' @param excludedCovariateConceptIds               A list of concept IDs that should NOT be used to
#'                                                  construct covariates.
#' @param includedCovariateConceptIds               A list of concept IDs that should be used to
#'                                                  construct covariates.
#'
#' @return
#' An object of type \code{defaultCovariateSettings}, to be used in other functions.
#'
#' @export
createTemporalCovariateSettings <- function(useCovariateConditionEraStart = FALSE,
                                            useCovariateConditionEraPresent = FALSE,
                                            useCovariateMeasurementValue = FALSE,
                                            excludedCovariateConceptIds = c(),
                                            includedCovariateConceptIds = c(),
                                            startDays = -365:-1,
                                            endDays = -364:0) {
  if (length(startDays) != length(endDays))
    stop("Length of startDays should be equal to length of endDays")
  if (any(startDays >= endDays))
    stop("End days must be after start days")
  # First: get the default values:
  covariateSettings <- list()
  for (name in names(formals(createTemporalCovariateSettings))) {
    covariateSettings[[name]] <- get(name)
  }
  # Next: overwrite defaults with actual values if specified:
  values <- lapply(as.list(match.call())[-1], function(x) eval(x, envir = sys.frame(-3)))
  for (name in names(values)) {
    if (name %in% names(covariateSettings))
      covariateSettings[[name]] <- values[[name]]
  }
  attr(covariateSettings, "fun") <- "getDbTemporalCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
