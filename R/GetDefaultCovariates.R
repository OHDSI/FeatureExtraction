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

#' Create covariate settings
#'
#' @details
#' creates an object specifying how covariates should be contructed from data in the CDM model.
#'
#' @param useCovariateDemographicsGender            A boolean value (TRUE/FALSE) to determine if gender
#'                                                  should be included in the model.
#' @param useCovariateDemographicsAge               A boolean value (TRUE/FALSE) to determine if age
#'                                                  (in 5 year increments) should be included in the
#'                                                  model.
#' @param useCovariateConditionOccurrenceLongTerm       A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of condition in the long term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateConditionOccurrence =
#'                                                  TRUE.
#' @param useCovariateConditionOccurrenceShortTerm        A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of condition in the short term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateConditionOccurrence =
#'                                                  TRUE.
#' @param longTermDays                             What is the length (in days) of the long-term window?
#' @param mediumTermDays                            What is the length (in days) of the medium-term window?
#' @param shortTermDays                             What is the length (in days) of the short-term window?
#' @param windowEndDays                             What is the last day of the window? 0 means the cohort
#'                                                  start date is the last date (included), 1 means the window
#'                                                  stops the day before the cohort start date, etc.
#'
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#'
#' @export
createCovariateSettings <- function(useDemographicsGender = FALSE,
                                    useDemographicsAge = FALSE,
                                    useDemographicsIndexYear = FALSE,
                                    useDemographicsIndexMonth = FALSE,
                                    useConditionOccurrenceLongTerm = FALSE,
                                    useConditionOccurrenceShortTerm = FALSE,
                                    useConditionEraLongTerm = FALSE,
                                    useConditionEraShortTerm = FALSE,
                                    useConditionGroupEraLongTerm = FALSE,
                                    useConditionGroupEraShortTerm = FALSE,
                                    useDrugExposureLongTerm = FALSE,
                                    useDrugExposureShortTerm = FALSE,
                                    useDrugEraLongTerm = FALSE,
                                    useDrugEraShortTerm = FALSE,
                                    useDrugGroupEraLongTerm = FALSE,
                                    useDrugGroupEraShortTerm = FALSE,
                                    useProcedureOccurrenceLongTerm = FALSE,
                                    useProcedureOccurrenceShortTerm = FALSE,
                                    useDeviceExposureLongTerm = FALSE,
                                    useDeviceExposureShortTerm = FALSE,
                                    useMeasurementLongTerm = FALSE,
                                    useMeasurementShortTerm = FALSE,
                                    useObservationLongTerm = FALSE,
                                    useObservationShortTerm = FALSE,
                                    useCharlsonIndex = FALSE,
                                    longTermDays = 365,
                                    shortTermDays = 30,
                                    windowEndDays = 0,
                                    excludedCovariateConceptIds = c(),
                                    addDescendantsToExclude = TRUE,
                                    includedCovariateConceptIds = c(),
                                    addDescendantsToInclude = TRUE,
                                    includedCovariateIds = c(),
                                    deleteCovariatesSmallCount = 100) {
  formalNames <- names(formals(createCovariateSettings))
  
  fileName <- system.file("csv","FeatureSets.csv", package = "FeatureExtraction")
  featureSet <- read.csv(fileName)
  
  useNames <- formalNames[grepl("use.*", formalNames)]
  useNames <- useNames[as.logical(mget(useNames))]
  featureSet <- featureSet[normName(featureSet$analysisName) %in% normName(gsub("use", "", useNames)), ]
  
  daysNames <- formalNames[grepl(".*Days$", formalNames)]
  days <- -as.integer(mget(daysNames))
  featureSet$startDay <- plyr::mapvalues(featureSet$startDay, daysNames, days, warn_missing = FALSE)
  featureSet$endDay <- plyr::mapvalues(featureSet$endDay, daysNames, days, warn_missing = FALSE)
  inclusionExclusion <- list(excludedCovariateConceptIds = excludedCovariateConceptIds,
                             addDescendantsToExclude = addDescendantsToExclude,
                             includedCovariateConceptIds = includedCovariateConceptIds,
                             addDescendantsToInclude = addDescendantsToInclude,
                             includedCovariateIds = includedCovariateIds,
                             deleteCovariatesSmallCount = deleteCovariatesSmallCount)
  covariateSettings <- list(featureSet = featureSet,
                            inclusionExclusion = inclusionExclusion)
  class(covariateSettings) <- append(class(covariateSettings), "covariateSettings")
  return(covariateSettings)
}

normName <- function(x) {
  return(gsub("[^a-z]", "", tolower(x)))
}
