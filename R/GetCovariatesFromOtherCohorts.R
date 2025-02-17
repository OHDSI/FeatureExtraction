# Copyright 2024 Observational Health Data Sciences and Informatics
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

#' Get covariate information from the database based on other cohorts
#'
#' @description
#' Constructs  covariates using other cohorts.
#'
#' @param covariateSettings   An object of type \code{covariateSettings} as created using the
#'                            \code{\link{createCohortBasedCovariateSettings}} or
#'                            \code{\link{createCohortBasedTemporalCovariateSettings}} functions.
#' @param minCharacterizationMean The minimum mean value for binary characterization output. Values below this will be cut off from output. This
#'                                will help reduce the file size of the characterization output, but will remove information
#'                                on covariates that have very low values. The default is 0.
#' @template GetCovarParams
#'
#' @export
getDbCohortBasedCovariatesData <- function(connection,
                                           oracleTempSchema = NULL,
                                           cdmDatabaseSchema,
                                           cohortTable = "#cohort_person",
                                           cohortId = -1,
                                           cohortIds = c(-1),
                                           cdmVersion = "5",
                                           rowIdField = "subject_id",
                                           covariateSettings,
                                           aggregated = FALSE,
                                           minCharacterizationMean = 0,
                                           tempEmulationSchema = NULL) {
  errorMessages <- checkmate::makeAssertCollection()
  checkmate::assertClass(connection, "DatabaseConnectorConnection", add = errorMessages)
  checkmate::assertCharacter(oracleTempSchema, len = 1, null.ok = TRUE, add = errorMessages)
  checkmate::assertCharacter(tempEmulationSchema, len = 1, null.ok = TRUE, add = errorMessages)
  checkmate::assertCharacter(cdmDatabaseSchema, len = 1, null.ok = TRUE, add = errorMessages)
  checkmate::assertCharacter(cohortTable, len = 1, add = errorMessages)
  checkmate::assertIntegerish(cohortId, add = errorMessages)
  # checkmate::assertCharacter(cdmVersion, len = 1, add = errorMessages)
  checkmate::assertCharacter(rowIdField, len = 1, add = errorMessages)
  checkmate::assertClass(covariateSettings, "covariateSettings", add = errorMessages)
  checkmate::assertLogical(aggregated, len = 1, add = errorMessages)
  minCharacterizationMean <- utils::type.convert(minCharacterizationMean, as.is = TRUE)
  checkmate::assertNumeric(x = minCharacterizationMean, lower = 0, upper = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)
  if (!missing(cohortId)) {
    warning("cohortId argument has been deprecated, please use cohortIds")
    cohortIds <- cohortId
  }
  if (!is.null(oracleTempSchema) && oracleTempSchema != "") {
    rlang::warn("The 'oracleTempSchema' argument is deprecated. Use 'tempEmulationSchema' instead.",
      .frequency = "regularly",
      .frequency_id = "oracleTempSchema"
    )
    tempEmulationSchema <- oracleTempSchema
  }

  start <- Sys.time()
  message("Constructing covariates from other cohorts")

  covariateCohorts <- covariateSettings$covariateCohorts %>%
    select("cohortId", "cohortName")

  DatabaseConnector::insertTable(connection,
    tableName = "#covariate_cohort_ref",
    data = covariateCohorts,
    dropTableIfExists = TRUE,
    createTable = TRUE,
    tempTable = TRUE,
    tempEmulationSchema = tempEmulationSchema,
    camelCaseToSnakeCase = TRUE
  )
  if (is.null(covariateSettings$covariateCohortTable)) {
    covariateCohortTable <- cohortTable
  } else if (is.null(covariateSettings$covariateCohortDatabaseSchema)) {
    covariateCohortTable <- covariateSettings$covariateCohortTable
  } else {
    covariateCohortTable <- paste(covariateSettings$covariateCohortDatabaseSchema,
      covariateSettings$covariateCohortTable,
      sep = "."
    )
  }

  if (covariateSettings$temporal) {
    if (covariateSettings$valueType == "binary") {
      sqlFileName <- "CohortBasedBinaryCovariates.sql"
    } else {
      sqlFileName <- "CohortBasedCountCovariates.sql"
    }
    parameters <- list(
      covariateCohortTable = covariateCohortTable,
      analysisId = covariateSettings$analysisId,
      analysisName = "CohortTemporal"
    )
    detail <- createAnalysisDetails(
      analysisId = covariateSettings$analysisId,
      sqlFileName = sqlFileName,
      parameters = parameters,
      includedCovariateConceptIds = covariateSettings$includedCovariateIds,
      addDescendantsToInclude = FALSE,
      excludedCovariateConceptIds = c(),
      addDescendantsToExclude = FALSE,
      includedCovariateIds = c()
    )
    detailledSettings <- createDetailedTemporalCovariateSettings(
      analyses = list(detail),
      temporalStartDays = covariateSettings$temporalStartDays,
      temporalEndDays = covariateSettings$temporalEndDays
    )
  } else {
    # Not temporal
    if (covariateSettings$valueType == "binary") {
      sqlFileName <- "CohortBasedBinaryCovariates.sql"
    } else {
      sqlFileName <- "CohortBasedCountCovariates.sql"
    }
    parameters <- list(
      covariateCohortTable = covariateCohortTable,
      analysisId = covariateSettings$analysisId,
      analysisName = "Cohort",
      startDay = covariateSettings$startDay,
      endDay = covariateSettings$endDay
    )
    detail <- createAnalysisDetails(
      analysisId = covariateSettings$analysisId,
      sqlFileName = sqlFileName,
      parameters = parameters,
      includedCovariateConceptIds = covariateSettings$includedCovariateIds,
      addDescendantsToInclude = FALSE,
      excludedCovariateConceptIds = c(),
      addDescendantsToExclude = FALSE,
      includedCovariateIds = c()
    )
    detailledSettings <- createDetailedCovariateSettings(analyses = list(detail))
  }
  result <- getDbDefaultCovariateData(
    connection = connection,
    tempEmulationSchema = tempEmulationSchema,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable,
    cohortIds = cohortIds,
    cdmVersion = cdmVersion,
    rowIdField = rowIdField,
    covariateSettings = detailledSettings,
    aggregated = aggregated,
    minCharacterizationMean = minCharacterizationMean
  )

  sql <- "TRUNCATE TABLE #covariate_cohort_ref; DROP TABLE #covariate_cohort_ref;"
  DatabaseConnector::renderTranslateExecuteSql(
    connection = connection,
    sql = sql,
    progressBar = FALSE,
    reportOverallTime = FALSE,
    tempEmulationSchema = tempEmulationSchema
  )
  return(result)
}

#' Create settings for covariates based on other cohorts
#'
#' @details
#' Creates an object specifying covariates to be constructed based on the presence of other cohorts.
#'
#' @param analysisId                    A unique identifier for this analysis.
#' @param covariateCohortDatabaseSchema The database schema where the cohorts used to define the covariates
#'                                      can be found. If set to \code{NULL}, the database schema will be
#'                                      guessed, for example using the same one as for the main cohorts.
#' @param covariateCohortTable          The table where the cohorts used to define the covariates
#'                                      can be found. If set to \code{NULL}, the table will be
#'                                      guessed, for example using the same one as for the main cohorts.
#' @param covariateCohorts              A data frame with at least two columns: 'cohortId' and 'cohortName'. The
#'                                      cohort  ID should correspond to the \code{cohort_definition_id} of the cohort
#'                                      to use for creating a covariate.
#' @param valueType                     Either 'binary' or 'count'. When \code{valueType = 'count'}, the covariate
#'                                      value will be the number of times the cohort was observed in the window.
#' @param startDay                      What is the start day (relative to the index date) of the covariate window?
#' @param endDay                        What is the end day (relative to the index date) of the covariate window?
#' @param includedCovariateIds          A list of covariate IDs that should be restricted to.
#' @param warnOnAnalysisIdOverlap       Warn if the provided `analysisId` overlaps with any predefined analysis as
#'                                      available in the `createCovariateSettings()` function.
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#'
#' @export
createCohortBasedCovariateSettings <- function(analysisId,
                                               covariateCohortDatabaseSchema = NULL,
                                               covariateCohortTable = NULL,
                                               covariateCohorts,
                                               valueType = "binary",
                                               startDay = -365,
                                               endDay = 0,
                                               includedCovariateIds = c(),
                                               warnOnAnalysisIdOverlap = TRUE) {
  errorMessages <- checkmate::makeAssertCollection()
  checkmate::assertInt(analysisId, lower = 1, upper = 999, add = errorMessages)
  checkmate::assertCharacter(covariateCohortDatabaseSchema, len = 1, null.ok = TRUE, add = errorMessages)
  checkmate::assertCharacter(covariateCohortTable, len = 1, null.ok = TRUE, add = errorMessages)
  checkmate::assertDataFrame(covariateCohorts, min.rows = 1, add = errorMessages)
  checkmate::assertNames(colnames(covariateCohorts), must.include = c("cohortId", "cohortName"), add = errorMessages)
  checkmate::assertChoice(valueType, c("binary", "count"), add = errorMessages)
  checkmate::assertInt(startDay, add = errorMessages)
  checkmate::assertInt(endDay, add = errorMessages)
  checkmate::assertTRUE(startDay <= endDay, add = errorMessages)
  .assertCovariateId(includedCovariateIds, null.ok = TRUE, add = errorMessages)
  checkmate::assertLogical(warnOnAnalysisIdOverlap, len = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)

  if (warnOnAnalysisIdOverlap) {
    warnIfPredefined(analysisId)
  }

  covariateSettings <- list(
    temporal = FALSE,
    temporalSequence = FALSE
  )

  formalNames <- names(formals(createCohortBasedCovariateSettings))
  for (name in formalNames) {
    value <- get(name)
    covariateSettings[[name]] <- value
  }
  attr(covariateSettings, "fun") <- "getDbCohortBasedCovariatesData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

#' Create settings for temporal covariates based on other cohorts
#'
#' @details
#' Creates an object specifying temporal covariates to be constructed based on the presence of other cohorts.
#'
#' @param analysisId                    A unique identifier for this analysis.
#' @param covariateCohortDatabaseSchema The database schema where the cohorts used to define the covariates
#'                                      can be found. If set to \code{NULL}, the database schema will be
#'                                      guessed, for example using the same one as for the main cohorts.
#' @param covariateCohortTable          The table where the cohorts used to define the covariates
#'                                      can be found. If set to \code{NULL}, the table will be
#'                                      guessed, for example using the same one as for the main cohorts.
#' @param covariateCohorts              A data frame with at least two columns: 'cohortId' and 'cohortName'. The
#'                                      cohort  ID should correspond to the \code{cohort_definition_id} of the cohort
#'                                      to use for creating a covariate.
#' @param valueType                     Either 'binary' or 'count'. When \code{valueType = 'count'}, the covariate
#'                                      value will be the number of times the cohort was observed in the window.
#' @param temporalStartDays                        A list of integers representing the start of a time
#'                                                 period, relative to the index date. 0 indicates the
#'                                                 index date, -1 indicates the day before the index
#'                                                 date, etc. The start day is included in the time
#'                                                 period.
#' @param temporalEndDays                          A list of integers representing the end of a time
#'                                                 period, relative to the index date. 0 indicates the
#'                                                 index date, -1 indicates the day before the index
#'                                                 date, etc. The end day is included in the time
#'                                                 period.
#' @param includedCovariateIds          A list of covariate IDs that should be restricted to.
#' @param warnOnAnalysisIdOverlap       Warn if the provided `analysisId` overlaps with any predefined analysis as
#'                                      available in the `createTemporalCovariateSettings()` function.
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#'
#' @export
createCohortBasedTemporalCovariateSettings <- function(analysisId,
                                                       covariateCohortDatabaseSchema = NULL,
                                                       covariateCohortTable = NULL,
                                                       covariateCohorts,
                                                       valueType = "binary",
                                                       temporalStartDays = -365:-1,
                                                       temporalEndDays = -365:-1,
                                                       includedCovariateIds = c(),
                                                       warnOnAnalysisIdOverlap = TRUE) {
  errorMessages <- checkmate::makeAssertCollection()
  checkmate::assertInt(analysisId, lower = 1, upper = 999, add = errorMessages)
  checkmate::assertCharacter(covariateCohortDatabaseSchema, len = 1, null.ok = TRUE, add = errorMessages)
  checkmate::assertCharacter(covariateCohortTable, len = 1, null.ok = TRUE, add = errorMessages)
  checkmate::assertDataFrame(covariateCohorts, min.rows = 1, add = errorMessages)
  checkmate::assertNames(colnames(covariateCohorts), must.include = c("cohortId", "cohortName"), add = errorMessages)
  checkmate::assertChoice(valueType, c("binary", "count"), add = errorMessages)
  checkmate::assertIntegerish(temporalStartDays, add = errorMessages)
  checkmate::assertIntegerish(temporalEndDays, add = errorMessages)
  checkmate::assertTRUE(all(temporalStartDays <= temporalEndDays), add = errorMessages)
  .assertCovariateId(includedCovariateIds, null.ok = TRUE, add = errorMessages)
  checkmate::assertLogical(warnOnAnalysisIdOverlap, len = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)

  if (warnOnAnalysisIdOverlap) {
    warnIfPredefined(analysisId, TRUE)
  }

  covariateSettings <- list(
    temporal = TRUE,
    temporalSequence = FALSE
  )
  formalNames <- names(formals(createCohortBasedTemporalCovariateSettings))
  for (name in formalNames) {
    value <- get(name)
    covariateSettings[[name]] <- value
  }
  attr(covariateSettings, "fun") <- "getDbCohortBasedCovariatesData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

warnIfPredefined <- function(analysisId, temporal = FALSE) {
  if (temporal) {
    csvFile <- system.file("csv", "PrespecTemporalAnalyses.csv", package = "FeatureExtraction")
  } else {
    csvFile <- system.file("csv", "PrespecAnalyses.csv", package = "FeatureExtraction")
  }
  preSpecAnalysis <- read.csv(csvFile) %>%
    filter(analysisId == !!analysisId)
  if (nrow(preSpecAnalysis) > 0) {
    warning(sprintf("Analysis ID %d also used for prespecified analysis '%s'.", analysisId, preSpecAnalysis$analysisName))
  }
}
