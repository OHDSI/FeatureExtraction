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

#' Tidy covariate data
#'
#' @details
#' Normalize covariate values by dividing by the max and/or remove redundant covariates and/or remove
#' infrequent covariates. For temporal covariates, redundancy is evaluated per time ID.
#'
#' @param covariateData      An object as generated using the \code{\link{getDbCovariateData}}
#'                           function. 
#' @param minFraction        Minimum fraction of the population that should have a non-zero value for a
#'                           covariate for that covariate to be kept. Set to 0 to don't filter on
#'                           frequency.
#' @param normalize          Normalize the coviariates? (dividing by the max)
#' @param removeRedundancy   Should redundant covariates be removed?
#'
#' @export
tidyCovariateData <- function(covariateData,
                              minFraction = 0.001,
                              normalize = TRUE,
                              removeRedundancy = TRUE) {
  if (!isCovariateData(covariateData))
    stop("Data not of class CovariateData")
  if (!Andromeda::isValidAndromeda(covariateData)) 
    stop("CovariateData object is closed")
  if (isAggregatedCovariateData(covariateData))
    stop("Cannot tidy aggregatd covariates")
  newCovariateData <- Andromeda::andromeda(covariateRef = covariateData$covariateRef,
                                           analysisRef = covariateData$analysisRef)
  metaData <- attr(covariateData, "metaData")
  populationSize <- metaData$populationSize 
  if (nrow(covariateData$covariates) == 0) {
    newCovariateData$covariates <- covariateData$covariates
  } else {
    newCovariates <- covariateData$covariates
    covariateData$maxValuePerCovariateId <- covariateData$covariates %>% 
      group_by(rlang::sym("covariateId")) %>% 
      summarise(maxValue = max(rlang::sym("covariateValue"), na.rm = TRUE))
    
    if (removeRedundancy || minFraction != 0) {
      covariateData$valueCounts <- covariateData$covariates %>% 
        group_by(rlang::sym("covariateId")) %>% 
        count()
    }
    
    ignoreCovariateIds <- c()
    deleteCovariateIds <- c()
    if (removeRedundancy) {
      ParallelLogger::logInfo("Removing redundant covariates")
      start <- Sys.time()
      covariateData$binaryCovariateIds <- covariateData$maxValuePerCovariateId %>% 
        filter(rlang::sym("maxValue") == 1) %>% 
        select(covariateId = rlang::sym("covariateId"))
      if (nrow(covariateData$binaryCovariateIds) != 0) {
        if (isTemporalCovariateData(covariateData)) { 
          # Temporal
          covariateData$temporalValueCounts <- covariateData$covariates %>% 
            inner_join(covariateData$binaryCovariateIds, by = "covariateId") %>% 
            group_by(rlang::sym("covariateId"), rlang::sym("timeId")) %>% 
            count()
          
          # First, find all single covariates that, for every timeId, appear in every row with the same value
          covariateData$deleteCovariateTimeIds <-  covariateData$temporalValueCounts %>% 
            filter(n == populationSize) %>% 
            select(rlang::sym("covariateId"), rlang::sym("timeId"))
          
          # Next, find groups of covariates (analyses) that together cover everyone:
          analysisIds <- covariateData$temporalValueCounts %>%
            anti_join(covariateData$deleteCovariateTimeIds, by = c("covariateId", "timeId")) %>%
            inner_join(covariateData$covariateRef, by = "covariateId") %>%
            group_by(rlang::sym("analysisId")) %>%
            summarise(n = sum(rlang::sym("n"), na.rm = TRUE)) %>%
            filter(n == populationSize) %>% 
            select(rlang::sym("analysisId")) 
          # For those, find most prevalent covariate, and mark it for deletion:
          valueCounts <- analysisIds %>%
            inner_join(covariateData$covariateRef, by = "analysisId") %>%
            inner_join(covariateData$temporalValueCounts, by = "covariateId") %>%
            select(rlang::sym("analysisId"), rlang::sym("covariateId"), rlang::sym("timeId"), rlang::sym("n")) %>%
            collect()
          valueCounts <- valueCounts[order(valueCounts$analysisId, -valueCounts$n), ]
          Andromeda::appendToTable(covariateData$deleteCovariateTimeIds, 
                                   valueCounts[!duplicated(valueCounts$analysisId), c("covariateId", "timeId")])
          
          newCovariates <- newCovariates %>%
            anti_join(covariateData$deleteCovariateTimeIds, by = c("covariateId", "timeId"))
        } else {
          # Non-temporal
          
          # First, find all single covariates that appear in every row with the same value
          toDelete <-  covariateData$valueCounts %>% 
            inner_join(covariateData$binaryCovariateIds, by = "covariateId") %>% 
            filter(n == populationSize) %>% 
            select(rlang::sym("covariateId")) %>% 
            collect()
          deleteCovariateIds <- toDelete$covariateId
          
          # Next, find groups of covariates (analyses) that together cover everyone:
          analysisIds <- covariateData$valueCounts %>%
            inner_join(covariateData$binaryCovariateIds, by = "covariateId") %>% 
            filter(!rlang::sym("covariateId") %in% deleteCovariateIds) %>%
            inner_join(covariateData$covariateRef, by = "covariateId") %>%
            group_by(rlang::sym("analysisId")) %>%
            summarise(n = sum(rlang::sym("n"), na.rm = TRUE)) %>%
            filter(n == populationSize) %>% 
            select(rlang::sym("analysisId")) 
          # For those, find most prevalent covariate, and mark it for deletion:
          valueCounts <- analysisIds %>%
            inner_join(covariateData$covariateRef, by = "analysisId") %>%
            inner_join(covariateData$valueCounts, by = "covariateId") %>%
            select(rlang::sym("analysisId"), rlang::sym("covariateId"), rlang::sym("n")) %>%
            collect()
          valueCounts <- valueCounts[order(valueCounts$analysisId, -valueCounts$n), ]
          deleteCovariateIds <- c(deleteCovariateIds, valueCounts$covariateId[!duplicated(valueCounts$analysisId)])
          ignoreCovariateIds <- valueCounts$covariateId
        }
      }
      metaData$deletedRedundantCovariateIds <- deleteCovariateIds
      delta <- Sys.time() - start
      ParallelLogger::logInfo("Removing redundant covariates took ", signif(delta, 3), " ", attr(delta, "units"))
    }
    if (minFraction != 0) {
      ParallelLogger::logInfo("Removing infrequent covariates")
      start <- Sys.time()
      minCount <- floor(minFraction * populationSize)
      toDelete <- covariateData$valueCounts %>%
        filter(rlang::sym("n") < minCount) %>%
        filter(!rlang::sym("covariateId") %in% ignoreCovariateIds) %>%
        select(rlang::sym("covariateId")) %>%
        collect()
      
      metaData$deletedInfrequentCovariateIds <- toDelete$covariateId
      deleteCovariateIds <- c(deleteCovariateIds, toDelete$covariateId)
      delta <- Sys.time() - start
      ParallelLogger::logInfo("Removing infrequent covariates took ", signif(delta, 3), " ", attr(delta, "units"))
    }
    if (length(deleteCovariateIds) > 0) {
      newCovariates <- newCovariates %>% 
        filter(!rlang::sym("covariateId") %in% deleteCovariateIds)
    }
    
    if (normalize) {
      ParallelLogger::logInfo("Normalizing covariates")
      start <- Sys.time()
      newCovariates <- newCovariates %>% 
        inner_join(covariateData$maxValuePerCovariateId, by = "covariateId") %>%
        mutate(covariateValue = rlang::sym("covariateValue") / rlang::sym("maxValue")) %>%
        select(-rlang::sym("maxValue"))
      metaData$normFactors <- covariateData$maxValuePerCovariateId %>%
        collect()
      
      delta <- Sys.time() - start
      ParallelLogger::logInfo("Normalizing covariates took ", signif(delta, 3), " ", attr(delta, "units"))
    } 
    newCovariateData$covariates <- newCovariates
  }
  #Cleanup:
  covariateData$binaryCovariateIds <- NULL
  covariateData$maxValuePerCovariateId <- NULL
  covariateData$valueCounts <- NULL
  covariateData$deleteCovariateTimeIds <- NULL
  
  class(newCovariateData) <- "CovariateData"
  attr(newCovariateData, "metaData") <- metaData
  return(newCovariateData)
}
