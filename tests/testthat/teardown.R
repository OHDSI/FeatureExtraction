## Drop cohorts tables for various databases

clearCohortsTableAndConnection <- function(connectionDetails, connection, ohdsiDatabaseSchema, cohortsTable) {
  dbms <- connectionDetails$dbms
  # a tmp table on oracle is basically a permanent table, so needs to be removed
  if (dbms == "oracle") {
    if (!DatabaseConnector::dbIsValid(connection)) {
      connection <- DatabaseConnector::connect(connectionDetails)
    }
    sql <- loadRenderTranslateSql(sqlFileName = "DropCohortsOfInterest.sql",
                                  targetDialect = connectionDetails$dbms,
                                  tempEmulationSchema = ohdsiDatabaseSchema,
                                  cohortsTable = cohortsTable)
    DatabaseConnector::executeSql(connection, sql)
    DatabaseConnector::disconnect(connection)
  } else {
    if (DatabaseConnector::dbIsValid(connection)) {
      DatabaseConnector::disconnect(connection) 
    }
  }
}

# postgres
if (runTestsOnPostgreSQL) {
  clearCohortsTableAndConnection(pgConnectionDetails, pgConnection, pgOhdsiDatabaseSchema, cohortsTable)
}

# sql server
if (runTestsOnSQLServer) {
  clearCohortsTableAndConnection(sqlServerConnectionDetails, sqlServerConnection, sqlServerOhdsiDatabaseSchema, cohortsTable)
}

# oracle
if (runTestsOnOracle) {
  clearCohortsTableAndConnection(oracleConnectionDetails, oracleConnection, oracleOhdsiDatabaseSchema, cohortsTable)
}

# impala
if (runTestsOnImpala) {
  clearCohortsTableAndConnection(impalaConnectionDetails, impalaConnection, impalaOhdsiDatabaseSchema, cohortsTable)
}

# eunomia
if (runTestsOnEunomia) {
  clearCohortsTableAndConnection(eunomiaConnectionDetails, eunomiaConnection, eunomiaOhdsiDatabaseSchema, cohortsTable)
}
