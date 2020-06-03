library(testthat)
library(FeatureExtraction)

test_that("tidyCovariates works", {
  # Generate some data:
  createCovariate <- function(i, analysisId) {
    return(tibble(covariateId = rep(i * 1000 + analysisId, i),
                          covariateValue = rep(1,i)))
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
  
  covariateRef <- tibble(covariateId = c(1:10 * 1000 + 1, 40002, 1003),
                                 analysisId = c(rep(1, 10), 2, 3))
  
  covariateData <- Andromeda::andromeda(covariates = covariates,
                                        covariateRef = covariateRef)
  attr(covariateData, "metaData") <- metaData
  class(covariateData) <- "CovariateData"
  
  tidy <- tidyCovariateData(covariateData, minFraction = 0.1, normalize = TRUE, removeRedundancy = TRUE)
  
  # Test: most prevalent covariate in analysis 1 is dropped:
  expect_true(nrow(tidy$covariates %>% filter(covariateId == 10001)) == 0)
  
  # Test: infrequent covariate in analysis 1 isn't dropped:
  expect_true(nrow(tidy$covariates %>% filter(covariateId == 1001)) != 0)
  
  # Test: infrequent covariate is dropped:
  expect_true(nrow(tidy$covariates %>% filter(covariateId == 1003)) == 0)

  # Test: frequent covariate isn't dropped:
  expect_true(nrow(tidy$covariates %>% filter(covariateId == 40002)) != 0)
})
