if (Sys.getenv("CDM5_IMPALA_CDM_SCHEMA") != "") {
  library(testthat)
  library(FeatureExtraction)
  options(dbms = "impala")
  options(test = "perPerson")
  test_check("FeatureExtraction")
}