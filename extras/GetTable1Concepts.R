# Some code to list all the concepts in the current (concept-based) table 1

# Create table with concept IDs ------------------------------------------------

table1Specs <- FeatureExtraction::getDefaultTable1Specifications() 
convertToTable <- function(i) {
  if (is.na(table1Specs$covariateIds[i])) {
    return(NULL)
  } else {
    return(data.frame(
      category = table1Specs$label[i],
      conceptId = round(as.numeric(strsplit(table1Specs$covariateIds[i], ",")[[1]]) / 1000)
    )
    )
  }
}
table <- lapply(seq_len(nrow(table1Specs)), convertToTable)
table <- do.call(rbind, table)

# Get concept names ------------------------------------------------------------
library(DatabaseConnector)
connection <- connect(
  dbms = "redshift",
  connectionString = keyring::key_get("redShiftConnectionStringOhdaCcae"),
  user = keyring::key_get("redShiftUserName"),
  password = keyring::key_get("redShiftPassword")
)
cdmDatabaseSchema <- "cdm_truven_ccae_v2008"
sql <- "SELECT concept_id,
  concept_name
FROM @cdm_database_schema.concept
WHERE concept_id IN (@concept_ids);"
conceptNames <- renderTranslateQuerySql(
  connection = connection,
  sql = sql,
  cdm_database_schema = cdmDatabaseSchema,
  concept_ids = table$conceptId,
  snakeCaseToCamelCase = TRUE
)
disconnect(connection)
table <- merge(table, conceptNames)
table <- table[order(table$category, table$conceptName), ]
table <- table[table$conceptId != 2 & table$conceptId != 8532, ]
write.csv(table, "extras/table1Concept.csv", row.names = FALSE)
