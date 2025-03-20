# This file covers the code in DetailedCovariateData.R. View coverage for this file using
test_that("test createDetailedCovariateSettings", {
  analysisDetails <- createAnalysisDetails(
    analysisId = 1,
    sqlFileName = "DemographicsGender.sql",
    parameters = list(
      analysisId = 1,
      analysisName = "Gender",
      domainId = "Demographics"
    ),
    includedCovariateConceptIds = c(),
    addDescendantsToInclude = FALSE,
    excludedCovariateConceptIds = c(),
    addDescendantsToExclude = FALSE,
    includedCovariateIds = c()
  )

  settings <- createDetailedCovariateSettings(list(analysisDetails))
  temporalSettings <- createDetailedTemporalCovariateSettings(list(analysisDetails))
  expect_s3_class(settings, "covariateSettings")
  expect_s3_class(temporalSettings, "covariateSettings")
  expect_equal(temporalSettings$temporalStartDays, -365:-1)
})

test_that("test createDetailedTemporalCovariateSettings", {
  analysisDetails <- createAnalysisDetails(
    analysisId = 1,
    sqlFileName = "DemographicsGender.sql",
    parameters = list(
      analysisId = 1,
      analysisName = "Gender",
      domainId = "Demographics"
    ),
    includedCovariateConceptIds = c(),
    addDescendantsToInclude = FALSE,
    excludedCovariateConceptIds = c(),
    addDescendantsToExclude = FALSE,
    includedCovariateIds = c()
  )

  temporalSettings <- createDetailedTemporalCovariateSettings(list(analysisDetails))
  expect_s3_class(temporalSettings, "covariateSettings")
  expect_equal(temporalSettings$temporalStartDays, -365:-1)
})

test_that("test convertPrespecSettingsToDetailedSettings", {
  settings <- createCovariateSettings(useDemographicsAgeGroup = TRUE, useChads2Vasc = TRUE)
  convertedSettings <- convertPrespecSettingsToDetailedSettings(settings)
  expect_s3_class(convertedSettings, "covariateSettings")
  expect_equal(names(convertedSettings), c("temporal", "temporalSequence", "temporalAnnual", "analyses"))
  expect_equal(sum(unlist(lapply(1:length(convertedSettings$analyses), function(i) convertedSettings$analyses[[i]]$sqlFileName)) %in% c("DemographicsAgeGroup.sql", "Chads2Vasc.sql")), 2)
})

test_that("test createDefaultCovariateSettings", {
  settings <- createDefaultCovariateSettings()
  expect_s3_class(settings, "covariateSettings")
})

test_that("test createDefaultTemporalCovariateSettings", {
  settings <- createDefaultTemporalCovariateSettings()
  expect_s3_class(settings, "covariateSettings")
})
