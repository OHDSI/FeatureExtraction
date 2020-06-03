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

#' Covariate Data
#'
#' @description
#' \code{CovariateData} is an S4 class that inherits from \code{\link[Andromeda]{Andromeda}}. It contains 
#' information on covariates, which can be either captured on a per-person basis, or aggregated across
#' the cohort(s).
#' 
#' By default covariates refer to a specific time period, with for example different covariate IDs for 
#' whether a diagnosis code was observed in the year before and month before index date. However, a
#' \code{CovariateData} can also be temporal, meaning that next to a covariate ID there is also a time ID,
#' which identifies the (user specified) time window the covariate was captured.
#'
#' A \code{CovariateData} object is typically created using \code{\link{getDbCovariateData}}, can only be saved using
#' \code{\link{saveCovariateData}}, and loaded using \code{\link{loadCovariateData}}.
#'
#' @seealso \code{\link{isCovariateData}}, \code{\link{isAggregatedCovariateData}}, \code{\link{isTemporalCovariateData}}
#' @name CovariateData-class
#' @aliases CovariateData
#' @export
#' @import Andromeda
setClass("CovariateData", contains = "Andromeda")


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
  if (!inherits(covariateData, "CovariateData"))
    stop("Data not of class CovariateData")
  
  Andromeda::saveAndromeda(covariateData, file)
}

#' Load the covariate data from a folder
#'
#' @description
#' \code{loadCovariateData} loads an object of type covariateData from a folder in the file system.
#'
#' @param file       The name of the folder containing the data.
#' @param readOnly   DEPRECATED: If true, the data is opened read only.
#'
#' @details
#' The data will be written to a set of files in the folder specified by the user.
#'
#' @return
#' An object of class \code{CovariateData}.
#'
#' @examples
#' # todo
#'
#' @export
loadCovariateData <- function(file, readOnly) {
  if (!file.exists(file))
    stop("Cannot find file ", file)
  if (file.info(file)$isdir)
    stop(file , " is a folder, but should be a file")
  if (!missing(readOnly)) 
    warning("readOnly argument has been deprecated")
  covariateData <- Andromeda::loadAndromeda(file)
  class(covariateData) <- "CovariateData"
  attr(class(covariateData), "package") <- "FeatureExtraction"
  return(covariateData)
}

# show()
#' @param object  An object of class `CovariateData`.
#' 
#' @export
#' @rdname CovariateData-class
setMethod("show", "CovariateData", function(object) {
  cli::cat_line(pillar::style_subtle("# CovariateData object"))
  cli::cat_line("")
  cohortId <- attr(object, "metaData")$cohortId
  if (cohortId == -1) {
    cli::cat_line("All cohorts")
  } else {
    cli::cat_line(paste("Cohort of interest ID:", cohortId))
  }
  cli::cat_line("")
  cli::cat_line(pillar::style_subtle("Inherits from Andromeda:"))
  class(object) <- "Andromeda"
  show(object)
})


# summary()
#' @param object  An object of class `CovariateData`.
#' 
#' @export
#' @rdname CovariateData-class
setMethod("summary", "CovariateData", function(object) {
  covariateValueCount <- 0
  if (!is.null(object$covariates)) {
    covariateValueCount <- covariateValueCount + (object$covariates %>% count() %>% pull())
  }
  if (!is.null(object$covariatesContinuous)) {
    covariateValueCount <- covariateValueCount + (object$covariatesContinuous %>% count() %>% pull())
  }
  result <- list(metaData = attr(object, "metaData"),
                 covariateCount = object$covariateRef %>% count() %>% pull(),
                 covariateValueCount = covariateValueCount)
  class(result) <- "summary.CovariateData"
  return(result)
})

#' @export
print.summary.CovariateData <- function(x, ...) {
  writeLines("CovariateData object summary")
  writeLines("")
  writeLines(paste("Number of covariates:", x$covariateCount))
  writeLines(paste("Number of non-zero covariate values:", x$covariateValueCount))
}

#' Check whether an object is a CovariateData object
#'
#' @param x  The object to check.
#'
#' @return
#' A logical value.
#' 
#' @export
isCovariateData <- function(x) {
  return(inherits(x, "CovariateData"))
}

#' Check whether covariate data is aggregated
#'
#' @param x  The covariate data object to check.
#'
#' @return
#' A logical value.
#' 
#' @export
isAggregatedCovariateData <- function(x) {
  if (!isCovariateData(x))
    stop("Object not of class CovariateData")
  if (!Andromeda::isValidAndromeda(x)) 
    stop("CovariateData object is closed")
  return(!is.null(x$covariatesContinuous) || !"rowId" %in% colnames(x$covariates))
}

#' Check whether covariate data is temporal
#'
#' @param x  The covariate data object to check.
#'
#' @return
#' A logical value.
#' 
#' @export
isTemporalCovariateData <- function(x) {
  if (!isCovariateData(x))
    stop("Object not of class CovariateData")
  if (!Andromeda::isValidAndromeda(x)) 
    stop("CovariateData object is closed")
  return("timeId" %in% colnames(x$covariates$timeId))
}

createEmptyCovariateData <- function(cohortId, aggregated, temporal) {
  dummy <- tibble(covariateId = 1,
                  covariateValue = 1)
  if (!aggregated) {
    dummy$rowId <- 1
  }
  if (!is.null(temporal) && temporal) {
    dummy$timeId <- 1
  }
  covariateData <- Andromeda::andromeda(covariates = dummy[!1, ],
                                        covariateRef = tibble(covariateId = 1, 
                                                              covariateName = "", 
                                                              analysisId = 1,
                                                              conceptId = 1)[!1, ],
                                        analysisRef = tibble(analysisId = 1, 
                                                             analysisName = "",
                                                             domainId = "",
                                                             startDay = 1, 
                                                             endDay = 1, 
                                                             isBinary = "", 
                                                             missingMeansZero = "")[!1, ])
  attr(covariateData, "metaData") <- list(populationSize = 0,
                                          cohortId = cohortId)
  class(covariateData) <- "CovariateData"
  return(covariateData)
}