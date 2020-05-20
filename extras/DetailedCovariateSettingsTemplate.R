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

#' Create detailed covariate settings
#'
#' @details
#' creates an object specifying in detail how covariates should be contructed from data in the CDM model. Warning: this 
#' function is for advanced users only.
#'
#' @param analyses   A list of \code{analysisDetail} objects as created using \code{\link{createAnalysisDetails}}.
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#' 
#' @export
createDetailedCovariateSettings <- function(analyses = list()) {
  covariateSettings <- list(temporal = FALSE,
                            analyses = analyses)
  attr(covariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
  
}

#' Create detailed temporal covariate settings
#'
#' @details
#' creates an object specifying in detail how temporal covariates should be contructed from data in the CDM model. Warning: this 
#' function is for advanced users only.
#'
#' @param analyses   A list of analysis detail objects as created using \code{\link{createAnalysisDetails}}.
%roxygenTemporal%
#'
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#' 
#' @export
createDetailedTemporalCovariateSettings <- function(analyses = list(), 
                                                    %argumentsTemporal%) {
  covariateSettings <- list(temporal = TRUE)
  formalNames <- names(formals(createDetailedTemporalCovariateSettings))
  for (name in formalNames) {
    covariateSettings[[name]] <- get(name)
  }
  attr(covariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

#' Create detailed covariate settings
#'
#' @details
#' creates an object specifying in detail how covariates should be contructed from data in the CDM model. Warning: this 
#' function is for advanced users only.
#'
#' @param analysisId   An integer between 0 and 999 that uniquely identifies this analysis.
#' @param sqlFileName   The name of the parameterized SQL file embedded in the \code{featureExtraction} package.
#' @param parameters   The list of parameter values used to render the template SQL.
%roxygenCommon%
#'
#' @return
#' An object of type \code{analysisDetail}, to be used in \code{\link{createDetailedCovariateSettings}} or \code{\link{createDetailedTemporalCovariateSettings}}.
#' 
#' @examples 
#' analysisDetails <- createAnalysisDetails(analysisId = 1,
#' sqlFileName = "DemographicsGender.sql",
#' parameters = list(analysisId = 1,
#'                   analysisName = "Gender",
#'                  domainId = "Demographics"),
#' includedCovariateConceptIds = c(), 
#' addDescendantsToInclude = FALSE,
#' excludedCovariateConceptIds = c(), 
#' addDescendantsToExclude = FALSE,
#' includedCovariateIds = c())
#' 
#' 
#' @export
createAnalysisDetails <- function(analysisId,
                                  sqlFileName,
                                  parameters,
                                  %argumentsCommon%) {
  analysisDetail <- list()
  formalNames <- names(formals(createAnalysisDetails))
  for (name in formalNames) {
    value <- get(name)
    if (is.null(value)) {
      value <- vector()
    }
    analysisDetail[[name]] <- value
  }
  class(analysisDetail) <- "analysisDetail"
  return(analysisDetail)
}

#' Convert prespecified covariate settings into detailed covariate settings
#' 
#' @details 
#' For advanced users only.
#' 
#' @param covariateSettings   An object of type \code{covariateSettings} as created for example by the \code{\link{createCovariateSettings}} function.
#' 
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#' 
#' @export
convertPrespecSettingsToDetailedSettings <- function(covariateSettings) {
  json <- .toJson(covariateSettings)
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("", package = "FeatureExtraction"))
  newJson <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$convertSettingsPrespecToDetails(json)
  detailedCovariateSettings <- .fromJson(newJson)
  attr(detailedCovariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(detailedCovariateSettings) <- "covariateSettings"
  return(detailedCovariateSettings)
}

#' Create default covariate settings
#' 
%roxygenCommon%
#' 
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#' 
#' @export
createDefaultCovariateSettings <- function(%argumentsCommon%) {
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("", package = "FeatureExtraction"))
  newJson <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$getDefaultPrespecAnalyses()
  covariateSettings <- .fromJson(newJson)
  formalNames <- names(formals(createDefaultCovariateSettings))
  for (name in formalNames) {
    value <- get(name)
    if (is.null(value)) {
      value <- vector()
    }
    covariateSettings[[name]] <- value
  }
  attr(covariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

#' Create default covariate settings
#' 
%roxygenCommon%
#' 
#' @return
#' An object of type \code{covariateSettings}, to be used in other functions.
#' 
#' @export
createDefaultTemporalCovariateSettings <- function(%argumentsCommon%) {
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(system.file("", package = "FeatureExtraction"))
  newJson <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$getDefaultPrespecTemporalAnalyses()
  covariateSettings <- .fromJson(newJson)
  formalNames <- names(formals(createDefaultTemporalCovariateSettings))
  for (name in formalNames) {
    value <- get(name)
    if (is.null(value)) {
      value <- vector()
    }
    covariateSettings[[name]] <- value
  }
  attr(covariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
