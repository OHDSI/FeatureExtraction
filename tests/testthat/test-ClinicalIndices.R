library(testthat)
library(FeatureExtraction)

test_that("CHADS2-VASc quartiles are calculated within each cohort", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  syntheticPersonIds <- c(-334001L, -334002L)
  DatabaseConnector::executeSql(
    connection = eunomiaConnection,
    sql = paste0(
      "DELETE FROM ", eunomiaCdmDatabaseSchema,
      ".person WHERE person_id IN (", paste(syntheticPersonIds, collapse = ", "), ")"
    )
  )
  on.exit(
    DatabaseConnector::executeSql(
      connection = eunomiaConnection,
      sql = paste0(
        "DELETE FROM ", eunomiaCdmDatabaseSchema,
        ".person WHERE person_id IN (", paste(syntheticPersonIds, collapse = ", "), ")"
      )
    ),
    add = TRUE
  )
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = "person",
    databaseSchema = eunomiaCdmDatabaseSchema,
    data = data.frame(
      personId = syntheticPersonIds,
      genderConceptId = c(8507L, 8507L),
      yearOfBirth = c(1900L, 2000L),
      raceConceptId = c(0L, 0L),
      ethnicityConceptId = c(0L, 0L)
    ),
    dropTableIfExists = FALSE,
    tempTable = FALSE,
    createTable = FALSE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )

  cohort <- data.frame(
    cohortDefinitionId = c(1, 2),
    subjectId = syntheticPersonIds,
    cohortStartDate = as.Date("2020-01-01"),
    cohortEndDate = as.Date("2020-01-01")
  )
  cohortTableName <- paste0("#chads2vasc_", tableSuffix)
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = cohortTableName,
    data = cohort,
    dropTableIfExists = TRUE,
    tempTable = TRUE,
    createTable = TRUE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )

  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTable = cohortTableName,
    cohortTableIsTemp = TRUE,
    cohortIds = c(1, 2),
    covariateSettings = createCovariateSettings(useChads2Vasc = TRUE),
    aggregated = TRUE
  )
  on.exit(Andromeda::close(covariateData), add = TRUE)

  summaries <- dplyr::collect(covariateData$covariatesContinuous)
  summaries <- summaries[summaries$covariateId == 1904, ]

  expect_equal(nrow(summaries), 2)
  elderlySummary <- summaries[summaries$cohortDefinitionId == 1, ]
  youngSummary <- summaries[summaries$cohortDefinitionId == 2, ]

  # The elderly person receives two age points. The young male cohort has
  # neither age, sex, nor condition-derived points. Before the cohort-keyed
  # join, its zero-score distribution could set the elderly cohort's quartiles
  # to zero.
  expect_equal(youngSummary$maxValue, 0)
  expect_true(all(c(
    elderlySummary$minValue,
    elderlySummary$p25Value,
    elderlySummary$medianValue,
    elderlySummary$p75Value
  ) >= 2))
})

test_that("Charlson applies hierarchy and includes zero-score people in standard deviation", {
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  anyMalignancyConcept <- DatabaseConnector::querySql(
    connection = eunomiaConnection,
    sql = "
      SELECT descendant_concept_id
      FROM main.concept_ancestor
      WHERE ancestor_concept_id = 443392
      LIMIT 1",
    snakeCaseToCamelCase = TRUE
  )
  metastaticTumorConcept <- DatabaseConnector::querySql(
    connection = eunomiaConnection,
    sql = "
      SELECT descendant_concept_id
      FROM main.concept_ancestor
      WHERE ancestor_concept_id = 432851
      LIMIT 1",
    snakeCaseToCamelCase = TRUE
  )
  skip_if(nrow(anyMalignancyConcept) == 0 || nrow(metastaticTumorConcept) == 0,
    "Eunomia does not contain the required Charlson concepts"
  )

  syntheticPersonIds <- c(-334003L, -334004L)
  syntheticConditionEraIds <- c(-334003L, -334004L)
  DatabaseConnector::executeSql(
    connection = eunomiaConnection,
    sql = paste0(
      "DELETE FROM ", eunomiaCdmDatabaseSchema,
      ".condition_era WHERE person_id IN (", paste(syntheticPersonIds, collapse = ", "), "); ",
      "DELETE FROM ", eunomiaCdmDatabaseSchema,
      ".person WHERE person_id IN (", paste(syntheticPersonIds, collapse = ", "), ")"
    )
  )
  on.exit({
    DatabaseConnector::executeSql(
      connection = eunomiaConnection,
      sql = paste0(
        "DELETE FROM ", eunomiaCdmDatabaseSchema,
        ".condition_era WHERE person_id IN (", paste(syntheticPersonIds, collapse = ", "), "); ",
        "DELETE FROM ", eunomiaCdmDatabaseSchema,
        ".person WHERE person_id IN (", paste(syntheticPersonIds, collapse = ", "), ")"
      )
    )
  }, add = TRUE)
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = "person",
    databaseSchema = eunomiaCdmDatabaseSchema,
    data = data.frame(
      personId = syntheticPersonIds,
      genderConceptId = c(8507L, 8507L),
      yearOfBirth = c(1970L, 1970L),
      raceConceptId = c(0L, 0L),
      ethnicityConceptId = c(0L, 0L)
    ),
    dropTableIfExists = FALSE,
    tempTable = FALSE,
    createTable = FALSE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = "condition_era",
    databaseSchema = eunomiaCdmDatabaseSchema,
    data = data.frame(
      conditionEraId = syntheticConditionEraIds,
      personId = rep(syntheticPersonIds[1], 2),
      conditionConceptId = c(
        anyMalignancyConcept$descendantConceptId[1],
        metastaticTumorConcept$descendantConceptId[1]
      ),
      conditionEraStartDate = as.Date(c("2019-01-01", "2019-01-01")),
      conditionEraEndDate = as.Date(c("2019-01-01", "2019-01-01")),
      conditionOccurrenceCount = c(1L, 1L)
    ),
    dropTableIfExists = FALSE,
    tempTable = FALSE,
    createTable = FALSE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )

  cohortTableName <- paste0("#charlson_", tableSuffix)
  DatabaseConnector::insertTable(
    connection = eunomiaConnection,
    tableName = cohortTableName,
    data = data.frame(
      cohortDefinitionId = c(1, 1),
      subjectId = syntheticPersonIds,
      cohortStartDate = as.Date("2020-01-01"),
      cohortEndDate = as.Date("2020-01-01")
    ),
    dropTableIfExists = TRUE,
    tempTable = TRUE,
    createTable = TRUE,
    progressBar = FALSE,
    camelCaseToSnakeCase = TRUE
  )
  covariateData <- getDbCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = eunomiaCdmDatabaseSchema,
    cohortTable = cohortTableName,
    cohortTableIsTemp = TRUE,
    cohortIds = 1,
    covariateSettings = createCovariateSettings(useCharlsonIndex = TRUE),
    aggregated = TRUE
  )
  on.exit(Andromeda::close(covariateData), add = TRUE)

  summary <- dplyr::collect(covariateData$covariatesContinuous)
  summary <- summary[summary$covariateId == 1901, ]

  expect_equal(summary$maxValue, 6)
  expect_equal(summary$averageValue, 3)
  expect_equal(summary$standardDeviation, stats::sd(c(6, 0)))
})
