# This file covers the code in Table1.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/Table1.R", "tests/testthat/test-Table1.R"))

test_that("getDefaultTable1Specifications works", {
  spec <- getDefaultTable1Specifications()
  expect_s3_class(spec, "data.frame")
  expect_equal(names(spec), c("label", "analysisId", "covariateIds"))
})


test_that("createTable1 works with categorical covariates", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  settings <- createCovariateSettings(
    useDemographicsAgeGroup = TRUE,
    useDemographicsGender = TRUE,
    useChads2Vasc = F
  )

  covariateData1 <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = settings,
    aggregated = TRUE
  )

  expect_error(createTable1("blah"), "not of type 'covariateData'")
  expect_error(createTable1(covariateData1, output = "blah"), "The `output` argument  must be")
  expect_error(createTable1(covariateData1, showCounts = F, showPercent = F), "counts or percent")
  table1 <- createTable1(covariateData1, specifications = getDefaultTable1Specifications()[1:2, ])
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 4)
  expect_equal(names(table1)[1], names(table1)[3])
  expect_equal(names(table1)[2], names(table1)[4])
  expect_equal(names(table1)[1], "Characteristic")
  expect_equal(names(table1)[2], "% (n = 638)")

  table1 <- createTable1(covariateData1, output = "one column")
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 2)
  expect_equal(names(table1), c("Characteristic", "% (n = 638)"))

  covariateData2 <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(2),
    covariateSettings = settings,
    aggregated = TRUE
  )

  expect_error(createTable1(covariateData1, "blah"), "not of type 'covariateData'")
  table1 <- createTable1(covariateData1, covariateData2)
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 8)
  expect_equal(names(table1), c(
    "Characteristic", "% (n = 638)", "% (n = 252)", "Std.Diff",
    "Characteristic", "% (n = 638)", "% (n = 252)", "Std.Diff"
  ))

  table1 <- createTable1(covariateData1, covariateData2, output = "one column")
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 4)
  expect_equal(names(table1), c("Characteristic", "% (n = 638)", "% (n = 252)", "Std.Diff"))

  rawCovariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = settings,
    aggregated = FALSE
  )

  expect_error(createTable1(rawCovariateData), "data is not aggregated")
  expect_error(createTable1(covariateData1, rawCovariateData), "data is not aggregated")
})



test_that("createTable1 works with continuous covariates", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  settings <- createCovariateSettings(
    useDemographicsAgeGroup = TRUE,
    useDemographicsGender = TRUE,
    useChads2Vasc = TRUE
  )

  covariateData1 <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = settings,
    aggregated = TRUE
  )

  # Does not fail?
  # expect_error(createTable1(covariateData1))


  table1 <- createTable1(covariateData1, specifications = getDefaultTable1Specifications()[1:2, ])
  expect_s3_class(table1, "data.frame")

  table1 <- createTable1(covariateData1, output = "one column")
  expect_s3_class(table1, "data.frame")

  covariateData2 <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(2),
    covariateSettings = settings,
    aggregated = TRUE
  )

  table1 <- createTable1(covariateData1, covariateData2,
    output = "one column",
    cohortId1 = 1, cohortId2 = 2,
    showCounts = TRUE, showPercent = TRUE
  )
  expect_s3_class(table1, "data.frame")


  settings <- createCovariateSettings(useChads2Vasc = TRUE)

  covariateData3 <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = settings,
    aggregated = TRUE
  )
  table1 <- createTable1(covariateData3, output = "one column", showCounts = T, showPercent = T)
  expect_s3_class(table1, "data.frame")
})


test_that("createTable1 works with other covariates", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  settings <- createCovariateSettings(
    useDemographicsAgeGroup = TRUE,
    useChads2Vasc = TRUE
  )
  spec <- getDefaultTable1Specifications()
  spec <- spec[which(spec$label %in% c("CHADS2Vasc", "Age group")), ]
  spec[1, "analysisId"] <- NA_integer_
  spec[2, "covariateIds"] <- NA_character_

  covariateData1 <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortDatabaseSchema = eunomiaOhdsiDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = settings,
    aggregated = TRUE
  )

  table1 <- createTable1(covariateData1, specifications = spec, output = "list")
  expect_type(table1, "list")
})

test_that("createTable1CovariateSettings works", {
  covariateSettings <- createTable1CovariateSettings()
  expect_s3_class(covariateSettings, "covariateSettings")
})
