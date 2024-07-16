library(testthat)
library(FeatureExtraction)
library(dplyr)

dbms <- getOption("dbms", default = "sqlite")
message("************* Testing on ", dbms, " *************\n")

# Unit Test Settings ------
# Set a directory for the JDBC drivers used in the tests
oldJarFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
tempJdbcDriverFolder <- tempfile("jdbcDrivers")
dir.create(tempJdbcDriverFolder, recursive = TRUE)
Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = tempJdbcDriverFolder)

withr::defer(
  {
    unlink(Sys.getenv("DATABASECONNECTOR_JAR_FOLDER"), recursive = TRUE, force = TRUE)
    Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = oldJarFolder)
  },
  testthat::teardown_env()
)

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
  sql <- loadRenderTranslateUnitTestSql(
    sqlFileName = "createTestingData.sql",
    targetDialect = connectionDetails$dbms,
    tempEmulationSchema = ohdsiDatabaseSchema,
    attribute_definition_table = attributeDefinitionTable,
    cdm_database_schema = cdmDatabaseSchema,
    cohort_attribute_table = cohortAttributeTable,
    cohort_database_schema = ohdsiDatabaseSchema,
    cohort_definition_ids = cohortDefinitionIds,
    cohort_table = cohortTable
  )
  DatabaseConnector::executeSql(connection, sql)
  return(connection)
}

dropUnitTestData <- function(connection, ohdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable) {
  sql <- loadRenderTranslateUnitTestSql(
    sqlFileName = "dropTestingData.sql",
    targetDialect = connection@dbms,
    tempEmulationSchema = ohdsiDatabaseSchema,
    attribute_definition_table = attributeDefinitionTable,
    cohort_attribute_table = cohortAttributeTable,
    cohort_database_schema = ohdsiDatabaseSchema,
    cohort_table = cohortTable
  )
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
}

checkRemoteFileAvailable <- function(remoteFile) {
  try_GET <- function(x, ...) {
    tryCatch(
      httr::GET(url = x, httr::timeout(1), ...),
      error = function(e) conditionMessage(e),
      warning = function(w) conditionMessage(w)
    )
  }
  is_response <- function(x) {
    class(x) == "response"
  }

  # First check internet connection
  if (!curl::has_internet()) {
    message("No internet connection.")
    return(NULL)
  }
  # Then try for timeout problems
  resp <- try_GET(remoteFile)
  if (!is_response(resp)) {
    message(resp)
    return(NULL)
  }
  # Then stop if status > 400
  if (httr::http_error(resp)) {
    message_for_status(resp)
    return(NULL)
  }
  return("success")
}

# Database Test Settings -----------
# bigquery - To avoid rate limit on BigQuery, only test on 1 OS
if (dbms == "bigquery" && .Platform$OS.type == "windows") {
  DatabaseConnector::downloadJdbcDrivers(dbms)
  bqKeyFile <- tempfile(fileext = ".json")
  writeLines(Sys.getenv("CDM_BIG_QUERY_KEY_FILE"), bqKeyFile)
  if (testthat::is_testing()) {
    withr::defer(unlink(bqKeyFile, force = TRUE), testthat::teardown_env())
  }
  bqConnectionString <- gsub(
    "<keyfile path>",
    normalizePath(bqKeyFile, winslash = "/"),
    Sys.getenv("CDM_BIG_QUERY_CONNECTION_STRING")
  )
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = dbms,
    user = "",
    password = "",
    connectionString = !!bqConnectionString
  )
  cdmDatabaseSchema <- Sys.getenv("CDM_BIG_QUERY_CDM_SCHEMA")
  vocabularyDatabaseSchema <- Sys.getenv("CDM_BIG_QUERY_CDM_SCHEMA")
  cohortDatabaseSchema <- Sys.getenv("CDM_BIG_QUERY_OHDSI_SCHEMA")
  options(sqlRenderTempEmulationSchema = Sys.getenv("CDM_BIG_QUERY_OHDSI_SCHEMA"))
}

# oracle
if (dbms == "oracle") {
  DatabaseConnector::downloadJdbcDrivers(dbms)
  oracleConnectionDetails <- createConnectionDetails(
    dbms = dbms,
    user = Sys.getenv("CDM5_ORACLE_USER"),
    password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
    server = Sys.getenv("CDM5_ORACLE_SERVER")
  )
  oracleCdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
  oracleOhdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
  # Set the tempEmulationSchema globally
  options(sqlRenderTempEmulationSchema = oracleOhdsiDatabaseSchema)
}

# postgres
if (dbms == "postgresql") {
  DatabaseConnector::downloadJdbcDrivers(dbms)
  pgConnectionDetails <- createConnectionDetails(
    dbms = dbms,
    user = Sys.getenv("CDM5_POSTGRESQL_USER"),
    password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
    server = Sys.getenv("CDM5_POSTGRESQL_SERVER")
  )
  pgCdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
  pgOhdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
}

# redshift
if (dbms == "redshift") {
  DatabaseConnector::downloadJdbcDrivers(dbms)
  redshiftConnectionDetails <- createConnectionDetails(
    dbms = dbms,
    user = Sys.getenv("CDM5_REDSHIFT_USER"),
    password = URLdecode(Sys.getenv("CDM5_REDSHIFT_PASSWORD")),
    server = Sys.getenv("CDM5_REDSHIFT_SERVER")
  )
  redshiftCdmDatabaseSchema <- Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA")
  redshiftOhdsiDatabaseSchema <- Sys.getenv("CDM5_REDSHIFT_OHDSI_SCHEMA")
}

# snowflake
if (dbms == "snowflake") {
  DatabaseConnector::downloadJdbcDrivers(dbms)
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = dbms,
    user = Sys.getenv("CDM_SNOWFLAKE_USER"),
    password = URLdecode(Sys.getenv("CDM_SNOWFLAKE_PASSWORD")),
    connectionString = Sys.getenv("CDM_SNOWFLAKE_CONNECTION_STRING")
  )
  cdmDatabaseSchema <- Sys.getenv("CDM_SNOWFLAKE_CDM53_SCHEMA")
  vocabularyDatabaseSchema <- Sys.getenv("CDM_SNOWFLAKE_CDM53_SCHEMA")
  cohortDatabaseSchema <- Sys.getenv("CDM_SNOWFLAKE_OHDSI_SCHEMA")
  options(sqlRenderTempEmulationSchema = Sys.getenv("CDM_SNOWFLAKE_OHDSI_SCHEMA"))
}

# spark
if (dbms == "spark") {
  DatabaseConnector::downloadJdbcDrivers(dbms)
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = dbms,
    user = Sys.getenv("CDM5_SPARK_USER"),
    password = URLdecode(Sys.getenv("CDM5_SPARK_PASSWORD")),
    connectionString = Sys.getenv("CDM5_SPARK_CONNECTION_STRING")
  )
  cdmDatabaseSchema <- Sys.getenv("CDM5_SPARK_CDM_SCHEMA")
  vocabularyDatabaseSchema <- Sys.getenv("CDM5_SPARK_CDM_SCHEMA")
  cohortDatabaseSchema <- Sys.getenv("CDM5_SPARK_OHDSI_SCHEMA")
  options(sqlRenderTempEmulationSchema = Sys.getenv("CDM5_SPARK_OHDSI_SCHEMA"))
}

# sql server
if (dbms == "sql server") {
  DatabaseConnector::downloadJdbcDrivers("sql server")
  sqlServerConnectionDetails <- createConnectionDetails(
    dbms = "sql server",
    user = Sys.getenv("CDM5_SQL_SERVER_USER"),
    password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
    server = Sys.getenv("CDM5_SQL_SERVER_SERVER")
  )
  sqlServerCdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
  sqlServerOhdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
}

# eunomia
if (dbms == "sqlite") {
  if (!is.null(checkRemoteFileAvailable("https://raw.githubusercontent.com/OHDSI/EunomiaDatasets/main/datasets/GiBleed/GiBleed_5.3.zip"))) {
    eunomiaConnectionDetails <- Eunomia::getEunomiaConnectionDetails(databaseFile = "testEunomia.sqlite")
    eunomiaCdmDatabaseSchema <- "main"
    eunomiaOhdsiDatabaseSchema <- "main"
    eunomiaConnection <- createUnitTestData(eunomiaConnectionDetails, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
    Eunomia::createCohorts(
      connectionDetails = eunomiaConnectionDetails,
      cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
      cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
      cohortTable = "cohort"
    )
  }
  withr::defer(
    {
      if (exists("eunomiaConnection")) {
        dropUnitTestData(eunomiaConnection, eunomiaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
        unlink("testEunomia.sqlite", recursive = TRUE, force = TRUE)
      }
    },
    testthat::teardown_env()
  )
}
