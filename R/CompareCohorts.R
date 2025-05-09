# Copyright 2025 Observational Health Data Sciences and Informatics
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
#' @param cohortId1        If provided, \code{covariateData1} will be restricted to this cohort. If not
#'                         provided, \code{covariateData1} is assumed to contain data on only 1 cohort.
#' @param cohortId2        If provided, \code{covariateData2} will be restricted to this cohort. If not
#'                         provided, \code{covariateData2} is assumed to contain data on only 1 cohort.
#'
#' @return
#' A data frame with means and standard deviations per cohort as well as the standardized difference
#' of mean.
#'
#' @examples
#' \donttest{
#' binaryCovDataFile <- system.file("testdata/binaryCovariateData.zip",
#'   package = "FeatureExtraction"
#' )
#' covariateData1 <- loadCovariateData(binaryCovDataFile)
#' covariateData2 <- loadCovariateData(binaryCovDataFile)
#' covDataDiff <- computeStandardizedDifference(
#'   covariateData1,
#'   covariateData2,
#'   cohortId1 = 1,
#'   cohortId2 = 2
#' )
#' }
#' @export
computeStandardizedDifference <- function(covariateData1, covariateData2, cohortId1 = NULL, cohortId2 = NULL) {
  if (!isCovariateData(covariateData1)) {
    stop("covariateData1 is not of type 'covariateData'")
  }
  if (!isCovariateData(covariateData1)) {
    stop("covariateData2 is not of type 'covariateData'")
  }
  if (!isAggregatedCovariateData(covariateData1)) {
    stop("Covariate1 data is not aggregated")
  }
  if (!isAggregatedCovariateData(covariateData2)) {
    stop("Covariate2 data is not aggregated")
  }
  result <- tibble()
  if (!is.null(covariateData1$covariates) && !is.null(covariateData2$covariates)) {
    covariates1 <- covariateData1$covariates
    if (!is.null(cohortId1)) {
      covariates1 <- covariates1 %>%
        filter(.data$cohortDefinitionId == cohortId1)
    }
    covariates1 <- covariates1 %>%
      select(
        covariateId = "covariateId",
        count1 = "sumValue"
      ) %>%
      collect()

    covariates2 <- covariateData2$covariates
    if (!is.null(cohortId2)) {
      covariates2 <- covariates2 %>%
        filter(.data$cohortDefinitionId == cohortId2)
    }
    covariates2 <- covariates2 %>%
      select(
        covariateId = "covariateId",
        count2 = "sumValue"
      ) %>%
      collect()

    n1 <- attr(covariateData1, "metaData")$populationSize
    if (!is.null(cohortId1)) {
      n1 <- n1[as.character(cohortId1)]
    }
    n2 <- attr(covariateData2, "metaData")$populationSize
    if (!is.null(cohortId2)) {
      n2 <- n2[as.character(cohortId2)]
    }
    m <- merge(covariates1, covariates2, all = T)
    m$count1[is.na(m$count1)] <- 0
    m$count2[is.na(m$count2)] <- 0
    m$mean1 <- m$count1 / n1
    m$mean2 <- m$count2 / n2
    m$sd1 <- sqrt(m$mean1 * (1 - m$mean1))
    m$sd2 <- sqrt(m$mean2 * (1 - m$mean2))
    m$sd <- sqrt((m$sd1^2 + m$sd2^2) / 2)
    m$stdDiff <- (m$mean2 - m$mean1) / m$sd
    result <- bind_rows(result, m[, c("covariateId", "mean1", "sd1", "mean2", "sd2", "sd", "stdDiff")])
  }
  if (!is.null(covariateData1$covariatesContinuous) && !is.null(covariateData2$covariatesContinuous)) {
    covariates1 <- covariateData1$covariatesContinuous
    if (!is.null(cohortId1)) {
      covariates1 <- covariates1 %>%
        filter(.data$cohortDefinitionId == cohortId1)
    }
    covariates1 <- covariates1 %>%
      select(
        covariateId = "covariateId",
        mean1 = "averageValue",
        sd1 = "standardDeviation"
      ) %>%
      collect()

    covariates2 <- covariateData2$covariatesContinuous
    if (!is.null(cohortId2)) {
      covariates2 <- covariates2 %>%
        filter(.data$cohortDefinitionId == cohortId2)
    }
    covariates2 <- covariates2 %>%
      select(
        covariateId = "covariateId",
        mean2 = "averageValue",
        sd2 = "standardDeviation"
      ) %>%
      collect()

    m <- merge(covariates1, covariates2, all = T)
    m$mean1[is.na(m$mean1)] <- 0
    m$sd1[is.na(m$sd1)] <- 0
    m$mean2[is.na(m$mean2)] <- 0
    m$sd2[is.na(m$sd2)] <- 0
    m$sd <- sqrt((m$sd1^2 + m$sd2^2) / 2)
    m$stdDiff <- (m$mean2 - m$mean1) / m$sd
    result <- bind_rows(result, m[, c("covariateId", "mean1", "sd1", "mean2", "sd2", "sd", "stdDiff")])
  }
  covariateRef1 <- covariateData1$covariateRef %>%
    collect()
  covariateRef2 <- covariateData2$covariateRef %>%
    collect()

  result <- result %>%
    left_join(select(covariateRef1, covariateId = "covariateId", covariateName1 = "covariateName"), by = "covariateId") %>%
    left_join(select(covariateRef2, covariateId = "covariateId", covariateName2 = "covariateName"), by = "covariateId") %>%
    mutate(covariateName = case_when(
      is.na(covariateName1) ~ covariateName2,
      TRUE ~ covariateName1
    )) %>%
    select(-"covariateName1", -"covariateName2") %>%
    arrange(desc(abs(!!rlang::sym("stdDiff"))))
  return(result)
}
