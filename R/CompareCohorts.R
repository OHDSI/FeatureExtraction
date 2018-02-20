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

#' Compute standardized difference of mean for all covariates.
#'
#' @description
#' Computes the standardized difference for all covariates between two cohorts. The standardized
#' difference is defined as the difference between the mean divided by the overall standard deviation.
#'
#' @param covariateData1   The covariate data of the first cohort. Needs to be in aggregated format.
#' @param covariateData2   The covariate data of the second cohort. Needs to be in aggregated format.
#'
#' @return
#' A data frame with means and standard deviations per cohort as well as the standardized difference
#' of mean.
#'
#' @export
computeStandardizedDifference <- function(covariateData1, covariateData2) {
  if (!is(covariateData1, "covariateData")) {
    stop("covariateData1 is not of type 'covariateData'")
  }
  if (!is(covariateData2, "covariateData")) {
    stop("covariateData2 is not of type 'covariateData'")
  }
  if (is.null(covariateData1$covariatesContinuous) && is.null(covariateData1$covariates$averageValue)) {
    stop("Covariate1 data is not aggregated")
  }
  if (is.null(covariateData2$covariatesContinuous) && is.null(covariateData2$covariates$averageValue)) {
    stop("Covariate2 data is not aggregated")
  }
  result <- data.frame()
  if (!is.null(covariateData1$covariates) && !is.null(covariateData1$covariates)) {
    covariates1 <- covariateData1$covariates[, c("covariateId", "sumValue")]
    names(covariates1)[2] <- "count1"
    covariates2 <- covariateData2$covariates[, c("covariateId", "sumValue")]
    names(covariates2)[2] <- "count2"
    n1 <- covariateData1$metaData$populationSize
    n2 <- covariateData2$metaData$populationSize
    m <- merge(covariates1, covariates2, all = T)
    m$count1[is.na(m$count1)] <- 0
    m$count2[is.na(m$count2)] <- 0
    m$mean1 <- m$count1/n1
    m$mean2 <- m$count2/n2
    m$sd1 <- sqrt((n1 * m$count1 + m$count1)/(n1^2))
    m$sd2 <- sqrt((n2 * m$count2 + m$count2)/(n2^2))
    m$sd <- sqrt(m$sd1^2 + m$sd2^2)
    m$stdDiff <- (m$mean2 - m$mean1)/m$sd
    result <- rbind(result, m[, c("covariateId", "mean1", "sd1", "mean2", "sd2", "sd", "stdDiff")])
  }
  if (!is.null(covariateData1$covariatesContinuous) && !is.null(covariateData1$covariatesContinuous)) {
    covariates1 <- covariateData1$covariatesContinuous[, c("covariateId",
                                                           "averageValue",
                                                           "standardDeviation")]
    names(covariates1)[2] <- "mean1"
    names(covariates1)[3] <- "sd1"
    covariates2 <- covariateData2$covariatesContinuous[, c("covariateId",
                                                           "averageValue",
                                                           "standardDeviation")]
    names(covariates2)[2] <- "mean2"
    names(covariates2)[3] <- "sd2"
    m <- merge(covariates1, covariates2, all = T)
    m$mean1[is.na(m$mean1)] <- 0
    m$sd1[is.na(m$sd1)] <- 0
    m$mean2[is.na(m$mean2)] <- 0
    m$sd2[is.na(m$sd2)] <- 0
    m$sd <- sqrt(m$sd1^2 + m$sd2^2)
    m$stdDiff <- (m$mean2 - m$mean1)/m$sd
    result <- rbind(result, m[, c("covariateId", "mean1", "sd1", "mean2", "sd2", "sd", "stdDiff")])
  }
  idx <- match(result$covariateId, ff::as.ram(covariateData1$covariateRef$covariateId))
  result$covariateName[!is.na(idx)] <- as.character(covariateData1$covariateRef$covariateName[idx[!is.na(idx)]])
  if (any(is.na(idx))) {
    idx <- is.na(idx)
    idx2 <- match(result$covariateId[idx], ff::as.ram(covariateData2$covariateRef$covariateId))
    result$covariateName[idx] <- as.character(covariateData2$covariateRef$covariateName[idx2])
  }
  result <- result[order(-abs(result$stdDiff)), ]
  return(result)
}
