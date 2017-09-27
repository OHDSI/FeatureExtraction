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
#' Normalize covariate values by dividing by the max and/or remove redundant covariates.
#'
#' @param covariateData     An object as generated using the \code{\link{getDbCovariateData}}
#'                          function.
#' @param normalize         Normalize the coviariates? (dividing by the max)
#' @param removeRedundancy  Should redundant covariates be removed?
#'
#' @export
tidyCovariateData <- function(covariateData, 
                              normalize = TRUE,
                              removeRedundancy = TRUE) {
  
  covariates <- covariateData$covariates
  if (nrow(covariates) != 0) {
    maxs <- byMaxFf(covariates$covariateValue, covariates$covariateId)
    
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
      valueCounts <- merge(valueCounts, covariateData$covariateRef[, c("covariateId", "analysisId")], by.x = "bins", by.y = "covariateId")
      countsPerAnalysis <- aggregate(sums ~ analysisId, data = valueCounts, sum)
      analysisIds <- countsPerAnalysis$analysisId[countsPerAnalysis$sums == covariateData$metaData$populationSize]
      # TODO: maybe check if sum was not accidentally achieved by duplicates (unlikely)
      # Find most prevalent covariateId per analysisId:
      valueCounts <- valueCounts[valueCounts$analysisId %in% analysisIds, ]
      valueCounts <- valueCounts[order(valueCounts$analysisId, -valueCounts$sums), ]
      deleteCovariateIds <- c(deleteCovariateIds, valueCounts$bins[!duplicated(valueCounts$analysisId)])
      
      if (length(deleteCovariateIds) != 0) {
        covariates <- covariates[!ffbase::`%in%`(covariates$covariateId, deleteCovariateIds), ]
      }
      covariateData$metaData$deletedCovariateIds <- deleteCovariateIds
      delta <- Sys.time() - start
      writeLines(paste("Removing redundant covariates took", signif(delta, 3), attr(delta, "units")))
    }
  }
  covariateData$covariates <- covariates
  covariateData$covariateRef <- ff::clone.ffdf(covariateData$covariateRef)
  return(covariateData)
}


