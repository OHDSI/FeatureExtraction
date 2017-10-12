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
getDefaultTable1Specifications <- function() {
  fileName <- system.file("csv", "Table1Specs.csv" , package = "FeatureExtraction")
  specifications <- read.csv(fileName, stringsAsFactors = FALSE)
  return(specifications)
}

#' @export
createTable1 <- function(covariateData1, 
                         covariateData2 = NULL, 
                         specifications = getDefaultTable1Specifications(),
                         output = "two columns") {
  comparison <- !is.null(covariateData2)
  if (!is(covariateData1, "covariateData")) {
    stop("covariateData1 is not of type 'covariateData'")
  }
  if (comparison && !is(covariateData2, "covariateData")) {
    stop("covariateData2 is not of type 'covariateData'")
  }
  if (is.null(covariateData1$covariatesContinuous) && is.null(covariateData1$covariates$averageValue)) {
    stop("Covariate1 data is not aggregated") 
  }
  if (comparison && is.null(covariateData2$covariatesContinuous) && is.null(covariateData2$covariates$averageValue)) {
    stop("Covariate2 data is not aggregated") 
  }

  fixCase <- function(label) {
    idx <- (toupper(label) == label)
    if (any(idx)) {
      label[idx] <- paste0(substr(label[idx], 1, 1), tolower(substr(label[idx], 2, nchar(label[idx]))))
    }
    return(label)
  }
  
  covariates <- ff::as.ram(covariateData1$covariates[, c("covariateId", "averageValue")])
  colnames(covariates)[2] <- "value1"
  covariates$value1 <- format(covariates$value1 * 100, digits = 0)
  covariatesContinuous <- ff::as.ram(covariateData1$covariatesContinuous[, c("covariateId", "minValue", "p25Value", "medianValue", "p75Value", "maxValue")])

  
  covariateRef <- ff::as.ram(covariateData1$covariateRef)
  analysisRef <- ff::as.ram(covariateData1$analysisRef)  
  if (comparison) {
    covariates2 <- ff::as.ram(covariateData1$covariates[, c("covariateId", "averageValue")])
    colnames(covariates2)[2] <- "value2"
    covariates2$value2 <- format(covariates2$value2 * 100, digits = 0)
    covariates <- merge(covariates, covariates2, all = TRUE)
    covariates$value1[is.na(covariates$value1)] <- " 0"
    covariates$value2[is.na(covariates$value2)] <- " 0"
    stdDiff <- computeStandardizedDifference(covariateData1, covariateData2)
    covariates <- merge(covariates, stdDiff[, c("covariateId", "stdDiff")])
    idx <- !ffbase::`%in%`(covariateData2$covariateRef$covariateId, covariateData1$covariateRef$covariateId)
    if (ffbase::any.ff(idx)) {
      covariateRef <- rbind(covariateRef, ff::as.ram(covariateData2$covariateRef[idx, ]))
    }
  } else {
    covariates$value2 <- 0
    covariates$stdDiff <- 0
  }
  
  binaryTable <- data.frame()
  continuousTable <- data.frame()
  for (i in 1:nrow(specifications)) {
    if (specifications$analysisId[i] == "") {
      binaryTable <- binaryTable(binaryTable, data.frame(Characteristic = specifications$label[i], value = ""))
    } else {
      idx <- analysisRef$analysisId == specifications$analysisId[i]
      if (any(idx)) {
        isBinary <- analysisRef$isBinary[idx]
        covariateIds <- NULL
        if (isBinary == 'Y') {
          # Binary
          if (specifications$covariateIds[i] == "") {
            idx <- covariateRef$analysisId == specifications$analysisId[i]
          } else {
            covariateIds <- as.numeric(strsplit(specifications$covariateIds[i], ",")[[1]])
            idx <- covariateRef$covariateId %in% covariateIds
          }
          if (any(idx)) {
            covariateRefSubset <- covariateRef[idx, ]
            covariatesSubset <- merge(covariates, covariateRefSubset)
            if (is.null(covariateIds)) {
              covariatesSubset <- covariatesSubset[order(covariatesSubset$covariateId), ]
            } else {
              covariatesSubset <- merge(covariatesSubset, data.frame(covariateId = covariateIds, rn = 1:length(covariateIds)))
              covariatesSubset <- covariatesSubset[order(covariatesSubset$rn, covariatesSubset$covariateId), ]
            }
            covariatesSubset$covariateName <- fixCase(gsub("^.*: ", "", covariatesSubset$covariateName))
            if (specifications$covariateIds[i] == "" || length(covariateIds) > 1) {
              binaryTable <- rbind(binaryTable, data.frame(Characteristic = specifications$label[i], 
                                                           value1 = "", 
                                                           value2 = "", 
                                                           stdDiff = "",
                                                           stringsAsFactors = FALSE))
              binaryTable <- rbind(binaryTable, data.frame(Characteristic = paste0("  ", covariatesSubset$covariateName), 
                                                           value1 = covariatesSubset$value1,
                                                           value2 = covariatesSubset$value2,
                                                           stdDiff = covariatesSubset$stdDiff,
                                                           stringsAsFactors = FALSE))
            } else {
              binaryTable <- rbind(binaryTable, data.frame(Characteristic = specifications$label[i], 
                                                           value1 = covariatesSubset$value1,
                                                           value2 = covariatesSubset$value2,
                                                           stdDiff = covariatesSubset$stdDiff,
                                                           stringsAsFactors = FALSE))
            }
          }
        } else {
          # Not binary
          if (specifications$covariateIds[i] == "") {
            idx <- covariateRef$analysisId == specifications$analysisId[i]
          } else {
            covariateIds <- as.numeric(strsplit(specifications$covariateIds[i], ",")[[1]])
            idx <- covariateRef$covariateId %in% covariateIds
          }
          if (any(idx)) {
            covariateRefSubset <- covariateRef[idx, ]
            covariatesSubset <- covariatesContinuous[covariatesContinuous$covariateId %in% covariateRefSubset$covariateId, ]
            covariatesSubset <- merge(covariatesSubset, covariateRefSubset)
            if (is.null(covariateIds)) {
              covariatesSubset <- covariatesSubset[order(covariatesSubset$covariateId), ]
            } else {
              covariatesSubset <- merge(covariatesSubset, data.frame(covariateId = covariateIds, rn = 1:length(covariateIds)))
              covariatesSubset <- covariatesSubset[order(covariatesSubset$rn, covariatesSubset$covariateId), ]
            }
            covariatesSubset$covariateName <- fixCase(gsub("^.*: ", "", covariatesSubset$covariateName))
            covariatesSubset$minValue <- format(covariatesSubset$minValue, digits = 0)
            covariatesSubset$p25Value <- format(covariatesSubset$p25Value, digits = 0)
            covariatesSubset$medianValue <- format(covariatesSubset$medianValue, digits = 0)
            covariatesSubset$p75Value <- format(covariatesSubset$p75Value, digits = 0)
            covariatesSubset$maxValue <- format(covariatesSubset$maxValue, digits = 0)
            if (specifications$covariateIds[i] == "" || length(covariateIds) > 1) {
              continuousTable <- rbind(continuousTable, data.frame(Characteristic = specifications$label[i], value = ""))
              for (j in 1:nrow(covariates)) {
                continuousTable <- rbind(continuousTable, data.frame(Characteristic = paste0("  ", covariatesSubset$covariateName[j]), 
                                                                     value = "",
                                                                     stringsAsFactors = FALSE))
                continuousTable <- rbind(continuousTable, data.frame(Characteristic = c("    Minimum", 
                                                                                        "    25th percentile", 
                                                                                        "    Median", 
                                                                                        "    75th percentile", 
                                                                                        "    Maximum"), 
                                                                     value = c(covariatesSubset$minValue[i], 
                                                                               covariatesSubset$p25Value[i], 
                                                                               covariatesSubset$medianValue[i], 
                                                                               covariatesSubset$p75Value[i], 
                                                                               covariatesSubset$maxValue[i]),
                                                                     stringsAsFactors = FALSE))
                
              }
            } else {
              continuousTable <- rbind(continuousTable, data.frame(Characteristic = specifications$label[i], 
                                                                   value = "",
                                                                   stringsAsFactors = FALSE))
              continuousTable <- rbind(continuousTable, data.frame(Characteristic = c("    Minimum", 
                                                                                      "    25th percentile", 
                                                                                      "    Median", 
                                                                                      "    75th percentile", 
                                                                                      "    Maximum"), 
                                                                   value = c(covariatesSubset$minValue, 
                                                                             covariatesSubset$p25Value, 
                                                                             covariatesSubset$medianValue, 
                                                                             covariatesSubset$p75Value, 
                                                                             covariatesSubset$maxValue),
                                                                   stringsAsFactors = FALSE))
            }
          }
        }
      }
    }
  }
  binaryTable$value1 <- as.character(binaryTable$value1)
  binaryTable$value1[binaryTable$value1 == " 0"] <- "<1" 
  if (comparison) {
    binaryTable$value2 <- as.character(binaryTable$value2)
    binaryTable$value2[binaryTable$value2 == " 0"] <- "<1" 
    colnames(binaryTable) <- c("Characteristic" , paste0("% (n = ", format(covariateData1$metaData$populationSize, big.mark = ","), ")"))
  } else {
    binaryTable$value2 <- NULL
    binaryTable$stdDiff <- NULL
    colnames(binaryTable) <- c("Characteristic" , paste0("% (n = ", format(covariateData1$metaData$populationSize, big.mark = ","), ")"))    
  }
  colnames(continuousTable) <- c("Characteristic" , "Value")
  
  if (output == "two columns") {
    if (nrow(binaryTable) > nrow(continuousTable)) {
      rowsPerColumn <- ceiling((nrow(binaryTable) + nrow(continuousTable) + 1) / 2)
      # bt <- as.matrix(binaryTable)
      # ct <- as.matrix(continuousTable)
      # 
      # result <- cbind(rbind(t(colnames(bt)), 
      #                       bt[1:rowsPerColumn, ]),
      #                 rbind(t(colnames(bt)), 
      #                       bt[(rowsPerColumn+1):nrow(bt), ],
      #                       t(rep("", ncol(bt))),
      #                       t(colnames(ct)), 
      #                       ct))
      # rownames(result) <- NULL
      # colnames(result) <- NULL
      # write.table(result)
      # knitr::kable(result)
      # write.table(result, row.names=F, col.names=F, file = "c:/temp/table.csv", sep = ",")
      column1 <- binaryTable[1:rowsPerColumn, ]
      colnames(continuousTable) <- colnames(binaryTable)
      column2 <- rbind(binaryTable[(rowsPerColumn+1):nrow(binaryTable), ],
                       rep("", ncol(binaryTable)),
                       colnames(continuousTable),
                       continuousTable)
      result <- cbind(column1, column2)
      
                      
    } else {
      
    }
    
  } else {
    result <- list(part1 = binaryTable,
                   part2 = continuousTable)
  }
  return(result)
}

#' @export
createTable1CovariateSettings <- function(specifications = getDefaultTable1Specifications()) {
  covariateSettings <- createDefaultCovariateSettings()  
  covariateSettings <- convertPrespecSettingsToDetailedSettings(covariateSettings)
  filterBySpecs <- function(analysis) {
    if (analysis$analysisId %in% specifications$analysisId) {
      covariateIds <- specifications$covariateIds[specifications$analysisId == analysis$analysisId]
      if (!any(covariateIds == "")) {
        covariateIds <- as.numeric(unlist(strsplit(covariateIds, ",")))
        analysis$includedCovariateIds <- covariateIds
      }
      return(analysis)
    } else {
      return(NULL)
    }
  }
  analyses <- lapply(covariateSettings$analyses, filterBySpecs)
  analyses <- analyses[which(!sapply(analyses, is.null))]
  covariateSettings$analyses <- analyses
  return(covariateSettings)
}