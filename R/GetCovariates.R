# Copyright 2026 Observational Health Data Sciences and Informatics
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

#' Get covariate information from the database
#'
#' @description
#' Uses one or several covariate builder functions to construct covariates.
#'
#' @details
#' This function uses the data in the CDM to construct a large set of covariates for the provided
#' cohort. The cohort is assumed to be in an existing table with these fields: 'subject_id',
#' 'cohort_definition_id', 'cohort_start_date'. Optionally, an extra field can be added containing the
#' unique identifier that will be used as rowID in the output.
#'
#' @param connectionDetails      An R object of type \code{connectionDetails} created using the
#'                               function \code{createConnectionDetails} in the
#'                               \code{DatabaseConnector} package. Either the \code{connection} or
#'                               \code{connectionDetails} argument should be specified.
#' @param connection             A connection to the server containing the schema as created using the
#'                               \code{connect} function in the \code{DatabaseConnector} package.
#'                               Either the \code{connection} or \code{connectionDetails} argument
#'                               should be specified.
#' @param oracleTempSchema       DEPRECATED: use \code{tempEmulationSchema} instead.
#' @param cdmDatabaseSchema      The name of the database schema that contains the OMOP CDM instance.
#'                               Requires read permissions to this database. On SQL Server, this should
#'                               specify both the database and the schema, so for example
#'                               'cdm_instance.dbo'.
#' @param cdmVersion             Define the OMOP CDM version used: currently supported is "5".
#' @param cohortTable            Name of the (temp) table holding the cohort for which we want to
#'                               construct covariates
#' @param cohortDatabaseSchema   If the cohort table is not a temp table, specify the database schema
#'                               where the cohort table can be found. On SQL Server, this should
#'                               specify both the database and the schema, so for example
#'                               'cdm_instance.dbo'.
#' @param cohortTableIsTemp      Is the cohort table a temp table?
#' @param cohortId               DEPRECATED:For which cohort ID(s) should covariates be constructed? If set to -1,
#'                               covariates will be constructed for all cohorts in the specified cohort
#'                               table.
#' @param cohortIds              For which cohort ID(s) should covariates be constructed? If set to c(-1),
#'                               covariates will be constructed for all cohorts in the specified cohort
#'                               table.
#' @param rowIdField             The name of the field in the cohort table that is to be used as the
#'                               row_id field in the output table. This can be especially usefull if
#'                               there is more than one period per person.
#' @param covariateSettings      Either an object of type \code{covariateSettings} as created using one
#'                               of the createCovariate functions, or a list of such objects.
#' @param aggregated             Should aggregate statistics be computed instead of covariates per
#'                               cohort entry? If aggregated is set to FALSE, the results returned will be based
#'                               on each subject_id and cohort_start_date in your cohort table. If your cohort
#'                               contains multiple entries for the same subject_id (due to different cohort_start_date values),
#'                               you must carefully set the rowIdField so you can identify the patients properly.
#'                               See issue #229 for more discussion on this parameter.
#' @param minCharacterizationMean The minimum mean value for characterization output. Values below this will be cut off from output. This
#'                                will help reduce the file size of the characterization output, but will remove information
#'                                on covariates that have very low values. The default is 0.
#' @param tempEmulationSchema    Some database platforms like Oracle and Impala do not truly support
#'                               temp tables. To emulate temp tables, provide a schema with write
#'                               privileges where temp tables can be created.
#' @param covariateCohortDatabaseSchema The database schema where the cohorts used to define the covariates can be found.
#' @param covariateCohortTable          The table where the cohorts used to define the covariates can be found.
#'
#' @param exportToTable          Whether to export to a table rather than Andromeda object
#' @param dropTableIfExists      If targetDatabaseSchema, drop any existing tables. Otherwise, results are merged
#'                               into existing table data. Overides createTable.
#' @param createTable            Run sql to create table? Code does not check if table exists.
#' @param targetDatabaseSchema   (Optional) The name of the database schema where the resulting covariates
#'                               should be stored as a table.  If not provided, results will be fetched to R.
#' @param targetCovariateTable  (Optional) The name of the table where the resulting covariates will
#'                               be stored. If not provided, results will be fetched to R. The table can be
#'                               a permanent table in the \code{targetDatabaseSchema} or a temp table. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#' @param targetCovariateContinuousTable   (Optional) The name of the table where the resulting continuous covariates will
#'                               be stored. If not provided, results will be fetched to R. The table can be
#'                               a permanent table in the \code{targetDatabaseSchema} or a temp table. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#' @param targetCovariateRefTable (Optional) The name of the table where the covariate reference will be stored. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#'
#' @param targetAnalysisRefTable (Optional) The name of the table where the analysis reference will be stored. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#' @param targetTimeRefTable     (Optional) The name of the table for the time reference. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#'
#'
#' @return
#' Returns an object of type \code{covariateData}, containing information on the covariates.
#'
#' @examples
#' \donttest{
#' eunomiaConnectionDetails <- Eunomia::getEunomiaConnectionDetails()
#' covSettings <- createDefaultCovariateSettings()
#' Eunomia::createCohorts(
#'   connectionDetails = eunomiaConnectionDetails,
#'   cdmDatabaseSchema = "main",
#'   cohortDatabaseSchema = "main",
#'   cohortTable = "cohort"
#' )
#' covData <- getDbCovariateData(
#'   connectionDetails = eunomiaConnectionDetails,
#'   tempEmulationSchema = NULL,
#'   cdmDatabaseSchema = "main",
#'   cdmVersion = "5",
#'   cohortTable = "cohort",
#'   cohortDatabaseSchema = "main",
#'   cohortTableIsTemp = FALSE,
#'   cohortIds = -1,
#'   rowIdField = "subject_id",
#'   covariateSettings = covSettings,
#'   aggregated = FALSE
#' )
#' }
#'
#' @export
getDbCovariateData <- function(connectionDetails = NULL,
                               connection = NULL,
                               oracleTempSchema = NULL,
                               cdmDatabaseSchema,
                               cdmVersion = "5",
                               cohortTable = "cohort",
                               cohortDatabaseSchema = cdmDatabaseSchema,
                               cohortTableIsTemp = FALSE,
                               cohortId = -1,
                               cohortIds = c(-1),
                               rowIdField = "subject_id",
                               covariateSettings,
                               exportToTable = FALSE,
                               createTable = exportToTable,
                               dropTableIfExists = exportToTable,
                               targetDatabaseSchema = NULL,
                               targetCovariateTable = NULL,
                               targetCovariateContinuousTable = NULL,
                               targetCovariateRefTable = NULL,
                               targetAnalysisRefTable = NULL,
                               targetTimeRefTable = NULL,
                               aggregated = FALSE,
                               minCharacterizationMean = 0,
                               tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
                               covariateCohortDatabaseSchema = NULL,
                               covariateCohortTable = NULL) {
  if (is.null(connectionDetails) && is.null(connection)) {
    stop("Need to provide either connectionDetails or connection")
  }
  if (!is.null(connectionDetails) && !is.null(connection)) {
    stop("Need to provide either connectionDetails or connection, not both")
  }
  if (cdmVersion == "4") {
    stop("CDM version 4 is not supported any more")
  }
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
  errorMessages <- checkmate::makeAssertCollection()
  minCharacterizationMean <- utils::type.convert(minCharacterizationMean, as.is = TRUE)
  checkmate::assertNumeric(x = minCharacterizationMean, lower = 0, upper = 1, add = errorMessages)
  checkmate::reportAssertions(collection = errorMessages)
  if (!is.null(connectionDetails)) {
    connection <- DatabaseConnector::connect(connectionDetails)
    on.exit(DatabaseConnector::disconnect(connection))
  }
  if (cohortTableIsTemp) {
    if (substr(cohortTable, 1, 1) == "#") {
      cohortDatabaseSchemaTable <- cohortTable
    } else {
      cohortDatabaseSchemaTable <- paste0("#", cohortTable)
    }
  } else {
    cohortDatabaseSchemaTable <- paste(cohortDatabaseSchema, cohortTable, sep = ".")
  }

  # check for temporal features in any of the settings
  if (inherits(covariateSettings, "covariateSettings")) {
    anyTemporal <- covariateSettings$temporal | covariateSettings$temporalSequence
  } else {
    anyTemporal <- sum(unlist(lapply(
      X = covariateSettings,
      FUN = function(x) {
        sum(c(x$temporal, x$temporalSequence)) == 1
      }
    ))) > 0
  }

  # Create export tables
  # figure out tables
  if (exportToTable) {
    if (is.null(targetDatabaseSchema)) {
      # turn off create table since the tables are temp
      tempOutputTables <- TRUE
      # covariate tables
      if (substr(targetCovariateTable, 1, 1) == "#") {
        targetCovariateTable <- targetCovariateTable
      } else {
        targetCovariateTable <- paste0("#", targetCovariateTable)
      }
      # cov cont table
      if (substr(targetCovariateContinuousTable, 1, 1) == "#") {
        targetCovariateContinuousTable <- targetCovariateContinuousTable
      } else {
        targetCovariateContinuousTable <- paste0("#", targetCovariateContinuousTable)
      }
      # cov ref table
      if (substr(targetCovariateRefTable, 1, 1) == "#") {
        targetCovariateRefTable <- targetCovariateRefTable
      } else {
        targetCovariateRefTable <- paste0("#", targetCovariateRefTable)
      }
      # analysis ref table
      if (substr(targetAnalysisRefTable, 1, 1) == "#") {
        targetAnalysisRefTable <- targetAnalysisRefTable
      } else {
        targetAnalysisRefTable <- paste0("#", targetAnalysisRefTable)
      }
      # time ref table
      if (substr(targetTimeRefTable, 1, 1) == "#") {
        targetTimeRefTable <- targetTimeRefTable
      } else {
        targetTimeRefTable <- paste0("#", targetTimeRefTable)
      }
    } else {
      tempOutputTables <- FALSE
      targetCovariateTable <- paste(targetDatabaseSchema, targetCovariateTable, sep = ".")
      targetCovariateContinuousTable <- paste(targetDatabaseSchema, targetCovariateContinuousTable, sep = ".")
      targetCovariateRefTable <- paste(targetDatabaseSchema, targetCovariateRefTable, sep = ".")
      targetAnalysisRefTable <- paste(targetDatabaseSchema, targetAnalysisRefTable, sep = ".")
      targetTimeRefTable <- paste(targetDatabaseSchema, targetTimeRefTable, sep = ".")
    }

    # drop table if required
    if (dropTableIfExists) {
      message("Dropping export tables")
      sql <- SqlRender::loadRenderTranslateSql(
        sqlFilename = "DropExportTables.sql",
        packageName = "FeatureExtraction",
        dbms = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema,
        temp_tables = tempOutputTables,
        covariate_table = targetCovariateTable,
        covariate_continuous_table = targetCovariateContinuousTable,
        covariate_ref_table = targetCovariateRefTable,
        analysis_ref_table = targetAnalysisRefTable,
        time_ref_table = targetTimeRefTable
      )

      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql
      )
    }

    if (dropTableIfExists & !createTable) {
      stop("Seem to be exporting to tables but create table is FALSE and dropTable is TRUE")
    }

    # create the cohort tables if required
    if (createTable) {
      message("Creating export tables")
      sql <- SqlRender::loadRenderTranslateSql(
        sqlFilename = "CreateExportTables.sql",
        packageName = "FeatureExtraction",
        dbms = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema,
        aggregated = aggregated,
        temporal = anyTemporal,
        row_id_field = "row_id",
        covariate_table = targetCovariateTable,
        covariate_continuous_table = targetCovariateContinuousTable,
        covariate_ref_table = targetCovariateRefTable,
        analysis_ref_table = targetAnalysisRefTable,
        time_ref_table = targetTimeRefTable
      )

      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql
      )
    }
  }

  sql <- "SELECT cohort_definition_id, COUNT_BIG(*) AS population_size FROM @cohort_database_schema_table {@cohort_ids != -1} ? {WHERE cohort_definition_id IN (@cohort_ids)} GROUP BY cohort_definition_id;"
  sql <- SqlRender::render(
    sql = sql,
    cohort_database_schema_table = cohortDatabaseSchemaTable,
    cohort_ids = cohortIds
  )
  sql <- SqlRender::translate(
    sql = sql,
    targetDialect = attr(connection, "dbms"),
    tempEmulationSchema = tempEmulationSchema
  )
  temp <- DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE)
  if (aggregated) {
    populationSize <- temp$populationSize
    names(populationSize) <- temp$cohortDefinitionId
  } else {
    populationSize <- sum(temp$populationSize)
  }
  if (sum(populationSize) == 0) {
    covariateData <- createEmptyCovariateData(cohortIds, aggregated, covariateSettings$temporal)
    warning("Population is empty. No covariates were constructed")
  } else {
    if (inherits(covariateSettings, "covariateSettings")) {
      covariateSettings <- list(covariateSettings)
    }
    if (is.list(covariateSettings)) {
      covariateData <- NULL
      hasData <- function(data) {
        return(!is.null(data) && (data %>% count() %>% pull()) > 0)
      }
      if (!is.null(covariateCohortDatabaseSchema) && !is.null(covariateCohortTable)) {
        covariateSettings <- replaceCovariateSettingsCohortSchemaTable(
          covariateSettings,
          covariateCohortDatabaseSchema,
          covariateCohortTable
        )
      }

      for (i in 1:length(covariateSettings)) {
        fun <- attr(covariateSettings[[i]], "fun")
        args <- list(
          connection = connection,
          tempEmulationSchema = tempEmulationSchema,
          cdmDatabaseSchema = cdmDatabaseSchema,
          cohortTable = cohortDatabaseSchemaTable,
          cohortIds = cohortIds,
          cdmVersion = cdmVersion,
          rowIdField = rowIdField,
          covariateSettings = covariateSettings[[i]],
          targetCovariateTable = targetCovariateTable,
          targetCovariateContinuousTable = targetCovariateContinuousTable,
          targetCovariateRefTable = targetCovariateRefTable,
          targetAnalysisRefTable = targetAnalysisRefTable,
          targetTimeRefTable = targetTimeRefTable,
          aggregated = aggregated,
          minCharacterizationMean = minCharacterizationMean
        )
        tempCovariateData <- do.call(eval(parse(text = fun)), args)
        if (is.null(covariateData)) {
          covariateData <- tempCovariateData
        } else {
          if (hasData(covariateData$covariates)) {
            if (hasData(tempCovariateData$covariates)) {
              Andromeda::appendToTable(covariateData$covariates, tempCovariateData$covariates)
            }
          } else if (hasData(tempCovariateData$covariates)) {
            covariateData$covariates <- tempCovariateData$covariates
          }
          if (hasData(covariateData$covariatesContinuous)) {
            if (hasData(tempCovariateData$covariatesContinuous)) {
              Andromeda::appendToTable(covariateData$covariatesContinuous, tempCovariateData$covariatesContinuous)
            }
          } else if (hasData(tempCovariateData$covariatesContinuous)) {
            covariateData$covariatesContinuous <- tempCovariateData$covariatesContinuous
          }

          if (hasData(tempCovariateData$covariateRef)) {
            Andromeda::appendToTable(covariateData$covariateRef, tempCovariateData$covariateRef)
          }
          if (hasData(tempCovariateData$analysisRef)) {
            Andromeda::appendToTable(covariateData$analysisRef, tempCovariateData$analysisRef)
          }

          if (!exportToTable) {
            for (name in names(attr(tempCovariateData, "metaData"))) {
              if (is.null(attr(covariateData, "metaData")[[name]])) {
                attr(covariateData, "metaData")[[name]] <- attr(tempCovariateData, "metaData")[[name]]
              } else {
                attr(covariateData, "metaData")[[name]] <- list(
                  c(
                    unlist(attr(covariateData, "metaData")[[name]]),
                    attr(tempCovariateData, "metaData")[[name]]
                  )
                )
              }
            }
          } # if not exporting
        }
      }
    }

    if (!is.null(covariateData)) {
      attr(covariateData, "metaData")$populationSize <- populationSize
      attr(covariateData, "metaData")$cohortIds <- cohortIds
    }
  }
  return(invisible(covariateData))
}
