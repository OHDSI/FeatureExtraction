# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariates.R", "tests/testthat/test-GetCovariates.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connectionDetails)
covSettings <- createDefaultCovariateSettings()

insertTempCohortData <- function(connection, dbms) {
  sql <- "SELECT 1 cohort_definition_id, 
                 1 subject_id, 
                 DATEFROMPARTS(2020,1,1) cohort_start_date,  
                 DATEFROMPARTS(2020,12,31) cohort_end_date
          INTO #cohort
          ;"
  sql <- SqlRender::translate(sql = sql,  targetDialect = dbms)
  DatabaseConnector::executeSql(connection, sql)
}

test_that("getDbCovariateData enforces specification of database details", {
  # No database details specified
  expect_error(getDbCovariateData(connectionDetails = NULL,
                                  connection = NULL,
                                  cdmDatabaseSchema = "main",
                                  covariateSettings = createDefaultCovariateSettings()))
  
  # Both database connection details and connection provided
  connection <- DatabaseConnector::connect(connectionDetails)
  expect_error(getDbCovariateData(connectionDetails = connectionDetails,
                                  connection = connection,
                                  cdmDatabaseSchema = "main",
                                  covariateSettings = createDefaultCovariateSettings()))
  on.exit(DatabaseConnector::disconnect(connection))
})

test_that("getDbCovariateData CDM v4 not supported", {
  expect_error(getDbCovariateData(connectionDetails = connectionDetails,
                                  connection = NULL,
                                  cdmVersion = "4",
                                  cdmDatabaseSchema = "main",
                                  covariateSettings = createDefaultCovariateSettings()))
})

test_that("getDbCovariateData cohortTableIsTemp tests when table name lacks # symbol", {
  connection <- DatabaseConnector::connect(connectionDetails)
  insertTempCohortData(connection, connectionDetails$dbms)
  result <- getDbCovariateData(connection = connection,
                               cdmDatabaseSchema = "main",
                               cohortTableIsTemp = TRUE,
                               cohortTable = "cohort",
                               covariateSettings = createDefaultCovariateSettings())
  expect_true(is(result, "CovariateData"))
  on.exit(DatabaseConnector::disconnect(connection))
})

test_that("getDbCovariateData cohortTableIsTemp tests when table name contains # symbol", {
  connection <- DatabaseConnector::connect(connectionDetails)
  insertTempCohortData(connection, connectionDetails$dbms)
  result <- getDbCovariateData(connection = connection,
                               cdmDatabaseSchema = "main",
                               cohortTableIsTemp = TRUE,
                               cohortTable = "#cohort",
                               covariateSettings = createDefaultCovariateSettings())
  expect_true(is(result, "CovariateData"))
  on.exit(DatabaseConnector::disconnect(connection))  
})

test_that("getDbCovariateData populationSize == 0 tests", {
  connection <- DatabaseConnector::connect(connectionDetails)
  result <- getDbCovariateData(connection = connection,
                               cdmDatabaseSchema = "main",
                               cohortTableIsTemp = FALSE,
                               cohortTable = "cohort",
                               cohortId = 0, # This is a cohort that is not created in Eunomia
                               covariateSettings = createDefaultCovariateSettings())
  expect_equal(class(result)[1], "CovariateData")
  on.exit(DatabaseConnector::disconnect(connection))
})



unlink(connectionDetails$server())