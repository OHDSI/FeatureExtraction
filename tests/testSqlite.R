library(testthat)
options(dbms = "sqlite")
runTestsOnEunomia <- TRUE
if (runTestsOnEunomia) {
  test_check("FeatureExtraction")
}
