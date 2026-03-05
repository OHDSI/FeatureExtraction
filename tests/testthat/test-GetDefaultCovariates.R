# This file covers the code in GetDefaultCovariates.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetDefaultCovariates.R", "tests/testthat/test-GetDefaultCovariates.R"))

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
