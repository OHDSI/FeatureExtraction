# Copyright 2018 Observational Health Data Sciences and Informatics
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
#' @param cdmVersion             Define the OMOP CDM version used: currently supported is "5".
#' @param cohortTable            Name of the (temp) table holding the cohort for which we want to
#'                               construct covariates
#' @param cohortDatabaseSchema   If the cohort table is not a temp table, specify the database schema
#'                               where the cohort table can be found. On SQL Server, this should
#'                               specifiy both the database and the schema, so for example
#'                               'cdm_instance.dbo'.
#' @param cohortTableIsTemp      Is the cohort table a temp table?
#' @param cohortId               For which cohort ID should covariates be constructed? If set to -1,
#'                               covariates will be constructed for all cohorts in the specified cohort
#'                               table.
#' @param rowIdField             The name of the field in the cohort table that is to be used as the
#'                               row_id field in the output table. This can be especially usefull if
#'                               there is more than one period per person.
#' @param covariateSettings      Either an object of type \code{covariateSettings} as created using one
#'                               of the createCovariate functions, or a list of such objects.
#' @param aggregated             Should aggregate statistics be computed instead of covariates per
#'                               cohort entry?
#'
#' @return
#' Returns an object of type \code{covariateData}, containing information on the covariates.
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
                               rowIdField = "subject_id",
                               covariateSettings,
                               aggregated = FALSE) {
  if (is.null(connectionDetails) && is.null(connection)) {
    stop("Need to provide either connectionDetails or connection")
  }
  if (!is.null(connectionDetails) && !is.null(connection)) {
    stop("Need to provide either connectionDetails or connection, not both")
  }
  if (cdmVersion == "4") {
    stop("CDM version 4 is not supported any more")
  }
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
  sql <- "SELECT COUNT_BIG(*) FROM @cohort_database_schema_table {@cohort_id != -1} ? {WHERE cohort_definition_id = @cohort_id} "
  sql <- SqlRender::renderSql(sql = sql,
                              cohort_database_schema_table = cohortDatabaseSchemaTable,
                              cohort_id = cohortId)$sql
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  populationSize <- DatabaseConnector::querySql(connection, sql)[1, 1]
  if (populationSize == 0) {
    covariateData <- list(covariates = data.frame(), covariateRef = data.frame(), metaData = list())
    class(covariateData) <- "covariateData"
    warning("Population is empty. No covariates were constructed")
  } else {
    if (class(covariateSettings) == "covariateSettings") {
      covariateSettings <- list(covariateSettings)
    }
    if (is.list(covariateSettings)) {
      covariateData <- NULL
      hasData <- function(data) {
        return(!is.null(data) && nrow(data) != 0) 
      }
      for (i in 1:length(covariateSettings)) {
        fun <- attr(covariateSettings[[i]], "fun")
        args <- list(connection = connection,
                     oracleTempSchema = oracleTempSchema,
                     cdmDatabaseSchema = cdmDatabaseSchema,
                     cohortTable = cohortDatabaseSchemaTable,
                     cohortId = cohortId,
                     cdmVersion = cdmVersion,
                     rowIdField = rowIdField,
                     covariateSettings = covariateSettings[[i]],
                     aggregated = aggregated)
        tempCovariateData <- do.call(eval(parse(text = fun)), args)
        if (is.null(covariateData)) {
          covariateData <- tempCovariateData
        } else {
          if (hasData(covariateData$covariates)) {
            if (hasData(tempCovariateData$covariates)) {
              covariateData$covariates <- ffbase::ffdfappend(covariateData$covariates,
                                                             tempCovariateData$covariates)
            } 
          } else if (hasData(tempCovariateData$covariates)) {
            covariateData$covariates <- tempCovariateData$covariates
          }
          if (hasData(covariateData$covariatesContinuous)) {
            if (hasData(tempCovariateData$covariatesContinuous)) {
              covariateData$covariatesContinuous <- ffbase::ffdfappend(covariateData$covariatesContinuous,
                                                                       tempCovariateData$covariatesContinuous)
            } else if (hasData(tempCovariateData$covariatesContinuous)) {
              covariateData$covariatesContinuous <- tempCovariateData$covariatesContinuous
            }
          } 
          covariateData$covariateRef <- ffbase::ffdfappend(covariateData$covariateRef,
                                                           ff::as.ram(tempCovariateData$covariateRef))
          covariateData$analysisRef <- ffbase::ffdfappend(covariateData$analysisRef,
                                                          ff::as.ram(tempCovariateData$analysisRef))
          for (name in names(tempCovariateData$metaData)) {
            if (is.null(covariateData$metaData[name])) {
              covariateData$metaData[[name]] <- tempCovariateData$metaData[[name]]
            } else {
              covariateData$metaData[[name]] <- list(covariateData$metaData[[name]],
                                                     tempCovariateData$metaData[[name]])
            }
          }
        }
      }
    }
  }
  covariateData$metaData$populationSize <- populationSize
  covariateData$metaData$cohortId <- cohortId
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
  
  covariateRef <- covariateData$covariateRef
  analysisRef <- covariateData$analysisRef
  if (!is.null(covariateData$covariates) && !is.null(covariateData$covariatesContinuous)) {
    covariates <- covariateData$covariates
    covariatesContinuous <- covariateData$covariatesContinuous
    ffbase::save.ffdf(analysisRef, covariateRef, covariates, covariatesContinuous, dir = file)
    open(covariateData$covariates)
    open(covariateData$covariatesContinuous)
  } else if (!is.null(covariateData$covariates) && is.null(covariateData$covariatesContinuous)) {
    covariates <- covariateData$covariates
    ffbase::save.ffdf(analysisRef, covariateRef, covariates, dir = file)
    open(covariateData$covariates)
  } else if (is.null(covariateData$covariates) && !is.null(covariateData$covariatesContinuous)) {
    covariatesContinuous <- covariateData$covariatesContinuous
    ffbase::save.ffdf(analysisRef, covariateRef, covariatesContinuous, dir = file)
    open(covariateData$covariatesContinuous)
  }
  open(covariateData$covariateRef)
  open(covariateData$analysisRef)
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
#' An object of class \code{covariateData}.
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
  result <- list(analysisRef = get("analysisRef", envir = e),
                 covariateRef = get("covariateRef", envir = e),
                 metaData = get("metaData", envir = e))
  open(result$analysisRef, readonly = readOnly)
  open(result$covariateRef, readonly = readOnly)
  # 'exists' for some reason generates false positives, so checking object names instead:
  eNames <- ls(envir = e)
  if (any(eNames == "covariates")) {
    result$covariates <- get("covariates", envir = e)
    open(result$covariates, readonly = readOnly)
  }
  if (any(eNames == "covariatesContinuous")) {
    result$covariatesContinuous <- get("covariatesContinuous", envir = e)
    open(result$covariatesContinuous, readonly = readOnly)
  }
  class(result) <- "covariateData"
  rm(e)
  return(result)
}

#' @export
print.covariateData <- function(x, ...) {
  writeLines("CovariateData object")
  writeLines("")
  writeLines(paste("Cohort of interest ID:", x$metaData$cohortId))
}

#' @export
summary.covariateData <- function(object, ...) {
  covariateValueCount <- 0
  if (!is.null(object$covariates)) {
    covariateValueCount <- covariateValueCount + nrow(object$covariates)
  }
  if (!is.null(object$covariatesContinuous)) {
    covariateValueCount <- covariateValueCount + nrow(object$covariatesContinuous)
  }
  
  result <- list(metaData = object$metaData,
                 covariateCount = nrow(object$covariateRef),
                 covariateValueCount = covariateValueCount)
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

