library(testthat)
options(dbms = "bigquery")
runTestsOnBigQuery <- !(Sys.getenv("CDM_BIG_QUERY_CONNECTION_STRING") == "" & Sys.getenv("CDM_BIG_QUERY_KEY_FILE") == "" & Sys.getenv("CDM_BIG_QUERY_CDM_SCHEMA") == "" & Sys.getenv("CDM_BIG_QUERY_OHDSI_SCHEMA") == "")
if (runTestsOnBigQuery) {
  test_check("FeatureExtraction")
}
