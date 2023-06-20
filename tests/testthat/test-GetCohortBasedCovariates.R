# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariates.R", "tests/testthat/test-GetCohortBasedCovariates.R"))
library(testthat)


covariateCohorts <- data.frame(cohortId = c(101, 102),
                               cohortName = c("Foo", "Bar"))

createCohortBasedCovariateTestData <- function(connection,
                                               databaseSchema,
                                               cohortTableName) {
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

# Database specific tests ---------------
runCohortBasedBinaryNonAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)  
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "binary")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
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
}

runCohortBasedBinaryAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)  
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "binary")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
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
}

runCohortBasedBinaryNonAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)  
  
  settings <- createCohortBasedTemporalCovariateSettings(analysisId = 999,
                                                         covariateCohorts = covariateCohorts)
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
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
}

runCohortBasedBinaryAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)
  settings <- createCohortBasedTemporalCovariateSettings(analysisId = 999,
                                                         covariateCohorts = covariateCohorts)
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
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
}

runCohortBasedCountsNonAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)
  
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "count")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
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
}

runCohortBasedCountsAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "count")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
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
}

runCohortBasedCountsNonAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)

  settings <- createCohortBasedTemporalCovariateSettings(analysisId = 999,
                                                         covariateCohorts = covariateCohorts,
                                                         valueType = "count")
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
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
}

runCohortBasedCountsAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)
  settings <- createCohortBasedTemporalCovariateSettings(analysisId = 999,
                                                         covariateCohorts = covariateCohorts,
                                                         valueType = "count")
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
                             cohortId = 1,
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = TRUE)
  covariates <- dplyr::collect(covs$covariatesContinuous)
  expectedCovariates <- data.frame(cohortDefinitionId  = 1,
                                   covariateId = 101999,
                                   countValue  = 1,
                                   minValue = 0,
                                   maxValue = 1,
                                   averageValue = 1,
                                   timeId = c(335,336))
  expect_equivalent(expectedCovariates[, names(expectedCovariates)], expectedCovariates)
}

runCohortBasedCountsAggMultiCohortTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(connection = connection,
                                     databaseSchema = ohdsiDatabaseSchema,
                                     cohortTableName = cohortTable)
  settings <- createCohortBasedCovariateSettings(analysisId = 999,
                                                 covariateCohorts = covariateCohorts,
                                                 valueType = "count")
  
  covs <- getDbCovariateData(connection = connection,
                             oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
                             cdmDatabaseSchema = cdmDatabaseSchema,
                             cohortDatabaseSchema = ohdsiDatabaseSchema,
                             cohortTable = cohortTable,
                             cohortId = c(1, 101),
                             cdmVersion = "5",
                             rowIdField = "subject_id",
                             covariateSettings = settings,
                             aggregated = TRUE)
  covariatesContinuous <- dplyr::collect(covs$covariatesContinuous)
  expectedCovariates <- data.frame(cohortDefinitionId  = c(1, 101),
                                   covariateId = c(101999, 101999),
                                   countValue  = c(1, 2),
                                   minValue = c(0, 1),
                                   maxValue = c(2, 2),
                                   averageValue = c(1, 1.5))
  expect_equivalent(expectedCovariates[, names(expectedCovariates)], expectedCovariates)
}

test_that("Cohort-based covariates: binary, non-aggregated on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedBinaryNonAggTest(connection = eunomiaConnection, 
                                 cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                                 ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                                 cohortTable = "cohort")
})

test_that("Cohort-based covariates: binary, aggregated on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedBinaryAggTest(connection = eunomiaConnection, 
                              cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                              ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                              cohortTable = "cohort")
})

test_that("Cohort-based covariates: binary, non-aggregated, temporal on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedBinaryNonAggTemporalTest(connection = eunomiaConnection, 
                                         cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                                         ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                                         cohortTable = "cohort")
})

test_that("Cohort-based covariates: binary, aggregated, temporal on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedBinaryAggTemporalTest(connection = eunomiaConnection, 
                                      cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                                      ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                                      cohortTable = "cohort")
})

test_that("Cohort-based covariates: counts, non-aggregated on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedCountsNonAggTest(connection = eunomiaConnection, 
                                 cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                                 ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                                 cohortTable = "cohort")
})

test_that("Cohort-based covariates: counts, aggregated on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedCountsAggTest(connection = eunomiaConnection, 
                              cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                              ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                              cohortTable = "cohort")
})

test_that("Cohort-based covariates: counts, non-aggregated, temporal on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedCountsNonAggTemporalTest(connection = eunomiaConnection, 
                                         cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                                         ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                                         cohortTable = "cohort")
})

test_that("Cohort-based covariates: counts, aggregated, temporal", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedCountsAggTemporalTest(connection = eunomiaConnection, 
                                      cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                                      ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                                      cohortTable = "cohort")
})

test_that("Cohort-based covariates: counts, aggregated, using multiple cohort IDs on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  runCohortBasedCountsAggMultiCohortTest(connection = eunomiaConnection, 
                                         cdmDatabaseSchema = eunomiaCdmDatabaseSchema, 
                                         ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                                         cohortTable = "cohort")
})


# Non-database specific tests ---------------
test_that("Cohort-based covariates: warning if using pre-defined analysis ID", {
  expect_warning(createCohortBasedCovariateSettings(analysisId = 1,
                                                    covariateCohorts = covariateCohorts,
                                                    valueType = "count"),
                 "Analysis ID [0-9+] also used for prespecified analysis")
  expect_warning(createCohortBasedTemporalCovariateSettings(analysisId = 1,
                                                            covariateCohorts = covariateCohorts),
                 "Analysis ID [0-9+] also used for prespecified analysis")
})
