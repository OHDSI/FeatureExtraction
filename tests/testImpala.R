library(testthat)
options(dbms = "impala")
runTestsOnImpala <- FALSE #!(Sys.getenv("CDM5_IMPALA_USER") == "" & Sys.getenv("CDM5_IMPALA_PASSWORD") == "" & Sys.getenv("CDM5_IMPALA_SERVER") == "" & Sys.getenv("CDM5_IMPALA_CDM_SCHEMA") == "" & Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA") == "")
if (runTestsOnImpala) {
  test_check("FeatureExtraction")
}