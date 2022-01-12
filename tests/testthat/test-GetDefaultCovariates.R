# This file covers the code in GetDefaultCovariates.R. View coverage for this file using
#library(testthat); library(FeatureExtraction)
#covr::file_report(covr::file_coverage("R/GetDefaultCovariates.R", "tests/testthat/test-GetDefaultCovariates.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()

test_that("Test exit conditions", {
  connection <- DatabaseConnector::connect(connectionDetails)

  # covariateSettings object type
  expect_error(getDbDefaultCovariateData(connection = connection,
                                         cdmDatabaseSchema = "main",
                                         covariateSettings = list(),
                                         targetDatabaseSchema = "main",
                                         targetTables = list(covariates = "cov",
                                                             covariateRef = "cov_ref",
                                                             analysisRef = "cov_analysis_ref")))
  # CDM 4 not supported
  expect_error(getDbDefaultCovariateData(connection = connection,
                                         cdmDatabaseSchema = "main",
                                         cdmVersion = "4",
                                         covariateSettings = createDefaultCovariateSettings(),
                                         targetDatabaseSchema = "main",
                                         targetTables = list(covariates = "cov",
                                                             covariateRef = "cov_ref",
                                                             analysisRef = "cov_analysis_ref")))
  on.exit(DatabaseConnector::disconnect(connection))
})

test_that("Test target table", {
  connection <- DatabaseConnector::connect(connectionDetails)
  Eunomia::createCohorts(connectionDetails)

  results <- getDbDefaultCovariateData(connection = connection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       targetDatabaseSchema = "main",
                                       targetTables = list(covariates = "ut_cov",
                                                           covariateRef = "ut_cov_ref",
                                                           analysisRef = "ut_cov_analysis_ref"))

  expect_gt(DatabaseConnector::renderTranslateQuerySql(connection, "SELECT COUNT(*) FROM main.ut_cov")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(connection, "SELECT COUNT(*) FROM main.ut_cov_ref")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(connection, "SELECT COUNT(*) FROM main.ut_cov_analysis_ref")[1], 1)

  results <- getDbDefaultCovariateData(connection = connection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       targetDatabaseSchema = "main",
                                       aggregated = TRUE,
                                       targetTables = list(covariates = "ut_cov_agg",
                                                           covariateRef = "ut_cov_ref_agg",
                                                           analysisRef = "ut_cov_analysis_ref_agg"))

  expect_gt(DatabaseConnector::renderTranslateQuerySql(connection, "SELECT COUNT(*) FROM main.ut_cov_agg")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(connection, "SELECT COUNT(*) FROM main.ut_cov_ref_agg")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(connection, "SELECT COUNT(*) FROM main.ut_cov_analysis_ref_agg")[1], 1)

  DatabaseConnector::disconnect(connection)
})

unlink(connectionDetails$server())