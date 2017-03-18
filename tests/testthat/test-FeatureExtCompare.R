#
#

library(DatabaseConnector)
library(SqlRender)

test_that("access", {
  print("This is a test of accessing the database")

  # connection details for the aws instance (password will be provided)
  dbms <- "redshift"
  user <- "synpuf_training"
  password <- Sys.getenv("SYNPUF_DB_PASSWD")
  schema="cdm"

  # for the 1% sample:
  server <- "ohdsi.cxmbbsphpllo.us-east-1.redshift.amazonaws.com/synpuf1pct"
  port <- 5439
  connectionDetails <- createConnectionDetails(dbms = dbms,
                                               user = user,
                                               password = password,
                                               server = server,
                                               port = port)
  connection <- connect(connectionDetails)
  
  print("done with query")
  
  covariateSettings <- FeatureExtraction::createCovariateSettings(
    useCovariateDemographics = TRUE,
    useCovariateDemographicsGender = TRUE,
    useCovariateDemographicsRace = TRUE,
    # useCovariateDemographicsEthnicity = TRUE,
    # useCovariateDemographicsAge = TRUE,
    # useCovariateDemographicsYear = TRUE,
    # useCovariateDemographicsMonth = TRUE,
    # useCovariateConditionOccurrence = TRUE,
    # useCovariateConditionOccurrence365d = TRUE,
    # useCovariateConditionOccurrence30d = TRUE,
    # useCovariateConditionOccurrenceInpt180d = TRUE,
    # useCovariateConditionEra = TRUE,
    # useCovariateConditionEraEver = TRUE,
    # useCovariateConditionEraOverlap = TRUE,
    # useCovariateConditionGroup = TRUE,
    # useCovariateConditionGroupMeddra = TRUE,
    # useCovariateConditionGroupSnomed = TRUE,
    useCovariateDrugExposure = TRUE,
    useCovariateDrugExposure365d = TRUE,
    # useCovariateDrugExposure30d = TRUE,
    # useCovariateDrugEra = TRUE,
    # useCovariateDrugEra365d = TRUE,
    # useCovariateDrugEra30d = TRUE,
    # useCovariateDrugEraOverlap = TRUE,
    # useCovariateDrugEraEver = TRUE,
    # useCovariateDrugGroup = TRUE,
    # useCovariateProcedureOccurrence = TRUE,
    # useCovariateProcedureOccurrence365d = TRUE,
    # useCovariateProcedureOccurrence30d = TRUE,
    # useCovariateProcedureGroup = TRUE,
    # useCovariateObservation = TRUE,
    # useCovariateObservation365d = TRUE,
    # useCovariateObservation30d = TRUE,
    # useCovariateObservationCount365d = TRUE,
    # useCovariateMeasurement = TRUE,
    # useCovariateMeasurement365d = TRUE,
    # useCovariateMeasurement30d = TRUE,
    # useCovariateMeasurementCount365d = TRUE,
    # useCovariateMeasurementBelow = TRUE,
    # useCovariateMeasurementAbove = TRUE,
    # useCovariateConceptCounts = TRUE,
    # useCovariateRiskScores = TRUE,
    # useCovariateRiskScoresCharlson = TRUE,
    # useCovariateRiskScoresDCSI = TRUE,
    # useCovariateRiskScoresCHADS2 = TRUE,
    # useCovariateRiskScoresCHADS2VASc = TRUE,
    # useCovariateInteractionYear = FALSE,
    # useCovariateInteractionMonth = FALSE,
    # excludedCovariateConceptIds = celecoxibDrugs,
    # includedCovariateConceptIds = c(),
    deleteCovariatesSmallCount = 2)

  baseStart<-Sys.time()
   # baseResult<- getDbDefaultCovariateData(connection,
   #                                        oracleTempSchema = NULL,
   #                                        schema,
   #                                        cdmVersion = "4",
   #                                        cohortTempTable = "temp_cohort",
   #                                        rowIdField = "subject_id",
   #                                        covariateSettings,
   #                                        sqlFile = "GetCovariates_old.sql")
   
  basetime <-Sys.time()- baseStart
 
  #ffdf
  
  
  testStart<-Sys.time()
  testResult<- getDbDefaultCovariateData(connection,
                                         oracleTempSchema = NULL,
                                         schema,
                                         cdmVersion = "5",
                                         cohortTempTable = "scratch.ftf_cohort",
                                         rowIdField = "subject_id",
                                         covariateSettings,
                                         sqlFile = "GetCovariates.sql")
  
  #testDF <-as.data.frame(testResult)
  #print(testDF)
  cat("Diff Time : ",basetime - (Sys.time()- baseStart))
})