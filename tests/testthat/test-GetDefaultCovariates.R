# This file covers the code in GetDefaultCovariates.R. View coverage for this file using
# library(testthat); library(FeatureExtraction)
# covr::file_report(covr::file_coverage("R/GetDefaultCovariates.R", "tests/testthat/test-GetDefaultCovariates.R"))

createDefaultCovariateSqlTodo <- function(covariateSettings, aggregated = FALSE) {
  packageFolders <- c(
    file.path(getwd(), "inst"),
    file.path(getwd(), "..", "..", "inst"),
    system.file("", package = "FeatureExtraction")
  )
  packageFolder <- packageFolders[dir.exists(file.path(packageFolders, "java"))][1]
  javaFolder <- file.path(packageFolder, "java")
  rJava::.jaddClassPath(list.files(javaFolder, pattern = "\\.jar$", full.names = TRUE))
  rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$init(packageFolder)
  json <- rJava::J("org.ohdsi.featureExtraction.FeatureExtraction")$createSql(
    FeatureExtraction:::.toJson(covariateSettings),
    aggregated,
    "#cohort_person",
    "row_id",
    rJava::.jarray(as.character(-1)),
    "cdm",
    "0"
  )
  jsonlite::fromJSON(json, simplifyVector = TRUE, simplifyDataFrame = FALSE)
}

test_that("Test exit conditions", {
  skip_on_cran()
  skip_if_not(dbms == "sqlite" && exists("eunomiaConnection"))

  # covariateSettings object type
  expect_error(getDbDefaultCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    covariateSettings = list(),
    targetDatabaseSchema = "main",
    targetCovariateTable = "cov",
    targetCovariateRefTable = "cov_ref",
    targetAnalysisRefTable = "cov_analysis_ref"
  ))
  # CDM 4 not supported
  expect_error(getDbDefaultCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    cdmVersion = "4",
    covariateSettings = createDefaultCovariateSettings(),
    targetDatabaseSchema = "main",
    targetCovariateTable = "cov",
    targetCovariateRefTable = "cov_ref",
    targetAnalysisRefTable = "cov_analysis_ref"
  ))

  # targetCovariateTable and aggregated not supported
  expect_error(getDbDefaultCovariateData(
    connection = eunomiaConnection,
    cdmDatabaseSchema = "main",
    cohortId = -1,
    covariateSettings = createDefaultCovariateSettings(),
    targetDatabaseSchema = "main",
    targetCovariateTable = "cov",
    targetCovariateRefTable = "cov_ref",
    targetAnalysisRefTable = "cov_analysis_ref",
    aggregated = TRUE
  ))
})

test_that("Non-aggregated feature SQL uses documented covariate data column order", {
  covariateSettings <- createCovariateSettings(useDemographicsGender = TRUE)
  todo <- createDefaultCovariateSqlTodo(covariateSettings = covariateSettings)

  expect_match(
    todo$sqlQueryFeatures,
    "^SELECT row_id,\n  covariate_id,\n  covariate_value\nFROM \\(",
    perl = TRUE
  )
  expect_false(grepl("^SELECT \\*\nFROM", todo$sqlQueryFeatures))
})

test_that("Aggregated feature SQL uses documented covariate data column order", {
  testCases <- list(
    nonTemporal = list(
      settings = createCovariateSettings(
        useDemographicsGender = TRUE,
        useDemographicsAge = TRUE
      ),
      binaryColumns = paste0(
        "^SELECT all_covariates\\.cohort_definition_id,\n",
        "  all_covariates\\.covariate_id,\n",
        "  all_covariates\\.sum_value,\n",
        "  CAST\\(all_covariates\\.sum_value / \\(1\\.0 \\* total\\.total_count\\) AS FLOAT\\) AS average_value\n",
        "FROM \\("
      ),
      continuousColumns = paste0(
        "^SELECT cohort_definition_id, covariate_id, count_value, min_value, max_value, ",
        "average_value, standard_deviation, median_value, p10_value, p25_value, p75_value, p90_value\n",
        "FROM \\("
      )
    ),
    temporal = list(
      settings = createTemporalCovariateSettings(
        useDemographicsGender = TRUE,
        useDemographicsAge = TRUE
      ),
      binaryColumns = paste0(
        "^SELECT all_covariates\\.cohort_definition_id,\n",
        "  all_covariates\\.covariate_id,\n",
        "  all_covariates\\.time_id,\n",
        "  all_covariates\\.sum_value,\n",
        "  CAST\\(all_covariates\\.sum_value / \\(1\\.0 \\* total\\.total_count\\) AS FLOAT\\) AS average_value\n",
        "FROM \\("
      ),
      continuousColumns = paste0(
        "^SELECT cohort_definition_id, covariate_id, count_value, min_value, max_value, ",
        "average_value, standard_deviation, median_value, p10_value, p25_value, p75_value, p90_value, time_id\n",
        "FROM \\("
      )
    ),
    temporalSequence = list(
      settings = createTemporalSequenceCovariateSettings(
        useDemographicsGender = TRUE,
        useDemographicsAge = TRUE
      ),
      binaryColumns = paste0(
        "^SELECT all_covariates\\.cohort_definition_id,\n",
        "  all_covariates\\.covariate_id,\n",
        "  all_covariates\\.time_id,\n",
        "  all_covariates\\.sum_value,\n",
        "  CAST\\(all_covariates\\.sum_value / \\(1\\.0 \\* total\\.total_count\\) AS FLOAT\\) AS average_value\n",
        "FROM \\("
      ),
      continuousColumns = paste0(
        "^SELECT cohort_definition_id, covariate_id, count_value, min_value, max_value, ",
        "average_value, standard_deviation, median_value, p10_value, p25_value, p75_value, p90_value, time_id\n",
        "FROM \\("
      )
    )
  )

  for (testCase in testCases) {
    todo <- createDefaultCovariateSqlTodo(
      covariateSettings = testCase$settings,
      aggregated = TRUE
    )

    expect_match(todo$sqlQueryFeatures, testCase$binaryColumns, perl = TRUE)
    expect_match(todo$sqlQueryContinuousFeatures, testCase$continuousColumns, perl = TRUE)
    expect_false(grepl("^SELECT \\*\nFROM", todo$sqlQueryFeatures))
    expect_false(grepl("^SELECT \\*\nFROM", todo$sqlQueryContinuousFeatures))
  }
})
