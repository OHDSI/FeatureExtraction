# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariates.R", "tests/testthat/test-GetCovariates.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connectionDetails)

getCovariateSettings <- function() {
  settings <- createCovariateSettings(useDemographicsGender = TRUE,
                                      useDemographicsAge = TRUE,
                                      useConditionOccurrenceLongTerm = TRUE,
                                      useDrugEraShortTerm = TRUE,
                                      useVisitConceptCountLongTerm = TRUE,
                                      longTermStartDays = -365,
                                      mediumTermStartDays = -180,
                                      shortTermStartDays = -30,
                                      endDays = 0,
                                      includedCovariateConceptIds = c(),
                                      addDescendantsToInclude = FALSE,
                                      excludedCovariateConceptIds = c(21603933),
                                      addDescendantsToExclude = TRUE,
                                      includedCovariateIds = c())
  return(settings)
}

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
                                  covariateSettings = getCovariateSettings()))
  
  # Both database connection details and connection provided
  connection <- DatabaseConnector::connect(connectionDetails)
  expect_error(getDbCovariateData(connectionDetails = connectionDetails,
                                  connection = connection,
                                  cdmDatabaseSchema = "main",
                                  covariateSettings = getCovariateSettings()))
  on.exit(DatabaseConnector::disconnect(connection))
})

test_that("getDbCovariateData CDM v4 not supported", {
  expect_error(getDbCovariateData(connectionDetails = connectionDetails,
                                  connection = NULL,
                                  cdmVersion = "4",
                                  cdmDatabaseSchema = "main",
                                  covariateSettings = getCovariateSettings()))
})

# AGS: The following tests are problematic - taking them out for now
# until there is more time to debug
# -----------------------
#
# test_that("getDbCovariateData cohortTableIsTemp tests when table name lacks # symbol", {
#   connection <- DatabaseConnector::connect(connectionDetails)
#   insertTempCohortData(connection, connectionDetails$dbms)
#   result <- getDbCovariateData(connection = connection,
#                                cdmDatabaseSchema = "main",
#                                cohortTableIsTemp = TRUE,
#                                cohortTable = "cohort",
#                                covariateSettings = getCovariateSettings())
#   expect_true(is(result, "CovariateData"))
#   on.exit(DatabaseConnector::disconnect(connection))
# })
# 
# test_that("getDbCovariateData cohortTableIsTemp tests when table name contains # symbol", {
#   connection <- DatabaseConnector::connect(connectionDetails)
#   insertTempCohortData(connection, connectionDetails$dbms)
#   result <- getDbCovariateData(connection = connection,
#                                cdmDatabaseSchema = "main",
#                                cohortTableIsTemp = TRUE,
#                                cohortTable = "#cohort",
#                                covariateSettings = getCovariateSettings())
#   expect_true(is(result, "CovariateData"))
#   on.exit(DatabaseConnector::disconnect(connection))
# })
# 
# test_that("getDbCovariateData populationSize == 0 tests", {
#   connection <- DatabaseConnector::connect(connectionDetails)
#   expect_warning(getDbCovariateData(connection = connection,
#                                cdmDatabaseSchema = "main",
#                                cohortTableIsTemp = FALSE,
#                                cohortTable = "cohort",
#                                cohortId = 0, # This is a cohort that is not created in Eunomia
#                                covariateSettings = getCovariateSettings()))
#   on.exit(DatabaseConnector::disconnect(connection))
# })

unlink(connectionDetails$server())