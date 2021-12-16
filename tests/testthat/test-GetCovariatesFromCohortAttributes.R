# This file covers the code in GetCovariatesFromCohortAttributes.R. 
# NOTE: Functionality is described in detail in the following vignette:
# http://ohdsi.github.io/FeatureExtraction/articles/CreatingCovariatesUsingCohortAttributes.html
#
# View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetCovariatesFromCohortAttributes.R", "tests/testthat/test-GetCovariatesFromCohortAttributes.R"))

connectionDetails <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connectionDetails)

# Helper function
createCohortAttribute <- function(connectionDetails, cohortDefinitionIds = c(1), cohortDatabaseSchema, cohortTable, cohortAttributeTable, attributeDefinitionTable) {
  sql <- SqlRender::readSql(system.file("sql/sql_server/LengthOfObsCohortAttr.sql", package = "FeatureExtraction"))
  sql <- SqlRender::render(sql = sql,
                           cdm_database_schema = cohortDatabaseSchema,
                           cohort_database_schema = cohortDatabaseSchema,
                           cohort_attribute_table = cohortAttributeTable,
                           attribute_definition_table = attributeDefinitionTable,
                           cohort_table = cohortTable,
                           cohort_definition_ids = cohortDefinitionIds)
  sql <- SqlRender::translate(sql = sql, targetDialect = connectionDetails$dbms, tempEmulationSchema = cohortDatabaseSchema)
  connection <- DatabaseConnector::connect(connectionDetails)
  DatabaseConnector::executeSql(connection, sql = sql)
  on.exit(DatabaseConnector::disconnect(connection))
}

test_that("getDbCohortAttrCovariatesData aggregation not supported check", {
  connection <- DatabaseConnector::connect(connectionDetails)
  expect_error(getDbCohortAttrCovariatesData(connection = connection,
                                             cdmDatabaseSchema = "main",
                                             covariateSettings = createDefaultCovariateSettings(),
                                             aggregated = TRUE))
  on.exit(DatabaseConnector::disconnect(connection))
})

test_that("getDbCohortAttrCovariatesData CDM v4 not supported check", {
  connection <- DatabaseConnector::connect(connectionDetails)
  expect_error(getDbCohortAttrCovariatesData(connection = connection,
                                             cdmDatabaseSchema = "main",
                                             cdmVersion = "4",
                                             covariateSettings = createDefaultCovariateSettings()))
  on.exit(DatabaseConnector::disconnect(connection))
})

test_that("getDbCohortAttrCovariatesData hasIncludedAttributes == 0", {
 # Ensure the attribute_definition table exists
 cohortDatabaseSchema <- "main"
 cohortTable <- "cohort"
 cohortAttributeTable <- "cohort_attribute"
 attributeDefinitionTable <- "attribute_definition"
 createCohortAttribute(connectionDetails = connectionDetails,
                       cohortTable = cohortTable,
                       cohortDefinitionIds = c(1),
                       cohortDatabaseSchema = cohortDatabaseSchema,
                       cohortAttributeTable = cohortAttributeTable,
                       attributeDefinitionTable = attributeDefinitionTable)
 covariateSettings <- createCohortAttrCovariateSettings(attrDatabaseSchema = cohortDatabaseSchema,
                                                        cohortAttrTable = cohortAttributeTable,
                                                        attrDefinitionTable = attributeDefinitionTable,
                                                        includeAttrIds = c(),
                                                        isBinary = FALSE,
                                                        missingMeansZero = FALSE)   
 connection <- DatabaseConnector::connect(connectionDetails)
 result <- getDbCohortAttrCovariatesData(connection = connection,
                                         cdmDatabaseSchema = "main",
                                         cohortTable = "cohort",
                                         covariateSettings = covariateSettings)
 expect_equal(class(result), "CovariateData")
 on.exit(DatabaseConnector::disconnect(connection))
})

test_that("getDbCohortAttrCovariatesData hasIncludedAttributes > 0", {
  # Ensure the attribute_definition table exists
  cohortDatabaseSchema <- "main"
  cohortTable <- "cohort"
  cohortAttributeTable <- "cohort_attribute"
  attributeDefinitionTable <- "attribute_definition"
  createCohortAttribute(connectionDetails = connectionDetails,
                        cohortTable = cohortTable,
                        cohortDefinitionIds = c(1),
                        cohortDatabaseSchema = cohortDatabaseSchema,
                        cohortAttributeTable = cohortAttributeTable,
                        attributeDefinitionTable = attributeDefinitionTable)
  covariateSettings <- createCohortAttrCovariateSettings(attrDatabaseSchema = cohortDatabaseSchema,
                                                         cohortAttrTable = cohortAttributeTable,
                                                         attrDefinitionTable = attributeDefinitionTable,
                                                         includeAttrIds = c(1),
                                                         isBinary = FALSE,
                                                         missingMeansZero = TRUE)   
  connection <- DatabaseConnector::connect(connectionDetails)
  result <- getDbCohortAttrCovariatesData(connection = connection,
                                          cdmDatabaseSchema = "main",
                                          cohortTable = "cohort",
                                          covariateSettings = covariateSettings)
  expect_equal(class(result), "CovariateData")
  on.exit(DatabaseConnector::disconnect(connection))
})

test_that("createCohortAttrCovariateSettings check", {
  result <- createCohortAttrCovariateSettings(attrDatabaseSchema = "main")
  expect_equal(class(result), "covariateSettings")
})


# Remove the Eunomia database:
unlink(connectionDetails$server())