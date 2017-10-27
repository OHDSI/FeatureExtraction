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

#' Compute max of values binned by a second variable
#'
#' @param values   An ff object containing the numeric values to take the max of.
#' @param bins     An ff object containing the numeric values to bin by.
#'
#' @examples
#' values <- ff::as.ff(c(1, 1, 2, 2, 1))
#' bins <- ff::as.ff(c(1, 1, 1, 2, 2))
#' byMaxFf(values, bins)
#'
#' @export
byMaxFf <- function(values, bins) {
  byMax(values, bins)
}

#' Compute sum of values binned by a second variable
#'
#' @param values   An ff object containing the numeric values to take the sum of.
#' @param bins     An ff object containing the numeric values to bin by.
#'
#' @examples
#' values <- ff::as.ff(c(1, 1, 2, 2, 1))
#' bins <- ff::as.ff(c(1, 1, 1, 2, 2))
#' bySumFf(values, bins)
#'
#' @export
bySumFf <- function(values, bins) {
  bySum(values, bins)
}

#' Tidy covariate data
#'
#' @details
#' Normalize covariate values by dividing by the max and/or remove redundant covariates and/or remove
#' infrequent covariates.
#'
#' @param covariateData      An object as generated using the \code{\link{getDbCovariateData}}
#'                           function. If provided, the \code{covariates}, \code{covariateRef}, and
#'                           \code{populationSize} arguments will be ignored.
#' @param covariates         An ffdf object with the covariate values in spare format. Will be ignored
#'                           if \code{covariateData} is provided.
#' @param covariateRef       An ffdf object with the covariate definitions. Will be ignored if
#'                           \code{covariateData} is provided. Only needed when \code{removeRedundancy
#'                           = TRUE}.
#' @param populationSize     An integer specifying the total number of unique cohort entries (rowIds).
#'                           Will be ignored if \code{covariateData} is provided. Only needed when
#'                           \code{removeRedundancy = TRUE}.
#' @param minFraction        Minimum fraction of the population that should have a non-zero value for a
#'                           covariate for that covariate to be kept. Set to 0 to don't filter on
#'                           frequency.
#' @param normalize          Normalize the coviariates? (dividing by the max)
#' @param removeRedundancy   Should redundant covariates be removed?
#'
#' @export
tidyCovariateData <- function(covariateData,
                              covariates,
                              covariateRef,
                              populationSize,
                              minFraction = 0.001,
                              normalize = TRUE,
                              removeRedundancy = TRUE) {
  if (missing(covariateData) && missing(covariates)) {
    stop("Either covariateData or covariates needs to be provided")
  }
  if (missing(covariateData) && removeRedundancy && (missing(covariateRef) | missing(populationSize))) {
    stop("If removeRedundancy = TRUE, either covariateData or both covariateRef and populationSize need to be specified")
  }
  if (!missing(covariateData) && !is(covariateData, "covariateData")) {
    stop("Argument covariateData is not of type covariateData")
  }
  if (missing(covariateData)) {
    covariateData <- list(metaData = list(populationSize = populationSize))
  } else {
    covariates <- covariateData$covariates
    if (removeRedundancy) {
      covariateRef <- covariateData$covariateRef
    }
  }
  if (nrow(covariates) != 0) {
    maxs <- byMaxFf(covariates$covariateValue, covariates$covariateId)
    if (minFraction != 0) {
      writeLines("Removing infrequent covariates")
      start <- Sys.time()
      minCount <- floor(minFraction * covariateData$metaData$populationSize)
      valueCounts <- bySumFf(ff::ff(1, length = nrow(covariates)), covariates$covariateId)
      deleteCovariateIds <- valueCounts$bins[valueCounts$sums < minCount]
      if (length(deleteCovariateIds) != 0) {
        covariates <- covariates[!ffbase::`%in%`(covariates$covariateId, deleteCovariateIds), ]
        covariateData$metaData$deletedInfrequentCovariateIds <- deleteCovariateIds
      }
      delta <- Sys.time() - start
      writeLines(paste("Removing infrequent covariates took",
                       signif(delta, 3),
                       attr(delta, "units")))
    }
    if (normalize) {
      writeLines("Normalizing covariates")
      start <- Sys.time()
      ffdfMaxs <- ff::as.ffdf(maxs)
      names(ffdfMaxs)[names(ffdfMaxs) == "bins"] <- "covariateId"
      covariates <- ffbase::merge.ffdf(covariates, ffdfMaxs)
      for (i in bit::chunk(covariates)) {
        covariates$covariateValue[i] <- covariates$covariateValue[i]/covariates$maxs[i]
      }
      covariates$maxs <- NULL
      covariateData$metaData$normFactors <- maxs
      delta <- Sys.time() - start
      writeLines(paste("Normalizing covariates took", signif(delta, 3), attr(delta, "units")))
    }
    if (removeRedundancy) {
      writeLines("Removing redundant covariates")
      start <- Sys.time()
      deleteCovariateIds <- c()
      binaryCovariateIds <- maxs$bins[maxs$maxs == 1]

      # First, find all single covariates that appear in every row with the same value
      valueCounts <- bySumFf(ff::ff(1, length = nrow(covariates)), covariates$covariateId)
      valueCounts <- valueCounts[valueCounts$bins %in% binaryCovariateIds, ]
      deleteCovariateIds <- valueCounts$bins[valueCounts$sums == covariateData$metaData$populationSize]

      # Next, find groups of covariates that together cover everyone:
      valueCounts <- valueCounts[!(valueCounts$bins %in% deleteCovariateIds), ]
      valueCounts <- merge(valueCounts,
                           covariateRef[,
                           c("covariateId", "analysisId")],
                           by.x = "bins",
                           by.y = "covariateId")
      countsPerAnalysis <- aggregate(sums ~ analysisId, data = valueCounts, sum)
      analysisIds <- countsPerAnalysis$analysisId[countsPerAnalysis$sums == covariateData$metaData$populationSize]
      # TODO: maybe check if sum was not accidentally achieved by duplicates (unlikely) Find most prevalent
      # covariateId per analysisId:
      valueCounts <- valueCounts[valueCounts$analysisId %in% analysisIds, ]
      valueCounts <- valueCounts[order(valueCounts$analysisId, -valueCounts$sums), ]
      deleteCovariateIds <- c(deleteCovariateIds,
                              valueCounts$bins[!duplicated(valueCounts$analysisId)])

      if (length(deleteCovariateIds) != 0) {
        covariates <- covariates[!ffbase::`%in%`(covariates$covariateId, deleteCovariateIds), ]
      }
      covariateData$metaData$deletedRedundantCovariateIds <- deleteCovariateIds
      delta <- Sys.time() - start
      writeLines(paste("Removing redundant covariates took",
                       signif(delta, 3),
                       attr(delta, "units")))
    }
  }
  covariateData$covariates <- covariates
  covariateData$covariateRef <- ff::clone.ffdf(covariateData$covariateRef)
  return(covariateData)
}
