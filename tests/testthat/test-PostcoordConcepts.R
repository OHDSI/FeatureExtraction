library(testthat)
library(FeatureExtraction)
library(dplyr)

test_that("Postcoordinated concepts on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  # eunomiaConnection <- DatabaseConnector::connect(Eunomia::getEunomiaConnectionDetails())
  cohort <- data.frame(
    cohortDefinitionId = c(1, 1, 1, 1),
    cohortStartDate = as.Date(c("2000-02-01", "2000-08-01", "2000-02-01", "2000-01-02")),
    cohortEndDate = as.Date(c("2000-02-14", "2000-09-14", "2000-02-01", "2000-01-02")),
    subjectId = c(1, 2, 3, 4)
  )
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = "#pcc_cohort",
    data = cohort,
    dropTableIfExists = TRUE,
    tempTable = TRUE,
    createTable = TRUE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )
  measurement <- data.frame(
    measurementId = c(0, 0, 0, 0),
    measurementTypeConceptId = c(0, 0, 0, 0),
    personId = c(1, 1, 3, 4),
    measurementConceptId = c(3000963, 3000963, 3000963, 3000963),
    valueAsConceptId = c(4083207, 4084765, 4084765, 4084765),
    measurementDate = as.Date(c("2000-01-14", "2000-01-01", "2000-01-14", "2000-01-01"))
  )
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = "measurement",
    databaseSchema = "main",
    data = measurement,
    dropTableIfExists = FALSE,
    tempTable = FALSE,
    createTable = FALSE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )
  settings <- createCovariateSettings(
    useMeasurementValueAsConceptShortTerm = TRUE,
    shortTermStartDays = -30
  )

  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    cohortTable = "#pcc_cohort",
    cohortTableIsTemp = TRUE,
    covariateSettings = settings
  )
  covariates <- covariateData$covariates %>%
    collect() %>%
    arrange(rowId)
  expect_equal(covariates$rowId, c(1, 3, 4))
  expect_equal(covariates$covariateId, c(583329995308716, 583329563103716, 583329563103716))
  expect_equal(covariates$covariateValue, c(1, 1, 1))

  covariateRef <- covariateData$covariateRef %>%
    collect() %>%
    arrange(covariateId)
  expect_equal(covariateRef$covariateId, c(583329563103716, 583329995308716))
  expect_equal(covariateRef$conceptId, c(3000963, 3000963))
  expect_equal(covariateRef$valueAsConceptId, c(4084765, 4083207))

  analysisRef <- covariateData$analysisRef %>%
    collect()
  expect_equal(analysisRef$analysisId, 716)

  # Introduce collisions
  measurement <- data.frame(
    measurementId = c(0, 0, 0, 0),
    measurementTypeConceptId = c(0, 0, 0, 0),
    personId = c(1, 1, 3, 4),
    measurementConceptId = c(3048564, 3048564, 40483078, 40483078),
    valueAsConceptId = c(4069590, 4069590, 4069590, 4069590),
    measurementDate = as.Date(c("2000-01-14", "2000-01-01", "2000-01-14", "2000-01-01"))
  )
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = "measurement",
    databaseSchema = "main",
    data = measurement,
    dropTableIfExists = FALSE,
    tempTable = FALSE,
    createTable = FALSE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )
  settings <- createCovariateSettings(
    useMeasurementValueAsConceptShortTerm = TRUE,
    shortTermStartDays = -30
  )

  expect_warning(
    {
      covariateData <- getDbCovariateData(
        connection = eunomiaConnection,
        cdmDatabaseSchema = "main",
        cohortTable = "#pcc_cohort",
        cohortTableIsTemp = TRUE,
        covariateSettings = settings
      )
    },
    "Collisions"
  )
})
