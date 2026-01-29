# This file covers the code in Aggregation.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/Aggregation.R", "tests/testthat/test-Aggregation.R"))

test_that("aggregateCovariates works", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  settings <- createCovariateSettings(useDemographicsAgeGroup = TRUE, useChads2Vasc = TRUE)
  covariateData <- getDbCovariateData(
    connectionDetails = eunomiaConnectionDetails,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = settings,
    aggregated = FALSE
  )

  aggregatedCovariateData <- aggregateCovariates(covariateData)
  expect_true(isAggregatedCovariateData(aggregatedCovariateData))
  expect_error(aggregateCovariates("blah"), "not of class CovariateData")
  expect_error(aggregateCovariates(aggregatedCovariateData), "already be aggregated")

  # create example where missing does not mean zero
  covariateData$analysisRef <- covariateData$analysisRef %>%
    mutate(missingMeansZero = ifelse(.data$analysisName == "Chads2Vasc", "N", .data$missingMeansZero))
  expect_true(isAggregatedCovariateData(aggregateCovariates(covariateData)))

  Andromeda::close(covariateData)
  expect_error(aggregateCovariates(covariateData), "object is closed")
})

test_that("aggregateCovariates handles temporalCovariates", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  settings <- createTemporalCovariateSettings(useDemographicsGender = TRUE)
  covariateData <- getDbCovariateData(
    connectionDetails = eunomiaConnectionDetails,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = settings
  )
  expect_error(aggregateCovariates(covariateData), "temporal covariates")
})
