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

#' Filter covariates by row ID
#'
#' @param covariateData  An object of type \code{CovariateData}
#' @param rowIds         A vector containing the rowIds to keep.
#'
#' @return
#' An object of type \code{covariateData}.
#'
#' @examples
#' \donttest{
#' covariateData <- FeatureExtraction::createEmptyCovariateData(
#'   cohortIds = 1,
#'   aggregated = FALSE,
#'   temporal = FALSE
#' )
#'
#' covData <- filterByRowId(
#'   covariateData = covariateData,
#'   rowIds = 1
#' )
#' }
#'
#' @export
filterByRowId <- function(covariateData, rowIds) {
  if (!isCovariateData(covariateData)) {
    stop("Data not of class CovariateData")
  }
  if (!Andromeda::isValidAndromeda(covariateData)) {
    stop("CovariateData object is closed")
  }
  if (isAggregatedCovariateData(covariateData)) {
    stop("Cannot filter aggregated data by rowId")
  }
  covariates <- covariateData$covariates %>%
    filter(.data$rowId %in% rowIds)

  result <- Andromeda::andromeda(
    covariates = covariates,
    covariateRef = covariateData$covariateRef,
    analysisRef = covariateData$analysisRef
  )
  metaData <- attr(covariateData, "metaData")
  metaData$populationSize <- length(rowIds)
  attr(result, "metaData") <- metaData
  class(result) <- "CovariateData"
  return(result)
}

#' Filter covariates by cohort definition IDs
#'
#' @param covariateData  An object of type \code{CovariateData}
#' @param cohortId       DEPRECATED The cohort definition IDs to keep.
#' @param cohortIds      The cohort definition IDs to keep.
#'
#' @return
#' An object of type \code{covariateData}.
#'
#' @examples
#' \donttest{
#' covariateData <- FeatureExtraction::createEmptyCovariateData(
#'   cohortIds = c(1, 2),
#'   aggregated = TRUE,
#'   temporal = FALSE
#' )
#'
#' covData <- filterByCohortDefinitionId(
#'   covariateData = covariateData,
#'   cohortIds = c(1)
#' )
#' }
#'
#' @export
filterByCohortDefinitionId <- function(covariateData,
                                       cohortId = 1,
                                       cohortIds = c(1)) {
  if (!isCovariateData(covariateData)) {
    stop("Data not of class CovariateData")
  }
  if (!Andromeda::isValidAndromeda(covariateData)) {
    stop("CovariateData object is closed")
  }
  if (!isAggregatedCovariateData(covariateData)) {
    stop("Can only filter aggregated data by cohortIds")
  }
  if (!missing(cohortId)) {
    warning("cohortId argument has been deprecated, please use cohortIds")
    cohortIds <- cohortId
  }

  if (is.null(covariateData$covariates)) {
    covariates <- NULL
  } else {
    covariates <- covariateData$covariates %>%
      filter(.data$cohortDefinitionId %in% cohortIds)
  }
  if (is.null(covariateData$covariatesContinuous)) {
    covariatesContinuous <- NULL
  } else {
    covariatesContinuous <- covariateData$covariatesContinuous %>%
      filter(.data$cohortDefinitionId %in% cohortIds)
  }
  result <- Andromeda::andromeda(
    covariates = covariates,
    covariatesContinuous = covariatesContinuous,
    covariateRef = covariateData$covariateRef,
    analysisRef = covariateData$analysisRef
  )
  metaData <- attr(covariateData, "metaData")
  metaData$populationSize <- metaData$populationSize[as.numeric(names(metaData$populationSize)) %in% cohortIds]
  attr(result, "metaData") <- metaData
  class(result) <- "CovariateData"
  attr(class(result), "package") <- "FeatureExtraction"
  return(result)
}

.assertCovariateId <- function(covariateId, len = NULL, min.len = NULL, null.ok = FALSE, add = NULL) {
  checkmate::assertNumeric(covariateId, null.ok = null.ok, len = len, min.len = 1, add = add)
  if (!is.null(covariateId)) {
    message <- sprintf(
      "Variable '%s' is a (64-bit) integer",
      paste0(deparse(eval.parent(substitute(substitute(covariateId))), width.cutoff = 500L), collapse = "\n")
    )
    checkmate::assertTRUE(all(covariateId == round(covariateId)), .var.name = message, add = add)
  }
}
