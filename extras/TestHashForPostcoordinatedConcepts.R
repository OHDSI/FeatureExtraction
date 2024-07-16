# To compute covariate IDs for postcoordinated concepts (concept_id - value_as_concept_id pairs),
# we use a simple hashing function we implement in SQL. The resulting covariate ID uses 52 bits of
# precision, so will fit in an R numeric type without loss of precision. 
#
# Below is some code evaluating how likely we are to have collisions in covariate IDs (the same
# covariate ID for different concept_id - value_as_concept_id pairs). Although collisions are 
# unlikely, they may occur. In general we are not concerned, as most covariates are used for 
# prediction or confounder adjustment, and this may simply lead to one covariate (out of tens
# of thousands) being less predictive. 

# Check in JnJ network ---------------------------------------------------------
uniquePcCombos <- readRDS("extras/uniquePcCombos.rds")
hash1 <- function(value, bits) {
  power <- 2^bits
  return(bitwAnd(bitwXor(value, value / power), power-1))
}

hash2 <- function(value, bits) {
  # Use Andromeda / SQLite for intermediate steps requiring 64-bit integers:
  a <- Andromeda::andromeda(a = data.frame(value = as.integer(value)))
  shift <- 2^(32-bits)
  mask <- (2^bits) - 1
  sql <- sprintf("SELECT CAST((2654435769 * value / %s) & %s AS INT) AS hash FROM a;", shift, mask)
  hash <- RSQLite::dbGetQuery(a, sql)
  return(hash$hash)
}


cid <- paste(hash1(uniquePcCombos$conceptId, 18), hash1(uniquePcCombos$valueAsConceptId, 21), uniquePcCombos$table)
sum(duplicated(cid))
# [1] 750
sum(duplicated(cid)) / nrow(uniquePcCombos)
# [1] 0.004121423

cid <- paste(hash2(uniquePcCombos$conceptId, 20), hash2(uniquePcCombos$valueAsConceptId, 22), uniquePcCombos$table)
sum(duplicated(cid))
# [1] 27
sum(duplicated(cid)) / nrow(uniquePcCombos)
# [1] 0.0001483712

cid <- hash2(uniquePcCombos$conceptId, 20) * 4194304000 + hash2(uniquePcCombos$valueAsConceptId, 22) * 1000 + as.integer(uniquePcCombos$table == "measurement")
sum(duplicated(cid))

# Find a duplicate for testing:
uniquePcCombos$cid <- cid
dups <- cid[duplicated(cid)]
dups <- uniquePcCombos[cid %in% dups, ]
dups <- dups[order(dups$cid), ]
dups[1:2, ]
# # A tibble: 2 x 4
# conceptId valueAsConceptId table           cid
# <int>            <int> <fct>         <dbl>
#   1   3048564          4069590 measurement 7.41e14
# 2  40483078          4069590 measurement 7.41e14

# Demonstration of hash algorithm 1 in RSQLite ---------------------------------
connection <- DatabaseConnector::connect(dbms = "sqlite", server = ":memory:")

# For reference:
hash1(380844, 18) * 2^21 + hash1(2821462, 21)
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

# Demonstration of hash algorithm 2 in RSQLite ---------------------------------
connection <- DatabaseConnector::connect(dbms = "sqlite", server = ":memory:")

# For reference:
format(hash2(380844, 20) * 2^22 + hash2(2821462, 22), scientific = FALSE)
# [1] 2358966384914

sql <- "
SELECT ((2654435769 * a / 4096) & 1048575)*4194304 + 
       ((2654435769 * b / 1024) & 4194303) AS covariate_id
FROM (
  SELECT 380844 AS a,
    2821462 AS b
) tmp;
"
format(DatabaseConnector::renderTranslateQuerySql(connection, sql)[1, 1], scientific = FALSE)
# #   COVARIATE_ID
# 1 2358966384914

DatabaseConnector::disconnect(connection)
