# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/CompareCohorts.R", "tests/testthat/test-CompareCohorts.R"))

test_that("Test stdDiff continuous variable computation", {
  # NOTE: Data stored in "inst/testdata/continuousCovariateData.zip" created by:
  # ------------------------------------------------------------------------------
  # connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  # Eunomia::createCohorts(connectionDetails)
  # data <- FeatureExtraction::getDbCovariateData(connectionDetails = connectionDetails,
  #                                               cdmDatabaseSchema = "main",
  #                                               cohortTable = "cohort",
  #                                               aggregated = TRUE,
  #                                               covariateSettings = FeatureExtraction::createCovariateSettings(useCharlsonIndex = TRUE))
  # FeatureExtraction::saveCovariateData(data, "inst/testdata/continuousCovariateData.zip")
  # ------------------------------------------------------------------------------
  data <- loadCovariateData(getTestResourceFilePath("continuousCovariateData.zip"))
  # Compute the expected value based on cohorts 1 & 2's values from
  # the loaded covariate data
  testData <- data.frame(
    mean1 = 0.614,
    sd1 = 0.387,
    mean2 = 0.404,
    sd2 = 0.345
  )

  output <- computeStandardizedDifference(
    covariateData1 = data,
    covariateData2 = data,
    cohortId1 = 1,
    cohortId2 = 2
  )
  testData$sd <- sqrt((testData$sd1^2 + testData$sd2^2) / 2)
  testData$stdDiff <- (testData$mean2 - testData$mean1) / testData$sd

  # Compute the standardized difference of mean using the source data
  expect_equal(output$stdDiff, testData$stdDiff, tolerance = 0.001, scale = 1)
})

test_that("Test stdDiff binary variable computation", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  Eunomia::createCohorts(connectionDetails)
  data <- FeatureExtraction::getDbCovariateData(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = "main",
    cohortTable = "cohort",
    aggregated = TRUE,
    covariateSettings = FeatureExtraction::createCovariateSettings(useConditionOccurrenceLongTerm = TRUE)
  )
  output <- computeStandardizedDifference(
    covariateData1 = data,
    covariateData2 = data,
    cohortId1 = 1,
    cohortId2 = 2
  )
  # Filter to: condition_occurrence during day -365 through 0 days relative to index: Diverticular disease
  singleCovariate <- output[output$covariateId == 4266809102, ]

  # Compute the expected value based on cohorts 1 & 2's values from
  # the loaded covariate data for covariateId == 4266809102
  testBinaryData <- data.frame(
    popSize1 = 1844,
    sumValue1 = 341,
    popSize2 = 850,
    sumValue2 = 64
  )

  testBinaryData$mean1 <- testBinaryData$sumValue1 / testBinaryData$popSize1
  testBinaryData$mean2 <- testBinaryData$sumValue2 / testBinaryData$popSize2
  testBinaryData$sd1 <- sqrt(testBinaryData$mean1 * (1 - testBinaryData$mean1))
  testBinaryData$sd2 <- sqrt(testBinaryData$mean2 * (1 - testBinaryData$mean2))
  testBinaryData$sd <- sqrt((testBinaryData$sd1^2 + testBinaryData$sd2^2) / 2)
  testBinaryData$stdDiff <- (testBinaryData$mean2 - testBinaryData$mean1) / testBinaryData$sd

  # Test the results
  expect_equal(singleCovariate$mean1, testBinaryData$mean1, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$sd1, testBinaryData$sd1, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$mean2, testBinaryData$mean2, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$sd2, testBinaryData$sd2, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$sd, testBinaryData$sd, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$stdDiff, testBinaryData$stdDiff, tolerance = 0.001, scale = 1)
})
