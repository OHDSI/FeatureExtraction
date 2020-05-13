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

#' Filter covariates by row ID
#'
#' @param covariateData  An object of type \code{CovariateData}
#' @param rowIds         A vector containing the rowIds to keep.
#'
#' @return
#' An object of type \code{covariateData}.
#' @export
filterByRowId <- function(covariateData, rowIds) {
  if (!isCovariateData(covariateData))
    stop("Data not of class CovariateData")
  if (!Andromeda::isValidAndromeda(covariateData)) 
    stop("CovariateData object is closed")
  if (isAggregatedCovariateData(covariateData))
    stop("Cannot filter aggregated data by rowId")
  covariates <- covariateData$covariates %>%
    filter(.data$rowId %in% rowIds)
  
  result <- Andromeda::andromeda(covariates = covariates,
                                 covariateRef = covariateData$covariateRef,
                                 analysisRef = covariateData$analysisRef)
  metaData <- attr(covariateData, "metaData")
  metaData$populationSize <- length(rowIds)
  attr(result, "metaData") <- metaData
  class(result) <- "CovariateData"
  return(result)
}
