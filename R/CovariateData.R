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

#' CovariateData class.
#'
#' @keywords internal
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
  return(covariateData)
}

# show()
#' @export
#' @rdname CovariateData-class
setMethod("show", "CovariateData", function(object) {
  writeLines("CovariateData object")
  writeLines("")
  writeLines(paste("Cohort of interest ID:", attr(object, "metaData")$cohortId))
})


# summary()
#' @export
#' @rdname CovariateData-class
setMethod("summary", "CovariateData", function(object) {
  covariateValueCount <- 0
  if (!is.null(object$covariates)) {
    covariateValueCount <- covariateValueCount + (object$covariates %>% count() %>% collect())$n
  }
  if (!is.null(object$covariatesContinuous)) {
    covariateValueCount <- covariateValueCount + (object$covariateValueCount %>% count() %>% collect())$n
  }
  result <- list(metaData = attr(object, "metaData"),
                 covariateCount = (object$covariateRef %>% count() %>% collect())$n,
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
