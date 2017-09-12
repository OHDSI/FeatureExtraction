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

#' @export
createTable1 <- function(covariateData, specifications) {
  if (!is(covariateData, "covariateData")) {
    stop("covariateData is not of type 'covariateData'")
  }
  if (is.null(covariateData$covariatesContinuous) && is.null(covariateData$covariates$averageValue)) {
    stop("Covariate data is not aggregated") 
  }
  if (missing(specifications)) {
    fileName <- system.file("csv", "Table1Specs.csv" , package = "FeatureExtraction")
    specifications <- read.csv(fileName, stringsAsFactors = FALSE)
  }
  fixCase <- function(label) {
    idx <- (toupper(label) == label)
    if (any(idx)) {
      label[idx] <- paste0(substr(label[idx], 1, 1), tolower(substr(label[idx], 2, nchar(label[idx]))))
    }
    return(label)
  }
  
  binaryTable <- data.frame()
  continuousTable <- data.frame()
  for (i in 1:nrow(specifications)) {
    if (specifications$analysisId[i] == "") {
      binaryTable <- binaryTable(binaryTable, data.frame(Characteristic = specifications$label[i], value = ""))
    } else {
      idx <- covariateData$analysisRef$analysisId == specifications$analysisId[i]
      if (ffbase::any.ff(idx)) {
        isBinary <- ff::as.ram(covariateData$analysisRef$isBinary[idx])
        covariateIds <- NULL
        if (isBinary == 'Y') {
          # Binary
          if (specifications$covariateIds[i] == "") {
            idx <- covariateData$covariateRef$analysisId == specifications$analysisId[i]
          } else {
            covariateIds <- as.numeric(strsplit(specifications$covariateIds[i], ",")[[1]])
            idx <- ffbase::`%in%`(covariateData$covariateRef$covariateId, covariateIds)
          }
          if (ffbase::any.ff(idx)) {
            covariateRef <- covariateData$covariateRef[idx, ]
            covariates <- covariateData$covariates[ffbase::`%in%`(covariateData$covariates$covariateId, covariateRef$covariateId), ]
            covariates <- merge(covariates, covariateRef)
            covariates <- ff::as.ram(covariates)
            if (is.null(covariateIds)) {
              covariates <- covariates[order(covariates$covariateId), ]
            } else {
              covariates <- merge(covariates, data.frame(covariateId = covariateIds, rn = 1:length(covariateIds)))
              covariates <- covariates[order(covariates$rn, covariates$covariateId), ]
            }
            covariates$covariateName <- fixCase(gsub("^.*: ", "", covariates$covariateName))
            covariates$value <- format(covariates$averageValue * 100, digits = 0)
            if (specifications$covariateIds[i] == "" || length(covariateIds) > 1) {
              binaryTable <- rbind(binaryTable, data.frame(Characteristic = specifications$label[i], value = ""))
              binaryTable <- rbind(binaryTable, data.frame(Characteristic = paste0("  ", covariates$covariateName), value = covariates$value))
            } else {
              binaryTable <- rbind(binaryTable, data.frame(Characteristic = specifications$label[i], value = covariates$value))
            }
          }
        } else {
          # Not binary
          if (specifications$covariateIds[i] == "") {
            idx <- covariateData$covariateRef$analysisId == specifications$analysisId[i]
          } else {
            covariateIds <- as.numeric(strsplit(specifications$covariateIds[i], ",")[[1]])
            idx <- ffbase::`%in%`(covariateData$covariateRef$covariateId, covariateIds)
          }
          if (ffbase::any.ff(idx)) {
            covariateRef <- covariateData$covariateRef[idx, ]
            covariates <- covariateData$covariatesContinuous[ffbase::`%in%`(covariateData$covariatesContinuous$covariateId, covariateRef$covariateId), ]
            covariates <- merge(covariates, covariateRef)
            covariates <- ff::as.ram(covariates)
            if (is.null(covariateIds)) {
              covariates <- covariates[order(covariates$covariateId), ]
            } else {
              covariates <- merge(covariates, data.frame(covariateId = covariateIds, rn = 1:length(covariateIds)))
              covariates <- covariates[order(covariates$rn, covariates$covariateId), ]
            }
            covariates$covariateName <- fixCase(gsub("^.*: ", "", covariates$covariateName))
            covariates$minValue <- format(covariates$minValue, digits = 0)
            covariates$p25Value <- format(covariates$p25Value, digits = 0)
            covariates$medianValue <- format(covariates$medianValue, digits = 0)
            covariates$p75Value <- format(covariates$p75Value, digits = 0)
            covariates$maxValue <- format(covariates$maxValue, digits = 0)
            if (specifications$covariateIds[i] == "" || length(covariateIds) > 1) {
              continuousTable <- rbind(continuousTable, data.frame(Characteristic = specifications$label[i], value = ""))
              for (j in 1:nrow(covariates)) {
                continuousTable <- rbind(continuousTable, data.frame(Characteristic = paste0("  ", covariates$covariateName[j]), value = ""))
                continuousTable <- rbind(continuousTable, data.frame(Characteristic = c("    Minimum", 
                                                                                        "    25th percentile", 
                                                                                        "    Median", 
                                                                                        "    75th percentile", 
                                                                                        "    Maximum"), 
                                                                     value = c(covariates$minValue[i], 
                                                                               covariates$p25Value[i], 
                                                                               covariates$medianValue[i], 
                                                                               covariates$p75Value[i], 
                                                                               covariates$maxValue[i])))
                
              }
            } else {
              continuousTable <- rbind(continuousTable, data.frame(Characteristic = specifications$label[i], value = ""))
              continuousTable <- rbind(continuousTable, data.frame(Characteristic = c("    Minimum", 
                                                                                      "    25th percentile", 
                                                                                      "    Median", 
                                                                                      "    75th percentile", 
                                                                                      "    Maximum"), 
                                                                   value = c(covariates$minValue, 
                                                                             covariates$p25Value, 
                                                                             covariates$medianValue, 
                                                                             covariates$p75Value, 
                                                                             covariates$maxValue)))
            }
          }
        }
      }
    }
  }
  binaryTable$value <- as.character(binaryTable$value)
  binaryTable$value[binaryTable$value == " 0"] <- "<1" 
  colnames(binaryTable) <- c("Characteristic" , paste0("% (n = ", format(covariateData$metaData$populationSize, big.mark = ","), ")"))
  colnames(continuousTable) <- c("Characteristic" , "Value")
  result <- list(part1 = binaryTable,
                 part2 = continuousTable)
  return(result)
}