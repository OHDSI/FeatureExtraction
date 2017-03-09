library(SqlRender)
library(DatabaseConnector)
library(FeatureExtraction)
options(fftempdir = "s:/fftemp")


dbms <- "pdw"
user <- NULL
pw <- NULL
server <- "JRDUSAPSCTL01"
cdmDatabaseSchema <- "CDM_Truven_mdcr_V520.dbo"
resultsDatabaseSchema <- "scratch.dbo"
port <- 17001
cdmVersion <- "5"
extraSettings <- NULL

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
connection <- DatabaseConnector::connect(connectionDetails)

sql <- loadRenderTranslateSql("coxibVsNonselVsGiBleed.sql",
                              packageName = "CohortMethod",
                              dbms = dbms,
                              cdmDatabaseSchema = cdmDatabaseSchema,
                              resultsDatabaseSchema = resultsDatabaseSchema)
DatabaseConnector::executeSql(connection, sql)

# Check number of subjects per cohort:
sql <- "SELECT cohort_definition_id, COUNT(*) AS count FROM @resultsDatabaseSchema.coxibVsNonselVsGiBleed GROUP BY cohort_definition_id"
sql <- SqlRender::renderSql(sql, resultsDatabaseSchema = resultsDatabaseSchema)$sql
sql <- SqlRender::translateSql(sql, targetDialect = connectionDetails$dbms)$sql
DatabaseConnector::querySql(connection, sql)


settings <- createTemporalCovariateSettings(useCovariateConditionEraStart = FALSE,
                                            useCovariateConditionEraPresent = FALSE,
                                            useCovariateDrugEraStart = FALSE,
                                            useCovariateDrugEraPresent = TRUE,
                                            useCovariateMeasurementValue = FALSE,
                                            useCovariateProcedureOccurence = FALSE,
                                            useCovariateObservationOccurence = FALSE)

covarData <- getDbCovariateData(connectionDetails = connectionDetails,
                                cdmDatabaseSchema = cdmDatabaseSchema,
                                cdmVersion = 5,
                                cohortDatabaseSchema = resultsDatabaseSchema,
                                cohortTable = "coxibVsNonselVsGiBleed",
                                cohortIds = 1,
                                rowIdField = "subject_id",
                                cohortTableIsTemp = FALSE,
                                covariateSettings = settings,
                                normalize = FALSE)
                                
                                
covarData$covariates
covarData$covariateRef
covarData$timePeriods
