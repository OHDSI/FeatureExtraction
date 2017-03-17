#
#

test_that("access", {
  print("This is a test of accessing the database")
  # script to connect to the hack-a-thon SYNPUF database in Amazon AWS
  # thanks to Lee Evans!
  
  # On Windows, make sure RTools is installed.
  # The DatabaseConnector and SqlRender packages require Java. Java can be downloaded from http://www.java.com.
  # In R, use the following commands to download and install some packages:
  
  #install.packages("devtools")
  #library(devtools)
  #install_github("ohdsi/OhdsiRTools") 
  #install_github("ohdsi/SqlRender")
  #install_github("ohdsi/DatabaseConnector")
  
  library(DatabaseConnector)
  library(SqlRender)
  
  # connection details for the aws instance (password will be provided)
  dbms <- "redshift"
  user <- "synpuf_training"
  password <- "Abc12345!" #Sys.getenv('dbpasswd')
  schema="cdm"
  
  # for the 1000 sample:
  #server <- "ohdsi.cxmbbsphpllo.us-east-1.redshift.amazonaws.com/synpuf1k"
  
  # for the 1% sample:
  server <- "ohdsi.cxmbbsphpllo.us-east-1.redshift.amazonaws.com/synpuf1pct"
  port <- 5439
  connectionDetails <- createConnectionDetails(dbms = dbms,
                                               user = user,
                                               password = password,
                                               server = server,
                                               port = port)
  connection <- connect(connectionDetails)
  
  sql <- translateSql("select * from cdm.person limit 100", targetDialect = connectionDetails$dbms)$sql
  result <- querySql(connection, sql)
  
  # The cdm schema contains all the cdm tabels and vocabulary and is read only
  # There is "scratch" schema that is writable in which you can create your own tables.
  # Please add your name in the table name to not clash with other participants, e.g rijnbeek-cohort
  
 # print(result)
  
  print("done with query")
  covariateSettings <- FeatureExtraction::createCovariateSettings(
    useCovariateDemographics = TRUE,
    useCovariateDemographicsGender = TRUE,
    # useCovariateDemographicsGender = TRUE,
    # useCovariateDemographicsGender = TRUE,
    # useCovariateDemographicsRace = TRUE,
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
    # useCovariateDrugExposure = TRUE,
    # useCovariateDrugExposure365d = TRUE,
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
    deleteCovariatesSmallCount = 100)

  baseStart<-Sys.time()
   baseResult<- getDbDefaultCovariateData(connection,
                                          oracleTempSchema = NULL,
                                          schema,
                                          cdmVersion = "4",
                                          cohortTempTable = "cohort_person",
                                          rowIdField = "subject_id",
                                          covariateSettings,
                                          sqlFile = "GetCovariates_old.sql")
   
  basetime <-Sys.time()- baseStart
 
  #ffdf
  
  
  testStart<-Sys.time()
  testResult<- getDbDefaultCovariateData(connection,
                                         oracleTempSchema = NULL,
                                         schema,
                                         cdmVersion = "5",
                                         cohortTempTable = "cohort",
                                         rowIdField = "subject_id",
                                         covariateSettings,
                                         sqlFile = "GetCovariates.sql")
  
  cat("Diff Time : ",basetime - (Sys.time()- baseStart))
  #require(sqldf)
  
  #a1NotIna2 <- sqldf("SELECT * FROM testResult EXCEPT SELECT * FROM testResult")
  #a1NotIna2
}
)