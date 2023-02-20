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
  dropCohortsTable(sqlServerConnectionDetails, sqlServerOhdsiDatabaseSchema, cohortsTable)
}

# oracle
if (runTestsOnOracle) {
  dropCohortsTable(oracleConnectionDetails, oracleOhdsiDatabaseSchema, cohortsTable)
}

# impala
if (runTestsOnImpala) {
  dropCohortsTable(impalaConnectionDetails, impalaOhdsiDatabaseSchema, cohortsTable)
}

# eunomia
if (runTestsOnEunomia) {
  dropCohortsTable(eunomiaConnectionDetails, eunomiaOhdsiDatabaseSchema, cohortsTable)
}