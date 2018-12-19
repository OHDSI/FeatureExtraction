library(FeatureExtraction)
options(fftempdir = "/home/chandryou/temp")
# setwd("s:/temp/pgProfile/")

# Pdw ---------------------------------------------------------------------
dbms <- "sql server"
user <- "chandryou"
pw <- "dbtmdcks12#"
server <- "128.1.99.53"
port <- NULL
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)
cdmDatabaseSchema <- "NHIS_NSC.dbo"
cohortDatabaseSchema <- "NHIS_NSC_result.dbo"
cohortTable <- "bleeding_cohort"
oracleTempSchema <- NULL
cdmVersion <- "5"

cohortId = 1117

settings<-createCovariateSettings(useHfrs = TRUE)
covs <- getDbCovariateData(connectionDetails = connectionDetails,
                           oracleTempSchema = oracleTempSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           cohortId = cohortId,
                           rowIdField = "subject_id",
                           covariateSettings = settings,
                           aggregated = FALSE)


