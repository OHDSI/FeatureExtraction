# Copyright 2021 Observational Health Data Sciences and Informatics
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
#'                               should be stored.  If not provided, results will be fetched to R.
#' @param targetTables           (Optional) list of mappings for table names.
#'                               The names of the table where the resulting covariates will be if
#'                               \code{targetDatabaseSchema} is specified. The tables will be created in permanent
#'                               table in the \code{targetDatabaseSchema} or as temporary tables. Tables that can be
#'                               included in this list: covariates, covariateRef, analysisRef, covariatesContinuous,
#'                               timeRef
#' @param targetCovariateTable  (Optional) The name of the table where the resulting covariates will
#'                               be stored. If not provided, results will be fetched to R. The table can be
#'                               a permanent table in the \code{targetDatabaseSchema} or a temp table. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#'                               Superseded by \code{targetTables}
#' @param targetCovariateRefTable (Optional) The name of the table where the covariate reference will be stored.
#'                               Superseded by \code{targetTables}
#' @param targetAnalysisRefTable (Optional) The name of the table where the analysis reference will be stored.
#'                               Superseded by \code{targetTables}
#' @param dropTableIfExists      If targetDatabaseSchema, drop any existing tables. Otherwise, results are merged
#'                               into existing table data. Overides createTable.
#' @param createTable            Run sql to create table? Code does not check if table exists.
#' @template GetCovarParams
#'
#' @export
getDbDefaultCovariateData <- function(connection,
                                      oracleTempSchema = NULL,
                                      cdmDatabaseSchema,
                                      cohortTable = "#cohort_person",
                                      cohortId = -1,
                                      cdmVersion = "5",
                                      rowIdField = "subject_id",
                                      covariateSettings,
                                      targetDatabaseSchema = NULL,
                                      targetCovariateTable = NULL,
                                      targetCovariateRefTable = NULL,
                                      targetAnalysisRefTable = NULL,
                                      targetTables = list(
                                        covariates = targetCovariateTable,
                                        covariateRef = targetCovariateRefTable,
                                        analysisRef = targetAnalysisRefTable
                                      ),
                                      dropTableIfExists = FALSE,
                                      createTable = TRUE,
                                      aggregated = FALSE) {
  if (!is(covariateSettings, "covariateSettings")) {
    stop("Covariate settings object not of type covariateSettings")
  }
  if (cdmVersion == "4") {
    stop("Common Data Model version 4 is not supported")
  }

  settings <- .toJson(covariateSettings)
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("", package = "FeatureExtraction"))
  json <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$createSql(settings, aggregated, cohortTable, rowIdField, rJava::.jarray(as.character(cohortId)), cdmDatabaseSchema)
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
                                     oracleTempSchema = oracleTempSchema)
    }
  }

  ParallelLogger::logInfo("Constructing features on server")

  sql <- SqlRender::translate(sql = todo$sqlConstruction,
                              targetDialect = attr(connection, "dbms"),
                              oracleTempSchema = oracleTempSchema)
  profile <- (!is.null(getOption("dbProfile")) && getOption("dbProfile") == TRUE)
  DatabaseConnector::executeSql(connection, sql, profile = profile)
  # Is the target schema missing or are all the specified tables temp
  allTempTables <- all(substr(targetTables,1,1) == "#")
  if ((missing(targetDatabaseSchema) | is.null(targetDatabaseSchema)) & !allTempTables) {
    # Save to Andromeda
    covariateData <- Andromeda::andromeda()

    queryFunction <- function(sql, tableName) {
      DatabaseConnector::querySqlToAndromeda(connection = connection,
                                             sql = sql,
                                             andromeda = covariateData,
                                             andromedaTableName = tableName,
                                             snakeCaseToCamelCase = TRUE)
    }
    ParallelLogger::logInfo("Fetching data from server")
  } else {

    if (dropTableIfExists) {
      createTable <- TRUE
    }
    # Save to DB
    ParallelLogger::logInfo("Creating tables on server")
    convertQuery <- function(sql, table) {
      outerSql <- "
      {@drop} ? {
        IF OBJECT_ID('@table', 'U') IS NOT NULL
          DROP TABLE @table;
      }
      {@create} ? {
      SELECT * INTO @table FROM ( @sub_query ) sq;
      } : {
      INSERT INTO @table @sub_query;
      }
      "
      SqlRender::render(outerSql,
                        sub_query = gsub(";", "", sql),
                        create = createTable,
                        drop = dropTableIfExists,
                        table = table)
    }

    queryFunction <- function(sql, table) {
      mappedTable <- targetTables[[table]]
      if (is.null(mappedTable)) {
        if (allTempTables) {
          # Only bother storing specified temp tables
          ParallelLogger::logInfo("Skipping", table, " other mapped tables are temp")
          return(NULL)
        }
        mappedTable <- SqlRender::camelCaseToSnakeCase(table)
      }

      if (substr(mappedTable, 1, 1) != "#") {
        mappedTable <- paste0(targetDatabaseSchema, ".", mappedTable)
      }

      if (createTable) {
        ParallelLogger::logInfo("Creating table ", mappedTable, " for ", table)
      } else {
        ParallelLogger::logInfo("Appending", table, " results to table ", mappedTable)
      }

      sql <- convertQuery(sql, mappedTable)
      DatabaseConnector::renderTranslateExecuteSql(connection,
                                                   sql,
                                                   tempEmulationSchema = oracleTempSchema,
                                                   progressBar = FALSE,
                                                   reportOverallTime = FALSE)
    }

  }

  start <- Sys.time()
  # Binary or non-aggregated features
  if (!is.null(todo$sqlQueryFeatures)) {
    sql <- SqlRender::translate(sql = todo$sqlQueryFeatures,
                                targetDialect = attr(connection, "dbms"),
                                oracleTempSchema = oracleTempSchema)
    queryFunction(sql, "covariates")
  }

  # Continuous aggregated features
  if (!is.null(todo$sqlQueryContinuousFeatures)) {
    sql <- SqlRender::translate(sql = todo$sqlQueryContinuousFeatures,
                                targetDialect = attr(connection, "dbms"),
                                oracleTempSchema = oracleTempSchema)
    queryFunction(sql, "covariatesContinuous")
  }

  # Covariate reference
  sql <- SqlRender::translate(sql = todo$sqlQueryFeatureRef,
                              targetDialect = attr(connection, "dbms"),
                              oracleTempSchema = oracleTempSchema)

  queryFunction(sql, "covariateRef")

  # Analysis reference
  sql <- SqlRender::translate(sql = todo$sqlQueryAnalysisRef,
                              targetDialect = attr(connection, "dbms"),
                              oracleTempSchema = oracleTempSchema)
  queryFunction(sql, "analysisRef")

  # Time reference
  if (!is.null(todo$sqlQueryTimeRef)) {
    sql <- SqlRender::translate(sql = todo$sqlQueryTimeRef,
                                targetDialect = attr(connection, "dbms"),
                                oracleTempSchema = oracleTempSchema)
    queryFunction(sql, "timeRef")
  }

  delta <- Sys.time() - start
  ParallelLogger::logInfo("Fetching data took ", signif(delta, 3), " ", attr(delta, "units"))

  # Drop temp tables
  sql <- SqlRender::translate(sql = todo$sqlCleanup,
                              targetDialect = attr(connection, "dbms"),
                              oracleTempSchema = oracleTempSchema)
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  if (length(todo$tempTables) != 0) {
    for (i in 1:length(todo$tempTables)) {
      sql <- "TRUNCATE TABLE @table;\nDROP TABLE @table;\n"
      sql <- SqlRender::render(sql, table = names(todo$tempTables)[i])
      sql <- SqlRender::translate(sql = sql,
                                  targetDialect = attr(connection, "dbms"),
                                  oracleTempSchema = oracleTempSchema)
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }

  if ((missing(targetDatabaseSchema) | is.null(targetDatabaseSchema)) & !allTempTables) {
    attr(covariateData, "metaData") <- list()
    if (is.null(covariateData$covariates) && is.null(covariateData$covariatesContinuous)) {
      warning("No data found, probably because no covariates were specified.")
      covariateData <- createEmptyCovariateData(cohortId = cohortId,
                                                aggregated = aggregated,
                                                temporal = covariateSettings$temporal)
    }
    class(covariateData) <- "CovariateData"
    attr(class(covariateData), "package") <- "FeatureExtraction"
    return(covariateData)
  }
}
