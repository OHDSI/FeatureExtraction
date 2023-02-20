# Download the JDBC drivers used in the tests

oldJarFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = tempfile("jdbcDrivers"))
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
loadRenderTranslateSql <- function(sqlFileName, targetDialect, tempEmulationSchema = NULL, ...) {
  sql <- SqlRender::readSql(system.file("sql/sql_server/", sqlFileName, package = "FeatureExtraction"))
  sql <- SqlRender::render(sql = sql, ...)
  sql <- SqlRender::translate(sql = sql, targetDialect = targetDialect, tempEmulationSchema = tempEmulationSchema)
  return(sql)
}

# Get all environment variables to determine which DBMS to use for testing
# AGS: Turning off Oracle database-level testing for now
runTestsOnPostgreSQL <- !(Sys.getenv("CDM5_POSTGRESQL_USER") == "" & Sys.getenv("CDM5_POSTGRESQL_PASSWORD") == "" & Sys.getenv("CDM5_POSTGRESQL_SERVER") == "" & Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA") == "" & Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA") == "")
runTestsOnSQLServer <- FALSE #!(Sys.getenv("CDM5_SQL_SERVER_USER") == "" & Sys.getenv("CDM5_SQL_SERVER_PASSWORD") == "" & Sys.getenv("CDM5_SQL_SERVER_SERVER") == "" & Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA") == "" & Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA") == "")
runTestsOnOracle <- FALSE #!(Sys.getenv("CDM5_ORACLE_USER") == "" & Sys.getenv("CDM5_ORACLE_PASSWORD") == "" & Sys.getenv("CDM5_ORACLE_SERVER") == "" & Sys.getenv("CDM5_ORACLE_CDM_SCHEMA") == "" & Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA") == "")
runTestsOnImpala <- FALSE #!(Sys.getenv("CDM5_IMPALA_USER") == "" & Sys.getenv("CDM5_IMPALA_PASSWORD") == "" & Sys.getenv("CDM5_IMPALA_SERVER") == "" & Sys.getenv("CDM5_IMPALA_CDM_SCHEMA") == "" & Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA") == "")
runTestsOnEunomia <- TRUE

# Get a cohorts table name that is unique per OS to avoid errors in running parallel tests
getCohortsTableName <- function() {
  sysName <- as.character(Sys.info()["sysname"])
  return(paste(sysName, "cohorts_of_interest", sep = "_"))
}

# create cohorts table based on given params
createCohortsTable <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- loadRenderTranslateSql(sqlFileName = "cohortsOfInterest.sql",
                                targetDialect = connectionDetails$dbms,
                                tempEmulationSchema = ohdsiDatabaseSchema,
                                cdmDatabaseSchema = cdmDatabaseSchema,
                                resultsDatabaseSchema = ohdsiDatabaseSchema,
                                cohortsTable = cohortsTable)
  DatabaseConnector::executeSql(connection, sql)
  return(connection)
}

## create cohorts table for different databases
cohortsTable <- getCohortsTableName()

# postgres
if (runTestsOnPostgreSQL) {
  pgConnectionDetails <- createConnectionDetails(dbms = "postgresql",
                                               user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                               password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                               server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
  pgCdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
  pgOhdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
  createCohortsTable(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortsTable)
}

# sql server
if (runTestsOnSQLServer) {
  connectionDetails <- createConnectionDetails(dbms = "sql server",
                                               user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                               password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                               server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
  cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
  ohdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
  createCohortsTable(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable)
}

# oracle
if (runTestsOnOracle) {
  connectionDetails <- createConnectionDetails(dbms = "oracle",
                                               user = Sys.getenv("CDM5_ORACLE_USER"),
                                               password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                               server = Sys.getenv("CDM5_ORACLE_SERVER"))
  cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
  ohdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
  createCohortsTable(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable)
}

# impala
if (runTestsOnImpala) {
  connectionDetails <- createConnectionDetails(dbms = "impala",
                                               user = Sys.getenv("CDM5_IMPALA_USER"),
                                               password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                               server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                               pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
  cdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
  ohdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
  createCohortsTable(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable)
}

# eunomia
if (runTestsOnEunomia) {
  eunomiaConnectionDetails <- Eunomia::getEunomiaConnectionDetails()
  eunomiaCdmDatabaseSchema <- "main"
  eunomiaOhdsiDatabaseSchema <- "main"
  print("create cohorts of interest eunomia!")
  eunomiaConnection <- createCohortsTable(eunomiaConnectionDetails, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortsTable)
}