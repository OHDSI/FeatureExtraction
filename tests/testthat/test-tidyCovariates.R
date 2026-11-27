# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/Normalization.R", "tests/testthat/test-tidyCovariates.R"))

test_that("Test exit conditions ", {
  # Covariate Data object check
  expect_error(tidyCovariateData(covariateData = list()))
  # CovariateData object closed
  cvData <- FeatureExtraction::createEmptyCovariateData(
    cohortIds = 1,
    aggregated = FALSE,
    temporal = FALSE
  )
  Andromeda::close(cvData)
  expect_error(tidyCovariateData(covariateData = cvData))
  # CovariateData aggregated
  cvData <- FeatureExtraction::createEmptyCovariateData(
    cohortIds = 1,
    aggregated = TRUE,
    temporal = FALSE
  )
  expect_error(tidyCovariateData(covariateData = cvData))
})

test_that("Test empty covariateData", {
  cvData <- FeatureExtraction::createEmptyCovariateData(
    cohortIds = 1,
    aggregated = FALSE,
    temporal = FALSE
  )
  result <- tidyCovariateData(covariateData = cvData)
  expect_equal(length(pull(result$covariates, covariateId)), length(pull(cvData$covariates, covariateId)))
})

test_that("tidyCovariates works", {
  # Generate some data:
  createCovariate <- function(i, analysisId) {
    return(tibble(
      covariateId = rep(i * 1000 + analysisId, i),
      covariateValue = rep(1, i)
    ))
  }
  covariates <- lapply(1:10, createCovariate, analysisId = 1)
  covariates <- do.call("rbind", covariates)
  covariates$rowId <- 1:nrow(covariates)
  metaData <- list(populationSize = nrow(covariates))
  frequentCovariate <- createCovariate(40, analysisId = 2)
  frequentCovariate$rowId <- sample.int(metaData$populationSize, nrow(frequentCovariate), replace = FALSE)
  infrequentCovariate <- createCovariate(1, analysisId = 3)
  infrequentCovariate$rowId <- sample.int(metaData$populationSize, nrow(infrequentCovariate), replace = FALSE)
  covariates <- rbind(covariates, frequentCovariate, infrequentCovariate)

  covariateRef <- tibble(
    covariateId = c(1:10 * 1000 + 1, 40002, 1003),
    analysisId = c(rep(1, 10), 2, 3)
  )

  covariateData <- Andromeda::andromeda(
    covariates = covariates,
    covariateRef = covariateRef
  )
  attr(covariateData, "metaData") <- metaData
  class(covariateData) <- "CovariateData"

  tidy <- tidyCovariateData(covariateData, minFraction = 0.1, normalize = TRUE, removeRedundancy = TRUE)

  # Test: most prevalent covariate in analysis 1 is dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 10001) %>% collect()) == 0)

  # Test: infrequent covariate in analysis 1 isn't dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 1001) %>% collect()) != 0)

  # Test: infrequent covariate is dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 1003) %>% collect()) == 0)

  # Test: frequent covariate isn't dropped:
  expect_true(nrow(filter(tidy$covariates, covariateId == 40002) %>% collect()) != 0)
})

test_that("tidyCovariateData on Temporal Data", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))
  covariateSettings <- createTemporalCovariateSettings(
    useDrugExposure = TRUE,
    temporalStartDays = -2:-1,
    temporalEndDays = -2:-1
  )
  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortIds = c(1),
    covariateSettings = covariateSettings
  )
  tidy <- tidyCovariateData(covariateData)
  expect_equal(length(pull(tidy$analysisRef, analysisId)), length(pull(covariateData$analysisRef, analysisId)))
})

test_that("Removal of redundant covariates is reproducible", {
  # Create data with two covariates from the same analysis, with equal prevalence:
  covariates <- tibble(
    covariateId = rep(c(1, 2), 5),
    rowId = seq_len(10),
    covariateValue = 1
  )
  covariateRef <- tibble(
    covariateId = c(1, 2),
    analysisId = c(1, 1)
  )
  metaData <- list(populationSize = 10)
  covariateData <- Andromeda::andromeda(
    covariates = covariates,
    covariateRef = covariateRef
  )
  attr(covariateData, "metaData") <- metaData
  class(covariateData) <- "CovariateData"

  # Repeat removal of redundant covariates multiple times to evaluate consistency:
  covariateIds <- c()
  for (i in seq_len(10)) {
    tidy <- tidyCovariateData(covariateData, minFraction = 0, normalize = FALSE, removeRedundancy = TRUE)
    covariateIds[i] <- tidy$covariates |>
      distinct(covariateId) |>
      pull()
  }
  expect_equal(length(unique(covariateIds)), 1)
})

test_that("tidyCovariateData removes redundant temporal covariates with NA timeId", {
  covariates <- tibble(
    rowId = c(1, 2, 3, 1, 2, 3, 1, 2, 3, 1),
    covariateId = c(
      8507001, 8507001, 8507001,
      1002, 1002, 2002,
      1003, 1003, 1003, 1003
    ),
    timeId = c(
      NA_real_, NA_real_, NA_real_,
      NA_real_, NA_real_, NA_real_,
      1, 1, 1, 2
    ),
    covariateValue = rep(1, 10)
  )
  covariateRef <- tibble(
    covariateId = c(8507001, 1002, 2002, 1003),
    analysisId = c(1, 2, 2, 3)
  )
  timeRef <- tibble(
    timeId = c(1, 2),
    startDay = c(-30, -60),
    endDay = c(0, -31)
  )
  covariateData <- Andromeda::andromeda(
    covariates = covariates,
    covariateRef = covariateRef,
    timeRef = timeRef
  )
  attr(covariateData, "metaData") <- list(populationSize = 3)
  class(covariateData) <- "CovariateData"

  tidy <- tidyCovariateData(
    covariateData,
    minFraction = 0,
    normalize = FALSE,
    removeRedundancy = TRUE
  )
  result <- collect(tidy$covariates)

  # Single non-temporal covariate covering everyone (timeId = NA) is removed
  expect_equal(sum(result$covariateId == 8507001), 0)
  # Most prevalent covariate in exhaustive non-temporal analysis (timeId = NA) is removed
  expect_equal(sum(result$covariateId == 1002), 0)
  expect_equal(sum(result$covariateId == 2002), 1)
  # Temporal covariate covering everyone in timeId = 1 is removed only for timeId = 1
  expect_equal(sum(result$covariateId == 1003 & result$timeId == 1), 0)
  expect_equal(sum(result$covariateId == 1003 & result$timeId == 2), 1)
})
