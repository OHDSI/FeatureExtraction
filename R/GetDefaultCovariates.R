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
                                      cohortTempTable = "#cohort_person",
                                      rowIdField = "subject_id",
                                      covariateSettings,
                                      aggregated = FALSE) {
  if (!is(covariateSettings, "covariateSettings")) {
    stop("Covariate settings object not of type covariateSettings") 
  }
  settings <- .toJson(covariateSettings)
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("", package = "FeatureExtraction"))
  json <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$createSql(settings, aggregated, cohortTempTable, rowIdField, as.integer(-1), cdmDatabaseSchema)
  todo <- .fromJson(json)
  if (length(todo$tempTables) != 0) {
    writeLines("Sending temp tables to server")
    for(i in 1:length(todo$tempTables)) {
      DatabaseConnector::insertTable(connection,
                                     tableName = names(todo$tempTables)[i],
                                     data = as.data.frame(todo$tempTables[[i]]),
                                     dropTableIfExists = TRUE,
                                     createTable = TRUE,
                                     tempTable = TRUE,
                                     oracleTempSchema = oracleTempSchema)
    }
  }
  
  writeLines("Constructing features on server")
  sql <- SqlRender::translateSql(sql = todo$sqlConstruction, 
                                 targetDialect = attr(connection, "dbms"), 
                                 oracleTempSchema = oracleTempSchema)$sql
  DatabaseConnector::executeSql(connection, sql)
  
  writeLines("Fetching data from server")
  start <- Sys.time()
  # Binary or non-aggregated features
  if (!is.null(todo$sqlQueryFeatureRef)) {
    sql <- SqlRender::translateSql(sql = todo$sqlQueryFeatures, 
                                   targetDialect = attr(connection, "dbms"), 
                                   oracleTempSchema = oracleTempSchema)$sql
    covariates <- DatabaseConnector::querySql.ffdf(connection, sql)
    colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
  } else {
    covariates <- NULL
  }
  
  # Continuous aggregated features
  if (!is.null(todo$sqlQueryContinuousFeatures)) {
    sql <- SqlRender::translateSql(sql = todo$sqlQueryContinuousFeatures, 
                                   targetDialect = attr(connection, "dbms"), 
                                   oracleTempSchema = oracleTempSchema)$sql
    covariatesContinuous <- DatabaseConnector::querySql.ffdf(connection, sql)
    colnames(covariatesContinuous) <- SqlRender::snakeCaseToCamelCase(colnames(covariatesContinuous))
  } else {
    covariatesContinuous <- NULL
  }
  
  # Covariate reference
  sql <- SqlRender::translateSql(sql = todo$sqlQueryFeatureRef, 
                                 targetDialect = attr(connection, "dbms"), 
                                 oracleTempSchema = oracleTempSchema)$sql
  covariateRef <- DatabaseConnector::querySql.ffdf(connection, sql)
  colnames(covariateRef) <- SqlRender::snakeCaseToCamelCase(colnames(covariateRef))
  
  # Analysis reference
  sql <- SqlRender::translateSql(sql = todo$sqlQueryAnalysisRef, 
                                 targetDialect = attr(connection, "dbms"), 
                                 oracleTempSchema = oracleTempSchema)$sql
  analysisRef <- DatabaseConnector::querySql.ffdf(connection, sql)
  colnames(analysisRef) <- SqlRender::snakeCaseToCamelCase(colnames(analysisRef))
  
  # Population size
  sql <- "SELECT COUNT_BIG(*) FROM @cohort_table"
  sql <- SqlRender::renderSql(sql, cohort_table = cohortTempTable)$sql
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  populationSize <- DatabaseConnector::querySql(connection, sql)[1, 1]  
  
  delta <- Sys.time() - start
  writeLines(paste("Fetching data took", signif(delta, 3), attr(delta, "units")))
  
  # Drop temp tables
  sql <- SqlRender::translateSql(sql = todo$sqlCleanup, 
                                 targetDialect = attr(connection, "dbms"), 
                                 oracleTempSchema = oracleTempSchema)$sql
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  if (length(todo$idSets) != 0) {
    writeLines("Sending ID sets to server")
    for(i in 1:length(todo$idSets)) {
      sql <- "TRUNCATE TABLE @table;\nDROP TABLE @table;\n"
      sql <- SqlRender::renderSql(sql, table = names(todo$idSets)[i])$sql
      sql <- SqlRender::translateSql(sql = sql,
                                     targetDialect = attr(connection, "dbms"),
                                     oracleTempSchema = oracleTempSchema)$sql
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }
  
  covariateData <- list(covariates = covariates, 
                        covariatesContinuous = covariatesContinuous,
                        covariateRef = covariateRef, 
                        analysisRef = analysisRef,
                        metaData = list(populationSize = populationSize))
  if (nrow(covariateData$covariates) == 0) {
    warning("No data found")
  } else {
    open(covariateData$covariates)
  }
  class(covariateData) <- "covariateData"
  return(covariateData)
}
