library(testthat)
options(dbms = "redshift")
runTestsOnRedshift <- FALSE #!(Sys.getenv("CDM5_REDSHIFT_USER") == "" & Sys.getenv("CDM5_REDSHIFT_PASSWORD") == "" & Sys.getenv("CDM5_REDSHIFT_SERVER") == "" & Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA") == "" & Sys.getenv("CDM5_REDSHIFT_OHDSI_SCHEMA") == "")
if (runTestsOnRedshift) {
  test_check("FeatureExtraction")
}