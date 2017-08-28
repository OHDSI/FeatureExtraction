library(FeatureExtraction)
options(fftempdir = "s:/FFtemp")


# Pdw ---------------------------------------------------------------------
dbms <- "pdw"
user <- NULL
pw <- NULL
server <- "JRDUSAPSCTL01"
port <- 17001
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
cdmDatabaseSchema <- "cdm_truven_mdcd_v521.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "ohdsi_celecoxib_prediction"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/CelecoxibPredictiveModels"



# PostgreSQL --------------------------------------------------------------
dbms <- "postgresql"
user <- "postgres"
pw <- Sys.getenv("pwPostgres")
server <- "localhost/ohdsi"
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw)
cdmDatabaseSchema <- "cdm_synpuf"
cohortDatabaseSchema <- "scratch"
cohortTable <- "ohdsi_celecoxib_prediction"
oracleTempSchema <- NULL
cdmVersion <- "5"
outputFolder <- "S:/temp/CelecoxibPredictiveModelsPg"


conn <- DatabaseConnector::connect(connectionDetails)
### Populate cohort table ###
sql <- "IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
DROP TABLE @cohort_database_schema.@cohort_table;
SELECT 1 AS cohort_definition_id, person_id AS subject_id, drug_era_start_date AS cohort_start_date 
INTO @cohort_database_schema.@cohort_table FROM @cdm_database_schema.drug_era 
WHERE drug_concept_id = 1118084;"
sql <- SqlRender::renderSql(sql, 
                            cdm_database_schema = cdmDatabaseSchema,
                            cohort_database_schema = cohortDatabaseSchema,
                            cohort_table = cohortTable)$sql
sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
DatabaseConnector::executeSql(conn, sql)

sql <- "SELECT COUNT(*) FROM @cohort_database_schema.@cohort_table WHERE cohort_definition_id = 1"
sql <- SqlRender::renderSql(sql,
                            cohort_database_schema = cohortDatabaseSchema,
                            cohort_table = cohortTable)$sql
sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
DatabaseConnector::querySql(conn, sql)
DatabaseConnector::disconnect(conn)

### Create covariateSettings ###

celecoxibDrugs <- 1118084
# x <- c(252351201, 2514584502, 2615790602, 440424201, 2212134701, 433950202, 40163038301, 42902283302, 380411101, 19115253302, 141508101, 2109262501, 440870101, 40175400301, 2212420701, 253321102, 2616540601, 40490966204, 198249204, 19003087302, 77069102, 259848101, 1201620402, 19035388301, 444084201, 2617130602, 40223423301, 4184252201, 2212996701, 40234152302, 19125485301, 21602471403, 4060101801, 442313204, 439502101, 1326303402, 440920202, 19040158302, 2414379501, 2313884502, 4204187204, 2721698801, 739209301, 376225102, 42742566701, 43021157201, 314131101, 2005962502, 133298201, 4157607204)
covariateSettings <- createCovariateSettings(useDemographicsGender = TRUE,
                                             useDemographicsAge = TRUE,
                                             useDemographicsIndexYear = TRUE,
                                             useDemographicsIndexMonth = TRUE,
                                             useConditionOccurrenceLongTerm = TRUE,
                                             useConditionOccurrenceShortTerm = TRUE,
                                             useConditionEraLongTerm = TRUE,
                                             useConditionEraShortTerm = TRUE,
                                             useConditionGroupEraLongTerm = TRUE,
                                             useConditionGroupEraShortTerm = TRUE,
                                             useDrugExposureLongTerm = TRUE,
                                             useDrugExposureShortTerm = TRUE,
                                             useDrugEraLongTerm = TRUE,
                                             useDrugEraShortTerm = TRUE,
                                             useDrugGroupEraLongTerm = TRUE,
                                             useDrugGroupEraShortTerm = TRUE,
                                             useProcedureOccurrenceLongTerm = TRUE,
                                             useProcedureOccurrenceShortTerm = TRUE,
                                             useDeviceExposureLongTerm = TRUE,
                                             useDeviceExposureShortTerm = TRUE,
                                             useMeasurementLongTerm = TRUE,
                                             useMeasurementShortTerm = TRUE,
                                             useObservationLongTerm = TRUE,
                                             useObservationShortTerm = TRUE,
                                             useCharlsonIndex = TRUE,
                                             longTermStartDays = -365,
                                             shortTermStartDays = -30,
                                             endDays = 0,
                                             excludedCovariateConceptIds = c(),
                                             addDescendantsToExclude = FALSE,
                                             includedCovariateConceptIds = c(),
                                             addDescendantsToInclude = FALSE,
                                             includedCovariateIds = c())

# covariateSettings <- convertPrespecSettingsToDetailedSettings(covariateSettings)
covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = 1,
                           cohortTableIsTemp = FALSE,
                           covariateSettings = covariateSettings,
                           aggregated = TRUE)


covariateSettings <- createDefaultCovariateSettings()

covariateSettings <- FeatureExtraction::createTemporalCovariateSettings(useDemographicsGender = TRUE,
                                                                        useDemographicsIndexYear = FALSE,
                                                                        useDemographicsAge = FALSE,
                                                                        useDemographicsIndexMonth = FALSE,
                                                                        useConditionOccurrence = TRUE,
                                                                        useConditionEraStart = FALSE,
                                                                        useConditionEraOverlap = FALSE,
                                                                        useConditionEraGroupStart = FALSE,
                                                                        useConditionEraGroupOverlap = FALSE,
                                                                        useDrugExposure = FALSE,
                                                                        useDrugEraStart = FALSE,
                                                                        useDrugEraOverlap = FALSE,
                                                                        useDrugEraGroupStart = FALSE,
                                                                        useDrugEraGroupOverlap = FALSE,
                                                                        useProcedureOccurrence = FALSE,
                                                                        useDeviceExposure = FALSE,
                                                                        useMeasurement = FALSE,
                                                                        useObservation = FALSE,
                                                                        useCharlsonIndex = FALSE,
                                                                        temporalStartDays = -365:-1, 
                                                                        temporalEndDays = -365:-1, 
                                                                        includedCovariateConceptIds = c(), 
                                                                        addDescendantsToInclude = FALSE,
                                                                        excludedCovariateConceptIds = c(), 
                                                                        addDescendantsToExclude = FALSE,
                                                                        includedCovariateIds = c())

# covariateSettings <- convertPrespecSettingsToDetailedSettings(covariateSettings)

covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = 1,
                           cohortTableIsTemp = FALSE,
                           covariateSettings = covariateSettings,
                           aggregated = TRUE)


analysisDetails <- createAnalysisDetails(analysisId = 1,
                                         sqlFileName = "DemographicsGender.sql",
                                         parameters = list(analysisId = 1,
                                                           analysisName = "Gender",
                                                           domainId = "Demographics"),
                                         includedCovariateConceptIds = c(), 
                                         addDescendantsToInclude = FALSE,
                                         excludedCovariateConceptIds = c(), 
                                         addDescendantsToExclude = FALSE,
                                         includedCovariateIds = c())

covariateSettings <- createDetailedCovariateSettings(analyses = list(analysisDetails))
                      
covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = 1,
                           cohortTableIsTemp = FALSE,
                           covariateSettings = covariateSettings,
                           aggregated = TRUE)


# All features:
# Generating features took 2.65 mins
# Downloading data
# Downloading data took 7.57 mins

# Filtering at end:
# Generating features took 2.27 mins
# Downloading data
# Downloading data took 1.58 secs

# Filtering by concept ID instead of covariate ID:
# Generating features took 3.83 mins
# Downloading data
# Downloading data took 1.34 secs


# Hint: 1.51 mins

querySql(connection, "SELECT COUNT(*) FROM #cov_2 WHERE covariate_id IN (2, 1002, 2002, 3002, 4002, 5002, 6002, 7002, 8002, 9002, 10002, 11002, 12002, 13002, 14002, 15002, 16002, 17002, 18002)")
querySql(connection, "SELECT COUNT(*) FROM #cov_all WHERE covariate_id IN (2, 1002, 2002, 3002, 4002, 5002, 6002, 7002, 8002, 9002, 10002, 11002, 12002, 13002, 14002, 15002, 16002, 17002, 18002)")
summary(covs)
saveCovariateData(covs, "s:/temp/covs")
covariateData <- covs
covs <- loadCovariateData("s:/temp/covs")
covs2 <- tidyCovariateData(covs, normalize = TRUE, removeRedundancy = TRUE)

x <- ff::as.ram(covs$covariateRef)
covs <- loadCovariateData("s:/temp/covsOld")
library(ffbase)
covs$covariateRef[covs$covariateRef$analysisId == 4, ]


conn <- connect(connectionDetails)

x <- ff::as.ram(covs$covariateRef$covariateId)
x <- sample(x, 50)
paste(x, collapse = ", ")
x <- c(252351201, 2514584502, 2615790602, 440424201, 2212134701, 433950202, 40163038301, 42902283302, 380411101, 19115253302, 141508101, 2109262501, 440870101, 40175400301, 2212420701, 253321102, 2616540601, 40490966204, 198249204, 19003087302, 77069102, 259848101, 1201620402, 19035388301, 444084201, 2617130602, 40223423301, 4184252201, 2212996701, 40234152302, 19125485301, 21602471403, 4060101801, 442313204, 439502101, 1326303402, 440920202, 19040158302, 2414379501, 2313884502, 4204187204, 2721698801, 739209301, 376225102, 42742566701, 43021157201, 314131101, 2005962502, 133298201, 4157607204)

# deprecated --------------------------------------------------------------

covariateSettings <- FeatureExtraction::createCovariateSettings(useCovariateDemographics = TRUE,
                                                                useCovariateDemographicsGender = TRUE,
                                                                useCovariateDemographicsRace = TRUE,
                                                                useCovariateDemographicsEthnicity = TRUE,
                                                                useCovariateDemographicsAge = TRUE,
                                                                useCovariateDemographicsYear = TRUE,
                                                                useCovariateDemographicsMonth = TRUE,
                                                                useCovariateConditionOccurrence = TRUE,
                                                                useCovariateConditionOccurrence365d = TRUE,
                                                                useCovariateConditionOccurrence30d = TRUE,
                                                                useCovariateConditionOccurrenceInpt180d = TRUE,
                                                                useCovariateConditionEra = TRUE,
                                                                useCovariateConditionEraEver = TRUE,
                                                                useCovariateConditionEraOverlap = TRUE,
                                                                useCovariateConditionGroup = TRUE,
                                                                useCovariateConditionGroupMeddra = TRUE,
                                                                useCovariateConditionGroupSnomed = TRUE,
                                                                useCovariateDrugExposure = TRUE,
                                                                useCovariateDrugExposure365d = TRUE,
                                                                useCovariateDrugExposure30d = TRUE,
                                                                useCovariateDrugEra = TRUE,
                                                                useCovariateDrugEra365d = TRUE,
                                                                useCovariateDrugEra30d = TRUE,
                                                                useCovariateDrugEraOverlap = TRUE,
                                                                useCovariateDrugEraEver = TRUE,
                                                                useCovariateDrugGroup = TRUE,
                                                                useCovariateProcedureOccurrence = TRUE,
                                                                useCovariateProcedureOccurrence365d = TRUE,
                                                                useCovariateProcedureOccurrence30d = TRUE,
                                                                useCovariateProcedureGroup = TRUE,
                                                                useCovariateObservation = TRUE,
                                                                useCovariateObservation365d = TRUE,
                                                                useCovariateObservation30d = TRUE,
                                                                useCovariateObservationCount365d = TRUE,
                                                                useCovariateMeasurement = TRUE,
                                                                useCovariateMeasurement365d = TRUE,
                                                                useCovariateMeasurement30d = TRUE,
                                                                useCovariateMeasurementCount365d = TRUE,
                                                                useCovariateMeasurementBelow = TRUE,
                                                                useCovariateMeasurementAbove = TRUE,
                                                                useCovariateConceptCounts = TRUE,
                                                                useCovariateRiskScores = TRUE,
                                                                useCovariateRiskScoresCharlson = TRUE,
                                                                useCovariateRiskScoresDCSI = TRUE,
                                                                useCovariateRiskScoresCHADS2 = TRUE,
                                                                useCovariateRiskScoresCHADS2VASc = TRUE,
                                                                useCovariateInteractionYear = FALSE,
                                                                useCovariateInteractionMonth = FALSE,
                                                                excludedCovariateConceptIds = 1234,
                                                                includedCovariateConceptIds = c(),
                                                                deleteCovariatesSmallCount = 100)

