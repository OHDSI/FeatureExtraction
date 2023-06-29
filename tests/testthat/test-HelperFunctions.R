# This file covers the code in HelperFunctions.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/HelperFunctions.R", "tests/testthat/test-HelperFunctions.R"))

test_that("Test helper functions for non-aggregated covariate data", {
  skip_if_not(runTestsOnEunomia)
  expect_error(filterByRowId("blah", 1), "not of class CovariateData")

  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortId = 1:2,
    covariateSettings = createCovariateSettings(useDemographicsAgeGroup = TRUE, useChads2Vasc = TRUE),
    aggregated = F
  )

  covariateDataFiltered <- filterByRowId(covariateData, rowIds = 1)
  expect_equal(unique(pull(covariateDataFiltered$covariates, rowId)), 1)

  locallyAggregated <- aggregateCovariates(covariateData)
  expect_error(filterByCohortDefinitionId(locallyAggregated, 1), "no such column")

  expect_error(filterByCohortDefinitionId(covariateData, 1), "Can only filter aggregated")

  Andromeda::close(covariateData)
  expect_error(filterByRowId(covariateData, 1), "closed")
})

test_that("Test helper functions for aggregated covariate data", {
  skip_if_not(runTestsOnEunomia)
  expect_error(filterByCohortDefinitionId("blah", 1), "not of class CovariateData")

  aggregatedCovariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortId = 1:2,
    covariateSettings = createCovariateSettings(useDemographicsAgeGroup = TRUE, useChads2Vasc = TRUE),
    aggregated = TRUE
  )

  aggCovariateDataFiltered <- filterByCohortDefinitionId(aggregatedCovariateData, 1)
  expect_equal(unique(pull(aggCovariateDataFiltered$covariates, cohortDefinitionId)), 1)
  expect_error(filterByRowId(aggregatedCovariateData, 1), "Cannot filter aggregated")
  Andromeda::close(aggregatedCovariateData)
  expect_error(filterByCohortDefinitionId(aggregatedCovariateData, 1), "closed")
})
