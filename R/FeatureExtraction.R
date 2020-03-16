# @file FeatureExtraction.R
#
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

#' FeatureExtraction
#'
#' @docType package
#' @name FeatureExtraction
#' @importFrom Rcpp evalCpp
#' @importFrom SqlRender loadRenderTranslateSql translate render
#' @importFrom plyr ddply
#' @importFrom methods is
#' @importFrom stats aggregate quantile sd
#' @importFrom utils read.csv
#' @import bit
#' @import DatabaseConnector
#' @useDynLib FeatureExtraction
NULL

.onLoad <- function(libname, pkgname) {
  
  rJava::.jpackage(pkgname, lib.loc = libname)
  
  # Copied this from the ff package:
  if (is.null(getOption("ffbatchbytes"))) {
    # memory.limit is windows specific
    if (.Platform$OS.type == "windows")
    {
      if (getRversion() >= "2.6.0")  # memory.limit was silently changed from 2.6.0 to return in MB instead of bytes
        options(ffbatchbytes =  utils::memory.limit()*(1024^2 / 100))
      else
        options(ffbatchbytes =  utils::memory.limit() / 100)
    } else {
      # some magic constant
      options(ffbatchbytes = 16*1024^2)
    }
  }
  if (is.null(getOption("ffmaxbytes"))) {
    # memory.limit is windows specific
    if (.Platform$OS.type == "windows") {
      if (getRversion() >= "2.6.0")
        options(ffmaxbytes = 0.5 * utils::memory.limit() * (1024^2)) 
      else 
        options(ffmaxbytes = 0.5 * utils::memory.limit())
    } else {
      # some magic constant
      options(ffmaxbytes = 0.5 * 1024^3)
    }
  }
  
  # Workaround for problem with ff on machines with lots of memory (see
  # https://github.com/edwindj/ffbase/issues/37)
  options(ffbatchbytes = min(getOption("ffbatchbytes"), .Machine$integer.max / 10))
  options(ffmaxbytes = min(getOption("ffmaxbytes"), .Machine$integer.max * 6))
  
  # Simulate behavior before R 3.6.0. Some explicit ff and ffbase calss so implicit calls work in future:
  ffbase::any.ff(ff::as.ff(c(TRUE, FALSE)))
  
  # Verify checksum of JAR:
  storedChecksum <- scan(file = system.file("csv", "jarChecksum.txt", package = "FeatureExtraction"), what = character(), quiet = TRUE)
  computedChecksum <- tryCatch(rJava::J("org.ohdsi.featureExtraction.JarChecksum","computeJarChecksum"),
                               error = function(e) {warning("Problem connecting to Java. This is normal when runing roxygen."); return("")})
  if (computedChecksum != "" && (storedChecksum != computedChecksum)) {
    warning("Java library version does not match R package version! Please try reinstalling the FeatureExtraction package.
            Make sure to close all instances of R, and open only one instance before reinstalling. Also make sure your 
            R workspace is not reloaded on startup. Delete your .Rdata file if necessary")
  }
}

.toJson <- function(object) {
  return(as.character(jsonlite::toJSON(object, force = TRUE, auto_unbox = TRUE)))
}

.fromJson <- function(json) {
  return(jsonlite::fromJSON(json, simplifyVector = TRUE, simplifyDataFrame = FALSE))
}
