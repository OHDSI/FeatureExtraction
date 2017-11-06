if (Sys.getenv("CDM5_IMPALA_CDM_SCHEMA") != "") {
  library(testthat)
  library(FeatureExtraction)
  options(dbms = "impala")
  test_check("FeatureExtraction")
}