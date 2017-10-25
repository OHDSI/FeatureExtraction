library(testthat)

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
  if (nrow(covariateData$covariates) == 0)
    return(TRUE)
  
  connection <- DatabaseConnector::connect(connectionDetails)
  
  # Test analysis 1: gender
  sql <- "SELECT subject_id, gender_concept_id FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.person ON subject_id = person_id WHERE cohort_definition_id = 1124300"
  sql <- SqlRender::renderSql(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId*1000 + 1
  results$covariateValue <- 1
  results <- results[order(results$rowId), ]
  row.names(results) <- NULL
  
  covariateIds <- covariateData$covariateRef$covariateId[covariateData$covariateRef$analysisId == 1]
  results2 <- ff::as.ram(covariateData$covariates[ffbase::`%in%`(covariateData$covariates$covariateId, covariateIds),])
  results2 <- results2[order(results2$rowId), ]
  row.names(results2) <- NULL
  
  expect_equal(results, results2)
  
  
  # Test analysis 2: age
  sql <- "SELECT subject_id, YEAR(cohort_start_date) - year_of_birth AS age FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.person ON subject_id = person_id WHERE cohort_definition_id = 1124300"
  sql <- SqlRender::renderSql(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateValue")
  results$covariateId <- 1000 + 2
  results <- results[, c("rowId", "covariateId", "covariateValue")]
  results <- results[order(results$rowId), ]
  row.names(results) <- NULL
  
  covariateIds <- covariateData$covariateRef$covariateId[covariateData$covariateRef$analysisId == 2]
  results2 <- ff::as.ram(covariateData$covariates[ffbase::`%in%`(covariateData$covariates$covariateId, covariateIds),])
  results2 <- results2[order(results2$rowId), ]
  row.names(results2) <- NULL
  
  expect_equal(results, results2)
  
  
  # Test analysis 102: condition occurrence long term
  sql <- "SELECT DISTINCT subject_id, condition_concept_id FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.condition_occurrence ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND condition_start_date <= cohort_start_date AND condition_start_date >= DATEADD(DAY, -365, cohort_start_date)"
  sql <- SqlRender::renderSql(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId*1000 + 102
  results$covariateValue <- 1
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL
  
  covariateIds <- covariateData$covariateRef$covariateId[covariateData$covariateRef$analysisId == 102]
  results2 <- ff::as.ram(covariateData$covariates[ffbase::`%in%`(covariateData$covariates$covariateId, covariateIds),])
  results2 <- results2[order(results2$rowId, results2$covariateId), ]
  row.names(results2) <- NULL
  
  expect_equal(results, results2)
  
  
  # Test analysis 404: drug era short term (excluding NSAIDS)
  sql <- "SELECT DISTINCT subject_id, drug_concept_id FROM @resultsDatabaseSchema.cohorts_of_interest INNER JOIN @cdmDatabaseSchema.drug_era ON subject_id = person_id WHERE cohort_definition_id = 1124300 AND drug_era_start_date <= cohort_start_date AND drug_era_end_date >= DATEADD(DAY, -30, cohort_start_date) AND drug_concept_id NOT IN (SELECT descendant_concept_id FROM @cdmDatabaseSchema.concept_ancestor WHERE ancestor_concept_id = 21603933)"
  sql <- SqlRender::renderSql(sql ,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = ohdsiDatabaseSchema)$sql
  sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
  results <- DatabaseConnector::querySql(connection, sql)
  colnames(results) <- c("rowId", "covariateId")
  results$covariateId <- results$covariateId*1000 + 404
  results$covariateValue <- 1
  results <- results[order(results$rowId, results$covariateId), ]
  row.names(results) <- NULL
  
  covariateIds <- covariateData$covariateRef$covariateId[covariateData$covariateRef$analysisId == 404]
  results2 <- ff::as.ram(covariateData$covariates[ffbase::`%in%`(covariateData$covariates$covariateId, covariateIds),])
  results2 <- results2[order(results2$rowId, results2$covariateId), ]
  row.names(results2) <- NULL
  
  expect_equal(results, results2)
}

test_that(paste("Run spot-checks at per-person level on ", getOption("dbms")), {
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
})