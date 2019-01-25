# Copyright 2019 Observational Health Data Sciences and Informatics
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
#' @param object   Either an object of type \code{covariateData}, or an ffdf object containing
#'                 covariate values.
#' @param rowIds   A vector (or ff object) containing the rowIds to keep.
#'
#' @return
#' Either an object of type \code{covariateData}, or an ffdf object containing covariate values.
#' (depending on the type of the \code{object} argument.
#' @export
filterByRowId <- function(object, rowIds) {
  if (!is(rowIds, "ff")) {
    rowIds <- ff::as.ff(rowIds)
  }
  if (is(object, "covariateData")) {
    idx <- ffbase::`%in%`(object$covariates$rowId, rowIds)
    object$covariates <- object$covariates[idx, ]
    return(object)
  } else {
    idx <- ffbase::`%in%`(object$rowId, rowIds)
    object <- object[idx, ]
    return(object)
  }
}
