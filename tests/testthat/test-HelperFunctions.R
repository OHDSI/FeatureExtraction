# This file covers the code in HelperFunctions.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/HelperFunctions.R", "tests/testthat/test-HelperFunctions.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connectionDetails)

settings <- createCovariateSettings(useDemographicsAgeGroup = TRUE, useChads2Vasc = TRUE)

aggregatedCovariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                              cdmDatabaseSchema = "main",
                                              cohortDatabaseSchema = "main",
                                              cohortId = 1:2,
                                              covariateSettings = settings,
                                              aggregated = TRUE)

covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                    cdmDatabaseSchema = "main",
                                    cohortDatabaseSchema = "main",
                                    cohortId = 1:2,
                                    covariateSettings = settings,
                                    aggregated = F)


test_that("filterByRowId works", {
  covariateDataFiltered <- filterByRowId(covariateData, rowIds = 1)
  expect_equal(unique(pull(covariateDataFiltered$covariates, rowId)), 1)
})

test_that("filterByCohortDefinitionId works", {
  aggCovariateDataFiltered <- filterByCohortDefinitionId(aggregatedCovariateData, 1)
  expect_equal(unique(pull(aggCovariateDataFiltered$covariates, cohortDefinitionId)), 1)
})

test_that("filterByCohortDefinitionId handles locally aggregated data", {
  locallyAggregated <- aggregateCovariates(covariateData)
  expect_error(filterByCohortDefinitionId(locallyAggregated, 1))
})

test_that("arguments are checked", {
  expect_error(filterByRowId("blah", 1), "not of class CovariateData")
  expect_error(filterByRowId(aggregatedCovariateData, 1), "Cannot filter aggregated")
  
  expect_error(filterByCohortDefinitionId("blah", 1), "not of class CovariateData")
  expect_error(filterByCohortDefinitionId(covariateData, 1), "Can only filter aggregated")
  
  Andromeda::close(covariateData)
  Andromeda::close(aggregatedCovariateData)
  # expect_error(filterByRowId(covariateData, 1), "closed")
  # expect_error(filterByCohortDefinitionId(aggregatedCovariateData, 1), "closed")
})
