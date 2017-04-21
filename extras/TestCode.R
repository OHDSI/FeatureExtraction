library(FeatureExtraction)
options(fftempdir = "s:/FFtemp")

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

### Create covariateSettings ###

sql <- "SELECT descendant_concept_id FROM @cdm_database_schema.concept_ancestor WHERE ancestor_concept_id = 1118084"

sql <- SqlRender::renderSql(sql, cdm_database_schema = cdmDatabaseSchema)$sql

sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql

cids <- DatabaseConnector::querySql(conn, sql)

celecoxibDrugs <- celecoxibDrugs[, 1]

celecoxibDrugs <- 1118084


RJDBC::dbDisconnect(conn)

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
                                                                excludedCovariateConceptIds = celecoxibDrugs,
                                                                addDescendantsToExclude = TRUE,
                                                                includedCovariateConceptIds = c(),
                                                                addDescendantsToInclude = TRUE,
                                                                deleteCovariatesSmallCount = 100)

covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmVersion = cdmVersion,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = 1,
                           cohortTableIsTemp = FALSE,
                           covariateSettings = covariateSettings,
                           normalize = TRUE)
any(covs$covariateRef$conceptId %in% cids)
summary(covs)
saveCovariateData(covs, "s:/temp/covsOld")
