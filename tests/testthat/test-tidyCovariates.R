library(testthat)
library(FeatureExtraction)

test_that("tidyCovariates works", {
  # Generate some data:
  createCovariate <- function(i, analysisId) {
     return(data.frame(covariateId = rep(i * 1000 + analysisId, i),
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
  
  covariateRef <- data.frame(covariateId = c(1:10 * 1000 + 1, 40002, 1003),
                             analysisId = c(rep(1, 10), 2, 3))
  covariateData <- list(covariates = ff::as.ffdf(covariates),
                        covariateRef = ff::as.ffdf(covariateRef),
                        metaData = metaData)
  class(covariateData) <- "covariateData"
  
  tidy <- tidyCovariateData(covariateData, minFraction = 0.1, normalize = TRUE, removeRedundancy = TRUE)

  # Test: most prevalent covariate in analysis 1 is dropped:
  expect_false(ffbase::any.ff(tidy$covariates$covariateId == 10001))

  # Test: infrequent covariate in analysis 1 isn't dropped:
  expect_true(ffbase::any.ff(tidy$covariates$covariateId == 1001))
    
  # Test: infrequent covariate is dropped:
  expect_false(ffbase::any.ff(tidy$covariates$covariateId == 1003))

  # Test: frequent covariate isn't dropped:
  expect_true(ffbase::any.ff(tidy$covariates$covariateId == 40002))
})
