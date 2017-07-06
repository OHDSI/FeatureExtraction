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
#'                               specifiy both the database and the schema, so for example
#'                               'cdm_instance.dbo'.
#' @param cdmVersion             Define the OMOP CDM version used: currently support "4" and "5".
#' @param cohortTable            Name of the (temp) table holding the cohort for which we want to
#'                               construct covariates
#' @param cohortDatabaseSchema   If the cohort table is not a temp table, specify the database schema
#'                               where the cohort table can be found. On SQL Server, this should
#'                               specifiy both the database and the schema, so for example
#'                               'cdm_instance.dbo'.
#' @param cohortTableIsTemp      Is the cohort table a temp table?
#' @param cohortIds              For which cohort IDs should covariates be constructed? If left empty,
#'                               covariates will be constructed for all cohorts in the specified cohort
#'                               table.
#' @param rowIdField             The name of the field in the cohort table that is to be used as the
#'                               row_id field in the output table. This can be especially usefull if
#'                               there is more than one period per person.
#' @param covariateSettings      Either an object of type \code{covariateSettings} as created using one
#'                               of the createCovariate functions, or a list of such objects.
#'
#' @return
#' Returns an object of type \code{covariateData}, containing information on the baseline covariates.
#' Information about multiple outcomes can be captured at once for efficiency reasons. This object is
#' a list with the following components: \describe{ \item{covariates}{An ffdf object listing the
#' baseline covariates per person in the cohorts. This is done using a sparse representation:
#' covariates with a value of 0 are omitted to save space. The covariates object will have three
#' columns: rowId, covariateId, and covariateValue. The rowId is usually equal to the person_id,
#' unless specified otherwise in the rowIdField argument.} \item{covariateRef}{An ffdf object
#' describing the covariates that have been extracted.} \item{metaData}{A list of objects with
#' information on how the covariateData object was constructed.} }
#'
#' @export
getDbCovariateData <- function(connectionDetails = NULL,
                               connection = NULL,
                               oracleTempSchema = NULL,
                               cdmDatabaseSchema,
                               cdmVersion = "4",
                               cohortTable = "cohort",
                               cohortDatabaseSchema = cdmDatabaseSchema,
                               cohortTableIsTemp = FALSE,
                               cohortIds = c(),
                               rowIdField = "subject_id",
                               covariateSettings,
                               aggregated = FALSE,
                               temporal = FALSE) {
  if (is.null(connectionDetails) && is.null(connection)) {
    stop("Need to provide either connectionDetails or connection")
  }
  if (!is.null(connectionDetails) && !is.null(connection)) {
    stop("Need to provide either connectionDetails or connection, not both")
  }
  if (!is(covariateSettings, "covariateSettings")) {
    stop("Covariate settings object not of type covariateSettings") 
  }
  if (!is.null(connectionDetails)) {
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  
  # Make sure temp cohort table exists --------------------------------------
  if (cohortTableIsTemp && length(cohortIds) == 0) {
    cohortTempTable <- cohortTable
  } else {
    cohortTempTable <- "#cohort_for_cov_temp"
    if (cohortTableIsTemp) {
      cohortDatabaseSchemaTable <- cohortTable
    } else {
      cohortDatabaseSchemaTable <- paste(cohortDatabaseSchema, cohortTable, sep = ".")
    }
    sql <- SqlRender::loadRenderTranslateSql("CreateTempCohortTable.sql",
                                             packageName = "FeatureExtraction",
                                             dbms = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema,
                                             cohort_database_schema_table = cohortDatabaseSchemaTable,
                                             cohort_ids = cohortIds,
                                             cdm_version = cdmVersion)
    DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  }
  
  # Upload excluded concept IDs if needed -----------------------------------
  excludedCovariateConceptIds <- covariateSettings$inclusionExclusion$excludedCovariateConceptIds
  addDescendantsToExclude <- covariateSettings$inclusionExclusion$addDescendantsToExclude
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
  includedCovariateConceptIds <- covariateSettings$inclusionExclusion$includedCovariateConceptIds
  addDescendantsToInclude <- covariateSettings$inclusionExclusion$addDescendantsToInclude
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
  includedCovariateIds <- covariateSettings$inclusionExclusion$includedCovariatIds
  if (is.null(includedCovariateIds) || length(includedCovariateIds) ==
      0) {
    hasIncludedCovariateIds <- FALSE
  } else {
    if (!is.numeric(includedCovariateIds))
      stop("includedCovariateIds must be a (vector of) numeric")
    hasIncludedCovariateIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#included_cov_by_id",
                                   data = data.frame(concept_id = as.integer(includedCovariateIds)),
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
  featureSets <- covariateSettings$featureSet
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
  fieldString <- "covariate_id, covariate_value"
  if (temporal) {
    fieldString <- paste0(fieldString, ", time_id")
  }
  if (!aggregated) {
    fieldString <- paste0(fieldString, ", row_id")
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
  sql <- "SELECT COUNT_BIG(*) FROM @cohort_temp_table"
  sql <- SqlRender::renderSql(sql, cohort_temp_table = cohortTempTable)$sql
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  populationSize <- DatabaseConnector::querySql(connection, sql)[1, 1]
  
  delta <- Sys.time() - start
  writeLines(paste("Downloading data took", signif(delta, 3), attr(delta, "units")))
  
  # Drop temp tables ----------------------------------
  tempTables <- c(covTableNames, "#cov_all", "#cov_ref")
  if (temporal) {
    tempTables <- c(tempTables, "#time_periods")
  }
  if (!cohortTableIsTemp || length(cohortIds) != 0) {
    tempTables <- c(tempTables, "#cohort_for_cov_temp")
  }
  sql <- paste0("TRUNCATE TABLE ", tempTables, "; DROP TABLE ", tempTables, ";")
  sql <- paste(sql, collapse = "\n")
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  
  if (!is.null(connectionDetails)) {
    DatabaseConnector::disconnect(connection)
  }
  
  metaData <- list(call = match.call(),
                   cohortIds = cohortIds,
                   populationSize = populationSize)
  covariateData <- list(covariates = covariates, covariateRef = covariateRef, metaData = metaData)
  if (nrow(covariateData$covariates) == 0) {
    warning("No data found")
  } else {
    open(covariateData$covariates)
  }
  class(covariateData) <- "covariateData"
  return(covariateData)
}

#' Save the covariate data to folder
#'
#' @description
#' \code{saveCovariateData} saves an object of type covariateData to folder.
#'
#' @param covariateData   An object of type \code{covariateData} as generated using
#'                        \code{getDbCovariateData}.
#' @param file            The name of the folder where the data will be written. The folder should not
#'                        yet exist.
#'
#' @details
#' The data will be written to a set of files in the folder specified by the user.
#'
#' @examples
#' # todo
#'
#' @export
saveCovariateData <- function(covariateData, file) {
  if (missing(covariateData))
    stop("Must specify covariateData")
  if (missing(file))
    stop("Must specify file")
  if (class(covariateData) != "covariateData")
    stop("Data not of class covariateData")
  
  covariates <- covariateData$covariates
  covariateRef <- covariateData$covariateRef
  ffbase::save.ffdf(covariates, covariateRef, dir = file)
  open(covariateData$covariates)
  open(covariateData$covariateRef)
  metaData <- covariateData$metaData
  save(metaData, file = file.path(file, "metaData.Rdata"))
}

#' Load the covariate data from a folder
#'
#' @description
#' \code{loadCovariateData} loads an object of type covariateData from a folder in the file system.
#'
#' @param file       The name of the folder containing the data.
#' @param readOnly   If true, the data is opened read only.
#'
#' @details
#' The data will be written to a set of files in the folder specified by the user.
#'
#' @return
#' An object of class covariateData
#'
#' @examples
#' # todo
#'
#' @export
loadCovariateData <- function(file, readOnly = FALSE) {
  if (!file.exists(file))
    stop(paste("Cannot find folder", file))
  if (!file.info(file)$isdir)
    stop(paste("Not a folder", file))
  
  temp <- setwd(file)
  absolutePath <- setwd(temp)
  
  e <- new.env()
  ffbase::load.ffdf(absolutePath, e)
  load(file.path(absolutePath, "metaData.Rdata"), e)
  result <- list(covariates = get("covariates", envir = e),
                 covariateRef = get("covariateRef", envir = e),
                 metaData = get("metaData", envir = e))
  # Open all ffdfs to prevent annoying messages later:
  open(result$covariates, readonly = readOnly)
  open(result$covariateRef, readonly = readOnly)
  
  class(result) <- "covariateData"
  rm(e)
  return(result)
}


#' @export
print.covariateData <- function(x, ...) {
  writeLines("CovariateData object")
  writeLines("")
  writeLines(paste("Cohort of interest concept ID(s):",
                   paste(x$metaData$cohortIds, collapse = ",")))
}

#' @export
summary.covariateData <- function(object, ...) {
  result <- list(metaData = object$metaData,
                 covariateCount = nrow(object$covariateRef),
                 covariateValueCount = nrow(object$covariates))
  class(result) <- "summary.covariateData"
  return(result)
}

#' @export
print.summary.covariateData <- function(x, ...) {
  writeLines("CovariateData object summary")
  writeLines("")
  writeLines(paste("Number of covariates:", x$covariateCount))
  writeLines(paste("Number of non-zero covariate values:", x$covariateValueCount))
}

