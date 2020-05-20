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

#' Getcovariate information from the database through the cohort_attribute table
#'
#' @description
#' Constructs covariates using the cohort_attribute table.
#'
#' @param covariateSettings   An object of type \code{covariateSettings} as created using the
#'                            \code{\link{createCohortAttrCovariateSettings}} function.
#'
#' @template GetCovarParams
#'
#' @export
getDbCohortAttrCovariatesData <- function(connection,
                                          oracleTempSchema = NULL,
                                          cdmDatabaseSchema,
                                          cohortTable = "#cohort_person",
                                          cohortId = -1,
                                          cdmVersion = "5",
                                          rowIdField = "subject_id",
                                          covariateSettings,
                                          aggregated = FALSE) {
  if (aggregated) {
    stop("Aggregation not implemented for covariates from cohort attributes.")
  }
  if (cdmVersion == "4") {
    stop("Common Data Model version 4 is not supported")
  }
  start <- Sys.time()
  writeLines("Constructing covariates from cohort attributes table")
  
  if (is.null(covariateSettings$includeAttrIds) || length(covariateSettings$includeAttrIds) == 0) {
    hasIncludeAttrIds <- FALSE
  } else {
    if (!is.numeric(covariateSettings$includeAttrIds))
      stop("includeAttrIds must be a (vector of) numeric")
    hasIncludeAttrIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#included_attr",
                                   data = data.frame(attribute_definition_id = as.integer(covariateSettings$includeAttrIds)),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
  }
  
  renderedSql <- SqlRender::loadRenderTranslateSql("GetAttrCovariates.sql",
                                                   packageName = "FeatureExtraction",
                                                   dbms = attr(connection, "dbms"),
                                                   oracleTempSchema = oracleTempSchema,
                                                   attr_database_schema = covariateSettings$attrDatabaseSchema,
                                                   cohort_table = cohortTable,
                                                   row_id_field = rowIdField,
                                                   cohort_attribute_table = covariateSettings$cohortAttrTable,
                                                   has_include_attr_ids = hasIncludeAttrIds)
  
  covariates <- DatabaseConnector::querySql(connection, renderedSql, snakeCaseToCamelCase = TRUE)  
  covariateRefSql <- "SELECT attribute_definition_id AS covariate_id, attribute_name AS covariate_name FROM @attr_database_schema.@attr_definition_table ORDER BY attribute_definition_id"
  covariateRefSql <- SqlRender::render(covariateRefSql,
                                       attr_database_schema = covariateSettings$attrDatabaseSchema,
                                       attr_definition_table = covariateSettings$attrDefinitionTable)
  covariateRefSql <- SqlRender::translate(sql = covariateRefSql,
                                          targetDialect = attr(connection, "dbms"),
                                          oracleTempSchema = oracleTempSchema)
  covariateRef <- DatabaseConnector::querySql(connection, covariateRefSql, snakeCaseToCamelCase = TRUE)
  covariateRef$analysisId <- rep(as.numeric(covariateSettings$analysisId), length = nrow(covariateRef))
  covariateRef$conceptId <- rep(0, length = nrow(covariateRef))
  
  analysisRef <- data.frame(analysisId = as.numeric(covariateSettings$analysisId),
                            analysisName = "Covariates from cohort attributes",
                            domainId = "Cohort",
                            startDay = as.numeric(NA),
                            endDay = as.numeric(NA),
                            isBinary = if (covariateSettings$isBinary) {"Y"} else {"N"},
                            missingMeansZero = if (covariateSettings$missingMeansZero) {"Y"} else {"N"})
  delta <- Sys.time() - start
  writeLines(paste("Loading took", signif(delta, 3), attr(delta, "units")))
  
  result <- Andromeda::andromeda(covariates = covariates, 
                                 covariateRef = covariateRef, 
                                 analysisRef = analysisRef)
  attr(result, "metaData") <- list()
  class(result) <- "CovariateData"
  attr(class(result), "package") <- "FeatureExtraction"
  return(result)
}

#' Create cohort attribute covariate settings
#'
#' @details
#' Creates an object specifying where the cohort attributes can be found to construct covariates. The
#' attributes should be defined in a table with the same structure as the attribute_definition table
#' in the Common Data Model. It should at least have these columns: \describe{
#' \item{attribute_definition_id}{A unique identifier of type integer.} \item{attribute_name}{A short
#' description of the attribute.} } The cohort attributes themselves should be stored in a table with
#' the same format as the cohort_attribute table in the Common Data Model. It should at least have
#' these columns: \describe{ \item{cohort_definition_id}{A key to link to the cohort table.}
#' \item{subject_id}{A key to link to the cohort table.} \item{cohort_start_date}{A key to link to the
#' cohort table.} \item{attribute_definition_id}{An foreign key linking to the attribute definition
#' table.} \item{value_as_number}{A real number.} }
#'
#' @param analysisId            A unique identifier for this analysis.
#' @param attrDatabaseSchema    The database schema where the attribute definition and cohort attribute
#'                              table can be found.
#' @param attrDefinitionTable   The name of the attribute definition table.
#' @param cohortAttrTable       The name of the cohort attribute table.
#' @param includeAttrIds        (optional) A list of attribute definition IDs to restrict to.
#' @param isBinary              Needed for aggregation: Are these binary variables? Binary 
#'                              variables should only have the values 0 or 1.
#' @param missingMeansZero      Needed for aggregation: For continuous values, should missing
#'                              values be interpreted as 0?
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#'
#' @export
createCohortAttrCovariateSettings <- function(analysisId = -1,
                                              attrDatabaseSchema,
                                              attrDefinitionTable = "attribute_definition",
                                              cohortAttrTable = "cohort_attribute",
                                              includeAttrIds = c(),
                                              isBinary = FALSE,
                                              missingMeansZero = FALSE) {
  # First: get the default values:
  covariateSettings <- list()
  for (name in names(formals(createCohortAttrCovariateSettings))) {
    covariateSettings[[name]] <- get(name)
  }
  # Next: overwrite defaults with actual values if specified:
  values <- lapply(as.list(match.call())[-1], function(x) eval(x, envir = sys.frame(-3)))
  for (name in names(values)) {
    if (name %in% names(covariateSettings))
      covariateSettings[[name]] <- values[[name]]
  }
  
  attr(covariateSettings, "fun") <- "getDbCohortAttrCovariatesData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
