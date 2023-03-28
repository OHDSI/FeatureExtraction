# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/DefaultTemporalSequenceCovariateSettings.R", "tests/testthat/test-GetCovariatesTemporalSequence.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connectionDetails)

test_that("createTemporalSequenceCovariateSettings correctly sets list", {
  settings <- createTemporalSequenceCovariateSettings(useDemographicsGender = T, 
                                                      useConditionEraGroupStart = T, 
                                                      useDrugEraStart = T, 
                                                      timePart = 'month', 
                                                      timeInterval = 1, 
                                                      sequenceEndDay = -1, 
                                                      sequenceStartDay = -365*5)
  
  testthat::expect_equal(settings$temporalSequence, T)
  testthat::expect_equal(settings$temporal, F)
  
  testthat::expect_equal(sum(c("DemographicsGender", "ConditionEraGroupStart", "DrugEraStart")%in%names(settings)),3)
  testthat::expect_equal(sum(c("DemographicsAge", "ConditionEraStart", "DrugEraGroupStart")%in%names(settings)),0)
  
  testthat::expect_equal(settings$timePart, "month")
  testthat::expect_equal(settings$timeInterval, 1)
  
  testthat::expect_equal(settings$sequenceEndDay, -1)
  testthat::expect_equal(settings$sequenceStartDay, -365*5)
  
  testthat::expect_equal(class(settings), "covariateSettings")
})


test_that("createTemporalSequenceCovariateSettings correctly sets function", {
  settings <- createTemporalSequenceCovariateSettings(useDemographicsGender = T, 
                                                      useConditionEraGroupStart = T, 
                                                      useDrugEraStart = T, 
                                                      timePart = 'month', 
                                                      timeInterval = 1, 
                                                      sequenceEndDay = -1, 
                                                      sequenceStartDay = -365*5)
  
  testthat::expect_equal(attr(settings, 'fun'), "getDbDefaultCovariateData")
  
})


# check extraction
test_that("getDbCovariateData works with createTemporalSequenceCovariateSettings", {
  
  covSet <- createTemporalSequenceCovariateSettings(useDemographicsGender = T, 
                                                    useDemographicsAge = T, 
                                                    useDemographicsRace = T,
                                                    useDemographicsEthnicity = T, 
                                                    useDemographicsAgeGroup = T,
                                                      useConditionEraGroupStart = T, 
                                                      useDrugEraStart = T, 
                                                      timePart = 'month', 
                                                      timeInterval = 1, 
                                                      sequenceEndDay = -1, 
                                                      sequenceStartDay = -365*5)
  
  
  connection <- DatabaseConnector::connect(connectionDetails)
  result <- getDbCovariateData(connection = connection,
                               cdmDatabaseSchema = "main",
                               cohortTable = "cohort", 
                               cohortId = 1,
                               covariateSettings = covSet)
  expect_true(is(result, "CovariateData"))
  
  # check timeId is 59 or less
  expect_true(max(collect(result$covariates)$timeId, na.rm = T)<=60)
  
  on.exit(DatabaseConnector::disconnect(connection))
})

# Check backwards compatibility
test_that("Temporal Covariate Settings are backwards compatible", {
  # Temporal covariate settings created previously will not have
  # the temporalSequence property
  covSet <- FeatureExtraction::createDefaultTemporalCovariateSettings()
  covSet$temporalSequence <- NULL 
  
  connection <- DatabaseConnector::connect(connectionDetails)
  result <- getDbCovariateData(connection = connection,
                               cdmDatabaseSchema = "main",
                               cohortTable = "cohort", 
                               cohortId = 1,
                               covariateSettings = covSet)
  expect_true(is(result, "CovariateData"))
  on.exit(DatabaseConnector::disconnect(connection))
})

unlink(connectionDetails$server())
