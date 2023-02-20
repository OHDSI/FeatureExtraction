## Drop cohorts tables for various databases

dropCohortsTable <- function(connectionDetails, ohdsiDatabaseSchema, cohortsTable) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- loadRenderTranslateSql(sqlFileName = "DropCohortsOfInterest.sql",
                                targetDialect = connectionDetails$dbms,
                                tempEmulationSchema = ohdsiDatabaseSchema,
                                resultsDatabaseSchema = ohdsiDatabaseSchema,
                                cohortsTable = cohortsTable)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
}

# postgres
if (runTestsOnPostgreSQL) {
  dropCohortsTable(pgConnectionDetails, pgOhdsiDatabaseSchema, cohortsTable)
}

# sql server
if (runTestsOnSQLServer) {
  connectionDetails <- createConnectionDetails(dbms = "sql server",
                                               user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                               password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                               server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
  ohdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
  dropCohortsTable(connectionDetails, ohdsiDatabaseSchema, cohortsTable)
}

# oracle
if (runTestsOnOracle) {
  connectionDetails <- createConnectionDetails(dbms = "oracle",
                                               user = Sys.getenv("CDM5_ORACLE_USER"),
                                               password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                               server = Sys.getenv("CDM5_ORACLE_SERVER"))
  ohdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
  dropCohortsTable(connectionDetails, ohdsiDatabaseSchema, cohortsTable)
}

# impala
if (runTestsOnImpala) {
  connectionDetails <- createConnectionDetails(dbms = "impala",
                                               user = Sys.getenv("CDM5_IMPALA_USER"),
                                               password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                               server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                               pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
  ohdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
  dropCohortsTable(connectionDetails, ohdsiDatabaseSchema, cohortsTable)
}

# eunomia
if (runTestsOnEunomia) {
  print("drop cohorts of interest eunomia!")
  dropCohortsTable(eunomiaConnectionDetails, eunomiaOhdsiDatabaseSchema, cohortsTable)
}