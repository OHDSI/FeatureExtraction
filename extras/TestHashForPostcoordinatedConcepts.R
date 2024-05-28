# To compute covariate IDs for postcoordinated concepts (concept_id - value_as_concept_id pairs),
# we use a simple hashing function we implement in SQL. The resulting covariate ID uses 52 bits of
# precision, so will fit in an R numeric type without loss of precision. 
#
# Below is some code evaluating how likely we are to have collisions in covariate IDs (the same
# covariate ID for different concept_id - value_as_concept_id pairs). Although collisions are 
# unlikely, they may occur. In general we are not concerned, as most covariates are used for 
# predicition or confounder adjustment, and this may simply lead to one covariate (out of tens
# of thousands) being less predictive. 


# Get all possible concept IDs from the vocabulary -----------------------------
connectionDetails = DatabaseConnector::createConnectionDetails(
  dbms = "redshift",
  connectionString = keyring::key_get("redShiftConnectionStringOhdaJmdc"),
  user = keyring::key_get("redShiftUserName"),
  password = keyring::key_get("redShiftPassword")
)
cdmDatabaseSchema <- "cdm_jmdc_v2906"

connection <- DatabaseConnector::connect(connectionDetails)
sql <- "
SELECT concept_id
FROM @cmd_database_Schema.concept
WHERE standard_concept = 'S'
{@domain_id != ''} ? {
  AND domain_id = '@domain_id'
};"
observationConceptIds <- DatabaseConnector::renderTranslateQuerySql(
  connection = connection,
  sql = sql,
  cmd_database_Schema = cdmDatabaseSchema,
  domain_id = "Observation"
)
observationConceptIds <- observationConceptIds[, 1]

conceptIds <- DatabaseConnector::renderTranslateQuerySql(
  connection = connection,
  sql = sql,
  cmd_database_Schema = cdmDatabaseSchema,
  domain_id = ""
)
conceptIds <- conceptIds[, 1]

measurementConceptIds <- DatabaseConnector::renderTranslateQuerySql(
  connection = connection,
  sql = sql,
  cmd_database_Schema = cdmDatabaseSchema,
  domain_id = "Measurement"
)
measurementConceptIds <- measurementConceptIds[, 1]

measurementValueConceptIds <- DatabaseConnector::renderTranslateQuerySql(
  connection = connection,
  sql = sql,
  cmd_database_Schema = cdmDatabaseSchema,
  domain_id = "Meas Value"
)
measurementValueConceptIds <- measurementValueConceptIds[, 1]
DatabaseConnector::disconnect(connection)

# Get universe of observed concept IDs in OHDSI --------------------------------
connectionDetails = DatabaseConnector::createConnectionDetails(
  dbms = "postgresql",
  server = paste(Sys.getenv("phoebedbServer"),
                 Sys.getenv("phoebedb"),
                 sep = "/"),
  user = Sys.getenv("phoebedbUser"),
  password = Sys.getenv("phoebedbPw")
)
connection <- DatabaseConnector::connect(connectionDetails)
sql <- "SELECT concept_id FROM concept_prevalence.universe;"
universeConceptIds <- DatabaseConnector::renderTranslateQuerySql(
  connection = connection,
  sql = sql
)
universeConceptIds <- universeConceptIds[, 1]
DatabaseConnector::disconnect(connection)

# Evaluate number of collisions with various settings --------------------------
hash <- function(value, bits) {
  power <- 2^bits
  return(bitwAnd(bitwXor(value, value / power), power-1))
}

evaluateBitSizes <- function(bits1, bits2, restrictToUniverse) {
  if (restrictToUniverse) {
    conceptIdsO1 <- intersect(observationConceptIds, universeConceptIds)
    conceptIdsO2 <- intersect(conceptIds, universeConceptIds)
    conceptIdsM1 <- intersect(measurementConceptIds, universeConceptIds)
    # Measurement values were not included in concept prevalence study:
    conceptIdsM2 <- measurementValueConceptIds
  } else {
    conceptIdsO1 <- observationConceptIds
    conceptIdsO2 <- conceptIds
    conceptIdsM1 <- measurementConceptIds
    conceptIdsM2 <- measurementValueConceptIds
  }
  hashCodesO1 <- hash(conceptIdsO1, bits1)
  hashCodesO2 <- hash(conceptIdsO2, bits2)
  hashCodesM1 <- hash(conceptIdsM1, bits1)
  hashCodesM2 <- hash(conceptIdsM2, bits2)
  # Not enough memory to hold all combinations of O1 and O2 or M1 and M2, so sampling:
  hashCodesO <- expand.grid(sample(hashCodesO1, min(1000, length(hashCodesO1))), sample(hashCodesO2, min(1000, length(hashCodesO2))))
  hashCodesO <-  hashCodesO[, 1] * 2 ^ bits2 + hashCodesO[, 2]
  hashCodesM <- expand.grid(sample(hashCodesM1, min(1000, length(hashCodesM1))), sample(hashCodesM2, min(1000, length(hashCodesM2))))
  hashCodesM <-  hashCodesM[, 1] * 2 ^ bits2 + hashCodesM[, 2]
  writeLines(sprintf("Collision percents: O1: %0.2f%%, O2: %0.2f%%, O1&O2: %0.2f%%, M1: %0.2f%%, M2: %0.2f%%, M1&M2: %0.2f%%",
                     100 * mean(duplicated(hashCodesO1)),
                     100 * mean(duplicated(hashCodesO2)),
                     100 * mean(duplicated(hashCodesO)),
                     100 * mean(duplicated(hashCodesM1)),
                     100 * mean(duplicated(hashCodesM2)),
                     100 * mean(duplicated(hashCodesM))))
}

evaluateBitSizes(21, 21, FALSE)
# Collision percents: O1: 1.92%, O2: 46.31%, O1&O2: 0.00%, M1: 4.04%, M2: 0.03%, M1&M2: 0.00%

evaluateBitSizes(21, 21, TRUE)
# Collision percents: O1: 0.00%, O2: 0.45%, O1&O2: 0.00%, M1: 0.00%, M2: 0.03%, M1&M2: 0.00%

evaluateBitSizes(18, 24, FALSE)
# Collision percents: O1: 17.19%, O2: 9.11%, O1&O2: 0.10%, M1: 30.19%, M2: 0.00%, M1&M2: 0.20%

evaluateBitSizes(18, 24, TRUE)
# Collision percents: O1: 0.00%, O2: 0.00%, O1&O2: 0.00%, M1: 0.00%, M2: 0.00%, M1&M2: 0.00%

# Demonstration in RSQLite -----------------------------------------------------
connection <- DatabaseConnector::connect(dbms = "sqlite", server = ":memory:")

# For reference:
hash(380844, 18) * 2^21 + hash(2821462, 21)
# [1] 248934763863

# XOR not available in SQLite, but can implement using (a|b)-(a&b)
# 2^18 = 262144
# 2^21 = 2097152
sql <- "
SELECT (((a | a/262144) - (a & a/262144)) & 262143)*2097152 +
       (((b | b/2097152) - (b & b/2097152)) & 2097151) AS covariate_id
FROM (
  SELECT 380844 AS a,
    2821462 AS b
) tmp;
"
DatabaseConnector::renderTranslateQuerySql(connection, sql)
# #   COVARIATE_ID
# 1 248934763863

# OR not available in Oracle, but can be implemented using a + b - (a&b)
sql <- "
SELECT (((a + a/262144 - 2*(a & a/262144))) & 262143)*2097152 +
       (((b + b/2097152 - 2*(b & b/2097152))) & 2097151) AS covariate_id
FROM (
  SELECT 380844 AS a,
    2821462 AS b
) tmp;
"
DatabaseConnector::renderTranslateQuerySql(connection, sql)
# #   COVARIATE_ID
# 1 248934763863


DatabaseConnector::disconnect(connection)
