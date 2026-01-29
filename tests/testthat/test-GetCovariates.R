# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariates.R", "tests/testthat/test-GetCovariates.R"))

getCovariateSettings <- function() {
  settings <- createCovariateSettings(
    useDemographicsGender = TRUE,
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
    includedCovariateIds = c()
  )
  return(settings)
}

# insertTempCohortData <- function(connection, dbms) {
#   sql <- "SELECT 1 cohort_definition_id,
#                  1 subject_id,
#                  DATEFROMPARTS(2020,1,1) cohort_start_date,
#                  DATEFROMPARTS(2020,12,31) cohort_end_date
#           INTO #cohort
#           ;"
#   sql <- SqlRender::translate(sql = sql,  targetDialect = dbms)
#   DatabaseConnector::executeSql(connection, sql)
# }

test_that("getDbCovariateData enforces specification of database details", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  # No database details specified
  expect_error(getDbCovariateData(
    connectionDetails = NULL,
    connection = NULL,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    covariateSettings = getCovariateSettings()
  ))

  # Both database connection details and connection provided
  expect_error(getDbCovariateData(
    connectionDetails = eunomiaConnectionDetails,
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    covariateSettings = getCovariateSettings()
  ))

  # Only database connection details provided
  result <- getDbCovariateData(
    connectionDetails = eunomiaConnectionDetails,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    covariateSettings = getCovariateSettings()
  )
})

test_that("getDbCovariateData CDM v4 not supported", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  expect_error(getDbCovariateData(
    connectionDetails = eunomiaConnectionDetails,
    connection = NULL,
    cdmVersion = "4",
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    covariateSettings = getCovariateSettings()
  ))
})

test_that("getDbCovariateData cohortTableIsTemp tests when table name lacks # symbol", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  result <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTableIsTemp = TRUE,
    cohortTable = cohortTable,
    covariateSettings = getCovariateSettings()
  )
  expect_true(is(result, "CovariateData"))
})

test_that("getDbCovariateData cohortTableIsTemp tests when table name contains # symbol", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  result <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTableIsTemp = TRUE,
    cohortTable = cohortTable,
    covariateSettings = getCovariateSettings()
  )
  expect_true(is(result, "CovariateData"))
})

test_that("getDbCovariateData populationSize == 0 tests", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  expect_warning(getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTableIsTemp = FALSE,
    cohortTable = "cohort",
    cohortIds = c(0), # This is a cohort that is not created in Eunomia
    covariateSettings = getCovariateSettings()
  ))
})

test_that("Custom covariate builder", {
  skip_on_cran()
  # TODO: This test is probably good to run on all DB platforms
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  covariateSettings <- createCovariateSettings(
    useDemographicsGender = TRUE,
    useDemographicsAgeGroup = TRUE,
    useDemographicsRace = TRUE,
    useDemographicsEthnicity = TRUE,
    useDemographicsIndexYear = TRUE,
    useDemographicsIndexMonth = TRUE
  )
  looCovSet <- FeatureExtraction:::.createLooCovariateSettings(useLengthOfObs = TRUE)
  covariateSettingsList <- list(covariateSettings, looCovSet)
  covariates <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTable = "cohort",
    cohortIds = c(-1),
    covariateSettings = covariateSettingsList
  )
})

test_that("getDbCovariateData care site from person tests", {
  # TODO: This test is probably good to run on all DB platforms
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  # Add care site IDs to person table
  person <- DatabaseConnector::querySql(eunomiaConnection, "SELECT * FROM main.person;", snakeCaseToCamelCase = TRUE)
  person$careSiteId <- sample.int(4, nrow(person), replace = TRUE)
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    databaseSchema = eunomiaCdmDatabaseSchema,
    tableName = "person",
    data = person,
    dropTableIfExists = TRUE,
    createTable = TRUE,
    camelCaseToSnakeCase = TRUE
  )

  covariateSettings <- createCovariateSettings(useCareSiteId = TRUE)
  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTableIsTemp = FALSE,
    cohortTable = "cohort",
    cohortIds = c(1),
    covariateSettings = covariateSettings
  )
  expect_gt(pull(count(covariateData$covariates)), 0)
  joined <- inner_join(collect(covariateData$covariates), person, by = c("rowId" = "personId"))
  expect_true(all(joined$careSiteId * 1000 + 12 == joined$covariateId))

  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTableIsTemp = FALSE,
    cohortTable = "cohort",
    cohortIds = c(1),
    covariateSettings = covariateSettings,
    aggregated = TRUE
  )
  expect_gt(pull(count(covariateData$covariates)), 0)
})

test_that("getDbCovariateData care site from visit_occurrence tests", {
  # TODO: This test is probably good to run on all DB platforms
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  # Add care site IDs to visit occurrence table
  visitOccurrence <- DatabaseConnector::querySql(eunomiaConnection, "SELECT * FROM main.visit_occurrence;", snakeCaseToCamelCase = TRUE)
  visitOccurrence$careSiteId <- 4 + sample.int(4, nrow(visitOccurrence), replace = TRUE)
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    databaseSchema = "main",
    tableName = "visit_occurrence",
    data = visitOccurrence,
    dropTableIfExists = TRUE,
    createTable = TRUE,
    camelCaseToSnakeCase = TRUE
  )

  # Make sure cohorts overlap with visits
  cohort <- DatabaseConnector::querySql(eunomiaConnection, "SELECT * FROM main.cohort;", snakeCaseToCamelCase = TRUE)
  cohort <- cohort %>%
    inner_join(
      visitOccurrence %>%
        select(
          subjectId = personId,
          visitStartDate
        ),
      by = "subjectId",
      relationship = "many-to-many"
    ) %>%
    mutate(cohortStartDate = visitStartDate, cohortEndDate = visitStartDate) %>%
    select(-visitStartDate) %>%
    filter(!duplicated(subjectId))
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    databaseSchema = "main",
    tableName = "cohort",
    data = cohort,
    dropTableIfExists = TRUE,
    createTable = TRUE,
    camelCaseToSnakeCase = TRUE
  )

  covariateSettings <- createCovariateSettings(useCareSiteId = TRUE)
  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    cohortTableIsTemp = FALSE,
    cohortTable = "cohort",
    cohortIds = c(1, 2),
    covariateSettings = covariateSettings
  )
  expect_equal(
    pull(count(filter(covariateData$covariates, covariateId > 4012))),
    sum(cohort$cohortDefinitionId == 1) + sum(cohort$cohortDefinitionId == 2)
  )
})
