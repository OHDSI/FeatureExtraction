# This file contains tests for all the PrespecAnalyses files in the inst/csv folder.

test_that("PrespecAnalyses check for uniqueness", {
  analysesFiles <- list.files(system.file("csv", package = "FeatureExtraction"),
    pattern = "^.*.Analyses*.csv$",
    full.names = TRUE
  )

  lapply(analysesFiles, FUN = function(filePath) {
    prespecAnalyses <- read.csv(filePath)

    expect_s3_class(prespecAnalyses, "data.frame")
    expect_true(all(c(
      "analysisId", "analysisName", "sqlFileName", "subType", "domainId",
      "domainTable", "domainConceptId", "domainStartDate", "domainEndDate",
      "isDefault", "description"
    ) %in% colnames(prespecAnalyses)))

    # analysisId should be unique as well as the combination of other columns
    expect_equal(length(unique(prespecAnalyses$analysisId)), length(prespecAnalyses$analysisId))

    prespecAnalyses <- prespecAnalyses %>%
      dplyr::select(-analysisId)
    expect_equal(nrow(unique(prespecAnalyses)), nrow(prespecAnalyses))
  })
})
