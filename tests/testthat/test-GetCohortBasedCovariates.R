# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariates.R", "tests/testthat/test-GetCohortBasedCovariates.R"))
library(testthat)

if (runTestsOnEunomia) {
  connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  connection <- DatabaseConnector::connect(connectionDetails)
  
  cohort <- data.frame(cohortDefinitionId = c(1, 1, 101, 101),
                       cohortStartDate = as.Date(c("2000-02-01", "2000-01-01", "2000-01-01", "2000-01-02")),
                       cohortEndDate = as.Date(c("2000-02-14", "2000-01-14", "2000-01-01", "2000-01-02")),
                       subjectId = c(1, 2, 1, 1))
  DatabaseConnector::insertTable(connection = connection,
                                 databaseSchema = "main",
                                 tableName = "cohort",
                                 data = cohort,
                                 dropTableIfExists = TRUE,
                                 createTable = TRUE,
                                 progressBar = FALSE,
                                 camelCaseToSnakeCase = TRUE)
}

covariateCohorts <- data.frame(cohortId = c(101, 102),
                               cohortName = c("Foo", "Bar"))

test_that("Cohort-based covariates: binary, non-aggregated", {
  skip_if_not(runTestsOnEunomia)
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "binary")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = NULL,
                             cdmDatabaseSchema = "main",
                             cohortTable = "cohort",
                             cohortId = 1,
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = FALSE)
  covariates <- dplyr::collect(covs$covariates)
  expectedCovariates <- data.frame(rowId = 1,
                                   covariateId = 101999,
                                   covariateValue = 1)
  expect_equivalent(covariates, expectedCovariates)
})

test_that("Cohort-based covariates: binary, aggregated", {
  skip_if_not(runTestsOnEunomia)
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "binary")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = NULL,
                             cdmDatabaseSchema = "main",
                             cohortTable = "cohort",
                             cohortId = 1,
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = TRUE)
  covariates <- dplyr::collect(covs$covariates)
  expectedCovariates <- data.frame(cohortDefinitionId  = 1,
                                   covariateId = 101999,
                                   sumValue  = 1,
                                   averageValue = 0.5)
  expect_equivalent(covariates, expectedCovariates)
})

test_that("Cohort-based covariates: binary, non-aggregated, temporal", {
  skip_if_not(runTestsOnEunomia)
  settings <- createCohortBasedTemporalCovariateSettings(analysisId = 999,
                                                         covariateCohorts = covariateCohorts)
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = NULL,
                             cdmDatabaseSchema = "main",
                             cohortTable = "cohort",
                             cohortId = 1,
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = FALSE)
  covariates <- dplyr::collect(covs$covariates)
  expectedCovariates <- data.frame(rowId = c(1, 1),
                                   covariateId = c(101999, 101999),
                                   covariateValue = c(1,1),
                                   timeId = c(335,336))
  expect_equivalent(covariates, expectedCovariates)
})

test_that("Cohort-based covariates: binary, aggregated, temporal", {
  skip_if_not(runTestsOnEunomia)
  settings <- createCohortBasedTemporalCovariateSettings(analysisId = 999,
                                                         covariateCohorts = covariateCohorts)
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = NULL,
                             cdmDatabaseSchema = "main",
                             cohortTable = "cohort",
                             cohortId = 1,
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = TRUE)
  covariates <- dplyr::collect(covs$covariates)
  expectedCovariates <- data.frame(cohortDefinitionId = c(1, 1),
                                   covariateId = c(101999, 101999),
                                   timeId = c(335,336),
                                   sumValue  = c(1,1),
                                   averageValue = c(0.5, 0.5))
  expect_equivalent(covariates, expectedCovariates)
})

test_that("Cohort-based covariates: counts, non-aggregated", {
  skip_if_not(runTestsOnEunomia)
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "count")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = NULL,
                             cdmDatabaseSchema = "main",
                             cohortTable = "cohort",
                             cohortId = 1,
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = FALSE)
  covariates <- dplyr::collect(covs$covariates)
  expectedCovariates <- data.frame(rowId = 1,
                                   covariateId = 101999,
                                   covariateValue = 2)
  expect_equivalent(covariates, expectedCovariates)
})

test_that("Cohort-based covariates: counts, aggregated", {
  skip_if_not(runTestsOnEunomia)
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "count")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = NULL,
                             cdmDatabaseSchema = "main",
                             cohortTable = "cohort",
                             cohortId = 1,
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = TRUE)
  covariatesContinuous <- dplyr::collect(covs$covariatesContinuous)
  expectedCovariates <- data.frame(cohortDefinitionId  = 1,
                                   covariateId = 101999,
                                   countValue  = 1,
                                   minValue = 0,
                                   maxValue = 2,
                                   averageValue = 1)
  expect_equivalent(expectedCovariates[, names(expectedCovariates)], expectedCovariates)
})

if (runTestsOnEunomia) {
  DatabaseConnector::disconnect(connection)
}

test_that("Cohort-based covariates: warning if using pre-defined analysis ID", {
  expect_warning(createCohortBasedCovariateSettings(analysisId = 1,
                                                    covariateCohorts = covariateCohorts,
                                                    valueType = "count"),
                 "Analysis ID [0-9+] also used for prespecified analysis")
  expect_warning(createCohortBasedTemporalCovariateSettings(analysisId = 1,
                                                            covariateCohorts = covariateCohorts),
                 "Analysis ID [0-9+] also used for prespecified analysis")
})
