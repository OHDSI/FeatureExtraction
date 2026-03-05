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
#' @param targetCovariateTable  (Optional) The name of the table where the resulting covariates will
#'                               be stored. If not provided, results will be fetched to R. The table can be
#'                               a permanent table in the \code{targetDatabaseSchema} or a temp table. If
#'                               it is a temp table, do not specify \code{targetDatabaseSchema}.
#' @param targetCovariateContinuousTable (Optional) The name of the table where the resulting continuous covariates should be stored.
#' @param targetCovariateRefTable (Optional) The name of the table where the covariate reference will be stored.
#'
#' @param targetAnalysisRefTable (Optional) The name of the table where the analysis reference will be stored.
#' @param targetTimeRefTable     (Optional) The name of the table for the time reference
#' @param minCharacterizationMean The minimum mean value for binary characterization output. Values below this will be cut off from output. This
#'                                will help reduce the file size of the characterization output, but will remove information
#'                                on covariates that have very low values. The default is 0.
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
#'   covariateSettings = createDefaultCovariateSettings()
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
                                      targetDatabaseSchema = NULL,
                                      targetCovariateTable = NULL,
                                      targetCovariateContinuousTable = NULL,
                                      targetCovariateRefTable = NULL,
                                      targetAnalysisRefTable = NULL,
                                      targetTimeRefTable = NULL,
                                      aggregated = FALSE,
                                      minCharacterizationMean = 0,
                                      tempEmulationSchema = getOption("sqlRenderTempEmulationSchema")) {
  if (!is(covariateSettings, "covariateSettings")) {
    stop("Covariate settings object not of type covariateSettings")
  }
  if (cdmVersion == "4") {
    stop("Common Data Model version 4 is not supported")
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


  targetTables <- list(
    covariates = targetCovariateTable,
    covariatesContinuous = targetCovariateContinuousTable,
    covariateRef = targetCovariateRefTable,
    analysisRef = targetAnalysisRefTable,
    timeRef = targetTimeRefTable
  )
  # Is the target schema missing or are all the specified tables temp
  allTempTables <- all(substr(targetTables, 1, 1) == "#")
  extractToAndromeda <- is.null(targetCovariateTable)


  settings <- .toJson(covariateSettings)
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("", package = "FeatureExtraction"))
  json <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$createSql(
    settings, aggregated, cohortTable, rowIdField, rJava::.jarray(as.character(cohortIds)), cdmDatabaseSchema, as.character(minCharacterizationMean)
  )
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
        tempEmulationSchema = tempEmulationSchema
      )
    }
  }

  ParallelLogger::logInfo("Constructing features on server")

  sql <- SqlRender::translate(
    sql = todo$sqlConstruction,
    targetDialect = attr(connection, "dbms"),
    tempEmulationSchema = tempEmulationSchema
  )
  profile <- (!is.null(getOption("dbProfile")) && getOption("dbProfile") == TRUE)
  DatabaseConnector::executeSql(connection, sql, profile = profile)

  # Now we extract the results into Andromeda tables or as tables
  ParallelLogger::logInfo("Fetching data from server")
  start <- Sys.time()
  covariateData <- Andromeda::andromeda()

  # Binary or non-aggregated features
  if (!is.null(todo$sqlQueryFeatures)) {
    # etracting covariate table
    if (extractToAndromeda) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryFeatures,
        targetDialect = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "covariates",
        snakeCaseToCamelCase = TRUE
      )
    } else {
      # for testing to see column order
      # print(todo$sqlQueryFeatures)

      sql <- "
      INSERT INTO @target_covariate_table(

      {@temporal | @temporal_sequence} ? {time_id,}

      {@aggregated}?{
      cohort_definition_id,
      covariate_id,
      sum_value,
      average_value
      }:{
      covariate_id,
      row_id,
      covariate_value
      }

      ) @sub_query; "

      sql <- SqlRender::render(
        sql = sql,
        target_covariate_table = targetTables$covariates,
        sub_query = gsub(";", "", todo$sqlQueryFeatures),
        temporal = covariateSettings$temporal,
        temporal_sequence = covariateSettings$temporalSequence,
        aggregated = aggregated
      )

      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = DatabaseConnector::dbms(connection),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql
      )
    }
  }

  # Continuous aggregated features
  if (!is.null(todo$sqlQueryContinuousFeatures)) {
    if (extractToAndromeda) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryContinuousFeatures,
        targetDialect = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "covariatesContinuous",
        snakeCaseToCamelCase = TRUE
      )
    } else {
      sql <- "
      INSERT INTO @target_covariate_continuous_table(
      {@aggregated}?{

      cohort_definition_id,
      covariate_id,
      {@temporal | @temporal_sequence} ? {time_id,}
      count_value,
      min_value,
      max_value,
      average_value,
      standard_deviation,
      median_value,
      p10_value,
      p25_value,
      p75_value,
      p90_value

      }:{

      covariate_id,
      {@temporal | @temporal_sequence} ? {time_id,}
      row_id,
      covariate_value

      }

      ) @sub_query;"

      sql <- SqlRender::render(
        sql = sql,
        target_covariate_continuous_table = targetTables$covariatesContinuous,
        sub_query = gsub(";", "", todo$sqlQueryContinuousFeatures),
        temporal = covariateSettings$temporal,
        temporal_sequence = covariateSettings$temporalSequence,
        aggregated = aggregated
      )

      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = DatabaseConnector::dbms(connection),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql
      )
    }
  }

  # Covariate reference
  if (!is.null(todo$sqlQueryFeatureRef)) {
    if (extractToAndromeda) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryFeatureRef,
        targetDialect = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "covariateRef",
        snakeCaseToCamelCase = TRUE
      )

      collisions <- covariateData$covariateRef %>%
        dplyr::filter(collisions > 0) %>%
        dplyr::collect()

      if (nrow(collisions) > 0) {
        warning(sprintf(
          "Collisions in covariate IDs detected for post-coordinated concepts with covariate IDs %s",
          paste(collisions$covariateId, paste = ", ")
        ))
      }
    } else {
      sql <- "
      INSERT INTO @target_covariate_ref_table(
      covariate_id,
	    covariate_name,
	    analysis_id,
	    concept_id,
	    value_as_concept_id,
	    collisions
      ) @sub_query ;"

      sql <- SqlRender::render(
        sql = sql,
        target_covariate_ref_table = targetTables$covariateRef,
        sub_query = gsub(";", "", todo$sqlQueryFeatureRef)
      )

      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = DatabaseConnector::dbms(connection),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql
      )
    }
  }


  # Analysis reference
  if (!is.null(todo$sqlQueryAnalysisRef)) {
    if (extractToAndromeda) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryAnalysisRef,
        targetDialect = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "analysisRef",
        snakeCaseToCamelCase = TRUE
      )
    } else {
      sql <- "
      INSERT INTO @target_analysis_ref_table(
      	analysis_id,
	      analysis_name,
	      domain_id,
        {!@temporal} ? {
	        start_day,
	        end_day,
        }
	      is_binary,
	      missing_means_zero
      ) @sub_query ;"

      sql <- SqlRender::render(
        sql = sql,
        target_analysis_ref_table = targetTables$analysisRef,
        sub_query = gsub(";", "", todo$sqlQueryAnalysisRef),
        temporal = covariateSettings$temporal | covariateSettings$temporalSequence
      )

      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = DatabaseConnector::dbms(connection),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql
      )
    }
  }


  # Time reference
  if (!is.null(todo$sqlQueryTimeRef)) {
    if (extractToAndromeda) {
      sql <- SqlRender::translate(
        sql = todo$sqlQueryTimeRef,
        targetDialect = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::querySqlToAndromeda(
        connection = connection,
        sql = sql,
        andromeda = covariateData,
        andromedaTableName = "timeRef",
        snakeCaseToCamelCase = TRUE
      )
    } else {
      # TODO - what columns are in time ref table?!
      sql <- "
      INSERT INTO @target_time_ref_table(
      	time_part,
      	time_interval,
      	sequence_start_day,
      	sequence_end_day
      ) @sub_query;"

      sql <- SqlRender::render(
        sql = sql,
        target_covariate_ref_table = targetTables$timeRef,
        sub_query = gsub(";", "", todo$sqlQueryTimeRef)
      )

      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = DatabaseConnector::dbms(connection),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::executeSql(
        connection = connection,
        sql = sql
      )
    }
  }

  delta <- Sys.time() - start
  ParallelLogger::logInfo("Fetching data took ", signif(delta, 3), " ", attr(delta, "units"))

  # Drop temp tables
  sql <- SqlRender::translate(
    sql = todo$sqlCleanup,
    targetDialect = attr(connection, "dbms"),
    tempEmulationSchema = tempEmulationSchema
  )
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  if (length(todo$tempTables) != 0) {
    for (i in 1:length(todo$tempTables)) {
      sql <- "TRUNCATE TABLE @table;\nDROP TABLE @table;\n"
      sql <- SqlRender::render(sql, table = names(todo$tempTables)[i])
      sql <- SqlRender::translate(
        sql = sql,
        targetDialect = attr(connection, "dbms"),
        tempEmulationSchema = tempEmulationSchema
      )
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }

  if (extractToAndromeda) {
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
  } else {
    return(invisible(NULL))
  }
}
