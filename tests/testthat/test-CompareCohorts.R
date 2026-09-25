# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/CompareCohorts.R", "tests/testthat/test-CompareCohorts.R"))

test_that("Test stdDiff continuous variable computation", {
  # NOTE: Data stored in "inst/testdata/continuousCovariateData.zip" created by:
  # ------------------------------------------------------------------------------
  # connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  # Eunomia::createCohorts(connectionDetails)
  # data <- FeatureExtraction::getDbCovariateData(connectionDetails = connectionDetails,
  #                                               cdmDatabaseSchema = "main",
  #                                               cohortTable = "cohort",
  #                                               aggregated = TRUE,
  #                                               covariateSettings = FeatureExtraction::createCovariateSettings(useCharlsonIndex = TRUE))
  # FeatureExtraction::saveCovariateData(data, "inst/testdata/continuousCovariateData.zip")
  # ------------------------------------------------------------------------------
  data <- loadCovariateData(getTestResourceFilePath("continuousCovariateData.zip"))
  # Compute the expected value based on cohorts 1 & 2's values from
  # the loaded covariate data
  testData <- data.frame(
    mean1 = 0.614,
    sd1 = 0.387,
    mean2 = 0.404,
    sd2 = 0.345
  )

  output <- computeStandardizedDifference(
    covariateData1 = data,
    covariateData2 = data,
    cohortId1 = 1,
    cohortId2 = 2
  )
  testData$sd <- sqrt((testData$sd1^2 + testData$sd2^2) / 2)
  testData$stdDiff <- (testData$mean2 - testData$mean1) / testData$sd

  # Compute the standardized difference of mean using the source data
  expect_equal(output$stdDiff, testData$stdDiff, tolerance = 0.001, scale = 1)
})

test_that("Test stdDiff binary variable computation", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  connectionDetails <- Eunomia::getEunomiaConnectionDetails()
  Eunomia::createCohorts(connectionDetails)
  data <- FeatureExtraction::getDbCovariateData(
    connectionDetails = connectionDetails,
    cdmDatabaseSchema = "main",
    cohortTable = "cohort",
    aggregated = TRUE,
    covariateSettings = FeatureExtraction::createCovariateSettings(useConditionOccurrenceLongTerm = TRUE)
  )
  output <- computeStandardizedDifference(
    covariateData1 = data,
    covariateData2 = data,
    cohortId1 = 1,
    cohortId2 = 2
  )
  # Filter to: condition_occurrence during day -365 through 0 days relative to index: Diverticular disease
  singleCovariate <- output[output$covariateId == 4266809102, ]

  # Compute the expected value based on cohorts 1 & 2's values from
  # the loaded covariate data for covariateId == 4266809102
  testBinaryData <- data.frame(
    popSize1 = 1844,
    sumValue1 = 341,
    popSize2 = 850,
    sumValue2 = 64
  )

  testBinaryData$mean1 <- testBinaryData$sumValue1 / testBinaryData$popSize1
  testBinaryData$mean2 <- testBinaryData$sumValue2 / testBinaryData$popSize2
  testBinaryData$sd1 <- sqrt(testBinaryData$mean1 * (1 - testBinaryData$mean1))
  testBinaryData$sd2 <- sqrt(testBinaryData$mean2 * (1 - testBinaryData$mean2))
  testBinaryData$sd <- sqrt((testBinaryData$sd1^2 + testBinaryData$sd2^2) / 2)
  testBinaryData$stdDiff <- (testBinaryData$mean2 - testBinaryData$mean1) / testBinaryData$sd

  # Test the results
  expect_equal(singleCovariate$mean1, testBinaryData$mean1, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$sd1, testBinaryData$sd1, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$mean2, testBinaryData$mean2, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$sd2, testBinaryData$sd2, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$sd, testBinaryData$sd, tolerance = 0.001, scale = 1)
  expect_equal(singleCovariate$stdDiff, testBinaryData$stdDiff, tolerance = 0.001, scale = 1)
})

test_that("Test stdDiff temporal binary variable computation", {
  # Regression test for https://github.com/OHDSI/FeatureExtraction/issues/225:
  # temporal covariate data carry a timeId column. The standardized difference must be
  # computed per (covariateId, timeId); merging on covariateId alone produces a cartesian
  # product across time windows, silently yielding wrong standardized differences.
  createTemporalBinaryCovariateData <- function(cohortId, covariates, populationSize) {
    covariateData <- Andromeda::andromeda(
      covariates = covariates,
      covariateRef = tibble(
        covariateId = c(101, 102),
        covariateName = c("Test covariate 101", "Test covariate 102"),
        analysisId = c(1, 1),
        conceptId = c(0, 0)
      )
    )
    attr(covariateData, "metaData") <- list(populationSize = setNames(populationSize, cohortId))
    class(covariateData) <- "CovariateData"
    return(covariateData)
  }

  covariateData1 <- createTemporalBinaryCovariateData(
    cohortId = 1,
    covariates = tibble(
      cohortDefinitionId = 1,
      covariateId = c(101, 101, 102),
      timeId = c(1, 2, 1),
      sumValue = c(100, 200, 500)
    ),
    populationSize = 1000
  )
  covariateData2 <- createTemporalBinaryCovariateData(
    cohortId = 2,
    covariates = tibble(
      cohortDefinitionId = 2,
      covariateId = c(101, 101),
      timeId = c(1, 2),
      sumValue = c(100, 50)
    ),
    populationSize = 1000
  )

  output <- computeStandardizedDifference(
    covariateData1 = covariateData1,
    covariateData2 = covariateData2,
    cohortId1 = 1,
    cohortId2 = 2
  )

  # One row per (covariateId, timeId); covariate 102 only exists in cohort 1.
  # (Merging on covariateId alone would yield a 2x2 cartesian product for covariate 101.)
  expect_equal(nrow(output), 3)
  expect_true("timeId" %in% colnames(output))

  expected <- data.frame(
    covariateId = c(101, 101, 102),
    timeId = c(1, 2, 1),
    mean1 = c(0.1, 0.2, 0.5),
    mean2 = c(0.1, 0.05, 0)
  )
  expected$sd1 <- sqrt(expected$mean1 * (1 - expected$mean1))
  expected$sd2 <- sqrt(expected$mean2 * (1 - expected$mean2))
  expected$sd <- sqrt((expected$sd1^2 + expected$sd2^2) / 2)
  expected$stdDiff <- (expected$mean2 - expected$mean1) / expected$sd

  output <- output[order(output$covariateId, output$timeId), ]
  expect_equal(output$mean1, expected$mean1, tolerance = 1e-8)
  expect_equal(output$mean2, expected$mean2, tolerance = 1e-8)
  expect_equal(output$stdDiff, expected$stdDiff, tolerance = 1e-8)

  # Covariate 101 in time window 1 is perfectly balanced between the cohorts:
  expect_equal(output$stdDiff[output$covariateId == 101 & output$timeId == 1], 0)
})

test_that("Test stdDiff temporal continuous variable computation", {
  # Same cartesian-product guard as above, for the covariatesContinuous code path (#225).
  createTemporalContinuousCovariateData <- function(cohortId, covariatesContinuous, populationSize) {
    covariateData <- Andromeda::andromeda(
      covariatesContinuous = covariatesContinuous,
      covariateRef = tibble(
        covariateId = 201,
        covariateName = "Test continuous covariate 201",
        analysisId = 1,
        conceptId = 0
      )
    )
    attr(covariateData, "metaData") <- list(populationSize = setNames(populationSize, cohortId))
    class(covariateData) <- "CovariateData"
    return(covariateData)
  }

  covariateData1 <- createTemporalContinuousCovariateData(
    cohortId = 1,
    covariatesContinuous = tibble(
      cohortDefinitionId = 1,
      covariateId = 201,
      timeId = c(1, 2),
      averageValue = c(10, 20),
      standardDeviation = c(2, 3)
    ),
    populationSize = 1000
  )
  covariateData2 <- createTemporalContinuousCovariateData(
    cohortId = 2,
    covariatesContinuous = tibble(
      cohortDefinitionId = 2,
      covariateId = 201,
      timeId = c(1, 2),
      averageValue = c(10, 14),
      standardDeviation = c(2, 4)
    ),
    populationSize = 1000
  )

  output <- computeStandardizedDifference(
    covariateData1 = covariateData1,
    covariateData2 = covariateData2,
    cohortId1 = 1,
    cohortId2 = 2
  )

  expect_equal(nrow(output), 2)
  expect_true("timeId" %in% colnames(output))

  expected <- data.frame(
    timeId = c(1, 2),
    mean1 = c(10, 20),
    sd1 = c(2, 3),
    mean2 = c(10, 14),
    sd2 = c(2, 4)
  )
  expected$sd <- sqrt((expected$sd1^2 + expected$sd2^2) / 2)
  expected$stdDiff <- (expected$mean2 - expected$mean1) / expected$sd

  output <- output[order(output$timeId), ]
  expect_equal(output$mean1, expected$mean1, tolerance = 1e-8)
  expect_equal(output$sd1, expected$sd1, tolerance = 1e-8)
  expect_equal(output$mean2, expected$mean2, tolerance = 1e-8)
  expect_equal(output$sd2, expected$sd2, tolerance = 1e-8)
  expect_equal(output$stdDiff, expected$stdDiff, tolerance = 1e-8)

  # Time window 1 is perfectly balanced between the cohorts:
  expect_equal(output$stdDiff[output$timeId == 1], 0)
})
