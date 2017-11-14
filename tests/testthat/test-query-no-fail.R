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
                                      useDemographicsPostObservationTime = FALSE,
                                      useDemographicsTimeInCohort = FALSE,
                                      useDemographicsIndexYearMonth = TRUE,
                                      useConditionOccurrenceAnyTimePrior = FALSE,
                                      useConditionOccurrenceLongTerm = FALSE,
                                      useConditionOccurrenceMediumTerm = FALSE,
                                      useConditionOccurrenceShortTerm = TRUE,
                                      useConditionOccurrenceInpatientAnyTimePrior = FALSE,
                                      useConditionOccurrenceInpatientLongTerm = FALSE,
                                      useConditionOccurrenceInpatientMediumTerm = FALSE,
                                      useConditionOccurrenceInpatientShortTerm = TRUE,
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
                                      useVisitCountLongTerm = FALSE,
                                      useVisitCountMediumTerm = FALSE,
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

  if (getOption("dbms") == "impala") {
    connectionDetails <- createConnectionDetails(dbms = "impala",
                                                 user = Sys.getenv("CDM5_IMPALA_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                                 server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                                 pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
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
                                      useDemographicsPostObservationTime = FALSE,
                                      useDemographicsTimeInCohort = FALSE,
                                      useDemographicsIndexYearMonth = TRUE,
                                      useConditionOccurrenceAnyTimePrior = FALSE,
                                      useConditionOccurrenceLongTerm = FALSE,
                                      useConditionOccurrenceMediumTerm = FALSE,
                                      useConditionOccurrenceShortTerm = TRUE,
                                      useConditionOccurrenceInpatientAnyTimePrior = FALSE,
                                      useConditionOccurrenceInpatientLongTerm = FALSE,
                                      useConditionOccurrenceInpatientMediumTerm = FALSE,
                                      useConditionOccurrenceInpatientShortTerm = TRUE,
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
                                      useVisitCountLongTerm = FALSE,
                                      useVisitCountMediumTerm = FALSE,
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

  if (getOption("dbms") == "impala") {
    connectionDetails <- createConnectionDetails(dbms = "impala",
                                                 user = Sys.getenv("CDM5_IMPALA_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                                 server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                                 pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
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

  if (getOption("dbms") == "impala") {
    connectionDetails <- createConnectionDetails(dbms = "impala",
                                                 user = Sys.getenv("CDM5_IMPALA_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                                 server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                                 pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
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

  if (getOption("dbms") == "impala") {
    connectionDetails <- createConnectionDetails(dbms = "impala",
                                                 user = Sys.getenv("CDM5_IMPALA_USER"),
                                                 password = URLdecode(Sys.getenv("CDM5_IMPALA_PASSWORD")),
                                                 server = Sys.getenv("CDM5_IMPALA_SERVER"),
                                                 pathToDriver = Sys.getenv("CDM5_IMPALA_PATH_TO_DRIVER"))
    cdmDatabaseSchema <- Sys.getenv("CDM5_IMPALA_CDM_SCHEMA")
    ohdsiDatabaseSchema <- Sys.getenv("CDM5_IMPALA_OHDSI_SCHEMA")
    covariateData <- runExtractionPerPerson(connectionDetails, cdmDatabaseSchema, ohdsiDatabaseSchema)
    expect_true(is(covariateData, "covariateData"))
  }
})
