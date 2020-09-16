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
  if (!isCovariateData(covariateData))
    stop("Data not of class CovariateData")
  if (!Andromeda::isValidAndromeda(covariateData)) 
    stop("CovariateData object is closed")
  if (isAggregatedCovariateData(covariateData))
    stop("Data appears to already be aggregated")
  if (isTemporalCovariateData(covariateData))
    stop("Aggregation for temporal covariates is not yet implemented")
  start <- Sys.time()
  result <- Andromeda::andromeda(covariateRef = covariateData$covariateRef,
                                 analysisRef = covariateData$analysisRef)
  attr(result, "metaData") <- attr(covariateData, "metaData")
  class(result) <- "CovariateData"
  attr(class(result), "package") <- "FeatureExtraction"
  populationSize <-  attr(covariateData, "metaData")$populationSize
  
  # Aggregate binary variables
  result$covariates <- covariateData$analysisRef %>%
    filter(rlang::sym("isBinary") == "Y") %>%
    inner_join(covariateData$covariateRef, by = "analysisId") %>%
    inner_join(covariateData$covariates, by = "covariateId") %>%
    group_by(rlang::sym("covariateId")) %>%
    summarize(sumValue = sum(rlang::sym("covariateValue"), na.rm = TRUE),
              averageValue = sum(rlang::sym("covariateValue") / populationSize, na.rm = TRUE))
  
  # Aggregate continuous variables where missing means zero
  computeStats <- function(data) {
    zeroFraction <- 1 - (nrow(data)/populationSize)
    allProbs <- c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1)
    probs <- allProbs[allProbs >= zeroFraction]
    probs <- (probs - zeroFraction)/(1 - zeroFraction)
    quants <- quantile(data$covariateValue, probs = probs, type = 1)
    quants <- c(rep(0, length(allProbs) - length(quants)), quants)
    result <- tibble(covariateId = data$covariateId[1],
                     countValue = nrow(data),
                     minValue = quants[1],
                     maxValue = quants[7],
                     averageValue = mean(data$covariateValue) * (1 - zeroFraction),
                     standardDeviation = sqrt((populationSize * sum(data$covariateValue^2) - sum(data$covariateValue)^2)/(populationSize * (populationSize - 1))), 
                     medianValue = quants[4], 
                     p10Value = quants[2], 
                     p25Value = quants[3], 
                     p75Value = quants[5], 
                     p90Value = quants[6])
  }
  
  covariatesContinuous1 <- covariateData$analysisRef %>%
    filter(rlang::sym("isBinary") == "N" & rlang::sym("missingMeansZero") == "Y") %>%
    inner_join(covariateData$covariateRef, by = "analysisId") %>%
    inner_join(covariateData$covariates, by = "covariateId") %>%
    Andromeda::groupApply("covariateId",  computeStats) %>%
    bind_rows()
  
  # Aggregate continuous variables where missing means missing
  computeStats <- function(data) {
    probs <- c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1)
    quants <- quantile(data$covariateValue, probs = probs, type = 1)
    result <- tibble(covariateId = data$covariateId[1],
                     countValue = length(data$covariateValue),
                     minValue = quants[1],
                     maxValue = quants[7],
                     averageValue = mean(data$covariateValue),
                     standardDeviation = sd(data$covariateValue),
                     medianValue = quants[4],
                     p10Value = quants[2],
                     p25Value = quants[3],
                     p75Value = quants[5],
                     p90Value = quants[6])
  }
  
  covariatesContinuous2 <- covariateData$analysisRef %>%
    filter(rlang::sym("isBinary") == "N" & rlang::sym("missingMeansZero") == "N") %>%
    inner_join(covariateData$covariateRef, by = "analysisId") %>%
    inner_join(covariateData$covariates, by = "covariateId") %>%
    Andromeda::groupApply("covariateId",  computeStats) %>%
    bind_rows()
  
  covariatesContinuous <- bind_rows(covariatesContinuous1, covariatesContinuous2)
  if (nrow(covariatesContinuous) > 0) {
    result$covariatesContinuous <- covariatesContinuous
  }
  delta <- Sys.time() - start
  writeLines(paste("Aggregating covariates took", signif(delta, 3), attr(delta, "units")))
  return(result)
}
