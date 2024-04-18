library(testthat)
options(dbms = "oracle")
runTestsOnOracle <- FALSE #!(Sys.getenv("CDM5_ORACLE_USER") == "" & Sys.getenv("CDM5_ORACLE_PASSWORD") == "" & Sys.getenv("CDM5_ORACLE_SERVER") == "" & Sys.getenv("CDM5_ORACLE_CDM_SCHEMA") == "" & Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA") == "")
if (runTestsOnOracle) {
  test_check("FeatureExtraction")
}