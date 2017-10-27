library(testthat)

runExtractionPerPerson <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- SqlRender::loadRenderTranslateSql("cohortsOfInterest.sql",
                                           packageName = "FeatureExtraction",
                                           dbms = connectionDetails$dbms,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           resultsDatabaseSchema = ohdsiDatabaseSchema)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
  settings <- createCovariateSettings(useDemographicsGender = TRUE,
                                      useDemographicsAge = TRUE,
                                      useDemographicsAgeGroup = TRUE,
                                      useDemographicsRace = TRUE,
                                      useDemographicsEthnicity = TRUE,
                                      useDemographicsIndexYear = TRUE,
                                      useDemographicsIndexMonth = TRUE,
                                      useDemographicsPriorObservationTime = TRUE,
                                      useDemographicsPostObservationTime = TRUE,
                                      useDemographicsTimeInCohort = TRUE,
                                      useConditionOccurrenceAnyTimePrior = TRUE,
                                      useConditionOccurrenceLongTerm = TRUE,
                                      useConditionOccurrenceMediumTerm = TRUE,
                                      useConditionOccurrenceShortTerm = TRUE,
                                      useConditionOccurrenceInpatientAnyTimePrior = TRUE,
                                      useConditionOccurrenceInpatientLongTerm = TRUE,
                                      useConditionOccurrenceInpatientMediumTerm = TRUE,
                                      useConditionOccurrenceInpatientShortTerm = TRUE,
                                      useConditionEraAnyTimePrior = TRUE,
                                      useConditionEraLongTerm = TRUE,
                                      useConditionEraMediumTerm = TRUE,
                                      useConditionEraShortTerm = TRUE,
                                      useConditionEraOverlapping = TRUE,
                                      useConditionEraStartLongTerm = TRUE,
                                      useConditionEraStartMediumTerm = TRUE,
                                      useConditionEraStartShortTerm = TRUE,
                                      useConditionGroupEraAnyTimePrior = TRUE,
                                      useConditionGroupEraLongTerm = TRUE,
                                      useConditionGroupEraMediumTerm = TRUE,
                                      useConditionGroupEraShortTerm = TRUE,
                                      useConditionGroupEraOverlapping = TRUE,
                                      useConditionGroupEraStartLongTerm = TRUE,
                                      useConditionGroupEraStartMediumTerm = TRUE,
                                      useConditionGroupEraStartShortTerm = TRUE,
                                      useDrugExposureAnyTimePrior = TRUE,
                                      useDrugExposureLongTerm = TRUE,
                                      useDrugExposureMediumTerm = TRUE,
                                      useDrugExposureShortTerm = TRUE,
                                      useDrugEraAnyTimePrior = TRUE,
                                      useDrugEraLongTerm = TRUE,
                                      useDrugEraMediumTerm = TRUE,
                                      useDrugEraShortTerm = TRUE,
                                      useDrugEraOverlapping = TRUE,
                                      useDrugEraStartLongTerm = TRUE,
                                      useDrugEraStartMediumTerm = TRUE,
                                      useDrugEraStartShortTerm = TRUE,
                                      useDrugGroupEraAnyTimePrior = TRUE,
                                      useDrugGroupEraLongTerm = TRUE,
                                      useDrugGroupEraMediumTerm = TRUE,
                                      useDrugGroupEraShortTerm = TRUE,
                                      useDrugGroupEraOverlapping = TRUE,
                                      useDrugGroupEraStartLongTerm = TRUE,
                                      useDrugGroupEraStartMediumTerm = TRUE,
                                      useDrugGroupEraStartShortTerm = TRUE,
                                      useProcedureOccurrenceAnyTimePrior = TRUE,
                                      useProcedureOccurrenceLongTerm = TRUE,
                                      useProcedureOccurrenceMediumTerm = TRUE,
                                      useProcedureOccurrenceShortTerm = TRUE,
                                      useDeviceExposureAnyTimePrior = TRUE,
                                      useDeviceExposureLongTerm = TRUE,
                                      useDeviceExposureMediumTerm = TRUE,
                                      useDeviceExposureShortTerm = TRUE,
                                      useMeasurementAnyTimePrior = TRUE,
                                      useMeasurementLongTerm = TRUE,
                                      useMeasurementMediumTerm = TRUE,
                                      useMeasurementShortTerm = TRUE,
                                      useMeasurementValueAnyTimePrior = TRUE,
                                      useMeasurementValueLongTerm = TRUE,
                                      useMeasurementValueMediumTerm = TRUE,
                                      useMeasurementValueShortTerm = TRUE,
                                      useMeasurementRangeGroupAnyTimePrior = TRUE,
                                      useMeasurementRangeGroupLongTerm = TRUE,
                                      useMeasurementRangeGroupMediumTerm = TRUE,
                                      useMeasurementRangeGroupShortTerm = TRUE,
                                      useObservationAnyTimePrior = TRUE,
                                      useObservationLongTerm = TRUE,
                                      useObservationMediumTerm = TRUE,
                                      useObservationShortTerm = TRUE,
                                      useCharlsonIndex = TRUE,
                                      useDcsi = TRUE,
                                      useChads2 = TRUE,
                                      useChads2Vasc = TRUE,
                                      useDistinctConditionCountLongTerm = TRUE,
                                      useDistinctConditionCountMediumTerm = TRUE,
                                      useDistinctConditionCountShortTerm = TRUE,
                                      useDistinctIngredientCountLongTerm = TRUE,
                                      useDistinctIngredientCountMediumTerm = TRUE,
                                      useDistinctIngredientCountShortTerm = TRUE,
                                      useDistinctProcedureCountLongTerm = TRUE,
                                      useDistinctProcedureCountMediumTerm = TRUE,
                                      useDistinctProcedureCountShortTerm = TRUE,
                                      useDistinctMeasurementCountLongTerm = TRUE,
                                      useDistinctMeasurementCountMediumTerm = TRUE,
                                      useDistinctMeasurementCountShortTerm = TRUE,
                                      useVisitCountLongTerm = TRUE,
                                      useVisitCountMediumTerm = TRUE,
                                      useVisitCountShortTerm = TRUE,
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
                                                       cohortTable = "cohorts_of_interest",
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings))
  return(covariateData)
}

test_that(paste("Run all analysis at per-person level on ", getOption("dbms")), {
  if (getOption("dbms") == "postgresql") {
    connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                                 user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                                 server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "sql server") {
    connectionDetails <- createConnectionDetails(dbms = "sql server",
                                                 user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                                 server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "oracle") {
    connectionDetails <- createConnectionDetails(dbms = "oracle",
                                                 user = Sys.getenv("CDM5_ORACLE_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                                 server = Sys.getenv("CDM5_ORACLE_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
})

runExtractionAggregated <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- SqlRender::loadRenderTranslateSql("cohortsOfInterest.sql",
                                           packageName = "FeatureExtraction",
                                           dbms = connectionDetails$dbms,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           resultsDatabaseSchema = ohdsiDatabaseSchema)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
  settings <- createCovariateSettings(useDemographicsGender = TRUE,
                                      useDemographicsAge = TRUE,
                                      useDemographicsAgeGroup = TRUE,
                                      useDemographicsRace = TRUE,
                                      useDemographicsEthnicity = TRUE,
                                      useDemographicsIndexYear = TRUE,
                                      useDemographicsIndexMonth = TRUE,
                                      useDemographicsPriorObservationTime = TRUE,
                                      useDemographicsPostObservationTime = TRUE,
                                      useDemographicsTimeInCohort = TRUE,
                                      useConditionOccurrenceAnyTimePrior = TRUE,
                                      useConditionOccurrenceLongTerm = TRUE,
                                      useConditionOccurrenceMediumTerm = TRUE,
                                      useConditionOccurrenceShortTerm = TRUE,
                                      useConditionOccurrenceInpatientAnyTimePrior = TRUE,
                                      useConditionOccurrenceInpatientLongTerm = TRUE,
                                      useConditionOccurrenceInpatientMediumTerm = TRUE,
                                      useConditionOccurrenceInpatientShortTerm = TRUE,
                                      useConditionEraAnyTimePrior = TRUE,
                                      useConditionEraLongTerm = TRUE,
                                      useConditionEraMediumTerm = TRUE,
                                      useConditionEraShortTerm = TRUE,
                                      useConditionEraOverlapping = TRUE,
                                      useConditionEraStartLongTerm = TRUE,
                                      useConditionEraStartMediumTerm = TRUE,
                                      useConditionEraStartShortTerm = TRUE,
                                      useConditionGroupEraAnyTimePrior = TRUE,
                                      useConditionGroupEraLongTerm = TRUE,
                                      useConditionGroupEraMediumTerm = TRUE,
                                      useConditionGroupEraShortTerm = TRUE,
                                      useConditionGroupEraOverlapping = TRUE,
                                      useConditionGroupEraStartLongTerm = TRUE,
                                      useConditionGroupEraStartMediumTerm = TRUE,
                                      useConditionGroupEraStartShortTerm = TRUE,
                                      useDrugExposureAnyTimePrior = TRUE,
                                      useDrugExposureLongTerm = TRUE,
                                      useDrugExposureMediumTerm = TRUE,
                                      useDrugExposureShortTerm = TRUE,
                                      useDrugEraAnyTimePrior = TRUE,
                                      useDrugEraLongTerm = TRUE,
                                      useDrugEraMediumTerm = TRUE,
                                      useDrugEraShortTerm = TRUE,
                                      useDrugEraOverlapping = TRUE,
                                      useDrugEraStartLongTerm = TRUE,
                                      useDrugEraStartMediumTerm = TRUE,
                                      useDrugEraStartShortTerm = TRUE,
                                      useDrugGroupEraAnyTimePrior = TRUE,
                                      useDrugGroupEraLongTerm = TRUE,
                                      useDrugGroupEraMediumTerm = TRUE,
                                      useDrugGroupEraShortTerm = TRUE,
                                      useDrugGroupEraOverlapping = TRUE,
                                      useDrugGroupEraStartLongTerm = TRUE,
                                      useDrugGroupEraStartMediumTerm = TRUE,
                                      useDrugGroupEraStartShortTerm = TRUE,
                                      useProcedureOccurrenceAnyTimePrior = TRUE,
                                      useProcedureOccurrenceLongTerm = TRUE,
                                      useProcedureOccurrenceMediumTerm = TRUE,
                                      useProcedureOccurrenceShortTerm = TRUE,
                                      useDeviceExposureAnyTimePrior = TRUE,
                                      useDeviceExposureLongTerm = TRUE,
                                      useDeviceExposureMediumTerm = TRUE,
                                      useDeviceExposureShortTerm = TRUE,
                                      useMeasurementAnyTimePrior = TRUE,
                                      useMeasurementLongTerm = TRUE,
                                      useMeasurementMediumTerm = TRUE,
                                      useMeasurementShortTerm = TRUE,
                                      useMeasurementValueAnyTimePrior = TRUE,
                                      useMeasurementValueLongTerm = TRUE,
                                      useMeasurementValueMediumTerm = TRUE,
                                      useMeasurementValueShortTerm = TRUE,
                                      useMeasurementRangeGroupAnyTimePrior = TRUE,
                                      useMeasurementRangeGroupLongTerm = TRUE,
                                      useMeasurementRangeGroupMediumTerm = TRUE,
                                      useMeasurementRangeGroupShortTerm = TRUE,
                                      useObservationAnyTimePrior = TRUE,
                                      useObservationLongTerm = TRUE,
                                      useObservationMediumTerm = TRUE,
                                      useObservationShortTerm = TRUE,
                                      useCharlsonIndex = TRUE,
                                      useDcsi = TRUE,
                                      useChads2 = TRUE,
                                      useChads2Vasc = TRUE,
                                      useDistinctConditionCountLongTerm = TRUE,
                                      useDistinctConditionCountMediumTerm = TRUE,
                                      useDistinctConditionCountShortTerm = TRUE,
                                      useDistinctIngredientCountLongTerm = TRUE,
                                      useDistinctIngredientCountMediumTerm = TRUE,
                                      useDistinctIngredientCountShortTerm = TRUE,
                                      useDistinctProcedureCountLongTerm = TRUE,
                                      useDistinctProcedureCountMediumTerm = TRUE,
                                      useDistinctProcedureCountShortTerm = TRUE,
                                      useDistinctMeasurementCountLongTerm = TRUE,
                                      useDistinctMeasurementCountMediumTerm = TRUE,
                                      useDistinctMeasurementCountShortTerm = TRUE,
                                      useVisitCountLongTerm = TRUE,
                                      useVisitCountMediumTerm = TRUE,
                                      useVisitCountShortTerm = TRUE,
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
                                                       cohortTable = "cohorts_of_interest",
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings,
                                                       aggregated = TRUE))
  return(covariateData)
}

test_that(paste("Run all analysis at aggregated level on ", getOption("dbms")), {
  if (getOption("dbms") == "postgresql") {
    connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                                 user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                                 server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "sql server") {
    connectionDetails <- createConnectionDetails(dbms = "sql server",
                                                 user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                                 server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "oracle") {
    connectionDetails <- createConnectionDetails(dbms = "oracle",
                                                 user = Sys.getenv("CDM5_ORACLE_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                                 server = Sys.getenv("CDM5_ORACLE_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
})

runExtractionTemporalPerPerson <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- SqlRender::loadRenderTranslateSql("cohortsOfInterest.sql",
                                           packageName = "FeatureExtraction",
                                           dbms = connectionDetails$dbms,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           resultsDatabaseSchema = ohdsiDatabaseSchema)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
  settings <- createTemporalCovariateSettings(useDemographicsGender = TRUE,
                                              useDemographicsAge = TRUE,
                                              useDemographicsAgeGroup = TRUE,
                                              useDemographicsRace = TRUE,
                                              useDemographicsEthnicity = TRUE,
                                              useDemographicsIndexYear = TRUE,
                                              useDemographicsIndexMonth = TRUE,
                                              useDemographicsPriorObservationTime = TRUE,
                                              useDemographicsPostObservationTime = TRUE,
                                              useDemographicsTimeInCohort = TRUE,
                                              useConditionOccurrence = TRUE,
                                              useConditionOccurrenceInpatient = TRUE,
                                              useConditionEraStart = TRUE,
                                              useConditionEraOverlap = TRUE,
                                              useConditionEraGroupStart = TRUE,
                                              useConditionEraGroupOverlap = TRUE,
                                              useDrugExposure = TRUE,
                                              useDrugEraStart = TRUE,
                                              useDrugEraOverlap = TRUE,
                                              useDrugEraGroupStart = TRUE,
                                              useDrugEraGroupOverlap = TRUE,
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
                                              useDistinctConditionCount = TRUE,
                                              useDistinctIngredientCount = TRUE,
                                              useDistinctProcedureCount = TRUE,
                                              useDistinctMeasurementCount = TRUE,
                                              useVisitCount = TRUE,
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
                                                       cohortTable = "cohorts_of_interest",
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings))
  return(covariateData)
}

test_that(paste("Run all temporalanalysis at per-person level on ", getOption("dbms")), {
  if (getOption("dbms") == "postgresql") {
    connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                                 user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                                 server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "sql server") {
    connectionDetails <- createConnectionDetails(dbms = "sql server",
                                                 user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                                 server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "oracle") {
    connectionDetails <- createConnectionDetails(dbms = "oracle",
                                                 user = Sys.getenv("CDM5_ORACLE_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                                 server = Sys.getenv("CDM5_ORACLE_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
})

runExtractionTemporalAggregated <- function(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema) {
  connection <- DatabaseConnector::connect(connectionDetails)
  sql <- SqlRender::loadRenderTranslateSql("cohortsOfInterest.sql",
                                           packageName = "FeatureExtraction",
                                           dbms = connectionDetails$dbms,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           resultsDatabaseSchema = ohdsiDatabaseSchema)
  DatabaseConnector::executeSql(connection, sql)
  DatabaseConnector::disconnect(connection)
  settings <- createTemporalCovariateSettings(useDemographicsGender = TRUE,
                                              useDemographicsAge = TRUE,
                                              useDemographicsAgeGroup = TRUE,
                                              useDemographicsRace = TRUE,
                                              useDemographicsEthnicity = TRUE,
                                              useDemographicsIndexYear = TRUE,
                                              useDemographicsIndexMonth = TRUE,
                                              useDemographicsPriorObservationTime = TRUE,
                                              useDemographicsPostObservationTime = TRUE,
                                              useDemographicsTimeInCohort = TRUE,
                                              useConditionOccurrence = TRUE,
                                              useConditionOccurrenceInpatient = TRUE,
                                              useConditionEraStart = TRUE,
                                              useConditionEraOverlap = TRUE,
                                              useConditionEraGroupStart = TRUE,
                                              useConditionEraGroupOverlap = TRUE,
                                              useDrugExposure = TRUE,
                                              useDrugEraStart = TRUE,
                                              useDrugEraOverlap = TRUE,
                                              useDrugEraGroupStart = TRUE,
                                              useDrugEraGroupOverlap = TRUE,
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
                                              useDistinctConditionCount = TRUE,
                                              useDistinctIngredientCount = TRUE,
                                              useDistinctProcedureCount = TRUE,
                                              useDistinctMeasurementCount = TRUE,
                                              useVisitCount = TRUE,
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
                                                       cohortTable = "cohorts_of_interest",
                                                       cohortId = 1124300,
                                                       rowIdField = "subject_id",
                                                       covariateSettings = settings,
                                                       aggregated = TRUE))
  return(covariateData)
}

test_that(paste("Run all temporalanalysis at aggregated level on ", getOption("dbms")), {
  if (getOption("dbms") == "postgresql") {
    connectionDetails <- createConnectionDetails(dbms = "postgresql",
                                                 user = Sys.getenv("CDM5_POSTGRESQL_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_POSTGRESQL_PASSWORD")),
                                                 server = Sys.getenv("CDM5_POSTGRESQL_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "sql server") {
    connectionDetails <- createConnectionDetails(dbms = "sql server",
                                                 user = Sys.getenv("CDM5_SQL_SERVER_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_SQL_SERVER_PASSWORD")),
                                                 server = Sys.getenv("CDM5_SQL_SERVER_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
  
  if (getOption("dbms") == "oracle") {
    connectionDetails <- createConnectionDetails(dbms = "oracle",
                                                 user = Sys.getenv("CDM5_ORACLE_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_ORACLE_PASSWORD")),
                                                 server = Sys.getenv("CDM5_ORACLE_SERVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
})
# connection <- connect(details)
# expect_true(inherits(connection, "Connection"))
# expect_true(disconnect(connection))
# 
# querySql(connection, "SELECT COUNT(*) FROM person")
# querySql(connection, "SELECT COUNT(*) FROM ohdsi.dbo.cohorts_of_interest WHERE cohort_definition_id = 1124300")
# disconnect(connection)
