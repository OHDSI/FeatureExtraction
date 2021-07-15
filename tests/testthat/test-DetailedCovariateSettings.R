# This file covers the code in DetailedCovariateData.R. View coverage for this file using
library(testthat); library(FeatureExtraction)


test_that("test createDetailedCovariateSettings", {
  analysisDetails <- createAnalysisDetails(analysisId = 1,
                                           sqlFileName = "DemographicsGender.sql",
                                           parameters = list(analysisId = 1,
                                                             analysisName = "Gender",
                                                             domainId = "Demographics"),
                                           includedCovariateConceptIds = c(),
                                           addDescendantsToInclude = FALSE,
                                           excludedCovariateConceptIds = c(),
                                           addDescendantsToExclude = FALSE,
                                           includedCovariateIds = c())
  
  settings <- createDetailedCovariateSettings(list(analysisDetails))
  temporalSettings <- createDetailedTemporalCovariateSettings(list(analysisDetails))
  expect_s3_class(settings, "covariateSettings")
  expect_s3_class(temporalSettings, "covariateSettings")
  expect_equal(temporalSettings$temporalStartDays, -365:-1)
})

test_that("test createDetailedTemporalCovariateSettings",{
  analysisDetails <- createAnalysisDetails(analysisId = 1,
                                           sqlFileName = "DemographicsGender.sql",
                                           parameters = list(analysisId = 1,
                                                             analysisName = "Gender",
                                                             domainId = "Demographics"),
                                           includedCovariateConceptIds = c(),
                                           addDescendantsToInclude = FALSE,
                                           excludedCovariateConceptIds = c(),
                                           addDescendantsToExclude = FALSE,
                                           includedCovariateIds = c())
  
  temporalSettings <- createDetailedTemporalCovariateSettings(list(analysisDetails))
  expect_s3_class(temporalSettings, "covariateSettings")
  expect_equal(temporalSettings$temporalStartDays, -365:-1)
  
})


test_that("test convertPrespecSettingsToDetailedSettings", {
  settings <- createCovariateSettings(useDemographicsAgeGroup = TRUE, useChads2Vasc = TRUE)
  convertedSettings <- convertPrespecSettingsToDetailedSettings(settings)
  expect_s3_class(convertedSettings, "covariateSettings")
  expect_equal(names(convertedSettings), c("temporal", "analyses"))
  expect_equal(convertedSettings$analyses[[1]]$sqlFileName, "DemographicsAgeGroup.sql")
})

test_that("test createDefaultCovariateSettings", {
  settings <- createDefaultCovariateSettings()
  expect_s3_class(settings, "covariateSettings")
})

test_that("test createDefaultTemporalCovariateSettings", {
  settings <- createDefaultTemporalCovariateSettings()
  expect_s3_class(settings, "covariateSettings")
})
