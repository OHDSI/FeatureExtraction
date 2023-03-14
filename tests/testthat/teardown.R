## Drop cohorts tables for various databases

dropCohortsTable <- function(connectionDetails, connection, ohdsiDatabaseSchema, cohortsTable) {
  if (!DatabaseConnector::dbIsValid(connection)) {
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  sql <- loadRenderTranslateSql(sqlFileName = "DropCohortsOfInterest.sql",
                                targetDialect = connectionDetails$dbms,
                                tempEmulationSchema = ohdsiDatabaseSchema,
                                cohortsTable = cohortsTable)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
}

# postgres
if (runTestsOnPostgreSQL) {
  dropCohortsTable(pgConnectionDetails, pgConnection, pgOhdsiDatabaseSchema, cohortsTable)
}

# sql server
if (runTestsOnSQLServer) {
  dropCohortsTable(sqlServerConnectionDetails, sqlServerConnection, sqlServerOhdsiDatabaseSchema, cohortsTable)
}

# oracle
if (runTestsOnOracle) {
  dropCohortsTable(oracleConnectionDetails, oracleConnection, oracleOhdsiDatabaseSchema, cohortsTable)
}

# impala
if (runTestsOnImpala) {
  dropCohortsTable(impalaConnectionDetails, impalaConnection, impalaOhdsiDatabaseSchema, cohortsTable)
}

# eunomia
if (runTestsOnEunomia) {
  dropCohortsTable(eunomiaConnectionDetails, eunomiaConnection, eunomiaOhdsiDatabaseSchema, cohortsTable)
}
