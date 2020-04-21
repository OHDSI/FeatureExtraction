#' @details
#' This function uses the data in the CDM to construct a large set of covariates for the provided
#' cohort. The cohort is assumed to be in an existing temp table with these fields: 'subject_id',
#' 'cohort_definition_id', 'cohort_start_date'. Optionally, an extra field can be added containing the
#' unique identifier that will be used as rowID in the output. Typically, users don't call this
#' function directly but rather use the \code{\link{getDbCovariateData}} function instead.
#'
#' @param connection          A connection to the server containing the schema as created using the
#'                            \code{connect} function in the \code{DatabaseConnector} package.
#' @param oracleTempSchema    A schema where temp tables can be created in Oracle.
#' @param cdmDatabaseSchema   The name of the database schema that contains the OMOP CDM instance.
#'                            Requires read permissions to this database. On SQL Server, this should
#'                            specifiy both the database and the schema, so for example
#'                            'cdm_instance.dbo'.
#' @param cohortTable         Name of the table holding the cohort for which we want to construct
#'                            covariates. If it is a temp table, the name should have a hash prefix,
#'                            e.g. '#temp_table'. If it is a non-temp table, it should include the
#'                            database schema, e.g. 'cdm_database.cohort'.
#' @param cohortId            For which cohort ID should covariates be constructed? If set to -1,
#'                            covariates will be constructed for all cohorts in the specified cohort
#'                            table.
#' @param cdmVersion          The version of the Common Data Model used. Currently only 
#'                            \code{cdmVersion = "5"} is supported.
#' @param rowIdField          The name of the field in the cohort temp table that is to be used as the
#'                            row_id field in the output table. This can be especially usefull if there
#'                            is more than one period per person.
#' @param aggregated          Should aggregate statistics be computed instead of covariates per
#'                            cohort entry? 
#'
#' @return
#' Returns an object of type \code{CovariateData}, which is an Andromeda object containing information on the baseline covariates.
#' Information about multiple outcomes can be captured at once for efficiency reasons. This object is
#' a list with the following components: \describe{ \item{covariates}{An ffdf object listing the
#' baseline covariates per person in the cohorts. This is done using a sparse representation:
#' covariates with a value of 0 are omitted to save space. The covariates object will have three
#' columns: rowId, covariateId, and covariateValue. The rowId is usually equal to the person_id,
#' unless specified otherwise in the rowIdField argument.} \item{covariateRef}{A table
#' describing the covariates that have been extracted.}  }. The CovariateData object will also have a \code{metaData} attribute, a list of objects with
#' information on how the covariateData object was constructed.
