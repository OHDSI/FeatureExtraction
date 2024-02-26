# Copyright 2023 Observational Health Data Sciences and Informatics
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
#' \dontrun{
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

computeStandardizedDifference <-
  function(covariateData1,
           covariateData2,
           cohortId1 = NULL,
           cohortId2 = NULL) {
    isTypeAndAggregated(covariateData1, "covariateData1")
    isTypeAndAggregated(covariateData2, "covariateData2")
    
    if (!setequal(colnames(covariateData1$covariates),
                  colnames(covariateData2$covariates))) {
      stop("Covariate1 and Covariate2 do not have the same structure")
    }
    
    covariateDataHasTimeId <- "timeId" %in% colnames(covariateData1$covariates)
    
    result <- dplyr::tibble()
    
    if (!is.null(covariateData1$covariates) &&
        !is.null(covariateData2$covariates)) {
      covariates1 <-
        prepareCovariates(
          covariates = covariateData1$covariates,
          cohortId = cohortId1,
          hasTimeId = covariateDataHasTimeId
        )
      covariates2 <-
        prepareCovariates(
          covariates = covariateData2$covariates,
          cohortId = cohortId2,
          hasTimeId = covariateDataHasTimeId
        )
      
      n1 <- getPopulationSize(covariateData1, cohortId1)
      n2 <- getPopulationSize(covariateData2, cohortId2)
      
      if (covariateDataHasTimeId) {
        m <-
          dplyr::bind_rows(
            covariates1 %>% dplyr::select(timeId, covariateId),
            covariates2 %>% dplyr::select(timeId, covariateId)
          ) %>%
          dplyr::distinct() %>%
          dplyr::left_join(covariates1 %>%
                             dplyr::rename(count1 = count),
                           by = c("timeId",
                                  "covariateId")) %>%
          dplyr::left_join(covariates2 %>%
                             dplyr::rename(count2 = count),
                           by = c("timeId",
                                  "covariateId"))
      } else {
        m <-
          dplyr::bind_rows(
            covariates1 %>% dplyr::select(covariateId),
            covariates2 %>% dplyr::select(covariateId)
          ) %>%
          dplyr::distinct() %>%
          dplyr::left_join(covariates1 %>%
                             dplyr::rename(count1 = count),
                           by = c("covariateId")) %>%
          dplyr::left_join(covariates2 %>%
                             dplyr::rename(count2 = count),
                           by = c("covariateId"))
      }
      m <- m %>%
        dplyr::distinct() %>%
        tidyr::replace_na(replace = list(count1 = 0,
                                         count2 = 0)) %>%
        dplyr::mutate(
          mean1 = .data$count1 / !!n1,
          mean2 = .data$count2 / !!n2,
          sd1 = sqrt(mean1 * (1 - mean1)),
          sd2 = sqrt(mean2 * (1 - mean2))
        ) %>%
        dplyr::mutate(sd = sqrt((sd1 ^ 2 + sd2 ^ 2) / 2),
                      stdDiff = (mean2 - mean1) / sd)
      result <-
        bindStandardizedDiff(result, m, covariateDataHasTimeId)
    }
    
    if (!is.null(covariateData1$covariatesContinuous) &&
        !is.null(covariateData2$covariatesContinuous)) {
      covariates1 <-
        prepareContinuousCovariates(covariateData1$covariatesContinuous,
                                    cohortId1,
                                    covariateDataHasTimeId)
      covariates2 <-
        prepareContinuousCovariates(covariateData2$covariatesContinuous,
                                    cohortId2,
                                    covariateDataHasTimeId)
      
      m <- dplyr::bind_rows(
        covariates1 %>% dplyr::select(timeId, covariateId),
        covariates2 %>% dplyr::select(timeId, covariateId)
      ) %>%
        dplyr::distinct() %>%
        dplyr::left_join(covariates1 %>%
                           dplyr::rename(mean1 = mean,
                                         sd1 = sd),
                         by = c("timeId",
                                "covariateId")) %>%
        dplyr::left_join(covariates2 %>%
                           dplyr::rename(mean2 = mean,
                                         sd2 = sd),
                         by = c("timeId",
                                "covariateId")) %>%
        dplyr::distinct() %>%
        tidyr::replace_na(replace = list(
          mean1 = 0,
          mean2 = 0,
          sd1 = 0,
          sd2 = 0
        )) %>%
        dplyr::mutate(sd =  sqrt((sd1 ^ 2 + sd2 ^ 2) / 2),
                      stdDiff = (mean2 - mean1) / sd)
      
      result <-
        bindStandardizedDiff(result, m, covariateDataHasTimeId)
    }
    
    result <-
      joinAndArrange(result,
                     covariateData1,
                     covariateData2,
                     covariateDataHasTimeId)
    
    return(result)
  }

isTypeAndAggregated <- function(data, name) {
  if (!isCovariateData(data)) {
    stop(paste(name, "is not of type 'covariateData'"))
  }
  if (!isAggregatedCovariateData(data)) {
    stop(paste("Covariate data in", name, "is not aggregated"))
  }
}

prepareCovariates <- function(covariates, cohortId, hasTimeId) {
  if (!is.null(cohortId)) {
    covariates <-
      covariates %>% dplyr::filter(.data$cohortDefinitionId == cohortId)
  }
  if (hasTimeId) {
    covariates <-
      covariates %>% dplyr::select(timeId, covariateId, sumValue) %>% dplyr::rename(count = sumValue) %>% dplyr::collect()
  } else {
    covariates <-
      covariates %>% dplyr::select(covariateId, sumValue) %>% dplyr::rename(count = sumValue) %>% dplyr::collect()
  }
  return(covariates)
}

prepareContinuousCovariates <-
  function(covariates, cohortId, hasTimeId) {
    if (!is.null(cohortId)) {
      covariates <-
        covariates %>% filter(.data$cohortDefinitionId == cohortId)
    }
    if (hasTimeId) {
      covariates <- covariates %>%
        select(
          timeId = "timeId",
          covariateId = "covariateId",
          mean = "averageValue",
          sd = "standardDeviation"
        ) %>%
        collect()
    } else {
      covariates <- covariates %>%
        select(covariateId = "covariateId",
               mean = "averageValue",
               sd = "standardDeviation") %>%
        collect()
    }
    return(covariates)
  }


getPopulationSize <- function(covariateData, cohortId) {
  populationSize <- attr(covariateData, "metaData")$populationSize
  if (!is.null(cohortId)) {
    populationSize <- populationSize[as.character(cohortId)]
  }
  return(populationSize)
}

bindStandardizedDiff <- function(result, newData, hasTimeId) {
  selectedCols <- if (hasTimeId) {
    c("covariateId",
      "timeId",
      "mean1",
      "sd1",
      "mean2",
      "sd2",
      "sd",
      "stdDiff")
  } else {
    c("covariateId",
      "mean1",
      "sd1",
      "mean2",
      "sd2",
      "sd",
      "stdDiff")
  }
  result <- dplyr::bind_rows(result, newData[, selectedCols])
  return(result)
}


joinAndArrange <-
  function(result,
           covariateData1,
           covariateData2,
           hasTimeId) {
    covariateRef1 <- covariateData1$covariateRef %>% dplyr::collect()
    covariateRef2 <- covariateData2$covariateRef %>% dplyr::collect()
    
    # unchecked assumption covariateRef's ae the same. They should be same if the output is from same feature extraction run.
    
    covariateRef <- dplyr::bind_rows(covariateRef1,
                                     covariateRef2) %>%
      dplyr::distinct()
    
    if (any(duplicated(covariateRef$covariateId))) {
      stop("CovariateRef's are not compatible")
    }
    
    if (hasTimeId) {
      timeRef1 <- covariateData1$timeRef %>% dplyr::collect()
      timeRef2 <- covariateData2$timeRef %>% dplyr::collect()
      
      # unchecked assumption timeRef's are the same. They should be same if the output is from same feature extraction run.
      
      timeRef <- dplyr::bind_rows(timeRef1,
                                  timeRef2) %>%
        dplyr::distinct()
      
      if (any(duplicated(covariateRef$covariateId))) {
        stop("timeRef's are not compatible")
      }
      
      result <- result %>%
        dplyr::left_join(covariateRef %>%
                           dplyr::select(covariateId, covariateName),
                         by = "covariateId") %>%
        dplyr::left_join(timeRef %>%
                           dplyr::select(timeId, startDay, endDay),
                         by = "timeId") %>%
        dplyr::arrange(dplyr::desc(abs(stdDiff)))
    } else {
      result <- result %>%
        dplyr::left_join(covariateRef %>%
                           dplyr::select(covariateId,
                                         covariateName),
                         by = "covariateId") %>%
        dplyr::left_join(covariateRef2 %>%
                           dplyr::select(covariateId,
                                         covariateName),
                         by = "covariateId") %>%
        dplyr::arrange(dplyr::desc(abs(stdDiff)))
    }
    
    return(result)
  }
