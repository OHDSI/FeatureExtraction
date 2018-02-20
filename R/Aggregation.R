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


#' Aggregate covariate data
#'
#' @param covariateData   An object of type \code{covariateData} as generated using
#'                        \code{getDbCovariateData}.
#'
#' @return
#' An object of class \code{covariateData}.
#'
#' @export
aggregateCovariates <- function(covariateData) {
  if (class(covariateData) != "covariateData")
    stop("Data not of class covariateData")
  if (!is.null(covariateData$covariatesContinuous) || is.null(covariateData$covariates$rowId))
    stop("Data appears to already be aggregated")
  if (!is.null(covariateData$covariates$timeId))
    stop("Aggregation for temporal covariates is not yet implemented")
  start <- Sys.time()
  result <- list(covariateRef = ff::clone.ffdf(covariateData$covariateRef),
                 analysisRef = ff::clone.ffdf(covariateData$analysisRef),
                 metaData = covariateData$metaData)
  populationSize <- covariateData$metaData$populationSize
  # Aggregate binary variables
  idx <- covariateData$analysisRef$isBinary == "Y"
  if (ffbase::any.ff(idx)) {
    analysisIds <- covariateData$analysisRef$analysisId[idx]
    idx <- ffbase::`%in%`(covariateData$covariateRef$analysisId, analysisIds)
    if (ffbase::any.ff(idx)) {
      covariateIds <- covariateData$covariateRef$covariateId[idx]
      idx <- ffbase::`%in%`(covariateData$covariates$covariateId, covariateIds)
      if (ffbase::any.ff(idx)) {
        binaryCovariates <- covariateData$covariates[idx, ]
        covariates <- bySumFf(binaryCovariates$covariateValue, binaryCovariates$covariateId)
        colnames(covariates) <- c("covariateId", "sumValue")
        covariates$averageValue <- covariates$sumValue/populationSize
        result$covariates <- ff::as.ffdf(covariates)
      }
    }
  }

  # Aggregate continuous variables where missing means zero
  idx <- covariateData$analysisRef$isBinary == "N" & covariateData$analysisRef$missingMeansZero == "Y"
  if (ffbase::any.ff(idx)) {
    analysisIds <- covariateData$analysisRef$analysisId[idx]
    idx <- ffbase::`%in%`(covariateData$covariateRef$analysisId, analysisIds)
    if (ffbase::any.ff(idx)) {
      covariateIds <- covariateData$covariateRef$covariateId[idx]

      computeStats <- function(covariateId) {
        idx <- covariateData$covariates$covariateId == covariateId
        if (ffbase::any.ff(idx)) {
          values <- ff::as.ram(covariateData$covariates$covariateValue[idx])
          zeroFraction <- 1 - (length(values)/populationSize)
          allProbs <- c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1)
          probs <- allProbs[allProbs > zeroFraction]
          probs <- (probs - zeroFraction)/(1 - zeroFraction)
          quants <- quantile(values, probs = probs, type = 1)
          quants <- c(rep(0, length(allProbs) - length(quants)), quants)
          result <- data.frame(covariateId = covariateId,
                               countValue = length(values),
                               minValue = quants[1],
                               maxValue = quants[7],
                               averageValue = mean(values) * (1 - zeroFraction),
                               standardDeviation = sqrt((populationSize *
            sum(values^2) - sum(values)^2)/(populationSize * (populationSize - 1))), medianValue = quants[4], p10Value = quants[2], p25Value = quants[3], p75Value = quants[5], p90Value = quants[6])
          return(result)
        } else {
          return(NULL)
        }
      }
      stats <- lapply(ff::as.ram(covariateIds), computeStats)
      if (!is.null(result$covariatesContinuous)) {
        stats <- append(result$covariatesContinuous, stats)
      }
      result$covariatesContinuous <- do.call("rbind", stats)
    }
  }

  # Aggregate continuous variables where missing means missing
  idx <- covariateData$analysisRef$isBinary == "N" & covariateData$analysisRef$missingMeansZero == "N"
  if (ffbase::any.ff(idx)) {
    analysisIds <- covariateData$analysisRef$analysisId[idx]
    idx <- ffbase::`%in%`(covariateData$covariateRef$analysisId, analysisIds)
    if (ffbase::any.ff(idx)) {
      covariateIds <- covariateData$covariateRef$covariateId[idx]

      computeStats <- function(covariateId) {
        idx <- covariateData$covariates$covariateId == covariateId
        if (ffbase::any.ff(idx)) {
          values <- ff::as.ram(covariateData$covariates$covariateValue[idx])
          probs <- c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1)
          quants <- quantile(values, probs = probs, type = 1)
          result <- data.frame(covariateId = covariateId,
                               countValue = length(values),
                               minValue = quants[1],
                               maxValue = quants[7],
                               averageValue = mean(values),
                               standardDeviation = sd(values),
                               medianValue = quants[4],
                               p10Value = quants[2],
                               p25Value = quants[3],
                               p75Value = quants[5],
                               p90Value = quants[6])
          return(result)
        } else {
          return(NULL)
        }
      }
      stats <- lapply(ff::as.ram(covariateIds), computeStats)
      if (!is.null(result$covariatesContinuous)) {
        stats <- append(result$covariatesContinuous, stats)
      }
      result$covariatesContinuous <- do.call("rbind", stats)
    }
  }
  if (!is.null(result$covariatesContinuous) && nrow(result$covariatesContinuous) != 0) {
    result$covariatesContinuous <- ff::as.ffdf(result$covariatesContinuous)
  }
  delta <- Sys.time() - start
  writeLines(paste("Aggregating covariates took", signif(delta, 3), attr(delta, "units")))
  class(result) <- "covariateData"
  return(result)
}
