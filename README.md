FeatureExtraction
=================

Introduction
============
An R package for generating features (covariates) for a cohort using data in the Common Data Model.

Features
========
- Takes a cohort as input.
- Generates baseline features for that cohort
- Default covariates include all drugs, diagnoses, procedures, as well as age, comorbidity indexes, etc.
- Support for creating custom covariates

Screenshots
===========
Todo

Technology
==========
FeatureExtraction is an R package, with some functions implemented in C++.

System Requirements
===================
Requires R (version 3.2.2 or higher). Installation on Windows requires [RTools](http://cran.r-project.org/bin/windows/Rtools/). Libraries used in FeatureExtraction require Java.

Dependencies
============
 * DatabaseConnector
 * SqlRender

Getting Started
===============
1. On Windows, make sure [RTools](http://cran.r-project.org/bin/windows/Rtools/) is installed.
2. The DatabaseConnector and SqlRender packages require Java. Java can be downloaded from
<a href="http://www.java.com" target="_blank">http://www.java.com</a>.
3. In R, use the following commands to download and install FeatureExtraction:

  ```r
  install.packages("devtools")
  library(devtools)
  install_github("ohdsi/SqlRender") 
  install_github("ohdsi/DatabaseConnector") 
  install_github("ohdsi/FeatureExtraction") 
  ```

Getting Involved
================
* Vignette: [Using FeatureExtraction](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/UsingFeatureExtraction.pdf)
* Vignette: [Creating covariates using cohort attributes](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/CreatingCovariatesUsingCohortAttributes.pdf)
* Vignette: [Creating custom covariate builders](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/inst/doc/CreatingCustomCovariateBuilders.pdf)
* Package manual: [FeatureExtraction.pdf](https://raw.githubusercontent.com/OHDSI/FeatureExtraction/master/extras/FeatureExtraction.pdf) 
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="../../issues">GitHub issue tracker</a> for all bugs/issues/enhancements
 
License
=======
FeatureExtraction is licensed under Apache License 2.0

Development
===========
FeatureExtraction is being developed in R Studio.

### Development status

[![Build Status](https://travis-ci.org/OHDSI/FeatureExtraction.svg?branch=master)](https://travis-ci.org/OHDSI/FeatureExtraction)


Beta

# Acknowledgements
- This project is supported in part through the National Science Foundation grant IIS 1251151.

