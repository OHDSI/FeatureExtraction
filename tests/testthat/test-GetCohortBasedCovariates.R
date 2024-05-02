# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariates.R", "tests/testthat/test-GetCohortBasedCovariates.R"))
library(testthat)


covariateCohorts <- data.frame(
  cohortId = c(101, 102),
  cohortName = c("Foo", "Bar")
)

createCohortBasedCovariateTestData <- function(connection,
                                               databaseSchema,
                                               cohortTableName) {
  cohort <- data.frame(
    cohortDefinitionId = c(1, 1, 101, 101),
    cohortStartDate = as.Date(c("2000-02-01", "2000-01-01", "2000-01-01", "2000-01-02")),
    cohortEndDate = as.Date(c("2000-02-14", "2000-01-14", "2000-01-01", "2000-01-02")),
    subjectId = c(1, 2, 1, 1)
  )
  tempTable <- substr(cohortTableName, 1, 1) == "#"
  if (tempTable) {
    DatabaseConnector::insertTable(
      connection = connection,
      tableName = cohortTableName,
      data = cohort,
      dropTableIfExists = TRUE,
      tempTable = tempTable,
      createTable = TRUE,
      progressBar = FALSE,
      camelCaseToSnakeCase = TRUE
    )
  } else {
    DatabaseConnector::insertTable(
      connection = connection,
      databaseSchema = databaseSchema,
      tableName = cohortTableName,
      data = cohort,
      dropTableIfExists = TRUE,
      tempTable = tempTable,
      createTable = TRUE,
      progressBar = FALSE,
      camelCaseToSnakeCase = TRUE
    )
  }
}

dropCohortBasedCovariateTestData <- function(connection,
                                             databaseSchema,
                                             cohortTableName) {
  # Handle temp table
  if (substr(cohortTableName, 1, 1) == "#") {
    DatabaseConnector::renderTranslateExecuteSql(
      connection = connection,
      sql = "DROP TABLE IF EXISTS @cohort_table;",
      progressBar = FALSE,
      reportOverallTime = FALSE,
      cohort_table = cohortTableName
    )
  } else {
    DatabaseConnector::renderTranslateExecuteSql(
      connection = connection,
      sql = "DROP TABLE IF EXISTS @database_schema.@cohort_table;",
      progressBar = FALSE,
      reportOverallTime = FALSE,
      database_schema = databaseSchema,
      cohort_table = cohortTableName
    )
  }
}

# Database specific tests ---------------
runCohortBasedBinaryNonAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )
  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))
  settings <- createCohortBasedCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts,
    valueType = "binary"
  )

  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTableIsTemp = tempTable,
    cohortTable = cohortTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = FALSE
  )

  covariates <- dplyr::collect(covs$covariates)

  expectedCovariates <- data.frame(
    rowId = 1,
    covariateId = 101999,
    covariateValue = 1
  )
  expect_equivalent(covariates, expectedCovariates)
}

runCohortBasedBinaryAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )
  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))
  settings <- createCohortBasedCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts,
    valueType = "binary"
  )

  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTableIsTemp = tempTable,
    cohortTable = cohortTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = TRUE
  )

  covariates <- dplyr::collect(covs$covariates)

  expectedCovariates <- data.frame(
    cohortDefinitionId = 1,
    covariateId = 101999,
    sumValue = 1,
    averageValue = 0.5
  )
  expect_equivalent(covariates, expectedCovariates)
}

runCohortBasedBinaryNonAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )

  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))

  settings <- createCohortBasedTemporalCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts
  )
  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTableIsTemp = tempTable,
    cohortTable = cohortTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = FALSE
  )

  covariates <- dplyr::collect(covs$covariates)
  covariates <- dplyr::arrange(covariates, timeId)

  expectedCovariates <- data.frame(
    rowId = c(1, 1),
    covariateId = c(101999, 101999),
    covariateValue = c(1, 1),
    timeId = c(335, 336)
  )
  expect_equivalent(covariates, expectedCovariates)
}

runCohortBasedBinaryAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )

  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))

  settings <- createCohortBasedTemporalCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts
  )
  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTableIsTemp = tempTable,
    cohortTable = cohortTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = TRUE
  )

  covariates <- dplyr::collect(covs$covariates)
  covariates <- dplyr::arrange(covariates, timeId)

  expectedCovariates <- data.frame(
    cohortDefinitionId = c(1, 1),
    covariateId = c(101999, 101999),
    timeId = c(335, 336),
    sumValue = c(1, 1),
    averageValue = c(0.5, 0.5)
  )
  expect_equivalent(covariates, expectedCovariates)
}

runCohortBasedCountsNonAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )

  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))

  settings <- createCohortBasedCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts,
    valueType = "count"
  )

  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTable = cohortTable,
    cohortTableIsTemp = tempTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = FALSE
  )

  covariates <- dplyr::collect(covs$covariates)

  expectedCovariates <- data.frame(
    rowId = 1,
    covariateId = 101999,
    covariateValue = 2
  )
  expect_equivalent(covariates, expectedCovariates)
}

runCohortBasedCountsAggTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )

  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))

  settings <- createCohortBasedCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts,
    valueType = "count"
  )

  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTableIsTemp = tempTable,
    cohortTable = cohortTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = TRUE
  )

  covariatesContinuous <- dplyr::collect(covs$covariatesContinuous)

  expectedCovariates <- data.frame(
    cohortDefinitionId = 1,
    covariateId = 101999,
    countValue = 1,
    minValue = 0,
    maxValue = 2,
    averageValue = 1
  )
  expect_equivalent(covariatesContinuous[, names(expectedCovariates)], expectedCovariates)
}

runCohortBasedCountsNonAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )

  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))

  settings <- createCohortBasedTemporalCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts,
    valueType = "count"
  )
  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTableIsTemp = tempTable,
    cohortTable = cohortTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = FALSE
  )

  covariates <- dplyr::collect(covs$covariates)
  covariates <- dplyr::arrange(covariates, timeId)

  expectedCovariates <- data.frame(
    rowId = c(1, 1),
    covariateId = c(101999, 101999),
    covariateValue = c(1, 1),
    timeId = c(335, 336)
  )
  expect_equivalent(covariates, expectedCovariates)
}

runCohortBasedCountsAggTemporalTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )

  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))

  settings <- createCohortBasedTemporalCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts,
    valueType = "count"
  )
  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTable = cohortTable,
    cohortTableIsTemp = tempTable,
    cohortIds = c(1),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = TRUE
  )

  covariatesContinuous <- dplyr::collect(covs$covariatesContinuous)
  covariatesContinuous <- dplyr::arrange(covariatesContinuous, timeId)

  expectedCovariates <- data.frame(
    cohortDefinitionId = 1,
    covariateId = 101999,
    countValue = 1,
    minValue = 0,
    maxValue = 1,
    averageValue = c(0.5, 0.5),
    timeId = c(335, 336)
  )
  expect_equivalent(covariatesContinuous[, names(expectedCovariates)], expectedCovariates)
}

runCohortBasedCountsAggMultiCohortTest <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
  createCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  )

  on.exit(dropCohortBasedCovariateTestData(
    connection = connection,
    databaseSchema = ohdsiDatabaseSchema,
    cohortTableName = cohortTable
  ))

  settings <- createCohortBasedCovariateSettings(
    analysisId = 999,
    covariateCohorts = covariateCohorts,
    valueType = "count"
  )

  tempTable <- substr(cohortTable, 1, 1) == "#"
  covs <- getDbCovariateData(
    connection = connection,
    oracleTempSchema = getOption("sqlRenderTempEmulationSchema"),
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTableIsTemp = tempTable,
    cohortTable = cohortTable,
    cohortIds = c(1, 101),
    cdmVersion = "5",
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = TRUE
  )
  covariatesContinuous <- dplyr::collect(covs$covariatesContinuous)
  covariatesContinuous <- dplyr::arrange(covariatesContinuous, cohortDefinitionId)
  expectedCovariates <- data.frame(
    cohortDefinitionId = c(1, 101),
    covariateId = c(101999, 101999),
    countValue = c(1, 2),
    minValue = c(0, 1),
    maxValue = c(2, 2),
    averageValue = c(1, 1.5)
  )
  expect_equivalent(covariatesContinuous[, names(expectedCovariates)], expectedCovariates)
}

# Eunomia tests ------------
test_that("Cohort-based covariates: binary, non-aggregated on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedBinaryNonAggTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: binary, aggregated on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedBinaryAggTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: binary, non-aggregated, temporal on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedBinaryNonAggTemporalTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: binary, aggregated, temporal on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedBinaryAggTemporalTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: counts, non-aggregated on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedCountsNonAggTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: counts, aggregated on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedCountsAggTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: counts, non-aggregated, temporal on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedCountsNonAggTemporalTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: counts, aggregated, temporal on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedCountsAggTemporalTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

test_that("Cohort-based covariates: counts, aggregated, using multiple cohort IDs on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runCohortBasedCountsAggMultiCohortTest(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    ohdsiDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortTable = "cohort_cov"
  )
})

# Postgres tests ------------
test_that("Cohort-based covariates: binary, non-aggregated on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, non-aggregated, temporal on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated, temporal on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated, temporal on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, temporal on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, using multiple cohort IDs on Postgres", {
  skip_if_not(dbms == "postgresql")
  connection <- DatabaseConnector::connect(pgConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggMultiCohortTest(
    connection = connection,
    cdmDatabaseSchema = pgCdmDatabaseSchema,
    ohdsiDatabaseSchema = pgOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

# SQL Server tests ------------
test_that("Cohort-based covariates: binary, non-aggregated on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, non-aggregated, temporal on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated, temporal on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated, temporal on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, temporal on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, using multiple cohort IDs on SQL Server", {
  skip_if_not(dbms == "sql server")
  connection <- DatabaseConnector::connect(sqlServerConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggMultiCohortTest(
    connection = connection,
    cdmDatabaseSchema = sqlServerCdmDatabaseSchema,
    ohdsiDatabaseSchema = sqlServerOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

# Oracle tests ------------
test_that("Cohort-based covariates: binary, non-aggregated on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, non-aggregated, temporal on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated, temporal on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated, temporal on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, temporal on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, using multiple cohort IDs on Oracle", {
  skip_if_not(dbms == "oracle")
  connection <- DatabaseConnector::connect(oracleConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggMultiCohortTest(
    connection = connection,
    cdmDatabaseSchema = oracleCdmDatabaseSchema,
    ohdsiDatabaseSchema = oracleOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

# RedShift tests ------------
test_that("Cohort-based covariates: binary, non-aggregated on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, non-aggregated, temporal on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: binary, aggregated, temporal on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedBinaryAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, non-aggregated, temporal on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsNonAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, temporal on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggTemporalTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})

test_that("Cohort-based covariates: counts, aggregated, using multiple cohort IDs on RedShift", {
  skip_if_not(dbms == "redshift")
  connection <- DatabaseConnector::connect(redshiftConnectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  runCohortBasedCountsAggMultiCohortTest(
    connection = connection,
    cdmDatabaseSchema = redshiftCdmDatabaseSchema,
    ohdsiDatabaseSchema = redshiftOhdsiDatabaseSchema,
    cohortTable = cohortTable
  )
})


# Non-database specific tests ---------------
test_that("Cohort-based covariates: warning if using pre-defined analysis ID", {
  expect_warning(
    createCohortBasedCovariateSettings(
      analysisId = 1,
      covariateCohorts = covariateCohorts,
      valueType = "count"
    ),
    "Analysis ID [0-9+] also used for prespecified analysis"
  )
  expect_warning(
    createCohortBasedTemporalCovariateSettings(
      analysisId = 1,
      covariateCohorts = covariateCohorts
    ),
    "Analysis ID [0-9+] also used for prespecified analysis"
  )
})
