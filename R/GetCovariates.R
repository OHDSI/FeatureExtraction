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
#' @param oracleTempSchema       A schema where temp tables can be created in Oracle.
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
#'                               cohort entry?
#' @param minCharacterizationMean The minimum mean value for characterization output. Values below this will be cut off from output. This
#'                                will help reduce the file size of the characterization output, but will remove information
#'                                on covariates that have very low values. The default is 0.
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
#'   oracleTempSchema = NULL,
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
                               aggregated = FALSE,
                               minCharacterizationMean = 0) {
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
  sql <- "SELECT cohort_definition_id, COUNT_BIG(*) AS population_size FROM @cohort_database_schema_table {@cohort_ids != -1} ? {WHERE cohort_definition_id IN (@cohort_ids)} GROUP BY cohort_definition_id;"
  sql <- SqlRender::render(
    sql = sql,
    cohort_database_schema_table = cohortDatabaseSchemaTable,
    cohort_ids = cohortIds
  )
  sql <- SqlRender::translate(
    sql = sql,
    targetDialect = attr(connection, "dbms"),
    oracleTempSchema = oracleTempSchema
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
      for (i in 1:length(covariateSettings)) {
        fun <- attr(covariateSettings[[i]], "fun")
        args <- list(
          connection = connection,
          oracleTempSchema = oracleTempSchema,
          cdmDatabaseSchema = cdmDatabaseSchema,
          cohortTable = cohortDatabaseSchemaTable,
          cohortIds = cohortIds,
          cdmVersion = cdmVersion,
          rowIdField = rowIdField,
          covariateSettings = covariateSettings[[i]],
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
            } else if (hasData(tempCovariateData$covariatesContinuous)) {
              covariateData$covariatesContinuous <- tempCovariateData$covariatesContinuous
            }
          }
          Andromeda::appendToTable(covariateData$covariateRef, tempCovariateData$covariateRef)
          Andromeda::appendToTable(covariateData$analysisRef, tempCovariateData$analysisRef)
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
        }
      }
    }
    attr(covariateData, "metaData")$populationSize <- populationSize
    attr(covariateData, "metaData")$cohortIds <- cohortIds
  }
  return(covariateData)
}
