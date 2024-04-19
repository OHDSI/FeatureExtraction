FeatureExtraction 3.5.0
=======================

New Features:

- Adds the ability to filter covariates by setting a minimum threshold for covariate mean (#174)

Bug Fixes:

- Table 1 - does not report correct subject count (#237) 

FeatureExtraction 3.4.1
=======================

Bug Fixes:

- Weekly R-check fails (#239)
- BigQuery error (#208)
- Error when specifying 1 temporal window in temportalCovariateSettings (#200)
- metaData aggregation issue (#195)

FeatureExtraction 3.4.0
=======================

Bug Fixes:

- SDM calculation fix (#223)
- Each covariate has a unique covariate name (#219)
- R check (notes) (#211, #215)

Other:

- Deprecate cohortId and use cohortIds (#188)

FeatureExtraction 3.3.2
=======================

Bug Fixes:

- Fixes R check on GitHub Actions (#211) 

FeatureExtraction 3.3.1
=======================

Bug Fixes:

- Fixes unit tests running on GitHub Actions (#211) 

FeatureExtraction 3.3.0
=======================

New Features:

- Adds the ability to create cohort-based covariates (#96)
- Add covariates based on care_site_id (#164)

Bug Fixes:

- Cast demographic index year and month-year to properly format the covariate name (#158) 
- Fix vignette output to include code blocks (#163)
- Fix failing unit tests (#178)
- Switch unit tests to use temp cohorts tables (#166)
- Fix typo in UsingFeatureExtraction vignette (#186)
- Fix duplicate analysis IDs in PrespecTemporalAnalysis (#144)
- Fix duplicate cdmVersion arguments in vignette (#176)

Other:

- Add examples to all function documentation (#201)
- Standardize Maven libraries (#197)

FeatureExtraction 3.2.0
=======================

New Features:

- Adds the ability to create a "temporalSequence" to create temporal features by specifying a fixed time window. (#134)

- Identify inpatient events using visit_occurrence to support CDM 5.4 (#141)

Bug Fixes:

- Fixes MeasurementRangeGroup analysis bug (#133) to use proper look back days

Other:

- Additional unit tests and improvement of code coverage

FeatureExtraction 3.1.1
=======================

Bug Fixes:

1. Removes 'size' column name since this is a reserved keyword for Oracle.

2. Age group covariate name fix for Spark SQL

3. Removes extraneous concepts from CCI score

4. Correct output of multiple cohort IDs in `print()` function.

5. Fix external class caching issue

6. Fix standardized difference calc

7. Fixing duplicates in counts when generating server-side aggregated measurement-range-group covariates.


FeatureExtraction 3.1.0
=======================

Changes:

1. Added ability to compute aggregated statistics for multiple cohorts at once: The `cohortId` argument of the `getDbCovariateData()` function now accepts a vector of IDs. The aggregated statistics now contains a new field called `cohortDefinitionId` that can be used to distinguish between the various cohorts.

2. Added `filterByCohortDefinitionId()` function to select covariates of one cohort from a `covariateData` object containing multiple.

3. The `cohortId` argument now also supports integers greater than 32-bits.

Bug Fixes:

1. If a person has multiple measurements with the same `measurement_concept_id`, the selection of which measurement value to include is now deterministic.


FeatureExtraction 3.0.1
=======================

Changes:

1. Adding timeRef table to CovariateData object for temporal covariates.

2. Throw meaningful error when `createCovariateSettings()` is called without specifying any covariates.

3. `getDbCovariateData()` returns empty covariates instead of NULL covariates when no covariates are specified. 

Bug Fixes: 

1. Time ID is now retrieved when aggregating binary temporal covariates.


FeatureExtraction 3.0.0
=======================

Changes:

1. Switching from ff to Andromeda for storage of large data objects.

2. Adding option to createTable1 to (also) show absolute counts.

3. For analyses that restrict to inpatient diagnoses, the string '(inpatient)' is now appended to the covariate name.

Bug Fixes: 

1. Dropping spurious 'analysis_name' field in temporary covariate reference table.

2. Fixed covariate name of age groups over 100 years old. 


FeatureExtraction 2.2.5
=======================

Changes:

1. Added Korean translation of vignettes.

Bug Fixes:

1. Fixing aggregation of covariates generated using the cohort_attribute table.

2. Fixed error when calling tidyCovariates without removing redundancy, when there are no infrequent covariates.

3. Fixed server-side computation of median and interquartile range for measurement values.

4. Restricting by concept ID now works for measurement values.

FeatureExtraction 2.2.4
=======================

Bug Fixes:

1. Removing redundant covariates now precedes removing infrequent covariates when calling tidyCovariates. Analyses where the most prevalent (redundant) covariate was removed are now exempt from removal of infrequent covariates.

2. Fixed some typos in the vignette


FeatureExtraction 2.2.3
=======================

Changes:

1. Also removing descendants when excluding condition concepts from condition groups. Condition groups therefore now work similar to drug groups.

Bug Fixes:

1. Updated workaround for ff bug causing chunk.default error on R v3.6.0 on machines with lots of memory.


FeatureExtraction 2.2.2
=======================

Changes:

1. Using new SqlRender (v1.6.0) functions.


FeatureExtraction 2.2.1
=======================

Changes:

1. Added option to specify number of digits for continuous variables in createTable1 function.

Bug Fixes:

1. Added missing space cause SQL error when both include and exclude concept are specified.


FeatureExtraction 2.2.0
=======================

Changes:

1. Added the Hospital Frailty Risk Score.
