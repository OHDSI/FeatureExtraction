library(testthat)
options(dbms = "sql server")
runTestsOnSQLServer <- !(Sys.getenv("CDM5_SQL_SERVER_USER") == "" & Sys.getenv("CDM5_SQL_SERVER_PASSWORD") == "" & Sys.getenv("CDM5_SQL_SERVER_SERVER") == "" & Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA") == "" & Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA") == "")
if (runTestsOnSQLServer) {
  test_check("FeatureExtraction")
}