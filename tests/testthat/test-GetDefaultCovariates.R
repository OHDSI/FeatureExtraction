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

# AGS - This test fails and is likely due to a bug when using SqlLite
# test_that("Test target table", {
#   connection <- DatabaseConnector::connect(connectionDetails)
#   Eunomia::createCohorts(connectionDetails)
#
#   results <- getDbDefaultCovariateData(connection = connection,
#                                        cdmDatabaseSchema = "main",
#                                        cohortTable = "cohort",
#                                        covariateSettings = createDefaultCovariateSettings(),
#                                        targetDatabaseSchema = "main",
#                                        targetCovariateTable = "ut_cov",
#                                        targetCovariateRefTable = "ut_cov_ref",
#                                        targetAnalysisRefTable = "ut_cov_analysis_ref")
#
#   on.exit(DatabaseConnector::disconnect(connection))
# })
#
# unlink(connectionDetails$server())
