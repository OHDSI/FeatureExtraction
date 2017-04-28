# @file GetDefaultCovariates.R
#
# Copyright 2017 Observational Health Data Sciences and Informatics
#
# This file is part of FeatureExtraction
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Get default covariate information from the database
#'
#' @description
#' Constructs a large default set of covariates for one or more cohorts using data in the CDM schema.
#' Includes covariates for all drugs, drug classes, condition, condition classes, procedures,
#' observations, etc.
#'
#' @param covariateSettings   An object of type \code{defaultCovariateSettings} as created using the
#'                            \code{\link{createCovariateSettings}} function.
#'
#' @template GetCovarParams
#'
#' @export
getDbDefaultCovariateData <- function(connection,
                                      oracleTempSchema = NULL,
                                      cdmDatabaseSchema,
                                      cdmVersion = "4",
                                      cohortTempTable = "cohort_person",
                                      rowIdField = "subject_id",
                                      covariateSettings) {
  if (substr(cohortTempTable, 1, 1) != "#") {
    cohortTempTable <- paste("#", cohortTempTable, sep = "")
  }
  if (!covariateSettings$useCovariateConditionGroupMeddra & !covariateSettings$useCovariateConditionGroupSnomed) {
    covariateSettings$useCovariateConditionGroup <- FALSE
  }
  
  if (cdmVersion == "4") {
    cohortDefinitionId <- "cohort_concept_id"
    conceptClassId <- "concept_class"
    measurement <- "observation"
  } else {
    cohortDefinitionId <- "cohort_definition_id"
    conceptClassId <- "concept_class_id"
    measurement <- "measurement"
  }
  
  if (is.null(covariateSettings$excludedCovariateConceptIds) || length(covariateSettings$excludedCovariateConceptIds) ==
      0) {
    hasExcludedCovariateConceptIds <- FALSE
  } else {
    if (!is.numeric(covariateSettings$excludedCovariateConceptIds))
      stop("excludedCovariateConceptIds must be a (vector of) numeric")
    hasExcludedCovariateConceptIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#excluded_cov",
                                   data = data.frame(concept_id = as.integer(covariateSettings$excludedCovariateConceptIds)),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
    if (covariateSettings$addDescendantsToExclude) {
      writeLines("Adding descendants to concepts to exclude")
      sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "IncludeDescendants.sql",
                                               packageName = "FeatureExtraction",
                                               dbms = attr(connection, "dbms"),
                                               oracleTempSchema = oracleTempSchema,
                                               cdm_database_schema = cdmDatabaseSchema,
                                               table_name = "#excluded_cov")
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }
  
  if (is.null(covariateSettings$includedCovariateConceptIds) || length(covariateSettings$includedCovariateConceptIds) ==
      0) {
    hasIncludedCovariateConceptIds <- FALSE
  } else {
    if (!is.numeric(covariateSettings$includedCovariateConceptIds))
      stop("includedCovariateConceptIds must be a (vector of) numeric")
    hasIncludedCovariateConceptIds <- TRUE
    DatabaseConnector::insertTable(connection,
                                   tableName = "#included_cov",
                                   data = data.frame(concept_id = as.integer(covariateSettings$includedCovariateConceptIds)),
                                   dropTableIfExists = TRUE,
                                   createTable = TRUE,
                                   tempTable = TRUE,
                                   oracleTempSchema = oracleTempSchema)
    if (covariateSettings$addDescendantsToInclude) {
      writeLines("Adding descendants to concepts to include")
      sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "IncludeDescendants.sql",
                                               packageName = "FeatureExtraction",
                                               dbms = attr(connection, "dbms"),
                                               oracleTempSchema = oracleTempSchema,
                                               cdm_database_schema = cdmDatabaseSchema,
                                               table_name = "#included_cov")
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }
  }
  writeLines("Constructing default covariates")
  renderedSql <- SqlRender::loadRenderTranslateSql("GetCovariates.sql",
                                                   packageName = "FeatureExtraction",
                                                   dbms = attr(connection, "dbms"),
                                                   oracleTempSchema = oracleTempSchema,
                                                   cdm_database_schema = cdmDatabaseSchema,
                                                   cdm_version = cdmVersion,
                                                   cohort_temp_table = cohortTempTable,
                                                   row_id_field = rowIdField,
                                                   cohort_definition_id = cohortDefinitionId,
                                                   concept_class_id = conceptClassId,
                                                   measurement = measurement,
                                                   use_covariate_demographics = covariateSettings$useCovariateDemographics,
                                                   use_covariate_demographics_gender = covariateSettings$useCovariateDemographicsGender,
                                                   use_covariate_demographics_race = covariateSettings$useCovariateDemographicsRace,
                                                   use_covariate_demographics_ethnicity = covariateSettings$useCovariateDemographicsEthnicity,
                                                   use_covariate_demographics_age = covariateSettings$useCovariateDemographicsAge,
                                                   use_covariate_demographics_year = covariateSettings$useCovariateDemographicsYear,
                                                   use_covariate_demographics_month = covariateSettings$useCovariateDemographicsMonth,
                                                   use_covariate_condition_occurrence = covariateSettings$useCovariateConditionOccurrence,
                                                   use_covariate_condition_occurrence_long_term = covariateSettings$useCovariateConditionOccurrenceLongTerm,
                                                   use_covariate_condition_occurrence_short_term = covariateSettings$useCovariateConditionOccurrenceShortTerm,
                                                   use_covariate_condition_occurrence_inpt_medium_term = covariateSettings$useCovariateConditionOccurrenceInptMediumTerm,
                                                   use_covariate_condition_era = covariateSettings$useCovariateConditionEra,
                                                   use_covariate_condition_era_ever = covariateSettings$useCovariateConditionEraEver,
                                                   use_covariate_condition_era_overlap = covariateSettings$useCovariateConditionEraOverlap,
                                                   use_covariate_condition_group = covariateSettings$useCovariateConditionGroup,
                                                   use_covariate_condition_group_meddra = covariateSettings$useCovariateConditionGroupMeddra,
                                                   use_covariate_condition_group_snomed = covariateSettings$useCovariateConditionGroupSnomed,
                                                   use_covariate_drug_exposure = covariateSettings$useCovariateDrugExposure,
                                                   use_covariate_drug_exposure_long_term = covariateSettings$useCovariateDrugExposureLongTerm,
                                                   use_covariate_drug_exposure_short_term = covariateSettings$useCovariateDrugExposureShortTerm,
                                                   use_covariate_drug_era = covariateSettings$useCovariateDrugEra,
                                                   use_covariate_drug_era_long_term = covariateSettings$useCovariateDrugEraLongTerm,
                                                   use_covariate_drug_era_short_term = covariateSettings$useCovariateDrugEraShortTerm,
                                                   use_covariate_drug_era_overlap = covariateSettings$useCovariateDrugEraOverlap,
                                                   use_covariate_drug_era_ever = covariateSettings$useCovariateDrugEraEver,
                                                   use_covariate_drug_group = covariateSettings$useCovariateDrugGroup,
                                                   use_covariate_procedure_occurrence = covariateSettings$useCovariateProcedureOccurrence,
                                                   use_covariate_procedure_occurrence_long_term = covariateSettings$useCovariateProcedureOccurrenceLongTerm,
                                                   use_covariate_procedure_occurrence_short_term = covariateSettings$useCovariateProcedureOccurrenceShortTerm,
                                                   use_covariate_procedure_group = covariateSettings$useCovariateProcedureGroup,
                                                   use_covariate_observation = covariateSettings$useCovariateObservation,
                                                   use_covariate_observation_long_term = covariateSettings$useCovariateObservationLongTerm,
                                                   use_covariate_observation_short_term = covariateSettings$useCovariateObservationShortTerm,
                                                   use_covariate_observation_count_long_term = covariateSettings$useCovariateObservationCountLongTerm,
                                                   use_covariate_measurement = covariateSettings$useCovariateMeasurement,
                                                   use_covariate_measurement_long_term = covariateSettings$useCovariateMeasurementLongTerm,
                                                   use_covariate_measurement_short_term = covariateSettings$useCovariateMeasurementShortTerm,
                                                   use_covariate_measurement_count_long_term = covariateSettings$useCovariateMeasurementCountLongTerm,
                                                   use_covariate_measurement_below = covariateSettings$useCovariateMeasurementBelow,
                                                   use_covariate_measurement_above = covariateSettings$useCovariateMeasurementAbove,
                                                   use_covariate_concept_counts = covariateSettings$useCovariateConceptCounts,
                                                   use_covariate_risk_scores = covariateSettings$useCovariateRiskScores,
                                                   use_covariate_risk_scores_Charlson = covariateSettings$useCovariateRiskScoresCharlson,
                                                   use_covariate_risk_scores_DCSI = covariateSettings$useCovariateRiskScoresDCSI,
                                                   use_covariate_risk_scores_CHADS2 = covariateSettings$useCovariateRiskScoresCHADS2,
                                                   use_covariate_risk_scores_CHADS2VASc = covariateSettings$useCovariateRiskScoresCHADS2VASc,
                                                   use_covariate_interaction_year = covariateSettings$useCovariateInteractionYear,
                                                   use_covariate_interaction_month = covariateSettings$useCovariateInteractionMonth,
                                                   has_excluded_covariate_concept_ids = hasExcludedCovariateConceptIds,
                                                   has_included_covariate_concept_ids = hasIncludedCovariateConceptIds,
                                                   delete_covariates_small_count = covariateSettings$deleteCovariatesSmallCount,
                                                   long_term_days = covariateSettings$longTermDays,
                                                   medium_term_days = covariateSettings$mediumTermDays,
                                                   short_term_days = covariateSettings$shortTermDays)
  
  DatabaseConnector::executeSql(connection, renderedSql)
  writeLines("Done")
  
  writeLines("Fetching data from server")
  start <- Sys.time()
  covariateSql <- "SELECT row_id, covariate_id, covariate_value FROM #cov ORDER BY covariate_id, row_id"
  covariateSql <- SqlRender::translateSql(sql = covariateSql,
                                          targetDialect = attr(connection, "dbms"),
                                          oracleTempSchema = oracleTempSchema)$sql
  covariates <- DatabaseConnector::querySql.ffdf(connection, covariateSql)
  covariateRefSql <- "SELECT covariate_id, covariate_name, analysis_id, concept_id  FROM #cov_ref ORDER BY covariate_id"
  covariateRefSql <- SqlRender::translateSql(sql = covariateRefSql,
                                             targetDialect = attr(connection, "dbms"),
                                             oracleTempSchema = oracleTempSchema)$sql
  covariateRef <- DatabaseConnector::querySql.ffdf(connection, covariateRefSql)
  
  sql <- "SELECT COUNT_BIG(*) FROM @cohort_temp_table"
  sql <- SqlRender::renderSql(sql, cohort_temp_table = cohortTempTable)$sql
  sql <- SqlRender::translateSql(sql = sql,
                                 targetDialect = attr(connection, "dbms"),
                                 oracleTempSchema = oracleTempSchema)$sql
  populationSize <- DatabaseConnector::querySql(connection, sql)[1, 1]
  
  delta <- Sys.time() - start
  writeLines(paste("Fetching data took", signif(delta, 3), attr(delta, "units")))
  
  renderedSql <- SqlRender::loadRenderTranslateSql("RemoveCovariateTempTables.sql",
                                                   packageName = "FeatureExtraction",
                                                   dbms = attr(connection, "dbms"),
                                                   oracleTempSchema = oracleTempSchema)
  
  DatabaseConnector::executeSql(connection,
                                renderedSql,
                                progressBar = FALSE,
                                reportOverallTime = FALSE)
  
  colnames(covariates) <- SqlRender::snakeCaseToCamelCase(colnames(covariates))
  colnames(covariateRef) <- SqlRender::snakeCaseToCamelCase(colnames(covariateRef))
  
  # Remove redundant covariates
  writeLines("Removing redundant covariates")
  start <- Sys.time()
  deletedCovariateIds <- c()
  if (nrow(covariates) != 0) {
    # First delete all single covariates that appear in every row with the same value
    valueCounts <- bySumFf(ff::ff(1, length = nrow(covariates)), covariates$covariateId)
    nonSparseIds <- valueCounts$bins[valueCounts$sums == populationSize]
    for (covariateId in nonSparseIds) {
      selection <- covariates$covariateId == covariateId
      idx <- ffbase::ffwhich(selection, selection == TRUE)
      values <- ffbase::unique.ff(covariates$covariateValue[idx])
      if (length(values) == 1) {
        idx <- ffbase::ffwhich(selection, selection == FALSE)
        covariates <- covariates[idx, ]
        deletedCovariateIds <- c(deletedCovariateIds, covariateId)
      }
    }
    # Next, from groups of covariates that together cover every row, remove the most prevalence one
    problematicAnalysisIds <- c(2, 3, 4, 5, 6, 7)  # Gender, race, ethnicity, age, year, month
    for (analysisId in problematicAnalysisIds) {
      t <- covariateRef$analysisId == analysisId
      if (ffbase::sum.ff(t) != 0) {
        covariateIds <- ff::as.ram(covariateRef$covariateId[ffbase::ffwhich(t, t == TRUE)])
        freq <- sapply(covariateIds, function(x) {
          ffbase::sum.ff(covariates$covariateId == x)
        })
        if (sum(freq) == populationSize) {
          # Each row belongs to one of the categories, making one redunant. Remove most prevalent one
          categoryToDelete <- covariateIds[which(freq == max(freq))[1]]
          deletedCovariateIds <- c(deletedCovariateIds, categoryToDelete)
          t <- covariates$covariateId == categoryToDelete
          covariates <- covariates[ffbase::ffwhich(t, t == FALSE), ]
        }
      }
    }
  }
  delta <- Sys.time() - start
  writeLines(paste("Removing redundant covariates took", signif(delta, 3), attr(delta, "units")))
  
  metaData <- list(sql = renderedSql,
                   call = match.call(),
                   deletedCovariateIds = deletedCovariateIds)
  result <- list(covariates = covariates, covariateRef = covariateRef, metaData = metaData)
  class(result) <- "covariateData"
  return(result)
}


#' Create covariate settings
#'
#' @details
#' creates an object specifying how covariates should be contructed from data in the CDM model.
#'
#' @param useCovariateDemographics                  A boolean value (TRUE/FALSE) to determine if
#'                                                  demographic covariates (age in 5-yr increments,
#'                                                  gender, race, ethnicity, year of index date, month
#'                                                  of index date) will be created and included in
#'                                                  future models.
#' @param useCovariateDemographicsGender            A boolean value (TRUE/FALSE) to determine if gender
#'                                                  should be included in the model.
#' @param useCovariateDemographicsRace              A boolean value (TRUE/FALSE) to determine if race
#'                                                  should be included in the model.
#' @param useCovariateDemographicsEthnicity         A boolean value (TRUE/FALSE) to determine if
#'                                                  ethnicity should be included in the model.
#' @param useCovariateDemographicsAge               A boolean value (TRUE/FALSE) to determine if age
#'                                                  (in 5 year increments) should be included in the
#'                                                  model.
#' @param useCovariateDemographicsYear              A boolean value (TRUE/FALSE) to determine if
#'                                                  calendar year should be included in the model.
#' @param useCovariateDemographicsMonth             A boolean value (TRUE/FALSE) to determine if
#'                                                  calendar month should be included in the model.
#' @param useCovariateConditionOccurrence           A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates derived from CONDITION_OCCURRENCE table
#'                                                  will be created and included in future models.
#' @param useCovariateConditionOccurrenceLongTerm       A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of condition in the long term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateConditionOccurrence =
#'                                                  TRUE.
#' @param useCovariateConditionOccurrenceShortTerm        A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of condition in the short term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateConditionOccurrence =
#'                                                  TRUE.
#' @param useCovariateConditionOccurrenceInptMediumTerm   A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of condition within
#'                                                  inpatient type in medium term window prior to or on cohort
#'                                                  index date.  Only applicable if
#'                                                  useCovariateConditionOccurrence = TRUE.
#' @param useCovariateConditionEra                  A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates derived from CONDITION_ERA table will be
#'                                                  created and included in future models.
#' @param useCovariateConditionEraEver              A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of condition era anytime
#'                                                  prior to or on cohort index date.  Only applicable
#'                                                  if useCovariateConditionEra = TRUE.
#' @param useCovariateConditionEraOverlap           A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of condition era that
#'                                                  overlaps the cohort index date.  Only applicable if
#'                                                  useCovariateConditionEra = TRUE.
#' @param useCovariateConditionGroup                A boolean value (TRUE/FALSE) to determine if all
#'                                                  CONDITION_OCCURRENCE and CONDITION_ERA covariates
#'                                                  should be aggregated or rolled-up to higher-level
#'                                                  concepts based on vocabluary classification.
#' @param useCovariateConditionGroupMeddra          A boolean value (TRUE/FALSE) to determine if all
#'                                                  CONDITION_OCCURRENCE and CONDITION_ERA covariates
#'                                                  should be aggregated or rolled-up to higher-level
#'                                                  concepts based on the MEDDRA classification.
#' @param useCovariateConditionGroupSnomed          A boolean value (TRUE/FALSE) to determine if all
#'                                                  CONDITION_OCCURRENCE and CONDITION_ERA covariates
#'                                                  should be aggregated or rolled-up to higher-level
#'                                                  concepts based on the SNOMED classification.
#' @param useCovariateDrugExposure                  A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates derived from DRUG_EXPOSURE table will be
#'                                                  created and included in future models.
#' @param useCovariateDrugExposureLongTerm              A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of drug in the long term window
#'                                                  prior to or on cohort index date.  Only applicable
#'                                                  if useCovariateDrugExposure = TRUE.
#' @param useCovariateDrugExposureShortTerm               A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of drug in the short term window
#'                                                  prior to or on cohort index date.  Only applicable
#'                                                  if useCovariateDrugExposure = TRUE.
#' @param useCovariateDrugEra                       A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates derived from DRUG_ERA table will be
#'                                                  created and included in future models.
#' @param useCovariateDrugEraLongTerm                   A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of drug era in the long term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateDrugEra = TRUE.
#' @param useCovariateDrugEraShortTerm                    A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of drug era in the short term window
#'                                                  prior to or on cohort index date.  Only applicable
#'                                                  if useCovariateDrugEra = TRUE.
#' @param useCovariateDrugEraEver                   A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of drug era anytime prior
#'                                                  to or on cohort index date.  Only applicable if
#'                                                  useCovariateDrugEra = TRUE.
#' @param useCovariateDrugEraOverlap                A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of drug era that overlaps
#'                                                  the cohort index date.  Only applicable if
#'                                                  useCovariateDrugEra = TRUE.
#' @param useCovariateDrugGroup                     A boolean value (TRUE/FALSE) to determine if all
#'                                                  DRUG_EXPOSURE and DRUG_ERA covariates should be
#'                                                  aggregated or rolled-up to higher-level concepts of
#'                                                  drug classes based on vocabluary classification.
#' @param useCovariateProcedureOccurrence           A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates derived from PROCEDURE_OCCURRENCE table
#'                                                  will be created and included in future models.
#' @param useCovariateProcedureOccurrenceLongTerm       A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of procedure in the long term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateProcedureOccurrence =
#'                                                  TRUE.
#' @param useCovariateProcedureOccurrenceShortTerm        A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of procedure in the short term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateProcedureOccurrence =
#'                                                  TRUE.
#' @param useCovariateProcedureGroup                A boolean value (TRUE/FALSE) to determine if all
#'                                                  PROCEDURE_OCCURRENCE covariates should be
#'                                                  aggregated or rolled-up to higher-level concepts
#'                                                  based on vocabluary classification.
#' @param useCovariateObservation                   A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates derived from OBSERVATION table will be
#'                                                  created and included in future models.
#' @param useCovariateObservationLongTerm               A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of observation in the long term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateObservation = TRUE.
#' @param useCovariateObservationShortTerm                A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of observation in the short term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateObservation = TRUE.
#' @param useCovariateObservationCountLongTerm          A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for the count of each observation concept in
#'                                                  LongTerm window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateObservation = TRUE.
#' @param useCovariateMeasurement                   A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates derived from OBSERVATION table will be
#'                                                  created and included in future models.
#' @param useCovariateMeasurementLongTerm               A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of measurement in the long term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateMeasurement = TRUE.
#' @param useCovariateMeasurementShortTerm                A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of measurement in the short term
#'                                                  window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateMeasurement = TRUE.
#' @param useCovariateMeasurementCountLongTerm          A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for the count of each measurement concept in
#'                                                  LongTerm window prior to or on cohort index date.  Only
#'                                                  applicable if useCovariateMeasurement = TRUE.
#' @param useCovariateMeasurementBelow              A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of measurement with a
#'                                                  numeric value below normal range for latest value
#'                                                  within medium term window of cohort index.  Only applicable if
#'                                                  useCovariateMeasurement = TRUE (CDM v5+) or
#'                                                  useCovariateObservation = TRUE (CDM v4).
#' @param useCovariateMeasurementAbove              A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  look for presence/absence of measurement with a
#'                                                  numeric value above normal range for latest value
#'                                                  within medium term window of cohort index.  Only applicable if
#'                                                  useCovariateMeasurement = TRUE (CDM v5+) or
#'                                                  useCovariateObservation = TRUE (CDM v4).
#' @param useCovariateConceptCounts                 A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  count the number of concepts that a person has
#'                                                  within each domain (CONDITION, DRUG, PROCEDURE,
#'                                                  OBSERVATION)
#' @param useCovariateRiskScores                    A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  calculate various Risk Scores, including Charlson,
#'                                                  DCSI.
#' @param useCovariateRiskScoresCharlson            A boolean value (TRUE/FALSE) to determine if the
#'                                                  Charlson comorbidity index should be included in
#'                                                  the model.
#' @param useCovariateRiskScoresDCSI                A boolean value (TRUE/FALSE) to determine if the
#'                                                  DCSI score should be included in the model.
#' @param useCovariateRiskScoresCHADS2              A boolean value (TRUE/FALSE) to determine if the
#'                                                  CHADS2 score should be included in the model.
#' @param useCovariateRiskScoresCHADS2VASc          A boolean value (TRUE/FALSE) to determine if the
#'                                                  CHADS2VASc score should be included in the model.
#' @param useCovariateInteractionYear               A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  represent interaction terms between all other
#'                                                  covariates and the year of the cohort index date.
#' @param useCovariateInteractionMonth              A boolean value (TRUE/FALSE) to determine if
#'                                                  covariates will be created and used in models that
#'                                                  represent interaction terms between all other
#'                                                  covariates and the month of the cohort index date.
#' @param deleteCovariatesSmallCount                A numeric value used to remove covariates that
#'                                                  occur in both cohorts fewer than
#'                                                  deleteCovariateSmallCounts time.
#' @param excludedCovariateConceptIds               A list of concept IDs that should NOT be used to
#'                                                  construct covariates.
#' @param addDescendantsToExclude                  Should descendant concept IDs be added to the list 
#'                                                  of concepts to exclude?
#' @param includedCovariateConceptIds               A list of concept IDs that should be used to
#'                                                  construct covariates.
#' @param addDescendantsToInclude                  Should descendant concept IDs be added to the list 
#'                                                  of concepts to include?
#' @param longTermDays                             What is the length (in days) of the long-term window?
#' @param mediumTermDays                            What is the length (in days) of the medium-term window?
#' @param shortTermDays                             What is the length (in days) of the short-term window?
#' @param useCovariateProcedureOccurrence365d  DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateConditionOccurrence365d  DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateDrugExposure365d   DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateMeasurementCount365d  DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateDrugEra365d  DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateObservation365d  DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateObservationCount365d  DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateMeasurement365d  DEPRECATED. Use the LongTerm equivalent instead
#' @param useCovariateConditionOccurrenceInpt180d  DEPRECATED. Use the ShortTerm equivalent instead
#' @param useCovariateConditionOccurrence30d  DEPRECATED. Use the ShortTerm equivalent instead
#' @param useCovariateDrugExposure30d  DEPRECATED. Use the ShortTerm equivalent instead
#' @param useCovariateDrugEra30d  DEPRECATED. Use the ShortTerm equivalent instead
#' @param useCovariateMeasurement30d  DEPRECATED. Use the ShortTerm equivalent instead
#' @param useCovariateObservation30d  DEPRECATED. Use the ShortTerm equivalent instead
#' @param useCovariateProcedureOccurrence30d  DEPRECATED. Use the ShortTerm equivalent instead
#'
#'
#' @return
#' An object of type \code{defaultCovariateSettings}, to be used in other functions.
#'
#' @export
createCovariateSettings <- function(useCovariateDemographics = FALSE,
                                    useCovariateDemographicsGender = FALSE,
                                    useCovariateDemographicsRace = FALSE,
                                    useCovariateDemographicsEthnicity = FALSE,
                                    useCovariateDemographicsAge = FALSE,
                                    useCovariateDemographicsYear = FALSE,
                                    useCovariateDemographicsMonth = FALSE,
                                    useCovariateConditionOccurrence = FALSE,
                                    useCovariateConditionOccurrenceLongTerm = FALSE,
                                    useCovariateConditionOccurrenceShortTerm = FALSE,
                                    useCovariateConditionOccurrenceInptMediumTerm = FALSE,
                                    useCovariateConditionEra = FALSE,
                                    useCovariateConditionEraEver = FALSE,
                                    useCovariateConditionEraOverlap = FALSE,
                                    useCovariateConditionGroup = FALSE,
                                    useCovariateConditionGroupMeddra = FALSE,
                                    useCovariateConditionGroupSnomed = FALSE,
                                    useCovariateDrugExposure = FALSE,
                                    useCovariateDrugExposureLongTerm = FALSE,
                                    useCovariateDrugExposureShortTerm = FALSE,
                                    useCovariateDrugEra = FALSE,
                                    useCovariateDrugEraLongTerm = FALSE,
                                    useCovariateDrugEraShortTerm = FALSE,
                                    useCovariateDrugEraOverlap = FALSE,
                                    useCovariateDrugEraEver = FALSE,
                                    useCovariateDrugGroup = FALSE,
                                    useCovariateProcedureOccurrence = FALSE,
                                    useCovariateProcedureOccurrenceLongTerm = FALSE,
                                    useCovariateProcedureOccurrenceShortTerm = FALSE,
                                    useCovariateProcedureGroup = FALSE,
                                    useCovariateObservation = FALSE,
                                    useCovariateObservationLongTerm = FALSE,
                                    useCovariateObservationShortTerm = FALSE,
                                    useCovariateObservationCountLongTerm = FALSE,
                                    useCovariateMeasurement = FALSE,
                                    useCovariateMeasurementLongTerm = FALSE,
                                    useCovariateMeasurementShortTerm = FALSE,
                                    useCovariateMeasurementCountLongTerm = FALSE,
                                    useCovariateMeasurementBelow = FALSE,
                                    useCovariateMeasurementAbove = FALSE,
                                    useCovariateConceptCounts = FALSE,
                                    useCovariateRiskScores = FALSE,
                                    useCovariateRiskScoresCharlson = FALSE,
                                    useCovariateRiskScoresDCSI = FALSE,
                                    useCovariateRiskScoresCHADS2 = FALSE,
                                    useCovariateRiskScoresCHADS2VASc = FALSE,
                                    useCovariateInteractionYear = FALSE,
                                    useCovariateInteractionMonth = FALSE,
                                    excludedCovariateConceptIds = c(),
                                    addDescendantsToExclude = TRUE,
                                    includedCovariateConceptIds = c(),
                                    addDescendantsToInclude = TRUE,
                                    deleteCovariatesSmallCount = 100,
                                    longTermDays = 365,
                                    mediumTermDays = 180,
                                    shortTermDays = 30,
                                    useCovariateProcedureOccurrence365d,
                                    useCovariateConditionOccurrence365d,
                                    useCovariateDrugExposure365d,
                                    useCovariateMeasurementCount365d,
                                    useCovariateDrugEra365d,
                                    useCovariateObservation365d,
                                    useCovariateObservationCount365d,
                                    useCovariateMeasurement365d,
                                    useCovariateConditionOccurrenceInpt180d,
                                    useCovariateConditionOccurrence30d,
                                    useCovariateDrugExposure30d,
                                    useCovariateDrugEra30d,
                                    useCovariateMeasurement30d,
                                    useCovariateObservation30d,
                                    useCovariateProcedureOccurrence30d) {
  if (!missing(useCovariateProcedureOccurrence365d)) {
    warning("Argument useCovariateProcedureOccurrence365d is deprecated. Use useCovariateProcedureOccurrenceLongTerm instead")
    useCovariateProcedureOccurrenceLongTerm <- useCovariateProcedureOccurrence365d
  }
  if (!missing(useCovariateConditionOccurrence365d)) {
    warning("Argument useCovariateConditionOccurrence365d is deprecated. Use useCovariateConditionOccurrenceLongTerm instead")
    useCovariateConditionOccurrenceLongTerm <- useCovariateConditionOccurrence365d
  }
  if (!missing(useCovariateDrugExposure365d)) {
    warning("Argument useCovariateDrugExposure365d is deprecated. Use useCovariateDrugExposureLongTerm instead")
    useCovariateDrugExposureLongTerm <- useCovariateDrugExposure365d
  }
  if (!missing(useCovariateMeasurementCount365d)) {
    warning("Argument useCovariateMeasurementCount365d is deprecated. Use useCovariateObservationCountLongTerm instead")
    useCovariateObservationCountLongTerm <- useCovariateMeasurementCount365d
  }
  if (!missing(useCovariateDrugEra365d)) {
    warning("Argument useCovariateDrugEra365d is deprecated. Use useCovariateDrugEraLongTerm instead")
    useCovariateDrugEraLongTerm <- useCovariateDrugEra365d
  }
  if (!missing(useCovariateObservation365d)) {
    warning("Argument useCovariateObservation365d is deprecated. Use useCovariateObservationLongTerm instead")
    useCovariateObservationLongTerm <- useCovariateObservation365d
  }
  if (!missing(useCovariateObservationCount365d)) {
    warning("Argument useCovariateObservationCount365d is deprecated. Use useCovariateObservationCountLongTerm instead")
    useCovariateObservationCountLongTerm <- useCovariateObservationCount365d
  }
  if (!missing(useCovariateMeasurement365d)) {
    warning("Argument useCovariateMeasurement365d is deprecated. Use useCovariateMeasurementLongTerm instead")
    useCovariateMeasurementLongTerm <- useCovariateMeasurement365d
  }
  if (!missing(useCovariateConditionOccurrenceInpt180d)) {
    warning("Argument useCovariateConditionOccurrenceInpt180d is deprecated. Use useCovariateConditionOccurrenceInptMediumTerm  instead")
    useCovariateConditionOccurrenceInptMediumTerm <- useCovariateConditionOccurrenceInpt180d
  }
  if (!missing(useCovariateConditionOccurrence30d)) {
    warning("Argument useCovariateConditionOccurrence30d is deprecated. Use useCovariateConditionOccurrenceShortTerm instead")
    useCovariateConditionOccurrenceShortTerm <- useCovariateConditionOccurrence30d
  }
  if (!missing(useCovariateDrugExposure30d)) {
    warning("Argument useCovariateDrugExposure30d is deprecated. Use useCovariateDrugExposureShortTerm instead")
    useCovariateDrugExposureShortTerm <- useCovariateDrugExposure30d
  }
  if (!missing(useCovariateDrugEra30d)) {
    warning("Argument useCovariateDrugEra30d is deprecated. Use useCovariateDrugEraShortTerm instead")
    useCovariateDrugEraShortTerm <- useCovariateDrugEra30d
  }
  if (!missing(useCovariateMeasurement30d)) {
    warning("Argument useCovariateMeasurement30d is deprecated. Use useCovariateMeasurementShortTerm instead")
    useCovariateMeasurementShortTerm <- useCovariateMeasurement30d
  }
  if (!missing(useCovariateObservation30d)) {
    warning("Argument useCovariateObservation30d is deprecated. Use useCovariateObservationShortTerm instead")
    useCovariateObservationShortTerm <- useCovariateObservation30d
  }
  if (!missing(useCovariateProcedureOccurrence30d)) {
    warning("Argument useCovariateProcedureOccurrence30d is deprecated. Use useCovariateProcedureOccurrenceShortTerm instead")
    useCovariateProcedureOccurrenceShortTerm <- useCovariateProcedureOccurrence30d
  }
  # # First: get the default values:
  covariateSettings <- list()
  formalNames <- names(formals(createCovariateSettings))
  formalNames <- formalNames[!grepl("(365)|(180)|(30)", formalNames)]  
  for (name in formalNames) {
      covariateSettings[[name]] <- get(name)
  }
  # Next: overwrite defaults with actual values if specified:
  values <- lapply(as.list(match.call())[-1], function(x) eval(x, envir = sys.frame(-3)))
  for (name in names(values)) {
    if (name %in% names(covariateSettings))
      covariateSettings[[name]] <- values[[name]]
  }
  attr(covariateSettings, "fun") <- "getDbDefaultCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
