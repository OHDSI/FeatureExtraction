library(FeatureExtraction)

options(andromedaTempFolder = "s:/andromedaTemp")

# Pdw ---------------------------------------------------------------------

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = keyring::key_get("pdwServer"),
                                                                port = keyring::key_get("pdwPort"))
cdmDatabaseSchema <- "CDM_IBM_MDCR_V1192.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "ohdsi_celecoxib_prediction"
oracleTempSchema <- NULL
cdmVersion <- "5"



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


# RedShift ---------------------------------

dbms <- "redshift"
user <- Sys.getenv("redShiftUser")
pw <- Sys.getenv("redShiftPassword")
cdmDatabaseSchema <- "cdm"
cohortDatabaseSchema <- "scratch_mschuemi"
cohortTable <- "informed_priors"
oracleTempSchema <- NULL
connectionString <- Sys.getenv("mdcrRedShiftConnectionString")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                connectionString = connectionString,
                                                                user = user,
                                                                password = pw)
cdmVersion <- "5"

outputFolder <- "S:/temp/CelecoxibPredictiveModelsPg"


# Popular drug: 1118084
# Medium drug: 945286
# Rare drug: 1125443
conn <- DatabaseConnector::connect(connectionDetails)
### Populate cohort table ###
sql <- "IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
DROP TABLE @cohort_database_schema.@cohort_table;
SELECT drug_concept_id AS cohort_definition_id, person_id AS subject_id, drug_era_start_date AS cohort_start_date, drug_era_end_date AS cohort_end_date, ROW_NUMBER() OVER (ORDER BY person_id, drug_era_start_date) AS row_id
INTO @cohort_database_schema.@cohort_table FROM @cdm_database_schema.drug_era 
WHERE drug_concept_id IN (740910, 945286);"
sql <- SqlRender::render(sql, 
                         cdm_database_schema = cdmDatabaseSchema,
                         cohort_database_schema = cohortDatabaseSchema,
                         cohort_table = cohortTable)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
DatabaseConnector::executeSql(conn, sql)

sql <- "SELECT cohort_definition_id, COUNT(*) FROM @cohort_database_schema.@cohort_table GROUP BY cohort_definition_id;"
sql <- SqlRender::render(sql,
                         cohort_database_schema = cohortDatabaseSchema,
                         cohort_table = cohortTable)
sql <- SqlRender::translate(sql, targetDialect = connectionDetails$dbms)
DatabaseConnector::querySql(conn, sql)
DatabaseConnector::disconnect(conn)

### Create covariateSettings ###

celecoxibDrugs <- 1118084
# x <- c(252351201, 2514584502, 2615790602, 440424201, 2212134701, 433950202, 40163038301, 42902283302, 380411101, 19115253302, 141508101, 2109262501, 440870101, 40175400301, 2212420701, 253321102, 2616540601, 40490966204, 198249204, 19003087302, 77069102, 259848101, 1201620402, 19035388301, 444084201, 2617130602, 40223423301, 4184252201, 2212996701, 40234152302, 19125485301, 21602471403, 4060101801, 442313204, 439502101, 1326303402, 440920202, 19040158302, 2414379501, 2313884502, 4204187204, 2721698801, 739209301, 376225102, 42742566701, 43021157201, 314131101, 2005962502, 133298201, 4157607204)
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
                                    useConditionOccurrencePrimaryInpatientLongTerm = TRUE,
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


covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = c(740910, 945286),
                           rowIdField = "row_id",
                           cohortTableIsTemp = FALSE,
                           covariateSettings = settings,
                           aggregated = TRUE)
covs$covariateRef %>%
  filter(covariateId > 15000)
covs$covariates[covs$covariates$covariateId == 4329847210, ]
# Exclude: sum = 2.883000e+03
# Not exclude: sum = 2.883000e+03
# Exclude after fix: sum = 2.538000e+03
system.time(
  saveCovariateData(covs, "s:/temp/covsHuge.zip")
)
saveCovariateData(covs, "s:/temp/covsAgg")
covariateData <- loadCovariateData("s:/temp/covsHuge.zip")
covariateData
print(covariateData)
summary(covariateData)
tidyCovs <- tidyCovariateData(covariateData)

tempCovariateData <- loadCovariateData("c:/temp/covs2.zip")


covs2 <- aggregateCovariates(covs)



settings2 <- createCovariateSettings(useDemographicsGender = TRUE)
covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = c(1),
                           rowIdField = "row_id",
                           cohortTableIsTemp = FALSE,
                           covariateSettings = list(settings, settings2),
                           aggregated = TRUE)
print(covs)
summary(covs)
print(covs$covariateRef, n = 100)
# Temporal covariates -----------------------------------------------
covariateSettings <- createTemporalCovariateSettings(useDemographicsGender = TRUE,
                                                     useMeasurementValue = TRUE)
covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = c(1),
                           rowIdField = "row_id",
                           cohortTableIsTemp = FALSE,
                           covariateSettings = covariateSettings,
                           aggregated = TRUE)
saveCovariateData(covs, "c:/temp/tempCovs")
covariateData <- loadCovariateData("c:/temp/tempCovs")
tidyCovs <- tidyCovariateData(covariateData)

agg <- aggregateCovariates(covs)

saveCovariateData(tidyCovs, "c:/temp/tidyCovs.zip")


# Aggregation ---------------------------------------------------------------------------------
covariateSettings <- createCovariateSettings(useDemographicsAge = TRUE,
                                             = TRUE)

covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = c(1),
                           rowIdField = "row_id",
                           cohortTableIsTemp = FALSE,
                           covariateSettings = covariateSettings,
                           aggregated = FALSE)

saveCovariateData(covs, "c:/temp/unaggregatedCovs.zip")

aggCovs <- getDbCovariateData(connectionDetails = connectionDetails,
                              oracleTempSchema = oracleTempSchema,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              cohortDatabaseSchema = cohortDatabaseSchema,
                              cohortTable = cohortTable,
                              cohortIds = c(1),
                              rowIdField = "row_id",
                              cohortTableIsTemp = FALSE,
                              covariateSettings = covariateSettings,
                              aggregated = TRUE)
saveCovariateData(aggCovs, "c:/temp/aggregatedCovs.zip")


covariateData <- loadCovariateData("c:/temp/unaggregatedCovs.zip")
aggCovs2 <- aggregateCovariates(covariateData)

aggCovs <- loadCovariateData("c:/temp/aggregatedCovs.zip")



aggCovs$covariates %>% collect()
aggCovs2$covariates %>% collect()

aggCovs$covariatesContinuous %>% collect()
aggCovs2$covariatesContinuous %>% collect()


# Storing data on server -----------------------------------------------------------------------
settings <- createCovariateSettings(useDemographicsGender = TRUE,
                                    useDemographicsAgeGroup = TRUE)
conn <- DatabaseConnector::connect(connectionDetails)
getDbDefaultCovariateData(connection = conn,
                          oracleTempSchema = oracleTempSchema,
                          cdmDatabaseSchema = cdmDatabaseSchema,
                          cohortTable = paste(cohortDatabaseSchema, cohortTable, sep = "."),
                          cohortIds = c(-1),
                          rowIdField = "row_id",
                          covariateSettings = settings,
                          targetCovariateTable = "#my_covs",
                          targetCovariateRefTable = "#my_cov_ref",
                          targetAnalysisRefTable = "#my_analysis_ref",
                          aggregated = FALSE)
querySql(conn, "SELECT TOP 100 * FROM #my_covs")
querySql(conn, "SELECT TOP 100 * FROM #my_cov_ref")
querySql(conn, "SELECT TOP 100 * FROM #my_analysis_ref")

DatabaseConnector::disconnect(conn)



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



# Table 1 -----------------------------------------------------------------

settings <- createCovariateSettings(useDemographicsAgeGroup = TRUE,
                                    useDemographicsGender = TRUE,
                                    useDemographicsEthnicity = TRUE,
                                    useConditionGroupEraLongTerm = TRUE,
                                    useDrugGroupEraLongTerm = TRUE,
                                    useCharlsonIndex = TRUE,
                                    useChads2Vasc = TRUE,
                                    useDcsi = TRUE)

covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortIds = c(1),
                           rowIdField = "row_id",
                           cohortTableIsTemp = FALSE,
                           covariateSettings = settings,
                           aggregated = TRUE)

saveCovariateData(covs, "c:/temp/covsTable1")

covariateData1 <- loadCovariateData("c:/temp/covsTable1")

tables <- createTable1(covariateData1, output = "one column", showCounts = T, showPercent = F)
tables <- createTable1(covariateData1, output = "two columns", showCounts = T, showPercent = F)

tables <- createTable1(covariateData1, covariateData1, output = "one column", showCounts = F, showPercent = T)
tables <- createTable1(covariateData1, covariateData1, output = "two columns", showCounts = T, showPercent = F)

write.csv(tables$part1, "c:/temp/table1Part1.csv", row.names = FALSE)
write.csv(tables$part2, "c:/temp/table1Part2.csv", row.names = FALSE)
print(tables$part1)


covariateData1 <- covariateData
covariateData2 <- covariateData

# Eunomia ------------------------------------------------------
library(FeatureExtraction)
library(Eunomia)
options(andromedaTempFolder = "c:/andromedaTemp")
connectionDetails <- getEunomiaConnectionDetails()
createCohorts(connectionDetails)

settings <- createCovariateSettings(useDemographicsGender = TRUE,
                                    useDemographicsAge = FALSE,
                                    useDemographicsAgeGroup = FALSE,
                                    useDemographicsRace = FALSE,
                                    useDemographicsEthnicity = FALSE,
                                    useDemographicsIndexYear = FALSE,
                                    useDemographicsIndexMonth = FALSE,
                                    useDemographicsPriorObservationTime = FALSE,
                                    useDemographicsPostObservationTime = FALSE,
                                    useDemographicsTimeInCohort = FALSE,
                                    useConditionOccurrenceAnyTimePrior = FALSE,
                                    useConditionOccurrenceLongTerm = FALSE,
                                    useConditionOccurrenceMediumTerm = FALSE,
                                    useConditionOccurrenceShortTerm = FALSE,
                                    useConditionEraAnyTimePrior = FALSE,
                                    useConditionEraLongTerm = FALSE,
                                    useConditionEraMediumTerm = FALSE,
                                    useConditionEraShortTerm = FALSE,
                                    useConditionEraOverlapping = FALSE,
                                    useConditionEraStartLongTerm = FALSE,
                                    useConditionEraStartMediumTerm = FALSE,
                                    useConditionEraStartShortTerm = FALSE,
                                    useConditionGroupEraAnyTimePrior = FALSE,
                                    useConditionGroupEraLongTerm = FALSE,
                                    useConditionGroupEraMediumTerm = FALSE,
                                    useConditionGroupEraShortTerm = FALSE,
                                    useConditionGroupEraOverlapping = FALSE,
                                    useConditionGroupEraStartLongTerm = FALSE,
                                    useConditionGroupEraStartMediumTerm = FALSE,
                                    useConditionGroupEraStartShortTerm = FALSE,
                                    useConditionOccurrencePrimaryInpatientLongTerm = FALSE,
                                    useDrugExposureAnyTimePrior = FALSE,
                                    useDrugExposureLongTerm = FALSE,
                                    useDrugExposureMediumTerm = FALSE,
                                    useDrugExposureShortTerm = FALSE,
                                    useDrugEraAnyTimePrior = FALSE,
                                    useDrugEraLongTerm = FALSE,
                                    useDrugEraMediumTerm = FALSE,
                                    useDrugEraShortTerm = FALSE,
                                    useDrugEraOverlapping = FALSE,
                                    useDrugEraStartLongTerm = FALSE,
                                    useDrugEraStartMediumTerm = FALSE,
                                    useDrugEraStartShortTerm = FALSE,
                                    useDrugGroupEraAnyTimePrior = FALSE,
                                    useDrugGroupEraLongTerm = FALSE,
                                    useDrugGroupEraMediumTerm = FALSE,
                                    useDrugGroupEraShortTerm = FALSE,
                                    useDrugGroupEraOverlapping = FALSE,
                                    useDrugGroupEraStartLongTerm = FALSE,
                                    useDrugGroupEraStartMediumTerm = FALSE,
                                    useDrugGroupEraStartShortTerm = FALSE,
                                    useProcedureOccurrenceAnyTimePrior = FALSE,
                                    useProcedureOccurrenceLongTerm = FALSE,
                                    useProcedureOccurrenceMediumTerm = FALSE,
                                    useProcedureOccurrenceShortTerm = FALSE,
                                    useDeviceExposureAnyTimePrior = FALSE,
                                    useDeviceExposureLongTerm = FALSE,
                                    useDeviceExposureMediumTerm = FALSE,
                                    useDeviceExposureShortTerm = FALSE,
                                    useMeasurementAnyTimePrior = FALSE,
                                    useMeasurementLongTerm = FALSE,
                                    useMeasurementMediumTerm = FALSE,
                                    useMeasurementShortTerm = FALSE,
                                    useMeasurementValueAnyTimePrior = FALSE,
                                    useMeasurementValueLongTerm = FALSE,
                                    useMeasurementValueMediumTerm = FALSE,
                                    useMeasurementValueShortTerm = FALSE,
                                    useMeasurementRangeGroupAnyTimePrior = FALSE,
                                    useMeasurementRangeGroupLongTerm = FALSE,
                                    useMeasurementRangeGroupMediumTerm = FALSE,
                                    useMeasurementRangeGroupShortTerm = FALSE,
                                    useObservationAnyTimePrior = FALSE,
                                    useObservationLongTerm = FALSE,
                                    useObservationMediumTerm = FALSE,
                                    useObservationShortTerm = FALSE,
                                    useCharlsonIndex = FALSE,
                                    useDcsi = FALSE,
                                    useChads2 = FALSE,
                                    useChads2Vasc = FALSE,
                                    useDistinctConditionCountLongTerm = FALSE,
                                    useDistinctConditionCountMediumTerm = FALSE,
                                    useDistinctConditionCountShortTerm = FALSE,
                                    useDistinctIngredientCountLongTerm = FALSE,
                                    useDistinctIngredientCountMediumTerm = FALSE,
                                    useDistinctIngredientCountShortTerm = FALSE,
                                    useDistinctProcedureCountLongTerm = FALSE,
                                    useDistinctProcedureCountMediumTerm = FALSE,
                                    useDistinctProcedureCountShortTerm = FALSE,
                                    useDistinctMeasurementCountLongTerm = FALSE,
                                    useDistinctMeasurementCountMediumTerm = FALSE,
                                    useDistinctMeasurementCountShortTerm = FALSE,
                                    useVisitCountLongTerm = FALSE,
                                    useVisitCountMediumTerm = FALSE,
                                    useVisitCountShortTerm = FALSE,
                                    longTermStartDays = -365,
                                    mediumTermStartDays = -180,
                                    shortTermStartDays = -30,
                                    endDays = 0,
                                    includedCovariateConceptIds = c(),
                                    addDescendantsToInclude = FALSE,
                                    excludedCovariateConceptIds = c(),
                                    addDescendantsToExclude = FALSE,
                                    includedCovariateIds = c()) 

covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           cdmDatabaseSchema = "main",
                           cohortDatabaseSchema = "main",
                           cohortTable = "cohort",
                           cohortIds = c(2^34),
                           covariateSettings = settings,
                           aggregated = TRUE)

collect(covs$covariatesContinuous)
collect(covs$covariates)
collect(covs$covariateRef) %>% filter(covariateId %% 1000 == 3)
x <- collect(covs$covariateRef) 
View(x)

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
                                            useDemographicsIndexYearMonth = TRUE,
                                            useConditionOccurrence = TRUE,
                                            useConditionOccurrencePrimaryInpatient = TRUE,
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
                                            useHfrs = TRUE,
                                            useDistinctConditionCount = TRUE,
                                            useDistinctIngredientCount = TRUE,
                                            useDistinctProcedureCount = TRUE,
                                            useDistinctMeasurementCount = TRUE,
                                            useDistinctObservationCount = TRUE,
                                            useVisitCount = TRUE,
                                            useVisitConceptCount = TRUE)
covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           cdmDatabaseSchema = "main",
                           cohortDatabaseSchema = "main",
                           cohortTable = "cohort",
                           cohortIds = c(1,2),
                           covariateSettings = settings,
                           aggregated = TRUE)

connection <- connect(connectionDetails)
querySql(connection, "SELECT * FROM main.cohort LIMIT 100")
