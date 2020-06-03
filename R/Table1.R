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

#' Get the default table 1 specifications
#'
#' @description
#' Loads the default specifications for a table 1, to be used with the \code{\link{createTable1}}
#' function.
#'
#' @return
#' A specifications objects.
#'
#' @export
getDefaultTable1Specifications <- function() {
  fileName <- system.file("csv", "Table1Specs.csv", package = "FeatureExtraction")
  colTypes <- list(label = readr::col_character(), analysisId = readr::col_integer(), covariateIds = readr::col_character())
  specifications <- readr::read_csv(fileName, col_types = colTypes, guess_max = )
  return(specifications)
}

#' Create a table 1
#'
#' @description
#' Creates a formatted table of cohort characteristics, to be included in publications or reports.
#' Allows for creating a table describing a single cohort, or a table comparing two cohorts.
#'
#' @param covariateData1   The covariate data of the cohort to be included in the table.
#' @param covariateData2   The covariate data of the cohort to also be included, when comparing two
#'                         cohorts.
#' @param specifications   Specifications of which covariates to display, and how.
#' @param output           The output format for the table. Options are \code{output = "two columns"},
#'                         \code{output = "one column"}, or \code{output = "list"}.
#' @param showCounts       Show the number of cohort entries having the binary covariate?
#' @param showPercent      Show the percentage of cohort entries having the binary covariate?
#' @param percentDigits    Number of digits to be used for percentages.
#' @param stdDiffDigits    Number of digits to be used for the standardized differences.
#' @param valueDigits      Number of digits to be used for the values of continuous variables.
#' 
#' @return
#' A data frame, or, when \code{output = "list"} a list of two data frames.
#'
#' @export
createTable1 <- function(covariateData1,
                         covariateData2 = NULL,
                         specifications = getDefaultTable1Specifications(),
                         output = "two columns",
                         showCounts = FALSE,
                         showPercent = TRUE,
                         percentDigits = 1,
                         valueDigits = 1,
                         stdDiffDigits = 2) {
  comparison <- !is.null(covariateData2)
  if (!isCovariateData(covariateData1))
    stop("covariateData1 is not of type 'covariateData'")
  if (comparison && !isCovariateData(covariateData1))
    stop("covariateData2 is not of type 'covariateData'")
  if (!isAggregatedCovariateData(covariateData1))
    stop("Covariate1 data is not aggregated")
  if (comparison && !isAggregatedCovariateData(covariateData2))
    stop("Covariate2 data is not aggregated")
  if (!showCounts && !showPercent)
    stop("Must show counts or percent, or both")
  
  fixCase <- function(label) {
    idx <- (toupper(label) == label)
    if (any(idx)) {
      label[idx] <- paste0(substr(label[idx], 1, 1),
                           tolower(substr(label[idx], 2, nchar(label[idx]))))
    }
    return(label)
  }
  
  formatCount <- function(x) {
    result <- format(round(x), justify = "right", big.mark = ",")
    result <- gsub("NA", "", result)
    result <- gsub(" ", " ", result)
    return(result)
  }
  
  formatPercent <- function(x) {
    result <- format(round(100*x, percentDigits), digits = percentDigits + 1, justify = "right")
    result <- gsub("NA", "", result)
    result <- gsub(" ", " ", result)
    return(result)
  }
  
  formatStdDiff <- function(x) {
    result <- format(round(x, stdDiffDigits), digits = stdDiffDigits + 1, justify = "right")
    result <- gsub("NA", "", result)
    result <- gsub(" ", " ", result)
    return(result)
  }
  
  formatValue <- function(x) {
    return(format(round(x, valueDigits), nsmall = valueDigits))
  }
  
  if (is.null(covariateData1$covariates)) {
    covariates <- NULL
  } else {
    covariates <- covariateData1$covariates %>% 
      select(covariateId = "covariateId", 
             count1 = "sumValue", 
             percent1 = "averageValue") %>%
      collect()
    covariates$count1 <- formatCount(covariates$count1)
    covariates$percent1 <- formatPercent(covariates$percent1)
  }
  if (is.null(covariateData1$covariatesContinuous)) {
    covariatesContinuous <- NULL
  } else {
    covariatesContinuous <- covariateData1$covariatesContinuous %>% 
      select(covariateId = "covariateId",
             averageValue1 = "averageValue",
             standardDeviation1 = "standardDeviation",
             minValue1 = "minValue",
             p25Value1 = "p25Value",
             medianValue1 = "medianValue",
             p75Value1 = "p75Value",
             maxValue1 = "maxValue") %>%
      collect()
    covariatesContinuous$averageValue1 <- formatValue(covariatesContinuous$averageValue1)
    covariatesContinuous$standardDeviation1 <- formatValue(covariatesContinuous$standardDeviation1)
    covariatesContinuous$minValue1 <- formatValue(covariatesContinuous$minValue1)
    covariatesContinuous$p25Value1 <- formatValue(covariatesContinuous$p25Value1)
    covariatesContinuous$medianValue1 <- formatValue(covariatesContinuous$medianValue1)
    covariatesContinuous$p75Value1 <- formatValue(covariatesContinuous$p75Value1)
    covariatesContinuous$maxValue1 <- formatValue(covariatesContinuous$maxValue1)
  }
  
  covariateRef <- covariateData1$covariateRef %>%
    collect()
  analysisRef <- covariateData1$analysisRef %>%
    collect()
  if (comparison) {
    stdDiff <- computeStandardizedDifference(covariateData1, covariateData2)
    if (!is.null(covariateData1$covariates) && !is.null(covariateData2$covariates)) {
      tempCovariates <- covariateData2$covariates %>%
        select(covariateId = "covariateId", 
               count2 = "sumValue", 
               percent2 = "averageValue") %>%
        collect()
      tempCovariates$count2 <- formatCount(tempCovariates$count2)
      tempCovariates$percent2 <- formatPercent(tempCovariates$percent2)
      covariates <- merge(covariates, tempCovariates, all = TRUE)
      covariates$count1[is.na(covariates$count1)] <- " 0"
      covariates$count2[is.na(covariates$count2)] <- " 0"
      covariates$percent1[is.na(covariates$percent1)] <- " 0"
      covariates$percent2[is.na(covariates$percent2)] <- " 0"
      covariates <- merge(covariates, stdDiff[, c("covariateId", "stdDiff")])
      covariates$stdDiff <- formatStdDiff(covariates$stdDiff)
    }
    if (!is.null(covariatesContinuous)) {
      tempCovariates <- covariateData2$covariatesContinuous %>% 
        select(covariateId = "covariateId",
               averageValue2 = "averageValue",
               standardDeviation2 = "standardDeviation",
               minValue2 = "minValue",
               p25Value2 = "p25Value",
               medianValue2 = "medianValue",
               p75Value2 = "p75Value",
               maxValue2 = "maxValue") %>%
        collect()
      
      tempCovariates$averageValue2 <- formatValue(tempCovariates$averageValue2)
      tempCovariates$standardDeviation2 <- formatValue(tempCovariates$standardDeviation2)
      tempCovariates$minValue2 <- formatValue(tempCovariates$minValue2)
      tempCovariates$p25Value2 <- formatValue(tempCovariates$p25Value2)
      tempCovariates$medianValue2 <- formatValue(tempCovariates$medianValue2)
      tempCovariates$p75Value2 <- formatValue(tempCovariates$p75Value2)
      tempCovariates$maxValue2 <- formatValue(tempCovariates$maxValue2)
      covariatesContinuous <- merge(covariatesContinuous, tempCovariates, all = TRUE)
      covariatesContinuous$averageValue1[is.na(covariatesContinuous$averageValue1)] <- "  "
      covariatesContinuous$standardDeviation1[is.na(covariatesContinuous$standardDeviation1)] <- "  "
      covariatesContinuous$minValue1[is.na(covariatesContinuous$minValue1)] <- "  "
      covariatesContinuous$p25Value1[is.na(covariatesContinuous$p25Value1)] <- "  "
      covariatesContinuous$medianValue1[is.na(covariatesContinuous$medianValue1)] <- "  "
      covariatesContinuous$p75Value1[is.na(covariatesContinuous$p75Value1)] <- "  "
      covariatesContinuous$maxValue1[is.na(covariatesContinuous$maxValue1)] <- "  "
      covariatesContinuous$averageValue2[is.na(covariatesContinuous$averageValue2)] <- "  "
      covariatesContinuous$standardDeviation2[is.na(covariatesContinuous$standardDeviation2)] <- "  "
      covariatesContinuous$minValue2[is.na(covariatesContinuous$minValue2)] <- "  "
      covariatesContinuous$p25Value2[is.na(covariatesContinuous$p25Value2)] <- "  "
      covariatesContinuous$medianValue2[is.na(covariatesContinuous$medianValue2)] <- "  "
      covariatesContinuous$p75Value2[is.na(covariatesContinuous$p75Value2)] <- "  "
      covariatesContinuous$maxValue2[is.na(covariatesContinuous$maxValue2)] <- "  "
      covariatesContinuous <- merge(covariatesContinuous, stdDiff[, c("covariateId", "stdDiff")])
      covariatesContinuous$stdDiff <- formatStdDiff(covariatesContinuous$stdDiff)
    }
    covariateRef <- unique(bind_rows(covariateRef, collect(covariateData2$covariateRef)))
  } else {
    covariates$count2 <- " 0"
    covariates$percent2 <- " 0"
    covariates$stdDiff <- " 0"
    covariatesContinuous$averageValue2 <- "  "
    covariatesContinuous$standardDeviation2 <- "  "
    covariatesContinuous$minValue2 <- "  "
    covariatesContinuous$p25Value2 <- "  "
    covariatesContinuous$medianValue2 <- "  "
    covariatesContinuous$p75Value2 <- "  "
    covariatesContinuous$maxValue2 <- "  "
    covariatesContinuous$stdDiff <- "  "
  }
  
  binaryTable <- tibble()
  continuousTable <- tibble()
  for (i in 1:nrow(specifications)) {
    if (is.na(specifications$analysisId[i])) {
      binaryTable <- bind_rows(binaryTable,
                               tibble(Characteristic = specifications$label[i], value = ""))
    } else {
      idx <- analysisRef$analysisId == specifications$analysisId[i]
      if (any(idx)) {
        isBinary <- analysisRef$isBinary[idx]
        covariateIds <- NULL
        if (isBinary == "Y") {
          # Binary
          if (is.na(specifications$covariateIds[i])) {
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
              covariatesSubset <- merge(covariatesSubset, tibble(covariateId = covariateIds,
                                                                 rn = 1:length(covariateIds)))
              covariatesSubset <- covariatesSubset[order(covariatesSubset$rn,
                                                         covariatesSubset$covariateId), ]
            }
            covariatesSubset$covariateName <- fixCase(gsub("^.*: ",
                                                           "",
                                                           covariatesSubset$covariateName))
            if (is.na(specifications$covariateIds[i]) || length(covariateIds) > 1) {
              binaryTable <- bind_rows(binaryTable, tibble(Characteristic = specifications$label[i],
                                                           count1 = "",
                                                           percent1 = "",
                                                           count2 = "",
                                                           percent2 = "",
                                                           stdDiff = ""))
              binaryTable <- bind_rows(binaryTable,
                                       tibble(Characteristic = paste0("  ", covariatesSubset$covariateName),
                                              count1 = covariatesSubset$count1,
                                              percent1 = covariatesSubset$percent1,
                                              count2 = covariatesSubset$count2,
                                              percent2 = covariatesSubset$percent2,
                                              stdDiff = covariatesSubset$stdDiff))
            } else {
              binaryTable <- bind_rows(binaryTable, tibble(Characteristic = specifications$label[i],
                                                           count1 = covariatesSubset$count1,
                                                           percent1 = covariatesSubset$percent1,
                                                           count2 = covariatesSubset$count2,
                                                           percent2 = covariatesSubset$percent2,
                                                           stdDiff = covariatesSubset$stdDiff))
            }
          }
        } else {
          # Not binary
          if (is.na(specifications$covariateIds[i])) {
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
              covariatesSubset <- merge(covariatesSubset, tibble(covariateId = covariateIds,
                                                                 rn = 1:length(covariateIds)))
              covariatesSubset <- covariatesSubset[order(covariatesSubset$rn,
                                                         covariatesSubset$covariateId), ]
            }
            covariatesSubset$covariateName <- fixCase(gsub("^.*: ",
                                                           "",
                                                           covariatesSubset$covariateName))
            if (is.na(specifications$covariateIds[i]) || length(covariateIds) > 1) {
              continuousTable <- bind_rows(continuousTable,
                                           tibble(Characteristic = specifications$label[i],
                                                  value1 = "",
                                                  value2 = "",
                                                  stdDiff = ""))
              for (j in 1:nrow(covariatesSubset)) {
                continuousTable <- bind_rows(continuousTable,
                                             tibble(Characteristic = paste0("  ", covariatesSubset$covariateName[j]),
                                                    value1 = "",
                                                    value2 = "",
                                                    stdDiff = ""))
                continuousTable <- bind_rows(continuousTable, tibble(Characteristic = c("    Mean",
                                                                                        "    Std. deviation",
                                                                                        "    Minimum",
                                                                                        "    25th percentile",
                                                                                        "    Median",
                                                                                        "    75th percentile",
                                                                                        "    Maximum"),
                                                                     value1 = c(covariatesSubset$averageValue1[j],
                                                                                covariatesSubset$standardDeviation1[j],
                                                                                covariatesSubset$minValue1[j],
                                                                                covariatesSubset$p25Value1[j],
                                                                                covariatesSubset$medianValue1[j],
                                                                                covariatesSubset$p75Value1[j],
                                                                                covariatesSubset$maxValue1[j]),
                                                                     value2 = c(covariatesSubset$averageValue2[j],
                                                                                covariatesSubset$standardDeviation2[j],
                                                                                covariatesSubset$minValue2[j],
                                                                                covariatesSubset$p25Value2[j],
                                                                                covariatesSubset$medianValue2[j],
                                                                                covariatesSubset$p75Value2[j],
                                                                                covariatesSubset$maxValue2[j]),
                                                                     stdDiff = c(covariatesSubset$stdDiff[j],
                                                                                 "  ",
                                                                                 "  ",
                                                                                 "  ",
                                                                                 "  ",
                                                                                 "  ",
                                                                                 "  ")))
                
              }
            } else {
              continuousTable <- bind_rows(continuousTable,
                                           tibble(Characteristic = specifications$label[i],
                                                  value1 = "",
                                                  value2 = "",
                                                  stdDiff = ""))
              continuousTable <- bind_rows(continuousTable, tibble(Characteristic = c("    Mean",
                                                                                      "    Std. deviation",
                                                                                      "    Minimum",
                                                                                      "    25th percentile",
                                                                                      "    Median",
                                                                                      "    75th percentile",
                                                                                      "    Maximum"),
                                                                   value1 = c(covariatesSubset$averageValue1,
                                                                              covariatesSubset$standardDeviation1,
                                                                              covariatesSubset$minValue1,
                                                                              covariatesSubset$p25Value1,
                                                                              covariatesSubset$medianValue1,
                                                                              covariatesSubset$p75Value1,
                                                                              covariatesSubset$maxValue1),
                                                                   value2 = c(covariatesSubset$averageValue2,
                                                                              covariatesSubset$standardDeviation2,
                                                                              covariatesSubset$minValue2,
                                                                              covariatesSubset$p25Value2,
                                                                              covariatesSubset$medianValue2,
                                                                              covariatesSubset$p75Value2,
                                                                              covariatesSubset$maxValue2),
                                                                   stdDiff = c(covariatesSubset$stdDiff,
                                                                               "  ",
                                                                               "  ",
                                                                               "  ",
                                                                               "  ",
                                                                               "  ",
                                                                               "  ")))
            }
          }
        }
      }
    }
  }
  if (nrow(continuousTable) != 0) {
    if (showCounts && showPercent) {
      if (comparison) {
        continuousTable$dummy1 <- ""
        continuousTable$dummy2 <- ""
        continuousTable <- continuousTable[, c(1, 5, 2, 6, 3, 4)]
        colnames(continuousTable) <- c("Characteristic", "", "Value", "", "Value", "Std.Diff")
      } else {
        continuousTable$dummy <- ""
        continuousTable <- continuousTable[, c(1,3,2)]
        colnames(continuousTable) <- c("Characteristic", "", "Value")
      }
    } else {
      if (comparison) {
        colnames(continuousTable) <- c("Characteristic", "Value", "Value", "Std.Diff")
      }  else {
        continuousTable$value2 <- NULL
        continuousTable$stdDiff <- NULL
        colnames(continuousTable) <- c("Characteristic", "Value")
      }
    }
  }
  
  if (nrow(binaryTable) != 0) {
    if (comparison) {
      colnames(binaryTable) <- c("Characteristic",
                                 "Count",
                                 paste0("% (n = ",
                                        formatCount(attr(covariateData1, "metaData")$populationSize),
                                        ")"),
                                 "Count",
                                 paste0("% (n = ",
                                        formatCount(attr(covariateData2, "metaData")$populationSize),
                                        ")"),
                                 "Std.Diff")
      if (!showCounts) {
        binaryTable[, 4] <- NULL
        binaryTable[, 2] <- NULL
      }
      if (!showPercent) {
        binaryTable[, 5] <- NULL
        binaryTable[, 3] <- NULL
      }
    } else {
      binaryTable$count2 <- NULL
      binaryTable$percent2 <- NULL
      binaryTable$stdDiff <- NULL
      colnames(binaryTable) <- c("Characteristic",
                                 "Count",
                                 paste0("% (n = ",
                                        formatCount(attr(covariateData1, "metaData")$populationSize),
                                        ")"))
      if (!showCounts) {
        binaryTable[, 2] <- NULL
      }
      if (!showPercent) {
        binaryTable[, 3] <- NULL
      }
    }
  }
  
  if (output == "two columns") {
    if (nrow(binaryTable) > nrow(continuousTable)) {
      if (nrow(continuousTable) > 0) {
        rowsPerColumn <- ceiling((nrow(binaryTable) + nrow(continuousTable) + 2)/2)
        column1 <- binaryTable[1:rowsPerColumn, ]
        ct <- continuousTable
        colnames(ct) <- colnames(binaryTable)
        column2 <- rbind(binaryTable[(rowsPerColumn + 1):nrow(binaryTable), ],
                         rep("", ncol(binaryTable)),
                         colnames(continuousTable),
                         ct)
      } else {
        rowsPerColumn <- ceiling((nrow(binaryTable) + nrow(continuousTable))/2)
        column1 <- binaryTable[1:rowsPerColumn, ]
        column2 <- binaryTable[(rowsPerColumn + 1):nrow(binaryTable), ]
      }
      if (nrow(column1) > nrow(column2)) {
        column2 <- rbind(column2, rep("", ncol(binaryTable)))
      }
      result <- cbind(column1, column2)
    } else {
      stop("Don't know what to do when there are more rows in the table of continuous covariates than there are in the table of binary covariates.")
    }
  } else if (output == "one column") {
    ct <- continuousTable
    colnames(ct) <- colnames(binaryTable)
    result <- rbind(binaryTable,
                    rep("", ncol(binaryTable)),
                    colnames(continuousTable),
                    ct)
  } else {
    result <- list(part1 = binaryTable, part2 = continuousTable)
  }
  return(result)
}

#' Create covariate settings for a table 1
#'
#' @description
#' Creates a covariate settings object for generating only those covariates that will be included in a
#' table 1. This function works by filtering the \code{covariateSettings} object for the covariates in
#' the \code{specifications} object.
#'
#' @param specifications                A specifications object for generating a table using the
#'                                      \code{\link{createTable1}} function.
#' @param covariateSettings             The covariate settings object to use as the basis for the
#'                                      filtered covariate settings.
#' @param includedCovariateConceptIds   A list of concept IDs that should be used to construct
#'                                      covariates.
#' @param addDescendantsToInclude       Should descendant concept IDs be added to the list of concepts
#'                                      to include?
#' @param excludedCovariateConceptIds   A list of concept IDs that should NOT be used to construct
#'                                      covariates.
#' @param addDescendantsToExclude       Should descendant concept IDs be added to the list of concepts
#'                                      to exclude?
#' @param includedCovariateIds          A list of covariate IDs that should be restricted to.
#' @return
#' A covariate settings object, for example to be used when calling the
#' \code{\link{getDbCovariateData}} function.
#'
#' @export
createTable1CovariateSettings <- function(specifications = getDefaultTable1Specifications(),
                                          covariateSettings = createDefaultCovariateSettings(),
                                          includedCovariateConceptIds = c(),
                                          addDescendantsToInclude = FALSE,
                                          excludedCovariateConceptIds = c(),
                                          addDescendantsToExclude = FALSE,
                                          includedCovariateIds = c()) {
  covariateSettings <- convertPrespecSettingsToDetailedSettings(covariateSettings)
  filterBySpecs <- function(analysis) {
    if (analysis$analysisId %in% specifications$analysisId) {
      covariateIds <- specifications$covariateIds[specifications$analysisId == analysis$analysisId]
      if (!any(is.na(covariateIds))) {
        covariateIds <- as.numeric(unlist(strsplit(covariateIds, ",")))
        analysis$includedCovariateIds <- covariateIds
      }
      analysis$includedCovariateConceptIds <- includedCovariateConceptIds
      analysis$addDescendantsToInclude <- addDescendantsToInclude
      analysis$excludedCovariateConceptIds <- excludedCovariateConceptIds
      analysis$addDescendantsToExclude <- addDescendantsToExclude
      analysis$includedCovariateIds <- unique(c(analysis$includedCovariateIds,
                                                includedCovariateIds))
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
