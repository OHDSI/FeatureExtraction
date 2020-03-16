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

%warning%

#' Create covariate settings
#'
#' @details
#' creates an object specifying how covariates should be contructed from data in the CDM model.
#'
%roxygen%
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#' 
#' @examples 
#' settings <- %functionName%(%roxygenArgs%)
#' 
#' @export
%functionName% <- function(%arguments%) {
  covariateSettings <- list(temporal = %temporal%)
  formalNames <- names(formals(%functionName%))
  for (name in formalNames) {
    value <- get(name)
    if (is.null(value)) {
      value <- vector()
    }
    if (grepl("use.*", name)) {
       if (value) {
         covariateSettings[[sub("use", "", name)]] <- value
       }
    } else {
      covariateSettings[[name]] <- value
    }
  }
  attr(covariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
