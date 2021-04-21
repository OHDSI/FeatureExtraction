# View coverage for this file
# covr::file_report(covr::file_coverage("R/Table1.R", "tests/testthat/test-Table1.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connectionDetails)

test_that("getDefaultTable1Specifications works", {
  spec <- getDefaultTable1Specifications()
  expect_s3_class(spec, "data.frame")
  expect_equal(names(spec), c("label", "analysisId", "covariateIds"))
})


test_that("createTable1 works with categorical covariates", {
  
  
  settings <- createCovariateSettings(useDemographicsAgeGroup = TRUE,
                                      useDemographicsGender = TRUE,
                                      useChads2Vasc = F)
                                           
  covariateData1 <- getDbCovariateData(connectionDetails = connectionDetails,
                                       cdmDatabaseSchema = "main",
                                       cohortDatabaseSchema = "main",
                                       cohortId = 1,
                                       covariateSettings = settings,
                                       aggregated = TRUE)
  
  expect_error(createTable1("blah"), "not of type 'covariateData'")
  expect_error(createTable1(covariateData1, showCounts = F, showPercent = F), "counts or percent")
  table1 <- createTable1(covariateData1, specifications = getDefaultTable1Specifications()[1:2,])
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 4)
  expect_equal(names(table1)[1], names(table1)[3])
  expect_equal(names(table1)[2], names(table1)[4])
  
  table1 <- createTable1(covariateData1, output = "one column")
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 2)
  
  
  
  covariateData2 <- getDbCovariateData(connectionDetails = connectionDetails,
                                      cdmDatabaseSchema = "main",
                                      cohortDatabaseSchema = "main",
                                      cohortId = 2,
                                      covariateSettings = settings,
                                      aggregated = TRUE)
  
  expect_error(createTable1(covariateData1, "blah"), "not of type 'covariateData'")
  table1 <- createTable1(covariateData1, covariateData2)
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 8)  
  
  table1 <- createTable1(covariateData1, covariateData2, output = "one column")
  expect_s3_class(table1, "data.frame")
  expect_equal(ncol(table1), 4)
  
  
  rawCovariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                       cdmDatabaseSchema = "main",
                                       cohortDatabaseSchema = "main",
                                       cohortId = 1,
                                       covariateSettings = settings,
                                       aggregated = FALSE)
  
  expect_error(createTable1(rawCovariateData), "data is not aggregated")
  expect_error(createTable1(covariateData1, rawCovariateData), "data is not aggregated")
  
})



test_that("createTable1 works with continuous covariates", {
  settings <- createCovariateSettings(useDemographicsAgeGroup = TRUE,
                                      useDemographicsGender = TRUE,
                                      useChads2Vasc = TRUE)
  
  covariateData1 <- getDbCovariateData(connectionDetails = connectionDetails,
                                       cdmDatabaseSchema = "main",
                                       cohortDatabaseSchema = "main",
                                       cohortId = 1,
                                       covariateSettings = settings,
                                       aggregated = TRUE)
  
  table1 <- createTable1(covariateData1, specifications = getDefaultTable1Specifications()[1:2,])
  expect_s3_class(table1, "data.frame")
  
  table1 <- createTable1(covariateData1, output = "one column")
  expect_s3_class(table1, "data.frame")
  
  
  covariateData2 <- getDbCovariateData(connectionDetails = connectionDetails,
                                       cdmDatabaseSchema = "main",
                                       cohortDatabaseSchema = "main",
                                       cohortId = 2,
                                       covariateSettings = settings,
                                       aggregated = TRUE)
  
  table1 <- createTable1(covariateData1, covariateData2, output = "one column")
  expect_s3_class(table1, "data.frame")
})







