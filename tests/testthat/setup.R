library(testthat)
library(FeatureExtraction)
library(dplyr)


# Download the JDBC drivers used in the tests
oldJarFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
tempJdbcDriverFolder <- tempfile("jdbcDrivers")
dir.create(tempJdbcDriverFolder, recursive = TRUE)
Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = tempJdbcDriverFolder)
downloadJdbcDrivers("postgresql")
downloadJdbcDrivers("sql server")
downloadJdbcDrivers("oracle")

withr::defer({
  unlink(Sys.getenv("DATABASECONNECTOR_JAR_FOLDER"), recursive = TRUE, force = TRUE)
  Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = oldJarFolder)
}, testthat::teardown_env())

getTestResourceFilePath <- function(fileName) {
  return(system.file("testdata", fileName, package = "FeatureExtraction"))
}

# Use this instead of SqlRender directly to avoid errors when running 
# individual test files
loadRenderTranslateUnitTestSql <- function(sqlFileName, targetDialect, tempEmulationSchema = NULL, ...) {
  sql <- SqlRender::readSql(system.file("sql/sql_server/unit_tests/", sqlFileName, package = "FeatureExtraction"))
  sql <- SqlRender::render(sql = sql, ...)
  sql <- SqlRender::translate(sql = sql, targetDialect = targetDialect, tempEmulationSchema = tempEmulationSchema)
  return(sql)
}

# Get all environment variables to determine which DBMS to use for testing
runTestsOnPostgreSQL <- !(Sys.getenv("CDM5_POSTGRESQL_USER") == "" & Sys.getenv("CDM5_POSTGRESQL_PASSWORD") == "" & Sys.getenv("CDM5_POSTGRESQL_SERVER") == "" & Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA") == "" & Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA") == "")
runTestsOnSQLServer <- !(Sys.getenv("CDM5_SQL_SERVER_USER") == "" & Sys.getenv("CDM5_SQL_SERVER_PASSWORD") == "" & Sys.getenv("CDM5_SQL_SERVER_SERVER") == "" & Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA") == "" & Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA") == "")
runTestsOnOracle <- !(Sys.getenv("CDM5_ORACLE_USER") == "" & Sys.getenv("CDM5_ORACLE_PASSWORD") == "" & Sys.getenv("CDM5_ORACLE_SERVER") == "" & Sys.getenv("CDM5_ORACLE_CDM_SCHEMA") == "" & Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA") == "")
runTestsOnImpala <- !(Sys.getenv("CDM5_IMPALA_USER") == "" & Sys.getenv("CDM5_IMPALA_PASSWORD") == "" & Sys.getenv("CDM5_IMPALA_SERVER") == "" & Sys.getenv("CDM5_IMPALA_CDM_SCHEMA") == "" & Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA") == "")
runTestsOnEunomia <- TRUE

# create unit test data
createUnitTestData <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable, cohortDefinitionIds = c(1)) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- loadRenderTranslateUnitTestSql(sqlFileName = "createTestingData.sql",
                                        targetDialect = connectionDetails$dbms,
                                        tempEmulationSchema = ohdsiDatabaseSchema,
                                        attribute_definition_table = attributeDefinitionTable,
                                        cdm_database_schema = cdmDatabaseSchema,
                                        cohort_attribute_table =  cohortAttributeTable,
                                        cohort_database_schema = ohdsiDatabaseSchema,
                                        cohort_definition_ids = cohortDefinitionIds,
                                        cohort_table = cohortTable)
  DatabaseConnector::executeSql(connection, sql)
  return(connection)
}

## These tables should be a temp table to avoid collisions between different runs
cohortTable <- "#cohorts_of_interest"
cohortAttributeTable <- paste0("c_attr_", gsub("[: -]", "", Sys.time(), perl = TRUE), sample(1:100, 1))
attributeDefinitionTable <- paste0("attr_def_", gsub("[: -]", "", Sys.time(), perl = TRUE), sample(1:100, 1))

# postgres
if (runTestsOnPostgreSQL) {
  pgConnectionDetails <- createConnectionDetails(dbms = "postgresql",
                                                 user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                                 server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
  pgCdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
  pgOhdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
  pgConnection <- createUnitTestData(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# sql server
if (runTestsOnSQLServer) {
  sqlServerConnectionDetails <- createConnectionDetails(dbms = "sql server",
                                                        user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                                        password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                                        server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
  sqlServerCdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
  sqlServerOhdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
  sqlServerConnection <- createUnitTestData(sqlServerConnectionDetails, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# oracle
if (runTestsOnOracle) {
  oracleConnectionDetails <- createConnectionDetails(dbms = "oracle",
                                                     user = Sys.getenv("CDM5_ORACLE_USER"),
                                                     password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                                     server = Sys.getenv("CDM5_ORACLE_SERVER"))
  oracleCdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
  oracleOhdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
  oracleConnection <- createUnitTestData(oracleConnectionDetails, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# impala
if (runTestsOnImpala) {
  impalaConnectionDetails <- createConnectionDetails(dbms = "impala",
                                                     user = Sys.getenv("CDM5_IMPALA_USER"),
                                                     password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                                     server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                                     pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
  impalaCdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
  impalaOhdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
  impalaConnection <- createUnitTestData(impalaConnectionDetails, impalaCdmDatabaseSchema, impalaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# eunomia
if (runTestsOnEunomia) {
  eunomiaConnectionDetails <- Eunomia::getEunomiaConnectionDetails(databaseFile = "testEunomia.sqlite")
  eunomiaCdmDatabaseSchema <- "main"
  eunomiaOhdsiDatabaseSchema <- "main"
  eunomiaCohortAttributeTable <- "cohort_attribute"
  eunomiaAttributeDefinitionTable <- "attribute_definition"
  eunomiaConnection <- createUnitTestData(eunomiaConnectionDetails, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
  Eunomia::createCohorts(connectionDetails = eunomiaConnectionDetails,
                         cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
                         cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
                         cohortTable = "cohort")
}