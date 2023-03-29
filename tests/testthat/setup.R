library(testthat)
library(FeatureExtraction)
library(dplyr)

# Unit Test Settings ------
# Set a directory for the JDBC drivers used in the tests
oldJarFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
tempJdbcDriverFolder <- tempfile("jdbcDrivers")
dir.create(tempJdbcDriverFolder, recursive = TRUE)
Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = tempJdbcDriverFolder)

withr::defer({
  unlink(Sys.getenv("DATABASECONNECTOR_JAR_FOLDER"), recursive = TRUE, force = TRUE)
  Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = oldJarFolder)
}, testthat::teardown_env())


# Get all environment variables to determine which DBMS to use for testing
runTestsOnPostgreSQL <- !(Sys.getenv("CDM5_POSTGRESQL_USER") == "" & Sys.getenv("CDM5_POSTGRESQL_PASSWORD") == "" & Sys.getenv("CDM5_POSTGRESQL_SERVER") == "" & Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA") == "" & Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA") == "")
runTestsOnSQLServer <- !(Sys.getenv("CDM5_SQL_SERVER_USER") == "" & Sys.getenv("CDM5_SQL_SERVER_PASSWORD") == "" & Sys.getenv("CDM5_SQL_SERVER_SERVER") == "" & Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA") == "" & Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA") == "")
runTestsOnOracle <- !(Sys.getenv("CDM5_ORACLE_USER") == "" & Sys.getenv("CDM5_ORACLE_PASSWORD") == "" & Sys.getenv("CDM5_ORACLE_SERVER") == "" & Sys.getenv("CDM5_ORACLE_CDM_SCHEMA") == "" & Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA") == "")
runTestsOnImpala <- !(Sys.getenv("CDM5_IMPALA_USER") == "" & Sys.getenv("CDM5_IMPALA_PASSWORD") == "" & Sys.getenv("CDM5_IMPALA_SERVER") == "" & Sys.getenv("CDM5_IMPALA_CDM_SCHEMA") == "" & Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA") == "")
runTestsOnRedshift <- !(Sys.getenv("CDM5_REDSHIFT_USER") == "" & Sys.getenv("CDM5_REDSHIFT_PASSWORD") == "" & Sys.getenv("CDM5_REDSHIFT_SERVER") == "" & Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA") == "" & Sys.getenv("CDM5_REDSHIFT_OHDSI_SCHEMA") == "")
runTestsOnEunomia <- TRUE

# The cohort table is a temp table but uses the same platform/datetime suffix to avoid collisions when running
# tests in parallel
tableSuffix <- paste0(substr(.Platform$OS.type, 1, 3), format(Sys.time(), "%y%m%d%H%M%S"), sample(1:100, 1))
cohortTable <- paste0("#fe", tableSuffix)
cohortAttributeTable <- paste0("c_attr_", tableSuffix)
attributeDefinitionTable <- paste0("attr_def_", tableSuffix)

# Helper functions ------------
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

dropUnitTestData <- function(connection, ohdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable) {
  sql <- loadRenderTranslateUnitTestSql(sqlFileName = "dropTestingData.sql",
                                        targetDialect = connection@dbms,
                                        tempEmulationSchema = ohdsiDatabaseSchema,
                                        attribute_definition_table = attributeDefinitionTable,
                                        cohort_attribute_table = cohortAttributeTable, 
                                        cohort_database_schema = ohdsiDatabaseSchema,
                                        cohort_table = cohortTable)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
}

# Database Test Settings -----------
# postgres
if (runTestsOnPostgreSQL) {
  DatabaseConnector::downloadJdbcDrivers("postgresql")  
  pgConnectionDetails <- createConnectionDetails(dbms = "postgresql",
                                                 user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                                 server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
  pgCdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
  pgOhdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
  #pgConnection <- createUnitTestData(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# sql server
if (runTestsOnSQLServer) {
  DatabaseConnector::downloadJdbcDrivers("sql server")
  sqlServerConnectionDetails <- createConnectionDetails(dbms = "sql server",
                                                        user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                                        password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                                        server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
  sqlServerCdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
  sqlServerOhdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
  #sqlServerConnection <- createUnitTestData(sqlServerConnectionDetails, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# oracle
if (runTestsOnOracle) {
  DatabaseConnector::downloadJdbcDrivers("oracle")  
  oracleConnectionDetails <- createConnectionDetails(dbms = "oracle",
                                                     user = Sys.getenv("CDM5_ORACLE_USER"),
                                                     password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                                     server = Sys.getenv("CDM5_ORACLE_SERVER"))
  oracleCdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
  oracleOhdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
  #oracleConnection <- createUnitTestData(oracleConnectionDetails, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# impala
if (runTestsOnImpala) {
  # NOTE: Driver for IMPALA requires manual installation
  impalaConnectionDetails <- createConnectionDetails(dbms = "impala",
                                                     user = Sys.getenv("CDM5_IMPALA_USER"),
                                                     password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                                     server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                                     pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
  impalaCdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
  impalaOhdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
  #impalaConnection <- createUnitTestData(impalaConnectionDetails, impalaCdmDatabaseSchema, impalaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
}

# redshift
if (runTestsOnRedshift) {
  DatabaseConnector::downloadJdbcDrivers("redshift")  
  redshiftConnectionDetails <- createConnectionDetails(dbms = "redshift",
                                                       user = Sys.getenv("CDM5_REDSHIFT_USER"),
                                                       password = URLdecode(Sys.getenv("CDM5_REDSHIFT_PASSWORD")),
                                                       server = Sys.getenv("CDM5_REDSHIFT_SERVER"))
  redshiftCdmDatabaseSchema <- Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA")
  redshiftOhdsiDatabaseSchema <- Sys.getenv("CDM5_REDSHIFT_OHDSI_SCHEMA")
  #redshiftConnection <- createUnitTestData(redshiftConnectionDetails, redshiftCdmDatabaseSchema, redshiftOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
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
  withr::defer(
    {
      dropUnitTestData(eunomiaConnectionDetails, eunomiaConnection, eunomiaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
      unlink("testEunomia.sqlite", recursive = TRUE, force = TRUE)  
    },
    testthat::teardown_env()
  )  
}