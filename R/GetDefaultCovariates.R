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

#' Get default covariate information from the database
#'
#' @description
#' Constructs a large default set of covariates for one or more cohorts using data in the CDM schema.
#' Includes covariates for all drugs, drug classes, condition, condition classes, procedures,
#' observations, etc.
#'
#' @param covariateSettings      Either an object of type \code{covariateSettings} as created using one
#'                               of the createCovariate functions, or a list of such objects.
#' @param targetDatabaseSchema   (Optional) The name of the database schema where the resulting covariates
#'                               should be stored.
#' @param targetCovariateTable  (Optional) The name of the table where the resulting covariates will
#'                               be stored. If not provided, results will be fetched to R. The table can be
#'                               a permanent table in the \code{targetDatabaseSchema} or a temp table. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#' @param targetCovariateRefTable (Optional) The name of the table where the covariate reference will be stored.
#' @param targetAnalysisRefTable (Optional) The name of the table where the analysis reference will be stored.
#' @param minCharacterizationMean The minimum mean value for binary characterization output. Values below this will be cut off from output. This
#'                                will help reduce the file size of the characterization output, but will remove information
#'                                on covariates that have very low values. The default is 0.
#'
#' @template GetCovarParams
#'
#' @examples
#' \donttest{
#' connectionDetails <- Eunomia::getEunomiaConnectionDetails()
#' Eunomia::createCohorts(
#'   connectionDetails = connectionDetails,
#'   cdmDatabaseSchema = "main",
#'   cohortDatabaseSchema = "main",
#'   cohortTable = "cohort"
#' )
#' connection <- DatabaseConnector::connect(connectionDetails)
#'
#' results <- getDbDefaultCovariateData(
#'   connection = connection,
#'   cdmDatabaseSchema = "main",
#'   cohortTable = "cohort",
#'   covariateSettings = createDefaultCovariateSettings(),
#'   targetDatabaseSchema = "main",
#'   targetCovariateTable = "ut_cov"
#' )
#' }
#' @export
getDbDefaultCovariateData <- function(connection,
                                      oracleTempSchema = NULL,
                                      cdmDatabaseSchema,
                                      cohortTable = "#cohort_person",
                                      cohortId = -1,
                                      cohortIds = c(-1),
                                      cdmVersion = "5",
                                      rowIdField = "subject_id",
                                      covariateSettings,
                                      targetDatabaseSchema,
                                      targetCovariateTable,
                                      targetCovariateRefTable,
                                      targetAnalysisRefTable,
                                      aggregated = FALSE,
                                      minCharacterizationMean = 0) {
  if (!is(covariateSettings, "covariateSettings")) {
    stop("Covariate settings object not of type covariateSettings")
  }
  if (cdmVersion == "4") {
    stop("Common Data Model version 4 is not supported")
  }
  if (!missing(targetCovariateTable) && !is.null(targetCovariateTable) && aggregated) {
    stop("Writing aggregated results to database is currently not supported")
  }
  if (!missing(cohortId)) {
    warning("cohortId argument has been deprecated, please use cohortIds")
    cohortIds <- cohortId
  }
  errorMessages <- checkmate::makeAssertCollection()
  minCharacterizationMean <- utils::type.convert(minCharacterizationMean, as.is = TRUE)
  checkmate::assertNumeric(x = minCharacterizationMean, lower = 0, upper = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)

  settings <- .toJson(covariateSettings)
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("", package = "FeatureExtraction"))
  json <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$createSql(settings, aggregated, cohortTable, rowIdField, rJava::.jarray(as.character(cohortIds)), cdmDatabaseSchema)
  todo <- .fromJson(json)
  if (length(todo$tempTables) != 0) {
    ParallelLogger::logInfo("Sending temp tables to server")
    for (i in 1:length(todo$tempTables)) {
      DatabaseConnector::insertTable(connection,
        tableName = names(todo$tempTables)[i],
        data = as.data.frame(todo$tempTables[[i]]),
        dropTableIfExists = TRUE,
        createTable = TRUE,
        tempTable = TRUE,
        oracleTempSchema = oracleTempSchema
      )
    }
  }

  ParallelLogger::logInfo("Constructing features on server")

  sql <- SqlRender::translate(
    sql = todo$sqlConstruction,
    targetDialect = attr(connection, "dbms"),
    oracleTempSchema = oracleTempSchema
  )
  profile <- (!is.null(getOption("dbProfile")) && getOption("dbProfile") == TRUE)
  DatabaseConnector::executeSql(connection, sql, profile = profile)

  if (missing(targetCovariateTable) || is.null(targetCovariateTable)) {
    ParallelLogger::logInfo("Fetching data from server")
    start <- Sys.time()
    # Binary or non-aggregated features
    covariateData <- Andromeda::andromeda()
    if (!is.null(todo$sqlQueryFeatures)) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryFeatures,
        targetDialect = attr(connection, "dbms"),
        oracleTempSchema = oracleTempSchema
      )

      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "covariates",
        snakeCaseToCamelCase = TRUE
      )
      filterCovariateDataCovariates(covariateData, "covariates", minCharacterizationMean)
    }

    # Continuous aggregated features
    if (!is.null(todo$sqlQueryContinuousFeatures)) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryContinuousFeatures,
        targetDialect = attr(connection, "dbms"),
        oracleTempSchema = oracleTempSchema
      )
      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "covariatesContinuous",
        snakeCaseToCamelCase = TRUE
      )
    }

    # Covariate reference
    sql <- SqlRender::translate(
      sql = todo$sqlQueryFeatureRef,
      targetDialect = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema
    )

    DatabaseConnector::querySqlToAndromeda(
      connection = connection,
      sql = sql,
      andromeda = covariateData,
      andromedaTableName = "covariateRef",
      snakeCaseToCamelCase = TRUE
    )
    collisions <- covariateData$covariateRef %>%
      filter(collisions > 0) %>%
      collect()
    if (nrow(collisions) > 0) {
      warning(sprintf(
        "Collisions in covariate IDs detected for post-coordinated concepts with covariate IDs %s",
        paste(collisions$covariateId, paste = ", ")
      ))
    }

    # Analysis reference
    sql <- SqlRender::translate(
      sql = todo$sqlQueryAnalysisRef,
      targetDialect = attr(connection, "dbms"),
      oracleTempSchema = oracleTempSchema
    )
    DatabaseConnector::querySqlToAndromeda(
      connection = connection,
      sql = sql,
      andromeda = covariateData,
      andromedaTableName = "analysisRef",
      snakeCaseToCamelCase = TRUE
    )

    # Time reference
    if (!is.null(todo$sqlQueryTimeRef)) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryTimeRef,
        targetDialect = attr(connection, "dbms"),
        oracleTempSchema = oracleTempSchema
      )
      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "timeRef",
        snakeCaseToCamelCase = TRUE
      )
    }


    delta <- Sys.time() - start
    ParallelLogger::logInfo("Fetching data took ", signif(delta, 3), " ", attr(delta, "units"))
  } else {
    # Don't fetch to R , but create on server instead
    ParallelLogger::logInfo("Writing data to table")
    start <- Sys.time()
    convertQuery <- function(sql, databaseSchema, table) {
      if (missing(databaseSchema) || is.null(databaseSchema)) {
        tableName <- table
      } else {
        tableName <- paste(databaseSchema, table, sep = ".")
      }
      return(sub("FROM", paste("INTO", tableName, "FROM"), sql))
    }

    # Covariates
    if (!is.null(todo$sqlQueryFeatures)) {
      sql <- convertQuery(todo$sqlQueryFeatures, targetDatabaseSchema, targetCovariateTable)
      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = attr(connection, "dbms"),
        oracleTempSchema = oracleTempSchema
      )
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }

    # Covariate reference
    if (!missing(targetCovariateRefTable) && !is.null(targetCovariateRefTable)) {
      sql <- convertQuery(todo$sqlQueryFeatureRef, targetDatabaseSchema, targetCovariateRefTable)
      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = attr(connection, "dbms"),
        oracleTempSchema = oracleTempSchema
      )
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }

    # Analysis reference
    if (!missing(targetAnalysisRefTable) && !is.null(targetAnalysisRefTable)) {
      sql <- convertQuery(todo$sqlQueryAnalysisRef, targetDatabaseSchema, targetAnalysisRefTable)
      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = attr(connection, "dbms"),
        oracleTempSchema = oracleTempSchema
      )
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
    delta <- Sys.time() - start
    ParallelLogger::logInfo("Writing data took", signif(delta, 3), " ", attr(delta, "units"))
  }
  # Drop temp tables
  sql <- SqlRender::translate(
    sql = todo$sqlCleanup,
    targetDialect = attr(connection, "dbms"),
    oracleTempSchema = oracleTempSchema
  )
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  if (length(todo$tempTables) != 0) {
    for (i in 1:length(todo$tempTables)) {
      sql <- "TRUNCATE TABLE @table;\nDROP TABLE @table;\n"
      sql <- SqlRender::render(sql, table = names(todo$tempTables)[i])
      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = attr(connection, "dbms"),
        oracleTempSchema = oracleTempSchema
      )
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }

  if (missing(targetCovariateTable) || is.null(targetCovariateTable)) {
    attr(covariateData, "metaData") <- list()
    if (is.null(covariateData$covariates) && is.null(covariateData$covariatesContinuous)) {
      warning("No data found, probably because no covariates were specified.")
      covariateData <- createEmptyCovariateData(
        cohortIds = cohortIds,
        aggregated = aggregated,
        temporal = covariateSettings$temporal
      )
    }
    class(covariateData) <- "CovariateData"
    attr(class(covariateData), "package") <- "FeatureExtraction"
    return(covariateData)
  }
}

#' Filters the covariateData covariates based on the given characterization mean value.
#'
#' @param covariateData The covariate data
#' @param covariatesName The name of the covariates object inside the covariateData
#' @param minCharacterizationMean The minimum mean value for characterization output. Values below this will be cut off from output. This
#'                                will help reduce the file size of the characterization output, but will remove information
#'                                on covariates that have very low values. The default is 0.
filterCovariateDataCovariates <- function(covariateData, covariatesName, minCharacterizationMean = 0) {
  if ("averageValue" %in% colnames(covariateData[[covariatesName]]) && minCharacterizationMean != 0) {
    covariateData[[covariatesName]] <- covariateData[[covariatesName]] %>%
      dplyr::filter(.data$averageValue >= minCharacterizationMean)
  }
}
