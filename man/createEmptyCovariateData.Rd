% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CovariateData.R
\name{createEmptyCovariateData}
\alias{createEmptyCovariateData}
\title{Creates an empty covariate data object}
\usage{
createEmptyCovariateData(cohortIds, aggregated, temporal)
}
\arguments{
\item{cohortIds}{For which cohort IDs should the covariate data be created?}

\item{aggregated}{if the data should be aggregated}

\item{temporal}{if the data is temporary}
}
\value{
the empty CovariateData object
}
\description{
Creates an empty covariate data object
}
\examples{
\dontrun{
covariateData <- FeatureExtraction:::createEmptyCovariateData(
  cohortIds = 1,
  aggregated = FALSE,
  temporal = FALSE
)
}
}
