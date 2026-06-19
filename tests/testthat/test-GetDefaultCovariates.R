# This file covers the code in GetDefaultCovariates.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetDefaultCovariates.R", "tests/testthat/test-GetDefaultCovariates.R"))

createDefaultCovariateSqlJson <- function(covariateSettings,
                                          aggregated = FALSE,
                                          minCharacterizationMean = 0,
                                          minCharacterizationCount = 0) {
  packageFolders <- c(
    file.path(getwd(), "inst"),
    file.path(getwd(), "..", "..", "inst"),
    system.file("", package = "FeatureExtraction")
  )
  packageFolder <- packageFolders[dir.exists(file.path(packageFolders, "java"))][1]
  javaFolder <- file.path(packageFolder, "java")
  rJava::.jaddClassPath(list.files(javaFolder, pattern = "\\.jar$", full.names = TRUE))
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(packageFolder)
  json <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$createSql(
    FeatureExtraction:::.toJson(covariateSettings),
    aggregated,
    "#cohort_person",
    "row_id",
    rJava::.jarray(as.character(-1)),
    "cdm",
    as.character(minCharacterizationMean),
    as.character(minCharacterizationCount)
  )
  jsonlite::fromJSON(json, simplifyVector = TRUE, simplifyDataFrame = FALSE)
}

test_that("Test exit conditions", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  # covariateSettings object type
  expect_error(getDbDefaultCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    covariateSettings = list(),
    targetDatabaseSchema = "main",
    targetCovariateTable = "cov",
    targetCovariateRefTable = "cov_ref",
    targetAnalysisRefTable = "cov_analysis_ref"
  ))
  # CDM 4 not supported
  expect_error(getDbDefaultCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    cdmVersion = "4",
    covariateSettings = createDefaultCovariateSettings(),
    targetDatabaseSchema = "main",
    targetCovariateTable = "cov",
    targetCovariateRefTable = "cov_ref",
    targetAnalysisRefTable = "cov_analysis_ref"
  ))

  # targetCovariateTable and aggregated not supported
  expect_error(getDbDefaultCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    cohortId = -1,
    covariateSettings = createDefaultCovariateSettings(),
    targetDatabaseSchema = "main",
    targetCovariateTable = "cov",
    targetCovariateRefTable = "cov_ref",
    targetAnalysisRefTable = "cov_analysis_ref",
    aggregated = TRUE
  ))
})

test_that("Aggregated feature SQL supports minCharacterizationCount", {
  covariateSettings <- createCovariateSettings(useDemographicsGender = TRUE)

  json <- createDefaultCovariateSqlJson(
    covariateSettings = covariateSettings,
    aggregated = TRUE,
    minCharacterizationCount = 2
  )
  expect_match(
    json$sqlQueryFeatures,
    "WHERE all_covariates\\.sum_value >= 2;",
    perl = TRUE
  )

  json <- createDefaultCovariateSqlJson(
    covariateSettings = covariateSettings,
    aggregated = TRUE,
    minCharacterizationMean = 0.01,
    minCharacterizationCount = 2
  )
  expect_match(
    json$sqlQueryFeatures,
    "WHERE all_covariates\\.sum_value / \\(1\\.0 \\* total\\.total_count\\) >= 0\\.01 AND all_covariates\\.sum_value >= 2;",
    perl = TRUE
  )
})
