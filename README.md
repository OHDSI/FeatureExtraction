FeatureExtraction
=================

[![Build Status](https://github.com/OHDSI/FeatureExtraction/workflows/R-CMD-check/badge.svg)](https://github.com/OHDSI/FeatureExtraction/actions?query=workflow%3AR-CMD-check)
[![codecov.io](https://codecov.io/github/OHDSI/FeatureExtraction/coverage.svg?branch=main)](https://app.codecov.io/github/OHDSI/FeatureExtraction?branch=main)
[![CRAN status](https://www.r-pkg.org/badges/version/FeatureExtraction)](https://CRAN.R-project.org/package=FeatureExtraction)

FeatureExtraction is part of [HADES](https://ohdsi.github.io/Hades/).

Introduction
============
An R package for generating features (covariates) for a cohort using data in the Common Data Model.

Features
========
- Takes a cohort as input.
- Generates baseline features for that cohort.
- Default covariates include all drugs, diagnoses, procedures, as well as age, comorbidity indexes, etc.
- Support for creating custom covariates.
- Generate paper-ready summary table of select population characteristics.

Technology
==========
FeatureExtraction is an R package, with some functions implemented in C++.

System Requirements
===================
Requires R (version 3.2.2 or higher). Installation on Windows requires [RTools](https://cran.r-project.org/bin/windows/Rtools/). FeatureExtraction require Java.

Getting Started
===============
1. See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including RTools and Java.

3. In R, use the following commands to download and install FeatureExtraction:

  ```r
  install.packages("drat")
  drat::addRepo("OHDSI")
  install.packages("FeatureExtraction")
  ```

User Documentation
==================
The documentation website can be found at [https://ohdsi.github.io/FeatureExtraction/](https://ohdsi.github.io/FeatureExtraction/). PDF versions of the vignettes and package manual are here:

* Vignette: [Using FeatureExtraction](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/main/inst/doc/UsingFeatureExtraction.pdf)
* Vignette: [Creating covariates using cohort attributes](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/main/inst/doc/CreatingCovariatesUsingCohortAttributes.pdf)
* Vignette: [Creating custom covariate builders](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/main/inst/doc/CreatingCustomCovariateBuilders.pdf)
* Vignette: [Creating covariates based on other cohorts](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/main/inst/doc/CreatingCovariatesBasedOnOtherCohorts.pdf)
* Package manual: [FeatureExtraction manual](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/main/extras/FeatureExtraction.pdf) 

These vignettes are also available in Korean:

* Vignette: [Using FeatureExtraction](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/main/inst/doc/UsingFeatureExtractionKorean.pdf)
* Vignette: [Creating custom covariate builders](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/main/inst/doc/CreatingCustomCovariateBuildersKorean.pdf)


Support
=======
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="https://github.com/OHDSI/FeatureExtraction/issues">GitHub issue tracker</a> for all bugs/issues/enhancements

Contributing
============
Read [here](https://ohdsi.github.io/Hades/contribute.html) how you can contribute to this package.

License
=======
FeatureExtraction is licensed under Apache License 2.0

Development
===========
FeatureExtraction is being developed in R Studio.

### Development status

Ready for use

# Acknowledgements
- This project is supported in part through the National Science Foundation grant IIS 1251151.
