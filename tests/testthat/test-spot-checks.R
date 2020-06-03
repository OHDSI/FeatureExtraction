library(testthat)
library(Andromeda)

runSpotChecks <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- SqlRender::loadRenderTranslateSql("cohortsOfInterest.sql",
                                           packageName = "FeatureExtraction",
                                           dbms = connectionDetails$dbms,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           resultsDatabaseSchema = ohdsiDatabaseSchema)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)

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
  suppressWarnings(covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       oracleTempSchema = ohdsiDatabaseSchema,
                                                       cohortDatabaseSchema = ohdsiDatabaseSchema,
                                                       cohortTable = "cohorts_of_interest",
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings))
  suppressWarnings(covariateDataAgg <- getDbCovariateData(connectionDetails = connectionDetails,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       oracleTempSchema = ohdsiDatabaseSchema,
                                                       cohortDatabaseSchema = ohdsiDatabaseSchema,
                                                       cohortTable = "cohorts_of_interest",
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings,
                                                       aggregated = TRUE))
  if (nrow(covariateData$covariates) == 0)
    return(TRUE)
  
  connection <- DatabaseConnector::connect(connectionDetails)
  
  # Test analysis 1: gender
  sql <- "SELECT subject_id, gender_concept_id FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.person ON subject_id = person_id WHERE cohort_definition_id = 1124300"
  sql <- SqlRender::render(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  results <- as_tibble(DatabaseConnector::querySql(connection, sql))
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId*1000 + 1
  results$covariateValue <- 1
  results <- results[order(results$rowId), ]

  covariateIds <- covariateData$covariateRef %>%
    filter(rlang::sym("analysisId") == 1) %>%
    select(rlang::sym("covariateId"))
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(rlang::sym("rowId")) %>%
    collect()

  expect_equivalent(results, results2)
  
  # Test analysis 2: age
  sql <- "SELECT subject_id, YEAR(cohort_start_date) - year_of_birth AS age FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.person ON subject_id = person_id WHERE cohort_definition_id = 1124300"
  sql <- SqlRender::render(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  results <- as_tibble(DatabaseConnector::querySql(connection, sql))
  colnames(results) <- c("rowId", "covariateValue")
  results$covariateId <- 1000 + 2
  results <- results[, c("rowId", "covariateId", "covariateValue")]
  results <- results[order(results$rowId), ]
  
  covariateIds <- covariateData$covariateRef %>%
    filter(rlang::sym("analysisId") == 2) %>%
    select(rlang::sym("covariateId"))
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(rlang::sym("rowId"))  %>%
    collect()
  
  expect_equivalent(results, results2)
  
  
  # Test analysis 102: condition occurrence long term
  sql <- "SELECT DISTINCT subject_id, condition_concept_id FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.condition_occurrence ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND condition_start_date <= cohort_start_date AND condition_start_date >= DATEADD(DAY, -365, cohort_start_date)"
  sql <- SqlRender::render(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId*1000 + 102
  results$covariateValue <- 1
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL

  covariateIds <- covariateData$covariateRef %>%
    filter(rlang::sym("analysisId") == 102) %>%
    select(rlang::sym("covariateId"))
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(rlang::sym("rowId"), rlang::sym("covariateId"))  %>%
    collect()
  
  expect_equivalent(results, results2)
  
  
  # Test analysis 404: drug era short term (excluding NSAIDS)
  sql <- "SELECT DISTINCT subject_id, drug_concept_id FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.drug_era ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND drug_era_start_date <= cohort_start_date AND drug_era_end_date >= DATEADD(DAY, -30, cohort_start_date) AND drug_concept_id NOT IN (SELECT descendant_concept_id FROM @cdmDatabaseSchema.concept_ancestor WHERE ancestor_concept_id = 21603933)"
  sql <- SqlRender::render(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId*1000 + 404
  results$covariateValue <- 1
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL
  
  covariateIds <- covariateData$covariateRef %>%
    filter(rlang::sym("analysisId") == 404) %>%
    select(rlang::sym("covariateId"))
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(rlang::sym("rowId"), rlang::sym("covariateId"))  %>%
    collect()
  
  expect_equivalent(results, results2)
  
  # Test analysis 923: visit concept count (long term)
  sql <- "SELECT subject_id, visit_concept_id, COUNT(*) AS visit_count FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.visit_occurrence ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND visit_start_date <= cohort_start_date AND visit_start_date >= DATEADD(DAY, -365, cohort_start_date) AND visit_concept_id != 0 GROUP BY subject_id, visit_concept_id"
  sql <- SqlRender::render(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)
  sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId", "covariateValue")
  results$covariateId <- results$covariateId*1000 + 923
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL
  
  covariateIds <- covariateData$covariateRef %>%
    filter(rlang::sym("analysisId") == 923) %>%
    select(rlang::sym("covariateId"))
  results2 <- covariateData$covariates %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(rlang::sym("rowId"), rlang::sym("covariateId"))  %>%
    collect()
  
  expect_equivalent(results, results2)
  
  # Aggregated
  results$count <- 1
  aggCount <- aggregate(count ~ covariateId, results, sum)
  aggCount <- aggCount[order(aggCount$covariateId), ]
  aggMax <- aggregate(covariateValue ~ covariateId, results, max)
  aggMax <- aggMax[order(aggMax$covariateId), ]
  
  covariateIds <- covariateDataAgg$covariateRef %>%
    filter(rlang::sym("analysisId") == 923) %>%
    select(rlang::sym("covariateId"))
  results3 <- covariateDataAgg$covariatesContinuous %>%
    inner_join(covariateIds, by = "covariateId") %>%
    arrange(rlang::sym("covariateId"))  %>%
    collect()
  
  expect_equal(aggCount$covariateId, results3$covariateId)
  expect_equal(aggCount$count, results3$countValue)

  expect_equal(aggMax$covariateId, results3$covariateId)
  expect_equal(aggMax$covariateValue, results3$maxValue)
  
  DatabaseConnector::disconnect(connection)
}

test_that(paste("Run spot-checks at per-person level on ", getOption("dbms")), {
  skip_if_not(getOption("test") == "spotChecks")
  if (getOption("dbms") == "postgresql") {
    connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                                 user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                                 server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
    runSpotChecks(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
  }
  
  if (getOption("dbms") == "sql server") {
    connectionDetails <- createConnectionDetails(dbms = "sql server",
                                                 user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                                 server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
    runSpotChecks(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
  }
  
  if (getOption("dbms") == "oracle") {
    connectionDetails <- createConnectionDetails(dbms = "oracle",
                                                 user = Sys.getenv("CDM5_ORACLE_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                                 server = Sys.getenv("CDM5_ORACLE_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
    runSpotChecks(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
  }


  if (getOption("dbms") == "impala") {
    connectionDetails <- createConnectionDetails(dbms = "impala",
                                                 user = Sys.getenv("CDM5_IMPALA_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                                 server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                                 pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
    runSpotChecks(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
  }
})
