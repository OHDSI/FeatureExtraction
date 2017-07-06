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
%roxygen%
#' @param longTermDays                              What is the length (in days) of the long-term window?
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
#' @examples
#' \dontrun{
#' # This will create the default set of covariates:
#' settings <- createCovariateSettings(%argumentsRoxygen%)
#' 
#' }
#'
#' @export
createCovariateSettings <- function(%arguments%
                                    longTermDays = 365,
                                    shortTermDays = 30,
                                    windowEndDays = 0,
                                    excludedCovariateConceptIds = c(),
                                    addDescendantsToExclude = TRUE,
                                    includedCovariateConceptIds = c(),
                                    addDescendantsToInclude = TRUE,
                                    includedCovariateIds = c(),
                                    deleteCovariatesSmallCount = 100) {
  covariateSettings <- list()
  formalNames <- names(formals(createCovariateSettings))
  for (name in formalNames) {
    value <- get(name)
    if (!grepl("use.*", name) || value)
      covariateSettings[[name]] <- value
  }
  attr(covariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
