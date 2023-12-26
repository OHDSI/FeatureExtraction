library(testthat)
options(dbms = "postgresql")
runTestsOnPostgreSQL <- !(Sys.getenv("CDM5_POSTGRESQL_USER") == "" & Sys.getenv("CDM5_POSTGRESQL_PASSWORD") == "" & Sys.getenv("CDM5_POSTGRESQL_SERVER") == "" & Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA") == "" & Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA") == "")
if (runTestsOnPostgreSQL) {
  test_check("FeatureExtraction")
}