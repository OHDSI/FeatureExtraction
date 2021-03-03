library(FeatureExtraction)

test_that("Test stdDiff computation", {
  # Data stored in "resources/continuousCovariateData.rds" created by:
  # connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  # Eunomia::createCohorts(connectionDetails)
  # data <- FeatureExtraction::getDbCovariateData(connectionDetails = connectionDetails,
  #                                               cdmDatabaseSchema = "main",
  #                                               cohortTable = "cohort",
  #                                               aggregated = TRUE,
  #                                               covariateSettings = FeatureExtraction::createCovariateSettings(useCharlsonIndex = TRUE))
  # FeatureExtraction::saveCovariateData(data, "resources/continuousCovariateData.rds")
  
  
  data <- loadCovariateData("resources/continuousCovariateData.rds")
  output <- computeStandardizedDifference(covariateData1 = data,
                                          covariateData2 = data,
                                          cohortId1 = 1,
                                          cohortId2 = 2)
  expect_equal(round(output$stdDiff, 3), -0.407)
})

test_that("Test sd computation", {
  # Data stored in "resources/binaryCovariateData.rds" created by:
  # connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  # Eunomia::createCohorts(connectionDetails)
  # data <- FeatureExtraction::getDbCovariateData(connectionDetails = connectionDetails,
  #                                               cdmDatabaseSchema = "main",
  #                                               cohortTable = "cohort",
  #                                               aggregated = TRUE,
  #                                               covariateSettings = FeatureExtraction::createCovariateSettings(useConditionOccurrenceLongTerm = TRUE))
  # FeatureExtraction::saveCovariateData(data, "resources/binaryCovariateData.rds")
  
  
  data <- loadCovariateData("resources/binaryCovariateData.rds")
  output <- computeStandardizedDifference(covariateData1 = data,
                                          covariateData2 = data,
                                          cohortId1 = 1,
                                          cohortId2 = 2)
  # Filter to: condition_occurrence during day -365 through 0 days relative to index: Diverticular disease
  singleCovariate <- output[output$covariateId == 4266809102,]
  expect_equal(round(singleCovariate$mean1, 3), 0.185)
  expect_equal(round(singleCovariate$sd1, 3), 0.388)
  expect_equal(round(singleCovariate$mean2, 3), 0.075)
  expect_equal(round(singleCovariate$sd2, 3), 0.264)
  expect_equal(round(singleCovariate$stdDiff, 3), -0.330)
})

