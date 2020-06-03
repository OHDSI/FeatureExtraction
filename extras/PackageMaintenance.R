# @file PackageMaintenance
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

# Format and check code
OhdsiRTools::formatRFolder("./R")
OhdsiRTools::checkUsagePackage("FeatureExtraction")
OhdsiRTools::updateCopyrightYearFolder()
OhdsiRTools::findNonAsciiStringsInFolder()
devtools::spell_check()

# Create manual and vignettes
unlink("extras/FeatureExtraction.pdf")
shell("R CMD Rd2pdf ./ --output=extras/FeatureExtraction.pdf")

dir.create("inst/doc")
rmarkdown::render("vignettes/CreatingCustomCovariateBuilders.Rmd",
                  output_file = "../inst/doc/CreatingCustomCovariateBuilders.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/CreatingCustomCovariateBuilders.tex")

rmarkdown::render("vignettes/CreatingCovariatesUsingCohortAttributes.Rmd",
                  output_file = "../inst/doc/CreatingCovariatesUsingCohortAttributes.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/CreatingCovariatesUsingCohortAttributes.tex")

rmarkdown::render("vignettes/UsingFeatureExtraction.Rmd",
                  output_file = "../inst/doc/UsingFeatureExtraction.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/UsingFeatureExtraction.tex")

# Note: these LaTex packages are required to render the Korean vignettes, but for 
# some reason are not installed automatically:
# - kotex*
# - infwarerr
# - kvoptions

rmarkdown::render("vignettes/UsingFeatureExtractionKorean.Rmd",
                  output_file = "../inst/doc/UsingFeatureExtractionKorean.pdf",
                  rmarkdown::pdf_document(number_sections = TRUE))
unlink("inst/doc/UsingFeatureExtractionKorean.tex")

rmarkdown::render("vignettes/CreatingCustomCovariateBuildersKorean.Rmd",
                  output_file = "../inst/doc/CreatingCustomCovariateBuildersKorean.pdf",
                  rmarkdown::pdf_document(number_sections = TRUE))
unlink("inst/doc/CreatingCustomCovariateBuildersKorean.tex")

pkgdown::build_site()
OhdsiRTools::fixHadesLogo()

# Store JAR checksum --------------------------------------------------------------
checksum <- rJava::J("org.ohdsi.featureExtraction.JarChecksum", "computeJarChecksum")
write(checksum, file.path("inst", "csv", "jarChecksum.txt"))

# Generate covariate settings function from template ----------------------
prespecAnalyses <- read.csv("inst/csv/PrespecAnalyses.csv", stringsAsFactors = FALSE)
otherParameters <- read.csv("inst/csv/OtherParameters.csv", stringsAsFactors = FALSE)
arguments <- data.frame(name = paste0("use", prespecAnalyses$analysisName),
                        defaultValue = "FALSE",
                        description = paste0(prespecAnalyses$description, " (analysis ID ", prespecAnalyses$analysisId, ")"),
                        example = prespecAnalyses$isDefault,
                        stringsAsFactors = FALSE)
otherParameters$example <- otherParameters$defaultValue
arguments <- rbind(arguments, otherParameters[otherParameters$type == "days", c("name", "defaultValue", "description", "example")])
arguments <- rbind(arguments, otherParameters[otherParameters$type == "common", c("name", "defaultValue", "description", "example")])
arguments$defaultValue <- gsub("^\\[", "c(", arguments$defaultValue)
arguments$defaultValue <- gsub("\\]$", ")", arguments$defaultValue)
arguments$defaultValue[arguments$defaultValue == "false"] <- "FALSE"
arguments$defaultValue[arguments$defaultValue == "true"] <- "TRUE"
arguments$example <- gsub("^\\[", "c(", arguments$example)
arguments$example <- gsub("\\]$", ")", arguments$example)
arguments$example[arguments$example == "false"] <- "FALSE"
arguments$example[arguments$example == "true"] <- "TRUE"
roxygen <- paste(paste("#' @param", arguments$name, arguments$description), collapse = "\n")
argumentString <- paste(paste(arguments$name, "=", arguments$defaultValue), collapse = ",\n")
roxygenArgsString <- paste(paste(arguments$name, "=", arguments$example), collapse = ",\n#'")
rCode <- readLines("extras/DefaultCovariateSettingsTemplate.R")
rCode <- gsub("%warning%", "# This file has been autogenerated. Do not change by hand.", rCode)
rCode <- gsub("%functionName%", "createCovariateSettings", rCode)
rCode <- gsub("%temporal%", "FALSE", rCode)
rCode <- gsub("%roxygen%", roxygen, rCode)
rCode <- gsub("%roxygenArgs%", roxygenArgsString, rCode)
rCode <- gsub("%arguments%", argumentString, rCode)
writeLines(rCode, "R/DefaultCovariateSettings.R")
OhdsiRTools::formatRFile("R/DefaultCovariateSettings.R")


# Generate temporal covariate settings function from template ----------------------
prespecAnalyses <- read.csv("inst/csv/PrespecTemporalAnalyses.csv", stringsAsFactors = FALSE)
otherParameters <- read.csv("inst/csv/OtherParameters.csv", stringsAsFactors = FALSE)
arguments <- data.frame(name = paste0("use", prespecAnalyses$analysisName),
                        defaultValue = "FALSE",
                        description = paste0(prespecAnalyses$description, " (analysis ID ", prespecAnalyses$analysisId, ")"),
                        example = prespecAnalyses$isDefault,
                        stringsAsFactors = FALSE)
otherParameters$example <- otherParameters$defaultValue
arguments <- rbind(arguments, otherParameters[otherParameters$type == "temporal", c("name", "defaultValue", "description", "example")])
arguments <- rbind(arguments, otherParameters[otherParameters$type == "common", c("name", "defaultValue", "description", "example")])
arguments$defaultValue <- gsub("^\\[", "c(", arguments$defaultValue)
arguments$defaultValue <- gsub("\\]$", ")", arguments$defaultValue)
arguments$defaultValue <- gsub("^c\\(-365,.*,-1\\)$", "-365:-1", arguments$defaultValue)
arguments$defaultValue[arguments$defaultValue == "false"] <- "FALSE"
arguments$defaultValue[arguments$defaultValue == "true"] <- "TRUE"
arguments$example <- gsub("^\\[", "c(", arguments$example)
arguments$example <- gsub("\\]$", ")", arguments$example)
arguments$example <- gsub("^c\\(-365,.*,-1\\)$", "-365:-1", arguments$example)
arguments$example[arguments$example == "false"] <- "FALSE"
arguments$example[arguments$example == "true"] <- "TRUE"
roxygen <- paste(paste("#' @param", arguments$name, arguments$description), collapse = "\n")
argumentString <- paste(paste(arguments$name, "=", arguments$defaultValue), collapse = ",\n")
roxygenArgsString <- paste(paste(arguments$name, "=", arguments$example), collapse = ",\n#'")
rCode <- readLines("extras/DefaultCovariateSettingsTemplate.R")
rCode <- gsub("%warning%", "# This file has been autogenerated. Do not change by hand.", rCode)
rCode <- gsub("%functionName%", "createTemporalCovariateSettings", rCode)
rCode <- gsub("%temporal%", "TRUE", rCode)
rCode <- gsub("%roxygen%", roxygen, rCode)
rCode <- gsub("%roxygenArgs%", roxygenArgsString, rCode)
rCode <- gsub("%arguments%", argumentString, rCode)
writeLines(rCode, "R/DefaultTemporalCovariateSettings.R")
OhdsiRTools::formatRFile("R/DefaultTemporalCovariateSettings.R")


# Generate detailed covariate settings function from template ----------------------
arguments <- read.csv("inst/csv/OtherParameters.csv", stringsAsFactors = FALSE)
arguments$defaultValue <- gsub("^\\[", "c(", arguments$defaultValue)
arguments$defaultValue <- gsub("\\]$", ")", arguments$defaultValue)
arguments$defaultValue <- gsub("^c\\(-365,.*,-1\\)$", "-365:-1", arguments$defaultValue)
arguments$defaultValue[arguments$defaultValue == "false"] <- "FALSE"
arguments$defaultValue[arguments$defaultValue == "true"] <- "TRUE"
argumentsTemporal <- arguments[arguments$type == "temporal", ]
roxygenTemporal <- paste(paste("#' @param", argumentsTemporal$name, argumentsTemporal$description), collapse = "\n")
argumentsTemporalString <- paste(paste(argumentsTemporal$name, "=", argumentsTemporal$defaultValue), collapse = ",\n")
argumentsCommon <- arguments[arguments$type == "common", ]
roxygenCommon <- paste(paste("#' @param", argumentsCommon$name, argumentsCommon$description), collapse = "\n")
argumentsCommonString <- paste(paste(argumentsCommon$name, "=", argumentsCommon$defaultValue), collapse = ",\n")
rCode <- readLines("extras/DetailedCovariateSettingsTemplate.R")
rCode <- gsub("%warning%", "# This file has been autogenerated. Do not change by hand.", rCode)
rCode <- gsub("%roxygenTemporal%", roxygenTemporal, rCode)
rCode <- gsub("%argumentsTemporal%", argumentsTemporalString, rCode)
rCode <- gsub("%roxygenCommon%", roxygenCommon, rCode)
rCode <- gsub("%argumentsCommon%", argumentsCommonString, rCode)
writeLines(rCode, "R/DetailedCovariateSettings.R")
OhdsiRTools::formatRFile("R/DetailedCovariateSettings.R")
