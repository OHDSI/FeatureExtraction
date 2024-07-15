library(testthat)
options(dbms = "snowflake")
runTestsOnSnowflake <- !(Sys.getenv("CDM_SNOWFLAKE_CONNECTION_STRING") == "" & Sys.getenv("CDM_SNOWFLAKE_USER") == "" & Sys.getenv("CDM_SNOWFLAKE_PASSWORD") == "" & Sys.getenv("CDM_SNOWFLAKE_CDM53_SCHEMA") == "" & Sys.getenv("CDM_SNOWFLAKE_OHDSI_SCHEMA") == "")
if (runTestsOnSnowflake) {
  test_check("FeatureExtraction")
}
