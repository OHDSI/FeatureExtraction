# This file covers the code in GetDefaultCovariates.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetDefaultCovariates.R", "tests/testthat/test-GetDefaultCovariates.R"))

test_that("Test exit conditions", {
  skip_if_not(dbms == "sqlite")
  
  # covariateSettings object type
  expect_error(getDbDefaultCovariateData(connection = eunomiaConnection,
                                         cdmDatabaseSchema = "main",
                                         covariateSettings = list(),
                                         targetDatabaseSchema = "main",
                                         targetTables = list(covariates = "cov",
                                                             covariateRef = "cov_ref",
                                                             analysisRef = "cov_analysis_ref")))
  # CDM 4 not supported
  expect_error(getDbDefaultCovariateData(connection = eunomiaConnection,
                                         cdmDatabaseSchema = "main",
                                         cdmVersion = "4",
                                         covariateSettings = createDefaultCovariateSettings(),
                                         targetDatabaseSchema = "main",
                                         targetTables = list(covariates = "cov",
                                                             covariateRef = "cov_ref",
                                                             analysisRef = "cov_analysis_ref")))
})

test_that("Test target table", {
  skip_if_not(dbms == "sqlite")

  results <- getDbDefaultCovariateData(connection = eunomiaConnection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       targetDatabaseSchema = "main",
                                       targetTables = list(covariates = "ut_cov",
                                                           covariateRef = "ut_cov_ref",
                                                           analysisRef = "ut_cov_analysis_ref"))

  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM main.ut_cov")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM main.ut_cov_ref")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(connection, "SELECT COUNT(*) FROM main.ut_cov_analysis_ref")[1], 1)

  results <- getDbDefaultCovariateData(connection = eunomiaConnection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       targetDatabaseSchema = "main",
                                       aggregated = TRUE,
                                       targetTables = list(covariates = "ut_cov_agg",
                                                           covariateRef = "ut_cov_ref_agg",
                                                           analysisRef = "ut_cov_analysis_ref_agg"))

  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM main.ut_cov_agg")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM main.ut_cov_ref_agg")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM main.ut_cov_analysis_ref_agg")[1], 1)

  # Temp tables with old prototype
  results <- getDbDefaultCovariateData(connection = eunomiaConnection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       aggregated = TRUE,
                                       targetCovariateTable = "#ut_cov_agg",
                                       targetAnalysisRefTable = "#ut_cov_ref_agg",
                                       targetCovariateRefTable = "#ut_cov_anal_ref_agg")

  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_agg")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_ref_agg")[1], 1)
  expect_gt(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_anal_ref_agg")[1], 1)

  results <- getDbDefaultCovariateData(connection = eunomiaConnection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       targetCovariateTable = "#ut_cov",
                                       targetAnalysisRefTable = "#ut_cov_ref",
                                       targetCovariateRefTable = "#ut_cov_analysis_ref")

  covCt <- DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov")[1]
  expect_gt(covCt, 1)
  covRefCt <- DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_ref")[1]
  expect_gt(covRefCt, 1)
  anlRefCt <- DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_analysis_ref")[1]
  expect_gt(anlRefCt, 1)

  # append results rather than deleting the tables
  results <- getDbDefaultCovariateData(connection = eunomiaConnection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       createTable = FALSE,
                                       dropTableIfExists = FALSE,
                                       targetCovariateTable = "#ut_cov",
                                       targetAnalysisRefTable = "#ut_cov_ref",
                                       targetCovariateRefTable = "#ut_cov_analysis_ref")

  expect_equal(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov")[1], covCt * 2)
  expect_equal(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_ref")[1], covRefCt * 2)
  expect_equal(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_analysis_ref")[1], anlRefCt * 2)

  # Recreate tables (and check create override works)
  results <- getDbDefaultCovariateData(connection = eunomiaConnection,
                                       cdmDatabaseSchema = "main",
                                       cohortTable = "cohort",
                                       covariateSettings = createDefaultCovariateSettings(),
                                       createTable = FALSE,
                                       dropTableIfExists = TRUE,
                                       targetCovariateTable = "#ut_cov",
                                       targetAnalysisRefTable = "#ut_cov_ref",
                                       targetCovariateRefTable = "#ut_cov_analysis_ref")

  expect_equal(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov")[1], covCt)
  expect_equal(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_ref")[1], covRefCt)
  expect_equal(DatabaseConnector::renderTranslateQuerySql(eunomiaConnection, "SELECT COUNT(*) FROM #ut_cov_analysis_ref")[1], anlRefCt)
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
