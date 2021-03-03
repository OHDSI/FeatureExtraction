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
  
  
  data <- FeatureExtraction::loadCovariateData("resources/continuousCovariateData.rds")
  output <- computeStandardizedDifference(covariateData1 = data,
                                          covariateData2 = data,
                                          cohortId1 = 1,
                                          cohortId2 = 2)
  expect_equal(round(output$stdDiff, 3), -0.407)
})