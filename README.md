FeatureExtraction
=================

[![Build Status](https://travis-ci.org/OHDSI/FeatureExtraction.svg?branch=master)](https://travis-ci.org/OHDSI/FeatureExtraction)
[![codecov.io](https://codecov.io/github/OHDSI/FeatureExtraction/coverage.svg?branch=master)](https://codecov.io/github/OHDSI/FeatureExtraction?branch=master)

FeatureExtraction is part [HADES](https://ohdsi.github.io/Hades).

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
Requires R (version 3.2.2 or higher). Installation on Windows requires [RTools](http://cran.r-project.org/bin/windows/Rtools/). FeatureExtraction require Java.

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
The documentation website can be found at [http://ohdsi.github.io/FeatureExtraction/](http://ohdsi.github.io/FeatureExtraction/). PDF versions of the vignettes and package manual are here:

* Vignette: [Using FeatureExtraction](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/UsingFeatureExtraction.pdf)
* Vignette: [Creating covariates using cohort attributes](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/CreatingCovariatesUsingCohortAttributes.pdf)
* Vignette: [Creating custom covariate builders](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/CreatingCustomCovariateBuilders.pdf)
* Package manual: [FeatureExtraction manual](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/extras/FeatureExtraction.pdf) 

These vignettes are also available in Korean:

* Vignette: [Using FeatureExtraction](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/UsingFeatureExtractionKorean.pdf)
* Vignette: [Creating custom covariate builders](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/CreatingCustomCovariateBuildersKorean.pdf)


Support
=======
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements

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
