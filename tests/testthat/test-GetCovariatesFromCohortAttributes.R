# This file covers the code in GetCovariatesFromCohortAttributes.R.
# NOTE: Functionality is described in detail in the following vignette:
# http://ohdsi.github.io/FeatureExtraction/articles/CreatingCovariatesUsingCohortAttributes.html
#
# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariatesFromCohortAttributes.R", "tests/testthat/test-GetCovariatesFromCohortAttributes.R"))

test_that("getDbCohortAttrCovariatesData aggregation not supported check", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  expect_error(getDbCohortAttrCovariatesData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    covariateSettings = createDefaultCovariateSettings(),
    aggregated = TRUE
  ))
})

test_that("getDbCohortAttrCovariatesData CDM v4 not supported check", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  expect_error(getDbCohortAttrCovariatesData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cdmVersion = "4",
    covariateSettings = createDefaultCovariateSettings()
  ))
})

test_that("getDbCohortAttrCovariatesData hasIncludedAttributes == 0", {
  # TODO: This test is probably good to run on all DB platforms
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  covariateSettings <- createCohortAttrCovariateSettings(
    attrDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortAttrTable = cohortAttributeTable,
    attrDefinitionTable = attributeDefinitionTable,
    includeAttrIds = c(),
    isBinary = FALSE,
    missingMeansZero = FALSE
  )
  result <- getDbCohortAttrCovariatesData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTable = cohortTable,
    covariateSettings = covariateSettings
  )
  expect_equal(class(result), "CovariateData")
})

test_that("getDbCohortAttrCovariatesData hasIncludedAttributes > 0", {
  # TODO: This test is probably good to run on all DB platforms
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  covariateSettings <- createCohortAttrCovariateSettings(
    attrDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortAttrTable = cohortAttributeTable,
    attrDefinitionTable = attributeDefinitionTable,
    includeAttrIds = c(1),
    isBinary = FALSE,
    missingMeansZero = TRUE
  )
  result <- getDbCohortAttrCovariatesData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTable = cohortTable,
    covariateSettings = covariateSettings,
    cohortIds = c(1, 2)
  )
  expect_equal(class(result), "CovariateData")
})

test_that("createCohortAttrCovariateSettings check", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  result <- createCohortAttrCovariateSettings(attrDatabaseSchema = "main")
  expect_equal(class(result), "covariateSettings")
})

test_that("getDbCohortAttrCovariatesData cohortId warning", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  covariateSettings <- createCohortAttrCovariateSettings(
    attrDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortAttrTable = cohortAttributeTable,
    attrDefinitionTable = attributeDefinitionTable,
    includeAttrIds = c(1),
    isBinary = FALSE,
    missingMeansZero = TRUE
  )
  # cohortId argument
  expect_warning(getDbCohortAttrCovariatesData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTable = cohortTable,
    covariateSettings = covariateSettings,
    cohortId = 1
  ), "cohortId argument has been deprecated, please use cohortIds")
})
