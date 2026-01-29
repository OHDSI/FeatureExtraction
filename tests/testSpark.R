library(testthat)
options(dbms = "spark")
runTestsOnSpark <- !(Sys.getenv("CDM5_SPARK_CONNECTION_STRING") == "" & Sys.getenv("CDM5_SPARK_USER") == "" & Sys.getenv("CDM_SPARK_PASSWORD") == "" & Sys.getenv("CDM5_SPARK_CDM_SCHEMA") == "" & Sys.getenv("CDM5_SPARK_OHDSI_SCHEMA") == "")
if (runTestsOnSpark) {
  test_check("FeatureExtraction")
}
