library(testthat)

# runExtractionPerPerson ----------- 
runExtractionPerPerson <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable) {
  settings <- createCovariateSettings(useDemographicsGender = TRUE,
                                      useDemographicsAge = TRUE,
                                      useDemographicsAgeGroup = TRUE,
                                      useDemographicsRace = TRUE,
                                      useDemographicsEthnicity = TRUE,
                                      useDemographicsIndexYear = TRUE,
                                      useDemographicsIndexMonth = TRUE,
                                      useDemographicsPriorObservationTime = TRUE,
                                      useDemographicsPostObservationTime = FALSE,
                                      useDemographicsTimeInCohort = FALSE,
                                      useDemographicsIndexYearMonth = TRUE,
                                      useCareSiteId = TRUE,
                                      useConditionOccurrenceAnyTimePrior = FALSE,
                                      useConditionOccurrenceLongTerm = FALSE,
                                      useConditionOccurrenceMediumTerm = FALSE,
                                      useConditionOccurrenceShortTerm = TRUE,
                                      useConditionOccurrencePrimaryInpatientAnyTimePrior =  FALSE,
                                      useConditionOccurrencePrimaryInpatientLongTerm = FALSE,
                                      useConditionOccurrencePrimaryInpatientMediumTerm = FALSE,
                                      useConditionOccurrencePrimaryInpatientShortTerm = TRUE,
                                      useConditionEraAnyTimePrior = FALSE,
                                      useConditionEraLongTerm = FALSE,
                                      useConditionEraMediumTerm = FALSE,
                                      useConditionEraShortTerm = TRUE,
                                      useConditionEraOverlapping = FALSE,
                                      useConditionEraStartLongTerm = FALSE,
                                      useConditionEraStartMediumTerm = FALSE,
                                      useConditionEraStartShortTerm = TRUE,
                                      useConditionGroupEraAnyTimePrior = FALSE,
                                      useConditionGroupEraLongTerm = FALSE,
                                      useConditionGroupEraMediumTerm = FALSE,
                                      useConditionGroupEraShortTerm = TRUE,
                                      useConditionGroupEraOverlapping = FALSE,
                                      useConditionGroupEraStartLongTerm = FALSE,
                                      useConditionGroupEraStartMediumTerm = FALSE,
                                      useConditionGroupEraStartShortTerm = FALSE,
                                      useDrugExposureAnyTimePrior = FALSE,
                                      useDrugExposureLongTerm = FALSE,
                                      useDrugExposureMediumTerm = FALSE,
                                      useDrugExposureShortTerm = TRUE,
                                      useDrugEraAnyTimePrior = FALSE,
                                      useDrugEraLongTerm = FALSE,
                                      useDrugEraMediumTerm = FALSE,
                                      useDrugEraShortTerm = TRUE,
                                      useDrugEraOverlapping = FALSE,
                                      useDrugEraStartLongTerm = FALSE,
                                      useDrugEraStartMediumTerm = FALSE,
                                      useDrugEraStartShortTerm = TRUE,
                                      useDrugGroupEraAnyTimePrior = FALSE,
                                      useDrugGroupEraLongTerm = FALSE,
                                      useDrugGroupEraMediumTerm = FALSE,
                                      useDrugGroupEraShortTerm = TRUE,
                                      useDrugGroupEraOverlapping = FALSE,
                                      useDrugGroupEraStartLongTerm = FALSE,
                                      useDrugGroupEraStartMediumTerm = FALSE,
                                      useDrugGroupEraStartShortTerm = TRUE,
                                      useProcedureOccurrenceAnyTimePrior = FALSE,
                                      useProcedureOccurrenceLongTerm = FALSE,
                                      useProcedureOccurrenceMediumTerm = FALSE,
                                      useProcedureOccurrenceShortTerm = TRUE,
                                      useDeviceExposureAnyTimePrior = FALSE,
                                      useDeviceExposureLongTerm = FALSE,
                                      useDeviceExposureMediumTerm = FALSE,
                                      useDeviceExposureShortTerm = TRUE,
                                      useMeasurementAnyTimePrior = FALSE,
                                      useMeasurementLongTerm = FALSE,
                                      useMeasurementMediumTerm = FALSE,
                                      useMeasurementShortTerm = TRUE,
                                      useMeasurementValueAnyTimePrior = FALSE,
                                      useMeasurementValueLongTerm = FALSE,
                                      useMeasurementValueMediumTerm = FALSE,
                                      useMeasurementValueShortTerm = TRUE,
                                      useMeasurementRangeGroupAnyTimePrior = FALSE,
                                      useMeasurementRangeGroupLongTerm = FALSE,
                                      useMeasurementRangeGroupMediumTerm = FALSE,
                                      useMeasurementRangeGroupShortTerm = TRUE,
                                      useObservationAnyTimePrior = FALSE,
                                      useObservationLongTerm = FALSE,
                                      useObservationMediumTerm = FALSE,
                                      useObservationShortTerm = TRUE,
                                      useCharlsonIndex = TRUE,
                                      useDcsi = TRUE,
                                      useChads2 = TRUE,
                                      useChads2Vasc = TRUE,
                                      useHfrs = TRUE,
                                      useDistinctConditionCountLongTerm = FALSE,
                                      useDistinctConditionCountMediumTerm = FALSE,
                                      useDistinctConditionCountShortTerm = TRUE,
                                      useDistinctIngredientCountLongTerm = FALSE,
                                      useDistinctIngredientCountMediumTerm = FALSE,
                                      useDistinctIngredientCountShortTerm = TRUE,
                                      useDistinctProcedureCountLongTerm = FALSE,
                                      useDistinctProcedureCountMediumTerm = FALSE,
                                      useDistinctProcedureCountShortTerm = TRUE,
                                      useDistinctMeasurementCountLongTerm = FALSE,
                                      useDistinctMeasurementCountMediumTerm = FALSE,
                                      useDistinctMeasurementCountShortTerm = TRUE,
                                      useDistinctObservationCountLongTerm = FALSE,
                                      useDistinctObservationCountMediumTerm = FALSE,
                                      useDistinctObservationCountShortTerm = TRUE,
                                      useVisitCountLongTerm = FALSE,
                                      useVisitCountMediumTerm = FALSE,
                                      useVisitCountShortTerm = TRUE,
                                      useVisitConceptCountLongTerm = FALSE,
                                      useVisitConceptCountMediumTerm = FALSE,
                                      useVisitConceptCountShortTerm = TRUE,
                                      longTermStartDays = -365,
                                      mediumTermStartDays = -180,
                                      shortTermStartDays = -30,
                                      endDays = 0,
                                      includedCovariateConceptIds = c(),
                                      addDescendantsToInclude = FALSE,
                                      excludedCovariateConceptIds = c(),
                                      addDescendantsToExclude = FALSE,
                                      includedCovariateIds = c())

  suppressWarnings(covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       oracleTempSchema = ohdsiDatabaseSchema,
                                                       cohortDatabaseSchema = ohdsiDatabaseSchema,
                                                       cohortTable = cohortsTable,
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings))
  return(covariateData)
}

test_that("Run all analysis at per-person level on PostgreSQL", {
  skip_if_not(runTestsOnPostgreSQL)
  covariateData <- runExtractionPerPerson(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at per-person level on SQL Server", {
  skip_if_not(runTestsOnSQLServer)
  covariateData <- runExtractionPerPerson(sqlServerConnectionDetails, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at per-person level on Oracle", {
  skip_if_not(runTestsOnOracle)
  covariateData <- runExtractionPerPerson(oracleConnectionDetails, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at per-person level on Impala", {
  skip_if_not(runTestsOnImpala)
  covariateData <- runExtractionPerPerson(impalaConnectionDetails, impalaCdmDatabaseSchema, impalaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at per-person level on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  covariateData <- runExtractionPerPerson(eunomiaConnectionDetails, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

# runExtractionAggregated ----------- 
runExtractionAggregated <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable) {
  settings <- createCovariateSettings(useDemographicsGender = TRUE,
                                      useDemographicsAge = TRUE,
                                      useDemographicsAgeGroup = TRUE,
                                      useDemographicsRace = TRUE,
                                      useDemographicsEthnicity = TRUE,
                                      useDemographicsIndexYear = TRUE,
                                      useDemographicsIndexMonth = TRUE,
                                      useDemographicsPriorObservationTime = TRUE,
                                      useDemographicsPostObservationTime = FALSE,
                                      useDemographicsTimeInCohort = FALSE,
                                      useDemographicsIndexYearMonth = TRUE,
                                      useCareSiteId = TRUE,
                                      useConditionOccurrenceAnyTimePrior = FALSE,
                                      useConditionOccurrenceLongTerm = FALSE,
                                      useConditionOccurrenceMediumTerm = FALSE,
                                      useConditionOccurrenceShortTerm = TRUE,
                                      useConditionOccurrencePrimaryInpatientAnyTimePrior = FALSE,
                                      useConditionOccurrencePrimaryInpatientLongTerm = FALSE,
                                      useConditionOccurrencePrimaryInpatientMediumTerm = FALSE,
                                      useConditionOccurrencePrimaryInpatientShortTerm = TRUE,
                                      useConditionEraAnyTimePrior = FALSE,
                                      useConditionEraLongTerm = FALSE,
                                      useConditionEraMediumTerm = FALSE,
                                      useConditionEraShortTerm = TRUE,
                                      useConditionEraOverlapping = FALSE,
                                      useConditionEraStartLongTerm = FALSE,
                                      useConditionEraStartMediumTerm = FALSE,
                                      useConditionEraStartShortTerm = TRUE,
                                      useConditionGroupEraAnyTimePrior = FALSE,
                                      useConditionGroupEraLongTerm = FALSE,
                                      useConditionGroupEraMediumTerm = FALSE,
                                      useConditionGroupEraShortTerm = TRUE,
                                      useConditionGroupEraOverlapping = FALSE,
                                      useConditionGroupEraStartLongTerm = FALSE,
                                      useConditionGroupEraStartMediumTerm = FALSE,
                                      useConditionGroupEraStartShortTerm = FALSE,
                                      useDrugExposureAnyTimePrior = FALSE,
                                      useDrugExposureLongTerm = FALSE,
                                      useDrugExposureMediumTerm = FALSE,
                                      useDrugExposureShortTerm = TRUE,
                                      useDrugEraAnyTimePrior = FALSE,
                                      useDrugEraLongTerm = FALSE,
                                      useDrugEraMediumTerm = FALSE,
                                      useDrugEraShortTerm = TRUE,
                                      useDrugEraOverlapping = FALSE,
                                      useDrugEraStartLongTerm = FALSE,
                                      useDrugEraStartMediumTerm = FALSE,
                                      useDrugEraStartShortTerm = TRUE,
                                      useDrugGroupEraAnyTimePrior = FALSE,
                                      useDrugGroupEraLongTerm = FALSE,
                                      useDrugGroupEraMediumTerm = FALSE,
                                      useDrugGroupEraShortTerm = TRUE,
                                      useDrugGroupEraOverlapping = FALSE,
                                      useDrugGroupEraStartLongTerm = FALSE,
                                      useDrugGroupEraStartMediumTerm = FALSE,
                                      useDrugGroupEraStartShortTerm = FALSE,
                                      useProcedureOccurrenceAnyTimePrior = FALSE,
                                      useProcedureOccurrenceLongTerm = FALSE,
                                      useProcedureOccurrenceMediumTerm = FALSE,
                                      useProcedureOccurrenceShortTerm = TRUE,
                                      useDeviceExposureAnyTimePrior = FALSE,
                                      useDeviceExposureLongTerm = FALSE,
                                      useDeviceExposureMediumTerm = FALSE,
                                      useDeviceExposureShortTerm = TRUE,
                                      useMeasurementAnyTimePrior = FALSE,
                                      useMeasurementLongTerm = FALSE,
                                      useMeasurementMediumTerm = FALSE,
                                      useMeasurementShortTerm = TRUE,
                                      useMeasurementValueAnyTimePrior = FALSE,
                                      useMeasurementValueLongTerm = FALSE,
                                      useMeasurementValueMediumTerm = FALSE,
                                      useMeasurementValueShortTerm = TRUE,
                                      useMeasurementRangeGroupAnyTimePrior = FALSE,
                                      useMeasurementRangeGroupLongTerm = FALSE,
                                      useMeasurementRangeGroupMediumTerm = FALSE,
                                      useMeasurementRangeGroupShortTerm = TRUE,
                                      useObservationAnyTimePrior = FALSE,
                                      useObservationLongTerm = FALSE,
                                      useObservationMediumTerm = FALSE,
                                      useObservationShortTerm = TRUE,
                                      useCharlsonIndex = TRUE,
                                      useDcsi = TRUE,
                                      useChads2 = TRUE,
                                      useChads2Vasc = TRUE,
                                      useHfrs = TRUE,
                                      useDistinctConditionCountLongTerm = FALSE,
                                      useDistinctConditionCountMediumTerm = FALSE,
                                      useDistinctConditionCountShortTerm = TRUE,
                                      useDistinctIngredientCountLongTerm = FALSE,
                                      useDistinctIngredientCountMediumTerm = FALSE,
                                      useDistinctIngredientCountShortTerm = TRUE,
                                      useDistinctProcedureCountLongTerm = FALSE,
                                      useDistinctProcedureCountMediumTerm = FALSE,
                                      useDistinctProcedureCountShortTerm = TRUE,
                                      useDistinctMeasurementCountLongTerm = FALSE,
                                      useDistinctMeasurementCountMediumTerm = FALSE,
                                      useDistinctMeasurementCountShortTerm = TRUE,
                                      useDistinctObservationCountLongTerm = FALSE,
                                      useDistinctObservationCountMediumTerm = FALSE,
                                      useDistinctObservationCountShortTerm = TRUE,
                                      useVisitCountLongTerm = FALSE,
                                      useVisitCountMediumTerm = FALSE,
                                      useVisitCountShortTerm = TRUE,
                                      useVisitConceptCountLongTerm = FALSE,
                                      useVisitConceptCountMediumTerm = FALSE,
                                      useVisitConceptCountShortTerm = TRUE,
                                      longTermStartDays = -365,
                                      mediumTermStartDays = -180,
                                      shortTermStartDays = -30,
                                      endDays = 0,
                                      includedCovariateConceptIds = c(),
                                      addDescendantsToInclude = FALSE,
                                      excludedCovariateConceptIds = c(),
                                      addDescendantsToExclude = FALSE,
                                      includedCovariateIds = c())

  suppressWarnings(covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       oracleTempSchema = ohdsiDatabaseSchema,
                                                       cohortDatabaseSchema = ohdsiDatabaseSchema,
                                                       cohortTable = cohortsTable,
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings,
                                                       aggregated = TRUE))
  return(covariateData)
}

test_that("Run all analysis at aggregated level on PostgreSQL", {
  skip_if_not(runTestsOnPostgreSQL)
  covariateData <- runExtractionAggregated(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at aggregated level on SQL Server", {
  skip_if_not(runTestsOnSQLServer)
  covariateData <- runExtractionAggregated(sqlServerConnectionDetails, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at aggregated level on Oracle", {
  skip_if_not(runTestsOnOracle)
  covariateData <- runExtractionAggregated(oracleConnectionDetails, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at aggregated level on Impala", {
  skip_if_not(runTestsOnImpala)
  covariateData <- runExtractionAggregated(impalaConnectionDetails, impalaCdmDatabaseSchema, impalaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all analysis at aggregated level on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  covariateData <- runExtractionAggregated(eunomiaConnectionDetails, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

# runExtractionTemporalPerPerson ----------- 
runExtractionTemporalPerPerson <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable) {
  settings <- createTemporalCovariateSettings(useDemographicsGender = TRUE,
                                              useDemographicsAge = TRUE,
                                              useDemographicsAgeGroup = TRUE,
                                              useDemographicsRace = TRUE,
                                              useDemographicsEthnicity = TRUE,
                                              useDemographicsIndexYear = TRUE,
                                              useDemographicsIndexMonth = TRUE,
                                              useDemographicsIndexYearMonth = TRUE,
                                              useDemographicsPriorObservationTime = TRUE,
                                              useDemographicsPostObservationTime = TRUE,
                                              useDemographicsTimeInCohort = TRUE,
                                              useCareSiteId = TRUE,
                                              useConditionOccurrence = TRUE,
                                              useConditionOccurrencePrimaryInpatient = TRUE,
                                              useConditionEraStart = TRUE,
                                              useConditionEraOverlap = TRUE,
                                              useConditionEraGroupStart = FALSE,
                                              useConditionEraGroupOverlap = FALSE,
                                              useDrugExposure = TRUE,
                                              useDrugEraStart = TRUE,
                                              useDrugEraOverlap = TRUE,
                                              useDrugEraGroupStart = FALSE,
                                              useDrugEraGroupOverlap = FALSE,
                                              useProcedureOccurrence = TRUE,
                                              useDeviceExposure = TRUE,
                                              useMeasurement = TRUE,
                                              useMeasurementValue = TRUE,
                                              useMeasurementRangeGroup = TRUE,
                                              useObservation = TRUE,
                                              useCharlsonIndex = TRUE,
                                              useDcsi = TRUE,
                                              useChads2 = TRUE,
                                              useChads2Vasc = TRUE,
                                              useHfrs = TRUE,
                                              useDistinctConditionCount = TRUE,
                                              useDistinctIngredientCount = TRUE,
                                              useDistinctProcedureCount = TRUE,
                                              useDistinctMeasurementCount = TRUE,
                                              useDistinctObservationCount = TRUE,
                                              useVisitCount = TRUE,
                                              useVisitConceptCount = TRUE,
                                              temporalStartDays = -365:-1,
                                              temporalEndDays = -365:-1,
                                              includedCovariateConceptIds = c(),
                                              addDescendantsToInclude = FALSE,
                                              excludedCovariateConceptIds = c(),
                                              addDescendantsToExclude = FALSE,
                                              includedCovariateIds = c())
  suppressWarnings(covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       oracleTempSchema = ohdsiDatabaseSchema,
                                                       cohortDatabaseSchema = ohdsiDatabaseSchema,
                                                       cohortTable = cohortsTable,
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings))
  return(covariateData)
}

test_that("Run all temporalanalysis at per-person level on PostgreSQL", {
  skip_if_not(runTestsOnPostgreSQL)
  covariateData <- runExtractionTemporalPerPerson(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at per-person level on SQL Server", {
  skip_if_not(runTestsOnSQLServer)
  covariateData <- runExtractionTemporalPerPerson(sqlServerConnectionDetails, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at per-person level on Oracle", {
  skip_if_not(runTestsOnOracle)
  covariateData <- runExtractionTemporalPerPerson(oracleConnectionDetails, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at per-person level on Impala", {
  skip_if_not(runTestsOnImpala)
  covariateData <- runExtractionTemporalPerPerson(impalaConnectionDetails, impalaCdmDatabaseSchema, impalaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at per-person level on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  covariateData <- runExtractionTemporalPerPerson(eunomiaConnectionDetails, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

# runExtractionTemporalPerPerson -----------
runExtractionTemporalAggregated <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema, cohortsTable) {
  settings <- createTemporalCovariateSettings(useDemographicsGender = TRUE,
                                              useDemographicsAge = TRUE,
                                              useDemographicsAgeGroup = TRUE,
                                              useDemographicsRace = TRUE,
                                              useDemographicsEthnicity = TRUE,
                                              useDemographicsIndexYear = TRUE,
                                              useDemographicsIndexMonth = TRUE,
                                              useDemographicsIndexYearMonth = TRUE,
                                              useDemographicsPriorObservationTime = TRUE,
                                              useDemographicsPostObservationTime = TRUE,
                                              useDemographicsTimeInCohort = TRUE,
                                              useCareSiteId = TRUE,
                                              useConditionOccurrence = TRUE,
                                              useConditionOccurrencePrimaryInpatient = TRUE,
                                              useConditionEraStart = TRUE,
                                              useConditionEraOverlap = TRUE,
                                              useConditionEraGroupStart = FALSE,
                                              useConditionEraGroupOverlap = FALSE,
                                              useDrugExposure = TRUE,
                                              useDrugEraStart = TRUE,
                                              useDrugEraOverlap = TRUE,
                                              useDrugEraGroupStart = FALSE,
                                              useDrugEraGroupOverlap = FALSE,
                                              useProcedureOccurrence = TRUE,
                                              useDeviceExposure = TRUE,
                                              useMeasurement = TRUE,
                                              useMeasurementValue = TRUE,
                                              useMeasurementRangeGroup = TRUE,
                                              useObservation = TRUE,
                                              useCharlsonIndex = TRUE,
                                              useDcsi = TRUE,
                                              useChads2 = TRUE,
                                              useChads2Vasc = TRUE,
                                              useHfrs = TRUE,
                                              useDistinctConditionCount = TRUE,
                                              useDistinctIngredientCount = TRUE,
                                              useDistinctProcedureCount = TRUE,
                                              useDistinctMeasurementCount = TRUE,
                                              useDistinctObservationCount = TRUE,
                                              useVisitCount = TRUE,
                                              useVisitConceptCount = TRUE,
                                              temporalStartDays = -365:-1,
                                              temporalEndDays = -365:-1,
                                              includedCovariateConceptIds = c(),
                                              addDescendantsToInclude = FALSE,
                                              excludedCovariateConceptIds = c(),
                                              addDescendantsToExclude = FALSE,
                                              includedCovariateIds = c())
  suppressWarnings(covariateData <- getDbCovariateData(connectionDetails = connectionDetails,
                                                       cdmDatabaseSchema = cdmDatabaseSchema,
                                                       oracleTempSchema = ohdsiDatabaseSchema,
                                                       cohortDatabaseSchema = ohdsiDatabaseSchema,
                                                       cohortTable = cohortsTable,
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings,
                                                       aggregated = TRUE))
  return(covariateData)
}

test_that("Run all temporalanalysis at aggregated level on PostgreSQL", {
  skip_if_not(runTestsOnPostgreSQL)
  covariateData <- runExtractionTemporalAggregated(pgConnectionDetails, pgCdmDatabaseSchema, pgOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at aggregated level on SQL Server", {
  skip_if_not(runTestsOnSQLServer)
  covariateData <- runExtractionTemporalAggregated(sqlServerConnectionDetails, sqlServerCdmDatabaseSchema, sqlServerOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at aggregated level on Oracle", {
  skip_if_not(runTestsOnOracle)
  covariateData <- runExtractionTemporalAggregated(oracleConnectionDetails, oracleCdmDatabaseSchema, oracleOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at aggregated level on Impala", {
  skip_if_not(runTestsOnImpala)
  covariateData <- runExtractionTemporalAggregated(impalaConnectionDetails, impalaCdmDatabaseSchema, impalaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})

test_that("Run all temporalanalysis at aggregated level on Eunomia", {
  skip_if_not(runTestsOnEunomia)
  covariateData <- runExtractionTemporalAggregated(eunomiaConnectionDetails, eunomiaCdmDatabaseSchema, eunomiaOhdsiDatabaseSchema, cohortsTable)
  expect_true(is(covariateData, "CovariateData"))
})
