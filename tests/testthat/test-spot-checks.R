library(testthat)
library(Andromeda)

runSpotChecks <- function(connection, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable) {
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
  suppressWarnings(covariateData <- getDbCovariateData(
    connection = connection,
    cdmDatabaseSchema = cdmDatabaseSchema,
    oracleTempSchema = ohdsiDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTable = cohortTable,
    cohortTableIsTemp = TRUE,
    cohortIds = c(1124300),
    rowIdField = "subject_id",
    covariateSettings = settings
  ))
  suppressWarnings(covariateDataAgg <- getDbCovariateData(
    connection = connection,
    cdmDatabaseSchema = cdmDatabaseSchema,
    oracleTempSchema = ohdsiDatabaseSchema,
    cohortDatabaseSchema = ohdsiDatabaseSchema,
    cohortTable = cohortTable,
    cohortTableIsTemp = TRUE,
    cohortIds = c(1124300),
    rowIdField = "subject_id",
    covariateSettings = settings,
    aggregated = TRUE
  ))
  if (covariateData$covariates %>% count() %>% pull() == 0) {
    return(TRUE)
  }

  # Test analysis 1: gender
  sql <- "SELECT subject_id, gender_concept_id FROM @cohortTable INNER JOIN @cdmDatabaseSchema.person ON subject_id = person_id WHERE cohort_definition_id = 1124300"
  sql <- SqlRender::render(sql,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable
  )
  sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
  results <- as_tibble(DatabaseConnector::querySql(connection, sql))
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId * 1000 + 1
  results$covariateValue <- 1
  results <- results[order(results$rowId), ]

  covariateIds <- covariateData$covariateRef %>%
    filter(.data$analysisId == 1) %>%
    select("covariateId")
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(local(rlang::sym("rowId"))) %>%
    collect()

  expect_equivalent(results, results2)

  # Test analysis 2: age
  sql <- "SELECT subject_id, YEAR(cohort_start_date) - year_of_birth AS age FROM @cohortTable INNER JOIN @cdmDatabaseSchema.person ON subject_id = person_id WHERE cohort_definition_id = 1124300"
  sql <- SqlRender::render(sql,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable
  )
  sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
  results <- as_tibble(DatabaseConnector::querySql(connection, sql))
  colnames(results) <- c("rowId", "covariateValue")
  results$covariateId <- 1000 + 2
  results <- results[, c("rowId", "covariateId", "covariateValue")]
  results <- results[order(results$rowId), ]

  covariateIds <- covariateData$covariateRef %>%
    filter(.data$analysisId == 2) %>%
    select("covariateId")
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(local(rlang::sym("rowId"))) %>%
    collect()

  expect_equivalent(results, results2)


  # Test analysis 102: condition occurrence long term
  sql <- "SELECT DISTINCT subject_id, condition_concept_id FROM @cohortTable INNER JOIN @cdmDatabaseSchema.condition_occurrence ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND condition_concept_id != 0 AND condition_start_date <= cohort_start_date AND condition_start_date >= DATEADD(DAY, -365, cohort_start_date)"
  sql <- SqlRender::render(sql,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable
  )
  sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId * 1000 + 102
  results$covariateValue <- 1
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL

  covariateIds <- covariateData$covariateRef %>%
    filter(.data$analysisId == 102) %>%
    select("covariateId")
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(local(rlang::sym("rowId")), local(rlang::sym("covariateId"))) %>%
    collect()

  expect_equivalent(results, results2)


  # Test analysis 404: drug era short term (excluding NSAIDS)
  sql <- "SELECT DISTINCT subject_id, drug_concept_id FROM @cohortTable INNER JOIN @cdmDatabaseSchema.drug_era ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND drug_concept_id != 0 AND drug_era_start_date <= cohort_start_date AND drug_era_end_date >= DATEADD(DAY, -30, cohort_start_date) AND drug_concept_id NOT IN (SELECT descendant_concept_id FROM @cdmDatabaseSchema.concept_ancestor WHERE ancestor_concept_id = 21603933)"
  sql <- SqlRender::render(sql,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable
  )
  sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId * 1000 + 404
  results$covariateValue <- 1
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL

  covariateIds <- covariateData$covariateRef %>%
    filter(.data$analysisId == 404) %>%
    select("covariateId")
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(local(rlang::sym("rowId")), local(rlang::sym("covariateId"))) %>%
    collect()

  expect_equivalent(results, results2)

  # Test analysis 923: visit concept count (long term)
  sql <- "SELECT subject_id, visit_concept_id, COUNT(*) AS visit_count FROM @cohortTable INNER JOIN @cdmDatabaseSchema.visit_occurrence ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND visit_start_date <= cohort_start_date AND visit_start_date >= DATEADD(DAY, -365, cohort_start_date) AND visit_concept_id != 0 GROUP BY subject_id, visit_concept_id"
  sql <- SqlRender::render(sql,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable
  )
  sql <- SqlRender::translate(sql, targetDialect = attr(connection, "dbms"))
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId", "covariateValue")
  results$covariateId <- results$covariateId * 1000 + 923
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL

  covariateIds <- covariateData$covariateRef %>%
    filter(.data$analysisId == 923) %>%
    select("covariateId")
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(local(rlang::sym("rowId")), local(rlang::sym("covariateId"))) %>%
    collect()

  expect_equivalent(results, results2)

  # Aggregated
  results$count <- 1
  aggCount <- aggregate(count ~ covariateId, results, sum)
  aggCount <- aggCount[order(aggCount$covariateId), ]
  aggMax <- aggregate(covariateValue ~ covariateId, results, max)
  aggMax <- aggMax[order(aggMax$covariateId), ]

  covariateIds <- covariateDataAgg$covariateRef %>%
    filter(.data$analysisId == 923) %>%
    select("covariateId")
  results3 <- covariateDataAgg$covariatesContinuous %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(local(rlang::sym("covariateId"))) %>%
    collect()

  expect_equal(aggCount$covariateId, results3$covariateId)
  expect_equal(aggCount$count, results3$countValue)

  expect_equal(aggMax$covariateId, results3$covariateId)
  expect_equal(aggMax$covariateValue, results3$maxValue)
}

test_that("Run spot-checks at per-person level on PostgreSQL", {
  skip_if_not(dbms == "postgresql")
  pgConnection <- createUnitTestData(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
  on.exit(dropUnitTestData(pgConnection, pgOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable))
  runSpotChecks(pgConnection, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortTable)
})

test_that("Run spot-checks at per-person level on SQL Server", {
  skip_if_not(dbms == "sql server")
  sqlServerConnection <- createUnitTestData(sqlServerConnectionDetails, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
  on.exit(dropUnitTestData(sqlServerConnection, sqlServerOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable))
  runSpotChecks(sqlServerConnection, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortTable)
})

test_that("Run spot-checks at per-person level on Oracle", {
  skip_if_not(dbms == "oracle")
  oracleConnection <- createUnitTestData(oracleConnectionDetails, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
  on.exit(dropUnitTestData(oracleConnection, oracleOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable))
  runSpotChecks(oracleConnection, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortTable)
})

test_that("Run spot-checks at per-person level on Redshift", {
  skip_if_not(dbms == "redshift")
  redshiftConnection <- createUnitTestData(redshiftConnectionDetails, redshiftCdmDatabaseSchema, redshiftOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
  on.exit(dropUnitTestData(redshiftConnection, redshiftOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable))
  runSpotChecks(redshiftConnection, redshiftCdmDatabaseSchema, redshiftOhdsiDatabaseSchema, cohortTable)
})

test_that("Run spot-checks at per-person level on Eunomia", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  runSpotChecks(eunomiaConnection, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortTable)
})
