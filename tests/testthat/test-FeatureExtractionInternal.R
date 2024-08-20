# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/FeatureExtraction.R", "tests/testthat/test-FeatureExtractionInternal.R"))

test_that("Test .onLoad()", {
  skip_on_cran()
  expect_silent(
    FeatureExtraction:::.onLoad(libname = "FeatureExtraction", pkgname = "FeatureExtraction")
  )
})

test_that("Test JSON functions", {
  skip_on_cran()
  expectedToJsonResult <- "{\"id\":\"1\"}"
  expectedFromJsonResult <- list("id" = "1")
  toJsonResult <- FeatureExtraction:::.toJson(expectedFromJsonResult)
  expect_equal(toJsonResult, expectedToJsonResult)

  fromJsonResult <- FeatureExtraction:::.fromJson(expectedToJsonResult)
  expect_equal(fromJsonResult, expectedFromJsonResult)
})
