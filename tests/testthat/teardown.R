# ## Drop cohorts tables for various databases
# 
# dropUnitTestData <- function(connectionDetails, connection, ohdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable) {
#   dbms <- connectionDetails$dbms
#   # a tmp table on oracle is basically a permanent table, so needs to be removed
#   if (dbms == "oracle") {
#     if (!DatabaseConnector::dbIsValid(connection)) {
#       connection <- DatabaseConnector::connect(connectionDetails)
#     }
#     sql <- loadRenderTranslateUnitTestSql(sqlFileName = "dropTestingData.sql",
#                                           targetDialect = connectionDetails$dbms,
#                                           tempEmulationSchema = ohdsiDatabaseSchema,
#                                           attribute_definition_table = attributeDefinitionTable,
#                                           cohort_attribute_table = cohortAttributeTable, 
#                                           cohort_database_schema = ohdsiDatabaseSchema,
#                                           cohort_table = cohortTable)
#     DatabaseConnector::executeSql(connection, sql)
#     DatabaseConnector::disconnect(connection)
#   } else {
#     if (DatabaseConnector::dbIsValid(connection)) {
#       DatabaseConnector::disconnect(connection) 
#     }
#   }
# }
# 
# # postgres
# if (runTestsOnPostgreSQL) {
#   dropUnitTestData(pgConnectionDetails, pgConnection, pgOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
# }
# 
# # sql server
# if (runTestsOnSQLServer) {
#   dropUnitTestData(sqlServerConnectionDetails, sqlServerConnection, sqlServerOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
# }
# 
# # oracle
# if (runTestsOnOracle) {
#   dropUnitTestData(oracleConnectionDetails, oracleConnection, oracleOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
# }
# 
# # impala
# if (runTestsOnImpala) {
#   dropUnitTestData(impalaConnectionDetails, impalaConnection, impalaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
# }
# 
# # redshift
# if (runTestsOnRedshift) {
#   dropUnitTestData(redshiftConnectionDetails, redshiftConnection, redshiftOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
# }
# 
# # eunomia
# if (runTestsOnEunomia) {
#   dropUnitTestData(eunomiaConnectionDetails, eunomiaConnection, eunomiaOhdsiDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable)
#   unlink("testEunomia.sqlite", recursive = TRUE, force = TRUE)  
# }
